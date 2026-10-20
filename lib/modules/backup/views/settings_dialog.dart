import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/theme_controller.dart';
import '../services/backup_service.dart';

class SettingsDialog extends StatefulWidget {
  final VoidCallback? onDataChanged;

  const SettingsDialog({super.key, this.onDataChanged});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
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

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.settings, color: colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Cài đặt & Dữ liệu'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Giao diện (Theme):', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(_themeController.isDarkMode ? Icons.dark_mode : Icons.light_mode),
              title: Text(_themeController.isDarkMode ? 'Chế độ Tối (Dark)' : 'Chế độ Sáng (Light)'),
              trailing: Switch(
                value: _themeController.isDarkMode,
                onChanged: (_) {
                  setState(() {
                    _themeController.toggleTheme();
                  });
                },
              ),
            ),
            const Divider(height: 24),
            const Text('Sao lưu & Phục hồi:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Xuất JSON'),
                    onPressed: _exportBackup,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.upload, size: 18),
                    label: const Text('Nhập JSON'),
                    onPressed: _showImportDialog,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              'LangCurve v1.0.0\nNền tảng học từ vựng tiếng Anh theo Đường cong lặp lại ngắt quãng SM-2.',
              style: TextStyle(fontSize: 11, color: colorScheme.outline),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}
