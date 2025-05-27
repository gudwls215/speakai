import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:dio/dio.dart';

class VideoStreamingService {
  static const String baseUrl = 'http://114.202.2.224:8888/api/public/site';
  final Dio _dio = Dio();
  String? _authToken;

  VideoStreamingService({String? authToken}) {
    _authToken = authToken;
    _setupDio();
  }

  void _setupDio() {
    _dio.options.headers['Authorization'] = 'Bearer $_authToken';
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  Future<Map<String, dynamic>?> getVideoInfo(String chapterId) async {
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt_token') ?? '';

    try {
      final response =
          await _dio.get('$baseUrl/apiGetVideoInfo/$chapterId?token=$jwt');
      return response.data;
    } catch (e) {
      print('Error getting video info: $e');
      return null;
    }
  }

  String getStreamingUrl(String chapterId, jwt) {
    return '$baseUrl/apiStreamCourseContent/$chapterId?token=$jwt';
  }
}

class VideoPlayerPage extends StatefulWidget {
  final String chapterId;
  final String? title;

  const VideoPlayerPage({
    this.title,
    required this.chapterId,
  });

  @override
  State<VideoPlayerPage> createState() => _StreamingVideoPlayerState();
}

class _StreamingVideoPlayerState extends State<VideoPlayerPage> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  late VideoStreamingService _streamingService;
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _videoInfo;

  @override
  void initState() {
    super.initState();
    _streamingService = VideoStreamingService(); // <-- Add this line
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // SharedPreferences에서 토큰 가져오기
      final prefs = await SharedPreferences.getInstance();
      final jwt = prefs.getString('jwt_token') ?? '';

      // 토큰을 서비스에 전달
      _streamingService = VideoStreamingService(authToken: jwt);

      // 동영상 정보 가져오기
      _videoInfo = await _streamingService.getVideoInfo(widget.chapterId);
      if (_videoInfo == null) {
        throw Exception('Failed to get video information');
      }

      // 스트리밍 URL 생성 (토큰을 쿼리 파라미터로 포함)
      final streamingUrl =
          _streamingService.getStreamingUrl(widget.chapterId, jwt);

      print("Streaming URL: $streamingUrl");

      // 웹에서는 NetworkVideoPlayerWeb 사용 (헤더 없이)
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(streamingUrl),
      );

      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: false,
        showControls: true,
        allowedScreenSleep: false,
        allowFullScreen: true,
        allowMuting: true,
        showControlsOnInitialize: true,
        controlsSafeAreaMinimum: const EdgeInsets.all(12),
        customControls: const MaterialControls(),
        hideControlsTimer: const Duration(seconds: 3),
        progressIndicatorDelay: const Duration(milliseconds: 200),
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error,
                    color: Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Video Error',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _retryVideo,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        },
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _retryVideo() {
    _disposeControllers();
    _initializePlayer();
  }

  void _disposeControllers() {
    _chewieController?.dispose();
    _videoController?.dispose();
    _chewieController = null;
    _videoController = null;
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Text(
              widget.title ?? '동영상',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              'Loading video...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading video',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _retryVideo,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_chewieController == null) {
      return const Center(
        child: Text(
          'Video player not initialized',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            child: Chewie(controller: _chewieController!),
          ),
        ),
      ],
    );
  }

}
