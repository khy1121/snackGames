/// Vibration Service with conditional export for Web and Mobile
library;
export 'vibration_service_stub.dart'
    if (dart.library.html) 'vibration_service_web.dart'
    if (dart.library.io) 'vibration_service_mobile.dart';
