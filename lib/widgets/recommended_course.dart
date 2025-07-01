import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speakai/config.dart';

class RecommendedCourse extends StatefulWidget {
  final String title;
  final String subtitle;
  final dynamic course; // course 전체 객체 전달
  final IconData icon;

  const RecommendedCourse(this.title, this.subtitle, this.course, this.icon,
      {Key? key})
      : super(key: key);

  @override
  State<RecommendedCourse> createState() => _RecommendedCourseState();
}

class _RecommendedCourseState extends State<RecommendedCourse> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() {
          _isHovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
        });
      },
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => CourseDetailSheet(courseId: widget.course),
          );
        },
        onTapDown: (_) {
          _animationController.forward();
        },
        onTapUp: (_) {
          _animationController.reverse();
        },
        onTapCancel: () {
          _animationController.reverse();
        },
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: Card(
                  color: _isHovered ? Colors.grey[800] : Colors.grey[900],
                  elevation: _isHovered ? 8 : 4,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: _isHovered ? Colors.blueAccent : Colors.grey,
                      width: _isHovered ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.0),
                      boxShadow: _isHovered
                          ? [
                              BoxShadow(
                                color: Colors.blueAccent.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              )
                            ]
                          : null,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            child: CircleAvatar(
                              backgroundColor: _isHovered ? Colors.blueAccent : Colors.blue,
                              child: Icon(widget.icon, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: _isHovered ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                Text(
                                  widget.subtitle,
                                  style: TextStyle(
                                    color: _isHovered ? Colors.grey[300] : Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
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
      BuildContext context, String courseId, String? firstChapterId) async {
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt_token') ?? '';
    try {
      final response = await http.post(
        Uri.parse(
            '$apiBaseUrl/api/public/site/apiSetTutorCurrentCourse?courseId=$courseId'),
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        if (mounted) {
          prefs.setInt('current_course', int.parse(courseId));
          if (firstChapterId != null) {
            prefs.setString('current_chapter', firstChapterId);
          }
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
          '$apiBaseUrl/api/public/site/apiGetCourseDetail/${widget.courseId}');
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
              // 강의 선택하기 버튼
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
                            String? firstChapterId;
                            if (_details.isNotEmpty) {
                              firstChapterId =
                                  _details[0]['chapterId']?.toString();
                            }
                            await _setTutorCurrentCourse(context,
                                widget.courseId.toString(), firstChapterId);
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
