import 'package:flutter/material.dart';
import 'package:speakai/widgets/chat_message.dart';

class ChatProvider extends ChangeNotifier {
  List<ChatMessage> messages = [];

  void add(ChatMessage message) {
    messages.add(message);
    notifyListeners();
  }

  bool get isEmpty {
    return messages.isEmpty;
  }

  bool get isNotEmpty {
    return messages.isNotEmpty;
  }

  void messageUpdate(String message) {
    messages[messages.length - 1] = ChatMessage(
      text: messages.last.text + message,
      isUser: false,
    );
    notifyListeners();
  }

  bool get isLastMessageUser {
    return messages.last.isUser;
  }

  int get getLength {
    return messages.length;
  }

  ChatMessage getMessage(int index) {
    return messages[index];
  }

}
