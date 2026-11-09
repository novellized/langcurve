import 'package:flutter/material.dart';
import 'core/database/database_helper.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'modules/auth/services/auth_service.dart';
import 'presentation/home_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize SQLite / Web Storage database
    await DatabaseHelper.instance.database;

    // Initialize Firebase & Local Auth state (offline-first safe)
    await AuthService.instance.initialize();
  } catch (e) {
    debugPrint('Startup initialization warning: $e');
  }

  runApp(const LangCurveApp());
}

class LangCurveApp extends StatelessWidget {
  const LangCurveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'LangCurve',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeController.instance.themeMode,
          home: const AdaptiveHomeScaffold(),
        );
      },
    );
  }
}
