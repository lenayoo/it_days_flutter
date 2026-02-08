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
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        },
        child: Center(
          child: Image.asset(
            'assets/imgs/launcher_screen.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

// ✅ 단어 모델
class Word {
  final int id;
  final String kanji;
  final String hira;
  final String meaningKo;
  final List<String> tags;

  Word({
    required this.id,
    required this.kanji,
    required this.hira,
    required this.meaningKo,
    required this.tags,
  });

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      id: json['id'],
      kanji: json['kanji'],
      hira: json['hira'],
      meaningKo: json['meaning_ko'],
      tags:
          (json['tags'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toList(),
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
  final ScrollController _listController = ScrollController();

  List<Word> _basicWords = [];
  List<Word> _advancedWords = [];
  List<Word> _currentTen = [];
  WordCategory _currentCategory = WordCategory.basic;
  String _selectedTag = 'all';
  bool _showAllTags = false;
  final Map<String, Color> _tagColorCache = {};
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
      _setCategory(WordCategory.basic);
    } catch (error) {
      setState(() {
        _loadError = 'JSON 로딩 실패: $error';
        _currentTen = [];
        _loading = false;
      });
    }
  }

  void _setCategory(WordCategory category) {
    final source =
        category == WordCategory.basic ? _basicWords : _advancedWords;
    if (source.isEmpty) {
      setState(() {
        _currentTen = [];
        _currentCategory = category;
        _selectedTag = 'all';
        _showAllTags = false;
        _loading = false;
      });
      return;
    }

    final randomTen = _pickRandomTen(source);
    setState(() {
      _currentTen = randomTen;
      _currentCategory = category;
      _selectedTag = 'all';
      _showAllTags = false;
      _loading = false;
    });
    _scrollToTop();
  }

  List<Word> _pickRandomTen(List<Word> source) {
    final count = min(10, source.length);
    final shuffled = List<Word>.from(source)..shuffle(_rng);
    return shuffled.take(count).toList();
  }

  List<String> _tagsForCurrentCategory() {
    final source =
        _currentCategory == WordCategory.basic ? _basicWords : _advancedWords;
    final tags = <String>{};
    for (final word in source) {
      tags.addAll(word.tags);
    }
    final sorted = tags.toList()..sort();
    return sorted;
  }

  Color _colorForTag(String tag) {
    return _tagColorCache.putIfAbsent(tag, () {
      final hash = tag.codeUnits.fold(0, (sum, code) => sum + code);
      final hue = (hash * 37) % 360;
      return HSLColor.fromAHSL(1, hue.toDouble(), 0.55, 0.78).toColor();
    });
  }

  void _selectTag(String tag) {
    if (tag == _selectedTag) return;
    setState(() {
      _selectedTag = tag;
    });
    _scrollToTop();
  }

  void _scrollToTop() {
    if (!_listController.hasClients) return;
    _listController.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  List<Word> get _visibleWords {
    if (_selectedTag == 'all') {
      return _currentTen;
    }
    final source =
        _currentCategory == WordCategory.basic ? _basicWords : _advancedWords;
    return source.where((word) => word.tags.contains(_selectedTag)).toList();
  }

  Widget _buildTagsBar() {
    final tags = _tagsForCurrentCategory();
    if (tags.isEmpty) return const SizedBox.shrink();
    final allTags = ['all', ...tags];
    if (!_showAllTags) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _showAllTags = true;
              });
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.black12),
              ),
            ),
            child: const Text('By section'),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                allTags.map((tag) {
                  final isSelected = tag == _selectedTag;
                  final baseColor =
                      tag == 'all' ? Colors.grey.shade400 : _colorForTag(tag);
                  return InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => _selectTag(tag),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? baseColor.withOpacity(0.9)
                                : baseColor.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(24),
                        border:
                            isSelected
                                ? Border.all(color: Colors.black87, width: 1.2)
                                : null,
                      ),
                      child: Text(
                        tag.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _showAllTags = false;
                });
              },
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor:
          _currentCategory == WordCategory.basic
              ? const Color(0xFFBFD7EA)
              : const Color(0xFFFDE2EB),
      appBar: AppBar(
        title: Text(
          _currentCategory == WordCategory.basic
              ? '基本情報技術者👨‍💻 - 基本'
              : '基本情報技術者👩‍💻 - 高級',
        ),
        backgroundColor:
            _currentCategory == WordCategory.basic
                ? const Color(0xFFBFD7EA)
                : const Color(0xFFFDE2EB),
        foregroundColor: Colors.black87,
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _setCategory(WordCategory.basic),
                  icon: const Icon(Icons.list_alt),
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
                  onPressed: () => _setCategory(WordCategory.advanced),
                  icon: const Icon(Icons.list_alt),
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
              : Column(
                children: [
                  _buildTagsBar(),
                  Expanded(
                    child:
                        _visibleWords.isEmpty
                            ? const Center(child: Text('표시할 단어가 없습니다.'))
                            : ListView.builder(
                              controller: _listController,
                              padding: const EdgeInsets.all(16),
                              itemCount: _visibleWords.length,
                              itemBuilder: (context, index) {
                                final word = _visibleWords[index];

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                  ),
                ],
              ),
    );
  }
}

enum WordCategory { basic, advanced }
