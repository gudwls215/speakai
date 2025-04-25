import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PronunciationAssessment extends StatefulWidget {
  final String course;
  final String chapter;
  final String section;

  const PronunciationAssessment(this.course, this.chapter, this.section,
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

  // For web audio recording
  html.MediaRecorder? _recorder;
  List<html.Blob> _audioChunks = [];
  html.MediaStream? _stream;
  html.AudioElement? _audioPlayer;

  @override
  void initState() {
    super.initState();
    _fetchConversationData();
  }

  Future<void> _fetchConversationData() async {
    final url = Uri.parse(
        'http://192.168.0.147:8000/conversation?course=${widget.course}&chapter=${widget.chapter}&section=${widget.section}');
    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Conversation data: $data');
        setState(() {
          _conversationData = List<String>.from(data['conversation']);
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

              // Play button
              if (_audioPlayer != null)
                ElevatedButton.icon(
                  onPressed: () {
                    _audioPlayer!.play();
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text(
                    '재생',
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

              if (_isProcessing)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Processing your pronunciation...'),
                      ],
                    ),
                  ),
                ),

              // Results section
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
                          '평과 결과:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildScoreRow(
                            '발음 점수', _assessmentResult!['pronunciationScore']),
                        _buildScoreRow(
                            '정확도 점수', _assessmentResult!['accuracyScore']),
                        _buildScoreRow(
                            '완성도 점수', _assessmentResult!['completenessScore']),
                        _buildScoreRow(
                            '유창성 점수', _assessmentResult!['fluencyScore']),
                        _buildScoreRow(
                            '운율 점수', _assessmentResult!['prosodyScore']),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Word-by-word results
                if (_wordResults != null && _wordResults!.isNotEmpty) ...[
                  const Text(
                    'Word-by-word Analysis:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _wordResults!.length,
                    itemBuilder: (context, index) {
                      final word = _wordResults![index];
                      final errorType = word['errorType'];

                      final errorTypeTranslations = {
                        'Mispronunciation': '잘못된 발음',
                        'Omission': '생략',
                        'Insertion': '삽입',
                        'Unnecessary pause': '불필요한 멈춤',
                        'Missing pause': '누락된 멈춤',
                        'Monotone': '모노톤',
                      };

                      final translatedErrorType =
                          errorTypeTranslations[errorType] ?? '알 수 없는 오류';

                      Color color;
                      if (errorType == 'None') {
                        color = Colors.green;
                      } else if (errorType == 'Omission') {
                        color = Colors.orange;
                      } else {
                        color = Colors.red;
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: color.withOpacity(0.1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Word on the left
                              Expanded(
                                flex: 2,
                                child: Text(
                                  word['word'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                    fontSize: 14, // 줄어든 높이에 맞게 폰트 크기 조정
                                  ),
                                ),
                              ),
                              // Accuracy and Error on the right
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '정확성: ${word['accuracyScore']?.toStringAsFixed(1) ?? "N/A"}',
                                      style: TextStyle(
                                        color: Colors.grey.shade300,
                                        fontSize: 12, // 줄어든 높이에 맞게 폰트 크기 조정
                                      ),
                                    ),
                                    Text(
                                      '오류: $translatedErrorType',
                                      style: TextStyle(
                                        color: Colors.grey.shade300,
                                        fontSize: 12, // 줄어든 높이에 맞게 폰트 크기 조정
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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

Widget _buildScoreRow(String label, dynamic score) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        Text(
          score is num ? score.toStringAsFixed(1) : 'N/A',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: 
            score is num && score >= 70
                ? Colors.green
                : score is num && score >= 20
                    ? Colors.orange
                    : Colors.red,
          ),
        ),
      ],
    ),
  );
}
