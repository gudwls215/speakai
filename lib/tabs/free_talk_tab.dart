import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speakai/widgets/page/free_talk_page.dart';
import 'package:speakai/config.dart';

class FreeTalkTab extends StatefulWidget {
  const FreeTalkTab({Key? key}) : super(key: key);

  @override
  State<FreeTalkTab> createState() => _FreeTalkTabState();
}

class _FreeTalkTabState extends State<FreeTalkTab> {
  List<dynamic> _posts = [];
  bool _isLoading = true;
  String? _error;
  int _selectedCategory = 0; // 0: 트렌딩, 1: 신규, 2: 탑 차트

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

    Future<void> _fetchPosts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwt = prefs.getString('jwt_token') ?? '';
      final dio = Dio();

      // endpoint 하나로 통일
      String endpoint = '$apiBaseUrl/api/public/site/apiGetTutorFreeTalk';
      String type;
      switch (_selectedCategory) {
        case 1:
          type = 'new';
          break;
        case 2:
          type = 'top';
          break;
        case 0:
        default:
          type = 'trending';
      }

      final response = await dio.get(
        endpoint,
        queryParameters: {'type': type}, // type 파라미터 추가
        options: Options(
          headers: {'Authorization': 'Bearer $jwt'},
        ),
      );
      setState(() {
        _posts = response.data is List ? response.data : [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '데이터를 불러오지 못했습니다.';
        _isLoading = false;
      });
    }
  }

  void _onCategoryTap(int idx) {
    if (_selectedCategory != idx) {
      setState(() {
        _selectedCategory = idx;
      });
      _fetchPosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          children: [
            const Text(
              'Community',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Topics',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 24,
              ),
            ),
          ],
        ),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.history, color: Colors.white),
          //   onPressed: () {},
          // ),
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const FavoritePostsPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ...카테고리 칩 등 기존 코드...
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _onCategoryTap(0),
                    child: _buildCategoryChip(
                      icon: Icons.local_fire_department,
                      label: '트렌딩',
                      isSelected: _selectedCategory == 0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _onCategoryTap(1),
                    child: _buildCategoryChip(
                      icon: Icons.access_time,
                      label: '신규',
                      isSelected: _selectedCategory == 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _onCategoryTap(2),
                    child: _buildCategoryChip(
                      icon: Icons.bar_chart,
                      label: '탑 차트',
                      isSelected: _selectedCategory == 2,
                      hasDropdown: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Text(_error!,
                            style: TextStyle(color: Colors.white)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: _posts.length,
                        itemBuilder: (context, index) {
                          final post = _posts[index];
                          return PostCard(
                            profileEmoji: post['profileEmoji'] ?? '🗣️',
                            username: post['username'] ?? '',
                            title: post['title'] ?? '',
                            userRole: post['userRole'] ?? '',
                            aiRole: post['aiRole'] ?? '',
                            description: post['description'] ?? '',
                            engagementCount:
                                post['engagementCount']?.toString() ?? '',
                            postId: post['id']?.toString() ?? '',
                            isFavorite: post['favorite'],
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await showModalBottomSheet<Map<String, String>>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const CreateScenarioBottomSheet(),
          );

          if (result != null) {
            // 테스트하기 버튼 결과 처리
            print('User Role: ${result['userRole']}');
            print('AI Role: ${result['aiRole']}');
            print('Description: ${result['description']}');

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FreeTalkMessage(
                  title: '나만의 시나리오',
                  emoji: '🎨',
                  userRole: result['userRole']!,
                  aiRole: result['aiRole']!,
                  description: result['description']!,
                  postId: DateTime.now().millisecondsSinceEpoch.toString(),
                ),
              ),
            );
          } else {
            // 공유하기가 성공적으로 완료된 경우 바텀시트에서 Navigator.pop(context)만 호출되므로,
            // 여기서 리스트를 새로고침
            await _fetchPosts();
          }
        },
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('나만의 시나리오 만들기'),
      ),
    );
  }

  Widget _buildCategoryChip({
    required IconData icon,
    required String label,
    required bool isSelected,
    bool hasDropdown = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.grey.shade700 : Colors.grey.shade900,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          if (hasDropdown) ...[
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 16,
            ),
          ],
        ],
      ),
    );
  }
}

class PostCard extends StatefulWidget {
  final String profileEmoji;
  final String username;
  final String title;
  final String userRole;
  final String aiRole;
  final String description;
  final String engagementCount;
  final String postId;
  final bool isFavorite;

  const PostCard({
    Key? key,
    required this.profileEmoji,
    required this.username,
    required this.title,
    required this.description,
    required this.engagementCount,
    required this.userRole,
    required this.aiRole,
    required this.postId,
    required this.isFavorite,
  }) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite; // 초기값을 widget에서 받아옴
  }

  Future<void> _toggleFavorite() async {
    final bool newFavorite = !_isFavorite; // 현재 상태의 반대값을 서버에 전송
    setState(() {
      _isFavorite = newFavorite;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwt = prefs.getString('jwt_token') ?? '';
      final dio = Dio();
      // 관심 등록/해제 API 호출
      final response = await dio.post(
        '$apiBaseUrl/api/public/site/apiToggleFavoriteTalk',
        data: {
          'talkId': widget.postId,
          'favorite': newFavorite, // 반전된 값 전송
        },
        options: Options(headers: {'Authorization': 'Bearer $jwt'}),
      );
      if (response.statusCode != 200) {
        // 실패 시 상태 복구
        setState(() {
          _isFavorite = !newFavorite;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('관심 등록 처리에 실패했습니다.')),
        );
      }
    } catch (e) {
      setState(() {
        _isFavorite = !newFavorite;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('네트워크 오류로 관심 등록 처리에 실패했습니다.')),
      );
    }
  }

  void _showPostDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PostDetailBottomSheet(
        profileEmoji: widget.profileEmoji,
        username: widget.username,
        title: widget.title,
        userRole: widget.userRole,
        aiRole: widget.aiRole,
        description: widget.description,
        engagementCount: widget.engagementCount,
        postId: widget.postId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPostDetails(context),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        color: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFF374151),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        widget.profileEmoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.username,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.red : Colors.white,
                    ),
                    onPressed: _toggleFavorite,
                  ),
                ],
              ),
              if (widget.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  widget.description,
                  style: TextStyle(
                    color: Colors.grey.shade300,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (widget.engagementCount.isNotEmpty) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    widget.engagementCount,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class CreateScenarioBottomSheet extends StatefulWidget {
  const CreateScenarioBottomSheet({Key? key}) : super(key: key);

  @override
  State<CreateScenarioBottomSheet> createState() =>
      _CreateScenarioBottomSheetState();
}

class _CreateScenarioBottomSheetState extends State<CreateScenarioBottomSheet> {
  final TextEditingController _userRoleController = TextEditingController();
  final TextEditingController _aiRoleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final List<String> _emojiOptions = [
    '🗣️',
    '👩‍🎓',
    '👨‍💻',
    '🧑‍🏫',
    '🦸',
    '🦸‍♀️',
    '🧑‍🎤',
    '🧑‍🚀',
    '🧑‍🍳',
    '🧑‍🎨',
    '🧑‍🔬',
    '🧑‍⚕️'
  ];
  String _selectedEmoji = '🗣️';

  @override
  void dispose() {
    _userRoleController.dispose();
    _aiRoleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final userRole = _userRoleController.text.trim();
    final aiRole = _aiRoleController.text.trim();
    final description = _descriptionController.text.trim();

    if (userRole.isNotEmpty && aiRole.isNotEmpty && description.isNotEmpty) {
      Navigator.pop(context, {
        'userRole': userRole,
        'aiRole': aiRole,
        'description': description,
        'profileEmoji': _selectedEmoji, // 선택한 이모지 전달
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 필드를 입력해주세요.')),
      );
    }
  }

  Future<void> _onSharePressed() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    final jwt = prefs.getString('jwt_token') ?? '';
    if (userString != null) {
      try {
        final userMap = json.decode(userString);
        final nickname = userMap['nickname'];

        final title = _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim().split('\n').first
            : '';
        final userRole = _userRoleController.text.trim();
        final aiRole = _aiRoleController.text.trim();
        final description = _descriptionController.text.trim();
        final profileEmoji = _selectedEmoji; // 사용자 선택값 사용

        // TutorFreeTalkEntity에 맞게 파라미터 구성
        final params = {
          "username": nickname,
          "title": title,
          "userRole": userRole,
          "aiRole": aiRole,
          "description": description,
          "profileEmoji": profileEmoji,
        };

        final dio = Dio();
        final response = await dio.post(
          '$apiBaseUrl/api/public/site/apiInsertTutorFreeTalk',
          data: params,
          options: Options(
            headers: {'Authorization': 'Bearer $jwt'},
          ),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('공유가 완료되었습니다.')),
          );
          Navigator.pop(context); // 바텀시트 닫기
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('공유 실패: ${response.data}')),
          );
        }
      } catch (e) {
        print('user 파싱 오류 또는 요청 실패: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('공유 중 오류가 발생했습니다.')),
        );
      }
    } else {
      print('user 값 없음');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('user 값 없음')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag indicator
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '나만의 시나리오 만들기',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(color: Color(0xFF333333)),
          // ▼▼▼ 이모지 선택 UI 추가 ▼▼▼
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _emojiOptions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final emoji = _emojiOptions[idx];
                  final isSelected = emoji == _selectedEmoji;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedEmoji = emoji;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue[700] : Colors.grey[800],
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.blue, width: 2)
                            : null,
                      ),
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      child: Text(
                        emoji,
                        style: TextStyle(
                          fontSize: 24,
                          color: isSelected ? Colors.white : Colors.grey[300],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Input fields
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // User Role
                TextField(
                  controller: _userRoleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: '나의 역할',
                    labelStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // AI Role
                TextField(
                  controller: _aiRoleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'AI의 역할',
                    labelStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Description
                TextField(
                  controller: _descriptionController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: '상황 및 대화 주제',
                    labelStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Submit button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '테스트하기',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _onSharePressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '공유하기',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Add this new class for the bottom sheet
class PostDetailBottomSheet extends StatelessWidget {
  final String profileEmoji;
  final String username;
  final String title;
  final String userRole;
  final String aiRole;
  final String description;
  final String engagementCount;
  final String postId;

  const PostDetailBottomSheet({
    Key? key,
    required this.profileEmoji,
    required this.username,
    required this.title,
    required this.description,
    required this.engagementCount,
    required this.userRole,
    required this.aiRole,
    required this.postId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag indicator
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Post header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFF374151),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      profileEmoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      username,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // IconButton(
                //   icon: const Icon(Icons.favorite_border, color: Colors.white),
                //   onPressed: () {},
                // ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF333333)),
          // Post content
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // My role
                ListTile(
                  leading: const Icon(
                    Icons.person,
                    color: Colors.grey,
                  ),
                  title: Text(
                    '나의 역할',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  subtitle: Text(
                    userRole,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                // Assistant role
                ListTile(
                  leading: const Icon(
                    Icons.smart_toy,
                    color: Colors.grey,
                  ),
                  title: Text(
                    'AI의 역할',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  subtitle: Text(
                    aiRole,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                // Situation
                ListTile(
                  leading: const Icon(
                    Icons.image,
                    color: Colors.grey,
                  ),
                  title: Text(
                    '상황 및 대화 주제',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  subtitle: Text(
                    description,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
          // Report link
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '게시물에 문제가 있나요? ',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    TextSpan(
                      text: '신고하기',
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final result =
                          await showModalBottomSheet<Map<String, String>>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => EditScenarioBottomSheet(
                          userRole: userRole,
                          aiRole: aiRole,
                          description: description,
                        ),
                      );
                      if (result != null) {
                        // 수정된 데이터 처리 (예: 화면 갱신, 서버 전송 등)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('시나리오가 수정되었습니다.')),
                        );
                        // 필요하다면 setState 또는 상위 콜백으로 데이터 전달
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '수정',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FreeTalkMessage(
                            title: title,
                            emoji: profileEmoji,
                            userRole: userRole,
                            aiRole: aiRole,
                            description: description,
                            postId: postId,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '대화 시작',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EditScenarioBottomSheet extends StatefulWidget {
  final String userRole;
  final String aiRole;
  final String description;

  const EditScenarioBottomSheet({
    Key? key,
    required this.userRole,
    required this.aiRole,
    required this.description,
  }) : super(key: key);

  @override
  State<EditScenarioBottomSheet> createState() =>
      _EditScenarioBottomSheetState();
}

class _EditScenarioBottomSheetState extends State<EditScenarioBottomSheet> {
  late TextEditingController _userRoleController;
  late TextEditingController _aiRoleController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _userRoleController = TextEditingController(text: widget.userRole);
    _aiRoleController = TextEditingController(text: widget.aiRole);
    _descriptionController = TextEditingController(text: widget.description);
  }

  @override
  void dispose() {
    _userRoleController.dispose();
    _aiRoleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final userRole = _userRoleController.text.trim();
    final aiRole = _aiRoleController.text.trim();
    final description = _descriptionController.text.trim();

    if (userRole.isNotEmpty && aiRole.isNotEmpty && description.isNotEmpty) {
      Navigator.pop(context, {
        'userRole': userRole,
        'aiRole': aiRole,
        'description': description,
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 필드를 입력해주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '시나리오 수정',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(color: Color(0xFF333333)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                TextField(
                  controller: _userRoleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: '나의 역할',
                    labelStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _aiRoleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'AI의 역할',
                    labelStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: '상황 및 대화 주제',
                    labelStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 60, // 버튼 높이 크게
              child: ElevatedButton(
                onPressed: () {
                  final userRole = _userRoleController.text.trim();
                  final aiRole = _aiRoleController.text.trim();
                  final description = _descriptionController.text.trim();

                  if (userRole.isNotEmpty &&
                      aiRole.isNotEmpty &&
                      description.isNotEmpty) {
                    Navigator.pop(context); // 먼저 바텀시트 닫기
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FreeTalkMessage(
                          title: '나만의 시나리오',
                          emoji: '🎨',
                          userRole: userRole,
                          aiRole: aiRole,
                          description: description,
                          postId:
                              DateTime.now().millisecondsSinceEpoch.toString(),
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('모든 필드를 입력해주세요.')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  elevation: 6,
                  shadowColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16), // 더 둥글게
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.chat_bubble_outline,
                        color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Text(
                      '대화 시작',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 1. 관심 등록 리스트만 보여주는 화면 추가
class FavoritePostsPage extends StatefulWidget {
  const FavoritePostsPage({Key? key}) : super(key: key);

  @override
  State<FavoritePostsPage> createState() => _FavoritePostsPageState();
}

class _FavoritePostsPageState extends State<FavoritePostsPage> {
  List<dynamic> _favoritePosts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchFavoritePosts();
  }

  Future<void> _fetchFavoritePosts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwt = prefs.getString('jwt_token') ?? '';
      final dio = Dio();

      // 관심 등록된 리스트만 가져오는 API 엔드포인트로 수정하세요
      final response = await dio.get(
        '$apiBaseUrl/api/public/site/apiGetTutorFreeTalkFavorite',
        options: Options(
          headers: {'Authorization': 'Bearer $jwt'},
        ),
      );
      setState(() {
        _favoritePosts = response.data is List ? response.data : [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '데이터를 불러오지 못했습니다.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '관심 등록한 시나리오',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(_error!, style: TextStyle(color: Colors.white)))
              : _favoritePosts.isEmpty
                  ? const Center(
                      child: Text('관심 등록된 시나리오가 없습니다.',
                          style: TextStyle(color: Colors.white)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: _favoritePosts.length,
                      itemBuilder: (context, index) {
                        final post = _favoritePosts[index];
                        return PostCard(
                          profileEmoji: post['profileEmoji'] ?? '🗣️',
                          username: post['username'] ?? '',
                          title: post['title'] ?? '',
                          userRole: post['userRole'] ?? '',
                          aiRole: post['aiRole'] ?? '',
                          description: post['description'] ?? '',
                          engagementCount:
                              post['engagementCount']?.toString() ?? '',
                          postId: post['id']?.toString() ?? '',
                          isFavorite: post['favorite'],
                        );
                      },
                    ),
    );
  }
}
