import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/user_role.dart';
import '../../../../core/network/network_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/firebase_error_mapper.dart';
import '../../../../core/widgets/responsive_container.dart';
import '../../../auth/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _user = FirebaseAuth.instance.currentUser;
  final _authService = AuthService();

  final _nameController = TextEditingController();
  bool _isEditingInfo = false;
  bool _isSavingInfo = false;
  Stream<DocumentSnapshot>? _userDocStream;

  @override
  void initState() {
    super.initState();
    if (_user != null) {
      _userDocStream = FirebaseFirestore.instance
          .collection('users')
          .doc(_user.uid)
          .snapshots();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateProfileInfo() async {
    final hasNet = await NetworkService.isConnected();
    if (!hasNet) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chưa kết nối mạng! Không thể cập nhật thông tin.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Họ và tên không được để trống!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSavingInfo = true);

    try {
      if (_user != null) {
        await _user.updateDisplayName(newName);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user.uid)
            .update({
          'fullName': newName,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        setState(() => _isEditingInfo = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật họ và tên thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật: ${FirebaseErrorMapper.getMessage(e)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingInfo = false);
    }
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.lock_reset, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Đổi Mật Khẩu'),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: currentPasswordController,
                      obscureText: obscureCurrent,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu hiện tại',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(obscureCurrent
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setDialogState(
                              () => obscureCurrent = !obscureCurrent),
                        ),
                      ),
                      validator: (val) => (val == null || val.isEmpty)
                          ? 'Vui lòng nhập mật khẩu hiện tại'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu mới',
                        prefixIcon: const Icon(Icons.key),
                        suffixIcon: IconButton(
                          icon: Icon(obscureNew
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setDialogState(
                              () => obscureNew = !obscureNew),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Vui lòng nhập mật khẩu mới';
                        }
                        if (val.length < 6) {
                          return 'Mật khẩu phải có tối thiểu 6 ký tự';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Xác nhận mật khẩu mới',
                        prefixIcon: const Icon(Icons.check_circle_outline),
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setDialogState(
                              () => obscureConfirm = !obscureConfirm),
                        ),
                      ),
                      validator: (val) {
                        if (val != newPasswordController.text) {
                          return 'Mật khẩu xác nhận không khớp!';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting
                    ? null
                    : () => Navigator.pop(dialogCtx),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => isSubmitting = true);

                        try {
                          final cred = EmailAuthProvider.credential(
                            email: _user!.email!,
                            password: currentPasswordController.text,
                          );
                          await _user.reauthenticateWithCredential(cred);
                          await _user.updatePassword(newPasswordController.text);

                          if (context.mounted) {
                            Navigator.pop(dialogCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đổi mật khẩu thành công!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(FirebaseErrorMapper.getMessage(e)),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } finally {
                          if (context.mounted) {
                            setDialogState(() => isSubmitting = false);
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Lưu Thay Đổi'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ Sơ Cá Nhân'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 600,
          child: StreamBuilder<DocumentSnapshot>(
            stream: _userDocStream,
            builder: (context, snapshot) {
              final data = snapshot.data?.data() as Map<String, dynamic>?;
              final role = UserRole.fromString(data?['role']);
              final fullName = data?['fullName'] as String? ??
                  _user?.displayName ??
                  'Chưa cập nhật';
              final email = _user?.email ?? 'Không có email';

              if (!_isEditingInfo && _nameController.text.isEmpty) {
                _nameController.text = fullName;
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Avatar & Role Badge
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: role.color,
                                width: 3,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 46,
                              backgroundColor: role.lightColor,
                              child: Icon(
                                role.icon,
                                size: 48,
                                color: role.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      fullName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Role Chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: role.lightColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: role.color.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        role.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: role.color,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Thông tin tài khoản Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Thông Tin Tài Khoản',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    _isEditingInfo ? Icons.close : Icons.edit,
                                    size: 20,
                                    color: AppColors.primary,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isEditingInfo = !_isEditingInfo;
                                      if (!_isEditingInfo) {
                                        _nameController.text = fullName;
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                            const Divider(height: 20),

                            if (_isEditingInfo) ...[
                              TextField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Họ và Tên',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: _isSavingInfo
                                      ? null
                                      : _updateProfileInfo,
                                  child: _isSavingInfo
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Lưu Họ và Tên'),
                                ),
                              ),
                            ] else ...[
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.person_outline,
                                    color: AppColors.primary),
                                title: const Text('Họ và Tên'),
                                subtitle: Text(fullName),
                              ),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.email_outlined,
                                    color: AppColors.primary),
                                title: const Text('Email Đăng Nhập'),
                                subtitle: Text(email),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Bảo mật & Thao tác Card
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.lock_outline,
                                color: AppColors.primary),
                            title: const Text('Đổi Mật Khẩu'),
                            subtitle: const Text('Cập nhật mật khẩu định kỳ'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _showChangePasswordDialog(context),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.logout,
                                color: AppColors.error),
                            title: const Text(
                              'Đăng Xuất',
                              style: TextStyle(color: AppColors.error),
                            ),
                            onTap: () async {
                              final nav = Navigator.of(context);
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Xác Nhận Đăng Xuất'),
                                  content: const Text(
                                      'Bạn có chắc chắn muốn đăng xuất khỏi hệ thống?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Hủy'),
                                    ),
                                    FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppColors.error,
                                      ),
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Đăng Xuất'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true && mounted) {
                                nav.pop(); // Đóng ProfileScreen
                                await _authService.signOut();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
