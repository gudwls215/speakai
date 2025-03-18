import 'package:flutter/material.dart';

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
      backgroundColor: const Color.fromARGB(255, 52, 39, 61), // Set the background color to dark
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 52, 39, 61),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              backgroundImage: AssetImage('assets/avatar.png'), // Replace with your avatar image
            ),
            Icon(Icons.notifications, color: Colors.white),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          labelColor: Colors.white, // Set the label color to white
          unselectedLabelColor: Colors.grey, // Set the unselected label color to grey
          tabs: const [
            Tab(text: '홈'),
            Tab(text: '코스'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHomePage(),
          Center(child: Text('Course Page', style: TextStyle(color: Colors.white))),
        ],
      ),
      bottomNavigationBar: _buildChatBotInput(),
    );
  }

  Widget _buildHomePage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0), // Add more horizontal padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('다음 수업 바로가기 >'),
            _buildNextLessonCard(),
            _buildSectionTitle('점프인 레슨'),
            _buildLessonCard('Word Smart', '꼭 알아야 하는 실전 위주 영단어!', Icons.school),
            _buildLessonCard('Native Speakers\' Idioms', '네이티브가 실제 쓰는 숙어 표현', Icons.language),
            _buildLessonCard('English Grammar', '영어 문법의 기초부터 심화까지', Icons.book),
            _buildSectionTitle('추천 코스'),
            _buildLessonCard('Daily English', '매일 10분씩 영어회화 능력 향상', Icons.access_time),
            _buildLessonCard('Business English', '비즈니스 상황에서 사용하는 영어 표현', Icons.work), 
          ],
        ),
      ),
    );
  }

  Widget _buildNextLessonCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0), // Add vertical padding to separate sections
      child: Card(
        color: Colors.grey[900], // Set the card color to dark grey
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Add padding inside the card
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '무료',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
              Icon(Icons.mic, color: Colors.pink, size: 50),
              SizedBox(height: 16),
              Text('여기가 영어 101 수업인가요?', style: TextStyle(color: Colors.white, fontSize: 18)),
              Text('Is this English 101?', style: TextStyle(color: Colors.grey, fontSize: 14)),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {},
                child: Text('시작하기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildLessonCard(String title, String subtitle, IconData icon) {
    return Card(
      color: Colors.grey[900], // Set the card color to dark grey
      child: ListTile(
        leading: Icon(icon, color: Colors.orange),
        title: Text(title, style: TextStyle(color: Colors.white)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey)),
      ),
    );
  }

  Widget _buildChatBotInput() {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0), // Add left, right, and bottom padding
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (BuildContext context) {
              return DraggableScrollableSheet(
                expand: false,
                initialChildSize: 1.0,
                builder: (BuildContext context, ScrollController scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24.0),
                        topRight: Radius.circular(24.0),
                      ),
                    ),
                    child: ListView(
                      controller: scrollController,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Chat History',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        // Add your chat history widgets here
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(color: Colors.blueAccent),
          ),
          child: Row(
            children: [
              Icon(Icons.chat_bubble, color: Colors.blue),
              SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  '무엇이든 물어보세요',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              Icon(Icons.mic, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}