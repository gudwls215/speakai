import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speakai/providers/lesson_provider.dart';
import 'package:speakai/widgets/page/home_page.dart';
import 'package:speakai/widgets/page/course_page.dart';
import 'package:speakai/widgets/chat_bot.dart';
import 'package:speakai/utils/token_manager.dart';
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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1F2937),
          title: const Text(
            '로그아웃',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            '정말 로그아웃하시겠습니까?\n저장된 로그인 정보가 삭제됩니다.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '취소',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // 다이얼로그 닫기
                await _performLogout();
              },
              child: const Text(
                '로그아웃',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      
      // 서버에 로그아웃 요청 (refresh token 무효화)
      if (refreshToken != null) {
        try {
          final response = await http.post(
            Uri.parse('$apiBaseUrl/api/public/auth/logout'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': refreshToken}),
          );
          
          if (response.statusCode == 200) {
            print('Logout successful on server');
          } else {
            print('Logout failed on server: ${response.statusCode}');
          }
        } catch (e) {
          print('Logout request failed: $e');
          // 네트워크 오류여도 로컬 데이터는 삭제
        }
      }
      
      // 모든 로그인 관련 데이터 삭제
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      await prefs.remove('user');
      await prefs.remove('is_onboarded');
      await prefs.remove('current_chapter');
      await prefs.remove('current_course');
      await prefs.remove('token_expiry');
      await prefs.remove('last_login');
      
      if (mounted) {
        // 인트로 페이지로 이동하고 모든 이전 페이지 제거
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/intro',
          (route) => false,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('로그아웃되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그아웃 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () async {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => LessonListSheet(),
                );
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blueAccent, width: 2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    backgroundImage: NetworkImage('https://tutor.glotos.com/assets/avatar.png'),
                    radius: 22,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Container(
                  width: 200, // TabBar 전체 가로 넓이 제한
                  height: 36, // TabBar 전체 높이 제한
                  decoration: BoxDecoration(
                    color: Color(0xFF374151),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey[600]!, width: 1),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: false,
                    indicator: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorPadding: EdgeInsets.all(3),
                    dividerColor: Colors.transparent, // 가로선 제거
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey[300],
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: [
                      Tab(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.home, size: 14),
                              SizedBox(width: 3),
                              Text('홈'),
                            ],
                          ),
                        ),
                      ),
                      Tab(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.book, size: 14),
                              SizedBox(width: 3),
                              Text('코스'),
                            ],
                          ),
                        ),
                      ),
                    ],
                    overlayColor: MaterialStateProperty.all(Colors.transparent),
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _showLogoutDialog(),
              child: Icon(Icons.logout, color: Colors.white),
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
      final jwt = await TokenManager.getValidAccessToken();
      if (jwt == null) {
        // 토큰이 없거나 갱신 실패 시 로그인 페이지로 리다이렉트
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/intro', (route) => false);
        }
        return;
      }
      
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
    final jwt = await TokenManager.getValidAccessToken();
    print('Setting current course: $courseId with JWT: $jwt');
    if (jwt == null) {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/intro', (route) => false);
      }
      return;
    }
    
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
        // 첫 번째 챕터 ID 가져오기
        final detailResponse = await http.get(
          Uri.parse('$apiBaseUrl/api/public/site/apiGetCourseDetail/$courseId'),
          headers: {
            'Authorization': 'Bearer $jwt',
            'Content-Type': 'application/json',
          },
        );
        String? firstChapterId;
        if (detailResponse.statusCode == 200) {
          final List<dynamic> chapters = json.decode(detailResponse.body);
          if (chapters.isNotEmpty) {
            firstChapterId = chapters[0]['chapterId']?.toString();
          }
        }
        if (mounted) {
          // 선택한 코스 ID 저장
          prefs.setInt('current_course', int.parse(courseId));
          // 첫 번째 챕터 ID 저장
          if (firstChapterId != null) {
            prefs.setString('current_chapter', firstChapterId);
          }
          // 강의 상세정보 새로 불러오기
          await Provider.of<LessonProvider>(context, listen: false)
              .fetchLessons(context, forceReload: true);
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
                      leading: Container(
                        width: 80,
                        height: 80,
                        margin: EdgeInsets.only(right: 12), 
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[600]!, width: 1),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: lesson['thumbnail'] != null && lesson['thumbnail'].toString().isNotEmpty
                              ? Image.network(
                                  '$apiBaseUrl${lesson['thumbnail']}',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[700],
                                      child: Icon(
                                        Icons.image_not_supported,
                                        color: Colors.grey[400],
                                        size: 28,
                                      ),
                                    );
                                  },
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      color: Colors.grey[700],
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                  loadingProgress.expectedTotalBytes!
                                              : null,
                                          strokeWidth: 2,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  color: Colors.grey[700],
                                  child: Icon(
                                    Icons.school,
                                    color: Colors.grey[400],
                                    size: 28,
                                  ),
                                ),
                        ),
                      ),
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
