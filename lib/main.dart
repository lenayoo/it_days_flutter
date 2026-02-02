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

  List<Word> _allWords = [];
  List<Word> _currentTen = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    final jsonString = await rootBundle.loadString(
      'assets/it_words_basic.json',
    );
    final List<dynamic> jsonList = json.decode(jsonString);

    _allWords = jsonList.map((e) => Word.fromJson(e)).toList();
    _refreshRandomTen();
  }

  void _refreshRandomTen() {
    if (_allWords.isEmpty) return;

    final count = min(10, _allWords.length);
    final shuffled = List<Word>.from(_allWords)..shuffle(_rng);

    setState(() {
      _currentTen = shuffled.take(count).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('IT 일본어 단어 10개')),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _refreshRandomTen,
        icon: const Icon(Icons.shuffle),
        label: const Text('다시 추천'),
      ),

      body: _currentTen.isEmpty
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
                          style:
                              const TextStyle(fontSize: 18, color: Colors.grey),
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
