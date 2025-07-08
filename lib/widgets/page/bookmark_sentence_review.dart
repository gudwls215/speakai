import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:speakai/config.dart';
import 'package:speakai/utils/token_manager.dart';

class BookmarSentenceReview extends StatefulWidget {
  final List<dynamic> bookmarks;

  const BookmarSentenceReview(this.bookmarks, {Key? key}) : super(key: key);

  @override
  State<BookmarSentenceReview> createState() => _BookmarSentenceReviewState();
}

class _BookmarSentenceReviewState extends State<BookmarSentenceReview> {
  late FlutterTts flutterTts;
  late stt.SpeechToText speech;
  int currentIndex = 0;
  bool isRecording = false;
  bool isPaused = false;
  bool showHint = false;
  String userSpeech = "";
  late PageController _pageController;
  int maxPage = 0; // 마지막으로 학습한 페이지 인덱스
  int lastTtsIndex = -1; // 마지막으로 TTS가 실행된 인덱스
  bool isListening = false;
  List<String> spokenWords = []; // 사용자가 말한 단어들
  Map<String, String> keywordCache = {}; // 문장별 핵심 단어 캐시

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88, initialPage: 0);
    flutterTts = FlutterTts();
    flutterTts.setLanguage('en-US'); // 언어 설정
    flutterTts.setSpeechRate(0.9);

    // STT 초기화
    speech = stt.SpeechToText();
    _initializeSpeech();

    // 첫 진입 시 첫 카드 TTS 실행 (2초 지연)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.bookmarks.isNotEmpty) {
        await Future.delayed(const Duration(seconds: 2));
        final sentence = widget.bookmarks[0]['sentence'] ?? '';
        speakSentence(sentence);
        setState(() {
          lastTtsIndex = 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    flutterTts.stop();
    speech.stop();
    super.dispose();
  }

  Future<void> _initializeSpeech() async {
    await speech.initialize(
      onStatus: (status) {
        print('STT Status: $status');
        if (status == 'done' || status == 'notListening') {
          setState(() {
            isListening = false;
            isRecording = false;
          });
        }
      },
      onError: (error) {
        print('STT Error: $error');
        setState(() {
          isListening = false;
          isRecording = false;
        });
      },
    );
  }

  Future<String> _getKeywordFromAPI(String sentence) async {
    // 캐시에서 먼저 확인
    if (keywordCache.containsKey(sentence)) {
      return keywordCache[sentence]!;
    }

    try {
      final jwt = await TokenManager.getValidAccessToken();
      if (jwt == null) {
        print('[API] JWT token not available, using fallback');
        return _getFallbackKeyword(sentence);
      }

      final response = await http.post(
        Uri.parse('$aiBaseUrl/sentences/keyword'),
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'sentence': sentence,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final keyword = data['keyword'] ?? _getFallbackKeyword(sentence);
        
        // 캐시에 저장
        keywordCache[sentence] = keyword;
        return keyword;
      } else {
        print('[API] Error response: ${response.statusCode} - ${response.body}');
        return _getFallbackKeyword(sentence);
      }
    } catch (e) {
      print('[API] Exception occurred: $e');
      return _getFallbackKeyword(sentence);
    }
  }

  String _getFallbackKeyword(String sentence) {
    // API 호출 실패 시 기존 로직으로 폴백
    final words = sentence.split(' ');
    if (words.length <= 1) return '';
    
    int maxLen = 0;
    String keyword = '';
    for (String word in words) {
      if (word.length > maxLen) {
        maxLen = word.length;
        keyword = word;
      }
    }
    return keyword;
  }

  Future<void> _startListening() async {
    if (!isListening && speech.isAvailable) {
      // 녹음 시작 시 TTS 중지
      await flutterTts.stop();
      
      setState(() {
        isListening = true;
        isRecording = true;
        userSpeech = "듣고 있습니다...";
      });

      await speech.listen(
        onResult: (result) {
          setState(() {
            userSpeech = result.recognizedWords;
            // 부분 결과도 처리하여 실시간 피드백 제공
            _processSpokenText(result.recognizedWords);
          });
          
          // 최종 결과일 때 녹음 상태 업데이트
          if (result.finalResult) {
            print('[STT] Final result received, stopping recording');
            setState(() {
              isListening = false;
              isRecording = false;
            });
          }
        },
        listenFor: const Duration(seconds: 30), // 더 긴 시간 허용
        pauseFor: const Duration(seconds: 5), // 짧은 정지 시간
        partialResults: true,
        localeId: 'en_US',
        cancelOnError: false, // 오류 시에도 계속 시도
        listenMode: stt.ListenMode.dictation, // 받아쓰기 모드로 정확도 향상
      );
    }
  }

  void _stopListening() {
    if (isListening) {
      speech.stop();
      setState(() {
        isListening = false;
        isRecording = false;
      });
    }
  }

  void _processSpokenText(String spokenText) {
    final currentItem = widget.bookmarks[currentIndex];
    final sentence = currentItem['sentence'] ?? '';
    final sentenceWords = sentence.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').split(' ');
    final spoken = spokenText.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').split(' ');
    
    print('[STT] 처리 중: 말한 내용="$spokenText", 문장 단어=$sentenceWords');
    
    setState(() {
      int beforeCount = spokenWords.length;
      
      // 1. 정확한 매칭
      for (String word in spoken) {
        if (sentenceWords.contains(word) && !spokenWords.contains(word)) {
          spokenWords.add(word);
          print('[STT] 정확 매칭: $word');
        }
      }
      
      // 2. 유사도 기반 매칭 (편집 거리 2 이하)
      for (String spokenWord in spoken) {
        if (spokenWord.length >= 3) { // 3글자 이상인 경우만
          for (String sentenceWord in sentenceWords) {
            if (!spokenWords.contains(sentenceWord) && 
                _calculateLevenshteinDistance(spokenWord, sentenceWord) <= 2 &&
                _isSimilarLength(spokenWord, sentenceWord)) {
              spokenWords.add(sentenceWord);
              print('[STT] 유사도 매칭: $spokenWord -> $sentenceWord (거리: ${_calculateLevenshteinDistance(spokenWord, sentenceWord)})');
            }
          }
        }
      }
      
      // 3. 부분 문자열 매칭 (4글자 이상인 경우)
      for (String spokenWord in spoken) {
        if (spokenWord.length >= 4) {
          for (String sentenceWord in sentenceWords) {
            if (!spokenWords.contains(sentenceWord) && sentenceWord.length >= 4) {
              if (sentenceWord.contains(spokenWord) || spokenWord.contains(sentenceWord)) {
                spokenWords.add(sentenceWord);
                print('[STT] 부분 매칭: $spokenWord -> $sentenceWord');
              }
            }
          }
        }
      }
      
      // 4. 발음 유사성 매칭
      for (String spokenWord in spoken) {
        for (String sentenceWord in sentenceWords) {
          if (!spokenWords.contains(sentenceWord) && 
              _checkPhoneticSimilarity(spokenWord, sentenceWord)) {
            spokenWords.add(sentenceWord);
            print('[STT] 발음 유사성 매칭: $spokenWord -> $sentenceWord');
          }
        }
      }
      
      int newMatches = spokenWords.length - beforeCount;
      if (newMatches > 0) {
        print('[STT] 총 ${newMatches}개 새로운 단어 매칭됨. 현재 총 ${spokenWords.length}개');
      }
    });
  }

  // Levenshtein Distance 계산 (편집 거리)
  int _calculateLevenshteinDistance(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    
    List<List<int>> matrix = List.generate(
      a.length + 1, 
      (i) => List.generate(b.length + 1, (j) => 0)
    );
    
    for (int i = 0; i <= a.length; i++) matrix[i][0] = i;
    for (int j = 0; j <= b.length; j++) matrix[0][j] = j;
    
    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        int cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,      // deletion
          matrix[i][j - 1] + 1,      // insertion
          matrix[i - 1][j - 1] + cost // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    
    return matrix[a.length][b.length];
  }

  // 길이 유사성 검사 (너무 다른 길이는 제외)
  bool _isSimilarLength(String a, String b) {
    int diff = (a.length - b.length).abs();
    int maxLen = a.length > b.length ? a.length : b.length;
    return diff <= (maxLen * 0.4).round(); // 40% 이내 차이만 허용
  }

  // 발음 유사성 검사 (흔한 발음 오류 패턴)
  bool _checkPhoneticSimilarity(String spoken, String target) {
    // 흔한 발음 오류 패턴들
    Map<String, List<String>> phoneticPatterns = {
      'th': ['d', 't', 's'],
      'v': ['b', 'f'],
      'w': ['v', 'u'],
      'r': ['l'],
      'l': ['r'],
      'p': ['b'],
      'b': ['p'],
      't': ['d'],
      'd': ['t'],
      'k': ['g'],
      'g': ['k'],
      'f': ['p', 'v'],
      's': ['z', 'th'],
      'z': ['s'],
    };
    
    // 단어가 너무 다르면 검사하지 않음
    if (!_isSimilarLength(spoken, target)) return false;
    
    String normalizedSpoken = spoken;
    String normalizedTarget = target;
    
    // 발음 패턴 적용
    phoneticPatterns.forEach((correct, alternatives) {
      for (String alt in alternatives) {
        normalizedSpoken = normalizedSpoken.replaceAll(alt, correct);
        normalizedTarget = normalizedTarget.replaceAll(alt, correct);
      }
    });
    
    // 정규화된 단어들의 편집 거리가 1 이하면 유사하다고 판단
    return _calculateLevenshteinDistance(normalizedSpoken, normalizedTarget) <= 1;
  }

  Future<void> speakSentence(String sentence) async {
    print('[TTS] speakSentence called: $sentence');
    await flutterTts.stop();
    await flutterTts.speak(sentence);
  }

  void nextSentence() {
    if (currentIndex < widget.bookmarks.length - 1) {
      // 다음 페이지로 이동 시 TTS 중지
      flutterTts.stop();
      
      setState(() {
        maxPage = currentIndex + 1 > maxPage ? currentIndex + 1 : maxPage;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      // TTS 관련 코드는 제거 (onPageChanged에서만 실행)
    } else {
      // 모든 문장 완료
      flutterTts.stop(); // 완료 시에도 TTS 중지
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Color(0xFF23272F),
          title: const Text('학습 완료', style: TextStyle(color: Colors.white)),
          content: const Text('모든 보관한 표현 학습을 완료했습니다!',
              style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('확인', style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      );
    }
  }

  void previousSentence() {
    if (currentIndex > 0) {
      // 이전 페이지로 이동 시 TTS 중지
      flutterTts.stop();
      
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void toggleRecording() {
    if (isRecording) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  void toggleHint() {
    setState(() {
      showHint = !showHint;
    });
  }

  Widget _buildHighlightedSentence(String sentence, String beforeBlank, String afterBlank) {
    return FutureBuilder<String>(
      future: _getKeywordFromAPI(sentence),
      builder: (context, snapshot) {
        String blankWord = '';
        if (snapshot.hasData) {
          blankWord = snapshot.data!.toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
        } else {
          // 로딩 중이거나 오류 시 기존 로직으로 폴백
          blankWord = _getFallbackKeyword(sentence).toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
        }
        
        return _buildHighlightedSentenceWithKeyword(sentence, beforeBlank, afterBlank, blankWord);
      },
    );
  }

  Widget _buildHighlightedSentenceWithKeyword(String sentence, String beforeBlank, String afterBlank, String blankWord) {
    List<InlineSpan> spans = [];
    
    // beforeBlank 처리
    if (beforeBlank.isNotEmpty) {
      final beforeWords = beforeBlank.split(' ');
      for (int i = 0; i < beforeWords.length; i++) {
        final word = beforeWords[i];
        final cleanWord = word.toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
        final isSpoken = spokenWords.contains(cleanWord);
        
        spans.add(TextSpan(
          text: word + (i < beforeWords.length - 1 ? ' ' : ''),
          style: TextStyle(
            color: isSpoken ? Colors.green : Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            backgroundColor: isSpoken ? Colors.green.withOpacity(0.3) : null,
          ),
        ));
      }
      spans.add(const TextSpan(text: ' '));
    }
    
    // 빈칸 추가 (인식된 경우 원래 단어를 초록색으로 표시)
    final isBlankSpoken = spokenWords.contains(blankWord);
    if (isBlankSpoken) {
      // 인식된 경우: 원래 단어를 초록색으로 표시
      final words = sentence.split(' ');
      final originalWord = words.firstWhere(
        (word) => word.toLowerCase().replaceAll(RegExp(r'[^\w]'), '') == blankWord,
        orElse: () => blankWord,
      );
      spans.add(TextSpan(
        text: originalWord,
        style: TextStyle(
          color: Colors.green,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          backgroundColor: Colors.green.withOpacity(0.3),
        ),
      ));
    } else {
      // 인식되지 않은 경우: 기존 빈칸 표시
      spans.add(WidgetSpan(
        child: Container(
          width: 60,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: const Text('', style: TextStyle(fontSize: 14)),
        ),
      ));
    }
    
    // afterBlank 처리
    if (afterBlank.isNotEmpty) {
      spans.add(const TextSpan(text: ' '));
      final afterWords = afterBlank.split(' ');
      for (int i = 0; i < afterWords.length; i++) {
        final word = afterWords[i];
        final cleanWord = word.toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
        final isSpoken = spokenWords.contains(cleanWord);
        
        spans.add(TextSpan(
          text: word + (i < afterWords.length - 1 ? ' ' : ''),
          style: TextStyle(
            color: isSpoken ? Colors.green : Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            backgroundColor: isSpoken ? Colors.green.withOpacity(0.3) : null,
          ),
        ));
      }
    }
    
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(children: spans),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookmarks = widget.bookmarks;
    if (bookmarks.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          automaticallyImplyLeading: false,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('보관한 표현 학습', style: TextStyle(color: Colors.white)),
        ),
        body: const Center(
          child: Text('보관한 표현이 없습니다.', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            flutterTts.stop(); // 닫기 시 TTS 중지
            Navigator.pop(context);
          },
        ),
        title: LinearProgressIndicator(
          value: (currentIndex + 1) / bookmarks.length,
          backgroundColor: Colors.grey[900],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
        actions: [
          IconButton(
            icon: Icon(isPaused ? Icons.volume_off : Icons.volume_up,
                color: Colors.white),
            onPressed: () {
              flutterTts.stop(); // 음소거 토글 시 TTS 중지
              setState(() {
                isPaused = !isPaused;
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // 메인 카드 박스 - PageView로 스크롤 지원
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  // 스와이프 제한: 앞으로 넘기려는 경우 maxPage까지만 허용
                  if (notification is ScrollUpdateNotification &&
                      _pageController.hasClients) {
                    final page = _pageController.page ?? 0;
                    if (page > maxPage) {
                      _pageController.animateToPage(
                        maxPage,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                      );
                      return true;
                    }
                  }
                  return false;
                },
                child: PageView.builder(
                  controller: _pageController,
                  physics: const ClampingScrollPhysics(),
                  onPageChanged: (index) async {
                    // 페이지 변경 시 TTS 중지
                    await flutterTts.stop();
                    
                    setState(() {
                      currentIndex = index;
                      isRecording = false;
                      isPaused = false;
                      showHint = false;
                      userSpeech = "";
                      spokenWords.clear(); // 새로운 카드로 넘어갈 때 말한 단어들 초기화
                    });
                    print(
                        '[TTS] onPageChanged: index=$index, maxPage=$maxPage, lastTtsIndex=$lastTtsIndex');
                    // TTS: 학습하지 않은 카드에 진입할 때만 읽어줌 (중복 방지)
                    if (index >= maxPage && lastTtsIndex != index) {
                      final item = bookmarks[index];
                      final sentence = item['sentence'] ?? '';
                      print('[TTS] speakSentence triggered for index $index');
                      await speakSentence(sentence);
                      setState(() {
                        lastTtsIndex = index;
                      });
                    }
                  },
                  itemCount: bookmarks.length,
                  itemBuilder: (context, index) {
                    final item = bookmarks[index];
                    final sentence = item['sentence'] ?? '';
                    final translate = item['translate'] ?? '';
                    
                    return FutureBuilder<String>(
                      future: _getKeywordFromAPI(sentence),
                      builder: (context, keywordSnapshot) {
                        // 빈칸 처리: API에서 받아온 핵심 단어를 기반으로 처리
                        final words = sentence.split(' ');
                        String beforeBlank = '';
                        String afterBlank = '';
                        
                        if (words.length > 1) {
                          String keyword = keywordSnapshot.hasData 
                              ? keywordSnapshot.data! 
                              : _getFallbackKeyword(sentence);
                          
                          // 핵심 단어의 인덱스 찾기
                          int blankIdx = -1;
                          for (int i = 0; i < words.length; i++) {
                            if (words[i].toLowerCase().replaceAll(RegExp(r'[^\w]'), '') == 
                                keyword.toLowerCase().replaceAll(RegExp(r'[^\w]'), '')) {
                              blankIdx = i;
                              break;
                            }
                          }
                          
                          if (blankIdx != -1) {
                            beforeBlank = words.sublist(0, blankIdx).join(' ');
                            afterBlank = words.sublist(blankIdx + 1).join(' ');
                          } else {
                            // 핵심 단어를 찾지 못한 경우 기존 방식으로 폴백
                            int maxLen = 0;
                            int fallbackIdx = 0;
                            for (int i = 0; i < words.length; i++) {
                              if (words[i].length > maxLen) {
                                maxLen = words[i].length;
                                fallbackIdx = i;
                              }
                            }
                            beforeBlank = words.sublist(0, fallbackIdx).join(' ');
                            afterBlank = words.sublist(fallbackIdx + 1).join(' ');
                          }
                        } else {
                          beforeBlank = sentence;
                        }

                        return Padding(
                          padding: EdgeInsets.only(
                            left: index == 0 ? 16.0 : 0.0, // 첫 카드는 좌측 패딩
                            right: 16.0,
                            top: 0,
                            bottom: 0,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF181B2A),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 24, horizontal: 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // 안내 텍스트
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isRecording
                                        ? (userSpeech.isNotEmpty && userSpeech != "듣고 있습니다..." 
                                           ? '인식: $userSpeech' 
                                           : '듣고 있습니다... 천천히 말해보세요')
                                        : '버튼을 눌러 연습을 시작하세요',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                // 진행 상황 표시
                                if (spokenWords.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                                      ),
                                      child: Text(
                                        '${spokenWords.length}개 단어 인식됨 ✓',
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 24),
                                // 문장 표시 (빈칸 포함 + 말한 단어 하이라이트)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: _buildHighlightedSentence(sentence, beforeBlank, afterBlank),
                                ),
                                const SizedBox(height: 24),
                                // 힌트
                                if (translate.toString().isNotEmpty)
                                  GestureDetector(
                                    onTap: toggleHint,
                                    child: Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 8,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.yellow[700],
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text('힌트',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        AnimatedOpacity(
                                          opacity: showHint ? 1.0 : 0.0,
                                          duration:
                                              const Duration(milliseconds: 300),
                                          child: ConstrainedBox(
                                            constraints:
                                                const BoxConstraints(maxWidth: 320),
                                            child: Text(
                                              translate,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12),
                                              softWrap: true,
                                              overflow: TextOverflow.visible,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 24),
                                const Spacer(),
                                // 플레이/녹음/다시 버튼 (카드 하단 고정)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.replay,
                                          color: Colors.white, size: 32),
                                      onPressed: () async {
                                        final item = bookmarks[index];
                                        final sentence = item['sentence'] ?? '';
                                        await speakSentence(sentence);
                                      },
                                    ),
                                    const SizedBox(width: 16),
                                    IconButton(
                                      icon: Icon(
                                          isRecording
                                              ? Icons.pause_circle
                                              : Icons.play_circle,
                                          color: Colors.blue,
                                          size: 48),
                                      onPressed: toggleRecording,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            // 다음 버튼
            Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: nextSentence,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black, // 검은색 배경
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      const Text('다음으로 넘어가기', style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
