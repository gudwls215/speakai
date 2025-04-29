import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:speakai/providers/free_talk_provider.dart';
import 'package:speakai/services/speech_to_text_handler.dart';
import 'package:speakai/services/sse_service.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_tts/flutter_tts.dart';

class FreeTalkMessage extends StatefulWidget {
  final String title;
  final String emoji;
  final String userRole;
  final String aiRole;
  final String description;
  final String postId;

  const FreeTalkMessage({
    Key? key,
    required this.title,
    required this.emoji,
    required this.userRole,
    required this.aiRole,
    required this.description,
    required this.postId,
  }) : super(key: key);

  @override
  State<FreeTalkMessage> createState() => _FreeTalkMessageState();
}

class _FreeTalkMessageState extends State<FreeTalkMessage> {
  final TextEditingController _textController = TextEditingController();
  final SpeechToTextHandler _speechHandler = SpeechToTextHandler();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  FreeTalkProvider _freeTalkProvider = FreeTalkProvider();
  bool _isLoading = false;
  String _recognizedText = "";
  String _hintText = "무슨 말을 해야할지 모르겠다면 힌트를 눌러보세요!";
  String _hintTextFromAPI = "";
  String _commentKoFromAPI = "";
  bool _isLoadingHint = false;
  bool _showCommentKo = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();

    _freeTalkProvider = Provider.of<FreeTalkProvider>(context, listen: false);

    _freeTalkProvider.postId.value = widget.postId;

    if (_freeTalkProvider.getMessagesNotifier(widget.postId).value.isEmpty) {
      _freeTalkProvider.add(
        TalkMessage(
          text: "Welcome to the conversation!",
          isUser: false,
          postId: widget.postId,
        ),
        widget.postId,
      );
    }
  }

  void _initSpeech() async {
    await _speechHandler.initialize(
      onStatus: (status) {
        print("onStatus: $status");
        setState(() {});
      },
      onError: (dynamic error) {
        print("Error: ${error.toString()}");
        setState(() {});
      },
    );

    if (!_speechHandler.isListening.value) {
      _showMicPermissionDialog();
    }
  }

  void _showMicPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('마이크 권한 필요'),
        content: Text('음성 인식을 사용하려면 브라우저에서 마이크 권한을 허용해주세요. '
            '주소창 옆 🔒 아이콘을 클릭해 마이크 권한을 허용할 수 있어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  void _startListening() {
    if (_speechHandler.isListening.value) {
      _stopListening();
      return;
    }

    _speechHandler.startListening((result) {
      setState(() {
        _recognizedText = result.recognizedWords;
        _textController.text = _recognizedText;
        _textController.selection = TextSelection.fromPosition(
          TextPosition(offset: _textController.text.length),
        );
      });
    });
  }

  void _stopListening() async {
    await _speechHandler.stopListening();
    setState(() {});
  }

  final List<TalkMessage> _messages = [
    const TalkMessage(
      isUser: false,
      text: "Great! Where will you be staying during your visit?",
      postId: "1",
    ),
    const TalkMessage(
      isUser: true,
      text: "hotel and airbnb",
      fixedText: "I'll be staying in a hotel and an Airbnb.",
      commentKo:
          "주어와 동사를 추가해서 문장을 완전하게 만들어야 자연스러워요. 또, 'hotel'과 'Airbnb' 앞에 각각 'a'와 'an' 관련 관사를 넣어 주면 더 정확해요.",
      postId: "2",
    ),
    const TalkMessage(
      isUser: false,
      text: "Nice choice! Which hotel or Airbnb will you be staying at?",
      postId: "3",
    ),
  ];

  void _sendMessage() async {
    final message = _textController.text;

    if (message.isEmpty) return;

    setState(() {
      _freeTalkProvider.add(
          TalkMessage(
            text: message,
            isUser: true,
            postId: widget.postId,
          ),
          widget.postId);
      _textController.clear();
      _isLoading = true;

      _hintTextFromAPI = "";

      // 봇 메시지 초기 생성
      _freeTalkProvider.add(
          TalkMessage(
            text: '', // 빈 텍스트로 초기 생성
            isUser: false,
            postId: widget.postId,
          ),
          widget.postId);
    });

    // 스크롤을 맨 아래로 이동
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    _focusNode.requestFocus();

    Map<String, String> parameters = {
      'user_message': message,
      'post_id': widget.postId,
      'user_role': widget.userRole,
      'ai_role': widget.aiRole,
      'situation': widget.description,
      'user_id': "ttm",
    };

    SSEHandler.fetchBotResponseWeb(parameters, "freetalk", (botMessageChunk) {
      // UI 업데이트는 반드시 main 스레드에서 처리
      if (mounted) {
        setState(() {
          // 마지막에 추가된 봇 메시지 업데이트
          if (_freeTalkProvider.isNotEmpty &&
              !_freeTalkProvider.isLastMessageUser(widget.postId)) {
            _freeTalkProvider.messageUpdate(botMessageChunk, widget.postId);

            // 각 메시지 청크마다 스크롤 업데이트
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });
          }
        });
      }
    }, (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }, onDone: () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // 메시지 완료 후 스크롤 업데이트
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    });
  }

  // 스크롤을 맨 아래로 이동시키는 함수
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: SpinKitFadingCircle(
        color: Colors.white,
        size: 24.0,
      ),
    );
  }

  Widget _buildDashedHintBox() {
    return GestureDetector(
      onTap: _fetchHint,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0), // 둥근 모서리
          border: Border.all(
            color: Colors.grey,
            width: 2.0,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _hintTextFromAPI.isNotEmpty ? _hintTextFromAPI : _hintText,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis, // 텍스트가 길 경우 생략
                maxLines: 2,
              ),
            ),
            IconButton(
              icon: Icon(
                _hintTextFromAPI.isNotEmpty
                    ? Icons.copy
                    : Icons.lightbulb_outline,
                color: Colors.grey,
                size: 20.0,
              ),
              onPressed: _hintTextFromAPI.isNotEmpty
                  ? () {
                      // 힌트 텍스트를 입력 필드에 복사
                      setState(() {
                        _textController.text = _hintTextFromAPI;
                        _textController.selection = TextSelection.fromPosition(
                          TextPosition(offset: _textController.text.length),
                        );
                      });
                    }
                  : null, // 기본 아이콘일 경우 아무 동작도 하지 않음
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchHint() async {
    if (_isLoadingHint || _hintTextFromAPI.isNotEmpty)
      return; // 이미 힌트가 있으면 동작하지 않음

    setState(() {
      _isLoadingHint = true;
    });

    // 가장 최근 AI 메시지를 가져오기
    final messages = _freeTalkProvider.getMessagesNotifier(widget.postId).value;
    final recentAiMessage = messages
        .lastWhere(
          (message) => !message.isUser, // AI 메시지 필터링
          orElse: () =>
              TalkMessage(text: "", isUser: false, postId: widget.postId),
        )
        .text;

    final Uri uri =
        Uri.parse("http://192.168.0.147:8000/hint").replace(queryParameters: {
      'user_id': "ttm",
      'pre_conversation': recentAiMessage, // 가장 최근 AI 메시지
      'user_role': widget.userRole, // 사용자 역할
      'ai_role': widget.aiRole, // AI 역할
    });

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body); // JSON 디코딩
        final exampleAnswer = data['response']['example_answer']
            ?.replaceAll('"', '') // "" 제거
            .trim(); // 앞뒤 공백 제거

        setState(() {
          _hintTextFromAPI = exampleAnswer ?? ""; // example_answer 값 설정
          _isLoadingHint = false;
        });
      } else {
        print('API 호출 실패: ${response.statusCode}');
        setState(() {
          _isLoadingHint = false;
        });
      }
    } catch (e) {
      print('예외 발생: $e');
      setState(() {
        _isLoadingHint = false;
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
              widget.title,
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
      body: Column(
        children: [
          Expanded(
            child: ValueListenableBuilder<List<TalkMessage>>(
              valueListenable:
                  _freeTalkProvider.getMessagesNotifier(widget.postId),
              builder: (context, messages, child) {
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length && _isLoading) {
                      return _buildLoadingIndicator();
                    }

                    if (index < messages.length) {
                      return TalkMessage(
                        isUser: messages[index].isUser,
                        text: messages[index].text,
                        fixedText: messages[index].fixedText,
                        commentKo: messages[index].commentKo,
                        postId: widget.postId,
                      );
                    }

                    return SizedBox.shrink();
                  },
                );
              },
            ),
          ),

          // Expanded(
          //   child: ListView.builder(
          //     padding: const EdgeInsets.symmetric(horizontal: 8.0),
          //     itemCount: _messages.length,
          //     itemBuilder: (context, index) {
          //       return _messages[index];
          //     },
          //   ),
          // ),

          Container(
            color: const Color(0xFF121212),
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Column(
              children: [
                // Blue tip box (only show for demo purposes)

                Container(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 8.0),
                  child: _buildDashedHintBox(),
                ),
                // Input field
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(24.0),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                focusNode: _focusNode,
                                onSubmitted: (value) {
                                  if (value.trim().isNotEmpty) {
                                    _sendMessage();
                                  }
                                },
                                controller: _textController,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: "여기에 답변 쓰기",
                                  hintStyle: TextStyle(color: Colors.grey),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            ValueListenableBuilder<bool>(
                              valueListenable: _speechHandler.isListening,
                              builder: (context, isListening, child) {
                                return IconButton(
                                  icon: Icon(
                                    isListening ? Icons.mic : Icons.mic_off,
                                    color:
                                        isListening ? Colors.red : Colors.grey,
                                  ),
                                  onPressed: () {
                                    if (isListening) {
                                      _stopListening();
                                    } else {
                                      _startListening();
                                    }
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Bottom navigation buttons
        ],
      ),
    );
  }
}

class TalkMessage extends StatefulWidget {
  final bool isUser;
  final String text;
  final String commentKo;
  final String fixedText;
  final String postId;

  const TalkMessage({
    Key? key,
    required this.isUser,
    required this.text,
    required this.postId,
    this.commentKo = "",
    this.fixedText = "",
  }) : super(key: key);

  @override
  State<TalkMessage> createState() => _TalkMessageState();
}

class _TalkMessageState extends State<TalkMessage> {
  bool _showCommentKo = false;
  bool _showTranslate = false;
  bool _isLoadingFeedback = false;
  bool _isLoadingTranslate = false;
  String _fixedTextFromAPI = "";
  String _commentKoFromAPI = "";
  String _translateTextFromAPI = "";

  final FlutterTts flutterTts = FlutterTts();

  Future<void> _speak(String text) async {
    await flutterTts.setLanguage("en-US"); // 언어 설정
    await flutterTts.setPitch(1.0); // 음 높이
    await flutterTts.setSpeechRate(0.8); // 속도
    await flutterTts.speak(text);
  }

  Future<void> _fetchTranslation() async {
    if (_isLoadingTranslate) return;

    setState(() {
      _isLoadingTranslate = true;
    });

    final Uri uri = Uri.parse("http://192.168.0.147:8000/translate")
        .replace(queryParameters: {
      'text': widget.text,
    });

    try {
      final response = await http.get(uri);

      print('응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _translateTextFromAPI = data['translation'];
          _showTranslate = true;
          _isLoadingTranslate = false;
        });

        print('Translation: $_translateTextFromAPI');
      } else {
        print('API 호출 실패: ${response.statusCode}');
        setState(() {
          _isLoadingTranslate = false;
        });
      }
    } catch (e) {
      print('예외 발생: $e');
      setState(() {
        _isLoadingTranslate = false;
      });
    }
  }

  Future<void> _fetchFeedback() async {
    if (_isLoadingFeedback) return;

    setState(() {
      _isLoadingFeedback = true;
    });

    // Get the provider to access previous messages
    final freeTalkProvider =
        Provider.of<FreeTalkProvider>(context, listen: false);
    final messages = freeTalkProvider
        .getMessagesNotifier(freeTalkProvider.getCurrentPostId())
        .value;

    // Find the current message index
    final currentIndex = messages.indexWhere(
        (msg) => msg.isUser == widget.isUser && msg.text == widget.text);

    if (currentIndex <= 0) {
      setState(() {
        _isLoadingFeedback = false;
      });
      return; // Can't get previous message or not found
    }

    // Get previous bot message
    final previousBotMessage = messages[currentIndex - 1].text;

    final Uri uri = Uri.parse("http://192.168.0.147:8000/feedback")
        .replace(queryParameters: {
      'user_id': "ttm",
      'user_message': widget.text,
      'pre_conversation': previousBotMessage,
    });

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final nestedData = json.decode(data['response']);
        setState(() {
          _fixedTextFromAPI = nestedData['response'];
          _commentKoFromAPI = nestedData['comment_ko'];
          _showCommentKo = true;
          _isLoadingFeedback = false;
        });

        print('fixedText: $_fixedTextFromAPI');
        print('commentKo: $_commentKoFromAPI');
      } else {
        print('API 호출 실패: ${response.statusCode}');
        setState(() {
          _isLoadingFeedback = false;
        });
      }
    } catch (e) {
      print('예외 발생: $e');
      setState(() {
        _isLoadingFeedback = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment:
            widget.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                widget.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.isUser)
                const SizedBox(width: 20),
              if (widget.isUser) // 좌측에 * 버튼 추가
                Align(
                  alignment: Alignment.center,
                  child: IconButton(
                    icon: _isLoadingFeedback
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color.fromARGB(179, 59, 197, 221),
                            ),
                          )
                        : const Icon(Icons.stars,
                            color: Color.fromARGB(179, 59, 197, 221), size: 15),
                    onPressed: () {
                      if (!_isLoadingFeedback) {
                        if (_fixedTextFromAPI.isEmpty &&
                            _commentKoFromAPI.isEmpty) {
                          _fetchFeedback();
                        } else {
                          setState(() {
                            _showCommentKo = !_showCommentKo;
                          });
                        }
                      }
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  margin: widget.isUser
                      ? const EdgeInsets.only(left: 28.0, right: 8.0)
                      : const EdgeInsets.only(right: 28.0, left: 8.0),
                  decoration: BoxDecoration(
                    color: widget.isUser
                        ? const Color(0xFF444444)
                        : const Color(0xFF1F2937),
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                      if (_showTranslate) ...[
                        const SizedBox(height: 8),
                        if (_translateTextFromAPI.isNotEmpty) ...[
                          const Divider(
                            color: Colors.grey,
                            thickness: 1,
                          ),
                          const SizedBox(height: 4),
                          IntrinsicWidth(
                            child: Text(
                              _translateTextFromAPI,
                              style: TextStyle(
                                color: Colors.teal[200],
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                      if (_showCommentKo) ...[
                        const SizedBox(height: 8),
                        if (_fixedTextFromAPI.isNotEmpty ||
                            widget.fixedText.isNotEmpty) ...[
                          const Divider(
                            color: Colors.grey,
                            thickness: 1,
                          ),
                          const SizedBox(height: 4),
                          IntrinsicWidth(
                            child: Text(
                              _fixedTextFromAPI.isNotEmpty
                                  ? _fixedTextFromAPI
                                  : widget.fixedText,
                              style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        if (_commentKoFromAPI.isNotEmpty ||
                            widget.commentKo.isNotEmpty)
                          IntrinsicWidth(
                            child: Text(
                              _commentKoFromAPI.isNotEmpty
                                  ? _commentKoFromAPI
                                  : widget.commentKo,
                              style: TextStyle(
                                color: Colors.teal[200],
                                fontSize: 14,
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (!widget.isUser)
            Padding(
              padding: const EdgeInsets.only(left: 48.0, top: 4.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.volume_up,
                        color: Colors.white70, size: 20),
                    onPressed: () => _speak(widget.text),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.translate,
                        color: Colors.white70, size: 20),
                    onPressed: () {
                      if (!_isLoadingTranslate) {
                        if (_translateTextFromAPI.isEmpty) {
                          _fetchTranslation();
                        } else {
                          setState(() {
                            _showTranslate = !_showTranslate;
                          });
                        }
                      }
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.visibility_off,
                        color: Colors.white70, size: 20),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const Spacer(),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
