import 'package:flutter/material.dart';

class PremiumCard extends StatelessWidget {
  const PremiumCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // Set the width to the maximum available width
      child: Card(
        color: Colors.grey[900], // Set the card color to dark grey
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Add padding inside the card
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.star, color: Colors.blue, size: 50),
              SizedBox(height: 16),
              Text('무제한으로 이용하기',
                  style: TextStyle(color: Colors.white, fontSize: 18)),
              Text('모든 컨텐츠를 마음껏 누려보세요.',
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {},
                child: Text('프리미엄 멤버 되기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
