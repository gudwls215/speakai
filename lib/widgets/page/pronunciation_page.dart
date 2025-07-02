import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speakai/utils/token_manager.dart';
import 'package:speakai/config.dart';

class PronunciationAssessment extends StatefulWidget {
  final String course;
  final String lesson;
  final String chapter;
  final String text;

  const PronunciationAssessment(
      this.course, this.lesson, this.chapter, this.text,
      {Key? key})
      : super(key: key);

  @override
  State<PronunciationAssessment> createState() =>
      _PronunciationAssessmentState();
}

class _PronunciationAssessmentState extends State<PronunciationAssessment> {
  bool _isLoadingConversation = true;
  Set<String> _bookmarkedSentences = {};
  int _currentIndex = 0;
  bool _isRecording = false;
  bool _isProcessing = false;
  String? _currentTranslation;
  Map<String, dynamic>? _assessmentResult;
  List<Map<String, dynamic>>? _wordResults;
  //List<String>? _conversationData;
  List<Map<String, dynamic>>? _conversationList;

  final FlutterTts _flutterTts = FlutterTts();

  final errorCounts = {
    'Mispronunciation': 0,
    'Omission': 0,
    'Insertion': 0,
    'Unnecessary pause': 0,
    'Missing pause': 0,
    'Monotone': 0,
  };

  // For web audio recording
  html.MediaRecorder? _recorder;
  List<html.Blob> _audioChunks = [];
  html.MediaStream? _stream;
  html.AudioElement? _audioPlayer;

  @override
  void initState() {
    super.initState();
    _loadConversationDataWithCache();
    _fetchBookmarks();
  }

  String _formatDuration(double? seconds) {
    if (seconds == null || seconds.isInfinite || seconds.isNaN) {
      return '00:00';
    }
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds.toInt() % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Generate a unique cache key
  String _generateCacheKey() {
    final String payloadString =
        "${widget.course}|${widget.lesson}|${widget.chapter}|${widget.text}";
    return md5.convert(utf8.encode(payloadString)).toString();
  }

  // Load conversation data with cache
  Future<void> _loadConversationDataWithCache() async {
    setState(() {
      _isLoadingConversation = true;
    });
    final cacheKey = _generateCacheKey();

    try {
      // Try to load from cache
      final cachedData = await _loadCachedConversationData(cacheKey);

      if (cachedData != null && cachedData.isNotEmpty) {
        setState(() {
          _conversationList = cachedData['fullList'];
          _isLoadingConversation = false;
        });
      } else {
        await _fetchConversationDataFromApi(cacheKey);
        setState(() {
          _isLoadingConversation = false;
        });
      }
    } catch (e) {
      print("Error loading cached conversation data: $e");
      await _fetchConversationDataFromApi(cacheKey);
      setState(() {
        _isLoadingConversation = false;
      });
    }
  }

  // Load cached conversation data
  Future<Map<String, dynamic>?> _loadCachedConversationData(
      String cacheKey) async {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedData = prefs.getString('conversation_data_$cacheKey');
    final String? cachedFull = prefs.getString('conversation_full_$cacheKey');
    if (cachedData != null && cachedFull != null) {
      return {
        'enList': List<String>.from(jsonDecode(cachedData)),
        'fullList': List<Map<String, dynamic>>.from(jsonDecode(cachedFull)),
      };
    }
    return null;
  }

  // Save conversation data to cache
  Future<void> _cacheConversationData(String cacheKey, List<String> enList,
      List<Map<String, dynamic>> fullList) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('conversation_data_$cacheKey', jsonEncode(enList));
    await prefs.setString('conversation_full_$cacheKey', jsonEncode(fullList));
  }

  // Fetch conversation data from API
  Future<void> _fetchConversationDataFromApi(String cacheKey) async {
    final url = Uri.parse(
        '$aiBaseUrl/conversation?course=${widget.course}&lesson=${widget.lesson}&chapter=${widget.chapter}&text=${widget.text}');
    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final conversationList =
            List<Map<String, dynamic>>.from(data['conversation']);
        final conversationEn = conversationList
            .map((e) => e['en']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList();

        // Cache both en-only and full list
        await _cacheConversationData(
            cacheKey, conversationEn, conversationList);

        setState(() {
          _conversationList = conversationList;
        });
      } else {
        print('Failed to fetch conversation data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching conversation data: $e');
    }
  }

  // 번역문을 conversationList의 'ko'에서 가져오도록 수정
  Future<String> _getKoTranslationForCurrentSentence() async {
    if (_conversationList != null &&
        _currentIndex < _conversationList!.length) {
      final item = _conversationList![_currentIndex];
      return item['ko']?.toString() ?? '';
    }
    return '';
  }

  Future<void> _startRecording() async {
    try {
      print('Starting recording...');
      // Request microphone access
      _stream = await html.window.navigator.mediaDevices?.getUserMedia({
        'audio': true,
      });
      print(_stream);

      if (_stream != null) {
        _audioChunks = [];

        // Create media recorder
        _recorder = html.MediaRecorder(_stream!);

        // Set up recorder event handlers
        _recorder!.addEventListener('dataavailable', (event) {
          final data = (event as html.BlobEvent).data;
          print('Audio data available: ${data} bytes');
          if (data != null) {
            _audioChunks.add(data);
          }
        });

        // Start recording
        _recorder!.start();

        setState(() {
          _isRecording = true;
          _assessmentResult = null;
          _wordResults = null;

          errorCounts.updateAll((key, value) => 0);
        });
      }
    } catch (e) {
      print('Error starting recording: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accessing microphone: $e')),
      );
    }
  }

  Future<void> _stopRecording() async {
    try {
      if (_recorder != null && _recorder!.state != 'inactive') {
        // Create a promise to wait for the recording to stop
        final completer = Completer<void>();

        _recorder!.addEventListener('stop', (event) {
          completer.complete();
        }, false);

        _recorder!.stop();
        await completer.future;

        // Stop all tracks in the stream
        _stream?.getTracks().forEach((track) => track.stop());

        setState(() {
          _isRecording = false;
          _isProcessing = true;
        });

        // Combine all chunks into a single blob
        final blob = html.Blob(_audioChunks, 'audio/webm');

        // Create an object URL for the audio
        final audioUrl = html.Url.createObjectUrl(blob);

        // Initialize the audio player
        _audioPlayer = html.AudioElement(audioUrl);

        // Process the recording (this will set _isProcessing to false when done)
        await _processRecording();
      }
    } catch (e) {
      print('Error stopping recording: $e');
      setState(() {
        _isRecording = false;
        _isProcessing = false;
      });
    }
  }

  Future<void> _fetchBookmarks() async {
    final jwt = await TokenManager.getValidAccessToken();
    if (jwt == null) return; // 토큰이 없으면 조용히 실패
    
    final url =
        Uri.parse('$apiBaseUrl/api/public/site/apiTutorSentenceBookmarks');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _bookmarkedSentences = data
              .map((e) => e['sentence']?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .toSet();
        });
      }
    } catch (e) {
      // 에러 무시 또는 필요시 처리
    }
  }

  Future<String> _fetchTranslationForBookmark(String sentence) async {
    try {
      final Uri uri = Uri.parse("$aiBaseUrl/translate")
          .replace(queryParameters: {'text': sentence});
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['translation'] ?? "";
      }
    } catch (e) {
      // 에러 무시 또는 필요시 처리
    }
    return "";
  }

  Future<void> _saveBookmark() async {
    final jwt = await TokenManager.getValidAccessToken();
    if (jwt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('인증이 필요합니다.')),
      );
      return;
    }
    
    final chapterId = widget.chapter;
    final sentence = _conversationList![_currentIndex]['en'];
    final translate = await _fetchTranslationForBookmark(sentence);

    final url =
        Uri.parse('$apiBaseUrl/api/public/site/apiTutorSentenceBookmark');
    final body = jsonEncode({
      "chapter_id": chapterId,
      "sentence": sentence,
      "translate": translate,
    });

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
        body: body,
      );
      if (response.statusCode == 200) {
        setState(() {
          _bookmarkedSentences.add(sentence);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('북마크가 저장되었습니다.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('북마크 저장 실패: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('네트워크 오류: $e')),
      );
    }
  }

  Future<void> _deleteBookmark() async {
    final jwt = await TokenManager.getValidAccessToken();
    if (jwt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('인증이 필요합니다.')),
      );
      return;
    }
    
    final sentence = _conversationList![_currentIndex]['en'];

    final url = Uri.parse(
        '$apiBaseUrl/api/public/site/apiTutorSentenceBookmark?sentence=${Uri.encodeComponent(sentence)}');

    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          _bookmarkedSentences.remove(sentence);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('북마크가 삭제되었습니다.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('북마크 삭제 실패: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('네트워크 오류: $e')),
      );
    }
  }

  Future<void> _processRecording() async {
    try {
      if (_audioChunks.isEmpty) {
        print('No audio recorded');
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // Combine all chunks into a single blob
      final blob = html.Blob(_audioChunks, 'audio/webm');

      // Create a FormData object
      final formData = html.FormData();

      // Add the audio file
      formData.appendBlob('audio_file', blob, 'recording.webm');

      // Add the reference text
      if (_conversationList != null &&
          _currentIndex < _conversationList!.length) {
        formData.append('reference_text', _conversationList![_currentIndex]['en']);
      } else {
        print('Invalid conversation data or index');
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // Send to server
      final url = '$aiBaseUrl/assess_pronunciation';
      final xhr = html.HttpRequest();

      xhr.open('POST', url);

      // Set up event listeners for XHR
      final completer = Completer<String>();

      xhr.onLoad.listen((event) {
        if (xhr.status == 200) {
          completer.complete(xhr.responseText);
        } else {
          completer.completeError('Server error: ${xhr.status}');
        }
      });

      xhr.onError.listen((event) {
        completer.completeError('Network error');
      });

      // Send the request
      xhr.send(formData);

      // Wait for the response
      final responseText = await completer.future;

      // Parse the response
      final data = jsonDecode(responseText);

      setState(() {
        _assessmentResult = {
          'pronunciationScore': data['pronunciation_score'],
          'accuracyScore': data['accuracy_score'],
          'completenessScore': data['completeness_score'],
          'fluencyScore': data['fluency_score'],
          'prosodyScore': data['prosody_score'],
        };
        _wordResults =
            List<Map<String, dynamic>>.from(data['words'].map((word) => {
                  'word': word['word'],
                  'accuracyScore': word['accuracy_score'],
                  'errorType': word['error_type'],
                }));

        for (final word in _wordResults!) {
          final errorType = word['errorType'];
          if (errorCounts.containsKey(errorType)) {
            errorCounts[errorType] = errorCounts[errorType]! + 1;
          }
        }

        // 오류 카운트를 UI에서 사용할 수 있도록 상태에 저장하거나 다른 곳에 전달 가능
        print('Error counts: $errorCounts');

        _isProcessing = false;
      });
    } catch (e) {
      print('Error processing recording: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing recording: $e')),
      );
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _goToNextSentence() {
    setState(() {
      _currentIndex++;
      _assessmentResult = null;
      _wordResults = null;
      _isRecording = false;
      _audioChunks.clear();
      _audioPlayer = null;
      _stream?.getTracks().forEach((track) => track.stop());
      _stream = null;
      _recorder = null;
      _currentTranslation = null; // 번역 숨기기
    });
  }

  @override
  void dispose() {
    // Stop recording if still active
    if (_isRecording) {
      _recorder?.stop();
      _stream?.getTracks().forEach((track) => track.stop());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = _conversationList?.length ?? 0;
    final progress = totalItems > 0 ? (_currentIndex + 1) / totalItems : 0.0;

    if (_isLoadingConversation) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color.fromARGB(179, 59, 197, 221),
          ),
        ),
      );
    }

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
              "발음 연습",
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 진행률 표시
              if (totalItems > 0) ...[
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // Reference text card
              if (_conversationList != null && _conversationList!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    color: Colors.grey[850],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 상단: "따라해보세요:" + 북마크 버튼
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '따라해보세요:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  _bookmarkedSentences.contains(
                                           _conversationList![_currentIndex]['en'])
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                  color: Colors.blue,
                                ),
                                onPressed: () {
                                  if (_bookmarkedSentences.contains(
                                      _conversationList![_currentIndex]['en'])) {
                                    _deleteBookmark();
                                  } else {
                                    _saveBookmark();
                                  }
                                },
                                tooltip: '북마크',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _conversationList![_currentIndex]['en'],
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.blue,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          // 번역 결과 노출 (좌측 정렬)
                          if (_currentTranslation != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: Text(
                                _currentTranslation!,
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.left,
                              ),
                            ),
                          // Add speaker button + 번역 버튼
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 번역 버튼
                                IconButton(
                                  icon: const Icon(Icons.translate,
                                      color: Colors.blue),
                                  tooltip: '번역 보기',
                                  onPressed: () async {
                                    if (_conversationList != null &&
                                        _currentIndex < _conversationList!.length) {
                                      // 버튼을 다시 누르면 번역 숨김
                                      if (_currentTranslation != null) {
                                        setState(() {
                                          _currentTranslation = null;
                                        });
                                      } else {
                                        final translation = await _getKoTranslationForCurrentSentence();
                                        setState(() {
                                          _currentTranslation = translation.isNotEmpty ? translation : '번역 결과가 없습니다.';
                                        });
                                      }
                                    }
                                  },
                                ),
                                // 음성 버튼
                                IconButton(
                                  icon: const Icon(Icons.volume_up,
                                      color: Colors.blue),
                                  onPressed: () async {
                                    if (_conversationList != null &&
                                        _currentIndex <
                                            _conversationList!.length) {
                                      final textToSpeak =
                                          _conversationList![_currentIndex]['en'];
                                      print('Playing text: $textToSpeak');
                                      await _flutterTts.setLanguage("en-US");
                                      await _flutterTts.setSpeechRate(0.8);
                                      await _flutterTts.speak(textToSpeak);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Record button
              ElevatedButton.icon(
                onPressed: _isProcessing
                    ? null
                    : (_isRecording ? _stopRecording : _startRecording),
                icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                label: Text(
                  _isRecording ? 'Stop Recording' : 'Start Recording',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRecording ? Colors.red : Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),

              const SizedBox(height: 16),

              // Next button
              if (//_assessmentResult != null &&
              !_isRecording && !_isProcessing && _conversationList != null)
                (_currentIndex < _conversationList!.length - 1)
                    ? ElevatedButton(
                        onPressed: () {
                          _goToNextSentence();
                        },
                        child: const Text(
                          '다음 문장',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 41, 177, 211),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: () async {
                          // 마지막 문장일 때: 서버로 말한 문장 전송
                          try {
                            final jwt = await TokenManager.getValidAccessToken();
                            if (jwt != null) {
                              final url = Uri.parse(
                                  '$apiBaseUrl/api/public/site/apiInsertTutorSentenceComp');
                              await http.post(
                                url,
                                headers: {
                                  'Authorization': 'Bearer $jwt',
                                  'Content-Type': 'application/json',
                                },
                                body: json.encode({
                                  'course': widget.course,
                                  'lesson': widget.lesson,
                                  'chapter': widget.chapter,
                                  'sentence': _conversationList,
                                  // 필요시 추가 데이터
                                }),
                              );
                            }
                            // 성공/실패에 상관없이 이전 페이지로 이동
                            if (mounted) Navigator.of(context).pop();
                          } catch (e) {
                            if (mounted) Navigator.of(context).pop();
                          }
                        },
                        child: const Text(
                          '학습 완료',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
              const SizedBox(height: 16),

              if (_isProcessing)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    color: Colors.grey[900]?.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color.fromARGB(179, 59, 197, 221),
                      width: 1,
                    ),
                  ),
                  child: const Column(
                    children: [
                      CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Color.fromARGB(179, 59, 197, 221),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Processing your pronunciation...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Please wait while we analyze your speech',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

              // Results chapter
              if (_assessmentResult != null) ...[
                const SizedBox(height: 24),

                // Overall scores
                Card(
                  color: Colors.grey[850],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '발음 점수',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 원형 점수 표시
                        Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 150,
                                height: 150,
                                child: CircularProgressIndicator(
                                  value:
                                      _assessmentResult!['pronunciationScore'] /
                                          100,
                                  strokeWidth: 12,
                                  backgroundColor: Colors.grey[700],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _getScoreColor(_assessmentResult![
                                        'pronunciationScore']),
                                  ),
                                ),
                              ),
                              Text(
                                _assessmentResult!['pronunciationScore']
                                    .round()
                                    .toString(),
                                style: TextStyle(
                                  fontSize: 50,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          '점수 분석 결과',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildScoreBar(
                            '정확도 점수', _assessmentResult!['accuracyScore']),
                        const SizedBox(height: 12),
                        _buildScoreBar(
                            '유창성 점수', _assessmentResult!['fluencyScore']),
                        const SizedBox(height: 12),
                        _buildScoreBar(
                            '완성도 점수', _assessmentResult!['completenessScore']),
                        const SizedBox(height: 12),
                        _buildScoreBar(
                            '운율 점수', _assessmentResult!['prosodyScore']),
                        const SizedBox(height: 20),
                        // 색상 범례
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            _buildColorLegend(Colors.red, '0 ~ 59'),
                            const SizedBox(width: 20),
                            _buildColorLegend(Colors.orange[700]!, '60 ~ 79'),
                            const SizedBox(width: 20),
                            _buildColorLegend(Colors.green, '80 ~ 100'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                if (_wordResults != null && _wordResults!.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 24, bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '단어별 분석',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        // 오른쪽에 오류 개수 표시
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 오디오 플레이어 UI
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _audioPlayer != null && _audioPlayer!.paused
                                ? Icons.play_circle_filled
                                : Icons.pause_circle_filled,
                            color: Colors.blue,
                          ),
                          onPressed: () {
                            if (_audioPlayer != null) {
                              if (_audioPlayer!.paused) {
                                _audioPlayer!.play();
                              } else {
                                _audioPlayer!.pause();
                              }
                              setState(() {});
                            }
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _audioPlayer != null
                              ? _formatDuration(
                                  _audioPlayer!.currentTime?.toDouble())
                              : '00:00',
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SliderTheme(
                            data: SliderThemeData(
                              thumbColor: Colors.blue,
                              activeTrackColor: Colors.blue,
                              inactiveTrackColor: Colors.grey[700],
                              trackHeight: 4.0,
                            ),
                            child: Slider(
                              value:
                                  (_audioPlayer?.currentTime ?? 0).toDouble(),
                              max: (_audioPlayer?.duration?.isFinite == true
                                      ? _audioPlayer!.duration!
                                      : 1)
                                  .toDouble(),
                              onChanged: (value) {
                                if (_audioPlayer != null) {
                                  _audioPlayer!.currentTime = value;
                                  setState(() {});
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _audioPlayer != null
                              ? _formatDuration(
                                  _audioPlayer!.duration?.toDouble())
                              : '00:00',
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.download, color: Colors.white),
                          onPressed: () {
                            if (_audioPlayer != null) {
                              html.AnchorElement()
                                ..href = _audioPlayer!.src
                                ..download = 'recording.webm'
                                ..click();
                            }
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 텍스트 표시 영역
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 8,
                      children: _wordResults!.map<Widget>((word) {
                        final errorType = word['errorType'];

                        // 오류 유형에 따라 색상 설정
                        Color getWordColor(String errorType) {
                          switch (errorType) {
                            case 'Mispronunciation':
                              return Colors.red;
                            case 'Omission':
                              return Colors.orange[700]!;
                            case 'Insertion':
                              return Colors.yellow;
                            case 'Unnecessary pause':
                              return Colors.purple;
                            case 'Missing pause':
                              return Colors.blue;
                            case 'Monotone':
                              return Colors.green;
                            default:
                              return Colors.grey[800]!;
                          }
                        }

                        return _buildWordBox(
                          word['word'],
                          getWordColor(errorType),
                          Colors.white,
                          showErrorCount: errorType != 'None',
                          errorCount: word['accuracyScore'],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 오류 유형 범례
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildLegendItem(
                              errorCounts['Mispronunciation'].toString(),
                              '잘못된 발음',
                              color: Colors.red,
                              tooltipMessage: '발음을 잘못한 경우입니다.',
                            ),
                            _buildLegendItem(
                              errorCounts['Omission'].toString(),
                              '생략',
                              color: Colors.orange,
                              tooltipMessage: '단어를 생략한 경우입니다.',
                            ),
                            _buildLegendItem(
                              errorCounts['Insertion'].toString(),
                              '삽입',
                              color: Colors.yellow,
                              tooltipMessage: '불필요한 단어를 삽입한 경우입니다.',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildLegendItem(
                              errorCounts['Unnecessary pause'].toString(),
                              '불필요한 멈춤',
                              tooltipMessage: '단어를 발음할 때 불필요하게 멈춘 경우입니다.',
                              color: Colors.purple,
                            ),
                            _buildLegendItem(
                              errorCounts['Missing pause'].toString(),
                              '누락된 멈춤',
                              color: Colors.blue,
                              tooltipMessage: '단어를 발음할 때 멈추지 않고 발음한 경우입니다.',
                            ),
                            _buildLegendItem(
                              errorCounts['Monotone'].toString(),
                              '모노톤',
                              tooltipMessage:
                                  '단어을 음조나 감정표현 없이 평탄하고 생기가 없는 톤으로 발음하고 있습니다.',
                              color: Colors.green,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildColorLegend(Color color, String label) {
  return Row(
    children: [
      Container(
        width: 20,
        height: 20,
        color: color,
      ),
      const SizedBox(width: 5),
      Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
      ),
    ],
  );
}

// 점수에 따른 색상 반환 함수
Color _getScoreColor(dynamic score) {
  if (score is num) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange[700]!;
    return Colors.red;
  }
  return Colors.grey;
}

// 점수 바 위젯
Widget _buildScoreBar(String label, dynamic score) {
  final double scoreValue = score is num ? score.toDouble() : 0.0;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          Text(
            '${scoreValue.round()} / 100',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
      const SizedBox(height: 5),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: scoreValue / 100,
          backgroundColor: Colors.grey[700],
          valueColor: AlwaysStoppedAnimation<Color>(_getScoreColor(scoreValue)),
          minHeight: 8,
        ),
      ),
    ],
  );
}

// 단어 상자 위젯
Widget _buildWordBox(String text, Color bgColor, Color textColor,
    {bool showUnderline = false,
    bool showErrorCount = false,
    int errorCount = 0}) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 2),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(4),
      border: showUnderline
          ? Border(
              bottom: BorderSide(
              color: showUnderline ? Colors.purple : Colors.transparent,
              width: 2,
            ))
          : null,
    ),
    child: showErrorCount
        ? Stack(
            alignment: Alignment.topRight,
            children: [
              Text(
                text,
                style: TextStyle(color: textColor),
              ),
              // Container(
              //   width: 16,
              //   height: 16,
              //   alignment: Alignment.center,
              //   decoration: const BoxDecoration(
              //     color: Colors.red,
              //     shape: BoxShape.circle,
              //   ),
              //   child: Text(
              //     errorCount.toString(),
              //     style: const TextStyle(
              //       color: Colors.white,
              //       fontSize: 10,
              //       fontWeight: FontWeight.bold,
              //     ),
              //   ),
              // ),
            ],
          )
        : Text(
            text,
            style: TextStyle(color: textColor),
          ),
  );
}

// 범례 아이템 위젯
Widget _buildLegendItem(String count, String label,
    {Color color = Colors.white, String tooltipMessage = ''}) {
  return Row(
    children: [
      Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          count,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        label,
        style: TextStyle(
          color: color,
        ),
      ),
      const SizedBox(width: 4),
      Tooltip(
        message: tooltipMessage,
        child: const Icon(
          Icons.info_outline,
          size: 16,
          color: Colors.white54,
        ),
      ),
    ],
  );
}

// Note: The above code is a complete implementation of the PronunciationAssessment widget.

                // Word-by-word results
                // if (_wordResults != null && _wordResults!.isNotEmpty) ...[
                //   const Text(
                //     'Word-by-word Analysis:',
                //     style: TextStyle(
                //       fontWeight: FontWeight.bold,
                //       fontSize: 18,
                //     ),
                //   ),
                //   const SizedBox(height: 8),
                //   ListView.builder(
                //     shrinkWrap: true,
                //     physics: const NeverScrollableScrollPhysics(),
                //     itemCount: _wordResults!.length,
                //     itemBuilder: (context, index) {
                //       final word = _wordResults![index];
                //       final errorType = word['errorType'];

                //       final errorTypeTranslations = {
                //         'Mispronunciation': '잘못된 발음',
                //         'Omission': '생략',
                //         'Insertion': '삽입',
                //         'Unnecessary pause': '불필요한 멈춤',
                //         'Missing pause': '누락된 멈춤',
                //         'Monotone': '모노톤',
                //       };

                //       final translatedErrorType =
                //           errorTypeTranslations[errorType] ?? '알 수 없는 오류';

                //       Color color;
                //       if (errorType == 'None') {
                //         color = Colors.green;
                //       } else if (errorType == 'Omission') {
                //         color = Colors.orange;
                //       } else {
                //         color = Colors.red;
                //       }

                //       return Card(
                //         margin: const EdgeInsets.only(bottom: 8),
                //         color: color.withOpacity(0.1),
                //         child: Padding(
                //           padding: const EdgeInsets.symmetric(
                //               vertical: 8, horizontal: 12),
                //           child: Row(
                //             crossAxisAlignment: CrossAxisAlignment.center,
                //             children: [
                //               // Word on the left
                //               Expanded(
                //                 flex: 2,
                //                 child: Text(
                //                   word['word'],
                //                   style: TextStyle(
                //                     fontWeight: FontWeight.bold,
                //                     color: color,
                //                     fontSize: 14, // 줄어든 높이에 맞게 폰트 크기 조정
                //                   ),
                //                 ),
                //               ),
                //               // Accuracy and Error on the right
                //               Expanded(
                //                 flex: 3,
                //                 child: Column(
                //                   crossAxisAlignment: CrossAxisAlignment.end,
                //                   children: [
                //                     Text(
                //                       '정확성: ${word['accuracyScore']?.toStringAsFixed(1) ?? "N/A"}',
                //                       style: TextStyle(
                //                         color: Colors.grey.shade300,
                //                         fontSize: 12, // 줄어든 높이에 맞게 폰트 크기 조정
                //                       ),
                //                     ),
                //                     Text(
                //                       '오류: $translatedErrorType',
                //                       style: TextStyle(
                //                         color: Colors.grey.shade300,
                //                         fontSize: 12, // 줄어든 높이에 맞게 폰트 크기 조정
                //                       ),
                //                     ),
                //                   ],
                //                 ),
                //               ),
                //             ],
                //           ),
                //         ),
                //       );
                //     },
                //   ),
                // ],