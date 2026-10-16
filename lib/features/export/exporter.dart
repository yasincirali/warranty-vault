import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/generated/app_localizations.dart';
import '../items/providers.dart';
import 'inventory_report.dart';
import 'pdf_export.dart';
import 'xlsx_export.dart';

enum ExportFormat {
  pdf('pdf', 'application/pdf'),
  xlsx('xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');

  const ExportFormat(this.extension, this.mime);
  final String extension;
  final String mime;
}

/// Hands a finished file to the system share sheet (Save to Files, Mail,
/// AirDrop, print…). The app never decides where the file goes: the data
/// stays on the phone until the user sends it somewhere. Tests replace it.
typedef ShareFile = Future<void> Function(File file, String mime, Rect origin);

final shareFileProvider = Provider<ShareFile>(
  (_) => (file, mime, origin) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: mime)],
        // iPad shows the sheet as a popover anchored here.
        sharePositionOrigin: origin,
      ),
    );
  },
);

/// Where the file is written before sharing. Temporary on purpose: the
/// copy the user keeps is the one they save; ours is cleaned by the system.
final exportDirProvider = Provider<Future<Directory> Function()>((_) => getTemporaryDirectory);

/// The PDF carries each photo at this width: sharp at the 56-pt thumbnail
/// when printed, without putting full camera photos into the file.
const _photoPx = 240;

final exporterProvider = Provider<Exporter>(Exporter.new);

class Exporter {
  Exporter(this.ref);
  final Ref ref;

  /// The inventory as of now, or null when there is nothing to export.
  Future<InventoryReport?> report() async {
    final vault = await ref.read(vaultProvider.future);
    final views = await ref.read(itemViewsProvider.future);
    final r = InventoryReport.from(vault, views, ref.read(clockProvider)());
    return r.isEmpty ? null : r;
  }

  /// Builds the file and returns it; null when the cabinet is empty.
  Future<File?> make(ExportFormat format, AppLocalizations l) async {
    final r = await report();
    if (r == null) return null;
    final Uint8List bytes;
    switch (format) {
      case ExportFormat.pdf:
        final store = ref.read(vaultStoreProvider);
        bytes = await inventoryPdf(
          r,
          l: l,
          assets: await PdfAssets.load(rootBundle),
          photo: (path) async => _small(await store.photoBytes(path)),
        );
      case ExportFormat.xlsx:
        bytes = inventoryXlsx(r, l: l);
    }
    final dir = await ref.read(exportDirProvider)();
    final day = r.today.toIso8601String().substring(0, 10);
    // "envanter-2026-10-16.pdf": sorts by date in Files, no spaces for mail.
    final file = File('${dir.path}/${l.exportFileName}-$day.${format.extension}');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static Future<Uint8List?> _small(Uint8List? bytes) async {
    if (bytes == null) return null;
    try {
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: _photoPx);
      final frame = await codec.getNextFrame();
      final png = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      frame.image.dispose();
      return png?.buffer.asUint8List();
    } catch (e, s) {
      // A photo that can't be decoded leaves its tile empty; the rest of
      // the inventory is still worth the file.
      FlutterError.reportError(FlutterErrorDetails(exception: e, stack: s, library: 'export'));
      return null;
    }
  }
}
