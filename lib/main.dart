import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:speakai/providers/chat_provider.dart';
import 'package:speakai/providers/free_talk_provider.dart';
import 'package:speakai/providers/lesson_provider.dart';
import 'package:speakai/widgets/page/intro_page.dart';
import 'package:speakai/widgets/page/login_page.dart';
import 'package:speakai/widgets/page/onboarding_page.dart';
import 'package:speakai/utils/token_manager.dart';
import 'tabs/home_tab.dart';
import 'tabs/free_talk_tab.dart';
import 'tabs/profile_tab.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:speakai/config.dart';

void main() {
  // 디버그 모드에서 위젯 경계선 표시
  //debugPaintSizeEnabled = true;
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

  Future<String> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    
    // TokenManager를 통해 유효한 Access Token 확인
    final accessToken = await TokenManager.getValidAccessToken();
    print('Access Token: $accessToken');
    
    if (accessToken == null) {
      print('No valid access token found, redirecting to intro page');
      return 'intro'; // 토큰이 없거나 갱신 실패 시 인트로 페이지로
    }
    
    // 온보딩 상태 체크
    final isOnboarded = prefs.getBool('is_onboarded') ?? false;
    if (!isOnboarded) {
      return 'onboarding'; // 온보딩이 안되어 있으면 온보딩 페이지로
    }
    
    return 'home'; // 모든 조건을 만족하면 홈으로
  }

  Future<void> _clearLoginData(SharedPreferences prefs) async {
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user');
    await prefs.remove('is_onboarded');
    await prefs.remove('token_expiry');
    await prefs.remove('last_login');
    await prefs.remove('current_chapter');
    await prefs.remove('current_course');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _checkLoginStatus(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // 로딩 중
          return const MaterialApp(
            home: Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: CircularProgressIndicator(color: Colors.blue),
              ),
            ),
            debugShowCheckedModeBanner: false,
          );
        }
        
        Widget initialPage;
        switch (snapshot.data!) {
          case 'home':
            initialPage = const MyHomePage(title: 'SpeakAI');
            break;
          case 'onboarding':
            initialPage = const OnboardingPage();
            break;
          case 'intro':
          default:
            print('Navigating to Intro Page');
            initialPage = const IntroPage();
            break;
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
          home: initialPage,
          debugShowCheckedModeBanner: false,
          routes: {
            '/home': (context) => const MyHomePage(title: 'SpeakAI'),
            '/intro': (context) => const IntroPage(),
            '/login': (context) => const LoginPage(),
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
