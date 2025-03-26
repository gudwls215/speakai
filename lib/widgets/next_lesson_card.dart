import 'package:flutter/material.dart';

class NextLessonCard extends StatelessWidget {
  const NextLessonCard({Key? key}) : super(key: key);

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
            const Text('여기가 영어 101 수업인가요?', style: TextStyle(color: Colors.white, fontSize: 18)),
            const Text('Is this English 101?', style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('시작하기'),
            ),
          ],
        ),
      ),
    );
  }
}
