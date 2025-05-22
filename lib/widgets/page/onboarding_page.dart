import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _pageIndex = 0;

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_onboarded', true);
    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  void _nextPage() {
    if (_pageIndex < 3) {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
    } else {
      _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: LinearProgressIndicator(
                value: (_pageIndex + 1) / 4,
                backgroundColor: Colors.grey[900],
                color: const Color(0xFF2563FF),
                minHeight: 6,
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _pageIndex = i),
                children: [
                  // 1. 목적 선택
                  _PurposePage(onNext: _nextPage),
                  // 2. 관심 주제 선택
                  _InterestPage(onNext: _nextPage),
                  // 3. 레벨 선택
                  _LevelPage(onNext: _nextPage),
                  // 4. 기존 마지막 페이지
                  _PlanReadyPage(onFinish: _finishOnboarding),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 1. 목적 선택 페이지
class _PurposePage extends StatefulWidget {
  final VoidCallback onNext;
  const _PurposePage({required this.onNext});

  @override
  State<_PurposePage> createState() => _PurposePageState();
}

class _PurposePageState extends State<_PurposePage> {
  final List<String> _purposes = [
    '✈️ 해외여행 또는 유학',
    '💻 이직 혹은 커리어 발전',
    '💬 외국인과 프리토킹',
    '✨ 자기계발',
    '👶 우리 아이와 영어로 대화하기',
    '🎯 기타',
  ];
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        const Text(
          '어떤 목적으로 영어 스피킹을 배우고 싶으세요?',
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: _purposes.map((p) => _PurposeTile(
              p,
              selected: _selected.contains(p),
              onTap: () {
                setState(() {
                  if (_selected.contains(p)) {
                    _selected.remove(p);
                  } else {
                    _selected.add(p);
                  }
                });
              },
            )).toList(),
          ),
        ),
        _NextButton(
          onNext: _selected.isNotEmpty ? widget.onNext : () {},
          label: '계속하기',
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _PurposeTile extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback? onTap;
  const _PurposeTile(this.text, {this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2563FF) : const Color(0xFF181C24),
          borderRadius: BorderRadius.circular(16),
          border: selected ? Border.all(color: Colors.white, width: 2) : null,
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 18)),
      ),
    );
  }
}

// 2. 관심 주제 선택 페이지 (여러 개 선택)
class _InterestPage extends StatefulWidget {
  final VoidCallback onNext;
  const _InterestPage({required this.onNext});

  @override
  State<_InterestPage> createState() => _InterestPageState();
}

class _InterestPageState extends State<_InterestPage> {
  final List<Map<String, String>> _interests = [
    {'emoji': '💻', 'label': '커리어'},
    {'emoji': '✈️', 'label': '여행'},
    {'emoji': '🎬', 'label': '영화/음악'},
    {'emoji': '🍸', 'label': '친목'},
    {'emoji': '🗽', 'label': '문화'},
    {'emoji': '💌', 'label': '연애'},
    {'emoji': '🛍️', 'label': '쇼핑'},
    {'emoji': '🥑', 'label': '음식'},
    {'emoji': '🏡', 'label': '가족'},
  ];
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        const Text(
          '관심있는 주제를 모두 선택해주세요',
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          '관심있는 주제를 3가지 이상 선택해주세요. 내게 꼭 맞는 코스를 추천해드릴게요!',
          style: TextStyle(color: Colors.white, fontSize: 15),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: _interests.map((item) => _InterestTile(
                item['emoji']!,
                item['label']!,
                selected: _selected.contains(item['label']),
                onTap: () {
                  setState(() {
                    if (_selected.contains(item['label'])) {
                      _selected.remove(item['label']);
                    } else {
                      _selected.add(item['label']!);
                    }
                  });
                },
              )).toList(),
            ),
          ),
        ),
        _NextButton(
          onNext: _selected.length >= 3 ? widget.onNext : () {},
          label: '계속하기',
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _InterestTile extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  const _InterestTile(this.emoji, this.label, {this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2563FF) : const Color(0xFF181C24),
          borderRadius: BorderRadius.circular(16),
          border: selected ? Border.all(color: Colors.white, width: 2) : null,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}

// 3. 레벨 선택 페이지 (1개만 선택)
class _LevelPage extends StatefulWidget {
  final VoidCallback onNext;
  const _LevelPage({required this.onNext});

  @override
  State<_LevelPage> createState() => _LevelPageState();
}

class _LevelPageState extends State<_LevelPage> {
  int? _selectedIndex;

  final List<Map<String, dynamic>> _levels = [
    {
      'level': '레벨 0',
      'desc': '몇 개의 단어를 알고 있습니다.',
      'icon': Icons.spa,
      'color': Colors.amber,
    },
    {
      'level': '레벨 1',
      'desc': '기본적인 단계입니다. 자기 소개를 할 수 있고, 간단한 질문에 대답할 수 있습니다.',
      'icon': Icons.spa,
      'color': Colors.teal,
    },
    {
      'level': '레벨 2',
      'desc': '일상적인 표현들을 이해할 수 있습니다. 하루 일과나 저의 배경에 대해 설명할 수 있습니다.',
      'icon': Icons.spa,
      'color': Colors.cyan,
    },
    {
      'level': '레벨 3',
      'desc': '저의 생각, 꿈, 목표에 대해 설명할 수 있습니다. 여행 중 발생하는 복잡한 상황도 대처할 수 있습니다.',
      'icon': Icons.spa,
      'color': Colors.blue,
    },
    {
      'level': '레벨 4',
      'desc': '원어민과 이야기하는 데 어려움이 없습니다. 업무에 관련된 복잡한 내용도 이해할 수 있습니다.',
      'icon': Icons.spa,
      'color': Colors.purple,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        const Text(
          '내 현재 영어 실력은 어디에 가까운가요?',
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: _levels.length,
            itemBuilder: (context, i) {
              final item = _levels[i];
              return GestureDetector(
                onTap: () => setState(() => _selectedIndex = i),
                child: _LevelTile(
                  item['level'],
                  item['desc'],
                  item['icon'],
                  item['color'],
                  selected: _selectedIndex == i,
                ),
              );
            },
          ),
        ),
        _NextButton(
          onNext: _selectedIndex != null ? widget.onNext : () {},
          label: '계속하기',
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _LevelTile extends StatelessWidget {
  final String level;
  final String desc;
  final IconData icon;
  final Color color;
  final bool selected;
  const _LevelTile(this.level, this.desc, this.icon, this.color, {this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF2563FF) : const Color(0xFF181C24),
        borderRadius: BorderRadius.circular(16),
        border: selected ? Border.all(color: Colors.white, width: 2) : null,
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(level, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 4. 마지막: 맞춤 스터디 플랜
class _PlanReadyPage extends StatelessWidget {
  final Future<void> Function() onFinish;
  const _PlanReadyPage({required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 25),
        Center(
          child: Container(
            width: 180,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.blue[900],
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.person_pin_circle, size: 100, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 25),
        const Text(
          '맞춤 스터디 플랜이 준비되었습니다!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 25),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Color(0xFF181C24),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              const Text(
                '원어민처럼 말하기',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '코스 시작 레벨: 레벨 3',
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Row(
                    children: [
                      Icon(Icons.play_circle, color: Colors.yellow, size: 28),
                      SizedBox(width: 8),
                      Text('2,300+ 수업', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.format_quote, color: Colors.purple, size: 28),
                      SizedBox(width: 8),
                      Text('35,000+ 표현', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.grey),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '내게 필요한 내용을 배우세요:',
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: const [
                  Icon(Icons.flight, color: Colors.white),
                  SizedBox(width: 8),
                  Text('현지인처럼 여행 다니기', style: TextStyle(color: Colors.white)),
                ],
              ),
              SizedBox(height: 6),
              Row(
                children: const [
                  Icon(Icons.shopping_bag, color: Colors.white),
                  SizedBox(width: 8),
                  Text('아무지게 쇼핑하기', style: TextStyle(color: Colors.white)),
                ],
              ),
              SizedBox(height: 6),
              Row(
                children: const [
                  Icon(Icons.local_bar, color: Colors.white),
                  SizedBox(width: 8),
                  Text('친구들과 약속 잡을 때 쓰는 표현', style: TextStyle(color: Colors.white)),
                ],
              ),
            ],
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2563FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: onFinish,
              child: const Text(
                '지금 바로 들으러가기!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NextButton extends StatelessWidget {
  final VoidCallback onNext;
  final String label;
  const _NextButton({required this.onNext, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563FF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: onNext,
          child: Text(
            label,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}