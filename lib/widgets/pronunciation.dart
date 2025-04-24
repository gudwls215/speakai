import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PronunciationAssessment extends StatefulWidget {
  final String referenceText;

  const PronunciationAssessment({
    Key? key,
    required this.referenceText,
  }) : super(key: key);

  @override
  State<PronunciationAssessment> createState() =>
      _PronunciationAssessmentState();
}

class _PronunciationAssessmentState extends State<PronunciationAssessment> {
  bool _isRecording = false;
  bool _isProcessing = false;
  Map<String, dynamic>? _assessmentResult;
  List<Map<String, dynamic>>? _wordResults;

  // For web audio recording
  html.MediaRecorder? _recorder;
  List<html.Blob> _audioChunks = [];
  html.MediaStream? _stream;
  html.AudioElement? _audioPlayer;

  @override
  void initState() {
    super.initState();
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
      formData.append('reference_text', widget.referenceText);

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

  // Alternative method using http package (useful if xhr doesn't work well)
  Future<void> _sendToServerWithHttp() async {
    try {
      final blob = html.Blob(_audioChunks, 'audio/webm');
      final reader = html.FileReader();
      final completer = Completer<List<int>>();

      reader.onLoadEnd.listen((event) {
        final result = reader.result;
        final list = (result as List<int>).cast<int>();
        completer.complete(list);
      });

      reader.readAsArrayBuffer(blob);
      final audioBytes = await completer.future;

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://localhost:8000/assess_pronunciation'),
      );

      // Add the audio file
      request.files.add(http.MultipartFile.fromBytes(
        'audio_file',
        audioBytes,
        filename: 'recording.webm',
      ));

      // Add reference text
      request.fields['reference_text'] = widget.referenceText;

      // Send the request
      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseData);
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
      } else {
        print('Server error: ${response.statusCode}');
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      print('Error sending to server: $e');
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pronunciation Assessment'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Reference text card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reference Text:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.referenceText,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ],
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
                label:
                    Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRecording ? Colors.red : Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),

              // Play button
              if (_audioPlayer != null)
                ElevatedButton.icon(
                  onPressed: () {
                    _audioPlayer!.play();
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Play Recording'),
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
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Assessment Results:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildScoreRow('Pronunciation Score',
                            _assessmentResult!['pronunciationScore']),
                        _buildScoreRow('Accuracy Score',
                            _assessmentResult!['accuracyScore']),
                        _buildScoreRow('Completeness Score',
                            _assessmentResult!['completenessScore']),
                        _buildScoreRow('Fluency Score',
                            _assessmentResult!['fluencyScore']),
                        _buildScoreRow('Prosody Score',
                            _assessmentResult!['prosodyScore']),
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
                        child: ListTile(
                          title: Text(
                            word['word'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Accuracy: ${word['accuracyScore']?.toStringAsFixed(1) ?? "N/A"}'),
                              Text('Error type: ${word['errorType']}'),
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

  Widget _buildScoreRow(String label, dynamic score) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            score is num ? score.toStringAsFixed(1) : 'N/A',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
