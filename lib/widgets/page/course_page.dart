import 'package:flutter/material.dart';
import 'package:speakai/widgets/progress_bar.dart';
import 'package:speakai/widgets/lesson_card.dart';
import 'package:speakai/widgets/premium_card.dart';

class CoursePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProgressBar(),
          Text('유닛 1 - 14 레슨', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          LessonCard(0, '여기가 영어 101 수업인가요?', 'Is this English 101?', Icons.play_arrow),
          LessonCard(1, '그래머 마스터', '', Icons.book),
          PremiumCard(),
          LessonCard(2, '저는 1학년이에요.', "I'm a freshman.", Icons.check_circle),
          LessonCard(3, '도서관이 어디에 있나요?', "Where's the library?", Icons.check_circle),
        ],
      ),
    );
  }
}
