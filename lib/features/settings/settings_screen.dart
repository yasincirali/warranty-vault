import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/widgets.dart';
import '../../l10n/generated/app_localizations.dart';
import '../backup/backup.dart';
import '../backup/backup_rows.dart';
import '../export/exporter.dart';
import '../reminders/notification_access_row.dart';
import 'settings.dart';

/// Two decisions and one fact (yasin, 15 Oct: "ayarlar yok, İngilizce de
/// kullanılabilir olmalı"):
/// - language: the phone's, or Türkçe / English regardless of the phone;
/// - country: which law new products are judged by;
/// - where the data lives;
/// - taking it all out as a file (yasin, 16 Oct: PDF and Excel export);
/// - reminders and a whole-cabinet backup (benchmark, 17 Oct: every
///   compared app reminds; a new phone must not mean an empty cabinet).
/// Choices are checkmark lists, the iOS Settings pattern, not dropdowns,
/// one page behind a row that names the current value (27 Oct).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(settingsProvider);
    final ctl = ref.read(settingsProvider.notifier);
    final vaultDir = ref.watch(backupDirProvider);
    final phoneLanguage = WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'tr' ? l.langTr : l.langEn;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.settingsTitle),
        backgroundColor: context.c.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(VSpace.xl, VSpace.sm, VSpace.xl, VSpace.xxl),
        children: [
          // One row each, the choice behind it (Rafım Ar-Ge 27 Oct, yasin
          // "yap"): ten checkmark rows filled the first screen and pushed
          // reminders and backup below it, and "phone's country · US" stood
          // right above "US". The value is said on the row.
          VCard(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(VRadius.lg - 1),
              child: Column(children: [
                _PickRow(
                  label: l.settingsLanguage,
                  value: switch (s.language) { 'tr' => l.langTr, 'en' => l.langEn, _ => phoneLanguage },
                  onTap: () => _pick(context, (l) => l.settingsLanguage, (context, ref, l) {
                    final s = ref.watch(settingsProvider);
                    final ctl = ref.read(settingsProvider.notifier);
                    return [
                      _Choice(
                        label: l.languageSystem,
                        detail: phoneLanguage,
                        selected: s.language == null,
                        onTap: () => ctl.setLanguage(null),
                      ),
                      _Choice(label: l.langTr, selected: s.language == 'tr', onTap: () => ctl.setLanguage('tr')),
                      _Choice(label: l.langEn, selected: s.language == 'en', onTap: () => ctl.setLanguage('en')),
                    ];
                  }),
                ),
                Divider(height: 1, indent: VSpace.lg, color: context.c.divider),
                _PickRow(
                  label: l.settingsRegion,
                  value: regionName(l, s.region ?? deviceRegion()),
                  onTap: () => _pick(context, (l) => l.settingsRegion, (context, ref, l) {
                    final s = ref.watch(settingsProvider);
                    final ctl = ref.read(settingsProvider.notifier);
                    return [
                      _Choice(
                        label: l.regionSystem,
                        detail: regionName(l, deviceRegion()),
                        selected: s.region == null,
                        onTap: () => ctl.setRegion(null),
                      ),
                      for (final r in kRegions)
                        _Choice(label: regionName(l, r), selected: s.region == r, onTap: () => ctl.setRegion(r)),
                    ];
                  }),
                ),
              ]),
            ),
          ),
          const SizedBox(height: VSpace.sm),
          Text(l.settingsRegionHint, style: context.t.small.copyWith(color: context.c.textSecondary)),
          const SizedBox(height: VSpace.xxl),
          SectionTitle(l.settingsReminders),
          VCard(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(VRadius.lg - 1),
              child: MergeSemantics(
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ctl.setReminders(!s.reminders);
                  },
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: VSize.button),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: VSpace.lg, vertical: VSpace.md),
                      child: Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(l.remindersSwitch, style: context.t.label),
                            Text(l.remindersWhy, style: context.t.small.copyWith(color: context.c.textSecondary)),
                          ]),
                        ),
                        const SizedBox(width: VSpace.md),
                        Switch.adaptive(
                          value: s.reminders,
                          onChanged: (v) {
                            HapticFeedback.selectionClick();
                            ctl.setReminders(v);
                          },
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (s.reminders) const NotificationAccessRow(),
          // Backup before export (27 Oct): with language and country one row
          // each, it now sits on the first screen; a new phone must not mean
          // an empty cabinet, and that is the row people come here for.
          if (vaultDir != null) ...[
            const SizedBox(height: VSpace.xxl),
            SectionTitle(l.settingsBackup),
            BackupCard(vaultDir: vaultDir),
            const SizedBox(height: VSpace.sm),
            Text(l.backupHint, style: context.t.small.copyWith(color: context.c.textSecondary)),
          ],
          const SizedBox(height: VSpace.xxl),
          SectionTitle(l.settingsExport),
          VCard(
            // Clip so a row's press highlight follows the card's corners.
            child: ClipRRect(
              borderRadius: BorderRadius.circular(VRadius.lg - 1),
              child: Column(
                children: [
                  _ExportRow(
                    format: ExportFormat.pdf,
                    icon: Icons.picture_as_pdf_outlined,
                    label: l.exportPdf,
                    detail: l.exportPdfWhy,
                  ),
                  Divider(height: 1, indent: VSpace.lg, color: context.c.divider),
                  _ExportRow(
                    format: ExportFormat.xlsx,
                    icon: Icons.table_chart_outlined,
                    label: l.exportExcel,
                    detail: l.exportExcelWhy,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: VSpace.sm),
          Text(l.exportHint, style: context.t.small.copyWith(color: context.c.textSecondary)),
          const SizedBox(height: VSpace.xxl),
          SectionTitle(l.settingsAbout),
          VCard(
            padding: const EdgeInsets.all(VSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // iOS backs Application Support up to iCloud with the phone (nothing
                // here is excluded), so the honest answer to "and if I lose the
                // phone?" is said. Android's auto backup stops at 25 MB, a cabinet
                // of photos passes that, so no promise there.
                Text(
                  Theme.of(context).platform == TargetPlatform.iOS ? l.aboutLocalIos : l.aboutLocal,
                  style: context.t.body,
                ),
                const SizedBox(height: VSpace.sm),
                Text(l.disclaimer, style: context.t.small.copyWith(color: context.c.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Choices extends StatelessWidget {
  const _Choices({required this.children});
  final List<_Choice> children;

  @override
  Widget build(BuildContext context) => VCard(
    // Clip so a row's press highlight follows the card's corners.
    child: ClipRRect(
      borderRadius: BorderRadius.circular(VRadius.lg - 1),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, indent: VSpace.lg, color: context.c.divider),
            children[i],
          ],
        ],
      ),
    ),
  );
}

/// A setting and its current value; the choices are one page further, the
/// iOS Settings pattern (standard back, swipe back).
class _PickRow extends StatelessWidget {
  const _PickRow({required this.label, required this.value, required this.onTap});
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: VSize.button),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: VSpace.lg, vertical: VSpace.sm),
          // Wrap: at large text the value drops under the label instead of
          // squeezing it.
          child: Row(children: [
            Expanded(
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: VSpace.md,
                children: [
                  Text(label, style: context.t.label),
                  Text(value, style: context.t.body.copyWith(color: context.c.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: VSpace.xs),
            Icon(Icons.chevron_right, color: context.c.muted, size: 20),
          ]),
        ),
      ),
    ),
  );
}

/// The checkmark list for one setting. Built with the live settings so the
/// mark moves (and, for language, the page itself changes language) as the
/// user taps; back returns, nothing to confirm.
void _pick(
  BuildContext context,
  String Function(AppLocalizations l) title,
  List<_Choice> Function(BuildContext context, WidgetRef ref, AppLocalizations l) choices,
) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => Consumer(
      builder: (context, ref, _) {
        final l = AppLocalizations.of(context);
        return Scaffold(
          appBar: AppBar(
            title: Text(title(l)),
            backgroundColor: context.c.background,
            surfaceTintColor: Colors.transparent,
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(VSpace.xl, VSpace.sm, VSpace.xl, VSpace.xxl),
            children: [
              _Choices(children: choices(context, ref, l)),
            ],
          ),
        );
      },
    ),
  ));
}

class _Choice extends StatelessWidget {
  const _Choice({required this.label, this.detail, required this.selected, required this.onTap});
  final String label;
  final String? detail;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    inMutuallyExclusiveGroup: true,
    button: true,
    child: InkWell(
      onTap: () {
        if (selected) return;
        HapticFeedback.selectionClick();
        onTap();
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: VSize.button),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: VSpace.lg, vertical: VSpace.sm),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: context.t.label),
                    if (detail != null) Text(detail!, style: context.t.small.copyWith(color: context.c.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: VSpace.md),
              // The checkmark is the state; it also scales in so a change
              // reads even without looking right at it.
              AnimatedScale(
                scale: selected ? 1 : .6,
                duration: VMotion.of(context, VMotion.quick),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  opacity: selected ? 1 : 0,
                  duration: VMotion.of(context, VMotion.quick),
                  curve: Curves.easeOutCubic,
                  child: Icon(Icons.check_rounded, color: context.c.accent),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// One format per row; tapping builds the file and opens the share sheet.
/// The trailing share glyph says where the tap leads (iOS pattern: the file
/// is handed to the system, not saved somewhere we chose).
class _ExportRow extends ConsumerStatefulWidget {
  const _ExportRow({required this.format, required this.icon, required this.label, required this.detail});
  final ExportFormat format;
  final IconData icon;
  final String label;
  final String detail;

  @override
  ConsumerState<_ExportRow> createState() => _ExportRowState();
}

class _ExportRowState extends ConsumerState<_ExportRow> {
  bool _busy = false;

  Future<void> _run() async {
    if (_busy) return;
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null ? Rect.zero : box.localToGlobal(Offset.zero) & box.size;
    void say(String text) => messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));

    HapticFeedback.selectionClick();
    setState(() => _busy = true);
    try {
      final file = await ref.read(exporterProvider).make(widget.format, l);
      if (file == null) {
        say(l.exportEmpty);
        return;
      }
      await ref.read(shareFileProvider)(file, widget.format.mime, origin);
    } catch (e, s) {
      FlutterError.reportError(FlutterErrorDetails(exception: e, stack: s, library: 'export'));
      say(l.exportFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: _busy ? l.exportPreparing(widget.label) : null,
      child: InkWell(
        onTap: _busy ? null : _run,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: VSize.button),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: VSpace.lg, vertical: VSpace.md),
            child: Row(
              children: [
                ExcludeSemantics(child: Icon(widget.icon, color: context.c.text)),
                const SizedBox(width: VSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.label, style: context.t.label),
                      Text(widget.detail, style: context.t.small.copyWith(color: context.c.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: VSpace.md),
                SizedBox.square(
                  dimension: 24,
                  child: AnimatedSwitcher(
                    duration: VMotion.of(context, VMotion.quick),
                    child: _busy
                        ? const Padding(
                            key: ValueKey('busy'),
                            padding: EdgeInsets.all(2),
                            child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                          )
                        : ExcludeSemantics(
                            key: const ValueKey('idle'),
                            child: Icon(Icons.ios_share_rounded, size: 22, color: context.c.textSecondary),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
