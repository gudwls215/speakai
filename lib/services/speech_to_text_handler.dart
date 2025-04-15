import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class SpeechToTextHandler {
  final SpeechToText _speech = SpeechToText();
  final ValueNotifier<bool> isListening = ValueNotifier(false);
  bool _speechEnabled = false;
  Timer? _inactivityTimer;

  bool get speechEnabled => _speechEnabled;

  Future<void> initialize({
    required Function(String status) onStatus,
    required Function(String error) onError,
  }) async {
    _speechEnabled = await _speech.initialize(
      onStatus: (status) {
        onStatus(status);
        isListening.value = (status == "listening");

        // Reset inactivity timer if listening
        if (status == "listening") {
          _resetInactivityTimer();
        } else {
          _cancelInactivityTimer();
        }
      },
      onError: (dynamic error) {
        onError(error.toString());
        isListening.value = false;
        _cancelInactivityTimer();
      },
    );
  }

  void startListening(Function(SpeechRecognitionResult result) onResult) {
    if (_speechEnabled) {
      _speech.listen(onResult: onResult, localeId: "en_US");
      isListening.value = true;
      _resetInactivityTimer();
    }
  }

  Future<void> stopListening() async {
    if (isListening.value) {
      await _speech.stop();
      isListening.value = false;
      _cancelInactivityTimer();
    }
  }

  void _resetInactivityTimer() {
    _cancelInactivityTimer();
    _inactivityTimer = Timer(const Duration(seconds: 6), () {
      stopListening();
    });
  }

  void _cancelInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }
}