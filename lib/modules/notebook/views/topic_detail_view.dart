import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/topic.dart';
import '../models/vocabulary.dart';
import '../repositories/notebook_repository.dart';

class TopicDetailView extends StatefulWidget {
  final Topic topic;
  final Function(int topicId)? onPracticeTopic;

  const TopicDetailView({
    super.key,
    required this.topic,
    this.onPracticeTopic,
  });

  @override
  State<TopicDetailView> createState() => _TopicDetailViewState();
}

class _TopicDetailViewState extends State<TopicDetailView> {
  final NotebookRepository _notebookRepo = NotebookRepository();
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<Vocabulary> _vocabularies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVocabularies();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadVocabularies() async {
    setState(() => _isLoading = true);
    final vocabs = await _notebookRepo.getVocabularies(widget.topic.id!);
    if (mounted) {
      setState(() {
        _vocabularies = vocabs;
        _isLoading = false;
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

  void _confirmDeleteWord(Vocabulary vocab) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xóa từ "${vocab.word}"?'),
        content: const Text('Từ vựng này sẽ bị xóa khỏi chủ đề và mất tiến trình ôn tập SRS.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () async {
              await _notebookRepo.deleteVocabulary(vocab.id!);
              if (ctx.mounted) Navigator.pop(ctx);
              _loadVocabularies();
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.topic.name),
        actions: [
          if (_vocabularies.isNotEmpty && widget.onPracticeTopic != null)
            IconButton(
              icon: const Icon(Icons.school),
              tooltip: 'Luyện tập chủ đề này',
              onPressed: () {
                widget.onPracticeTopic!(widget.topic.id!);
                Navigator.pop(context);
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vocabularies.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 56, color: colorScheme.outline),
                      const SizedBox(height: 12),
                      const Text('Chưa có từ vựng nào trong chủ đề này.'),
                      const SizedBox(height: 8),
                      Text(
                        'Hãy qua màn hình Tra từ để lưu từ mới vào đây.',
                        style: TextStyle(fontSize: 12, color: colorScheme.outline),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _vocabularies.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final v = _vocabularies[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    v.word,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                                if (v.cefrLevel != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: colorScheme.secondaryContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      v.cefrLevel!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSecondaryContainer,
                                      ),
                                    ),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20),
                                  onPressed: () => _confirmDeleteWord(v),
                                ),
                              ],
                            ),
                            if (v.phoneticUk != null || v.phoneticUs != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  children: [
                                    if (v.phoneticUk != null) ...[
                                      InkWell(
                                        onTap: () => _playAudio(v.audioUrlUk),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.volume_up, size: 16),
                                            const SizedBox(width: 4),
                                            Text('UK ${v.phoneticUk}', style: const TextStyle(fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                    ],
                                    if (v.phoneticUs != null) ...[
                                      InkWell(
                                        onTap: () => _playAudio(v.audioUrlUs),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.volume_up, size: 16),
                                            const SizedBox(width: 4),
                                            Text('US ${v.phoneticUs}', style: const TextStyle(fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            if (v.definition.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text(
                                  v.definition,
                                  style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
                                ),
                              ),
                            if (v.userExample != null && v.userExample!.isNotEmpty)
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(top: 6),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Ví dụ: "${v.userExample}"',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'SRS Interval: ${v.interval} ngày',
                                  style: TextStyle(fontSize: 11, color: colorScheme.outline),
                                ),
                                Text(
                                  v.countdownText,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: v.isDue ? Colors.red.shade700 : colorScheme.primary,
                                  ),
                                ),
                              ],
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
