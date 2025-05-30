import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speakai/providers/lesson_provider.dart';
import 'package:speakai/widgets/page/pronunciation_page.dart';
import 'package:speakai/widgets/chapter_title.dart';
import 'package:speakai/widgets/category_card.dart';
import 'package:speakai/widgets/next_lesson_card.dart';
import 'package:speakai/widgets/page/voca_multiple_page.dart';
import 'package:speakai/widgets/recommended_course.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isInit = false;
  List<Map<String, dynamic>> _recommendedCourses = [];
  bool _isLoadingRecommend = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      Provider.of<LessonProvider>(context, listen: false)
          .fetchLessons(context, forceReload: true);
      _fetchRecommendedCourses();
      _isInit = true;
    }
  }

  Future<void> _fetchRecommendedCourses() async {
    setState(() {
      _isLoadingRecommend = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwt = prefs.getString('jwt_token') ?? '';
      final url = Uri.parse(
          'https://192.168.0.147/api/public/site/apiRecommendCoursesByOnboarding');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _recommendedCourses = data.cast<Map<String, dynamic>>();
          _isLoadingRecommend = false;
        });
      } else {
        setState(() {
          _recommendedCourses = [];
          _isLoadingRecommend = false;
        });
      }
    } catch (e) {
      setState(() {
        _recommendedCourses = [];
        _isLoadingRecommend = false;
      });
    }
  }

  Future<Map<String, String>?> getCurrentLessonCourseChapter() async {
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt_token') ?? '';
    final currentCourseId = prefs.getInt('current_course')?.toString() ?? '';
    final currentChapterId = prefs.getString('current_chapter') ?? '';

    if (currentCourseId.isEmpty || currentChapterId.isEmpty) {
      return null;
    }

    try {
      final url = Uri.parse(
          'https://192.168.0.147/api/public/site/apiGetCourseDetail/$currentCourseId');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> chapters = json.decode(response.body);
        final chapter = chapters.firstWhere(
          (item) => item['chapterId'].toString() == currentChapterId,
          orElse: () => null,
        );
        if (chapter != null) {
          return {
            'lessonId': chapter['lessonId']?.toString() ?? '',
            'courseId': chapter['courseId']?.toString() ?? '',
            'chapterId': chapter['chapterId']?.toString() ?? '',
          };
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final lessonProvider = Provider.of<LessonProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChapterTitle('다음 수업 바로가기 >'),
          NextLessonCard(lessonProvider.currentChapterName ?? '',
              lessonProvider.currentChapter ?? ''),
          ChapterTitle('점프인 레슨'),
          GestureDetector(
            onTap: () async {
              // ▼▼▼ current_chapter와 일치하는 챕터 정보로 VocaMultiple 이동 ▼▼▼
              final result = await getCurrentLessonCourseChapter();
              if (result == null ||
                  result['lessonId']!.isEmpty ||
                  result['courseId']!.isEmpty ||
                  result['chapterId']!.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('코스 또는 챕터 정보가 없습니다.')),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VocaMultiple(
                    result['courseId']!,
                    result['lessonId']!,
                    result['chapterId']!,
                    "호흡기 관리",
                  ),
                ),
              );
            },
            child: const CategoryCard(
                'Word Smart', '꼭 알아야 하는 실전 위주 영단어!', Icons.school),
          ),
          GestureDetector(
            onTap: () async {
              // ▼▼▼ current_chapter와 일치하는 챕터 정보로 PronunciationAssessment 이동 ▼▼▼
              final result = await getCurrentLessonCourseChapter();
              if (result == null ||
                  result['lessonId']!.isEmpty ||
                  result['courseId']!.isEmpty ||
                  result['chapterId']!.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('코스 또는 챕터 정보가 없습니다.')),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PronunciationAssessment(
                    result['courseId']!,
                    result['lessonId']!,
                    result['chapterId']!,
                    '',
                  ),
                ),
              );
            },
            child: const CategoryCard(
                'pronunciation assessment', '수업한 내용 복습과 발음 평가!', Icons.school),
          ),
          ChapterTitle('추천 코스'),
          // CategoryCard(
          //     'Daily English', '매일 10분씩 영어회화 능력 향상', Icons.access_time),
          // CategoryCard('Business English', '비즈니스 상황에서 사용하는 영어 표현', Icons.work),
          // 추천 코스 API 결과 표시
          if (_isLoadingRecommend)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_recommendedCourses.isNotEmpty)
            ..._recommendedCourses.map((course) => RecommendedCourse(
                  course['course_name'] ?? '',
                  course['intro'] ?? '',
                  course['id'] ?? '',
                  Icons.star,
                )),
        ],
      ),
    );
  }
}
