import 'package:flutter/material.dart';
import 'package:speakai/widgets/chat_message.dart';

class ChatProvider extends ChangeNotifier {
  final ValueNotifier<List<ChatMessage>> messages = ValueNotifier([]);
  final ValueNotifier<String> intent = ValueNotifier(''); 
  final ValueNotifier<String> userId = ValueNotifier(''); 
  final ValueNotifier<String> gameType = ValueNotifier(''); 

  void add(ChatMessage message) {
    messages.value = [...messages.value, message]; // 리스트 업데이트
  }

  void messageUpdate(String message) {
    final updatedMessages = List<ChatMessage>.from(messages.value);
    updatedMessages[updatedMessages.length - 1] = ChatMessage(
      text: updatedMessages.last.text + message,
      isUser: false,
    );
    messages.value = updatedMessages; // 리스트 업데이트
  }

  void intentUpdate(String intent) {
    this.intent.value = intent; // intent 업데이트
  }

  void userIdUpdate(String userId) {
    this.userId.value = userId; // userId 업데이트
  }

  void gameTypeUpdate(String gameType) {
    this.gameType.value = gameType; // gameType 업데이트
  }

  String get getIntent {
    return intent.value;
  }

  String get getUserId {
    return userId.value;
  }

  String get getGameType {
    return gameType.value;
  }

  bool get isEmpty {
    return messages.value.isEmpty;
  }

  bool get isNotEmpty {
    return messages.value.isNotEmpty;
  }

  bool get isLastMessageUser {
    return messages.value.last.isUser;
  }

  int get getLength {
    return messages.value.length;
  }

  ChatMessage getMessage(int index) {
    return messages.value[index];
  }

  ChatMessage get lastMessage {
    if (messages.value.isNotEmpty) {
      return messages.value.last;
    } else {
      throw Exception("No messages available");
    }
  }

  void removeLastMessage() {
    if (messages.value.isNotEmpty) {
      final updatedMessages = List<ChatMessage>.from(messages.value);
      updatedMessages.removeLast();
      messages.value = updatedMessages; // 리스트 업데이트
    }
  }
}