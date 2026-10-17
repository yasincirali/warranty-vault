import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/ui/widgets.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/item.dart';
import '../providers.dart';

enum DocSource { camera, gallery, pdf }

/// A picked document: bytes plus the extension it is stored under.
typedef PickedDoc = ({Uint8List bytes, String extension});

/// The biggest PDF kept. E-invoices are 50–300 KB; a 20 MB file is a scan
/// at print resolution, and the vault (and every backup) carries it.
const maxDocBytes = 20 << 20;

/// Picks a document; overridden in tests (the plugins need a device).
/// Photographed paper is scaled and compressed by the platform picker, not
/// in Dart: 2000 px keeps thermal-receipt print readable at ~300–600 KB.
final docPickerProvider = Provider<Future<PickedDoc?> Function(DocSource)>(
  (_) => (source) async {
    if (source == DocSource.pdf) {
      final f = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: const ['pdf']);
      if (f == null) return null;
      if ((await f.length() ?? 0) > maxDocBytes) throw const DocTooLarge();
      return (bytes: await f.readAsBytes(), extension: 'pdf');
    }
    final x = await ImagePicker().pickImage(
      source: source == DocSource.camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 85,
    );
    if (x == null) return null;
    return (bytes: await x.readAsBytes(), extension: 'jpg');
  },
);

class DocTooLarge implements Exception {
  const DocTooLarge();
}

/// Opens a stored PDF in the system viewer (Quick Look on iOS: zoom,
/// share, print come with it). Tests replace it.
final openFileProvider = Provider<Future<void> Function(String path)>(
  (_) => (path) async {
    await OpenFilex.open(path, type: 'application/pdf', uti: 'com.adobe.pdf');
  },
);

String docKindLabel(AppLocalizations l, DocKind k) => switch (k) {
      DocKind.receipt => l.docReceipt,
      DocKind.warrantyCard => l.docWarrantyCard,
      DocKind.manual => l.docManual,
      DocKind.other => l.docOther,
    };

IconData docKindIcon(DocKind k) => switch (k) {
      DocKind.receipt => Icons.receipt_long_outlined,
      DocKind.warrantyCard => Icons.verified_outlined,
      DocKind.manual => Icons.menu_book_outlined,
      DocKind.other => Icons.description_outlined,
    };

/// The product's papers on its page: each opens full screen, one row adds
/// another. Kept small (one card) because the answer card above is the
/// page's point; the papers are the proof behind it.
class DocumentsSection extends ConsumerWidget {
  const DocumentsSection({super.key, required this.item});
  final Item item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final docs = item.documents;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionTitle(l.docsHeader),
      VCard(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(VRadius.lg - 1),
          child: Column(children: [
            for (final d in docs) ...[
              _DocRow(item: item, doc: d),
              Divider(height: 1, indent: VSpace.lg, color: context.c.divider),
            ],
            _AddRow(item: item, empty: docs.isEmpty),
          ]),
        ),
      ),
    ]);
  }
}

class _DocRow extends ConsumerWidget {
  const _DocRow({required this.item, required this.doc});
  final Item item;
  final ItemDoc doc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final store = ref.watch(vaultStoreProvider);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return InkWell(
      onTap: () => openDoc(context, ref, item, doc),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: VSpace.lg, vertical: VSpace.sm),
          child: Row(children: [
            ExcludeSemantics(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(VRadius.sm),
                child: SizedBox.square(
                  dimension: 44,
                  child: doc.isPdf
                      ? ColoredBox(
                          color: context.c.tile,
                          child: Icon(Icons.picture_as_pdf_outlined, color: context.c.textSecondary),
                        )
                      // Decoded at thumbnail size: a 2000-px receipt would
                      // otherwise sit in the image cache at full size.
                      : Image(
                          image: ResizeImage(store.photo(doc.path), width: (44 * dpr).round(), policy: ResizeImagePolicy.fit),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => ColoredBox(color: context.c.tile),
                        ),
                ),
              ),
            ),
            const SizedBox(width: VSpace.md),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(docKindLabel(l, doc.kind), style: context.t.label),
                Text(
                  doc.isPdf ? l.docPdf : l.docPhoto,
                  style: context.t.small.copyWith(color: context.c.textSecondary),
                ),
              ]),
            ),
            Icon(Icons.chevron_right, color: context.c.muted, size: 20),
          ]),
        ),
      ),
    );
  }
}

class _AddRow extends ConsumerWidget {
  const _AddRow({required this.item, required this.empty});
  final Item item;
  final bool empty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return InkWell(
      onTap: () => _showAddSheet(context, ref, item),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: VSize.button),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: VSpace.lg, vertical: VSpace.md),
          child: Row(children: [
            ExcludeSemantics(child: Icon(Icons.add, color: context.c.text)),
            const SizedBox(width: VSpace.md),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.docAdd, style: context.t.label),
                // Said only while there is nothing yet: why it matters.
                if (empty) Text(l.docAddWhy, style: context.t.small.copyWith(color: context.c.textSecondary)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// One sheet, two choices, every option visible: what the paper is (the
/// receipt is preselected while there is none), then where it comes from.
Future<void> _showAddSheet(BuildContext context, WidgetRef ref, Item item) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  var kind = item.receipt == null ? DocKind.receipt : DocKind.warrantyCard;
  final source = await showModalBottomSheet<DocSource>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) => StatefulBuilder(
      builder: (sheet, setSheet) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(VSpace.xl, 0, VSpace.xl, VSpace.lg),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SectionTitle(l.docWhat),
            VCard(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(VRadius.lg - 1),
                child: Column(children: [
                  for (final (i, k) in DocKind.values.indexed) ...[
                    if (i > 0) Divider(height: 1, indent: VSpace.lg, color: sheet.c.divider),
                    Semantics(
                      selected: k == kind,
                      button: true,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setSheet(() => kind = k);
                        },
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: VSize.minTap + 4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: VSpace.lg, vertical: VSpace.sm),
                            child: Row(children: [
                              ExcludeSemantics(child: Icon(docKindIcon(k), size: 20, color: sheet.c.textSecondary)),
                              const SizedBox(width: VSpace.md),
                              Expanded(child: Text(docKindLabel(l, k), style: sheet.t.label)),
                              if (k == kind) Icon(Icons.check, color: sheet.c.text, size: 20),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ],
                ]),
              ),
            ),
            const SizedBox(height: VSpace.lg),
            for (final (s, icon, label) in [
              (DocSource.camera, Icons.photo_camera_outlined, l.docFromCamera),
              (DocSource.gallery, Icons.photo_library_outlined, l.docFromGallery),
              (DocSource.pdf, Icons.picture_as_pdf_outlined, l.docFromFile),
            ]) ...[
              OutlinedButton.icon(
                onPressed: () => Navigator.of(sheet).pop(s),
                icon: Icon(icon, size: 18),
                label: Text(label),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(VSize.button),
                  foregroundColor: sheet.c.text,
                  backgroundColor: sheet.c.surface,
                  side: BorderSide(color: sheet.c.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VRadius.md)),
                ),
              ),
              const SizedBox(height: VSpace.sm),
            ],
          ]),
        ),
      ),
    ),
  );
  if (source == null) return;
  void say(String text) => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
  try {
    final picked = await ref.read(docPickerProvider)(source);
    if (picked == null) return;
    await ref.read(vaultProvider.notifier).addDoc(item.id, picked.bytes, extension: picked.extension, kind: kind);
    HapticFeedback.lightImpact();
    say(l.docAdded(docKindLabel(l, kind)));
  } on DocTooLarge {
    say(l.docTooLarge);
  } catch (e, s) {
    FlutterError.reportError(FlutterErrorDetails(exception: e, stack: s, library: 'documents'));
    say(l.docFailed);
  }
}

/// Photos open in the app (pinch to zoom); PDFs go to the system viewer,
/// which already does pages, zoom, share and print better than we would.
Future<void> openDoc(BuildContext context, WidgetRef ref, Item item, ItemDoc doc) async {
  if (doc.isPdf) {
    final path = ref.read(vaultStoreProvider).filePath(doc.path);
    if (path != null) await ref.read(openFileProvider)(path);
    return;
  }
  await Navigator.of(context).push(MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => DocViewerScreen(itemId: item.id, doc: doc),
  ));
}

class DocViewerScreen extends ConsumerWidget {
  const DocViewerScreen({super.key, required this.itemId, required this.doc});
  final String itemId;
  final ItemDoc doc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final store = ref.watch(vaultStoreProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(docKindLabel(l, doc.kind)),
        backgroundColor: context.c.background,
        surfaceTintColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.only(left: VSpace.md),
          child: Center(child: VIconButton(icon: Icons.close, label: l.close, onPressed: () => Navigator.of(context).pop())),
        ),
        actions: [
          VIconButton(
            icon: Icons.delete_outline,
            label: l.docDelete,
            onPressed: () async {
              final nav = Navigator.of(context);
              final yes = await showDialog<bool>(
                context: context,
                builder: (d) => AlertDialog.adaptive(
                  title: Text(l.docDeleteTitle(docKindLabel(l, doc.kind))),
                  content: Text(l.docDeleteBody),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(d).pop(false), child: Text(l.cancel)),
                    TextButton(onPressed: () => Navigator.of(d).pop(true), child: Text(l.docDelete)),
                  ],
                ),
              );
              if (yes != true) return;
              await ref.read(vaultProvider.notifier).removeDoc(itemId, doc.path);
              nav.pop();
            },
          ),
          const SizedBox(width: VSpace.md),
        ],
      ),
      body: SafeArea(
        child: InteractiveViewer(
          maxScale: 5,
          child: Center(
            child: Semantics(
              image: true,
              label: docKindLabel(l, doc.kind),
              child: Image(image: store.photo(doc.path), fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}
