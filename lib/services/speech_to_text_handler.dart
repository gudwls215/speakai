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
    try {
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
      
      if (!_speechEnabled) {
        throw Exception('Speech recognition not available or permission denied');
      }
    } catch (e) {
      _speechEnabled = false;
      onError(e.toString());
      throw e; // 오류를 다시 던져서 호출하는 곳에서 처리할 수 있도록 함
    }
  }

  void startListening(Function(SpeechRecognitionResult result) onResult) {
    if (_speechEnabled) {
      try {
        _speech.listen(onResult: onResult, localeId: "en_US");
        isListening.value = true;
        _resetInactivityTimer();
      } catch (e) {
        isListening.value = false;
        _cancelInactivityTimer();
        throw e; // 오류를 다시 던져서 호출하는 곳에서 처리할 수 있도록 함
      }
    } else {
      throw Exception('Speech recognition not initialized or permission denied');
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