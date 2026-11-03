import 'package:flutter/material.dart';
import '../../notebook/repositories/notebook_repository.dart';

class ProfileView extends StatefulWidget {
  final Function(int targetTab)? onNavigate;

  const ProfileView({super.key, this.onNavigate});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final NotebookRepository _notebookRepo = NotebookRepository();

  Map<String, dynamic> _profile = {
    'xp': 0,
    'streak_count': 0,
    'daily_goal': 10,
    'today_reviewed_count': 0,
  };
  Map<String, int> _stats = {
    'total_topics': 0,
    'total_words': 0,
    'total_examples': 0,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    final profile = await _notebookRepo.getUserProfile();
    final stats = await _notebookRepo.getStats();

    if (mounted) {
      setState(() {
        _profile = profile;
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  void _showEditDailyGoalDialog() {
    final controller = TextEditingController(text: '${_profile['daily_goal'] ?? 10}');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đặt mục tiêu từ vựng hàng ngày'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Số từ muốn ôn tập mỗi ngày',
            suffixText: 'từ/ngày',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () async {
              final val = int.tryParse(controller.text.trim());
              if (val != null && val > 0) {
                await _notebookRepo.updateDailyGoal(val);
                if (ctx.mounted) Navigator.pop(ctx);
                _loadProfileData();
              }
            },
            child: const Text('Lưu mục tiêu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final xp = _profile['xp'] as int? ?? 0;
    final streak = _profile['streak_count'] as int? ?? 0;
    final dailyGoal = _profile['daily_goal'] as int? ?? 10;
    final todayCount = _profile['today_reviewed_count'] as int? ?? 0;
    final totalWords = _stats['total_words'] ?? 0;
    final totalTopics = _stats['total_topics'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Profile Card
          Card(
            color: colorScheme.surfaceContainerHigh,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Icon(Icons.person, size: 36, color: colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Người học LangCurve',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Cấp độ: Người chinh phục từ vựng',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Gamification Highlights (XP & Streak)
          Row(
            children: [
              Expanded(
                child: Card(
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text('🔥 Chuỗi học', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.brown)),
                        const SizedBox(height: 6),
                        Text(
                          '$streak ngày',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  color: colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text('⚡ Điểm XP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer)),
                        const SizedBox(height: 6),
                        Text(
                          '$xp XP',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Daily Goal Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text('🎯', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(
                            'Mục tiêu học hôm nay',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: _showEditDailyGoalDialog,
                        child: const Text('Đổi mục tiêu'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Đã hoàn thành $todayCount / $dailyGoal từ vựng',
                    style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: (todayCount / dailyGoal).clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Learning Statistics
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thống kê kho từ vựng',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Divider(height: 20),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.secondaryContainer,
                      child: Icon(Icons.menu_book, color: colorScheme.onSecondaryContainer),
                    ),
                    title: const Text('Tổng số từ vựng đã lưu'),
                    trailing: Text(
                      '$totalWords từ',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.tertiaryContainer,
                      child: Icon(Icons.folder, color: colorScheme.onTertiaryContainer),
                    ),
                    title: const Text('Tổng số chủ đề đã tạo'),
                    trailing: Text(
                      '$totalTopics chủ đề',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
