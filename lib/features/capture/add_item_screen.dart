import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../rights/rights_engine.dart';
import '../items/domain/item.dart';
import '../items/providers.dart';
import 'subject_lift.dart';

enum PhotoSource { camera, gallery }

/// Picks a photo; overridden in tests (the plugin needs a device).
final photoPickerProvider = Provider<Future<Uint8List?> Function(PhotoSource)>((_) => (source) async {
      final file = await ImagePicker().pickImage(
        source: source == PhotoSource.camera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 92,
      );
      return file?.readAsBytes();
    });

/// Regions the rules file knows. Order: the user's own country first is
/// decided by [_defaultRegion]; the list itself stays stable.
const _regions = ['TR', 'DE', 'EU', 'GB', 'US', 'AU'];
const _eu = {
  'AT', 'BE', 'BG', 'HR', 'CY', 'CZ', 'DK', 'EE', 'FI', 'FR', 'GR', 'HU', 'IE', 'IT', //
  'LV', 'LT', 'LU', 'MT', 'NL', 'PL', 'PT', 'RO', 'SK', 'SI', 'ES', 'SE',
};
const _currencies = ['TRY', 'EUR', 'GBP', 'USD', 'AUD'];
const _warrantyMonths = [0, 6, 12, 24, 36, 60];

String _defaultRegion(Locale l) {
  final c = l.countryCode?.toUpperCase();
  if (c != null && _regions.contains(c)) return c;
  if (c != null && _eu.contains(c)) return 'EU';
  return l.languageCode == 'tr' ? 'TR' : 'EU';
}

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

class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  final _name = TextEditingController();
  final _store = TextEditingController();
  final _price = TextEditingController();
  LiftResult? _photo;
  bool _useCutout = true;
  bool _lifting = false;
  bool _photoFailed = false;
  bool _saving = false;
  late DateTime _date = ref.read(clockProvider)();
  SalesChannel _channel = SalesChannel.store;
  String? _region;
  String? _currency;
  int _warranty = 24;
  String? _shelfId;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
    if (widget.initialSource != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pick(widget.initialSource!));
    }
  }

  @override
  void dispose() {
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
      _photoFailed = false;
    });
    try {
      final result = await Isolate.run(() => liftSubject(bytes));
      if (!mounted) return;
      setState(() {
        _photo = result;
        _useCutout = result.cutout != null;
      });
    } catch (_) {
      if (mounted) setState(() => _photoFailed = true);
    } finally {
      if (mounted) setState(() => _lifting = false);
    }
  }

  LiftedPhoto? get _chosen => _photo == null ? null : (_useCutout ? _photo!.cutout ?? _photo!.original : _photo!.original);

  Future<void> _save() async {
    final region = _region ?? _defaultRegion(Localizations.localeOf(context));
    final amount = parseAmount(_price.text);
    setState(() => _saving = true);
    final item = Item(
      id: '',
      name: _name.text.trim(),
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
    HapticFeedback.lightImpact();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final region = _region ?? _defaultRegion(Localizations.localeOf(context));
    final currency = _currency ?? _currencyFor(region);
    final shelves = ref.watch(vaultProvider).value?.shelves ?? const [];
    final canSave = _name.text.trim().isNotEmpty && !_saving && !_lifting;

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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(VSpace.xl, VSpace.sm, VSpace.xl, VSpace.xxl),
        children: [
          _PhotoArea(
            photo: _chosen,
            lifting: _lifting,
            failed: _photoFailed,
            noCutout: _photo != null && _photo!.cutout == null,
            onPick: _pick,
          ),
          if (_photo?.cutout != null) ...[
            const SizedBox(height: VSpace.md),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: true, label: Text(l.photoCutout)),
                ButtonSegment(value: false, label: Text(l.photoOriginal)),
              ],
              selected: {_useCutout},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _useCutout = s.first),
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
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: l.fieldProduct, hintText: l.nameHint),
          ),
          const SizedBox(height: VSpace.md),
          TextField(
            controller: _store,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: l.fieldStore),
          ),
          const SizedBox(height: VSpace.md),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: TextField(
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: l.fieldAmount),
              ),
            ),
            const SizedBox(width: VSpace.md),
            SizedBox(
              width: 110,
              child: DropdownButtonFormField<String>(
                initialValue: currency,
                isExpanded: true,
                items: [for (final c in _currencies) DropdownMenuItem(value: c, child: Text(c))],
                onChanged: (c) => setState(() => _currency = c),
              ),
            ),
          ]),
          const SizedBox(height: VSpace.md),
          _FieldButton(
            label: l.fieldDate,
            value: fmtDate(context, _date),
            onTap: () async {
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
          SegmentedButton<SalesChannel>(
            segments: [
              ButtonSegment(value: SalesChannel.store, label: Text(l.channelStore)),
              ButtonSegment(value: SalesChannel.online, label: Text(l.channelOnline)),
            ],
            selected: {_channel},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _channel = s.first),
          ),
          const SizedBox(height: VSpace.lg),
          DropdownButtonFormField<String>(
            initialValue: region,
            isExpanded: true,
            decoration: InputDecoration(labelText: l.fieldRegion),
            items: [for (final r in _regions) DropdownMenuItem(value: r, child: Text(regionName(l, r)))],
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
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(VSpace.xl, VSpace.md, VSpace.xl, VSpace.md),
        child: FilledButton(
          onPressed: canSave ? _save : null,
          child: _saving
              ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator.adaptive(strokeWidth: 2))
              : Text(l.putOnShelf),
        ),
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
    required this.lifting,
    required this.failed,
    required this.noCutout,
    required this.onPick,
  });
  final LiftedPhoto? photo;
  final bool lifting;
  final bool failed;
  final bool noCutout;
  final void Function(PhotoSource) onPick;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Widget body;
    if (lifting) {
      body = Column(mainAxisSize: MainAxisSize.min, children: [
        const CircularProgressIndicator.adaptive(),
        const SizedBox(height: VSpace.md),
        Text(l.lifting, style: context.t.small.copyWith(color: context.c.textSecondary)),
      ]);
    } else if (photo != null) {
      body = Padding(
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
        padding: const EdgeInsets.all(VSpace.lg),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Wrap(spacing: VSpace.md, runSpacing: VSpace.sm, alignment: WrapAlignment.center, children: [
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
          ]),
          const SizedBox(height: VSpace.md),
          Text(
            failed ? l.photoFailed : l.photoOptional,
            textAlign: TextAlign.center,
            style: context.t.small.copyWith(color: failed ? context.c.deadline : context.c.textSecondary),
          ),
        ]),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        constraints: const BoxConstraints(minHeight: 220),
        decoration: BoxDecoration(
          color: context.c.tile,
          borderRadius: BorderRadius.circular(VRadius.lg),
        ),
        alignment: Alignment.center,
        child: SizedBox(height: photo != null && !lifting ? 240 : null, child: body),
      ),
      if (noCutout) ...[
        const SizedBox(height: VSpace.sm),
        Text(l.photoNoCutout, style: context.t.small.copyWith(color: context.c.textSecondary)),
      ],
    ]);
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
