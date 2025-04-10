import 'package:flutter/material.dart';

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
                  description: '영어실력 99.9% 느는 외국인과의 3분 대화',
                  engagementCount: '93',
                ),
                PostCard(
                  profileEmoji: '📖',
                  username: '@제작진이다먹음',
                  title: '미드 대사 따라하기!',
                  description: '선생님이 미드 대사를 한문장씩 총 50문장을 읽어준다. 학습자는 그대로 따라 읽는다.',
                  engagementCount: '403',
                ),
                PostCard(
                  profileEmoji: '📚',
                  username: '@50년째 초보',
                  title: '한국어 번역',
                  description: '1. 선생님이 한국어로 문장을 제시한다\n2. 학생은 그 문장을 영어로 번역한다...',
                  engagementCount: '435',
                ),
                PostCard(
                  profileEmoji: '🗣️',
                  username: '@Taekgy',
                  title: '원어민 선생님과의 프리토킹',
                  description: '선생님과 일상적인 혹은 전문적인 이야기를 10분 동안 나눈다. 10분의 대화가 끝나면 ...',
                  engagementCount: '143',
                ),
                PostCard(
                  profileEmoji: '🎉',
                  username: '@한국인_영어학습가',
                  title: '매일 도전 시나리오...에서...',
                  description: '',
                  engagementCount: '',
                ),
              ],
            ),
          ),
        ],
      ),
    
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
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
  final String description;
  final String engagementCount;

  const PostCard({
    Key? key,
    required this.profileEmoji,
    required this.username,
    required this.title,
    required this.description,
    required this.engagementCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
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
    );
  }
}