import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

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

// ✅ 단어 모델
class Word {
  final int id;
  final String kanji;
  final String hira;
  final String meaningKo;

  Word({
    required this.id,
    required this.kanji,
    required this.hira,
    required this.meaningKo,
  });

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      id: json['id'],
      kanji: json['kanji'],
      hira: json['hira'],
      meaningKo: json['meaning_ko'],
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _rng = Random();

  List<Word> _basicWords = [];
  List<Word> _advancedWords = [];
  List<Word> _currentTen = [];
  WordCategory _currentCategory = WordCategory.basic;
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    try {
      final results = await Future.wait([
        rootBundle.loadString('assets/it_words_basic.json'),
        rootBundle.loadString('assets/it_words_advanced.json'),
      ]);

      final basicList = json.decode(results[0]) as List<dynamic>;
      final advancedList = json.decode(results[1]) as List<dynamic>;

      _basicWords = basicList.map((e) => Word.fromJson(e)).toList();
      _advancedWords = advancedList.map((e) => Word.fromJson(e)).toList();
      _loadError = null;
      _refreshRandomTen(WordCategory.basic);
    } catch (error) {
      setState(() {
        _loadError = 'JSON 로딩 실패: $error';
        _currentTen = [];
        _loading = false;
      });
    }
  }

  void _refreshRandomTen(WordCategory category) {
    final source =
        category == WordCategory.basic ? _basicWords : _advancedWords;
    if (source.isEmpty) {
      setState(() {
        _currentTen = [];
        _currentCategory = category;
        _loading = false;
      });
      return;
    }

    final count = min(10, source.length);
    final shuffled = List<Word>.from(source)..shuffle(_rng);

    setState(() {
      _currentTen = shuffled.take(count).toList();
      _currentCategory = category;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentCategory == WordCategory.basic
              ? '基本情報技術者 - 基本'
              : '基本情報技術者 - 高級',
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _refreshRandomTen(WordCategory.basic),
                  icon: const Icon(Icons.shuffle),
                  label: const Text('基本単語'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _currentCategory == WordCategory.basic
                            ? null
                            : Colors.grey.shade300,
                    foregroundColor:
                        _currentCategory == WordCategory.basic
                            ? null
                            : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _refreshRandomTen(WordCategory.advanced),
                  icon: const Icon(Icons.shuffle),
                  label: const Text('高級単語'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _currentCategory == WordCategory.advanced
                            ? null
                            : Colors.grey.shade300,
                    foregroundColor:
                        _currentCategory == WordCategory.advanced
                            ? null
                            : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      body:
          _loadError != null
              ? Center(child: Text(_loadError!))
              : _currentTen.isEmpty
              ? const Center(child: Text('표시할 단어가 없습니다.'))
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _currentTen.length,
                itemBuilder: (context, index) {
                  final word = _currentTen[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            word.kanji,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            word.hira,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            word.meaningKo,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}

enum WordCategory { basic, advanced }
