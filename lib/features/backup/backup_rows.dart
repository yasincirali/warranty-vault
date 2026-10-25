import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/widgets.dart';
import '../../l10n/generated/app_localizations.dart';
import '../export/exporter.dart';
import '../items/providers.dart';
import '../settings/settings.dart';
import 'backup.dart';

/// Picks a backup file; tests replace it. Any type: iOS Files shows a zip
/// greyed out when filtered by extension in some providers.
final backupPickerProvider = Provider<Future<File?> Function()>(
  (_) => () async {
    final f = await FilePicker.pickFile();
    final path = f?.path;
    return path == null ? null : File(path);
  },
);

/// When the last backup file was made (or the backup that was restored
/// was made). Rafım Ar-Ge 25 Oct (yasin "yap"): a local-first app's worst
/// review is "new phone, everything gone", and nothing told the user
/// whether they had ever taken a copy. Made, not saved: the share sheet
/// does not say where the file went, so the line says "backup file".
const lastBackupKey = 'last_backup';

/// From this many of the user's own products on, a cabinet with no backup
/// says so (in Settings only: no notification, no sheet). Below it the
/// loss is small and the line would only nag a new user.
const backupNudgeFrom = 10;

class LastBackupController extends Notifier<DateTime?> {
  @override
  DateTime? build() => DateTime.tryParse(ref.read(settingsStoreProvider).read(lastBackupKey) ?? '');

  Future<void> record(DateTime when) async {
    // A restored backup older than the one already noted does not move it back.
    if (state != null && !when.isAfter(state!)) return;
    state = when;
    await ref.read(settingsStoreProvider).write(lastBackupKey, when.toUtc().toIso8601String());
  }
}

final lastBackupProvider = NotifierProvider<LastBackupController, DateTime?>(LastBackupController.new);

/// "Take everything with you" and "bring it back": the device backup
/// covers a lost phone, this covers a new phone without that backup, a
/// reinstall, or moving to another Apple ID.
class BackupCard extends ConsumerWidget {
  const BackupCard({super.key, required this.vaultDir});
  final Directory vaultDir;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return VCard(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(VRadius.lg - 1),
        child: Column(children: [
          const _BackupStatus(),
          _BusyRow(
            icon: Icons.archive_outlined,
            trailing: Icons.ios_share_rounded,
            label: l.backupMake,
            detail: l.backupMakeWhy,
            run: (context) => _make(context, ref),
          ),
          Divider(height: 1, indent: VSpace.lg, color: context.c.divider),
          _BusyRow(
            icon: Icons.unarchive_outlined,
            trailing: Icons.chevron_right,
            label: l.backupRestore,
            detail: l.backupRestoreWhy,
            run: (context) => _restore(context, ref),
          ),
        ]),
      ),
    );
  }

  Future<void> _make(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null ? Rect.zero : box.localToGlobal(Offset.zero) & box.size;
    final now = ref.read(clockProvider)();
    final out = await ref.read(exportDirProvider)();
    final name = '${l.backupFilePrefix}-${now.year}-${_two(now.month)}-${_two(now.day)}.zip';
    final file = await makeBackup(vaultDir, out, name, now);
    await ref.read(shareFileProvider)(file, 'application/zip', origin);
    await ref.read(lastBackupProvider.notifier).record(now);
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final zip = await ref.read(backupPickerProvider)();
    if (zip == null) return;
    final Directory staging;
    final BackupSummary summary;
    try {
      (staging, summary) = await stageRestore(zip, vaultDir);
    } on BackupInvalid {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.backupInvalid)));
      return;
    }
    final current = ref.read(vaultProvider).value?.items.length ?? 0;
    if (!context.mounted) return discardRestore(staging);
    final yes = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog.adaptive(
        title: Text(l.backupConfirmTitle(summary.items)),
        content: Text([
          if (summary.created != null) l.backupFrom(fmtDate(d, summary.created!)),
          l.backupConfirmBody(current),
        ].join('\n\n')),
        actions: [
          TextButton(onPressed: () => Navigator.of(d).pop(false), child: Text(l.cancel)),
          TextButton(onPressed: () => Navigator.of(d).pop(true), child: Text(l.backupReplace)),
        ],
      ),
    );
    if (yes != true) return discardRestore(staging);
    await commitRestore(staging, vaultDir);
    if (summary.created != null) await ref.read(lastBackupProvider.notifier).record(summary.created!);
    // Photos keep their file names across backups; the cache would keep
    // showing the old pictures under the same paths.
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
    ref.invalidate(vaultProvider);
    await ref.read(vaultProvider.future);
    HapticFeedback.lightImpact();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l.backupRestored(summary.items))));
  }
}

/// The card's first line: when the last backup was made, or, past
/// [backupNudgeFrom] own products with none, that there is none. In words
/// and an icon, never colour alone.
class _BackupStatus extends ConsumerWidget {
  const _BackupStatus();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final last = ref.watch(lastBackupProvider);
    final own = ref.watch(vaultProvider).value?.items.where((i) => !i.sample).length ?? 0;
    if (last == null && own < backupNudgeFrom) return const SizedBox.shrink();
    final text = last != null ? l.backupLast(fmtDate(context, last.toLocal())) : l.backupNever(own);
    return MergeSemantics(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: VSpace.lg, vertical: VSpace.md),
          child: Row(children: [
            ExcludeSemantics(
              child: Icon(
                last != null ? Icons.check_circle_outline : Icons.info_outline,
                color: last != null ? context.c.textSecondary : context.c.text,
              ),
            ),
            const SizedBox(width: VSpace.md),
            Expanded(
              child: Text(
                text,
                style: context.t.small.copyWith(color: last != null ? context.c.textSecondary : context.c.text),
              ),
            ),
          ]),
        ),
        Divider(height: 1, indent: VSpace.lg, color: context.c.divider),
      ]),
    );
  }
}

String _two(int n) => n.toString().padLeft(2, '0');

/// A settings row that runs one job and shows a spinner while it does;
/// the same look as the export rows.
class _BusyRow extends StatefulWidget {
  const _BusyRow({required this.icon, required this.trailing, required this.label, required this.detail, required this.run});
  final IconData icon;
  final IconData trailing;
  final String label;
  final String detail;
  final Future<void> Function(BuildContext context) run;

  @override
  State<_BusyRow> createState() => _BusyRowState();
}

class _BusyRowState extends State<_BusyRow> {
  bool _busy = false;

  Future<void> _go() async {
    if (_busy) return;
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    HapticFeedback.selectionClick();
    setState(() => _busy = true);
    try {
      await widget.run(context);
    } catch (e, s) {
      FlutterError.reportError(FlutterErrorDetails(exception: e, stack: s, library: 'backup'));
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.backupFailed)));
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
        onTap: _busy ? null : _go,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: VSize.button),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: VSpace.lg, vertical: VSpace.md),
            child: Row(children: [
              ExcludeSemantics(child: Icon(widget.icon, color: context.c.text)),
              const SizedBox(width: VSpace.md),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.label, style: context.t.label),
                  Text(widget.detail, style: context.t.small.copyWith(color: context.c.textSecondary)),
                ]),
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
                          child: Icon(widget.trailing, size: 22, color: context.c.textSecondary),
                        ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
