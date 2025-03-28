import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speakai/services/sse_service.dart';
import 'package:speakai/widgets/chat_message.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';


class ChatBotInput extends StatefulWidget {
  @override
  _ChatBotInputState createState() => _ChatBotInputState();
}

class _ChatBotInputState extends State<ChatBotInput> {
  late stt.SpeechToText _speech;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
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
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() async {
    final message = _textController.text;
    if (message.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: true,
      ));
      _textController.clear();
      _isLoading = true;

      // 봇 메시지 초기 생성
      _messages.add(ChatMessage(
        text: '', // 빈 텍스트로 초기 생성
        isUser: false,
      ));
    });

    SSEHandler.fetchBotResponseWeb(message, (botMessageChunk) {
      print("botMessageChunk :" + botMessageChunk);
      setState(() {
        // 마지막에 추가된 봇 메시지 업데이트
        if (_messages.isNotEmpty && !_messages.last.isUser) {
          _messages[_messages.length - 1] = ChatMessage(
            text: _messages.last.text + botMessageChunk,
            isUser: false,
          );
        }
      });
    }, (error) {
      setState(() {
        _isLoading = false;
        //_messages.removeLast(); // 빈 봇 메시지 제거
        // _messages.add(ChatMessage(
        //   text: '메시지 전송 중 오류가 발생했습니다.',
        //   isUser: false,
        //   isError: true,
        // ));
      });
    }, onDone: () {
      setState(() {
        _isLoading = false;
      });
    });
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

  // void _sendMessage() {
  //   final message = _textController.text; // 메시지 변수로 저장
  //   print("메시지 전송: $_textController.text"); // 실제 전송 로직 추가 가능
  //   if (_textController.text.isEmpty) {
  //     return;
  //   }

  //   setState(() {
  //     _messages.add(_buildUserMessage(_textController.text)); // 사용자 메시지 추가
  //     _messages.add(_buildBotMessage(_textController.text));
  //   });

  //   // 웹 환경에서의 SSE 요청
  //   if (kIsWeb) {
  //     SSEHandler.fetchBotResponseWeb(_textController.text, (botMessage) {
  //       print("챗봇 응답: $botMessage");
  //       setState(() {
  //         _botResponse.add(botMessage); // 챗봇 메시지 추가
  //       });
  //     }, (error) {
  //       // 오류 발생 시 폴백 요청 시도
  //       SSEHandler.fallbackHttpRequest(message, (botMessage) {
  //         setState(() {
  //           _botResponse.add(botMessage);
  //         });
  //       }, (fallbackError) {
  //         // 최종 오류 처리
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(content: Text('메시지 전송 실패: $fallbackError')),
  //         );
  //       });
  //     });
  //   } else {
  //     // 모바일 환경에서는 기존 SSE 로직 사용
  //     _fetchBotResponseMobile(message);
  //   }

  //   _textController.clear(); // 입력 필드 초기화
  //   _recognizedText = ""; // 변수 초기화
  // }

  // 모바일 환경용 기존 SSE 메서드 (수정 필요)
  void _fetchBotResponseMobile(String message) {
    // 기존 SSE 클라이언트 로직 그대로 사용
  }

  Widget _buildUserMessage(String title) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.only(bottom: 16.0),
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: Colors.blue.shade800,
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildBotMessage(String title) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.smart_toy, color: Colors.white),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: 16.0),
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
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
                                itemCount:
                                    _messages.length + (_isLoading ? 1 : 0),
                                itemBuilder: (context, index) {
                                  // 기존 로직 유지
                                  if (index == _messages.length && _isLoading) {
                                    return _buildLoadingIndicator();
                                  }

                                  if (index < _messages.length) {
                                    return _messages[index];
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
                                      Expanded(
                                        child: Container(
                                          margin: EdgeInsets.all(4.0),
                                          padding: EdgeInsets.symmetric(
                                              vertical: 12.0),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade900,
                                            borderRadius:
                                                BorderRadius.circular(16.0),
                                          ),
                                          child: Column(
                                            children: [
                                              Text(
                                                '대화 시작하기',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              Text(
                                                '세상을 바꿔봅시다',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          margin: EdgeInsets.all(4.0),
                                          padding: EdgeInsets.symmetric(
                                              vertical: 12.0),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade900,
                                            borderRadius:
                                                BorderRadius.circular(16.0),
                                          ),
                                          child: Column(
                                            children: [
                                              Text(
                                                '대화 시작하기',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              Text(
                                                '어떤 직업을 갖고 싶나요?',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          margin: EdgeInsets.all(4.0),
                                          padding: EdgeInsets.symmetric(
                                              vertical: 12.0),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade900,
                                            borderRadius:
                                                BorderRadius.circular(16.0),
                                          ),
                                          child: Column(
                                            children: [
                                              Text(
                                                '대화 시작하기',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              Text(
                                                '어떤 직업을 갖고 싶나요?',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
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
