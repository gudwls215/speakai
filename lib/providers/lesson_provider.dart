import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LessonProvider with ChangeNotifier {
  List<Map<String, dynamic>> _lessons = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get lessons => _lessons;
  bool get isLoading => _isLoading;

  Future<void> fetchLessons() async {
    if (_lessons.isNotEmpty) return; // 이미 데이터를 로드한 경우 재호출 방지

    _isLoading = true;
    notifyListeners();

    final Uri uri = Uri.parse('https://192.168.0.147/internal/course/courses')
        .replace(queryParameters: {'course': "1"});

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _lessons = List<Map<String, dynamic>>.from(data['metadatas']);
    } else {
      print('Failed to load lessons');
    }

    _isLoading = false;
    notifyListeners();
  }
}