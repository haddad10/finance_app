// Implementasi web: memicu download file via dart:html AnchorElement.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Memicu download file CSV langsung di browser Chrome tanpa plugin tambahan.
void triggerWebDownload(List<int> bytes, String filename) {
  final blob = html.Blob([bytes], 'text/csv; charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}
