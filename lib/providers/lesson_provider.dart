import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // 추가

class LessonProvider with ChangeNotifier {
  List<Map<String, dynamic>> _lessons = [];
  bool _isLoading = false;
  String? currentChapterName;
  String? currentChapter;

  List<Map<String, dynamic>> get lessons => _lessons;
  bool get isLoading => _isLoading;

Future<void> fetchLessons(BuildContext? context, {bool forceReload = false}) async {
    print('fetchLessons called');
    print("_lessons: $_lessons");
    if (_lessons.isNotEmpty && !forceReload) return; // 이미 데이터를 로드한 경우 재호출 방지

    _isLoading = true;
    notifyListeners();
    print('Loading lessons...');

    // SharedPreferences에서 JWT 토큰 가져오기
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt_token') ?? '';
    final currentCourse = prefs.getInt('current_course') ?? 0;
    final currentChapterFromPrefs = prefs.getString('current_chapter') ?? '';
    print('Current Course: $currentCourse');
    currentChapter = currentChapterFromPrefs;
    print('JWT Token: $jwt');
    if (jwt.isEmpty) {
      print('JWT Token is empty');
      _isLoading = false;
      notifyListeners();
      // 로그인 페이지로 이동
      if (context != null) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
      return;
    }

    final Uri uri = Uri.parse(
        'https://192.168.0.147/api/public/site/apiGetCourseDetail/$currentCourse');

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $jwt',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      _lessons = data
          .map<Map<String, dynamic>>((item) => {
                'filePath': item['filePath'],
                'courseId': item['courseId'],
                'chapterId': item['chapterId'],
                'lessonId': item['lessonId'],
                'lessonName': item['lessonName'],
                'chapterName': item['chapterName'],
              })
          .toList();

      print("currentChapter = $currentChapter");
      // current_chapter에 해당하는 chapterName 저장
      final lesson = _lessons.firstWhere(
        (item) => item['chapterId'].toString() == currentChapter,
        orElse: () => {},
      );
      currentChapterName = lesson.isNotEmpty ? lesson['chapterName'] : null;
      print("currentChapterName = $currentChapterName");
    } else if (response.statusCode == 401) {
      // 인증 실패 시 반복 호출 방지 및 로그인 페이지로 이동
      print('Unauthorized: JWT 인증 실패');
      _lessons = [];
      if (context != null) {
        Navigator.of(context).pushReplacementNamed('/intro');
      }
    } else {
      print('Failed to load lessons');
    }

    _isLoading = false;
    notifyListeners();
  }

}
