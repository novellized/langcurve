import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/theme_controller.dart';
import '../../auth/services/auth_service.dart';
import '../services/backup_service.dart';
import '../services/cloud_sync_service.dart';

class SettingsView extends StatefulWidget {
  final VoidCallback? onDataChanged;
  final AuthService? authService;
  final CloudSyncService? cloudSyncService;

  const SettingsView({
    super.key,
    this.onDataChanged,
    this.authService,
    this.cloudSyncService,
  });

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final BackupService _backupService = BackupService();
  final ThemeController _themeController = ThemeController.instance;
  late final AuthService _authService;
  late final CloudSyncService _cloudSyncService;
  bool _isCloudBusy = false;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService.instance;
    _cloudSyncService =
        widget.cloudSyncService ?? CloudSyncService(authService: _authService);
    _authService.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _exportBackup() async {
    try {
      final jsonStr = await _backupService.exportBackupJson();
      await Clipboard.setData(ClipboardData(text: jsonStr));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã sao chép chuỗi JSON sao lưu vào Clipboard!'),
          ),
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

  Future<void> _handleGoogleSignIn() async {
    try {
      final account = await _authService.signInWithGoogle();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã đăng nhập với ${account.email}'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  Future<void> _handleCloudUpload() async {
    setState(() => _isCloudBusy = true);
    try {
      await _cloudSyncService.syncToCloud();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã sao lưu dữ liệu lên Cloud Firestore thành công!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi đồng bộ lên Cloud: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCloudBusy = false);
      }
    }
  }

  Future<void> _handleCloudRestore() async {
    setState(() => _isCloudBusy = true);
    try {
      await _cloudSyncService.restoreFromCloud();
      if (widget.onDataChanged != null) widget.onDataChanged!();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã khôi phục dữ liệu từ Cloud Firestore thành công!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khôi phục từ Cloud: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCloudBusy = false);
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
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
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
                    const SnackBar(
                      content: Text('Phục hồi dữ liệu thành công!'),
                    ),
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
    final user = _authService.currentUser;
    final isSignedIn = !user.isGuest;

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
                  const Text(
                    'Giao diện (Theme)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      _themeController.isDarkMode
                          ? Icons.dark_mode
                          : Icons.light_mode,
                    ),
                    title: Text(
                      _themeController.isDarkMode
                          ? 'Chế độ Tối (Dark Mode)'
                          : 'Chế độ Sáng (Light Mode)',
                    ),
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

          // Google Account & Cloud Firestore Sync Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.cloud_sync_outlined, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Tài khoản Google & Cloud Firestore',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isSignedIn
                        ? 'Đang đăng nhập: ${user.displayName} (${user.email})'
                        : 'Đăng nhập bằng Google để đồng bộ từ vựng, chuỗi học (Streak) và điểm XP trên mọi thiết bị.',
                    style: TextStyle(fontSize: 12, color: colorScheme.outline),
                  ),
                  const SizedBox(height: 14),
                  if (!isSignedIn)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: const Key('btn_settings_google_sign_in'),
                        icon: const Icon(Icons.login, size: 18),
                        label: const Text('Đăng nhập bằng Google'),
                        onPressed:
                            _authService.isBusy ? null : _handleGoogleSignIn,
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonalIcon(
                            key: const Key('btn_cloud_upload'),
                            icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                            label: const Text('Sao lưu lên Cloud'),
                            onPressed: _isCloudBusy ? null : _handleCloudUpload,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key('btn_cloud_restore'),
                            icon: const Icon(Icons.cloud_download_outlined, size: 18),
                            label: const Text('Tải từ Cloud'),
                            onPressed: _isCloudBusy ? null : _handleCloudRestore,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Backup & Restore JSON Card (Offline)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sao lưu & Phục hồi Ngoại tuyến (JSON)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Xuất dữ liệu từ vựng ra mã JSON hoặc phục hồi sổ từ vựng từ tệp sao lưu thủ công.',
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
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
