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
      lessonProvider.fetchLessons(context);
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
    String? currentLesson;
    String? currentChapter;

    for (var entry in lessons.asMap().entries) {
      final index = entry.key;
      final lesson = entry.value;

      if (lesson['lessonName'] != currentLesson) {
        currentLesson = lesson['lessonName'];
        currentChapter = null;
        widgets.add(_buildLessonHeader('$currentLesson'));
      }

      if (lesson['chapterName'] != currentChapter) {
        currentChapter = lesson['chapterName'];
        widgets.add(_buildChapterHeader('$currentChapter'));
      }

      widgets.add(LessonCard(
          index,
          lesson['lessonName'] ?? '',
          lesson['lessonName'] ?? '',
          Icons.book,
          lesson['courseId'].toString(),
          lesson['lessonId'].toString(),
          lesson['chapterId'].toString(),
          lesson['chapterStudyTime']
          ));
    }

    return widgets;
  }

  Widget _buildChapterHeader(String chapterName) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        chapterName,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLessonHeader(String unitTitle) {
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
