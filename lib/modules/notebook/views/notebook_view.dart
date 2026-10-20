import 'package:flutter/material.dart';
import '../models/topic.dart';
import '../repositories/notebook_repository.dart';
import 'topic_detail_view.dart';

class NotebookView extends StatefulWidget {
  final Function(int topicId)? onPracticeTopic;

  const NotebookView({super.key, this.onPracticeTopic});

  @override
  State<NotebookView> createState() => _NotebookViewState();
}

class _NotebookViewState extends State<NotebookView> {
  final NotebookRepository _notebookRepo = NotebookRepository();
  List<Topic> _topics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    setState(() => _isLoading = true);
    final list = await _notebookRepo.getTopics();
    if (mounted) {
      setState(() {
        _topics = list;
        _isLoading = false;
      });
    }
  }

  void _showAddTopicDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tạo chủ đề từ vựng mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Tên chủ đề',
                hintText: 'Ví dụ: IELTS Speaking, Du lịch...',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Mô tả (tùy chọn)',
                hintText: 'Mô tả ngắn gọn về chủ đề này...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                await _notebookRepo.createTopic(name, descController.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
                _loadTopics();
              }
            },
            child: const Text('Tạo chủ đề'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTopic(Topic topic) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xóa chủ đề "${topic.name}"?'),
        content: const Text(
          'Tất cả từ vựng thuộc chủ đề này cũng sẽ bị xóa vĩnh viễn.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () async {
              await _notebookRepo.deleteTopic(topic.id!);
              if (ctx.mounted) Navigator.pop(ctx);
              _loadTopics();
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTopicDialog,
        icon: const Icon(Icons.add),
        label: const Text('Thêm chủ đề'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _topics.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open, size: 64, color: colorScheme.outline),
                      const SizedBox(height: 12),
                      const Text('Chưa có chủ đề nào.', style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 6),
                      Text(
                        'Bấm "Thêm chủ đề" để bắt đầu phân loại từ vựng.',
                        style: TextStyle(fontSize: 12, color: colorScheme.outline),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
                  itemCount: _topics.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final t = _topics[index];
                    return Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TopicDetailView(
                                topic: t,
                                onPracticeTopic: widget.onPracticeTopic,
                              ),
                            ),
                          );
                          _loadTopics();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: colorScheme.primaryContainer,
                                child: Icon(Icons.folder, color: colorScheme.onPrimaryContainer),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (t.description != null && t.description!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          t.description!,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 12, color: colorScheme.outline),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${t.wordCount} từ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.more_vert, size: 20),
                                onPressed: () => _confirmDeleteTopic(t),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
