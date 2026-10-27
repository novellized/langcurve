import 'package:flutter/material.dart';
import '../core/theme/theme_controller.dart';
import '../modules/dashboard/views/dashboard_view.dart';
import '../modules/dictionary/views/dictionary_view.dart';
import '../modules/notebook/views/notebook_view.dart';
import '../modules/practice/views/practice_view.dart';
import '../modules/backup/views/settings_dialog.dart';
import '../modules/notebook/repositories/notebook_repository.dart';

class AdaptiveHomeScaffold extends StatefulWidget {
  const AdaptiveHomeScaffold({super.key});

  @override
  State<AdaptiveHomeScaffold> createState() => _AdaptiveHomeScaffoldState();
}

class _AdaptiveHomeScaffoldState extends State<AdaptiveHomeScaffold> {
  int _selectedTabIndex = 0;
  int _userXp = 0;
  int _streakCount = 0;
  int? _practiceTopicId;
  final NotebookRepository _notebookRepo = NotebookRepository();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final profile = await _notebookRepo.getUserProfile();
    if (mounted) {
      setState(() {
        _userXp = profile['xp'] as int;
        _streakCount = profile['streak_count'] as int;
      });
    }
  }

  void _navigateToTab(int index, {int? topicId}) {
    setState(() {
      _selectedTabIndex = index;
      if (index == 3 && topicId != null) {
        _practiceTopicId = topicId;
      }
    });
    _loadProfileData();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktopOrTablet = MediaQuery.of(context).size.width >= 640;

    final List<Widget> pages = [
      DashboardView(onNavigate: _navigateToTab),
      const DictionaryView(),
      NotebookView(onPracticeTopic: (id) => _navigateToTab(3, topicId: id)),
      PracticeView(initialTopicId: _practiceTopicId),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.auto_graph, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'LangCurve',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
        actions: [
          // Daily Streak Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '$_streakCount ngày',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
              ],
            ),
          ),

          // XP Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt, color: Colors.amber, size: 16),
                const SizedBox(width: 2),
                Text(
                  '$_userXp XP',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),

          // Theme Toggle Button
          IconButton(
            icon: Icon(
              ThemeController.instance.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            ),
            tooltip: 'Chuyển đổi giao diện sáng/tối',
            onPressed: () {
              ThemeController.instance.toggleTheme();
            },
          ),

          // Settings Button
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Cài đặt & Sao lưu',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => SettingsDialog(onDataChanged: _loadProfileData),
              );
            },
          ),
        ],
      ),
      body: isDesktopOrTablet
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedTabIndex,
                  onDestinationSelected: (idx) => _navigateToTab(idx),
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('Tổng quan'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.search),
                      selectedIcon: Icon(Icons.search_rounded),
                      label: Text('Tra từ'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.book_outlined),
                      selectedIcon: Icon(Icons.book),
                      label: Text('Sổ từ'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.school_outlined),
                      selectedIcon: Icon(Icons.school),
                      label: Text('Ôn tập'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: pages[_selectedTabIndex]),
              ],
            )
          : pages[_selectedTabIndex],
      bottomNavigationBar: isDesktopOrTablet
          ? null
          : NavigationBar(
              selectedIndex: _selectedTabIndex,
              onDestinationSelected: (idx) => _navigateToTab(idx),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Tổng quan',
                ),
                NavigationDestination(
                  icon: Icon(Icons.search),
                  selectedIcon: Icon(Icons.search_rounded),
                  label: 'Tra từ',
                ),
                NavigationDestination(
                  icon: Icon(Icons.book_outlined),
                  selectedIcon: Icon(Icons.book),
                  label: 'Sổ từ',
                ),
                NavigationDestination(
                  icon: Icon(Icons.school_outlined),
                  selectedIcon: Icon(Icons.school),
                  label: 'Ôn tập',
                ),
              ],
            ),
    );
  }
}
