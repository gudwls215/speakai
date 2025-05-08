import 'package:flutter/material.dart';

class LessonCard extends StatefulWidget {
  final int index;
  final String title;
  final String subtitle;
  final IconData icon;

  const LessonCard(this.index, this.title, this.subtitle, this.icon, {Key? key})
      : super(key: key);

  @override
  _LessonCardState createState() => _LessonCardState();
}

class _LessonCardState extends State<LessonCard> {
  bool isExpanded = false;
  int? selectedMenuIndex;
  bool showStartButton = false;

  // Menu options for each lesson
  final List<Map<String, dynamic>> menuOptions = [
    {'icon': Icons.play_arrow, 'text': '오늘의 수업', 'color': Colors.amber},
    {'icon': Icons.mic, 'text': '스피킹 연습', 'color': Colors.pink[300]},
    {'icon': Icons.people, 'text': '롤플레잉', 'color': Colors.purple[300]},
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 0),
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            if (showStartButton) {
              // If start button is showing, reset the state
              showStartButton = false;
              selectedMenuIndex = null;
              isExpanded = false;
            } else {
              // Otherwise toggle expand/collapse
              isExpanded = !isExpanded;
              selectedMenuIndex = null;
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getIconColor(widget.index),
                    child: Icon(widget.icon, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500)),
                        if (widget.subtitle.isNotEmpty)
                          Text(widget.subtitle,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.white),
                  ),
                ],
              ),
              if (isExpanded) _buildDropdownMenu(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownMenu() {
    return Column(
      children: [
        const Divider(color: Colors.grey, height: 24),
        ...List.generate(
          menuOptions.length,
          (index) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    selectedMenuIndex =
                        (selectedMenuIndex == index) ? null : index;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: menuOptions[index]['color'],
                        child: Icon(
                          menuOptions[index]['icon'],
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        menuOptions[index]['text'],
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const Spacer(),
                      if (selectedMenuIndex == index)
                        Icon(Icons.check, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
              if (selectedMenuIndex == index)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: _buildStartButton(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedOption() {
    final option = menuOptions[selectedMenuIndex!];
    return Column(
      children: [
        const Divider(color: Colors.grey, height: 24),
        Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: option['color'],
              child: Icon(
                option['icon'],
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              option['text'],
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildStartButton(), // "시작하기" 버튼을 바로 아래에 추가
      ],
    );
  }

  Widget _buildStartButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.blue[600],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: TextButton(
        onPressed: () {
          // 버튼 클릭 시 동작 추가 가능
          print('Start button clicked!');
        },
        child: const Text(
          '시작하기',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _getIconColor(int index) {
    // Match the colors seen in the first image
    switch (index % 3) {
      case 0:
        return Colors.amber; // Yellow for play icon
      case 1:
        return Colors.teal; // Teal for document icon
      case 2:
        return Colors.purple; // Purple for role-playing icon
      default:
        return Colors.blue;
    }
  }
}
