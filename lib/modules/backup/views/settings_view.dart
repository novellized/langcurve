import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/theme_controller.dart';
import '../services/backup_service.dart';

class SettingsView extends StatefulWidget {
  final VoidCallback? onDataChanged;

  const SettingsView({super.key, this.onDataChanged});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final BackupService _backupService = BackupService();
  final ThemeController _themeController = ThemeController.instance;

  void _exportBackup() async {
    try {
      final jsonStr = await _backupService.exportBackupJson();
      await Clipboard.setData(ClipboardData(text: jsonStr));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã sao chép chuỗi JSON sao lưu vào Clipboard!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi sao lưu: $e')),
        );
      }
    }
  }

  void _showImportDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Phục hồi dữ liệu từ JSON'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dán nội dung JSON sao lưu vào ô bên dưới. Dữ liệu sẽ được hợp nhất vào cơ sở dữ liệu hiện tại:',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: textController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: '{\n  "version": "1.0",\n  "topics": [...]\n}',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () async {
              final text = textController.text.trim();
              if (text.isEmpty) return;
              try {
                await _backupService.importBackupJson(text);
                if (ctx.mounted) Navigator.pop(ctx);
                if (widget.onDataChanged != null) widget.onDataChanged!();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Phục hồi dữ liệu thành công!')),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Lỗi nhập dữ liệu: $e')),
                  );
                }
              }
            },
            child: const Text('Nhập dữ liệu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cài đặt & Dữ liệu',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),

          // Theme Settings Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Giao diện (Theme)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(_themeController.isDarkMode ? Icons.dark_mode : Icons.light_mode),
                    title: Text(_themeController.isDarkMode ? 'Chế độ Tối (Dark Mode)' : 'Chế độ Sáng (Light Mode)'),
                    trailing: Switch(
                      value: _themeController.isDarkMode,
                      onChanged: (_) {
                        setState(() {
                          _themeController.toggleTheme();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Backup & Restore Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sao lưu & Phục hồi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(
                    'Xuất dữ liệu từ vựng ra mã JSON hoặc phục hồi sổ từ vựng từ tệp sao lưu.',
                    style: TextStyle(fontSize: 12, color: colorScheme.outline),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text('Xuất JSON'),
                          onPressed: _exportBackup,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.upload, size: 18),
                          label: const Text('Nhập JSON'),
                          onPressed: _showImportDialog,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // About Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ứng dụng LangCurve v1.0.0',
                    style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Nền tảng học từ vựng tiếng Anh theo Đường cong lặp lại ngắt quãng SM-2 (SuperMemo) với phân tích CEFR và phát âm chuẩn.',
                    style: TextStyle(fontSize: 12, color: colorScheme.outline),
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
