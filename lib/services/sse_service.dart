// sse_service.dart
import 'package:flutter/foundation.dart';
import 'mobile_sse_impl.dart';
import 'web_sse_impl.dart';

class SSEHandler {
  static void fetchBotResponseWeb(
    Map<String, String> parameters, 
    String path,
    Function(String) onMessageReceived,
    Function(dynamic) onErrorHandler, {
    VoidCallback? onDone,
  }) {
    //final targetUrl = 'https://192.168.0.147/internal/chat?user_message=$message';
        // URL 생성
    final Uri targetUri = Uri(
      scheme: 'https',
      host: '192.168.0.147',
      //port: 8001,
      path: "internal/$path",
      queryParameters: parameters, // 딕셔너리로 쿼리 파라미터 추가
    );

    final targetUrl = targetUri.toString();

    
    if (kIsWeb) {
      print("web sse start =="+targetUrl);
      // 웹 환경에서는 web_sse_impl.dart의 구현 사용
      WebSSEImpl.startSSEConnection(
          targetUrl, onMessageReceived, onErrorHandler, onDone: onDone);
    } else {
      // 모바일 환경에서는 mobile_sse_impl.dart의 구현 사용
      MobileSSEImpl.startSSEConnection(
          targetUrl, onMessageReceived, onErrorHandler, onDone: onDone);
    }
  }
}


// 모바일 환경과 웹 환경의 구현을 분리하기 위한 인터페이스
abstract class SSEImplementation {
  static void startSSEConnection(
      String fullUrl,
      Function(String) onMessageReceived,
      Function(dynamic) onErrorHandler, {
      VoidCallback? onDone}) {}
}