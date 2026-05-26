// Conditional export:
// - di web    → mobile_saver_stub.dart (no-op)
// - di mobile → mobile_saver_mobile.dart (share_plus + path_provider)
export 'mobile_saver_stub.dart'
    if (dart.library.io) 'mobile_saver_mobile.dart';
