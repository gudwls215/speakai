import 'package:flutter/material.dart';
import 'package:speakai/providers/chat_provider.dart';
import 'tabs/home_tab.dart';
import 'tabs/free_talk_tab.dart';
import 'tabs/review_tab.dart';
import 'tabs/challenge_tab.dart';
import 'tabs/profile_tab.dart';
import 'package:provider/provider.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: ChangeNotifierProvider(  // ChangeNotifierProvider를 통해 변화에 대해 구독(하나만 구독 가능)
        create: (BuildContext context) => ChatProvider(), // count_provider.dart
        child: const MyHomePage(title: 'Flutter Demo Home Page') // home.dart // child 하위에 모든 것들은 CountProvider에 접근 할 수 있다.
     )
     
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    HomeTab(),
    FreeTalkTab(),
    ReviewTab(),
    ChallengeTab(),
    ProfileTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        unselectedItemColor: Colors.grey,
        selectedItemColor: Colors.blue,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Colors.grey),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people, color: Colors.grey),
            label: '프리톡',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bolt, color: Colors.grey),
            label: '리뷰',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events, color: Colors.grey),
            label: '챌린지',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, color: Colors.grey),
            label: '프로필',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}