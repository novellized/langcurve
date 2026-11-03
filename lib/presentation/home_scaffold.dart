import 'package:flutter/material.dart';
import '../modules/dashboard/views/dashboard_view.dart';
import '../modules/dictionary/views/dictionary_view.dart';
import '../modules/notebook/views/notebook_view.dart';
import '../modules/practice/views/practice_view.dart';
import '../modules/profile/views/profile_view.dart';
import '../modules/backup/views/settings_view.dart';
import '../modules/notebook/repositories/notebook_repository.dart';

class AdaptiveHomeScaffold extends StatefulWidget {
  const AdaptiveHomeScaffold({super.key});

  @override
  State<AdaptiveHomeScaffold> createState() => _AdaptiveHomeScaffoldState();
}

class _AdaptiveHomeScaffoldState extends State<AdaptiveHomeScaffold> {
  int _selectedTabIndex = 0;
  int? _practiceTopicId;
  final NotebookRepository _notebookRepo = NotebookRepository();

  void _navigateToTab(int index, {int? topicId}) {
    setState(() {
      _selectedTabIndex = index;
      if (index == 3 && topicId != null) {
        _practiceTopicId = topicId;
      }
    });
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
      ProfileView(onNavigate: _navigateToTab),
      SettingsView(onDataChanged: () => setState(() {})),
    ];

    return Scaffold(
      appBar: null, // Removed top AppBar per user specification
      body: SafeArea(
        child: isDesktopOrTablet
            ? Row(
                children: [
                  NavigationRail(
                    selectedIndex: _selectedTabIndex,
                    onDestinationSelected: (idx) => _navigateToTab(idx),
                    labelType: NavigationRailLabelType.none, // Hide labels
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.grid_view_outlined),
                        selectedIcon: Icon(Icons.grid_view_rounded),
                        label: Text(''),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.search_outlined),
                        selectedIcon: Icon(Icons.search_rounded),
                        label: Text(''),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.auto_stories_outlined),
                        selectedIcon: Icon(Icons.auto_stories_rounded),
                        label: Text(''),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.school_outlined),
                        selectedIcon: Icon(Icons.school_rounded),
                        label: Text(''),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.person_outlined),
                        selectedIcon: Icon(Icons.person_rounded),
                        label: Text(''),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.settings_outlined),
                        selectedIcon: Icon(Icons.settings_rounded),
                        label: Text(''),
                      ),
                    ],
                  ),
                  const VerticalDivider(thickness: 1, width: 1),
                  Expanded(child: pages[_selectedTabIndex]),
                ],
              )
            : pages[_selectedTabIndex],
      ),
      bottomNavigationBar: isDesktopOrTablet
          ? null
          : Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: NavigationBar(
                  selectedIndex: _selectedTabIndex,
                  onDestinationSelected: (idx) => _navigateToTab(idx),
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysHide, // Hide labels
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.grid_view_outlined),
                      selectedIcon: Icon(Icons.grid_view_rounded),
                      label: '',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.search_outlined),
                      selectedIcon: Icon(Icons.search_rounded),
                      label: '',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.auto_stories_outlined),
                      selectedIcon: Icon(Icons.auto_stories_rounded),
                      label: '',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.school_outlined),
                      selectedIcon: Icon(Icons.school_rounded),
                      label: '',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outlined),
                      selectedIcon: Icon(Icons.person_rounded),
                      label: '',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings_rounded),
                      label: '',
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
