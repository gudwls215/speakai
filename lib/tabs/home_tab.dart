import 'package:flutter/material.dart';
import 'package:speakai/widgets/home_page.dart';
import 'package:speakai/widgets/course_page.dart';
import 'package:speakai/widgets/chat_bot.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class HomeTab extends StatefulWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _text = "음성을 입력하세요...";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 52, 39, 61),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 52, 39, 61),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(backgroundImage: AssetImage('avatar.png')),
            Icon(Icons.notifications, color: Colors.white),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: '홈'),
            Tab(text: '코스'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          HomePage(),
          CoursePage(),
        ],
      ),
      bottomNavigationBar: ChatBotInput(),
    );
  }
}
