import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';

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
  int _currentIndex = 0;
  bool _isRecording = false;
  bool _isProcessing = false;
  Map<String, dynamic>? _assessmentResult;
  List<Map<String, dynamic>>? _wordResults;
  List<String>? _conversationData;
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
    final cacheKey = _generateCacheKey();

    try {
      // Try to load from cache
      final cachedData = await _loadCachedConversationData(cacheKey);

      if (cachedData != null && cachedData.isNotEmpty) {
        // Use cached data
        setState(() {
          _conversationData = cachedData;
        });
      } else {
        // Fetch from API if not in cache
        await _fetchConversationDataFromApi(cacheKey);
      }
    } catch (e) {
      print("Error loading cached conversation data: $e");
      // Fallback to API if cache fails
      await _fetchConversationDataFromApi(cacheKey);
    }
  }

  // Load cached conversation data
  Future<List<String>?> _loadCachedConversationData(String cacheKey) async {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedData = prefs.getString('conversation_data_$cacheKey');

    if (cachedData != null) {
      return List<String>.from(jsonDecode(cachedData));
    }
    return null;
  }

  // Save conversation data to cache
  Future<void> _cacheConversationData(
      String cacheKey, List<String> dataToCache) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'conversation_data_$cacheKey', jsonEncode(dataToCache));
  }

  // Fetch conversation data from API
  Future<void> _fetchConversationDataFromApi(String cacheKey) async {
    final url = Uri.parse(
        'http://192.168.0.147:8000/conversation?course=${widget.course}&lesson=${widget.lesson}&chapter=${widget.chapter}&text=${widget.text}');
    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final conversation = List<String>.from(data['conversation']);

        // Cache the data
        await _cacheConversationData(cacheKey, conversation);

        setState(() {
          _conversationData = conversation;
        });
      } else {
        print('Failed to fetch conversation data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching conversation data: $e');
    }
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

        setState(() {
          _isProcessing = false;
        });

        // Process the recording
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
      if (_conversationData != null &&
          _currentIndex < _conversationData!.length) {
        formData.append('reference_text', _conversationData![_currentIndex]);
      } else {
        print('Invalid conversation data or index');
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // Send to server
      final url = 'http://192.168.0.147:8000/assess_pronunciation';
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
    final totalItems = _conversationData?.length ?? 0;
    final progress = totalItems > 0 ? (_currentIndex + 1) / totalItems : 0.0;

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
              if (_conversationData != null && _conversationData!.isNotEmpty)
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
                          const Text(
                            '따라해보세요:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _conversationData![_currentIndex],
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.blue,
                            ),
                            textAlign: TextAlign.center,
                          ),
// Add speaker button
                          Align(
                            alignment: Alignment.bottomRight,
                            child: IconButton(
                              icon: const Icon(Icons.volume_up,
                                  color: Colors.blue),
                              onPressed: () async {
                                if (_conversationData != null &&
                                    _currentIndex < _conversationData!.length) {
                                  final textToSpeak =
                                      _conversationData![_currentIndex];
                                  print('Playing text: $textToSpeak');

                                  // Use FlutterTTS to speak the text
                                  await _flutterTts
                                      .setLanguage("en-US"); // Set the language
                                  await _flutterTts
                                      .setSpeechRate(0.8); // Adjust speech rate
                                  await _flutterTts
                                      .speak(textToSpeak); // Speak the text
                                }
                              },
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
              if (!_isRecording && !_isProcessing && _conversationData != null)
                ElevatedButton(
                  onPressed: _currentIndex < totalItems - 1
                      ? () {
                          setState(() {
                            _currentIndex++;
                            _assessmentResult = null; // 평가 결과 초기화
                            _wordResults = null; // 단어 결과 초기화

                            // 녹음 관련 상태 초기화
                            _isRecording = false;
                            _audioChunks.clear();
                            _audioPlayer = null;
                            _stream
                                ?.getTracks()
                                .forEach((track) => track.stop());
                            _stream = null;
                            _recorder = null;
                          });
                        }
                      : null,
                  child: const Text(
                    '다음 문장',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 41, 177, 211),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),

              const SizedBox(height: 16),

              if (_isProcessing)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color.fromARGB(179, 59, 197, 221),
                        ),
                        SizedBox(height: 16),
                        Text('Processing your pronunciation...'),
                      ],
                    ),
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