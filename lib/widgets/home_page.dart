import 'package:flutter/material.dart';
import 'package:speakai/widgets/pronunciation.dart';
import 'package:speakai/widgets/section_title.dart.dart';
import 'package:speakai/widgets/category_card.dart';
import 'package:speakai/widgets/next_lesson_card.dart';
import 'package:speakai/widgets/voca_multiple.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle('다음 수업 바로가기 >'),
          NextLessonCard(),
          SectionTitle('점프인 레슨'),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        VocaMultiple("1", "1", "1", "")),
              );
            },
            child: const CategoryCard(
                'Word Smart', '꼭 알아야 하는 실전 위주 영단어!', Icons.school),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        PronunciationAssessment("1", "1", "1","")),
              );
            },
            child: const CategoryCard(
                'pronunciation assessment', '수업한 내용 복습과 발음 평가!', Icons.school),
          ),
          // CategoryCard(
          //     'Native Speakers\' Idioms', '네이티브가 실제 쓰는 숙어 표현', Icons.language),
          CategoryCard('English Grammar', '영어 문법의 기초부터 심화까지', Icons.book),
          SectionTitle('추천 코스'),
          CategoryCard(
              'Daily English', '매일 10분씩 영어회화 능력 향상', Icons.access_time),
          CategoryCard('Business English', '비즈니스 상황에서 사용하는 영어 표현', Icons.work),
        ],
      ),
    );
  }
}
