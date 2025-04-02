// web_sse_impl.dart
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'sse_service.dart';

// 웹 환경에서만 사용되는 구현체
class WebSSEImpl implements SSEImplementation {
  static void startSSEConnection(
      String fullUrl,
      Function(String) onMessageReceived,
      Function(dynamic) onErrorHandler, {
      VoidCallback? onDone}) {
    try {
      // HTML5 EventSource 사용 (웹 환경에서만 사용 가능)
      final eventSource = html.EventSource(fullUrl, withCredentials: true);

      // 메시지 이벤트 리스너
      eventSource.onMessage.listen((event) {
        print('웹 SSE 메시지 수신: ${event.data}');
        if (event.data != null) {
          onMessageReceived(event.data.toString());
        }
      }, onError: (error) {
        print('웹 SSE 메시지 수신 오류: $error');
        onErrorHandler(error);
        eventSource.close();
      });

      // 완료 이벤트 리스너
      eventSource.addEventListener('complete', (event) {
        if (onDone != null) onDone();
        eventSource.close();
      });

      // 연결 오류 핸들링
      eventSource.onError.listen((error) {
        print('웹 SSE 연결 오류: $error');
        onErrorHandler(error);
        eventSource.close();
      });
    } catch (e) {
      print('웹 SSE 요청 예외 발생: $e');
      onErrorHandler(e);
    }
  }
}