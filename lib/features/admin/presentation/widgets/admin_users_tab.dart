import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/user_role.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/responsive_container.dart';
import '../../services/admin_user_service.dart';

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  final AdminUserService _adminUserService = AdminUserService();
  final String? _currentUid = FirebaseAuth.instance.currentUser?.uid;

  String _searchQuery = '';
  UserRole? _selectedRoleFilter;
  late final Stream<QuerySnapshot> _usersStream;

  @override
  void initState() {
    super.initState();
    _usersStream = FirebaseFirestore.instance.collection('users').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _usersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('Chưa có tài khoản nào trên hệ thống.'),
          );
        }

        final allUsers = snapshot.data!.docs;
        final totalCount = allUsers.length;
        final activeCount = allUsers.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return (data['isActive'] as bool? ?? true) == true;
        }).length;
        final lockedCount = totalCount - activeCount;

        final filteredUsers = allUsers.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final email = (data['email'] as String? ?? '').toLowerCase();
          final name = (data['fullName'] as String? ?? '').toLowerCase();
          final role = UserRole.fromString(data['role'] as String?);

          final matchesSearch = _searchQuery.isEmpty ||
              email.contains(_searchQuery.toLowerCase()) ||
              name.contains(_searchQuery.toLowerCase());

          final matchesRole =
              _selectedRoleFilter == null || role == _selectedRoleFilter;

          return matchesSearch && matchesRole;
        }).toList();

        return ResponsiveContainer(
          maxWidth: 950,
          child: CustomScrollView(
            slivers: [
              // 1. Thống kê nhanh 3 chỉ số
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Tổng số',
                          count: '$totalCount',
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Hoạt động',
                          count: '$activeCount',
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Đã khóa',
                          count: '$lockedCount',
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Thanh tìm kiếm và bộ lọc Vai trò (Mỗi mục 1 dòng độc lập)
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      // Dòng 1: Ô Tìm kiếm
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Tìm theo email, họ tên...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () =>
                                      setState(() => _searchQuery = ''),
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          isDense: true,
                        ),
                        onChanged: (val) =>
                            setState(() => _searchQuery = val.trim()),
                      ),
                      const SizedBox(height: 8),

                      // Dòng 2: Ô Select Vai trò
                      DropdownButtonFormField<UserRole?>(
                        initialValue: _selectedRoleFilter,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Lọc theo vai trò',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                        ),
                        items: const [
                          DropdownMenuItem<UserRole?>(
                            value: null,
                            child: Text(
                              'Tất cả vai trò tài khoản',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                          DropdownMenuItem<UserRole?>(
                            value: UserRole.admin,
                            child: Text(
                              'Quản Trị Viên (Admin)',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                          DropdownMenuItem<UserRole?>(
                            value: UserRole.leadTeacher,
                            child: Text(
                              'Tổng Phụ Trách (Lead Teacher)',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                        onChanged: (val) =>
                            setState(() => _selectedRoleFilter = val),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Danh sách tài khoản
              if (filteredUsers.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Không tìm thấy tài khoản nào phù hợp.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final doc = filteredUsers[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final uid = doc.id;
                        final email = data['email'] as String? ?? '';
                        final fullName =
                            data['fullName'] as String? ?? 'Chưa đặt tên';
                        final role =
                            UserRole.fromString(data['role'] as String?);
                        final isActive = data['isActive'] as bool? ?? true;
                        final isSelf = uid == _currentUid;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isActive
                                  ? Colors.transparent
                                  : Colors.red.shade200,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            leading: CircleAvatar(
                              backgroundColor: isActive
                                  ? role.lightColor
                                  : Colors.grey.shade200,
                              child: Icon(
                                role.icon,
                                color: isActive
                                    ? role.color
                                    : AppColors.textMuted,
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    fullName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isActive ? null : Colors.grey,
                                      decoration: isActive
                                          ? null
                                          : TextDecoration.lineThrough,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isSelf)
                                  Container(
                                    margin: const EdgeInsets.only(left: 6),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryMint,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Bạn',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  email,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Chip(
                                      label: Text(
                                        role.label,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      backgroundColor: role.color,
                                      side: BorderSide.none,
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    if (!isActive) ...[
                                      const SizedBox(width: 6),
                                      Chip(
                                        label: const Text(
                                          'Đã khóa',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        backgroundColor: AppColors.error,
                                        side: BorderSide.none,
                                        padding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              tooltip: 'Tùy chọn',
                              onSelected: (action) {
                                switch (action) {
                                  case 'edit':
                                    _showEditUserDialog(
                                      context: context,
                                      uid: uid,
                                      currentName: fullName,
                                      currentRole: role,
                                    );
                                    break;
                                  case 'lock':
                                    if (isSelf) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Không thể tự khóa tài khoản của chính mình!'),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                      return;
                                    }
                                    _confirmToggleLock(
                                      context: context,
                                      uid: uid,
                                      email: email,
                                      currentStatus: isActive,
                                    );
                                    break;
                                  case 'delete':
                                    if (isSelf) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Không thể xóa tài khoản của chính mình!'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }
                                    _confirmDeleteUser(
                                      context: context,
                                      uid: uid,
                                      email: email,
                                    );
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined, size: 20),
                                      SizedBox(width: 10),
                                      Text('Chỉnh sửa'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'lock',
                                  child: Row(
                                    children: [
                                      Icon(
                                        isActive
                                            ? Icons.lock_outline
                                            : Icons.lock_open_outlined,
                                        size: 20,
                                        color: isActive
                                            ? Colors.orange.shade800
                                            : Colors.green,
                                      ),
                                      SizedBox(width: 10),
                                      Text(isActive
                                          ? 'Khóa tài khoản'
                                          : 'Mở khóa tài khoản'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline,
                                          size: 20, color: Colors.red),
                                      SizedBox(width: 10),
                                      Text('Xóa tài khoản',
                                          style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: filteredUsers.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog({
    required BuildContext context,
    required String uid,
    required String currentName,
    required UserRole currentRole,
  }) {
    final nameCtrl = TextEditingController(text: currentName);
    UserRole selectedRole = currentRole;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Chỉnh Sửa Tài Khoản'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Họ và Tên',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<UserRole>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Vai trò trong hệ thống',
                      prefixIcon: Icon(Icons.shield_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: UserRole.leadTeacher,
                        child: Text('Tổng Phụ Trách'),
                      ),
                      DropdownMenuItem(
                        value: UserRole.admin,
                        child: Text('Quản Trị Viên'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedRole = val);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;

                        setDialogState(() => isSaving = true);
                        try {
                          await _adminUserService.updateUser(
                            uid: uid,
                            fullName: name,
                            role: selectedRole,
                          );
                          if (context.mounted) {
                            Navigator.pop(dialogCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã cập nhật thông tin tài khoản!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Lỗi: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        } finally {
                          if (context.mounted) {
                            setDialogState(() => isSaving = false);
                          }
                        }
                      },
                child: const Text('Lưu Thay Đổi'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmToggleLock({
    required BuildContext context,
    required String uid,
    required String email,
    required bool currentStatus,
  }) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(currentStatus ? 'Khóa Tài Khoản?' : 'Mở Khóa Tài Khoản?'),
        content: Text(
          currentStatus
              ? 'Tài khoản $email sẽ không thể đăng nhập vào hệ thống cho đến khi được mở khóa lại.'
              : 'Tài khoản $email sẽ có thể đăng nhập lại vào hệ thống bình thường.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor:
                  currentStatus ? AppColors.error : AppColors.success,
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await _adminUserService.toggleUserLock(
                  uid: uid,
                  currentIsActive: currentStatus,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(currentStatus
                          ? 'Đã khóa tài khoản $email'
                          : 'Đã mở khóa tài khoản $email'),
                      backgroundColor:
                          currentStatus ? AppColors.error : AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: Text(currentStatus ? 'Khóa' : 'Mở Khóa'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteUser({
    required BuildContext context,
    required String uid,
    required String email,
  }) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Xác Nhận Xóa Tài Khoản'),
        content: Text(
          'Bạn có chắc chắn muốn xóa tài khoản $email khỏi hệ thống? Thao tác này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await _adminUserService.deleteUser(uid);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã xóa tài khoản $email'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Xóa Tài Khoản'),
          ),
        ],
      ),
    );
  }
}
