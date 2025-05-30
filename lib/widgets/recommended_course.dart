import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RecommendedCourse extends StatelessWidget {
  final String title;
  final String subtitle;
  final dynamic course; // course 전체 객체 전달
  final IconData icon;

  const RecommendedCourse(this.title, this.subtitle, this.course, this.icon,
      {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16.0),
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => CourseDetailSheet(courseId: course),
        );
      },
      child: Card(
        color: Colors.grey[900],
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.grey),
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 18)),
                    Text(subtitle,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 하단에서 보여줄 코스 상세 리스트
class CourseDetailSheet extends StatefulWidget {
  final dynamic courseId;
  const CourseDetailSheet({Key? key, required this.courseId}) : super(key: key);

  @override
  State<CourseDetailSheet> createState() => _CourseDetailSheetState();
}

class _CourseDetailSheetState extends State<CourseDetailSheet> {
  List<dynamic> _details = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCourseDetail();
  }

  Future<void> _setTutorCurrentCourse(
      BuildContext context, String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt_token') ?? '';
    try {
      final response = await http.post(
        Uri.parse(
            'https://192.168.0.147/api/public/site/apiSetTutorCurrentCourse?courseId=$courseId'),
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        if (mounted) {
          prefs.setInt('current_course', int.parse(courseId));
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('코스가 성공적으로 선택되었습니다.')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('코스 선택에 실패했습니다: ${response.body}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('네트워크 오류가 발생했습니다.')),
        );
      }
    }
  }

  Future<void> _fetchCourseDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // 인증토큰 추가
      final prefs = await SharedPreferences.getInstance();
      final jwt = prefs.getString('jwt_token') ?? '';
      final url = Uri.parse(
          'https://192.168.0.147/api/public/site/apiGetCourseDetail/${widget.courseId}');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          _details = json.decode(response.body);
          _isLoading = false;
        });
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
                '코스 상세',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              // ▼▼▼ 추가: 강의 선택하기 버튼 ▼▼▼
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _isLoading
                        ? null
                        : () async {
                            await _setTutorCurrentCourse(
                                context, widget.courseId.toString());
                          },
                    child: const Text('강의 선택하기'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white))
                    : _error != null
                        ? Center(
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                          )
                        : _details.isEmpty
                            ? const Center(
                                child: Text(
                                  '코스 상세 정보가 없습니다.',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              )
                            : ListView.separated(
                                controller: scrollController,
                                itemCount: _details.length,
                                separatorBuilder: (_, __) => Divider(
                                  color: Colors.grey[800],
                                  height: 1,
                                ),
                                itemBuilder: (context, idx) {
                                  final item = _details[idx];
                                  return ListTile(
                                    title: Text(
                                      item['chapterName'] ?? '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: Text(
                                      item['lessonName'] ?? '',
                                      style: const TextStyle(
                                        color: Colors.blueAccent,
                                        fontSize: 14,
                                      ),
                                    ),
                                    trailing: Icon(Icons.play_circle_fill,
                                        color: Colors.white),
                                    onTap: () {
                                      // 필요시 상세 이동/영상 재생 등 구현
                                    },
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
