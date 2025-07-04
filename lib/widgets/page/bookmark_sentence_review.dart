import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class BookmarSentenceReview extends StatefulWidget {
  final List<dynamic> bookmarks;

  const BookmarSentenceReview(
      this.bookmarks,
      {Key? key})
      : super(key: key);

  @override
  State<BookmarSentenceReview> createState() => _BookmarSentenceReviewState();
}

class _BookmarSentenceReviewState extends State<BookmarSentenceReview> {
  late FlutterTts flutterTts;
  int currentIndex = 0;
  bool isRecording = false;
  bool isPaused = false;
  bool showHint = false;
  String userSpeech = "";
  late PageController _pageController;
  int maxPage = 0; // 마지막으로 학습한 페이지 인덱스
  int lastTtsIndex = -1; // 마지막으로 TTS가 실행된 인덱스

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88, initialPage: 0);
    flutterTts = FlutterTts();
    flutterTts.setLanguage('ko-KR');
    flutterTts.setSpeechRate(0.4);
  }

  @override
  void dispose() {
    _pageController.dispose();
    flutterTts.stop();
    super.dispose();
  }

  Future<void> speakSentence(String sentence) async {
    await flutterTts.stop();
    await flutterTts.speak(sentence);
  }

  void nextSentence() {
    if (currentIndex < widget.bookmarks.length - 1) {
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
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Color(0xFF23272F),
          title: const Text('학습 완료', style: TextStyle(color: Colors.white)),
          content: const Text('모든 보관한 표현 학습을 완료했습니다!', style: TextStyle(color: Colors.white70)),
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
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void toggleRecording() {
    setState(() {
      isRecording = !isRecording;
      if (isRecording) {
        userSpeech = "이제 스피킹 하세요...";
      }
    });
  }

  void toggleHint() {
    setState(() {
      showHint = !showHint;
    });
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
          onPressed: () => Navigator.pop(context),
        ),
        title: LinearProgressIndicator(
          value: (currentIndex + 1) / bookmarks.length,
          backgroundColor: Colors.grey[900],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
        actions: [
          IconButton(
            icon: Icon(isPaused ? Icons.volume_off : Icons.volume_up, color: Colors.white),
            onPressed: () {
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
                  if (notification is ScrollUpdateNotification && _pageController.hasClients) {
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
                    setState(() {
                      currentIndex = index;
                      isRecording = false;
                      isPaused = false;
                      showHint = false;
                      userSpeech = "";
                    });
                    // TTS: 학습하지 않은 카드에 진입할 때만 읽어줌 (중복 방지)
                    if (index > maxPage && lastTtsIndex != index) {
                      final item = bookmarks[index];
                      final sentence = item['sentence'] ?? '';
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
                    // 빈칸 처리: 문장의 핵심 단어(가장 긴 단어)를 blank로 처리
                    final words = sentence.split(' ');
                    String beforeBlank = '';
                    String afterBlank = '';
                    if (words.length > 1) {
                      // 가장 긴 단어를 blank로
                      int maxLen = 0;
                      int blankIdx = 0;
                      for (int i = 0; i < words.length; i++) {
                        if (words[i].length > maxLen) {
                          maxLen = words[i].length;
                          blankIdx = i;
                        }
                      }
                      beforeBlank = words.sublist(0, blankIdx).join(' ');
                      afterBlank = words.sublist(blankIdx + 1).join(' ');
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
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 안내 텍스트
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isRecording ? '이제 스피킹 하세요...' : '버튼을 눌러 연습을 시작하세요',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // 문장 표시 (빈칸 포함)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  children: [
                                    TextSpan(text: beforeBlank.isNotEmpty ? beforeBlank + ' ' : '', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                                    WidgetSpan(
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
                                    ),
                                    TextSpan(text: afterBlank.isNotEmpty ? ' ' + afterBlank : '', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
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
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.yellow[700],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('힌트', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                    AnimatedOpacity(
                                      opacity: showHint ? 1.0 : 0.0,
                                      duration: const Duration(milliseconds: 300),
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 320),
                                        child: Text(
                                          translate,
                                          style: const TextStyle(color: Colors.white, fontSize: 12),
                                          softWrap: true,
                                          overflow: TextOverflow.visible,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 24),
                            // 플레이/녹음/다시 버튼
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.replay, color: Colors.white, size: 32),
                                  onPressed: () {},
                                ),
                                const SizedBox(width: 16),
                                IconButton(
                                  icon: Icon(isRecording ? Icons.pause_circle : Icons.play_circle, color: Colors.blue, size: 48),
                                  onPressed: toggleRecording,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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
                  child: const Text('다음으로 넘어가기', style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
