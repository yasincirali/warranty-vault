import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/brand_mark.dart';
import '../../core/ui/widgets.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../rights/rights_engine.dart';
import '../items/domain/item.dart';
import '../items/providers.dart';
import '../settings/settings.dart';
import 'category_guess.dart';
import 'subject_lift.dart';

enum PhotoSource { camera, gallery }

/// Picks a photo; overridden in tests (the plugin needs a device).
final photoPickerProvider = Provider<Future<Uint8List?> Function(PhotoSource)>(
  (_) => (source) async {
    final file = await ImagePicker().pickImage(
      source: source == PhotoSource.camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1800,
      maxHeight: 1800,
      imageQuality: 92,
    );
    return file?.readAsBytes();
  },
);

/// The system's subject lifting (iOS 17+, `SubjectLift.swift`): a
/// transparent PNG cropped to the product, or a short code saying why not
/// (`android`, `ios_old`, `no_subject`, `vision`…). Never an error: the flood
/// fill in [liftSubject] is always there behind it. The code is shown small
/// under an uncut photo, so a TestFlight report says which step failed.
typedef SystemLift = ({Uint8List? png, String? why});

final systemLiftProvider = Provider<Future<SystemLift> Function(Uint8List)>(
  (_) => (bytes) async {
    if (!Platform.isIOS) return (png: null, why: 'android');
    try {
      final png = await const MethodChannel('warranty_vault/subject_lift').invokeMethod<Uint8List>('lift', bytes);
      return (png: png, why: png == null ? 'empty' : null);
    } on PlatformException catch (e) {
      return (png: null, why: e.code);
    } on MissingPluginException {
      return (png: null, why: 'no_channel');
    }
  },
);

/// [liftSubject] on a background isolate. A top-level function on purpose:
/// a closure written inside the State's method shares its scope with the
/// `setState` closures there, so it carried the State (and through it the
/// engine's ports) into the isolate message, which Dart refuses as
/// unsendable. Every photo then ended as "couldn't be read" or uncut
/// (yasin, 18 Oct); `lift_diagnostic_test` runs the real isolate.
Future<LiftResult> _liftOffMain(Uint8List bytes, Uint8List? system, RawPhoto? raw) =>
    Isolate.run(() => liftSubject(bytes, system: system, raw: raw));

/// What the photo shows, as the system's (label, confidence) pairs (iOS,
/// Vision; `SubjectLift.swift`). Empty off iOS and on any failure: then the
/// kind comes from the name or the user, never from a guess.
final photoLabelsProvider = Provider<Future<List<(String, double)>> Function(Uint8List)>(
  (_) => (bytes) async {
    if (!Platform.isIOS) return const [];
    try {
      final raw = await const MethodChannel('warranty_vault/subject_lift').invokeListMethod<List<Object?>>(
        'classify',
        bytes,
      );
      return [
        for (final r in raw ?? const <List<Object?>>[])
          if (r.length == 2 && r[0] is String && r[1] is num) (r[0] as String, (r[1] as num).toDouble()),
      ];
    } on PlatformException {
      return const [];
    } on MissingPluginException {
      return const [];
    }
  },
);

/// Decodes a photo with the phone's codec (HEIC on iPhone), scaled to
/// [maxPhotoSide]. Null when the platform can't read it either.
final platformDecodeProvider = Provider<Future<RawPhoto?> Function(Uint8List)>(
  (_) => (bytes) async {
    try {
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      final desc = await ui.ImageDescriptor.encoded(buffer);
      final k = math.min(1.0, maxPhotoSide / math.max(desc.width, desc.height));
      final codec = await desc.instantiateCodec(
        targetWidth: math.max(1, (desc.width * k).round()),
        targetHeight: math.max(1, (desc.height * k).round()),
      );
      final frame = await codec.getNextFrame();
      final data = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final raw = data == null
          ? null
          : RawPhoto(width: frame.image.width, height: frame.image.height, rgba: data.buffer.asUint8List());
      frame.image.dispose();
      codec.dispose();
      desc.dispose();
      buffer.dispose();
      return raw;
    } catch (_) {
      return null;
    }
  },
);

const _currencies = ['TRY', 'EUR', 'GBP', 'USD', 'AUD'];
const _warrantyMonths = [0, 6, 12, 24, 36, 60];

String _currencyFor(String region) => switch (region) {
  'TR' => 'TRY',
  'GB' => 'GBP',
  'US' => 'USD',
  'AU' => 'AUD',
  _ => 'EUR',
};

/// Photo → product on a shelf. Only the name is required: every other field
/// has a sensible default, and the rights engine works from date, country
/// and channel, which are prefilled.
class AddItemScreen extends ConsumerStatefulWidget {
  const AddItemScreen({super.key, this.initialSource});

  /// Opens the camera/gallery right away (from the empty-state rows).
  final PhotoSource? initialSource;

  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen> with SingleTickerProviderStateMixin {
  final _name = TextEditingController();
  final _store = TextEditingController();
  final _price = TextEditingController();

  /// Form rows rise in one after another once the sheet has arrived.
  late final _intro = AnimationController(vsync: this, duration: VMotion.enter + VMotion.stagger * 10);
  Animation<double>? _route;
  Uint8List? _picked;
  LiftResult? _photo;
  bool _useCutout = true;
  bool _lifting = false;
  bool _photoFailed = false;

  /// Why the system lift gave nothing (see [systemLiftProvider]).
  String? _liftWhy;
  bool _saving = false;
  late DateTime _date = ref.read(clockProvider)();
  SalesChannel _channel = SalesChannel.store;
  String? _region;
  String? _currency;
  int _warranty = 24;
  String? _shelfId;

  /// The kind the user picked; until then it is guessed from the name.
  ItemCategory? _kind;

  /// The kind the photo shows (Vision), when it was clear enough.
  ItemCategory? _photoKind;

  /// The user's pick wins, then the typed name (a deliberate word), then the
  /// photo. The photo usually comes first, before any name.
  ItemCategory get _effectiveKind => _kind ?? guessCategory(_name.text) ?? _photoKind ?? ItemCategory.other;

  bool get _kindFromPhoto => _kind == null && guessCategory(_name.text) == null && _photoKind != null;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
    _price.addListener(() => setState(() {}));
    if (widget.initialSource != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pick(widget.initialSource!));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _intro.value = 1;
      return;
    }
    // Start after the sheet's own slide, or the two motions blur together.
    final route = ModalRoute.of(context)?.animation;
    if (route == null || route.isCompleted) {
      if (!_intro.isAnimating && _intro.value == 0) _intro.forward();
    } else if (_route != route) {
      _route?.removeStatusListener(_onRoute);
      _route = route..addStatusListener(_onRoute);
    }
  }

  void _onRoute(AnimationStatus s) {
    if (s.isCompleted && mounted && _intro.value == 0) _intro.forward();
  }

  @override
  void dispose() {
    _route?.removeStatusListener(_onRoute);
    _intro.dispose();
    _name.dispose();
    _store.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _pick(PhotoSource source) async {
    final bytes = await ref.read(photoPickerProvider)(source);
    if (bytes == null || !mounted) return;
    setState(() {
      _lifting = true;
      _picked = bytes;
      _photoFailed = false;
    });
    try {
      // Both are on-device Vision requests; they run side by side.
      final labelsFuture = ref.read(photoLabelsProvider)(bytes);
      final system = await ref.read(systemLiftProvider)(bytes);
      // The platform codec runs here (it needs the engine), only for formats
      // the isolate's decoder can't read.
      final raw = dartCanDecode(bytes) ? null : await ref.read(platformDecodeProvider)(bytes);
      final result = await _liftOffMain(bytes, system.png, raw);
      final photoKind = guessCategoryFromLabels(await labelsFuture);
      if (!mounted) return;
      setState(() {
        _photo = result;
        _photoKind = photoKind;
        // A PNG came back but [liftSubject] refused it (no transparency, a speck).
        _liftWhy = system.why ?? 'rejected';
        _useCutout = result.cutout != null;
      });
    } catch (_) {
      if (mounted) setState(() => _photoFailed = true);
    } finally {
      if (mounted) setState(() => _lifting = false);
    }
  }

  LiftedPhoto? get _chosen =>
      _photo == null ? null : (_useCutout ? _photo!.cutout ?? _photo!.original : _photo!.original);

  Future<void> _save() async {
    final region = _region ?? ref.read<String>(defaultRegionProvider);
    final amount = parseAmount(_price.text);
    setState(() => _saving = true);
    final item = Item(
      id: '',
      name: _name.text.trim(),
      category: _effectiveKind,
      store: _store.text.trim(),
      price: amount == null ? null : Money(amount, _currency ?? _currencyFor(region)),
      shelfId: _shelfId,
      purchase: Purchase(
        date: DateTime.utc(_date.year, _date.month, _date.day),
        region: region,
        channel: _channel,
        manufacturer: _warranty == 0 ? const ManufacturerWarranty.none() : ManufacturerWarranty.months(_warranty),
      ),
    );
    await ref.read(vaultProvider.notifier).add(item, photo: _chosen);
    // No haptic here: the product's landing on its shelf gives it.
    if (mounted) Navigator.of(context).pop();
  }

  /// Rows rise 12 pt and fade in, 40 ms apart; spacers are not rows.
  List<Widget> _staggered(List<Widget> rows) {
    final total = _intro.duration!.inMicroseconds;
    var i = 0;
    return [
      for (final r in rows)
        if (r is SizedBox)
          r
        else
          _Enter(
            animation: CurvedAnimation(
              parent: _intro,
              curve: Interval(
                ((VMotion.stagger * i).inMicroseconds / total).clamp(0.0, 1.0),
                ((VMotion.stagger * i++ + VMotion.enter).inMicroseconds / total).clamp(0.0, 1.0),
                curve: Curves.easeOutCubic,
              ),
            ),
            child: r,
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final region = _region ?? ref.read<String>(defaultRegionProvider);
    final currency = _currency ?? _currencyFor(region);
    final shelves = ref.watch(vaultProvider).value?.shelves ?? const [];
    final canSave = _name.text.trim().isNotEmpty && !_saving && !_lifting;
    // Read above the Scaffold: its body sees the keyboard as already removed.
    final keyboardUp = MediaQuery.viewInsetsOf(context).bottom > 0;

    String warrantyText(int m) => m == 0 ? l.warrantyNone : (m % 12 == 0 ? l.durYears(m ~/ 12) : l.durMonths(m));

    return Scaffold(
      appBar: AppBar(
        title: Text(l.addTitle),
        backgroundColor: context.c.background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: l.close,
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      // The save bar is part of the body, not bottomNavigationBar: the body
      // shrinks above the keyboard, so the bar rides on top of it and the
      // focused field is scrolled into the space that is left.
      body: Column(
        children: [
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(VSpace.xl, VSpace.sm, VSpace.xl, VSpace.xxl),
              children: _staggered([
                _PhotoArea(
                  photo: _chosen,
                  picked: _picked,
                  lifting: _lifting,
                  failed: _photoFailed,
                  noCutout: _photo != null && _photo!.cutout == null,
                  liftWhy: _liftWhy,
                  onPick: _pick,
                ),
                if (_photo?.cutout != null) ...[
                  const SizedBox(height: VSpace.md),
                  VSegment<bool>(
                    options: [(true, l.photoCutout), (false, l.photoOriginal)],
                    selected: _useCutout,
                    onChanged: (v) => setState(() => _useCutout = v),
                  ),
                ],
                if (_photo != null) ...[
                  const SizedBox(height: VSpace.xs),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _pick(PhotoSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: Text(l.photoChange),
                    ),
                  ),
                ],
                const SizedBox(height: VSpace.lg),
                VFieldLift(
                  child: TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    groupId: formFieldsGroup,
                    onTapOutside: dismissKeyboard,
                    decoration: InputDecoration(
                      labelText: l.fieldProduct,
                      hintText: l.nameHint,
                      // The one required field says when it is done.
                      suffixIcon: VDoneTick(visible: _name.text.trim().isNotEmpty),
                    ),
                  ),
                ),
                const SizedBox(height: VSpace.lg),
                Text(l.fieldKind, style: context.t.section.copyWith(color: context.c.textSecondary)),
                const SizedBox(height: VSpace.sm),
                _KindPicker(selected: _effectiveKind, onChanged: (k) => setState(() => _kind = k)),
                if (_chosen == null) ...[
                  const SizedBox(height: VSpace.xs),
                  Text(l.kindHint, style: context.t.small.copyWith(color: context.c.textSecondary)),
                ] else if (_kindFromPhoto) ...[
                  const SizedBox(height: VSpace.xs),
                  Text(l.kindFromPhoto, style: context.t.small.copyWith(color: context.c.textSecondary)),
                ],
                const SizedBox(height: VSpace.md),
                VFieldLift(
                  child: TextField(
                    controller: _store,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    groupId: formFieldsGroup,
                    onTapOutside: dismissKeyboard,
                    decoration: InputDecoration(labelText: l.fieldStore),
                  ),
                ),
                const SizedBox(height: VSpace.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: VFieldLift(
                        child: TextField(
                          controller: _price,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          // Android shows a done key; iOS's decimal pad has none,
                          // so the bar above the keyboard carries "hide keyboard".
                          textInputAction: TextInputAction.done,
                          groupId: formFieldsGroup,
                          onTapOutside: dismissKeyboard,
                          // Keep the read-back line under the field in view too.
                          scrollPadding: const EdgeInsets.fromLTRB(20, 20, 20, 72),
                          decoration: InputDecoration(labelText: l.fieldAmount),
                        ),
                      ),
                    ),
                    const SizedBox(width: VSpace.md),
                    SizedBox(
                      width: 110,
                      child: VFieldLift(
                        child: DropdownButtonFormField<String>(
                          initialValue: currency,
                          isExpanded: true,
                          items: [for (final c in _currencies) DropdownMenuItem(value: c, child: Text(c))],
                          onChanged: (c) => setState(() => _currency = c),
                        ),
                      ),
                    ),
                  ],
                ),
                // Read back what will be saved, so "1.299" is never a surprise.
                _AmountEcho(raw: _price.text, currency: currency),
                const SizedBox(height: VSpace.md),
                _FieldButton(
                  label: l.fieldDate,
                  value: fmtDate(context, _date),
                  onTap: () async {
                    dismissKeyboard();
                    final today = ref.read(clockProvider)();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(today.year - 15),
                      lastDate: today,
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                ),
                const SizedBox(height: VSpace.lg),
                Text(l.fieldChannel, style: context.t.section.copyWith(color: context.c.textSecondary)),
                const SizedBox(height: VSpace.sm),
                // The channel changes the rights (online = 14-day withdrawal), so
                // it is asked, not guessed.
                VSegment<SalesChannel>(
                  options: [(SalesChannel.store, l.channelStore), (SalesChannel.online, l.channelOnline)],
                  selected: _channel,
                  onChanged: (v) => setState(() => _channel = v),
                ),
                const SizedBox(height: VSpace.lg),
                DropdownButtonFormField<String>(
                  initialValue: region,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l.fieldRegion),
                  items: [for (final r in kRegions) DropdownMenuItem(value: r, child: Text(regionName(l, r)))],
                  onChanged: (r) => setState(() => _region = r),
                ),
                const SizedBox(height: VSpace.md),
                DropdownButtonFormField<int>(
                  initialValue: _warranty,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l.kindManufacturer),
                  items: [for (final m in _warrantyMonths) DropdownMenuItem(value: m, child: Text(warrantyText(m)))],
                  onChanged: (m) => setState(() => _warranty = m ?? 0),
                ),
                const SizedBox(height: VSpace.md),
                DropdownButtonFormField<String?>(
                  initialValue: _shelfId,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l.fieldShelf),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l.shelfAuto)),
                    for (final (i, s) in shelves.indexed)
                      DropdownMenuItem(value: s.id, child: Text(s.label.isEmpty ? l.shelfName(i + 1) : s.label)),
                  ],
                  onChanged: (s) => setState(() => _shelfId = s),
                ),
              ]),
            ),
          ),
          _SaveBar(keyboardUp: keyboardUp, onSave: canSave ? _save : null, saving: _saving),
        ],
      ),
    );
  }
}

/// "Put it on the shelf", and while the keyboard is up a "hide keyboard"
/// button next to it: the one way to close a keyboard that has no return
/// key, in the place the thumb already is.
class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.keyboardUp, required this.onSave, required this.saving});
  final bool keyboardUp;
  final VoidCallback? onSave;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(VSpace.xl, VSpace.md, VSpace.xl, VSpace.md),
      child: Row(
        children: [
          if (keyboardUp) ...[
            VIconButton(icon: Icons.keyboard_hide_outlined, label: l.hideKeyboard, onPressed: dismissKeyboard),
            const SizedBox(width: VSpace.sm),
          ],
          Expanded(
            child: FilledButton(
              onPressed: onSave,
              child: AnimatedSwitcher(
                duration: VMotion.of(context, VMotion.quick),
                child: saving
                    ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator.adaptive(strokeWidth: 2))
                    : Text(l.putOnShelf),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "1.299,90", "1,299.90", "1299" → 1299.9. Whichever separator comes last
/// is the decimal one, so both Turkish/German and English input work.
num? parseAmount(String raw) {
  var s = raw.replaceAll(RegExp(r'[^0-9.,]'), '');
  if (s.isEmpty) return null;
  final lastComma = s.lastIndexOf(','), lastDot = s.lastIndexOf('.');
  final dec = lastComma > lastDot ? ',' : '.';
  final decIndex = dec == ',' ? lastComma : lastDot;
  // A single separator followed by exactly three digits is a thousands
  // separator ("1.299", "1,299").
  final digitsAfter = decIndex < 0 ? 0 : s.length - decIndex - 1;
  final onlyOne = s.indexOf(dec) == decIndex && !s.contains(dec == ',' ? '.' : ',');
  if (decIndex >= 0 && onlyOne && digitsAfter == 3) {
    s = s.replaceAll(dec, '');
  } else if (decIndex >= 0) {
    s = '${s.substring(0, decIndex).replaceAll(RegExp('[.,]'), '')}.${s.substring(decIndex + 1)}';
  }
  return num.tryParse(s);
}

class _PhotoArea extends StatelessWidget {
  const _PhotoArea({
    required this.photo,
    required this.picked,
    required this.lifting,
    required this.failed,
    required this.noCutout,
    required this.onPick,
    this.liftWhy,
  });
  final LiftedPhoto? photo;

  /// The raw photo while its background is being lifted.
  final Uint8List? picked;
  final bool lifting;
  final bool failed;
  final bool noCutout;
  final String? liftWhy;
  final void Function(PhotoSource) onPick;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Widget body;
    if (lifting) {
      body = KeyedSubtree(
        key: const ValueKey('lifting'),
        child: picked == null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  VLoader(label: l.loading),
                  const SizedBox(height: VSpace.md),
                  Text(l.lifting, style: context.t.small.copyWith(color: context.c.textSecondary)),
                ],
              )
            : _Scanning(bytes: picked!, label: l.lifting),
      );
    } else if (photo != null) {
      body = Padding(
        key: ValueKey(photo),
        padding: const EdgeInsets.all(VSpace.lg),
        child: Semantics(
          image: true,
          label: l.fieldProduct,
          child: photo!.cutout
              ? Image.memory(photo!.png, fit: BoxFit.contain, gaplessPlayback: true)
              : ClipRRect(
                  borderRadius: BorderRadius.circular(VRadius.sm),
                  child: Image.memory(photo!.png, fit: BoxFit.contain, gaplessPlayback: true),
                ),
        ),
      );
    } else {
      body = Padding(
        key: const ValueKey('empty'),
        padding: const EdgeInsets.all(VSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: VSpace.md,
              runSpacing: VSpace.sm,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () => onPick(PhotoSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(l.photoCamera),
                ),
                OutlinedButton.icon(
                  onPressed: () => onPick(PhotoSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(l.photoGallery),
                ),
              ],
            ),
            const SizedBox(height: VSpace.md),
            Text(
              failed ? l.photoFailed : l.photoOptional,
              textAlign: TextAlign.center,
              style: context.t.small.copyWith(color: failed ? context.c.deadline : context.c.textSecondary),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 220),
          decoration: BoxDecoration(color: context.c.tile, borderRadius: BorderRadius.circular(VRadius.lg)),
          alignment: Alignment.center,
          child: SizedBox(
            height: (photo != null && !lifting) || (lifting && picked != null) ? 240 : null,
            // The cut-out product arrives with a small pop (scale .94 → 1 and
            // a fade): it is the moment the photo becomes "a thing".
            child: AnimatedSwitcher(
              duration: VMotion.of(context, VMotion.enter),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeOutCubic,
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: ScaleTransition(scale: Tween(begin: .94, end: 1.0).animate(a), child: child),
              ),
              child: body,
            ),
          ),
        ),
        if (noCutout) ...[
          const SizedBox(height: VSpace.sm),
          Text(l.photoNoCutout, style: context.t.small.copyWith(color: context.c.textSecondary)),
          // A diagnostic code, not prose: it names the failed step for a bug
          // report. Not translated on purpose.
          if (liftWhy != null)
            Text(liftWhy!, style: context.t.small.copyWith(color: context.c.muted)),
        ],
      ],
    );
  }
}

class _FieldButton extends StatelessWidget {
  const _FieldButton({required this.label, required this.value, required this.onTap});
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '$label: $value',
    excludeSemantics: true,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(VRadius.sm),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18)),
        child: Text(value, style: context.t.body),
      ),
    ),
  );
}

/// The seven kinds as their drawings, the same ones a product without a
/// photo stands on the shelf as: picking one shows exactly what you'll get.
class _KindPicker extends StatelessWidget {
  const _KindPicker({required this.selected, required this.onChanged});
  final ItemCategory selected;
  final ValueChanged<ItemCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = VMotion.of(context, VMotion.quick);
    return Wrap(
      spacing: VSpace.sm,
      runSpacing: VSpace.sm,
      children: [
        for (final k in ItemCategory.values)
          Semantics(
            button: true,
            selected: k == selected,
            label: l.kindA11y(categoryLabel(l, k)),
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (k == selected) return;
                HapticFeedback.selectionClick();
                onChanged(k);
              },
              child: SizedBox(
                width: 72,
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: d,
                      curve: Curves.easeOutCubic,
                      width: 64,
                      height: 56,
                      padding: const EdgeInsets.all(VSpace.sm),
                      decoration: BoxDecoration(
                        color: context.c.surface,
                        borderRadius: BorderRadius.circular(VRadius.md),
                        // Selection is the ink edge plus the tick, never colour alone.
                        border: Border.all(
                          color: k == selected ? context.c.text : context.c.border,
                          width: k == selected ? 2 : 1,
                        ),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(child: Image.asset(CategoryArt.asset(k), fit: BoxFit.contain)),
                          if (k == selected)
                            Positioned(
                              right: -VSpace.sm + 2,
                              top: -VSpace.sm + 2,
                              child: Icon(Icons.check_circle_rounded, size: 16, color: context.c.text),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      categoryLabel(l, k),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      // Grows with Dynamic Type up to where two lines still
                      // fit the 72-pt column; the spoken label is the full name.
                      textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.4),
                      style: context.t.small.copyWith(
                        color: k == selected ? context.c.text : context.c.textSecondary,
                        fontWeight: k == selected ? FontWeight.w600 : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Enter extends StatelessWidget {
  const _Enter({required this.animation, required this.child});
  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    builder: (context, child) => Opacity(
      opacity: animation.value,
      child: Transform.translate(offset: Offset(0, 12 * (1 - animation.value)), child: child),
    ),
    child: child,
  );
}

/// "Kaydedilecek: ₺1.299,90" under the amount, or a plain note when the
/// text is not a number. Slides open and closed with the text.
class _AmountEcho extends StatelessWidget {
  const _AmountEcho({required this.raw, required this.currency});
  final String raw;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final amount = raw.trim().isEmpty ? null : parseAmount(raw);
    final String? text = raw.trim().isEmpty
        ? null
        : amount == null
        ? l.amountUnreadable
        : l.amountPreview(fmtMoney(context, Money(amount, currency)));
    final d = VMotion.of(context, VMotion.quick);
    return AnimatedSize(
      duration: d,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topLeft,
      child: text == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: VSpace.sm, left: VSpace.lg),
              child: Semantics(
                liveRegion: true,
                child: Row(
                  children: [
                    Icon(
                      amount == null ? Icons.info_outline_rounded : Icons.check_rounded,
                      size: 16,
                      color: context.c.textSecondary,
                    ),
                    const SizedBox(width: VSpace.xs),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: d,
                        layoutBuilder: (current, previous) =>
                            Stack(alignment: Alignment.centerLeft, children: [...previous, ?current]),
                        child: Text(
                          text,
                          key: ValueKey(text),
                          style: context.t.small.copyWith(
                            color: context.c.textSecondary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// The picked photo, dimmed, with a light band passing over it while the
/// background is being lifted: progress shown on the photo itself.
/// Constant motion, so linear. Reduce motion: still photo and a spinner.
class _Scanning extends StatefulWidget {
  const _Scanning({required this.bytes, required this.label});
  final Uint8List bytes;
  final String label;

  @override
  State<_Scanning> createState() => _ScanningState();
}

class _ScanningState extends State<_Scanning> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.of(context).disableAnimations;
    return Semantics(
      label: widget.label,
      child: Padding(
        padding: const EdgeInsets.all(VSpace.lg),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(VRadius.sm),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Opacity(opacity: .5, child: Image.memory(widget.bytes, fit: BoxFit.contain, gaplessPlayback: true)),
              if (still)
                Center(child: VLoader(label: widget.label))
              else
                AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) => Align(
                    alignment: Alignment(0, -1.2 + 2.4 * _c.value),
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            context.c.surface.withValues(alpha: 0),
                            context.c.surface.withValues(alpha: .75),
                            context.c.surface.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
