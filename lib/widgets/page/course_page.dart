import 'package:flutter/material.dart';
import 'package:speakai/widgets/progress_bar.dart';
import 'package:speakai/widgets/lesson_card.dart';
import 'package:speakai/widgets/premium_card.dart';
import 'package:provider/provider.dart';
import 'package:speakai/providers/lesson_provider.dart';

class CoursePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final lessonProvider = Provider.of<LessonProvider>(context);

    // fetchLessons 호출 (한 번만 실행됨)
    if (!lessonProvider.isLoading && lessonProvider.lessons.isEmpty) {
      lessonProvider.fetchLessons();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProgressBar(),
          Text(
            '유닛 1 - ${lessonProvider.lessons.length} 레슨',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (lessonProvider.isLoading)
            Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color.fromARGB(179, 59, 197, 221),
              ),
            )
          else
            ..._buildLessonsWithHeaders(lessonProvider.lessons),
        ],
      ),
    );
  }

  List<Widget> _buildLessonsWithHeaders(List<Map<String, dynamic>> lessons) {
    List<Widget> widgets = [];
    String? currentChapter;
    String? currentSection;

    for (var entry in lessons.asMap().entries) {
      final index = entry.key;
      final lesson = entry.value;

      if (lesson['CHAPTER_NAME'] != currentChapter) {
        currentChapter = lesson['CHAPTER_NAME'];
        currentSection = null;
        widgets.add(_buildChapterHeader('$currentChapter'));
      }

      if (lesson['SECTION_NAME'] != currentSection) {
        currentSection = lesson['SECTION_NAME'];
        widgets.add(_buildSectionHeader('$currentSection'));
      }

      widgets.add(LessonCard(
        index,
        lesson['CASE_NAME'] ?? '',
        lesson['THEME'] ?? '',
        Icons.book,
      ));
    }

    return widgets;
  }

  Widget _buildSectionHeader(String sectionName) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        sectionName,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildChapterHeader(String unitTitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: Colors.grey, thickness: 1),
        const SizedBox(height: 16),
        Text(
          unitTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

