import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speakai/widgets/page/onboarding_page.dart';
import 'package:speakai/config.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    setState(() => _isLoading = true);
    final id = _idController.text.trim();
    final pw = _pwController.text.trim();

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/public/auth/getJwtAccessToken'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id, 'password': pw}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final accessToken = data['accessToken'];
        final refreshToken = data['refreshToken'];
        final expiresIn = data['expiresIn'] as int?; // seconds
        final user = data['user'];
        
        if (accessToken != null && refreshToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', accessToken);
          await prefs.setString('refresh_token', refreshToken);
          
          // 토큰 만료 시간 계산 및 저장
          final loginTime = DateTime.now();
          final expiryTime = expiresIn != null 
              ? loginTime.add(Duration(seconds: expiresIn))
              : loginTime.add(const Duration(hours: 1)); // 기본 1시간
          await prefs.setString('token_expiry', expiryTime.toIso8601String());
          await prefs.setString('last_login', loginTime.toIso8601String());
          
          if (user != null) {
            await prefs.setString('user', jsonEncode(user));
            // tutorOnboardYn 값으로 온보딩 여부 저장
            final isOnboarded = user['tutorOnboardYn'] == true;
            final currentChapter = user['tutorCurrentChapterId'] != null ? user['tutorCurrentChapterId'].toString() : '';
            await prefs.setString('current_chapter', currentChapter);
            await prefs.setInt('current_course', user['tutorCurrentCourseId'] ?? 0);
            await prefs.setBool('is_onboarded', isOnboarded);
            print('Login successful - Access Token expires: ${expiryTime.toIso8601String()}');
          }
          print(mounted);
          if (!mounted) return;
          final isOnboarded = prefs.getBool('is_onboarded') ?? false;
          if (!isOnboarded) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const OnboardingPage()),
            );
          } else {
            Navigator.of(context).pushReplacementNamed('/home');
          }
          return;
        }
      }
      // 실패 처리
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('로그인 실패'),
          content: const Text('아이디 또는 비밀번호를 확인하세요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('오류'),
          content: Text('네트워크 오류가 발생했습니다.\n$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),
            Center(
              child: CircleAvatar(
                radius: 64,
                backgroundImage: NetworkImage('https://tutor.glotos.com/assets/avatar.png'),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              '로그인',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  TextField(
                    controller: _idController,
                    decoration: InputDecoration(
                      hintText: '아이디',
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintStyle: const TextStyle(color: Colors.grey),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onSubmitted: (_) {
                      FocusScope.of(context)
                          .nextFocus(); // 아이디 입력 후 엔터 시 비밀번호로 이동
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _pwController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: '비밀번호',
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintStyle: const TextStyle(color: Colors.grey),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onSubmitted: (_) {
                      if (!_isLoading) _login(); // 비밀번호 입력 후 엔터 시 로그인
                    },
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              '로그인',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    '돌아가기',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 15,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
