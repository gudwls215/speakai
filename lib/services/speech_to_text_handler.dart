import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class SpeechToTextHandler {
  final SpeechToText _speech = SpeechToText();
  final ValueNotifier<bool> isListening = ValueNotifier(false);
  bool _speechEnabled = false;

  bool get speechEnabled => _speechEnabled;

  Future<void> initialize({
    required Function(String status) onStatus,
    required Function(String error) onError,
  }) async {
    _speechEnabled = await _speech.initialize(
      onStatus: (status) {
        onStatus(status);
        isListening.value = (status == "listening");
      },
      onError: (error) {
        onError(error as String);
        isListening.value = false;
      },
    );
  }

  void startListening(Function(SpeechRecognitionResult result) onResult) {
    if (_speechEnabled) {
      _speech.listen(onResult: onResult);
      isListening.value = true;
    }
  }

  Future<void> stopListening() async {
    if (isListening.value) {
      await _speech.stop();
      isListening.value = false;
    }
  }
}