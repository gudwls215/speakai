import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speakai/widgets/page/login_page.dart';

// Design tokens — from hifi-mocks.jsx
const _bg = Color(0xFF0A0B0D);
const _bgElev = Color(0xFF16181C);
const _bgElev2 = Color(0xFF1E2127);
const _border = Color(0x14FFFFFF);
const _text = Color(0xFFFFFFFF);
const _textSec = Color(0x9EFFFFFF);
const _accent = Color(0xFF10B981);
const _accentSoft = Color(0x2410B981);
const _good = Color(0xFF22C55E);
const _mid = Color(0xFFF59E0B);
const _bad = Color(0xFFEF4444);

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHero(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  children: [
                    _ChatbotCard(),
                    const SizedBox(height: 10),
                    Row(
                      children: const [
                        Expanded(child: _PronCard()),
                        SizedBox(width: 10),
                        Expanded(child: _VocabCard()),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _RoleplayCard(),
                    const SizedBox(height: 10),
                    Row(
                      children: const [
                        Expanded(child: _LevelCard()),
                        SizedBox(width: 10),
                        Expanded(child: _PersonalizedCard()),
                      ],
                    ),
                  ],
                ),
              ),
              _buildCta(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.8),
                radius: 0.95,
                colors: [Color(0x3310B981), Colors.transparent],
                stops: [0, 0.7],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 70, 22, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'MOBILE ENGLISH · 2026',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  letterSpacing: 1.4,
                  color: _accent,
                ),
              ),
              const SizedBox(height: 24),
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    letterSpacing: -0.8,
                  ),
                  children: [
                    TextSpan(text: '당신을\n', style: TextStyle(color: _text)),
                    TextSpan(
                        text: '말하게 하는\n',
                        style: TextStyle(color: _accent)),
                    TextSpan(text: '영어 앱', style: TextStyle(color: _text)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'AI 튜터와 대화하며 발음 · 표현 · 어휘를 한 번에.\n내 레벨에 맞춘 학습을 지금 시작해보세요.',
                style: TextStyle(
                  fontSize: 13.5,
                  color: _textSec,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCta(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 32, 22, 44),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
                shadowColor: const Color(0x6610B981),
              ).copyWith(
                elevation: WidgetStateProperty.all(10),
                shadowColor: WidgetStateProperty.all(const Color(0x4410B981)),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
              child: const Text('무료로 시작하기'),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('skip_intro', true);
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              }
            },
            child: const Text(
              '다시 보지 않기',
              style: TextStyle(
                fontSize: 15.5,
                color: Color(0x59FFFFFF),
                decoration: TextDecoration.underline,
                decorationColor: Color(0x40FFFFFF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 01 · CHATBOT
class _ChatbotCard extends StatelessWidget {
  const _ChatbotCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 220),
      decoration: BoxDecoration(
        color: _bgElev,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('01 · CHATBOT',
                    style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 9,
                        color: _accent,
                        letterSpacing: 1.2)),
                const SizedBox(height: 6),
                const Text('끊김 없는 AI 대화',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _text)),
                const SizedBox(height: 4),
                const Text('24시간, 내 레벨에 맞춰 대화.',
                    style: TextStyle(
                        fontSize: 12, color: _textSec),
                    maxLines: 2),
                const SizedBox(height: 120),
              ],
            ),
          ),
          Positioned(
            bottom: -8,
            right: -8,
            child: Container(
              width: 190,
              height: 150,
              decoration: BoxDecoration(
                color: _bgElev2,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x4D000000),
                      blurRadius: 24,
                      offset: Offset(-8, -8))
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                            color: _accent, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'What do you usually do on weekends?',
                          style: TextStyle(fontSize: 10.5, color: _text, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                          color: _accent,
                          borderRadius: BorderRadius.circular(10)),
                      child: const Text('I usually…',
                          style: TextStyle(
                              fontSize: 10.5, color: Colors.white)),
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

// 02 · PRONUNCIATION
class _PronCard extends StatelessWidget {
  const _PronCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 160),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bgElev,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('02 · PRONUN.',
                  style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 9,
                      color: _accent,
                      letterSpacing: 1.2)),
              SizedBox(height: 6),
              Text('발음 교정',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _text)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('유창성 68',
                  style: TextStyle(fontSize: 10, color: _textSec)),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: 4,
                  child: Stack(
                    children: [
                      Container(color: _bgElev2),
                      FractionallySizedBox(
                        widthFactor: 0.68,
                        child: Container(color: _mid),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 3,
                runSpacing: 3,
                children: const [
                  _WordChip('Dr', _good),
                  _WordChip('Vargas', _bad),
                  _WordChip('feels', _bad),
                  _WordChip('gets', _bad),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WordChip extends StatelessWidget {
  final String word;
  final Color color;
  const _WordChip(this.word, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(3)),
      child: Text(word,
          style: const TextStyle(
              fontSize: 9, color: Colors.white, fontWeight: FontWeight.w500)),
    );
  }
}

// 03 · VOCAB
class _VocabCard extends StatelessWidget {
  const _VocabCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 160),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bgElev,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('03 · VOCAB',
                  style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 9,
                      color: _accent,
                      letterSpacing: 1.2)),
              SizedBox(height: 6),
              Text('단어 연습',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _text)),
            ],
          ),
          Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  color: _accentSoft,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _accent),
                ),
                child: const Text('around',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _accent)),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  color: _bgElev2,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('along',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: _text)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 04 · ROLEPLAY
class _RoleplayCard extends StatelessWidget {
  const _RoleplayCard();

  static const _scenes = ['☕ Café', '✈ Airport', '🏥 Clinic', '💼 Interview', '🏨 Hotel'];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 130),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgElev,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('04 · ROLEPLAY',
              style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  color: _accent,
                  letterSpacing: 1.2)),
          const SizedBox(height: 6),
          const Text('상황별 대화',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: _text)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _scenes
                .map((t) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _bgElev2,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: _border),
                      ),
                      child: Text(t,
                          style: const TextStyle(
                              fontSize: 11, color: _text)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// 05 · LEVEL
class _LevelCard extends StatelessWidget {
  const _LevelCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_accent, Color(0xFF1E40AF)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('05 · LEVEL',
              style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  color: Colors.white,
                  letterSpacing: 1.2)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('A1–C2',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.0)),
              SizedBox(height: 2),
              Text('5분 진단',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

// 06 · YOU
class _PersonalizedCard extends StatelessWidget {
  const _PersonalizedCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bgElev,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('06 · YOU',
              style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  color: _accent,
                  letterSpacing: 1.2)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('맞춤 학습',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _text)),
              SizedBox(height: 4),
              Text('자동 편성',
                  style: TextStyle(fontSize: 11, color: _textSec)),
            ],
          ),
        ],
      ),
    );
  }
}
