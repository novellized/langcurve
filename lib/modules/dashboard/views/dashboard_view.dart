import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../notebook/repositories/notebook_repository.dart';
import '../../srs/repositories/srs_repository.dart';
import '../../analytics/services/tracking_service.dart';
import '../../analytics/models/curve_data_point.dart';
import '../../videos/services/bbc_video_sync_service.dart';
import '../../videos/models/bbc_video_item.dart';

class DashboardView extends StatefulWidget {
  final Function(int targetTab)? onNavigate;

  const DashboardView({super.key, this.onNavigate});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final NotebookRepository _notebookRepo = NotebookRepository();
  final SrsRepository _srsRepo = SrsRepository();
  final TrackingService _trackingService = TrackingService();
  final BbcVideoSyncService _videoService = BbcVideoSyncService();

  Map<String, int> _stats = {
    'total_topics': 0,
    'total_words': 0,
    'total_examples': 0,
    'xp': 0,
    'streak_count': 0,
    'daily_goal': 10,
    'today_reviewed_count': 0,
  };
  int _dueWordsCount = 0;
  List<CurveDataPoint> _curveData = [];
  List<BbcVideoItem> _videos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData({bool forceRefreshVideos = false}) async {
    setState(() => _isLoading = true);
    try {
      final stats = await _notebookRepo.getStats();
      final dueWords = await _srsRepo.getDueOnlyVocabularies();
      final curve = await _trackingService.getLearningCurve();
      final videos = await _videoService.fetchVideos(forceRefresh: forceRefreshVideos);

      if (mounted) {
        setState(() {
          _stats = stats;
          _dueWordsCount = dueWords.length;
          _curveData = curve;
          _videos = videos;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEditDailyGoalDialog() {
    final controller = TextEditingController(text: '${_stats['daily_goal'] ?? 10}');
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
                _loadDashboardData();
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

    return RefreshIndicator(
      onRefresh: () => _loadDashboardData(forceRefreshVideos: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Welcome, Streak & Daily Goal Banner
            _buildWelcomeBanner(colorScheme),
            const SizedBox(height: 16),

            // 2. Quick Action Buttons
            _buildQuickActions(colorScheme),
            const SizedBox(height: 16),

            // 3. Statistics Grid
            _buildStatsGrid(colorScheme),
            const SizedBox(height: 16),

            // 4. Spaced Repetition Due Banner
            _buildDueReviewBanner(colorScheme),
            const SizedBox(height: 24),

            // 5. Learning Curve Analytics Chart
            _buildLearningCurveSection(colorScheme),
            const SizedBox(height: 24),

            // 6. BBC Learning English Videos Section
            _buildBbcVideosSection(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(ColorScheme colorScheme) {
    final todayCount = _stats['today_reviewed_count'] ?? 0;
    final dailyGoal = _stats['daily_goal'] ?? 10;
    final progress = (todayCount / dailyGoal).clamp(0.0, 1.0);
    final streak = _stats['streak_count'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chào mừng trở lại! 👋',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Duy trì thói quen học từ vựng cùng LangCurve.',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),

              // Streak Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 4),
                    Text(
                      '$streak ngày',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Daily Goal Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('🎯', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    'Mục tiêu hôm nay: $todayCount/$dailyGoal từ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: _showEditDailyGoalDialog,
                child: Text(
                  'Đổi mục tiêu',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: colorScheme.surfaceContainerHighest,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: ActionChip(
            avatar: const Icon(Icons.school, size: 18),
            label: const Text('Ôn SM-2'),
            onPressed: () {
              if (widget.onNavigate != null) widget.onNavigate!(3);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ActionChip(
            avatar: const Icon(Icons.quiz, size: 18),
            label: const Text('Thách Quiz'),
            onPressed: () {
              if (widget.onNavigate != null) widget.onNavigate!(3);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ActionChip(
            avatar: const Icon(Icons.search, size: 18),
            label: const Text('Tra từ mới'),
            onPressed: () {
              if (widget.onNavigate != null) widget.onNavigate!(1);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(ColorScheme colorScheme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        final count = isNarrow ? 2 : 4;
        return GridView.count(
          crossAxisCount: count,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: isNarrow ? 1.6 : 2.2,
          children: [
            _buildStatCard(
              title: 'Chủ đề',
              value: '${_stats['total_topics']}',
              icon: Icons.folder_outlined,
              color: colorScheme.primary,
              bgColor: colorScheme.primaryContainer.withValues(alpha: 0.4),
            ),
            _buildStatCard(
              title: 'Tổng từ vựng',
              value: '${_stats['total_words']}',
              icon: Icons.translate,
              color: colorScheme.secondary,
              bgColor: colorScheme.secondaryContainer.withValues(alpha: 0.4),
            ),
            _buildStatCard(
              title: 'Câu ví dụ',
              value: '${_stats['total_examples']}',
              icon: Icons.edit_note,
              color: colorScheme.tertiary,
              bgColor: colorScheme.tertiaryContainer.withValues(alpha: 0.4),
            ),
            _buildStatCard(
              title: 'Cần ôn hôm nay',
              value: '$_dueWordsCount',
              icon: Icons.alarm,
              color: Colors.orange.shade800,
              bgColor: Colors.orange.shade100,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: bgColor,
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDueReviewBanner(ColorScheme colorScheme) {
    return Card(
      color: colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.school, size: 36, color: colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _dueWordsCount > 0
                        ? 'Có $_dueWordsCount từ đến hạn ôn tập SM-2'
                        : 'Bạn đã hoàn thành các từ cần ôn hôm nay!',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _dueWordsCount > 0
                        ? 'Ôn tập đúng chu kỳ giúp tăng 80% khả năng ghi nhớ dài hạn.'
                        : 'Hãy tra từ mới hoặc luyện tập thêm các chủ đề khác.',
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () {
                if (widget.onNavigate != null) {
                  widget.onNavigate!(3); // Tab Practice
                }
              },
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('Ôn tập'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLearningCurveSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Đường cong học tập (Curve Analytics)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              'SuperMemo SM-2',
              style: TextStyle(fontSize: 12, color: colorScheme.primary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _curveData.isEmpty
                ? SizedBox(
                    height: 160,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.show_chart, size: 40, color: colorScheme.outline),
                          const SizedBox(height: 8),
                          Text(
                            'Chưa có dữ liệu ôn tập. Hãy thực hành một số từ vựng để vẽ đường cong!',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: colorScheme.outline),
                          ),
                        ],
                      ),
                    ),
                  )
                : SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true, drawVerticalLine: false),
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 24,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index >= 0 && index < _curveData.length) {
                                  final date = _curveData[index].date;
                                  final parts = date.split('-');
                                  if (parts.length >= 3) {
                                    return Text(
                                      '${parts[2]}/${parts[1]}',
                                      style: TextStyle(fontSize: 10, color: colorScheme.outline),
                                    );
                                  }
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _curveData.asMap().entries.map((e) {
                              return FlSpot(e.key.toDouble(), e.value.wordCount.toDouble());
                            }).toList(),
                            isCurved: true,
                            color: colorScheme.primary,
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildBbcVideosSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.ondemand_video, size: 20, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Bài học BBC Learning English mới nhất',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              tooltip: 'Đồng bộ bài học BBC mới',
              onPressed: () => _loadDashboardData(forceRefreshVideos: true),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _videos.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final video = _videos[index];
            return Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    'https://img.youtube.com/vi/${video.id}/hqdefault.jpg',
                    width: 80,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 80,
                      height: 60,
                      color: colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.video_library),
                    ),
                  ),
                ),
                title: Text(
                  video.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    video.desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: colorScheme.outline),
                  ),
                ),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () async {
                  final launched = await BbcVideoSyncService.openVideo(video.id);
                  if (!launched && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Không thể mở video ${video.title}')),
                    );
                  }
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
