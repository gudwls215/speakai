import 'package:flutter/material.dart';
import 'package:speakai/widgets/page/video_player_page.dart';

class NextLessonCard extends StatelessWidget {
  final String chapterName;
  final String chapter;
  final String course;

  const NextLessonCard(this.chapterName, this.chapter, this.course, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '무료',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
            const Icon(Icons.mic, color: Colors.pink, size: 50),
            const SizedBox(height: 16),
            Text(
              chapterName.isNotEmpty ? chapterName : '',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            Text(
              chapterName.isNotEmpty ? chapterName : '강의 탭에서 챕터를 선택하세요',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoPlayerPage(
                      title: chapterName,
                      chapterId: chapter,
                      courseId: course,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('시작하기'),
            ),
          ],
        ),
      ),
    );
  }
}
