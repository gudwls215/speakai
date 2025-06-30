import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speakai/config.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  List<dynamic> _courses = [];
  bool _isLoadingCourses = true;
  String? _courseError;
  int? _totalLessonStudyTimeMinutes;
  bool _isLoadingStudyTime = true;
  int? _completedSentenceCount;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
    _fetchTotalLessonStudyTime();
    _fetchCompletedSentenceCount();
  }

  // '말한 문장' 갯수 가져오기
  Future<void> _fetchCompletedSentenceCount() async {
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt_token') ?? '';
    final url =
        Uri.parse('$apiBaseUrl/api/public/site/apiGetTutorSentenceCompCount');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _completedSentenceCount = data['count'] as int?;
        });
      }
    } catch (e) {
      // 필요시 에러 처리
    }
  }

  Future<void> _fetchTotalLessonStudyTime() async {
    setState(() {
      _isLoadingStudyTime = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwt = prefs.getString('jwt_token') ?? '';
      final url =
          Uri.parse('$apiBaseUrl/api/public/site/apiGetTotalLessonStudyTime');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final totalSeconds = data['totalLessonStudyTime'] ?? 0;
        setState(() {
          _totalLessonStudyTimeMinutes = (totalSeconds / 60).floor();
          _isLoadingStudyTime = false;
        });
      } else if (response.statusCode == 401) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/intro');
        }
      } else {
        setState(() {
          _isLoadingStudyTime = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingStudyTime = false;
      });
    }
  }

  Future<void> _fetchCourses({int size = 3}) async {
    setState(() {
      _isLoadingCourses = true;
      _courseError = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwt = prefs.getString('jwt_token') ?? '';
      final url = Uri.parse('$apiBaseUrl/api/public/site/getCourseStatiList');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "page": "1",
          "size": size.toString(),
          "sort": "desc",
          "order": "",
          "currentClass": "ing"
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _courses = data['list'] ?? [];
          _isLoadingCourses = false;
        });
      } else if (response.statusCode == 401) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/intro');
        }
      } else {
        setState(() {
          _courseError = '코스 불러오기 실패: ${response.body}';
          _isLoadingCourses = false;
        });
      }
    } catch (e) {
      setState(() {
        _courseError = '네트워크 오류: $e';
        _isLoadingCourses = false;
      });
    }
  }

  void _showAllCoursesDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            constraints:
                const BoxConstraints(maxWidth: 500, maxHeight: 600), // 높이 제한 추가
            decoration: BoxDecoration(
              color: const Color(0xFF1E2133),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                // 스크롤 가능하게 감싸기
                child: _buildAllCoursesChapter(),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<List<dynamic>> _fetchCoursesList({int size = 3}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwt = prefs.getString('jwt_token') ?? '';
      final url = Uri.parse('$apiBaseUrl/api/public/site/getCourseStatiList');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "page": "1",
          "size": size.toString(),
          "sort": "desc",
          "order": "",
          "currentClass": "ing"
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['list'] ?? [];
      } else if (response.statusCode == 401) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
        Navigator.of(context).pushReplacementNamed('/intro');
        return [];
      } else {
        throw Exception('코스 불러오기 실패: ${response.body}');
      }
    } catch (e) {
      throw Exception('네트워크 오류: $e');
    }
  }

  Widget _buildAllCoursesChapter() {
    return FutureBuilder<List<dynamic>>(
      future: _fetchCoursesList(size: 100),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child:
                Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Text(
                snapshot.error.toString(),
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          );
        }
        final courses = snapshot.data ?? [];
        return FutureBuilder<int?>(
          future: SharedPreferences.getInstance()
              .then((prefs) => prefs.getInt('current_course')),
          builder: (context, idSnap) {
            final currentCourseId = idSnap.data;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '모든 코스',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (courses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(
                      child: Text(
                        '수강 중인 코스가 없습니다.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  )
                else
                  Column(
                    children: List.generate(courses.length, (idx) {
                      final item = courses[idx];
                      final courseId = item['courseId'];
                      final isInProgress = currentCourseId != null &&
                          courseId == currentCourseId;
                      return Column(
                        children: [
                          _buildCourseItem(
                            image: item['thumnail'] != null
                                ? '$apiBaseUrl${item['thumnail']}'
                                : '',
                            title: item['courseName'] ?? '',
                            instructors: '',
                            progress: (item['totalRate'] ?? 0) / 100.0,
                            isInProgress: isInProgress,
                          ),
                          if (idx != courses.length - 1)
                            const Divider(height: 1, color: Color(0xFF2A2E45)),
                        ],
                      );
                    }),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Color(0xFF1F2937),
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(backgroundImage: AssetImage('avatar.png')),
            Icon(Icons.settings, color: Colors.white),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  '당신의 학습 하이라이트',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // 상단 통계 카드 섹션
              Row(
                children: [
                  // 말한 문장 카드
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.chat_bubble_outline,
                      iconColor: Colors.purple.shade300,
                      title: '말한 문장',
                      value: '$_completedSentenceCount개',
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 공부한 시간 카드
                  Expanded(
                    child: _buildStudyTimeStatCard(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 어휘 및 표현 카드
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2133),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red.shade300,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.menu_book_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              '어휘 및 표현',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const Icon(
                          Icons.info_outline,
                          color: Colors.white54,
                          size: 24,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildCountItem('210', '신규'),
                        _buildCountItem('65', '학습 완료'),
                        _buildCountItem('3', '마스터 완료'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 북마크 및 저장 항목 섹션
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2133),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // _buildBookmarkItem(
                    //   icon: Icons.local_fire_department_outlined,
                    //   iconBgColor: Colors.grey.shade600,
                    //   title: '불꽃 기록부',
                    //   subtitle: '1일 1수업으로 불꽃 유지!',
                    // ),
                    // const Divider(height: 1, color: Colors.grey),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) =>
                                const BookmarkedSentencesSheet(),
                          );
                        },
                        child: _buildBookmarkItem(
                          icon: Icons.bookmark_outline,
                          iconBgColor: Colors.blue,
                          title: '보관한 표현',
                          subtitle: '두고두고 볼 나만의 표현 집합소!',
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: Colors.grey),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => const BookmarkedWordsSheet(),
                          );
                        },
                        child: _buildBookmarkItem(
                          icon: Icons.bookmark_outline,
                          iconBgColor: Colors.amber,
                          title: '보관한 단어',
                          subtitle: 'AI 코치와 함께 발음 연습하기!',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 수강 시작한 코스 섹션
              const SizedBox(height: 30),
              _buildCourseChapter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseChapter({int size = 3}) {
    return FutureBuilder<int?>(
      future: SharedPreferences.getInstance()
          .then((prefs) => prefs.getInt('current_course')),
      builder: (context, snapshot) {
        final currentCourseId = snapshot.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '수강 시작한 코스',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (size == 3)
                  TextButton(
                    onPressed: _showAllCoursesDialog,
                    child: const Text(
                      '모든 코스 보기',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E2133),
                borderRadius: BorderRadius.circular(16),
              ),
              child: _isLoadingCourses
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                          child:
                              CircularProgressIndicator(color: Colors.white)),
                    )
                  : _courseError != null
                      ? Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Center(
                            child: Text(
                              _courseError!,
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        )
                      : (_courses.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Center(
                                child: Text(
                                  '수강 중인 코스가 없습니다.',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                            )
                          : Column(
                              children: List.generate(_courses.length, (idx) {
                                final item = _courses[idx];
                                final courseId = item['courseId'];
                                final isInProgress = currentCourseId != null &&
                                    courseId == currentCourseId;
                                return Column(
                                  children: [
                                    _buildCourseItem(
                                      image: item['thumnail'] != null
                                          ? '$apiBaseUrl${item['thumnail']}'
                                          : '',
                                      title: item['courseName'] ?? '',
                                      instructors: '',
                                      progress:
                                          (item['totalRate'] ?? 0) / 100.0,
                                      isInProgress: isInProgress,
                                    ),
                                    if (idx != _courses.length - 1)
                                      const Divider(
                                          height: 1, color: Color(0xFF2A2E45)),
                                  ],
                                );
                              }),
                            )),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCourseItem({
    required String image,
    required String title,
    required String instructors,
    required double progress,
    bool isInProgress = false,
  }) {
    Widget profileImage;
    if (image.isNotEmpty) {
      profileImage = ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Image.network(
          image,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 80,
            height: 80,
            color: Colors.grey.shade800,
            child: const Icon(Icons.person, color: Colors.white, size: 40),
          ),
        ),
      );
    } else {
      profileImage = ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 80,
          height: 80,
          color: Colors.grey.shade800,
          child: const Icon(
            Icons.person,
            color: Colors.white,
            size: 40,
          ),
        ),
      );
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      leading: Stack(
        children: [
          profileImage,
          if (isInProgress)
            Positioned(
              bottom: 0,
              right: 0,
              left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Center(
                  child: Text(
                    '학습 중',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (instructors.isNotEmpty)
            Text(
              instructors,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
          if (instructors.isNotEmpty) const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade800,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          const SizedBox(height: 4),
          Text(
            '${(progress * 100).toInt()}% 완료',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
      trailing: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check,
          color: Colors.white,
          size: 24,
        ),
      ),
      isThreeLine: true,
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF23263A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 32),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // 예시: 공부한 시간 StatCard 추가
  Widget _buildStudyTimeStatCard() {
    return _buildStatCard(
      icon: Icons.timer,
      iconColor: Colors.teal.shade300,
      title: '공부한 시간',
      value:
          _isLoadingStudyTime ? '...' : '${_totalLessonStudyTimeMinutes ?? 0}분',
    );
  }

  Widget _buildCountItem(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildBookmarkItem({
    required IconData icon,
    required Color iconBgColor,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconBgColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 12,
        ),
      ),
    );
  }
}

// 북마크한 문장 리스트를 보여주는 BottomSheet 위젯
class BookmarkedSentencesSheet extends StatefulWidget {
  const BookmarkedSentencesSheet({Key? key}) : super(key: key);

  @override
  State<BookmarkedSentencesSheet> createState() =>
      _BookmarkedSentencesSheetState();
}

class _BookmarkedSentencesSheetState extends State<BookmarkedSentencesSheet> {
  List<dynamic> _bookmarks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchBookmarks();
  }

  Future<void> _fetchBookmarks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwt = prefs.getString('jwt_token') ?? '';
      final url =
          Uri.parse('$apiBaseUrl/api/public/site/apiTutorSentenceBookmarks');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          _bookmarks = json.decode(response.body);
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/intro');
        }
      } else {
        setState(() {
          _error = '불러오기 실패: ${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '네트워크 오류: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF23272F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                '보관한 표현',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : _error != null
                        ? Center(
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                          )
                        : _bookmarks.isEmpty
                            ? const Center(
                                child: Text(
                                  '보관한 표현이 없습니다.',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              )
                            : ListView.separated(
                                controller: scrollController,
                                itemCount: _bookmarks.length,
                                separatorBuilder: (_, __) => Divider(
                                  color: Colors.grey[800],
                                  height: 1,
                                ),
                                itemBuilder: (context, idx) {
                                  final item = _bookmarks[idx];
                                  return ListTile(
                                    title: Text(
                                      item['sentence'] ?? '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: (item['translate'] ?? '')
                                            .toString()
                                            .isNotEmpty
                                        ? Text(
                                            item['translate'],
                                            style: const TextStyle(
                                              color: Colors.blueAccent,
                                              fontSize: 14,
                                            ),
                                          )
                                        : null,
                                    trailing: Text(
                                      (item['createdAt'] ?? '')
                                          .toString()
                                          .split('T')
                                          .first,
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  );
                                },
                              ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// 단어 북마크 리스트를 보여주는 BottomSheet 위젯
class BookmarkedWordsSheet extends StatefulWidget {
  const BookmarkedWordsSheet({Key? key}) : super(key: key);

  @override
  State<BookmarkedWordsSheet> createState() => _BookmarkedWordsSheetState();
}

class _BookmarkedWordsSheetState extends State<BookmarkedWordsSheet> {
  List<dynamic> _bookmarks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchBookmarks();
  }

  Future<void> _fetchBookmarks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwt = prefs.getString('jwt_token') ?? '';
      final url =
          Uri.parse('$apiBaseUrl/api/public/site/apiTutorWordBookmarks');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          _bookmarks = json.decode(response.body);
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/intro');
        }
      } else {
        setState(() {
          _error = '불러오기 실패: ${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '네트워크 오류: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF23272F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                '보관한 단어',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : _error != null
                        ? Center(
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                          )
                        : _bookmarks.isEmpty
                            ? const Center(
                                child: Text(
                                  '보관한 단어가 없습니다.',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              )
                            : ListView.separated(
                                controller: scrollController,
                                itemCount: _bookmarks.length,
                                separatorBuilder: (_, __) => Divider(
                                  color: Colors.grey[800],
                                  height: 1,
                                ),
                                itemBuilder: (context, idx) {
                                  final item = _bookmarks[idx];
                                  return ListTile(
                                    title: Text(
                                      item['word'] ?? '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: (item['translate'] ?? '')
                                            .toString()
                                            .isNotEmpty
                                        ? Text(
                                            item['translate'],
                                            style: const TextStyle(
                                              color: Colors.blueAccent,
                                              fontSize: 14,
                                            ),
                                          )
                                        : null,
                                    trailing: Text(
                                      (item['createdAt'] ?? '')
                                          .toString()
                                          .split('T')
                                          .first,
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  );
                                },
                              ),
              ),
            ],
          ),
        );
      },
    );
  }
}
