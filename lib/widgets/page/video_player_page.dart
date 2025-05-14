import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerPage extends StatefulWidget {
  final String title; // 타이틀
  final String videoPath; // 동영상 파일 경로

  const VideoPlayerPage({Key? key, required this.title, required this.videoPath}) : super(key: key);

  @override
  _VideoPlayerPageState createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    // Initialize the video player with the provided video path
    _controller = VideoPlayerController.asset(widget.videoPath)
      ..initialize().then((_) {
        setState(() {}); // Refresh the UI once the video is loaded
      });
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose the controller to free resources
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title, // 동적으로 전달된 타이틀 사용
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueGrey[800],
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 1,
      ),
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const CircularProgressIndicator(
                strokeWidth: 2,
                color: Color.fromARGB(179, 59, 197, 221),
              ), // Show a loader while the video is loading
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            if (_controller.value.isPlaying) {
              _controller.pause();
            } else {
              _controller.play();
            }
          });
        },
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
      backgroundColor: Colors.black,
    );
  }
}