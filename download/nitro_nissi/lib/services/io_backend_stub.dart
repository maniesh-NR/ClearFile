/// Web IO backend: no filesystem; saves become browser downloads.
library;

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class IoBackend {
  const IoBackend();

  bool get hasFileSystem => false;
  bool get isDesktop => false;
  bool get isAndroid => false;

  Future<String?> returnsDirectory() async => null;

  Future<void> writeBytes(String path, List<int> bytes) async {
    final name = path.split('/').last;
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
          ..download = name
          ..click();
    html.Url.revokeObjectUrl(url);
  }

  Future<String?> readFileText(String path) async => null;
}
