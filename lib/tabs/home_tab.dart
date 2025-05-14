import 'package:flutter/material.dart';
import 'package:speakai/widgets/page/home_page.dart';
import 'package:speakai/widgets/page/course_page.dart';
import 'package:speakai/widgets/chat_bot.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class HomeTab extends StatefulWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 5, 1, 34),
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
          indicatorWeight: 6.0, // Increase the thickness of the indicator
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(
            // Increase the font size for selected tab
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            // Increase the font size for unselected tabs
            fontSize: 14,
          ),
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
