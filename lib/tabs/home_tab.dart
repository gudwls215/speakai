import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
        backgroundColor: Color(0xFF1F2937),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(backgroundImage: AssetImage('avatar.png')),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 150.0), 
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.blue, // Keep the blue indicator
                  indicatorWeight: 3.0, // Adjust the thickness of the indicator
                  indicatorSize: TabBarIndicatorSize
                      .label, // Make the indicator fit the label
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white,
                  labelStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  tabs: const [
                    Tab(text: '홈'),
                    Tab(text: '코스'),
                  ],
                  overlayColor: MaterialStateProperty.all(
                      Colors.transparent), // Remove the white underline
                  labelPadding: EdgeInsets.symmetric(
                      horizontal:
                          4.0), // Reduce horizontal padding between tabs
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.notifications, color: Colors.white),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('jwt_token'); // 'key'를 원하는 값으로 변경
                // 필요하다면 setState 또는 알림 추가
              },
            ),
            
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
