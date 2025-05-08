import 'package:flutter/material.dart';
import 'package:speakai/widgets/page/free_talk_page.dart';

class FreeTalkProvider extends ChangeNotifier {
  final ValueNotifier<Map<String, List<TalkMessage>>> messages = ValueNotifier(<String, List<TalkMessage>>{});
  final ValueNotifier<String> intent = ValueNotifier('');
  final ValueNotifier<String> userId = ValueNotifier('');
  final ValueNotifier<String> userRole = ValueNotifier('');
  final ValueNotifier<String> aiRole = ValueNotifier('');
  final ValueNotifier<String> postId = ValueNotifier('');

  void add(TalkMessage message, String key) {
    print("22 getMessagesNotifier key: $key, messages: ${messages.value}");
    if (messages.value[key] == null) {
      messages.value[key] = []; // 키가 없으면 초기화
    }
    messages.value[key]!.add(message); // 리스트 업데이트
    messages.notifyListeners(); // 상태 변경 알림
  }

  void messageUpdate(String message, String key) {
    if (messages.value[key] == null) {
      return; // 키가 없으면 업데이트 하지 않음
    }
    final updatedMessages = List<TalkMessage>.from(messages.value[key]!);
    updatedMessages[updatedMessages.length - 1] = TalkMessage(
      text: updatedMessages.last.text + message,
      isUser: false,
      postId: key,
    );
    messages.value = {...messages.value, key: updatedMessages}; // 리스트 업데이트
  }

  void intentUpdate(String intent) {
    this.intent.value = intent; // intent 업데이트
  }

  void userIdUpdate(String userId) {
    this.userId.value = userId; // userId 업데이트
  }

  ValueNotifier<List<TalkMessage>> getMessagesNotifier(String key) {
    print("getMessagesNotifier key: $key, messages: ${messages.value}");
    if (messages.value[key] == null) {
      // 빈 리스트를 반환할 때도 명시적으로 타입을 지정
      return ValueNotifier<List<TalkMessage>>([]);
    }
    return ValueNotifier<List<TalkMessage>>(messages.value[key]!);
  }

  String get getIntent {
    return intent.value;
  }

  String get getUserId {
    return userId.value;
  }

  String get getuserRole {
    return userRole.value;
  }

  String get getAiRole {
    return aiRole.value;
  }

  bool get isEmpty {
    return messages.value.isEmpty;
  }

  bool get isNotEmpty {
    return messages.value.isNotEmpty;
  }

  String getCurrentPostId() {
    return postId.value;
  }

  bool isLastMessageUser(String key) {
    if (messages.value[key] == null) {
      return false; // 리스트가 비어있을 때는 false 반환
    } else {
      return messages.value[key]?.last.isUser ?? false;
    }
  }

  int get getLength {
    return messages.value.length;
  }

  TalkMessage getMessage(int index, String key) {
    if (messages.value[key] == null || index >= messages.value[key]!.length) {
      throw Exception("Invalid index or key");
    }
    return messages.value[key]![index];
  }
}
