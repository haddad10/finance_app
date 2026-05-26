// Conditional export:
// - di web  → pakai download_helper_web.dart (dart:html)
// - di mobile → pakai download_helper_stub.dart (unsupported, mobile pakai share_plus)
export 'download_helper_stub.dart'
    if (dart.library.html) 'download_helper_web.dart';
