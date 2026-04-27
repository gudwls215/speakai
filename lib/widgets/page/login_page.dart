import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speakai/widgets/page/onboarding_page.dart';
import 'package:speakai/config.dart';
import 'app_colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _idController = TextEditingController();
  final _pwController = TextEditingController();
  final _idFocus = FocusNode();
  final _pwFocus = FocusNode();
  bool _isLoading = false;
  bool _obscurePw = true;
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();
    _idFocus.addListener(() => setState(() {}));
    _pwFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _idController.dispose();
    _pwController.dispose();
    _idFocus.dispose();
    _pwFocus.dispose();
    super.dispose();
  }

  Future<void> _login() async {
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
        final expiresIn = data['expiresIn'] as int?;
        final user = data['user'];

        if (accessToken != null && refreshToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', accessToken);
          await prefs.setString('refresh_token', refreshToken);
          final loginTime = DateTime.now();
          final expiryTime = expiresIn != null
              ? loginTime.add(Duration(seconds: expiresIn))
              : loginTime.add(const Duration(hours: 1));
          await prefs.setString('token_expiry', expiryTime.toIso8601String());
          await prefs.setString('last_login', loginTime.toIso8601String());

          if (user != null) {
            await prefs.setString('user', jsonEncode(user));
            final isOnboarded = user['tutorOnboardYn'] == true;
            final currentChapter = user['tutorCurrentChapterId'] != null
                ? user['tutorCurrentChapterId'].toString()
                : '';
            await prefs.setString('current_chapter', currentChapter);
            await prefs.setInt('current_course', user['tutorCurrentCourseId'] ?? 0);
            await prefs.setBool('is_onboarded', isOnboarded);
          }
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
      _showError('로그인 실패', '아이디 또는 비밀번호를 확인하세요.');
    } catch (e) {
      _showError('오류', '네트워크 오류가 발생했습니다.\n$e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgElev,
        title: Text(title, style: const TextStyle(color: AppColors.text)),
        content: Text(msg, style: const TextStyle(color: AppColors.textSec)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  InputDecoration _dec(String hint, {Widget? suffix}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textTer, fontSize: 15),
        filled: true,
        fillColor: AppColors.bgElev,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        suffixIcon: suffix,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0, height: 320,
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -1.0),
                    radius: 0.9,
                    colors: [Color(0x3310B981), Color(0x0010B981)],
                    stops: [0, 0.7],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.bgElev,
                      foregroundColor: AppColors.text,
                      shape: const CircleBorder(
                          side: BorderSide(color: AppColors.border)),
                      minimumSize: const Size(40, 40),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 14),
                  ),
                  const SizedBox(height: 28),

                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.accent, Color(0xFF047857)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.27),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.graphic_eq,
                        color: Colors.white, size: 28),
                  ),

                  const SizedBox(height: 22),
                  const Text(
                    '다시 오신 걸\n환영합니다',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '어제 연습하던 대화, 그 자리에서 이어갈게요.',
                    style: TextStyle(
                        color: AppColors.textSec, fontSize: 13.5, height: 1.55),
                  ),
                  const SizedBox(height: 32),

                  const _Label('ID'),
                  TextField(
                    controller: _idController,
                    focusNode: _idFocus,
                    style: const TextStyle(color: AppColors.text, fontSize: 15),
                    decoration: _dec('아이디를 입력하세요'),
                    onSubmitted: (_) => _pwFocus.requestFocus(),
                  ),
                  const SizedBox(height: 16),

                  Row(children: [
                    const _Label('PASSWORD'),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: GestureDetector(
                        onTap: () {},
                        child: const Text('비밀번호 찾기',
                            style: TextStyle(
                                color: AppColors.accent, fontSize: 11)),
                      ),
                    ),
                  ]),
                  TextField(
                    controller: _pwController,
                    focusNode: _pwFocus,
                    obscureText: _obscurePw,
                    style: const TextStyle(color: AppColors.text, fontSize: 15),
                    decoration: _dec(
                      '••••••••',
                      suffix: IconButton(
                        icon: Icon(
                          _obscurePw
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppColors.textSec,
                          size: 18,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePw = !_obscurePw),
                      ),
                    ),
                    onSubmitted: (_) {
                      if (!_isLoading) _login();
                    },
                  ),

                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => setState(() => _rememberMe = !_rememberMe),
                    child: Row(children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: _rememberMe
                              ? AppColors.accent
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: _rememberMe
                                ? AppColors.accent
                                : AppColors.border,
                          ),
                        ),
                        child: _rememberMe
                            ? const Icon(Icons.check,
                                size: 13, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      const Text('로그인 상태 유지',
                          style: TextStyle(
                              color: AppColors.textSec, fontSize: 12.5)),
                    ]),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        textStyle: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                        elevation: 0,
                      ),
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text('로그인'),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Row(children: const [
                    Expanded(
                        child: Divider(color: AppColors.border, height: 1)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('또는',
                          style: TextStyle(
                              color: AppColors.textTer, fontSize: 11)),
                    ),
                    Expanded(
                        child: Divider(color: AppColors.border, height: 1)),
                  ]),
                  const SizedBox(height: 14),

                  Row(children: [
                    Expanded(
                      child: _SocialButton(
                        label: 'Apple로 계속하기',
                        bg: Colors.white,
                        fg: Colors.black,
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SocialButton(
                        label: 'Google로 계속하기',
                        bg: AppColors.bgElev,
                        fg: AppColors.text,
                        onTap: () {},
                      ),
                    ),
                  ]),
                  const SizedBox(height: 22),

                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('아직 계정이 없으신가요? ',
                            style: TextStyle(
                                color: AppColors.textSec, fontSize: 12.5)),
                        GestureDetector(
                          onTap: () {},
                          child: const Text('가입하기',
                              style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              )),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.textSec,
            fontSize: 10,
            letterSpacing: 1.2,
          ),
        ),
      );
}

class _SocialButton extends StatelessWidget {
  final String label;
  final Color bg, fg;
  final VoidCallback onTap;

  const _SocialButton({
    required this.label,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 48,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            elevation: 0,
            side: bg == AppColors.bgElev
                ? const BorderSide(color: AppColors.border)
                : BorderSide.none,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            textStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          onPressed: onTap,
          child: Text(label),
        ),
      );
}
