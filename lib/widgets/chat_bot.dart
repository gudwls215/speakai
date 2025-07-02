import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:speakai/services/speech_to_text_handler.dart';
import 'package:speakai/services/sse_service.dart';
import 'package:speakai/widgets/chat_message.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:speakai/providers/chat_provider.dart';
import 'package:http/http.dart' as http;
import 'package:speakai/widgets/page/pronunciation_page.dart';
import 'package:speakai/widgets/page/voca_multiple_page.dart';
import 'package:speakai/config.dart';

class ChatBotInput extends StatefulWidget {
  @override
  _ChatBotInputState createState() => _ChatBotInputState();
}

class _ChatBotInputState extends State<ChatBotInput> {
  final SpeechToTextHandler _speechHandler = SpeechToTextHandler();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatProvider _chatProvider = ChatProvider();

  String _recognizedText = "";
  bool _isLoading = false;
  bool _isInLevelTest = false; // 레벨 테스트 모드 여부
  Completer<String>? _levelTestCompleter; // 레벨 테스트에서 사용할 Completer
  
  // STT 개선을 위한 새로운 상태 변수들
  bool _autoSendEnabled = true; // 자동 전송 옵션
  bool _continuousListening = false; // 연속 음성 인식 모드
  String _lastRecognizedText = ""; // 마지막으로 인식된 텍스트 저장
  Timer? _autoSendTimer; // 자동 전송을 위한 타이머

  Future<void> fetchIntent({
    required String userId,
    required String userMessage,
  }) async {
    final Uri uri = Uri.parse("$aiBaseUrl/intent").replace(queryParameters: {
      'user_id': userId,
      'user_message': userMessage,
      'stream': 'false',
    });

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final apiResponse = data['response'];
        final intent = data['intent'];
        final gameType = data['game_type'] ?? '';
        final datas = data['data'] ?? [];

        print(datas);

        setState(() {
          // 마지막에 추가된 봇 메시지 업데이트
          if (_chatProvider.isNotEmpty && !_chatProvider.isLastMessageUser) {
            _chatProvider.messageUpdate(apiResponse);

            // 각 메시지 청크마다 스크롤 업데이트
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });
          }
        });

        // 의도와 게임 타입을 업데이트
        _chatProvider.intentUpdate(intent);
        _chatProvider.gameTypeUpdate(gameType);

        switch (intent) {
          case "pronunciation":
            print('발음 연습 관련 처리');
            if (datas.isNotEmpty) {
              final metadata = datas[0]['metadata']; // metadata 접근

              setState(() {
                // 추천 카드 추가
                _chatProvider.add(ChatMessage(
                  widget:
                      _buildRecommendationCard(metadata, intent), // 추천 카드 추가
                  isUser: false, text: '',
                ));
              });
            }
            break;
          case "help":
            break;
          case "vocabulary":
            print('단어 연습 관련 처리');
            if (datas.isNotEmpty) {
              final metadata = datas[0]['metadata']; // metadata 접근

              setState(() {
                _chatProvider.add(ChatMessage(
                  widget:
                      _buildRecommendationCard(metadata, intent), // 추천 카드 추가
                  isUser: false, text: '',
                ));
              });
            }

            break;
          case "course":
            print('코스 관련 처리');
            if (datas.isNotEmpty) {
              final metadata = datas[0]['metadata']; // metadata 접근

              setState(() {
                _chatProvider.add(ChatMessage(
                  widget:
                      _buildRecommendationCard(metadata, intent), // 추천 카드 추가
                  isUser: false, text: '',
                ));
              });
            }

            break;
          case "conversation":
            // 대화 관련 처리
            chatBotResponse(userMessage);
            break;
          default:
          // 기본 처리
        }

        print('Response: $apiResponse');
        print('Intent: $intent');
        print('Game Type: $gameType');
      } else {
        print('API 호출 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('예외 발생: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  void chatBotResponse(String message) async {
    Map<String, String> parameters = {
      'user_message': message,
      'user_id': "ttm",
      'stream': 'true',
    };

    SSEHandler.fetchBotResponseWeb(parameters, "chat2", (botMessageChunk) {
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

  @override
  void initState() {
    super.initState();
    _initSpeech();

    // 메시지 변경 시 자동 스크롤
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    _chatProvider.add(ChatMessage(
      text: '안녕하세요! 무엇을 도와드릴까요?',
      isUser: false,
    ));
  }

  void _initSpeech() async {
    try {
      await _speechHandler.initialize(
        onStatus: (status) {
          print("onStatus: $status");
          setState(() {});
        },
        onError: (dynamic error) {
          print("Error: ${error.toString()}");
          // 권한 관련 에러인 경우에만 다이얼로그 표시
          if (error.toString().contains('permission') || 
              error.toString().contains('denied') ||
              error.toString().contains('not-allowed')) {
            _showMicPermissionDialog();
          }
          setState(() {});
        },
      );
      
      // 초기화 성공 시 마이크 권한이 있다고 가정
      print("Speech initialization successful");
      
    } catch (e) {
      print("Speech initialization failed: $e");
      // 초기화 실패 시에만 권한 다이얼로그 표시
      if (e.toString().contains('permission') || 
          e.toString().contains('denied') ||
          e.toString().contains('not-allowed')) {
        _showMicPermissionDialog();
      }
    }
  }

  void _showMicPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1E2133),
        title: Row(
          children: [
            Icon(Icons.mic, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              '마이크 권한 필요',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '음성 인식을 사용하려면 브라우저에서 마이크 권한을 허용해주세요.',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '주소창 옆 🔒 아이콘을 클릭하여 마이크 권한을 허용하세요.',
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 권한 재시도
              _initSpeech();
            },
            child: Text(
              '다시 시도',
              style: TextStyle(color: Colors.blue),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '확인',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  // 메시지 전송 함수 - 일반 채팅과 레벨 테스트 모드에 따라 동작 분기
  void _sendMessage() async {
    final message = _textController.text;

    if (message.isEmpty) return;

    // 레벨 테스트 모드인 경우
    if (_isInLevelTest &&
        _levelTestCompleter != null &&
        !_levelTestCompleter!.isCompleted) {
      // 레벨 테스트 응답 처리
      _levelTestCompleter!.complete(message);
      setState(() {
        _chatProvider.add(ChatMessage(
          text: message,
          isUser: true,
        ));
        _textController.clear();
      });

      // 스크롤을 맨 아래로 이동
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
      return;
    }

    // 일반 채팅 모드인 경우 기존 로직 수행
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

    // 의도 분석 모델 붙이기
    await fetchIntent(
      userId: "ttm",
      userMessage: message,
    );
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

  void _startListening() {
    if (_speechHandler.isListening.value) {
      _stopListening();
      return;
    }

    // 이전 타이머가 있다면 취소
    _autoSendTimer?.cancel();
    
    try {
      // 음성 인식 시작 피드백
      _showVoiceRecognitionStatus('음성 인식을 시작합니다...');
      
      _speechHandler.startListening((result) {
        setState(() {
          _recognizedText = result.recognizedWords;
          _textController.text = _recognizedText;
          _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: _textController.text.length),
          );
          
          // 마지막으로 인식된 텍스트 저장
          _lastRecognizedText = _recognizedText;
        });

        // 자동 전송이 활성화되어 있고, 텍스트가 비어있지 않으면 타이머 설정
        if (_autoSendEnabled && _recognizedText.trim().isNotEmpty) {
          _autoSendTimer?.cancel(); // 기존 타이머 취소
          _autoSendTimer = Timer(Duration(seconds: 2), () {
            // 2초 동안 새로운 음성 입력이 없으면 자동으로 전송
            if (_recognizedText.trim().isNotEmpty && 
                _textController.text == _recognizedText) {
              _showVoiceRecognitionStatus('음성 메시지를 자동 전송합니다.');
              _stopListening();
              _sendMessage();
            }
          });
        }
      });
    } catch (e) {
      print("Start listening failed: $e");
      // 권한 관련 오류인 경우 다이얼로그 표시
      if (e.toString().contains('permission') || 
          e.toString().contains('denied') ||
          e.toString().contains('not-allowed')) {
        _showMicPermissionDialog();
      } else {
        _showVoiceRecognitionStatus('음성 인식을 시작할 수 없습니다.', isError: true);
      }
    }
  }

  void _stopListening() async {
    await _speechHandler.stopListening();
    _autoSendTimer?.cancel(); // 타이머 취소
    
    setState(() {
      _recognizedText = "";
    });
    
    // 연속 인식 모드가 활성화되어 있다면 잠시 후 다시 시작
    if (_continuousListening && !_isInLevelTest) {
      Timer(Duration(milliseconds: 500), () {
        if (_continuousListening && !_speechHandler.isListening.value) {
          _startListening();
        }
      });
    }
  }

  Widget _buildQuickReply(String title, String text, [String intent = ""]) {
    return GestureDetector(
      onTap: () {
        _handleQuickReply(intent); // 클릭 시 intent를 특정 함수로 전달
      },
      child: SizedBox(
        width: 200,
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
      ),
    );
  }

  // 레벨 평가 API 호출 함수
  Future<void> _fetchLevelAssessment(
      List<String> userResponses, List<dynamic> questions) async {
    final Uri uri = Uri.parse("$aiBaseUrl/level/assessment");

    // API에 보낼 데이터 구성
    List<Map<String, String>> answersData = [];
    for (int i = 0; i < userResponses.length; i++) {
      print("레벨 테스트 질문: ${questions[i]['text']}");
      print("레벨 테스트 답변: ${userResponses[i]}");

      answersData.add({
        "answer": userResponses[i],
        "question": questions[i]['text']!,
        "question_id": questions[i]['id']!,
      });
    }

    final Map<String, dynamic> requestData = {
      "user_id": "ttm",
      "stream": false,
      "answers": answersData,
    };

    try {
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));

        // 결과 표시
        setState(() {
          // "레벨 테스트 결과를 분석 중입니다..." 메시지 제거
          if (_chatProvider.isNotEmpty &&
              !_chatProvider.isLastMessageUser &&
              _chatProvider.lastMessage.text == "레벨 테스트 결과를 분석 중입니다...") {
            _chatProvider.removeLastMessage();
          }

          // 마지막 메시지 업데이트 (분석 중 -> 결과)
          _chatProvider.add(ChatMessage(
            text: _buildLevelAssessmentResult(data),
            isUser: false,
          ));
        });

        // 스크롤 업데이트
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      } else {
        print('API 호출 실패: ${response.statusCode}');
        setState(() {
          _chatProvider.add(ChatMessage(
            text: "레벨 테스트 평가 중 오류가 발생했습니다. 다시 시도해주세요.",
            isUser: false,
          ));
        });
      }
    } catch (e) {
      print('예외 발생: $e');
      setState(() {
        _chatProvider.add(ChatMessage(
          text: "레벨 테스트 평가 중 오류가 발생했습니다. 다시 시도해주세요.",
          isUser: false,
        ));
      });
    }
  }

  // 레벨 평가 결과 메시지 구성
  String _buildLevelAssessmentResult(Map<String, dynamic> data) {
    String level = data['level'] ?? 'N/A';
    String explanation = data['explanation'] ?? '평가 내용을 불러올 수 없습니다.';
    List<dynamic> strengths = data['strengths'] ?? [];
    List<dynamic> weaknesses = data['weaknesses'] ?? [];

    String resultMessage = "📊 레벨 테스트 결과\n\n";
    resultMessage += "📝 영어 레벨: $level\n\n";
    resultMessage += "✨ 설명:\n$explanation\n\n";

    if (strengths.isNotEmpty) {
      resultMessage += "💪 강점:\n";
      for (int i = 0; i < strengths.length; i++) {
        resultMessage += "- ${strengths[i]}\n";
      }
      resultMessage += "\n";
    }

    if (weaknesses.isNotEmpty) {
      resultMessage += "🔍 개선할 점:\n";
      for (int i = 0; i < weaknesses.length; i++) {
        resultMessage += "- ${weaknesses[i]}\n";
      }
    }

    return resultMessage;
  }

  Future<void> _handleQuickReply(String intent) async {
    switch (intent) {
      case "level":
        print("레벨 테스트 시작");

        setState(() {
          _isLoading = true;
        });

        // 레벨 테스트 모드 시작
        setState(() {
          _isInLevelTest = true;

          _chatProvider.add(ChatMessage(
            text: "레벨 테스트",
            isUser: true,
          ));

          _chatProvider.add(ChatMessage(
            text:
                "당신의 영어 레벨을 측정해볼게요! 세개의 질문을 드릴거에요. 할 수 있는 만큼 영어로 대답해보세요. 마지막에는 CEFR(유럽연합 공통언어 표준등급)에 따라 당신의 영어 레벨을 알려드릴게요. 잠시만 기다려 주세요.",
            isUser: false,
          ));
        });

        final Uri uri =
            Uri.parse("$aiBaseUrl/level/questions").replace(queryParameters: {
          'user_id': "ttm",
        });

        try {
          final response = await http.get(uri);

          if (response.statusCode == 200) {
            final data = json.decode(response.body);

            // `questions` 필드가 문자열로 반환되었을 경우 다시 디코딩
            final questions = data['questions'] as List<dynamic>;
            print(questions);

            // 로딩 상태 종료
            setState(() {
              _isLoading = false;
            });

            // 사용자 응답 저장
            List<String> userResponses = [];

            // 질문 순차적으로 처리
            for (var question in questions) {
              setState(() {
                _chatProvider.add(ChatMessage(
                  text: question['text']!,
                  isUser: false,
                ));
              });

              // 사용자 응답 대기
              String userResponse = await _waitForUserResponse();
              userResponses.add(userResponse);
            }

            // 레벨 테스트 평가 API 호출
            setState(() {
              _chatProvider.add(ChatMessage(
                text: "레벨 테스트 결과를 분석 중입니다...",
                isUser: false,
              ));
            });

            // 레벨 평가 API 호출
            await _fetchLevelAssessment(userResponses, questions);

            // 레벨 테스트 모드 종료
            setState(() {
              _isInLevelTest = false;
            });
          }
        } catch (e) {
          setState(() {
            _isInLevelTest = false; // 에러 발생 시에도 레벨 테스트 모드 종료
            _isLoading = false;
            _chatProvider.add(ChatMessage(
              text: "레벨 테스트 중 오류가 발생했습니다. 다시 시도해주세요.",
              isUser: false,
            ));
          });
          print('예외 발생: $e');
        }

        break;
      case "vocabulary":
        print("단어 모음집 열기");

        setState(() {
          _chatProvider.add(ChatMessage(
            text: "단어 모음집",
            isUser: true,
          ));

          _chatProvider.add(ChatMessage(
            text:
                "공부하실 단어 주제나 카테고리를 말씀해주세요. 예를 들어 '비즈니스 영어', '여행 영어', '토익 단어' 등을 입력하시면 관련 단어 모음집을 준비해 드립니다.",
            isUser: false,
          ));
        });

        // 스크롤 업데이트
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });

        // 사용자 입력을 기다리기 위해 대화형 모드 활성화
        // (여기서는 특별한 플래그나 상태를 설정하지 않고, 사용자가 입력한 텍스트를
        // fetchIntent 함수가 처리하도록 함)

        break;

      case "pronunciation":
        print("발음 연습 시작");

        setState(() {
          _chatProvider.add(ChatMessage(
            text: "발음 연습",
            isUser: true,
          ));

          _chatProvider.add(ChatMessage(
            text:
                "어떤 발음을 연습하고 싶으신가요? 특정 단어나 발음하기 어려운 소리를 알려주시면 맞춤 발음 연습을 준비해 드릴게요. 예를 들어 'th 발음', 'r과 l 구분', '장모음과 단모음' 등을 입력해보세요.",
            isUser: false,
          ));
        });

        // 스크롤 업데이트
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });

        break;

      case "course":
        print("강의 추천");

        setState(() {
          _chatProvider.add(ChatMessage(
            text: "강의 추천",
            isUser: true,
          ));

          _chatProvider.add(ChatMessage(
            text:
                "어떤 목적의 강의를 찾고 계신가요? 예를 들어 '회화 능력 향상', '비즈니스 영어', '토익/토플 준비', '문법 공부' 등 원하시는 학습 목표나 관심 분야를 알려주시면 맞춤형 강의를 추천해 드릴게요.",
            isUser: false,
          ));
        });

        // 스크롤 업데이트
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });

        break;

      default:
        print("알 수 없는 intent: $intent");
    }
  }

  // 사용자 응답 대기 함수
  Future<String> _waitForUserResponse() async {
    // 기존 completer가 있으면 취소하고 새로운 completer 생성
    if (_levelTestCompleter != null && !_levelTestCompleter!.isCompleted) {
      // 완료되지 않은 기존 completer는 취소할 방법이 없으므로 새로운 것으로 대체
    }

    _levelTestCompleter = Completer<String>();

    return _levelTestCompleter!.future;
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: SpinKitThreeBounce(
        color: Colors.blue,
        size: 30.0,
      ),
    );
  }

  Widget _buildRecommendationCard(metadata, intent) {
    String title;
    switch (intent) {
      case "pronunciation":
        title = '회원님이 요청한 발음 연습';
        break;
      case "vocabulary":
        title = '회원님이 요청한 단어 모음집';
        break;
      case "course":
        title = '회원님이 요청한 코스';
        break;
      default:
        title = '회원님이 요청한 항목';
    }

    return GestureDetector(
      onTap: () {
        switch (intent) {
          case "pronunciation":
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PronunciationAssessment(
                  metadata['COURSE'].toString(),
                  metadata['LESSON'].toString(),
                  metadata['CHAPTER'].toString(),
                  metadata['WORD'].toString(),
                ),
              ),
            );
            break;
          case "vocabulary":
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VocaMultiple(
                  metadata['COURSE'].toString(),
                  metadata['LESSON'].toString(),
                  metadata['CHAPTER'].toString(),
                  "",
                ),
              ),
            );
            break;
          case "course":
            // 코스 관련 처리
            print('코스 관련 처리');
            break;
          default:
          // 기본 처리
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 13.0),
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
                    title,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    intent != "vocabulary"
                        ? metadata['COURSE_NAME']
                        : 'Course. ' +
                            metadata['COURSE_NAME'] +
                            '\n Lesson. ' +
                            metadata['LESSON_NAME'],
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
      ),
    );
  }

  @override
  void dispose() {
    _autoSendTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 개선된 마이크 버튼 위젯
  Widget _buildEnhancedMicButton() {
    return ValueListenableBuilder<bool>(
      valueListenable: _speechHandler.isListening,
      builder: (context, isListening, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // 외부 파형 애니메이션 (음성 인식 중일 때)
            if (isListening)
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 1000),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withOpacity(0.1),
                  ),
                ),
              ),
            // 메인 마이크 버튼
            GestureDetector(
              onTap: _isInLevelTest
                  ? null
                  : () {
                      if (isListening) {
                        _stopListening();
                      } else {
                        _startListening();
                      }
                    },
              onLongPress: _isInLevelTest ? null : _showSTTSettings,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isListening ? Colors.red : Colors.grey.shade700,
                  boxShadow: isListening
                      ? [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          )
                        ]
                      : null,
                ),
                child: Icon(
                  isListening ? Icons.mic : Icons.mic_off,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            // 인식된 텍스트가 있을 때 표시되는 작은 점
            if (_recognizedText.isNotEmpty && !isListening)
              Positioned(
                top: 5,
                right: 5,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // STT 설정 다이얼로그
  void _showSTTSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1E2133),
        title: Text(
          'STT 설정',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 자동 전송 설정
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '자동 전송',
                  style: TextStyle(color: Colors.white70),
                ),
                Switch(
                  value: _autoSendEnabled,
                  onChanged: (value) {
                    setState(() {
                      _autoSendEnabled = value;
                      if (!value) {
                        _autoSendTimer?.cancel();
                      }
                    });
                    Navigator.pop(context);
                  },
                  activeColor: Colors.blue,
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              '음성 인식 완료 후 2초 뒤 자동으로 메시지를 전송합니다.',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
            SizedBox(height: 16),
            // 연속 음성 인식 설정
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '연속 인식',
                  style: TextStyle(color: Colors.white70),
                ),
                Switch(
                  value: _continuousListening,
                  onChanged: (value) {
                    setState(() {
                      _continuousListening = value;
                    });
                    Navigator.pop(context);
                    if (value && !_speechHandler.isListening.value) {
                      _startListening();
                    }
                  },
                  activeColor: Colors.blue,
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              '한 번 활성화하면 계속해서 음성을 인식합니다.',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '확인',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  // 음성 인식 상태 토스트 메시지
  void _showVoiceRecognitionStatus(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.mic,
              color: Colors.white,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade700 : Colors.blue.shade700,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
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
                            Expanded(
                              child: ValueListenableBuilder<List<ChatMessage>>(
                                valueListenable: _chatProvider.messages,
                                builder: (context, messages, child) {
                                  return ListView.builder(
                                    controller: _scrollController,
                                    itemCount:
                                        messages.length + (_isLoading ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      if (index == messages.length &&
                                          _isLoading) {
                                        return _buildLoadingIndicator();
                                      }

                                      if (index < messages.length) {
                                        return messages[index];
                                      }

                                      return SizedBox.shrink();
                                    },
                                  );
                                },
                              ),
                            ),

                            // Quick reply options
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8.0, vertical: 12.0),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal, // 수평 스크롤 활성화
                                physics: ClampingScrollPhysics(), // 드래그 스크롤 활성화
                                child: Row(
                                  mainAxisSize:
                                      MainAxisSize.min, // Row의 크기를 내용물에 맞춤
                                  children: [
                                    _buildQuickReply(
                                        "레벨테스트", "당신의 영어 레벨을 측정해볼게요!", "level"),
                                    _buildQuickReply("단어모음집", "단어 모음집을 만들어볼까요?",
                                        "vocabulary"),
                                    _buildQuickReply("발음연습",
                                        "어려운 단어 발음연습을 하고싶어", "pronunciation"),
                                    _buildQuickReply(
                                        "강의추천", "어떤 강의를 추천해줄래?", "course"),
                                  ],
                                ),
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
                                          hintText: _isInLevelTest
                                              ? '영어로 답변해 주세요...'
                                              : '메시지 보내기',
                                          hintStyle:
                                              TextStyle(color: Colors.grey),
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  // 마이크 버튼 (전송 버튼 왼쪽)
                                  _buildEnhancedMicButton(),
                                  SizedBox(width: 8),
                                  // 전송 버튼 (가장 오른쪽)
                                  IconButton(
                                    icon: Icon(
                                      Icons.send,
                                      color: _isInLevelTest
                                          ? Colors.blue
                                          : Colors.grey,
                                    ),
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
              // 음성 인식 상태에 따른 동적 아이콘
              ValueListenableBuilder<bool>(
                valueListenable: _speechHandler.isListening,
                builder: (context, isListening, child) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_autoSendEnabled)
                        Icon(
                          Icons.auto_awesome,
                          color: Colors.amber,
                          size: 16,
                        ),
                      SizedBox(width: 4),
                      Icon(
                        isListening ? Icons.mic : Icons.mic_off,
                        color: isListening ? Colors.red : Colors.grey,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
