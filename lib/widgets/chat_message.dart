import 'package:flutter/material.dart';

// 채팅 메시지 클래스
class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool isError;
  final Widget? widget;

  const ChatMessage({
    Key? key,
    required this.text,
    this.isUser = false,
    this.isError = false,
    this.widget,
  }) : super(key: key);

  Widget _buildUserMessage() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.only(bottom: 16.0, right: 8.0),
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: Colors.blue.shade800,
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildBotMessage() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 8),
        CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.smart_toy, color: Colors.white),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: 16.0),
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget != null
        ? widget!
        : isUser
            ? _buildUserMessage()
            : _buildBotMessage();
  }
}
