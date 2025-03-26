import 'package:flutter/material.dart';

class LessonCard extends StatefulWidget {
  final int index;
  final String title;
  final String subtitle;
  final IconData icon;

  const LessonCard(this.index, this.title, this.subtitle, this.icon, {Key? key}) : super(key: key);

  @override
  _LessonCardState createState() => _LessonCardState();
}

class _LessonCardState extends State<LessonCard> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(widget.icon, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 18)),
                      if (widget.subtitle.isNotEmpty)
                        Text(widget.subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      isExpanded = !isExpanded;
                    });
                  },
                ),
              ],
            ),
            if (isExpanded) const SizedBox(height: 16),
            if (isExpanded)
              Row(
                children: [
                  Icon(Icons.play_arrow, color: Colors.pink, size: 24),
                  const SizedBox(width: 8),
                  const Text('오늘의 수업', style: TextStyle(color: Colors.white)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
