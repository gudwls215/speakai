import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

class VocaMultiple extends StatefulWidget {
  final String course;
  final String lesson;
  final String section;
  final String text;

  const VocaMultiple(this.course, this.lesson, this.section, this.text,
      {Key? key})
      : super(key: key);

  @override
  State<VocaMultiple> createState() => _VocaMultipleState();
}

class _VocaMultipleState extends State<VocaMultiple> {
  int currentQuestionIndex = 0;
  String? selectedAnswer;
  bool isAnswerCorrect = false;
  bool hasAnswered = false;
  bool _isLoading = false;
  List<Map<String, dynamic>> questions = [];

  @override
  void initState() {
    super.initState();
    _loadQuestionsWithCache();
  }

  // Create a unique key for the current payload
  String _generateCacheKey() {
    final String payloadString =
        "${widget.course}|${widget.lesson}|${widget.section}|${widget.text}";
    print("Payload String: $payloadString");
    return md5.convert(utf8.encode(payloadString)).toString();
  }

  // Try to load questions from cache, or fetch them if not available
  Future<void> _loadQuestionsWithCache() async {
    setState(() {
      _isLoading = true;
    });

    final cacheKey = _generateCacheKey();

    try {
      // Try to load from cache first
      final cachedQuestions = await _loadCachedQuestions(cacheKey);

      if (cachedQuestions != null && cachedQuestions.isNotEmpty) {
        // Use cached questions if available
        setState(() {
          questions = cachedQuestions;
          _isLoading = false;
        });
      } else {
        // Fetch from API if not in cache
        _fetchQuestionsFromApi(cacheKey);
      }
    } catch (e) {
      print("Error loading cached questions: $e");
      // Fallback to API if cache fails
      _fetchQuestionsFromApi(cacheKey);
    }
  }

  // Load cached questions from SharedPreferences
  Future<List<Map<String, dynamic>>?> _loadCachedQuestions(
      String cacheKey) async {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedData = prefs.getString('vocab_questions_$cacheKey');
    print("Cached Data: $cachedData");

    if (cachedData != null) {
      final List<dynamic> decoded = jsonDecode(cachedData);
      return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    }
    return null;
  }

  // Save questions to cache
  Future<void> _cacheQuestions(
      String cacheKey, List<Map<String, dynamic>> questionsToCache) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'vocab_questions_$cacheKey', jsonEncode(questionsToCache));
  }

  // Fetch questions from API
  void _fetchQuestionsFromApi(String cacheKey) {
    fetchVocabQuestions(
      userId: "ttm",
      text: widget.text,
      course: widget.course,
      lesson: widget.lesson,
      section: widget.section,
      onSuccess: (result) async {
        // Cache the questions for future use
        await _cacheQuestions(cacheKey, result);

        setState(() {
          questions = result;
          _isLoading = false;
        });
      },
      onError: (error) {
        setState(() {
          _isLoading = false;
        });
        print("Error fetching questions: $error");
      },
    );
  }

  void fetchVocabQuestions({
    required String userId,
    required String text,
    required String course,
    required String lesson,
    required String section,
    required void Function(List<Map<String, dynamic>> result) onSuccess,
    required void Function(String error) onError,
  }) async {
    final url = Uri.parse('http://192.168.0.147:8000/vocab');

    final payload = {
      "user_id": userId,
      "text": text,
      "course": course,
      "lesson": lesson,
      "section": section,
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonBody =
            jsonDecode(utf8.decode(response.bodyBytes));
        final dynamic rawQuestions = jsonBody['questions'];

        // Parse based on response format
        List<Map<String, dynamic>> parsedQuestions;

        if (rawQuestions is String) {
          final parsed = jsonDecode(rawQuestions);
          parsedQuestions =
              List<Map<String, dynamic>>.from(parsed['questions']);
        } else if (rawQuestions is Map<String, dynamic>) {
          parsedQuestions =
              List<Map<String, dynamic>>.from(rawQuestions['questions']);
        } else if (rawQuestions is List) {
          parsedQuestions = List<Map<String, dynamic>>.from(rawQuestions);
        } else {
          throw Exception(
              "Unexpected response format: ${rawQuestions.runtimeType}");
        }

        onSuccess(parsedQuestions);
      } else {
        onError("Server returned status: ${response.statusCode}");
      }
    } catch (e) {
      onError("Error: $e");
    }
  }

  double get progressValue => (currentQuestionIndex + 1) / questions.length;

  void checkAnswer(String answer) {
    setState(() {
      selectedAnswer = answer;
      isAnswerCorrect =
          answer == questions[currentQuestionIndex]['correctAnswer'];
      hasAnswered = true;
    });
  }

  void nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedAnswer = null;
        hasAnswered = false;
      });
    } else {
      // End of quiz, show completion or exit
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('퀴즈 완료'),
          content: const Text('모든 문제를 완료했습니다.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // 다이얼로그 닫기
                Navigator.pop(context); // 화면 종료
              },
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color.fromARGB(179, 59, 197, 221),
          ),
        ),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("문제를 불러올 수 없습니다.", style: TextStyle(color: Colors.white)),
              ElevatedButton(
                onPressed: _loadQuestionsWithCache,
                child: Text("다시 시도"),
              ),
            ],
          ),
        ),
      );
    }

    final currentQuestion = questions[currentQuestionIndex];

    return Scaffold(
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
              "단어 연습",
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
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with back button and progress indicator
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0), // 좌우 여백 추가
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progressValue,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Question card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                color: Colors.grey[850],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style:
                              const TextStyle(fontSize: 24, color: Colors.blue),
                          children: _buildQuestionTextSpans(
                              currentQuestion['question']),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        currentQuestion['translatedQuestion'],
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue[200],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Answer options
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  itemCount: currentQuestion['options'].length,
                  itemBuilder: (context, index) {
                    final option = currentQuestion['options'][index];
                    final isSelected = selectedAnswer == option;
                    final isCorrect =
                        option == currentQuestion['correctAnswer'];

                    Color buttonColor = Colors.blue[800]!;
                    if (hasAnswered) {
                      if (isSelected && isCorrect) {
                        buttonColor = Colors.green;
                      } else if (isSelected && !isCorrect) {
                        buttonColor = Colors.red[900]!;
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isSelected ? buttonColor : Colors.grey[800],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed:
                            hasAnswered ? null : () => checkAnswer(option),
                        child: Text(
                          option,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Feedback and continue button
            if (hasAnswered)
              Container(
                width: double.infinity,
                color: isAnswerCorrect ? Colors.green[900] : Colors.red[900],
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          isAnswerCorrect ? Icons.check_circle : Icons.cancel,
                          color: isAnswerCorrect
                              ? Colors.green[400]
                              : Colors.red[400],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isAnswerCorrect ? '정답!' : '오답',
                          style: TextStyle(
                            color: isAnswerCorrect
                                ? Colors.green[400]
                                : Colors.red[400],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.flag_outlined,
                          color: isAnswerCorrect
                              ? Colors.green[400]
                              : Colors.red[400],
                        ),
                      ],
                    ),
                    if (!isAnswerCorrect)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Answer: ${currentQuestion['correctAnswer']}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isAnswerCorrect
                            ? Colors.green[400]
                            : Colors.red[400],
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: nextQuestion,
                      child: Text(
                        isAnswerCorrect ? '계속하기' : '이해했어요',
                        style: const TextStyle(fontSize: 16),
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

  List<TextSpan> _buildQuestionTextSpans(String question) {
    final parts = question.split('_____');
    if (parts.length == 1) {
      // No blanks
      return [TextSpan(text: question)];
    }

    return [
      TextSpan(text: parts[0]),
      TextSpan(
        text: '_____',
        style: TextStyle(
          color: Colors.grey[600],
          backgroundColor: Colors.grey[700],
          fontWeight: FontWeight.bold,
        ),
      ),
      TextSpan(text: parts.length > 1 ? parts[1] : ''),
    ];
  }
}
