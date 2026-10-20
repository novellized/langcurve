import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/dictionary_service.dart';
import '../models/dictionary_entry.dart';
import '../../notebook/repositories/notebook_repository.dart';
import '../../notebook/models/vocabulary.dart';
import '../../grammar/services/sentence_helper.dart';

class DictionaryView extends StatefulWidget {
  final String? initialWord;

  const DictionaryView({super.key, this.initialWord});

  @override
  State<DictionaryView> createState() => _DictionaryViewState();
}

class _DictionaryViewState extends State<DictionaryView> {
  final TextEditingController _searchController = TextEditingController();
  final DictionaryService _dictionaryService = DictionaryService();
  final NotebookRepository _notebookRepo = NotebookRepository();
  final AudioPlayer _audioPlayer = AudioPlayer();

  DictionaryEntry? _entry;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialWord != null && widget.initialWord!.isNotEmpty) {
      _searchController.text = widget.initialWord!;
      _performSearch();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final entry = await _dictionaryService.lookupWord(query);
      if (mounted) {
        setState(() {
          _entry = entry;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _playAudio(String? url) async {
    if (url == null || url.isEmpty) return;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể phát âm thanh này.')),
        );
      }
    }
  }

  void _showSaveToNotebookDialog() async {
    if (_entry == null) return;
    final topics = await _notebookRepo.getTopics();
    if (!mounted) return;

    int? selectedTopicId = topics.isNotEmpty ? topics.first.id : null;
    final exampleController = TextEditingController();
    final definitionController = TextEditingController(text: _entry!.vietnameseMeaning ?? '');
    String? exampleWarning;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final colorScheme = Theme.of(ctx).colorScheme;
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Lưu từ "${_entry!.word}"',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Chọn chủ đề
                    const Text('Chọn chủ đề lưu:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      initialValue: selectedTopicId,
                      items: topics.map((t) {
                        return DropdownMenuItem<int>(
                          value: t.id,
                          child: Text(t.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setModalState(() => selectedTopicId = val);
                      },
                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                    ),
                    const SizedBox(height: 12),

                    // Nghĩa tiếng Việt
                    const Text('Nghĩa tiếng Việt:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: definitionController,
                      decoration: const InputDecoration(hintText: 'Nhập nghĩa của từ...'),
                    ),
                    const SizedBox(height: 12),

                    // Đặt câu ví dụ
                    const Text('Câu ví dụ của bạn:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: exampleController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Tự đặt 1 câu ví dụ có chứa từ "${_entry!.word}"...',
                        errorText: exampleWarning,
                      ),
                      onChanged: (text) {
                        if (text.isNotEmpty && !SentenceHelper.checkWordInSentence(_entry!.word, text)) {
                          setModalState(() {
                            exampleWarning = 'Câu chưa chứa từ "${_entry!.word}" hoặc biến thể của từ.';
                          });
                        } else {
                          setModalState(() => exampleWarning = null);
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // Action Save
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.bookmark_add),
                        label: const Text('Lưu vào sổ tay'),
                        onPressed: selectedTopicId == null
                            ? null
                            : () async {
                                final firstMeaning = _entry!.meanings.isNotEmpty
                                    ? _entry!.meanings.first.partOfSpeech
                                    : '';
                                final vocab = Vocabulary(
                                  topicId: selectedTopicId!,
                                  word: _entry!.word,
                                  definition: definitionController.text.trim(),
                                  partOfSpeech: firstMeaning,
                                  phoneticUk: _entry!.phoneticUk,
                                  audioUrlUk: _entry!.audioUrlUk,
                                  phoneticUs: _entry!.phoneticUs,
                                  audioUrlUs: _entry!.audioUrlUs,
                                  userExample: exampleController.text.trim().isNotEmpty
                                      ? exampleController.text.trim()
                                      : null,
                                  cefrLevel: _entry!.cefrLevel,
                                  synonyms: _entry!.synonyms.join(', '),
                                  antonyms: _entry!.antonyms.join(', '),
                                );

                                await _notebookRepo.upsertVocabulary(vocab);
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Đã lưu "${_entry!.word}" vào sổ tay!')),
                                  );
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Search Bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _performSearch(),
                  decoration: InputDecoration(
                    hintText: 'Nhập từ vựng cần tra cứu (ví dụ: study, algorithm)...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _entry = null);
                            },
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _performSearch,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                child: const Text('Tra từ'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. Loading / Error / Empty states
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_errorMessage != null)
            Card(
              color: colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: colorScheme.onErrorContainer),
                ),
              ),
            )
          else if (_entry != null)
            _buildDictionaryResultCard(colorScheme)
          else
            _buildEmptyPlaceholder(colorScheme),
        ],
      ),
    );
  }

  Widget _buildEmptyPlaceholder(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.menu_book, size: 64, color: colorScheme.outline.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(
            'Tra cứu từ điển đa nguồn',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.outline),
          ),
          const SizedBox(height: 6),
          Text(
            'Hỗ trợ nhận diện từ gốc (Lemmatizer), phát âm UK/US,\nphân loại CEFR và dịch tự động.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: colorScheme.outline),
          ),
        ],
      ),
    );
  }

  Widget _buildDictionaryResultCard(ColorScheme colorScheme) {
    final entry = _entry!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Word header & CEFR badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.word,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                if (entry.cefrLevel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      entry.cefrLevel!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSecondaryContainer,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // UK and US Audio Buttons
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (entry.phoneticUk != null && entry.phoneticUk!.isNotEmpty)
                  ActionChip(
                    avatar: const Icon(Icons.volume_up, size: 18),
                    label: Text('🇬🇧 UK ${entry.phoneticUk}'),
                    onPressed: () => _playAudio(entry.audioUrlUk),
                  ),
                if (entry.phoneticUs != null && entry.phoneticUs!.isNotEmpty)
                  ActionChip(
                    avatar: const Icon(Icons.volume_up, size: 18),
                    label: Text('🇺🇸 US ${entry.phoneticUs}'),
                    onPressed: () => _playAudio(entry.audioUrlUs),
                  ),
              ],
            ),
            const Divider(height: 28),

            // Nghĩa tiếng Việt tự động
            if (entry.vietnameseMeaning != null && entry.vietnameseMeaning!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.translate, size: 20, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.vietnameseMeaning!,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Synonyms & Antonyms
            if (entry.synonyms.isNotEmpty || entry.antonyms.isNotEmpty) ...[
              if (entry.synonyms.isNotEmpty) ...[
                Text('Từ đồng nghĩa:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.outline)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: entry.synonyms.map((s) => Chip(label: Text(s, style: const TextStyle(fontSize: 11)))).toList(),
                ),
                const SizedBox(height: 10),
              ],
              if (entry.antonyms.isNotEmpty) ...[
                Text('Từ trái nghĩa:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.outline)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: entry.antonyms.map((a) => Chip(label: Text(a, style: const TextStyle(fontSize: 11)))).toList(),
                ),
                const SizedBox(height: 10),
              ],
              const Divider(height: 20),
            ],

            // Definitions List
            ...entry.meanings.map((m) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.partOfSpeech.toUpperCase(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...m.definitions.map((d) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• ${d.definition}', style: const TextStyle(fontSize: 14)),
                            if (d.translatedDefinition != null && d.translatedDefinition!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 14.0, top: 2),
                                child: Text(
                                  d.translatedDefinition!,
                                  style: TextStyle(fontSize: 13, color: colorScheme.primary),
                                ),
                              ),
                            if (d.example != null && d.example!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 14.0, top: 2),
                                child: Text(
                                  '"${d.example!}"',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),
            // Save Button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.bookmark_add),
                label: const Text('Lưu vào sổ từ vựng'),
                onPressed: _showSaveToNotebookDialog,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
