import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:speakai/providers/chat_provider.dart';
import 'package:speakai/providers/free_talk_provider.dart';
import 'package:speakai/providers/lesson_provider.dart';
import 'package:speakai/widgets/page/intro_page.dart';
import 'tabs/home_tab.dart';
import 'tabs/free_talk_tab.dart';
import 'tabs/review_tab.dart';
import 'tabs/challenge_tab.dart';
import 'tabs/profile_tab.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FreeTalkProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => LessonProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> _isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    print('Token: $token');
    // 토큰이 null이 아니고, (필요하다면) 유효성 검사 추가
    return token != null && token.isNotEmpty;
    //return false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isLoggedIn(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // 로딩 중
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            debugShowCheckedModeBanner: false,
          );
        }
        return MaterialApp(
          title: 'SpeakAI',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: Colors.black,
            useMaterial3: true,
          ),
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            dragDevices: const {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
            },
          ),
          home: snapshot.data! 
              ? const MyHomePage(title: 'SpeakAI') 
              : const IntroPage(),
          debugShowCheckedModeBanner: false,
          routes: {
            '/home': (context) => const MyHomePage(title: 'SpeakAI'),
            '/intro': (context) => const IntroPage(),
          },
        );
      },
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
    // ReviewTab(),
    // ChallengeTab(),
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
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.bolt, color: Colors.grey),
          //   label: '리뷰',
          // ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.emoji_events, color: Colors.grey),
          //   label: '챌린지',
          // ),
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
