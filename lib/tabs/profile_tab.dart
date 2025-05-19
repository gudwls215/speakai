import 'package:flutter/material.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
            appBar: AppBar(
        backgroundColor: Color(0xFF1F2937),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(backgroundImage: AssetImage('avatar.png')),
            Icon(Icons.settings, color: Colors.white),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  '당신의 학습 하이라이트',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // 상단 통계 카드 섹션
              Row(
                children: [
                  // 말한 문장 카드
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.chat_bubble_outline,
                      iconColor: Colors.purple.shade300,
                      title: '말한 문장',
                      value: '215개',
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 공부한 시간 카드
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.access_time_rounded,
                      iconColor: Colors.teal.shade300,
                      title: '공부한 시간',
                      value: '129분',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 어휘 및 표현 카드
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2133),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red.shade300,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.menu_book_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              '어휘 및 표현',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const Icon(
                          Icons.info_outline,
                          color: Colors.white54,
                          size: 24,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildCountItem('210', '신규'),
                        _buildCountItem('65', '학습 완료'),
                        _buildCountItem('3', '마스터 완료'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 북마크 및 저장 항목 섹션
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2133),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildBookmarkItem(
                      icon: Icons.local_fire_department_outlined,
                      iconBgColor: Colors.grey.shade600,
                      title: '불꽃 기록부',
                      subtitle: '1일 1수업으로 불꽃 유지!',
                    ),
                    const Divider(height: 1, color: Colors.grey),
                    _buildBookmarkItem(
                      icon: Icons.bookmark_outline,
                      iconBgColor: Colors.blue,
                      title: '보관한 표현',
                      subtitle: '두고두고 볼 나만의 표현 집합소!',
                    ),
                    const Divider(height: 1, color: Colors.grey),
                    _buildBookmarkItem(
                      icon: Icons.bookmark_outline,
                      iconBgColor: Colors.amber,
                      title: '보관한 단어',
                      subtitle: 'AI 코치와 함께 발음 연습하기!',
                    ),
                  ],
                ),
              ),
              
              // 수강 시작한 코스 섹션
              const SizedBox(height: 30),
              _buildCourseSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '수강 시작한 코스',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                '모든 코스 보기',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E2133),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildCourseItem(
                image: 'assets/images/audrey.jpg',
                title: '영어적 사고 기르기',
                instructors: 'With Audrey & Sarah',
                progress: 0.0,
                isInProgress: true,
              ),
              const Divider(height: 1, color: Color(0xFF2A2E45)),
              _buildCourseItem(
                image: 'assets/images/kate.jpg',
                title: '스피킹하며 시작 (왕초보 1탄)',
                instructors: 'With Kate & Christina',
                progress: 0.0,
              ),
              const Divider(height: 1, color: Color(0xFF2A2E45)),
              _buildCourseItem(
                image: 'assets/images/jenny.jpg',
                title: '실전 상황별 스피킹',
                instructors: 'With Jenny & Audrey',
                progress: 0.0,
              ),
              const Divider(height: 1, color: Color(0xFF2A2E45)),
              _buildCourseItem(
                image: 'assets/images/sarah.jpg',
                title: '스피킹 살아남기 (기초 1탄)',
                instructors: 'With Sarah & Christina',
                progress: 0.0,
              ),
              const Divider(height: 1, color: Color(0xFF2A2E45)),
              _buildCourseItem(
                image: 'assets/images/campus.jpg',
                title: '대학 캠퍼스 영어',
                instructors: 'With Audrey & Friends',
                progress: 0.0,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCourseItem({
    required String image,
    required String title,
    required String instructors,
    required double progress,
    bool isInProgress = false,
  }) {
    // 프로필 이미지 대체 위젯
    Widget profileImage = ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 80,
        height: 80,
        color: Colors.grey.shade800,
        child: const Icon(
          Icons.person,
          color: Colors.white,
          size: 40,
        ),
      ),
    );

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      leading: Stack(
        children: [
          profileImage,
          if (isInProgress)
            Positioned(
              bottom: 0,
              right: 0,
              left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Center(
                  child: Text(
                    '학습 중',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            instructors,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade800,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          const SizedBox(height: 4),
          Text(
            '${(progress * 100).toInt()}% 완료',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
      trailing: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check,
          color: Colors.white,
          size: 24,
        ),
      ),
      isThreeLine: true,
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2133),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 28,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountItem(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildBookmarkItem({
    required IconData icon,
    required Color iconBgColor,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconBgColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 12,
        ),
      ),
    );
  }
}