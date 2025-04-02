import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speakai/services/sse_service.dart';
import 'package:speakai/widgets/chat_message.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:speakai/providers/chat_provider.dart';
import 'package:provider/provider.dart';

class ChatBotInput extends StatefulWidget {
  @override
  _ChatBotInputState createState() => _ChatBotInputState();
}

class _ChatBotInputState extends State<ChatBotInput> {
  late stt.SpeechToText _speech;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  ChatProvider _chatProvider = ChatProvider();

  // ChatProvider _chatProvider = Provider.of<ChatProvider>(context, listen: false);

  String _recognizedText = "";
  bool _isListening = false;
  bool _isLoading = false; // 로딩 상태 추가

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();

    // 메시지 변경 시 자동 스크롤
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    _chatProvider.add(ChatMessage(
      text: '안녕하세요! 무엇을 도와드릴까요?',
      isUser: false,
    ));
  }

  void _sendMessage() async {
    final message = _textController.text;
    if (message.isEmpty) return;

    setState(() {
      _chatProvider.add(ChatMessage(
        text: message,
        isUser: true,
      ));
      _textController.clear();
      _isLoading = true;

      // 봇 메시지 초기 생성
      _chatProvider.add(ChatMessage(
        text: '', // 빈 텍스트로 초기 생성
        isUser: false,
      ));
    });

    // 스크롤을 맨 아래로 이동
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    SSEHandler.fetchBotResponseWeb(message, (botMessageChunk) {
      print("botMessageChunk: " + botMessageChunk);

      // UI 업데이트는 반드시 main 스레드에서 처리
      if (mounted) {
        setState(() {
          // 마지막에 추가된 봇 메시지 업데이트
          if (_chatProvider.isNotEmpty && !_chatProvider.isLastMessageUser) {
            _chatProvider.messageUpdate(botMessageChunk);

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

  void _startListening() async {
    if (_isListening || _speech.isListening) {
      _stopListening();
      //print("이미 음성 인식이 실행 중입니다.");
      return;
    }

    bool available = await _speech.initialize(onStatus: (status) {
      print("onStatus: $status");
      print("_isListening: $_isListening");
      setState(() {
        _isListening = (status == "listening");
      });
    }, onError: (error) {
      print("onError: $error");
      setState(() {
        _isListening = false;
      });
    });

    print("available: $available");
    if (available) {
      _speech.listen(
        onResult: (result) {
          print("result: $result");
          setState(() {
            _recognizedText = result.recognizedWords;
            _textController.text = _recognizedText; // 👈 자동으로 입력값 업데이트
            _textController.selection = TextSelection.fromPosition(
              TextPosition(offset: _textController.text.length),
            );
          });
        },
      );
      setState(() {
        _isListening = true;
      });
    } else {
      print("음성 인식을 사용할 수 없습니다.");
    }
  }

  void _stopListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    }
  }

  // 모바일 환경용 기존 SSE 메서드 (수정 필요)
  void _fetchBotResponseMobile(String message) {
    // 기존 SSE 클라이언트 로직 그대로 사용
  }

  Widget _buildMessageReco(String title, String text) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.all(4.0),
        padding: EdgeInsets.symmetric(vertical: 12.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              text,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: SpinKitThreeBounce(
        color: Colors.blue,
        size: 30.0,
      ),
    );
  }

  Widget _buildRecommendationCard(String title) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.0),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue.shade700,
            child: Icon(Icons.stars, color: Colors.white),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '회원님이 요청한 수업',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Music Genres',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (BuildContext context) {
              return StatefulBuilder(
                // 👈 Modal 내부에서 setState 적용 가능하게 함
                builder: (context, setState) {
                  return DraggableScrollableSheet(
                    expand: false,
                    initialChildSize: 1.0,
                    builder: (BuildContext context,
                        ScrollController scrollController) {
                      return Container(
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 15, 15, 30),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(24.0),
                            topRight: Radius.circular(24.0),
                          ),
                        ),
                        child: Column(
                          children: [
                            // App bar with back button and controls
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 12.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon:
                                        Icon(Icons.close, color: Colors.white),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.volume_off,
                                            color: Colors.white),
                                        onPressed: () {},
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.more_vert,
                                            color: Colors.white),
                                        onPressed: () {},
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Chat messages

                            // 채팅 메시지 리스트
                            Expanded(
                              child: ListView.builder(
                                // 컨트롤러 추가
                                controller: _scrollController,
                                itemCount: _chatProvider.getLength +
                                    (_isLoading ? 1 : 0),
                                itemBuilder: (context, index) {
                                  // 기존 로직 유지
                                  if (index == _chatProvider.getLength &&
                                      _isLoading) {
                                    return _buildLoadingIndicator();
                                  }

                                  if (index < _chatProvider.getLength) {
                                    return _chatProvider.getMessage(index);
                                  }

                                  return SizedBox.shrink();
                                },
                              ),
                            ),
                            // Expanded(
                            //   child: ListView(
                            //     controller: scrollController,
                            //     padding: EdgeInsets.symmetric(horizontal: 16.0),
                            // children: [
                            //   _buildUserMessage('음악 장르는 뭐가 있어'),
                            //   _buildBotMessage(
                            //       '음악 장르는 정말 다양해요! 예를 들어, "rock"은 록, "jazz"는 재즈, "pop"은 팝, "classical"은 클래식이라고 해요. 더 궁금한 음악 장르가 있나요? 함께 더 알아볼까요?'),
                            //   _buildUserMessage('단어 모음집'),
                            //   _buildBotMessage(
                            //       '음악 장르와 관련된 영어 단어들을 모아볼까요? 다양한 장르와 관련된 단어들을 함께 배워보세요.'),
                            //   _buildRecommendationCard('Music Genres'),
                            //   _buildBotMessage(
                            //       '이 강의를 시작해서 더 많은 단어를 익혀보세요! 궁금한 점이 있으면 언제든지 물어보세요.'),
                            //   _buildUserMessage('어려운 단어 연습을 하고싶어어'),
                            //   _messages,

                            // ],
                            //   ),
                            // ),

                            // Quick reply options
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8.0, vertical: 12.0),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      _buildMessageReco("게임하기기",
                                          "10고개 게임을 해볼까요?"),
                                      _buildMessageReco("단어모음집",
                                          "단어 모음집을 만들어볼까요?"),
                                      _buildMessageReco("단어연습",
                                          "어려운 단어 연습을 하고싶어"),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Message input field
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                border: Border(
                                  top: BorderSide(
                                      color: Colors.grey.shade800, width: 0.5),
                                ),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      _isListening ? Icons.mic : Icons.mic_off,
                                      color: _isListening
                                          ? Colors.red
                                          : Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        // 👈 Modal 내부에서 상태 변경 가능
                                        if (_isListening) {
                                          _stopListening();
                                        } else {
                                          _startListening();
                                        }
                                      });
                                    },
                                  ),
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 16.0),
                                      decoration: BoxDecoration(
                                        color: Colors.transparent,
                                        border: Border(
                                          bottom: BorderSide(
                                              color: Colors.blue, width: 1.0),
                                        ),
                                      ),
                                      child: TextField(
                                        onSubmitted: (value) {
                                          if (value.trim().isNotEmpty) {
                                            _sendMessage();
                                          }
                                        },
                                        style: TextStyle(color: Colors.white),
                                        controller:
                                            _textController, // 입력 필드에 컨트롤러 추가
                                        decoration: InputDecoration(
                                          hintText: '메시지 보내기',
                                          hintStyle:
                                              TextStyle(color: Colors.grey),
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.send,
                                        color: Colors.grey),
                                    onPressed: _sendMessage,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(color: Colors.blueAccent),
          ),
          child: Row(
            children: [
              Icon(Icons.chat_bubble, color: Colors.blue),
              SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  '무엇이든 물어보세요',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              Icon(Icons.mic, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
