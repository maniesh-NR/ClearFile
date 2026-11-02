/// Conditional IO backend: real dart:io on native, browser download on web.
export 'io_backend_real.dart' if (dart.library.html) 'io_backend_stub.dart';
