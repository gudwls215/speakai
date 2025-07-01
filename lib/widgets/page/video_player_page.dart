import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:dio/dio.dart';
import 'package:speakai/config.dart';
import 'dart:async';

// 커스텀 비디오 컨트롤
class CustomVideoControls extends StatefulWidget {
  final String title;
  final VoidCallback onBack;

  const CustomVideoControls({
    Key? key,
    required this.title,
    required this.onBack,
  }) : super(key: key);

  @override
  State<CustomVideoControls> createState() => _CustomVideoControlsState();
}

class _CustomVideoControlsState extends State<CustomVideoControls>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  VideoPlayerController? _controller;
  ChewieController? _chewieController;
  bool _isVisible = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final chewieController = ChewieController.of(context);
    if (chewieController != _chewieController) {
      _chewieController = chewieController;
      _controller = _chewieController!.videoPlayerController;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }

  void _toggleControls() {
    if (_isVisible) {
      _animationController.reverse();
      setState(() {
        _isVisible = false;
      });
    } else {
      _animationController.forward();
      setState(() {
        _isVisible = true;
      });
      _startHideTimer();
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isVisible) {
        _animationController.reverse();
        setState(() {
          _isVisible = false;
        });
      }
    });
  }

  void _playPause() {
    if (_controller!.value.isPlaying) {
      _controller!.pause();
    } else {
      _controller!.play();
      _startHideTimer();
    }
  }

  void _seekBackward() {
    final currentPosition = _controller!.value.position;
    final newPosition = currentPosition - const Duration(seconds: 5);
    _controller!.seekTo(newPosition < Duration.zero ? Duration.zero : newPosition);
    _startHideTimer();
  }

  void _seekForward() {
    final currentPosition = _controller!.value.position;
    final duration = _controller!.value.duration;
    final newPosition = currentPosition + const Duration(seconds: 5);
    _controller!.seekTo(newPosition > duration ? duration : newPosition);
    _startHideTimer();
  }

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

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: _toggleControls,
      child: Container(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: _controller!,
          builder: (context, child) {
            final position = _controller!.value.position;
            final duration = _controller!.value.duration;
            final isPlaying = _controller!.value.isPlaying;

            return Stack(
              children: [
                // 상단 컨트롤 (타이틀, 뒤로가기)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, -50 * (1 - _animationController.value)),
                        child: Opacity(
                          opacity: _animationController.value,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.7),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: SafeArea(
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: widget.onBack,
                                    icon: const Icon(
                                      Icons.arrow_back,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      widget.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // 중앙 재생/일시정지 및 이동 버튼들
                Center(
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _animationController.value,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 뒤로 5초
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: _seekBackward,
                                iconSize: 48,
                                icon: const Icon(
                                  Icons.replay_5,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 32),
                            // 재생/일시정지
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: _playPause,
                                iconSize: 64,
                                icon: Icon(
                                  isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 32),
                            // 앞으로 5초
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: _seekForward,
                                iconSize: 48,
                                icon: const Icon(
                                  Icons.forward_5,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // 하단 컨트롤 (진행바, 시간)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, 50 * (1 - _animationController.value)),
                        child: Opacity(
                          opacity: _animationController.value,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.7),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 진행바
                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor: Colors.blue,
                                      inactiveTrackColor: Colors.white.withOpacity(0.3),
                                      thumbColor: Colors.blue,
                                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                      trackHeight: 3,
                                    ),
                                    child: Slider(
                                      value: position.inMilliseconds.toDouble(),
                                      max: duration.inMilliseconds.toDouble(),
                                      onChanged: (value) {
                                        _controller!.seekTo(Duration(milliseconds: value.toInt()));
                                      },
                                    ),
                                  ),
                                  // 시간 표시
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDuration(position),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        _formatDuration(duration),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class VideoStreamingService {
  static const String baseUrl = '$apiBaseUrl/api/public/site';
  static const String courseApiUrl = '$apiBaseUrl/api/public/course';
  final Dio _dio = Dio();
  String? _authToken;
  
  // 임시 시청 시간 저장용 정적 Map (chapterId -> playTime)
  static Map<String, double> _tempWatchTimes = {};

  VideoStreamingService({String? authToken}) {
    _authToken = authToken;
    _setupDio();
  }

  void _setupDio() {
    _dio.options.headers['Authorization'] = 'Bearer $_authToken';
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  // 임시 시청 시간 저장
  static void updateTempWatchTime(String chapterId, double playTime) {
    _tempWatchTimes[chapterId] = playTime;
  }

  // 임시 시청 시간 가져오기
  static double? getTempWatchTime(String chapterId) {
    return _tempWatchTimes[chapterId];
  }

  // 임시 시청 시간 초기화 (필요한 경우)
  static void clearTempWatchTime(String chapterId) {
    _tempWatchTimes.remove(chapterId);
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

  String getStreamingUrl(String chapterId, jwt) {
    return '$baseUrl/apiStreamCourseContent/$chapterId?token=$jwt';
  }
}

class VideoPlayerPage extends StatefulWidget {
  final String chapterId;
  final String? courseId;
  final String? title;
  final dynamic chapterStudyTime; 

  const VideoPlayerPage({
    Key? key,
    required this.title,
    required this.chapterId,
    required this.courseId,
    this.chapterStudyTime,
  }) : super(key: key);

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
  
  // 이어서 보기 관련
  double _resumePosition = 0;
  bool _showResumeDialog = false;

  @override
  void initState() {
    super.initState();
    _streamingService = VideoStreamingService();
    _loadWatchHistory();
  }

  // 시청 기록 불러오기 (VideoStreamingService의 임시 저장된 시간을 우선 체크)
  Future<void> _loadWatchHistory() async {
    try {
      // 1. VideoStreamingService에서 임시 저장된 시청 시간을 먼저 확인
      double? tempWatchTime = VideoStreamingService.getTempWatchTime(widget.chapterId);
      
      if (tempWatchTime != null && tempWatchTime > 0) {
        // 임시 저장된 시간이 있으면 우선 사용
        _resumePosition = tempWatchTime;
        print('Using temp watch time from service: ${tempWatchTime}s');
      } else if (widget.chapterStudyTime != null) {
        // 임시 저장 시간이 없으면 chapterStudyTime 사용
        _resumePosition = (widget.chapterStudyTime as num).toDouble();
        print('Using chapterStudyTime: ${_resumePosition}s');
      }
      
      // 5초 이상 시청한 경우에만 이어서 보기 제안
      if (_resumePosition > 5) {
        setState(() {
          _showResumeDialog = true;
        });
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
        customControls: CustomVideoControls(
          title: widget.title ?? '동영상',
          onBack: () => Navigator.pop(context),
        ),
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
        // 1. VideoStreamingService에 임시 시청 시간 저장
        VideoStreamingService.updateTempWatchTime(widget.chapterId, currentTime);
        
        // 2. 서버에 시청 기록 저장
        final success = await _streamingService.updateChapterLog(
          chapterId: widget.chapterId,
          courseId: widget.courseId ?? '',
          chapterPlayTime: currentTime,
          courseRate: courseRate,
          countYn: countYn,
        );

        if (success) {
          _lastSavedTime = currentTime;
          print('Progress saved: ${currentTime}s (${courseRate.toStringAsFixed(1)}%) - Temp time updated');
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