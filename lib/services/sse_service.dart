// sse_service.dart
import 'package:flutter/foundation.dart';
import 'mobile_sse_impl.dart';
import 'web_sse_impl.dart';
import 'package:speakai/config.dart';

class SSEHandler {
  static void fetchBotResponseWeb(
    Map<String, String> parameters,
    String path,
    Function(String) onMessageReceived,
    Function(dynamic) onErrorHandler, {
    VoidCallback? onDone,
  }) {
    // URL 생성
    final Uri targetUri =
        Uri.parse('$aiBaseUrl/$path?${Uri(queryParameters: parameters).query}');

    final targetUrl = targetUri.toString();

    if (kIsWeb) {
      print("web sse start ==" + targetUrl);
      // 웹 환경에서는 web_sse_impl.dart의 구현 사용
      WebSSEImpl.startSSEConnection(
          targetUrl, onMessageReceived, onErrorHandler,
          onDone: onDone);
    } else {
      // 모바일 환경에서는 mobile_sse_impl.dart의 구현 사용
      MobileSSEImpl.startSSEConnection(
          targetUrl, onMessageReceived, onErrorHandler,
          onDone: onDone);
    }
  }
}

// 모바일 환경과 웹 환경의 구현을 분리하기 위한 인터페이스
abstract class SSEImplementation {
  static void startSSEConnection(String fullUrl,
      Function(String) onMessageReceived, Function(dynamic) onErrorHandler,
      {VoidCallback? onDone}) {}
}
