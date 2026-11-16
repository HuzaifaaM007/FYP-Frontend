import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/config/env.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/theme_controller.dart';
import '../../settings/screens/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  String? _error;
  String? _avatarUrl; // absolute URL, with a version query so a new picture is not cached
  bool _avatarBusy = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ApiClient().dio.get('/auth/me');
      _user = response.data as Map<String, dynamic>;
      await _loadAvatar();
    } catch (_) {
      _error = 'Could not load your profile.';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAvatar() async {
    try {
      final response = await ApiClient().dio.get('/me/avatar');
      final path = response.data['avatar_url'] as String?;
      _avatarUrl = path == null ? null : '${Env.apiBaseUrl}$path';
    } catch (_) {
      // Older backend: just show initials.
    }
  }

  Future<void> _changePicture() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            if (_avatarUrl != null)
              ListTile(
                leading: Icon(Icons.delete_outline, color: AppColors.error),
                title: Text('Remove picture', style: TextStyle(color: AppColors.error)),
                onTap: () => Navigator.pop(ctx, 'remove'),
              ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;

    setState(() => _avatarBusy = true);
    try {
      if (choice == 'remove') {
        await ApiClient().dio.delete('/me/avatar');
        _avatarUrl = null;
      } else {
        final picked = await ImagePicker().pickImage(
          source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );
        if (picked == null) return;
        final form = FormData.fromMap({
          'file': await MultipartFile.fromFile(picked.path, filename: 'avatar.jpg'),
        });
        final response = await ApiClient().dio.post('/me/avatar', data: form);
        _avatarUrl = '${Env.apiBaseUrl}${response.data['avatar_url']}';
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not update your picture.')));
      }
    } finally {
      if (mounted) setState(() => _avatarBusy = false);
    }
  }

  void _showChangePasswordSheet() {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    String? sheetError;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Change Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              AppTextField(hint: 'Current password', controller: currentController, obscureText: true),
              const SizedBox(height: 10),
              AppTextField(hint: 'New password', controller: newController, obscureText: true),
              if (sheetError != null) ...[
                const SizedBox(height: 10),
                Text(sheetError!, style: TextStyle(color: AppColors.error, fontSize: 13)),
              ],
              const SizedBox(height: 16),
              AppButton(
                label: 'Update Password',
                isLoading: isSubmitting,
                onPressed: () async {
                  if (currentController.text.isEmpty || newController.text.length < 8) {
                    setSheetState(() => sheetError = 'New password must be at least 8 characters.');
                    return;
                  }
                  setSheetState(() {
                    isSubmitting = true;
                    sheetError = null;
                  });
                  try {
                    await ApiClient().dio.post('/auth/change-password', data: {
                      'current_password': currentController.text,
                      'new_password': newController.text,
                    });
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(content: Text('Password updated.')),
                      );
                    }
                  } catch (_) {
                    setSheetState(() {
                      sheetError = 'Current password is incorrect.';
                      isSubmitting = false;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    // Signing out resets the whole app (see main.dart), so no navigation is needed here.
    await context.read<AuthProvider>().logout();
  }

  Future<void> _confirmDeleteAccount() async {
    final passwordController = TextEditingController();
    String? error;
    bool deleting = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Delete account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This permanently deletes your account, uploaded lectures, quizzes, planner and notifications. '
                'It cannot be undone.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 14),
              AppTextField(hint: 'Enter your password to confirm', controller: passwordController, obscureText: true),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: TextStyle(color: AppColors.error, fontSize: 13)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: deleting ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: deleting
                  ? null
                  : () async {
                      if (passwordController.text.isEmpty) {
                        setDialogState(() => error = 'Enter your password.');
                        return;
                      }
                      setDialogState(() {
                        deleting = true;
                        error = null;
                      });
                      final failure = await context.read<AuthProvider>().deleteAccount(passwordController.text);
                      if (failure != null) {
                        setDialogState(() {
                          deleting = false;
                          error = failure;
                        });
                      }
                      // On success the app resets itself and this dialog disappears with it.
                    },
              child: Text(deleting ? 'Deleting...' : 'Delete forever', style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      ),
    );
    passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const LoadingView();
    if (_error != null) return ErrorView(message: _error!, onRetry: _loadProfile);

    final user = _user!;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: GestureDetector(
            onTap: _avatarBusy ? null : _changePicture,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.surfaceElevated,
                  backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                  child: _avatarBusy
                      ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5))
                      : _avatarUrl == null
                          ? Text(
                              (user['full_name'] as String? ?? user['email'] as String).substring(0, 1).toUpperCase(),
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                            )
                          : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 2),
                    ),
                    child: Icon(Icons.edit, size: 14, color: AppColors.onPrimary),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(child: Text('Tap the picture to change it', style: TextStyle(color: AppColors.textSecondary, fontSize: 11))),
        const SizedBox(height: 16),
        Center(
          child: Text(
            user['full_name'] as String? ?? 'Student',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Center(
          child: Text(user['email'] as String, style: TextStyle(color: AppColors.textSecondary)),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
          child: Column(
            children: [
              _InfoRow(label: 'Role', value: (user['role'] as String).toUpperCase()),
              Divider(color: AppColors.border),
              _InfoRow(label: 'Status', value: (user['is_active'] as bool) ? 'Active' : 'Inactive'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: Icon(Icons.palette_outlined, color: AppColors.accentPurple),
            title: const Text('Appearance'),
            subtitle: Text('Theme: ${ThemeController.instance.palette.name}', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary),
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              if (mounted) setState(() {}); // refresh the "Theme: ..." line
            },
          ),
        ),
        const SizedBox(height: 24),
        AppButton(label: 'Change Password', outlined: true, onPressed: _showChangePasswordSheet),
        const SizedBox(height: 12),
        AppButton(label: 'Log Out', onPressed: _handleLogout),
        const SizedBox(height: 28),
        Divider(color: AppColors.border),
        TextButton(
          onPressed: _confirmDeleteAccount,
          child: Text('Delete my account', style: TextStyle(color: AppColors.error)),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}