import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../notebook/repositories/notebook_repository.dart';
import '../../notebook/models/topic.dart';
import '../../notebook/models/vocabulary.dart';
import '../../srs/repositories/srs_repository.dart';
import '../../grammar/services/sentence_helper.dart';
import '../../grammar/services/grammar_checker_service.dart';
import '../../grammar/models/grammar_error.dart';

class PracticeView extends StatefulWidget {
  final int? initialTopicId;

  const PracticeView({super.key, this.initialTopicId});

  @override
  State<PracticeView> createState() => _PracticeViewState();
}

class _PracticeViewState extends State<PracticeView> {
  final NotebookRepository _notebookRepo = NotebookRepository();
  final SrsRepository _srsRepo = SrsRepository();
  final GrammarCheckerService _grammarChecker = GrammarCheckerService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<Topic> _topics = [];
  int? _selectedTopicId; // null = all due words

  List<Vocabulary> _studyWords = [];
  int _currentIndex = 0;
  bool _isFlipped = false;
  bool _isLoading = true;

  // Sentence writing & grammar check
  final TextEditingController _sentenceController = TextEditingController();
  List<GrammarError> _grammarErrors = [];
  bool _isCheckingGrammar = false;

  @override
  void initState() {
    super.initState();
    _selectedTopicId = widget.initialTopicId;
    _initPractice();
  }

  @override
  void dispose() {
    _sentenceController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _initPractice() async {
    setState(() => _isLoading = true);
    final topics = await _notebookRepo.getTopics();
    await _loadStudyWords();
    if (mounted) {
      setState(() {
        _topics = topics;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStudyWords() async {
    List<Vocabulary> words;
    if (_selectedTopicId == null) {
      // Due words across all topics
      words = await _srsRepo.getDueOnlyVocabularies();
      if (words.isEmpty) {
        words = await _srsRepo.getVocabulariesForReview();
      }
    } else {
      words = await _srsRepo.getVocabulariesForReview(topicId: _selectedTopicId);
    }

    words.shuffle();
    if (mounted) {
      setState(() {
        _studyWords = words;
        _currentIndex = 0;
        _isFlipped = false;
        _sentenceController.clear();
        _grammarErrors = [];
      });
    }
  }

  Future<void> _playAudio(String? url) async {
    if (url == null || url.isEmpty) return;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(url));
    } catch (_) {}
  }

  Future<void> _checkGrammar() async {
    final text = _sentenceController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isCheckingGrammar = true);
    final errors = await _grammarChecker.checkGrammar(text);
    if (mounted) {
      setState(() {
        _grammarErrors = errors;
        _isCheckingGrammar = false;
      });
    }
  }

  Future<void> _submitReview(int quality) async {
    if (_studyWords.isEmpty) return;
    final currentWord = _studyWords[_currentIndex];

    // Save sentence if user wrote one
    final userSentence = _sentenceController.text.trim();
    if (userSentence.isNotEmpty) {
      await _notebookRepo.updateExample(currentWord.id!, userSentence);
    }

    // Record review in SRS
    final updated = await _srsRepo.recordReview(
      vocabId: currentWord.id!,
      quality: quality,
    );

    if (mounted) {
      final xpGained = quality == 5 ? 20 : (quality >= 3 ? 10 : 0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            quality >= 3
                ? 'Tuyệt vời! +$xpGained XP. Lặp lại sau ${updated.interval} ngày.'
                : 'Đã ghi nhận! Từ sẽ được xếp ôn lại sớm.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      setState(() {
        if (_currentIndex < _studyWords.length - 1) {
          _currentIndex++;
          _isFlipped = false;
          _sentenceController.clear();
          _grammarErrors = [];
        } else {
          _studyWords = [];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Topic Filter Selector
          _buildTopicSelector(colorScheme),
          const SizedBox(height: 16),

          // 2. Practice Card / Empty State
          if (_studyWords.isEmpty)
            _buildEmptyState(colorScheme)
          else
            _buildFlashcard(colorScheme),
        ],
      ),
    );
  }

  Widget _buildTopicSelector(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.tune, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: _selectedTopicId,
                isExpanded: true,
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Tất cả từ đến hạn ôn (SRS)'),
                  ),
                  ..._topics.map((t) {
                    return DropdownMenuItem<int?>(
                      value: t.id,
                      child: Text('Chủ đề: ${t.name} (${t.wordCount} từ)'),
                    );
                  }),
                ],
                onChanged: (val) {
                  setState(() => _selectedTopicId = val);
                  _loadStudyWords();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
        child: Column(
          children: [
            Icon(Icons.task_alt, size: 64, color: colorScheme.primary),
            const SizedBox(height: 16),
            const Text(
              'Không có từ vựng nào cần ôn tập!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Bạn đã hoàn thành mục tiêu ôn tập cho chủ đề này.\nHãy chọn chủ đề khác hoặc đi tra từ mới!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlashcard(ColorScheme colorScheme) {
    final v = _studyWords[_currentIndex];
    final maskedSentence = v.userExample != null && v.userExample!.isNotEmpty
        ? SentenceHelper.maskWordInSentence(v.word, v.userExample!)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Progress header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Từ ${_currentIndex + 1} / ${_studyWords.length}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            if (v.cefrLevel != null)
              Chip(
                label: Text(v.cefrLevel!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                backgroundColor: colorScheme.secondaryContainer,
                labelStyle: TextStyle(color: colorScheme.onSecondaryContainer),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        const SizedBox(height: 10),

        // Main Flashcard
        Card(
          elevation: 2,
          color: colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Front / Hint
                if (!_isFlipped) ...[
                  Icon(Icons.help_outline, size: 40, color: colorScheme.secondary),
                  const SizedBox(height: 16),
                  if (maskedSentence != null) ...[
                    const Text('Điền từ thích hợp vào chỗ trống:', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 8),
                    Text(
                      maskedSentence,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.4),
                    ),
                  ] else ...[
                    const Text('Định nghĩa của từ:', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 8),
                    Text(
                      v.definition.isNotEmpty ? v.definition : '(Hãy tự nhớ lại nghĩa của từ)',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.flip),
                    label: const Text('Lật thẻ xem đáp án'),
                    onPressed: () => setState(() => _isFlipped = true),
                  ),
                ]
                // Back / Answer
                else ...[
                  Text(
                    v.word,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Audio Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (v.phoneticUk != null)
                        ActionChip(
                          avatar: const Icon(Icons.volume_up, size: 16),
                          label: Text('UK ${v.phoneticUk}'),
                          onPressed: () => _playAudio(v.audioUrlUk),
                        ),
                      const SizedBox(width: 8),
                      if (v.phoneticUs != null)
                        ActionChip(
                          avatar: const Icon(Icons.volume_up, size: 16),
                          label: Text('US ${v.phoneticUs}'),
                          onPressed: () => _playAudio(v.audioUrlUs),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (v.definition.isNotEmpty)
                    Text(
                      v.definition,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  if (v.userExample != null && v.userExample!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text(
                        'Ví dụ: "${v.userExample}"',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 3. Sentence Writing & Grammar Check
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Thực hành đặt câu với từ này:', style: TextStyle(fontWeight: FontWeight.w600)),
                    if (_isCheckingGrammar)
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    else
                      TextButton.icon(
                        icon: const Icon(Icons.spellcheck, size: 16),
                        label: const Text('Check ngữ pháp'),
                        onPressed: _checkGrammar,
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _sentenceController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Nhập câu của bạn có chứa "${v.word}"...',
                  ),
                ),
                if (_grammarErrors.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ..._grammarErrors.map((err) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Lỗi: "${err.badText}" — ${err.message}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.brown)),
                          if (err.replacements.isNotEmpty)
                            Text('Gợi ý: ${err.replacements.join(', ')}', style: TextStyle(fontSize: 11, color: colorScheme.primary)),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 4. SRS Rating Buttons
        if (_isFlipped) ...[
          const Text(
            'Bạn nhớ từ này như thế nào? (SuperMemo SM-2):',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.errorContainer,
                    foregroundColor: colorScheme.onErrorContainer,
                  ),
                  onPressed: () => _submitReview(0),
                  child: const Text('Quên (0)'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.amber.shade100,
                    foregroundColor: Colors.brown.shade800,
                  ),
                  onPressed: () => _submitReview(1),
                  child: const Text('Khó (1)'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () => _submitReview(3),
                  child: const Text('Nhớ (3)'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primaryContainer,
                    foregroundColor: colorScheme.onPrimaryContainer,
                  ),
                  onPressed: () => _submitReview(5),
                  child: const Text('Dễ (5) ⚡'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
