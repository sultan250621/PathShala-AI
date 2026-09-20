import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

// ---------------- DATABASE HELPER ----------------
class DBHelper {
  static Database? _db;

  static Future<Database> getDatabase() async {
    if (_db != null) return _db!;
    _db = await openDatabase(
      p.join(await getDatabasesPath(), 'quiz_app.db'),
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE questions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            subject TEXT,
            topic TEXT,
            question TEXT,
            option_a TEXT,
            option_b TEXT,
            option_c TEXT,
            option_d TEXT,
            correct_answer TEXT,
            difficulty TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE progress(
            topic TEXT PRIMARY KEY,
            correct INTEGER,
            total INTEGER
          )
        ''');
        await _insertSampleQuestions(db);
      },
    );
    return _db!;
  }

  static Future<void> _insertSampleQuestions(Database db) async {
    List<Map<String, dynamic>> sampleQuestions = [
      {'subject': 'Mathematics', 'topic': 'Fractions', 'question': '1/2 + 1/4 = ?', 'option_a': '3/4', 'option_b': '2/6', 'option_c': '1/6', 'option_d': '2/4', 'correct_answer': '3/4', 'difficulty': 'easy'},
      {'subject': 'Mathematics', 'topic': 'Fractions', 'question': '3/4 - 1/4 = ?', 'option_a': '2/4', 'option_b': '1/2', 'option_c': '2/0', 'option_d': '4/4', 'correct_answer': '1/2', 'difficulty': 'easy'},
      {'subject': 'Mathematics', 'topic': 'Fractions', 'question': '2/3 x 3/4 = ?', 'option_a': '6/12', 'option_b': '1/2', 'option_c': '5/7', 'option_d': '6/7', 'correct_answer': '1/2', 'difficulty': 'medium'},
      {'subject': 'Mathematics', 'topic': 'Fractions', 'question': '1/2 ÷ 1/4 = ?', 'option_a': '2', 'option_b': '1/8', 'option_c': '4', 'option_d': '1/2', 'correct_answer': '2', 'difficulty': 'medium'},
      {'subject': 'Mathematics', 'topic': 'Fractions', 'question': 'Which is bigger: 3/5 or 2/3?', 'option_a': '3/5', 'option_b': '2/3', 'option_c': 'Equal', 'option_d': 'Cannot say', 'correct_answer': '2/3', 'difficulty': 'hard'},
      {'subject': 'Mathematics', 'topic': 'Algebra', 'question': 'Solve: x + 5 = 12', 'option_a': 'x=5', 'option_b': 'x=7', 'option_c': 'x=17', 'option_d': 'x=12', 'correct_answer': 'x=7', 'difficulty': 'easy'},
      {'subject': 'Mathematics', 'topic': 'Algebra', 'question': 'Solve: 2x = 10', 'option_a': 'x=2', 'option_b': 'x=10', 'option_c': 'x=5', 'option_d': 'x=20', 'correct_answer': 'x=5', 'difficulty': 'easy'},
      {'subject': 'Mathematics', 'topic': 'Algebra', 'question': 'Simplify: 3x + 2x', 'option_a': '5x', 'option_b': '6x', 'option_c': '5x^2', 'option_d': '3x', 'correct_answer': '5x', 'difficulty': 'medium'},
      {'subject': 'Mathematics', 'topic': 'Algebra', 'question': 'Solve: x - 4 = 9', 'option_a': 'x=13', 'option_b': 'x=5', 'option_c': 'x=-5', 'option_d': 'x=36', 'correct_answer': 'x=13', 'difficulty': 'medium'},
      {'subject': 'Mathematics', 'topic': 'Algebra', 'question': 'If x=3, find 2x + 4', 'option_a': '10', 'option_b': '9', 'option_c': '7', 'option_d': '11', 'correct_answer': '10', 'difficulty': 'hard'},
      {'subject': 'Mathematics', 'topic': 'Geometry', 'question': 'How many sides does a triangle have?', 'option_a': '3', 'option_b': '4', 'option_c': '5', 'option_d': '6', 'correct_answer': '3', 'difficulty': 'easy'},
      {'subject': 'Mathematics', 'topic': 'Geometry', 'question': 'Sum of angles in a triangle?', 'option_a': '90°', 'option_b': '180°', 'option_c': '270°', 'option_d': '360°', 'correct_answer': '180°', 'difficulty': 'easy'},
      {'subject': 'Mathematics', 'topic': 'Geometry', 'question': 'Area of a square with side 4?', 'option_a': '8', 'option_b': '12', 'option_c': '16', 'option_d': '20', 'correct_answer': '16', 'difficulty': 'medium'},
      {'subject': 'Mathematics', 'topic': 'Geometry', 'question': 'How many sides does a hexagon have?', 'option_a': '5', 'option_b': '6', 'option_c': '7', 'option_d': '8', 'correct_answer': '6', 'difficulty': 'medium'},
      {'subject': 'Mathematics', 'topic': 'Geometry', 'question': 'A circle has how many degrees?', 'option_a': '180°', 'option_b': '270°', 'option_c': '360°', 'option_d': '90°', 'correct_answer': '360°', 'difficulty': 'hard'},
    ];

    for (var q in sampleQuestions) {
      await db.insert('questions', q);
    }
  }

  static Future<List<Map<String, dynamic>>> getQuestions(String subject, String topic) async {
    final db = await getDatabase();
    return await db.query(
      'questions',
      where: 'subject = ? AND topic = ?',
      whereArgs: [subject, topic],
    );
  }

  // Save/update progress after a quiz finishes
  static Future<void> updateProgress(String topic, int correct, int total) async {
    final db = await getDatabase();
    final existing = await db.query('progress', where: 'topic = ?', whereArgs: [topic]);

    if (existing.isEmpty) {
      await db.insert('progress', {'topic': topic, 'correct': correct, 'total': total});
    } else {
      final oldCorrect = existing.first['correct'] as int;
      final oldTotal = existing.first['total'] as int;
      await db.update(
        'progress',
        {'correct': oldCorrect + correct, 'total': oldTotal + total},
        where: 'topic = ?',
        whereArgs: [topic],
      );
    }
  }

  // Get progress for all topics (returns 0% for topics never attempted)
  static Future<Map<String, double>> getAllProgress(List<String> topics) async {
    final db = await getDatabase();
    final rows = await db.query('progress');

    Map<String, double> result = {for (var t in topics) t: 0.0};

    for (var row in rows) {
      final topic = row['topic'] as String;
      final correct = row['correct'] as int;
      final total = row['total'] as int;
      if (result.containsKey(topic) && total > 0) {
        result[topic] = correct / total;
      }
    }
    return result;
  }
}

// ---------------- HOME SCREEN ----------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> topics = ['Fractions', 'Algebra', 'Geometry'];
  Map<String, double> progress = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProgress();
  }

  Future<void> loadProgress() async {
    final data = await DBHelper.getAllProgress(topics);
    setState(() {
      progress = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadProgress,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ---- Header ----
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF7E5F), Color(0xFFFEB47B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.school, color: Colors.white, size: 40),
                    SizedBox(height: 12),
                    Text(
                      'Offline Math\nLearning',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Learn anytime, even without internet',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ---- Subject Card ----
              const Text('Subjects', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TopicSelectionScreen(subject: 'Mathematics')),
                  ).then((_) => loadProgress());
                },
                child: Container(
                  height: 120,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7F00FF), Color(0xFFE100FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Mathematics', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      Icon(Icons.calculate, color: Colors.white, size: 40),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ---- Progress Overview ----
              const Text('Progress Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ...topics.map((topic) {
                  final percent = progress[topic] ?? 0.0;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(topic, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            Text('${(percent * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: percent,
                            minHeight: 8,
                            backgroundColor: Colors.grey[200],
                            color: percent >= 0.7
                                ? Colors.green
                                : percent >= 0.4
                                ? Colors.orange
                                : Colors.red,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          percent == 0
                              ? 'Not attempted yet'
                              : percent >= 0.7
                              ? 'Great! You are ready.'
                              : percent >= 0.4
                              ? 'Needs more practice'
                              : 'Needs a lot more practice',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- TOPIC SELECTION SCREEN ----------------
class TopicSelectionScreen extends StatelessWidget {
  final String subject;
  const TopicSelectionScreen({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    final topics = ['Fractions', 'Algebra', 'Geometry'];

    return Scaffold(
      appBar: AppBar(title: Text('$subject - Select Topic')),
      body: ListView.builder(
        itemCount: topics.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(topics[index]),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizScreen(subject: subject, topic: topics[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ---------------- QUIZ SCREEN ----------------
class QuizScreen extends StatefulWidget {
  final String subject;
  final String topic;
  const QuizScreen({super.key, required this.subject, required this.topic});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Map<String, dynamic>> questions = [];
  int currentIndex = 0;
  bool isLoading = true;
  String? selectedAnswer;
  int correctCount = 0;
  int wrongCount = 0;

  @override
  void initState() {
    super.initState();
    loadQuestions();
  }

  Future<void> loadQuestions() async {
    final data = await DBHelper.getQuestions(widget.subject, widget.topic);
    setState(() {
      questions = data;
      isLoading = false;
    });
  }

  void checkAnswer(String answer) {
    setState(() {
      selectedAnswer = answer;
      if (answer == questions[currentIndex]['correct_answer']) {
        correctCount++;
      } else {
        wrongCount++;
      }
    });
  }

  void nextQuestion() {
    if (currentIndex < questions.length - 1) {
      setState(() {
        selectedAnswer = null;
        currentIndex++;
      });
    } else {
      // Quiz finished - save progress to database
      DBHelper.updateProgress(widget.topic, correctCount, correctCount + wrongCount);

      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Quiz Complete'),
          content: Text('Correct: $correctCount\nWrong: $wrongCount'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (questions.isEmpty) {
      return const Scaffold(body: Center(child: Text('No questions found for this topic')));
    }

    final q = questions[currentIndex];

    return Scaffold(
      appBar: AppBar(title: Text('${widget.topic} Quiz')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Question ${currentIndex + 1} of ${questions.length}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            Text(q['question'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ...['option_a', 'option_b', 'option_c', 'option_d'].map((key) {
              final optionText = q[key];
              Color? color;
              if (selectedAnswer != null) {
                if (optionText == q['correct_answer']) {
                  color = Colors.green[200];
                } else if (optionText == selectedAnswer) {
                  color = Colors.red[200];
                }
              }
              return Card(
                color: color,
                child: ListTile(
                  title: Text(optionText),
                  onTap: selectedAnswer == null ? () => checkAnswer(optionText) : null,
                ),
              );
            }),
            const Spacer(),
            if (selectedAnswer != null)
              ElevatedButton(
                onPressed: nextQuestion,
                child: Text(currentIndex < questions.length - 1 ? 'Next Question' : 'Finish Quiz'),
              ),
          ],
        ),
      ),
    );
  }
}