import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speakai/providers/lesson_provider.dart';
import 'package:speakai/widgets/page/home_page.dart';
import 'package:speakai/widgets/page/course_page.dart';
import 'package:speakai/widgets/chat_bot.dart';
import 'package:speakai/config.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Color(0xFF1F2937),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () async {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => LessonListSheet(),
                );
              },
              child: CircleAvatar(backgroundImage: AssetImage('avatar.png')),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 150.0),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.blue, // Keep the blue indicator
                  indicatorWeight: 3.0, // Adjust the thickness of the indicator
                  indicatorSize: TabBarIndicatorSize
                      .label, // Make the indicator fit the label
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white,
                  labelStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  tabs: const [
                    Tab(text: '홈'),
                    Tab(text: '코스'),
                  ],
                  overlayColor: MaterialStateProperty.all(
                      Colors.transparent), // Remove the white underline
                  labelPadding: EdgeInsets.symmetric(
                      horizontal:
                          4.0), // Reduce horizontal padding between tabs
                ),
              ),
            ),
            GestureDetector(
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear(); // 모든 저장 정보 초기화
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('저장된 정보가 초기화되었습니다.')),
                );
              },
              child: Icon(Icons.notifications, color: Colors.white),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          HomePage(),
          CoursePage(),
        ],
      ),
      bottomNavigationBar: ChatBotInput(),
    );
  }
}

class LessonListSheet extends StatefulWidget {
  @override
  State<LessonListSheet> createState() => _LessonListSheetState();
}

class _LessonListSheetState extends State<LessonListSheet> {
  List<Map<String, dynamic>> lessons = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchLessons();
  }

  Future<void> fetchLessons() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwt = prefs.getString('jwt_token') ?? '';
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/public/site/apiGetCourseList'),
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          lessons = data.cast<Map<String, dynamic>>();
          isLoading = false;
        });
      } else {
        setState(() {
          error = '강의 목록을 불러오지 못했습니다.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = '네트워크 오류가 발생했습니다.';
        isLoading = false;
      });
    }
  }

  Future<void> setTutorCurrentCourse(String courseId) async {
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
          // 선택한 코스 ID 저장
          prefs.setInt('current_course', int.parse(courseId));
          // 강의 상세정보 새로 불러오기
          await Provider.of<LessonProvider>(context, listen: false).fetchLessons(context, forceReload: true);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('코스가 성공적으로 선택되었습니다.')),
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
          SnackBar(content: Text('네트워크 오류가 발생했습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF23272F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '강의 선택',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          if (isLoading)
            Expanded(
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else if (error != null)
            Expanded(
              child: Center(
                child: Text(
                  error!,
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            )
          else if (lessons.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  '강의가 없습니다.',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: lessons.length,
                itemBuilder: (context, index) {
                  final lesson = lessons[index];
                  final courseId = lesson['courseId']?.toString() ?? '';
                  return Card(
                    color: Color(0xFF1F2937),
                    elevation: 2,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      onTap: () {
                        if (courseId.isNotEmpty) {
                          setTutorCurrentCourse(courseId);
                        }
                      },
                      title: Text(
                        lesson['courseName'] ?? '',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            [
                              lesson['category1Name'],
                              lesson['category2Name'],
                              if (lesson['category3Name'] != null)
                                lesson['category3Name']
                            ]
                                .where(
                                    (e) => e != null && e.toString().isNotEmpty)
                                .join(' > '),
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 13),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '교수: ${lesson['lecturerName'] ?? ''}  |  학기: ${lesson['semesterName'] ?? ''}',
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 13),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '수강생: ${lesson['studentCounts'] ?? 0}명',
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 12),
                          ),
                        ],
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
