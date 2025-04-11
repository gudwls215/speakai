import 'package:flutter/material.dart';
import 'package:speakai/widgets/free_talk_message.dart';

class FreeTalkTab extends StatelessWidget {
  const FreeTalkTab({Key? key}) : super(key: key);

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
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip(
                    icon: Icons.local_fire_department,
                    label: '트렌딩',
                    isSelected: true,
                  ),
                  const SizedBox(width: 8),
                  _buildCategoryChip(
                    icon: Icons.access_time,
                    label: '신규',
                    isSelected: false,
                  ),
                  const SizedBox(width: 8),
                  _buildCategoryChip(
                    icon: Icons.bar_chart,
                    label: '탑 차트',
                    isSelected: false,
                    hasDropdown: true,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: const [
                PostCard(
                  profileEmoji: '⏰',
                  username: '@DynamicCaribou6647',
                  title: '3분 영어 대화',
                  userRole: '나',
                  aiRole: '외국인',
                  description: '영어실력 99.9% 느는 외국인과의 3분 대화',
                  engagementCount: '93',
                  postId: "1",
                ),
                PostCard(
                  profileEmoji: '📖',
                  username: '@제작진이다먹음',
                  title: '미드 대사 따라하기!',
                  userRole: '나',
                  aiRole: '외국인',
                  description:
                      '선생님이 미드 대사를 한문장씩 총 50문장을 읽어준다. 학습자는 그대로 따라 읽는다.',
                  engagementCount: '403',
                  postId: "2",
                ),
                PostCard(
                  profileEmoji: '📚',
                  username: '@50년째 초보',
                  title: '한국어 번역',
                  userRole: '나',
                  aiRole: '외국인',
                  description:
                      '1. 선생님이 한국어로 문장을 제시한다\n2. 학생은 그 문장을 영어로 번역한다...',
                  engagementCount: '435',
                  postId: "3",
                ),
                PostCard(
                  profileEmoji: '🗣️',
                  username: '@Taekgy',
                  title: '원어민 선생님과의 프리토킹',
                  userRole: '나',
                  aiRole: '외국인',
                  description:
                      '선생님과 일상적인 혹은 전문적인 이야기를 10분 동안 나눈다. 10분의 대화가 끝나면 ...',
                  engagementCount: '143',
                  postId: "4",
                ),
                PostCard(
                  profileEmoji: '🎉',
                  username: '@한국인_영어학습가',
                  title: '매일 도전 시나리오...에서...',
                  userRole: '나',
                  aiRole: '외국인',
                  description: '매일 도전 시나리오에서 10분간 대화하기. 매일 10분씩 대화하기.',
                  engagementCount: '',
                  postId: "5",
                ),
              ],
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
            // 결과 처리
            print('User Role: ${result['userRole']}');
            print('AI Role: ${result['aiRole']}');
            print('Description: ${result['description']}');

            // 예: FreeTalkMessage로 이동
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

class PostCard extends StatelessWidget {
  final String profileEmoji;
  final String username;
  final String title;
  final String userRole;
  final String aiRole;
  final String description;
  final String engagementCount;
  final String postId;

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
  }) : super(key: key);

  void _showPostDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PostDetailBottomSheet(
        profileEmoji: profileEmoji,
        username: username,
        title: title,
        userRole: userRole,
        aiRole: aiRole,
        description: description,
        engagementCount: engagementCount,
        postId: postId,
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
                          profileEmoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          title,
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
                      icon: const Icon(
                        Icons.favorite_border,
                        color: Colors.white,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey.shade300,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (engagementCount.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      engagementCount,
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
        ));
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
                '완료',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
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
                IconButton(
                  icon: const Icon(Icons.favorite_border, color: Colors.white),
                  onPressed: () {},
                ),
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
                    onPressed: () => Navigator.pop(context),
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
