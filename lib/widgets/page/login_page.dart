import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speakai/widgets/page/onboarding_page.dart';
import 'package:speakai/widgets/page/intro_page.dart';
import 'package:speakai/config.dart';
import 'package:speakai/utils/url_helper.dart';
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

  Widget _fieldWithGlow({required bool focused, required Widget child}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: focused
            ? [BoxShadow(color: AppColors.accent.withOpacity(0.13), blurRadius: 0, spreadRadius: 3)]
            : [],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 700;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // 전체 화면 그라디언트 (데스크탑/모바일 공통)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.85),
                    radius: 1.1,
                    colors: [Color(0x6610B981), Color(0x0010B981)],
                    stops: [0, 1.0],
                  ),
                ),
              ),
            ),
          ),
          if (isDesktop)
            Center(
              child: Container(
                width: 460,
                margin: const EdgeInsets.symmetric(vertical: 32),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height - 64,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgElev.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 60,
                      offset: const Offset(0, 24),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: _buildContent(context),
                ),
              ),
            )
          else
            _buildContent(context),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
            child: GestureDetector(
              onTap: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const IntroPage()),
              ),
              child: Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.bgElev,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.arrow_back_ios_new,
                        size: 11, color: AppColors.textSec),
                    SizedBox(width: 6),
                    Text('인트로 보기',
                        style: TextStyle(
                            color: AppColors.textSec,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                        // brand mark — speech bubble character
                        SizedBox(
                          width: 116,
                          height: 116,
                          child: SvgPicture.string(
                            '''<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
                              <defs>
                                <linearGradient id="bubbleFill" x1="0" y1="0" x2="0" y2="1">
                                  <stop offset="0" stop-color="#ffffff"/>
                                  <stop offset="1" stop-color="#d8fff0"/>
                                </linearGradient>
                                <linearGradient id="handFill" x1="0" y1="0" x2="0" y2="1">
                                  <stop offset="0" stop-color="#34d399"/>
                                  <stop offset="1" stop-color="#059669"/>
                                </linearGradient>
                                <radialGradient id="hi" cx="35%" cy="30%" r="55%">
                                  <stop offset="0" stop-color="#ffffff" stop-opacity="0.8"/>
                                  <stop offset="1" stop-color="#ffffff" stop-opacity="0"/>
                                </radialGradient>
                              </defs>
                              <path d="M100 22c-42 0-72 25-72 56 0 19 12 36 30 47l-8 24c-1 3 2 5 5 4l28-15c5 1 11 2 17 2 42 0 72-25 72-56s-30-62-72-62z"
                                fill="url(#bubbleFill)" stroke="#10b981" stroke-width="6"/>
                              <path d="M100 22c-42 0-72 25-72 56 0 19 12 36 30 47l-8 24c-1 3 2 5 5 4l28-15c5 1 11 2 17 2 42 0 72-25 72-56s-30-62-72-62z"
                                fill="url(#hi)"/>
                              <ellipse cx="78" cy="78" rx="9" ry="13" fill="#0d9b6a"/>
                              <ellipse cx="122" cy="78" rx="9" ry="13" fill="#0d9b6a"/>
                              <circle cx="80" cy="74" r="3" fill="#fff"/>
                              <circle cx="124" cy="74" r="3" fill="#fff"/>
                              <g transform="translate(112 110)">
                                <path d="M-2 0 c-4 4 -6 12 -2 22 c4 8 14 14 22 12 c8 -2 12 -10 10 -18 c-2 -8 -10 -14 -18 -16 c-6 -2 -10 -2 -12 0z"
                                  fill="url(#handFill)"/>
                                <rect x="-4" y="-26" width="9" height="30" rx="4.5" fill="url(#handFill)"/>
                                <rect x="-4" y="-26" width="9" height="6" rx="3" fill="#0d9b6a" opacity="0.4"/>
                              </g>
                            </svg>''',
                            width: 116,
                            height: 116,
                          ),
                        ),

                        const SizedBox(height: 18),
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                              height: 1.18,
                            ),
                            children: [
                              TextSpan(text: '말하고, 듣고,\n'),
                              TextSpan(
                                text: '매일 늘어나는',
                                style: TextStyle(color: AppColors.accent),
                              ),
                              TextSpan(text: ' 영어'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'AI 튜터와의 대화 · 발음 교정 · 맞춤 단어 학습을 한 곳에서.',
                          style: TextStyle(
                              color: AppColors.textSec, fontSize: 13.5, height: 1.55),
                        ),
                        const SizedBox(height: 28),

                        // ID field
                        const _Label('ID'),
                        _fieldWithGlow(
                          focused: _idFocus.hasFocus,
                          child: TextField(
                            controller: _idController,
                            focusNode: _idFocus,
                            style: const TextStyle(color: AppColors.text, fontSize: 15),
                            decoration: _dec('아이디를 입력하세요'),
                            onSubmitted: (_) => _pwFocus.requestFocus(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // PW field
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
                        _fieldWithGlow(
                          focused: _pwFocus.hasFocus,
                          child: TextField(
                            controller: _pwController,
                            focusNode: _pwFocus,
                            obscureText: _obscurePw,
                            style: const TextStyle(color: AppColors.text, fontSize: 15),
                            decoration: _dec(
                              '••••••••',
                              suffix: IconButton(
                                icon: Icon(
                                  _obscurePw ? Icons.visibility_off : Icons.visibility,
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

                        // CTA
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
                            ).copyWith(
                              shadowColor: WidgetStatePropertyAll(
                                  AppColors.accent.withOpacity(0.27)),
                              elevation: const WidgetStatePropertyAll(12),
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

                        // divider
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

                        // social buttons (disabled)
                        Row(children: [
                          Expanded(
                            child: _SocialButton(
                              label: 'Apple로 계속하기',
                              bg: Colors.white.withOpacity(0.08),
                              fg: AppColors.textTer,
                              onTap: null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SocialButton(
                              label: 'Google로 계속하기',
                              bg: AppColors.bgElev.withOpacity(0.5),
                              fg: AppColors.textTer,
                              onTap: null,
                            ),
                          ),
                        ]),
                        const SizedBox(height: 22),

                        // signup link
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('아직 계정이 없으신가요? ',
                                  style: TextStyle(
                                      color: AppColors.textSec, fontSize: 12.5)),
                              GestureDetector(
                                onTap: () => openExternalUrl(
                                    'https://lms.glotos.com/auth/join/terms'),
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
                  const SizedBox(height: 28),
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
  final VoidCallback? onTap;

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
            disabledBackgroundColor: bg,
            disabledForegroundColor: fg,
            elevation: 0,
            side: const BorderSide(color: AppColors.border),
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
