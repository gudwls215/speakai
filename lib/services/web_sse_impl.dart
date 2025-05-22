// web_sse_impl.dart
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter_client_sse/constants/sse_request_type_enum.dart';
import 'package:flutter_client_sse/flutter_client_sse.dart';
import 'sse_service.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

// 웹 환경에서만 사용되는 구현체
class WebSSEImpl implements SSEImplementation {
  static Future<void> startSSEConnection(String fullUrl,
      Function(String) onMessageReceived, Function(dynamic) onErrorHandler,
      {VoidCallback? onDone}) async {
    try {
      // SSEClient.subscribeToSSE(
      //   method: SSERequestType.POST,
      //   url: fullUrl,
      //   body: {
      //     'message': message,
      //     'user_id': 'ttm',
      //     'stream': true
      //   }, // 서버에 전송할 데이터
      //   header: {
      //     'Authorization': 'Bearer your_token',
      //     'Content-Type': 'application/json'
      //   },
      // ).listen((event) {
      //   print('Received event: ${event.data}');
      //   if (event.data != null) {
      //     onMessageReceived(event.data.toString());
      //   }
      // }, onError: (error) {
      //   print('Error: $error');
      //   onErrorHandler(error);
      // }, onDone: () {
      //   if (onDone != null) onDone();
      // }, cancelOnError: true);

      // SSEClient.subscribeToSSE(
      //     method: SSERequestType.GET,
      //     url: 'https://192.168.0.147/internal/chat?user_message=$message',
      //     header: {
      //       // "Cookie":
      //       //     'jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6InRlc3QiLCJpYXQiOjE2NDMyMTAyMzEsImV4cCI6MTY0MzgxNTAzMX0.U0aCAM2fKE1OVnGFbgAU_UVBvNwOMMquvPY8QaLD138; Path=/; Expires=Wed, 02 Feb 2022 15:17:11 GMT; HttpOnly; SameSite=Strict',
      //       // "Accept": "text/event-stream",
      //       // "Cache-Control": "no-cache",
      //     }).listen(
      //   (event) {
      //     print('Id: ' + (event.id ?? ""));
      //     print('Event: ' + (event.event ?? ""));
      //     print('Data: ' + (event.data ?? ""));
      //     if (event.data != null) {
      //       onMessageReceived(event.data.toString());
      //     }
      //   },
      // );

    
      // final uri = Uri.parse(fullUrl);
      // final request = http.Request("POST", uri);
      // request.headers.addAll({
      //   "Accept": "text/event-stream",
      //   "Content-Type": "application/json",
      // });
      // request.body = jsonEncode({
      //   "message": message,
      //   "user_id": "ttm",
      //   "stream": true,
      // });

      // final response = await request.send();

      // response.stream
      //     .transform(utf8.decoder)
      //     .transform(const LineSplitter()) // 또는 `split('\n')` 직접 사용
      //     .listen((line) {
      //   if (line.startsWith('data:')) {
      //     final data = line.replaceFirst('data: ', '');
      //     print('>> $data');
      //     onMessageReceived(data);
      //   }
      // });

      //HTML5 EventSource 사용 (웹 환경에서만 사용 가능)
      final eventSource = html.EventSource(fullUrl, withCredentials: true);

      // 메시지 이벤트 리스너
      eventSource.onMessage.listen((event) {
        //print('웹 SSE 메시지 수신: ${event.data}');
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
