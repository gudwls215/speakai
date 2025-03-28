import 'dart:html' as html;
import 'package:flutter/material.dart';

class SSEHandler {
  // 웹 환경에서 SSE 요청 처리 메서드
  static void fetchBotResponseWeb(
    String message, 
    Function(String) onMessageReceived,
    Function(dynamic) onErrorHandler, {
    VoidCallback? onDone,
  }) {
    // CORS 우회를 위한 프록시 URL (선택적)
    //final proxyUrl = 'https://cors-anywhere.herokuapp.com/';
    final targetUrl = 'http://192.168.0.147:8001/chat?user_message=$message';
    //final fullUrl = kIsWeb ? '$proxyUrl$targetUrl' : targetUrl;
    final fullUrl = targetUrl;

    try {
      // HTML5 EventSource 직접 사용
      final eventSource = html.EventSource(fullUrl, withCredentials: true);

      // 메시지 이벤트 리스너
      eventSource.onMessage.listen((event) {
        print('SSE 메시지 수신: '+ event.data);
        if (event.data != null) {
          onMessageReceived(event.data.toString());
        }
      }, onError: (error) {
        print('SSE 메시지 수신 오류: $error');
        onErrorHandler(error);
        eventSource.close();
      });

      eventSource.addEventListener('complete', (event) => {
        if (onDone != null) onDone()
      });


      // 연결 오류 핸들링
      eventSource.onError.listen((error) {
        print('SSE 연결 오류: $error');
        onErrorHandler(error);
        eventSource.close();
      });

    } catch (e) {
      print('SSE 요청 예외 발생: $e');
      onErrorHandler(e);
    }
  }

  // 대체 네트워크 요청 메서드 (SSE 실패 시)
  static Future<void> fallbackHttpRequest(
    String message, 
    Function(String) onMessageReceived,
    Function(dynamic) onErrorHandler
  ) async {
    try {
      // HTTP 폴백 요청 로직
      final response = await html.HttpRequest.request(
        'http://192.168.0.147:8001/chat?user_message=$message',
        method: 'GET',
        withCredentials: true,
        requestHeaders: {
          'Accept': 'application/json',
          'Cookie': 'jwt=...' // 기존 쿠키 그대로 사용
        }
      );

      if (response.status == 200) {
        onMessageReceived(response.responseText ?? '');
      } else {
        onErrorHandler('HTTP 요청 실패: ${response.status}');
      }
    } catch (e) {
      print('폴백 요청 오류: $e');
      onErrorHandler(e);
    }
  }
}