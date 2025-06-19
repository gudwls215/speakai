import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:dio/dio.dart';
import 'package:speakai/config.dart';
import 'dart:async';

class VideoStreamingService {
  static const String baseUrl = '$apiBaseUrl/api/public/site';
  static const String courseApiUrl = '$apiBaseUrl/api/public/course';
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

  // 시청 기록 업데이트
  Future<bool> updateChapterLog({
    required String chapterId,
    required String courseId, 
    required double chapterPlayTime,
    required double courseRate,
    required String countYn,
  }) async {
    try {
      final response = await _dio.post(
        '$courseApiUrl/updateChapterLogForTutor',
        data: {
          'chapterId': chapterId,
          'courseId': courseId,
          'chapterPlayTime': chapterPlayTime,
          'courseRate': courseRate,
          'countYn': countYn,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating chapter log: $e');
      return false;
    }
  }

  // 시청 기록 가져오기
  Future<Map<String, dynamic>?> getChapterLog({
    required String chapterId,
  }) async {
    try {
      final response = await _dio.get(
        '$courseApiUrl/getChapterLog',
        queryParameters: {
          'chapterId': chapterId,
        },
      );
      return response.data;
    } catch (e) {
      print('Error getting chapter log: $e');
      return null;
    }
  }

  String getStreamingUrl(String chapterId, jwt) {
    return '$baseUrl/apiStreamCourseContent/$chapterId?token=$jwt';
  }
}

class VideoPlayerPage extends StatefulWidget {
  final String chapterId;
  final String? courseId;
  final String? title;

  const VideoPlayerPage({
    super.key,
    this.title,
    required this.chapterId,
    required this.courseId,
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
  Timer? _progressTimer;
  double _lastSavedTime = 0;
  bool _hasResumed = false;
  
  // 이어서 보기 관련
  double _resumePosition = 0;
  bool _showResumeDialog = false;

  @override
  void initState() {
    super.initState();
    _streamingService = VideoStreamingService();
    _loadWatchHistory();
  }

  // 시청 기록 불러오기
  Future<void> _loadWatchHistory() async {
    try {
      final historyData = await _streamingService.getChapterLog(
        chapterId: widget.chapterId,
      );

      if (historyData != null && historyData['chapterPlayTime'] != null) {
        _resumePosition = (historyData['chapterPlayTime'] as num).toDouble();
        
        // 5초 이상 시청한 경우에만 이어서 보기 제안
        if (_resumePosition > 5) {
          setState(() {
            _showResumeDialog = true;
          });
        }
      }
    } catch (e) {
      print('Error loading watch history: $e');
    }
    
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final prefs = await SharedPreferences.getInstance();
      final jwt = prefs.getString('jwt_token') ?? '';

      _streamingService = VideoStreamingService(authToken: jwt);

      _videoInfo = await _streamingService.getVideoInfo(widget.chapterId);
      if (_videoInfo == null) {
        throw Exception('Failed to get video information');
      }

      final streamingUrl =
          _streamingService.getStreamingUrl(widget.chapterId, jwt);

      print("Streaming URL: $streamingUrl");

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
                  const Text(
                    'Video Error',
                    style: TextStyle(color: Colors.white, fontSize: 18),
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

      // 비디오 상태 변경 리스너 등록
      _videoController!.addListener(_videoStateListener);

      setState(() {
        _isLoading = false;
      });

      // 이어서 보기 다이얼로그 표시
      if (_showResumeDialog && mounted) {
        _showResumePlayDialog();
      }

    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  // 비디오 상태 리스너
  void _videoStateListener() {
    if (_videoController == null) return;

    // 재생 시작시 진행률 업데이트 타이머 시작
    if (_videoController!.value.isPlaying && _progressTimer == null) {
      _startProgressTimer();
    }
    // 일시정지시 타이머 정지 및 진행률 저장
    else if (!_videoController!.value.isPlaying && _progressTimer != null) {
      _stopProgressTimer();
      _saveProgress(countYn: 'N'); // 일시정지시는 countYn = 'N'
    }
  }

  // 진행률 업데이트 타이머 시작
  void _startProgressTimer() {
    _progressTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _saveProgress(countYn: 'Y'); // 정기 업데이트시는 countYn = 'Y'
    });
  }

  // 진행률 업데이트 타이머 정지
  void _stopProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  // 진행률 저장
  Future<void> _saveProgress({required String countYn}) async {
    if (_videoController == null) {
      return;
    }

    final currentTime = _videoController!.value.position.inSeconds.toDouble();
    final duration = _videoController!.value.duration.inSeconds.toDouble();
    
    if (duration <= 0) return;

    final courseRate = (currentTime / duration) * 100;

    // 마지막 저장 시간과 5초 이상 차이날 때만 저장
    if ((currentTime - _lastSavedTime).abs() >= 5) {
      try {
        final success = await _streamingService.updateChapterLog(
          chapterId: widget.chapterId,
          courseId: widget.courseId ?? '',
          chapterPlayTime: currentTime,
          courseRate: courseRate,
          countYn: countYn,
        );

        if (success) {
          _lastSavedTime = currentTime;
          print('Progress saved: ${currentTime}s (${courseRate.toStringAsFixed(1)}%)');
        }
      } catch (e) {
        print('Error saving progress: $e');
      }
    }
  }

  // 이어서 보기 다이얼로그
  void _showResumePlayDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            '이어서 보기',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            '이전에 시청하던 위치(${_formatDuration(Duration(seconds: _resumePosition.toInt()))})부터 계속 시청하시겠습니까?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _hasResumed = true;
              },
              child: const Text('처음부터', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resumeFromPosition();
              },
              child: const Text('이어서 보기', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  // 이어서 보기 실행
  void _resumeFromPosition() {
    if (_videoController != null && _resumePosition > 0) {
      _videoController!.seekTo(Duration(seconds: _resumePosition.toInt()));
      _hasResumed = true;
    }
  }

  // 시간 포맷팅 헬퍼 함수
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    } else {
      return "$twoDigitMinutes:$twoDigitSeconds";
    }
  }

  void _retryVideo() {
    _disposeControllers();
    _initializePlayer();
  }

  void _disposeControllers() {
    _stopProgressTimer();
    _videoController?.removeListener(_videoStateListener);
    _chewieController?.dispose();
    _videoController?.dispose();
    _chewieController = null;
    _videoController = null;
  }

  @override
  void dispose() {
    // 페이지 종료시 마지막 진행률 저장
    if (_videoController != null && _videoController!.value.isInitialized) {
      _saveProgress(countYn: 'N');
    }
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Text(
              widget.title ?? '동영상',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ],
        ),
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
            const Text(
              'Error loading video',
              style: TextStyle(color: Colors.white, fontSize: 18),
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