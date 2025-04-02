// mobile_sse_impl.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'sse_service.dart';

// 모바일/데스크톱 환경에서 사용되는 구현체
class MobileSSEImpl implements SSEImplementation {
  static void startSSEConnection(
      String fullUrl,
      Function(String) onMessageReceived,
      Function(dynamic) onErrorHandler, {
      VoidCallback? onDone}) async {
    try {
      // HTTP 클라이언트 생성
      final client = http.Client();
      
      // SSE 연결 설정
      final request = http.Request('GET', Uri.parse(fullUrl));
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';
      
      final response = await client.send(request);
      
      response.stream.transform(utf8.decoder);
      response.stream.transform(const Utf8Decoder())
          .transform(const LineSplitter())
          .listen((line) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6);
          print('모바일 SSE 메시지 수신: $data');
          onMessageReceived(data);
        } else if (line == 'event: complete') {
          if (onDone != null) onDone();
        }
      }, onError: (error) {
        print('모바일 SSE 오류: $error');
        onErrorHandler(error);
        client.close();
      }, onDone: () {
        print('모바일 SSE 연결 종료');
        if (onDone != null) onDone();
        client.close();
      });
    } catch (e) {
      print('모바일 SSE 예외 발생: $e');
      onErrorHandler(e);
    }
  }
  
  // 대안: WebSocket 사용 구현
  static void startWebSocketConnection(
      String url,
      Function(String) onMessageReceived,
      Function(dynamic) onErrorHandler, {
      VoidCallback? onDone}) async {
    try {
      // WebSocket 서버 URL로 변환 (필요시)
      final wsUrl = url.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://');
      
      final socket = await WebSocket.connect(wsUrl);
      
      socket.listen(
        (data) {
          print("모바일 WebSocket 메시지 수신: $data");
          onMessageReceived(data.toString());
        },
        onError: (error) {
          print("모바일 WebSocket 오류: $error");
          onErrorHandler(error);
        },
        onDone: () {
          print("모바일 WebSocket 연결 종료");
          if (onDone != null) onDone();
        },
      );
    } catch (e) {
      print('모바일 WebSocket 예외 발생: $e');
      onErrorHandler(e);
    }
  }
}