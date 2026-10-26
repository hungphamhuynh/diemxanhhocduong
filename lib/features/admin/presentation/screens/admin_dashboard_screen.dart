import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/user_role.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/responsive_container.dart';
import '../../../auth/services/auth_service.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../models/system_config_model.dart';
import '../../services/admin_class_service.dart';
import '../../services/admin_user_service.dart';
import '../../services/score_criteria_service.dart';
import '../../services/system_config_service.dart';
import '../widgets/admin_classes_tab.dart';
import '../widgets/admin_criteria_tab.dart';
import '../widgets/admin_users_tab.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AuthService _authService = AuthService();
  final SystemConfigService _configService = SystemConfigService();
  final AdminUserService _adminUserService = AdminUserService();
  final AdminClassService _adminClassService = AdminClassService();
  final ScoreCriteriaService _criteriaService = ScoreCriteriaService();

  int _currentTabIndex = 0;

  late final Stream<QuerySnapshot> _usersCountStream;
  late final Stream<QuerySnapshot> _classesCountStream;
  late final Stream<QuerySnapshot> _criteriaCountStream;

  @override
  void initState() {
    super.initState();
    _usersCountStream =
        FirebaseFirestore.instance.collection('users').snapshots();
    _classesCountStream =
        FirebaseFirestore.instance.collection('classes').snapshots();
    _criteriaCountStream =
        FirebaseFirestore.instance.collection('score_criteria').snapshots();
  }

  String get _appBarTitle {
    switch (_currentTabIndex) {
      case 1:
        return 'Quản Lý Tài Khoản';
      case 2:
        return 'Quản Lý Lớp Học';
      case 3:
        return 'Tiêu Chí Hành Động Xanh';
      case 0:
      default:
        return 'Tổng Quan Hệ Thống';
    }
  }

  Widget? _buildFloatingActionButton(BuildContext context) {
    if (_currentTabIndex == 1) {
      return FloatingActionButton.extended(
        onPressed: () => _showAddUserDialog(context),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Thêm Tài Khoản'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      );
    } else if (_currentTabIndex == 2) {
      return FloatingActionButton.extended(
        onPressed: () => _showAddClassDialog(context),
        icon: const Icon(Icons.add_home_work_rounded),
        label: const Text('Thêm Lớp Mới'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      );
    } else if (_currentTabIndex == 3) {
      return FloatingActionButton.extended(
        onPressed: () => _showAddCriteriaDialog(context),
        icon: const Icon(Icons.add_circle_outline_rounded),
        label: const Text('Thêm Tiêu Chí'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SystemConfigModel>(
      stream: _configService.getConfigStream(),
      builder: (context, configSnap) {
        final config = configSnap.data ??
            const SystemConfigModel(
              baseScore: 100,
              academicYear: '2026-2027',
            );

        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Text(
              _appBarTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.account_circle_outlined),
                tooltip: 'Hồ sơ cá nhân',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Đăng xuất',
                onPressed: () => _authService.signOut(),
              ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentTabIndex,
            onDestinationSelected: (index) =>
                setState(() => _currentTabIndex = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: 'Tổng Quan',
              ),
              NavigationDestination(
                icon: Icon(Icons.manage_accounts_outlined),
                selectedIcon: Icon(Icons.manage_accounts_rounded),
                label: 'Tài Khoản',
              ),
              NavigationDestination(
                icon: Icon(Icons.school_outlined),
                selectedIcon: Icon(Icons.school_rounded),
                label: 'Lớp Học',
              ),
              NavigationDestination(
                icon: Icon(Icons.rule_outlined),
                selectedIcon: Icon(Icons.rule_folder_rounded),
                label: 'Tiêu Chí',
              ),
            ],
          ),
          floatingActionButton: _buildFloatingActionButton(context),
          body: ResponsiveContainer(
            maxWidth: 950,
            child: _buildCurrentTabBody(context, config),
          ),
        );
      },
    );
  }

  Widget _buildCurrentTabBody(BuildContext context, SystemConfigModel config) {
    switch (_currentTabIndex) {
      case 0:
        return _buildOverviewTab(context, config);
      case 1:
        return const AdminUsersTab();
      case 2:
        return const AdminClassesTab();
      case 3:
        return const AdminCriteriaTab();
      default:
        return _buildOverviewTab(context, config);
    }
  }

  Widget _buildOverviewTab(BuildContext context, SystemConfigModel config) {
    final user = FirebaseAuth.instance.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Chào mừng phong cách Gradient chuẩn THCS Nguyễn Thị Hương
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BẢNG ĐIỀU HÀNH TRUNG TÂM',
                  style: TextStyle(
                    color: AppColors.primaryContainer,
                    letterSpacing: 1.2,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user?.email ?? 'Quản Trị Viên',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Hệ thống Chấm điểm Thi đua & Hành Động Xanh - THCS Nguyễn Thị Hương',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Danh sách các phân hệ quản lý
          const Text(
            'Phân Hệ Quản Trị',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Module 1: Quản lý tài khoản
          StreamBuilder<QuerySnapshot>(
            stream: _usersCountStream,
            builder: (context, snapshot) {
              final count = snapshot.data?.docs.length ?? 0;
              return _buildModuleCard(
                icon: Icons.manage_accounts_rounded,
                title: 'Quản Lý Tài Khoản',
                description:
                    'Cấp phát, phân quyền Quản Trị Viên & Tổng Phụ Trách',
                badgeText: '$count tài khoản',
                badgeColor: AppColors.primary,
                onTap: () => setState(() => _currentTabIndex = 1),
              );
            },
          ),
          const SizedBox(height: 12),

          // Module 2: Quản lý lớp học
          StreamBuilder<QuerySnapshot>(
            stream: _classesCountStream,
            builder: (context, snapshot) {
              final classCount = snapshot.data?.docs.length ?? 0;
              return _buildModuleCard(
                icon: Icons.school_rounded,
                title: 'Quản Lý Lớp Học',
                description: 'Danh sách 36 lớp học chi đội (Khối 6 -> Khối 9)',
                badgeText: '$classCount lớp học',
                badgeColor: AppColors.secondary,
                onTap: () => setState(() => _currentTabIndex = 2),
              );
            },
          ),
          const SizedBox(height: 12),

          // Module 3: Tiêu chí điểm Hành Động Xanh
          StreamBuilder<QuerySnapshot>(
            stream: _criteriaCountStream,
            builder: (context, snapshot) {
              final criteriaCount = snapshot.data?.docs.length ?? 0;
              return _buildModuleCard(
                icon: Icons.rule_folder_rounded,
                title: 'Tiêu Chí Hành Động Xanh',
                description:
                    'Danh mục hành động cộng điểm xanh và các lỗi trừ điểm',
                badgeText: '$criteriaCount tiêu chí',
                badgeColor: AppColors.roleLeadTeacher,
                onTap: () => setState(() => _currentTabIndex = 3),
              );
            },
          ),
          const SizedBox(height: 12),

          // Module 4: Cấu hình hệ thống (Điểm gốc & Năm học)
          _buildModuleCard(
            icon: Icons.tune_rounded,
            title: 'Cấu Hình Hệ Thống',
            description:
                'Điểm gốc xuất phát: ${config.baseScore}đ • Năm học: ${config.academicYear}',
            badgeText: '${config.baseScore} điểm gốc',
            badgeColor: const Color(0xFFC2410C),
            onTap: () => _showConfigSystemDialog(context, config),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard({
    required IconData icon,
    required String title,
    required String description,
    required String badgeText,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: badgeColor.withValues(alpha: 0.12),
                child: Icon(icon, color: badgeColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(
                            badgeText,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: badgeColor,
                          side: BorderSide.none,
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HỘP THOẠI CẤU HÌNH ĐIỂM GỐC & NĂM HỌC
  // ---------------------------------------------------------------------------
  void _showConfigSystemDialog(BuildContext context, SystemConfigModel config) {
    final scoreCtrl = TextEditingController(text: config.baseScore.toString());
    final yearCtrl = TextEditingController(text: config.academicYear);
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.tune_rounded, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Cấu Hình Hệ Thống'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Điểm xuất phát ban đầu của các lớp học trong mỗi kỳ thi đua:',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: scoreCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Điểm gốc chuẩn',
                      hintText: 'Ví dụ: 100 hoặc 120...',
                      prefixIcon: Icon(Icons.stars_rounded),
                      suffixText: 'điểm',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: yearCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Năm học hiện hành',
                      hintText: '2026-2027',
                      prefixIcon: Icon(Icons.calendar_today_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '💡 Công thức tính: Điểm Tổng = Điểm Gốc + Điểm Cộng - Điểm Trừ',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppColors.primary,
                    ),
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
                        final val = int.tryParse(scoreCtrl.text.trim()) ?? 0;
                        final year = yearCtrl.text.trim();
                        if (val <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Điểm gốc phải lớn hơn 0!'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }
                        if (year.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vui lòng nhập năm học!'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }

                        setDialogState(() => isSaving = true);
                        try {
                          await _configService.updateBaseScore(val);
                          await _configService.updateAcademicYear(year);
                          if (context.mounted) {
                            Navigator.pop(dialogCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã cập nhật cấu hình hệ thống!'),
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
                child: isSaving
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

  // ---------------------------------------------------------------------------
  // HỘP THOẠI THÊM TÀI KHOẢN MỚI
  // ---------------------------------------------------------------------------
  void _showAddUserDialog(BuildContext context) {
    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    UserRole selectedRole = UserRole.leadTeacher;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.person_add_rounded, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Thêm Tài Khoản'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Họ và Tên',
                      hintText: 'Ví dụ: Thầy Nguyễn Văn A',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Địa chỉ Email',
                      hintText: 'tpt@${AppConstants.schoolDomain}',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu khởi tạo',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<UserRole>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Vai trò trong hệ thống',
                      prefixIcon: Icon(Icons.shield_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: UserRole.leadTeacher,
                        child: Text('Tổng Phụ Trách (Chấm điểm & Thống kê)'),
                      ),
                      DropdownMenuItem(
                        value: UserRole.admin,
                        child: Text('Quản Trị Viên (Toàn quyền hệ thống)'),
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
                        final email = emailCtrl.text.trim();
                        final name = nameCtrl.text.trim();
                        final pass = passCtrl.text.trim();

                        if (email.isEmpty || name.isEmpty || pass.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vui lòng điền đầy đủ thông tin!'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }
                        if (pass.length < 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Mật khẩu tối thiểu 6 ký tự!'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }

                        setDialogState(() => isSaving = true);
                        try {
                          await _adminUserService.createUser(
                            email: email,
                            password: pass,
                            fullName: name,
                            role: selectedRole,
                          );
                          if (context.mounted) {
                            Navigator.pop(dialogCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã tạo tài khoản thành công!'),
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
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Tạo Tài Khoản'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HỘP THOẠI THÊM LỚP MỚI (CHUẨN HÓA: KHỐI + A + SỐ LỚP - KHÔNG CHO NHẬP TỰ DO)
  // ---------------------------------------------------------------------------
  void _showAddClassDialog(BuildContext context) {
    int selectedGrade = 6;
    int selectedClassNum = 1;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final className = '${selectedGrade}A$selectedClassNum';

          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            title: const Text(
              'Thêm Lớp Học Mới',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Cú pháp lớp: Khối + A + Số lớp',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Bộ chọn chuẩn hóa: Khối + 'A' + Số lớp (Không cho nhập tự do)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Chọn Khối (6, 7, 8, 9)
                      Expanded(
                        flex: 5,
                        child: DropdownButtonFormField<int>(
                          isExpanded: true,
                          initialValue: selectedGrade,
                          decoration: const InputDecoration(
                            isDense: true,
                            labelText: 'Khối',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                          ),
                          items: [6, 7, 8, 9].map((g) {
                            return DropdownMenuItem<int>(
                              value: g,
                              child: Text(
                                'Khối $g',
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => selectedGrade = val);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Ký tự cố định 'A'
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          'A',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Chọn Số thứ tự lớp (1 -> 20)
                      Expanded(
                        flex: 5,
                        child: DropdownButtonFormField<int>(
                          isExpanded: true,
                          initialValue: selectedClassNum,
                          decoration: const InputDecoration(
                            isDense: true,
                            labelText: 'Số lớp',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                          ),
                          items: List.generate(20, (i) => i + 1).map((n) {
                            return DropdownMenuItem<int>(
                              value: n,
                              child: Text(
                                'Lớp $n',
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => selectedClassNum = val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Khung xem trước thông tin lớp học chuẩn hóa
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lớp sẽ tạo: $className',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const Divider(height: 16),
                        Text(
                          '• Phân loại: Khối $selectedGrade',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '• Trạng thái ban đầu: Đang hoạt động',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
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
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        setDialogState(() => isSaving = true);
                        try {
                          await _adminClassService.createClass(
                            className: className,
                            grade: selectedGrade,
                          );
                          if (context.mounted) {
                            Navigator.pop(dialogCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Đã thêm lớp $className thành công!'),
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
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Tạo Lớp'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HỘP THOẠI THÊM TIÊU CHÍ MỚI
  // ---------------------------------------------------------------------------
  void _showAddCriteriaDialog(BuildContext context) {
    int typeIndex = 0; // 0 = Cộng điểm, 1 = Trừ điểm
    final titleCtrl = TextEditingController();
    final pointsCtrl = TextEditingController(text: '5');
    final descCtrl = TextEditingController();
    String iconName = 'plant';
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isPlus = typeIndex == 0;

          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  isPlus
                      ? Icons.add_circle_outline_rounded
                      : Icons.remove_circle_outline_rounded,
                  color: isPlus ? AppColors.plusColor : AppColors.minusColor,
                ),
                const SizedBox(width: 8),
                Text(isPlus ? 'Thêm Tiêu Chí Cộng Điểm' : 'Thêm Tiêu Chí Trừ Điểm'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Chọn loại điểm
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setDialogState(() {
                                typeIndex = 0;
                                iconName = 'plant';
                                pointsCtrl.text = '5';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isPlus
                                    ? AppColors.plusColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  'Cộng Điểm',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isPlus ? Colors.white : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setDialogState(() {
                                typeIndex = 1;
                                iconName = 'fan';
                                pointsCtrl.text = '3';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: !isPlus
                                    ? AppColors.minusColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  'Trừ Điểm',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: !isPlus ? Colors.white : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: isPlus
                          ? 'Tên hành động xanh'
                          : 'Tên lỗi vi phạm',
                      prefixIcon: const Icon(Icons.title_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: pointsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: isPlus ? 'Số điểm cộng' : 'Số điểm trừ',
                      prefixIcon: Icon(
                        isPlus ? Icons.add : Icons.remove,
                        color: isPlus ? AppColors.plusColor : AppColors.minusColor,
                      ),
                      suffixText: 'điểm',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả / Hướng dẫn ghi nhận',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Biểu tượng:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: isPlus
                        ? [
                            _buildDialogIconChoice('plant', Icons.yard_rounded, iconName, (v) => setDialogState(() => iconName = v)),
                            _buildDialogIconChoice('clean', Icons.cleaning_services_rounded, iconName, (v) => setDialogState(() => iconName = v)),
                            _buildDialogIconChoice('light', Icons.lightbulb_rounded, iconName, (v) => setDialogState(() => iconName = v)),
                            _buildDialogIconChoice('eco', Icons.eco_rounded, iconName, (v) => setDialogState(() => iconName = v)),
                            _buildDialogIconChoice('award', Icons.emoji_events_rounded, iconName, (v) => setDialogState(() => iconName = v)),
                          ]
                        : [
                            _buildDialogIconChoice('fan', Icons.mode_fan_off_rounded, iconName, (v) => setDialogState(() => iconName = v)),
                            _buildDialogIconChoice('trash', Icons.delete_outline_rounded, iconName, (v) => setDialogState(() => iconName = v)),
                            _buildDialogIconChoice('light', Icons.lightbulb_outline_rounded, iconName, (v) => setDialogState(() => iconName = v)),
                            _buildDialogIconChoice('warning', Icons.warning_amber_rounded, iconName, (v) => setDialogState(() => iconName = v)),
                          ],
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
                style: FilledButton.styleFrom(
                  backgroundColor: isPlus ? AppColors.plusColor : AppColors.minusColor,
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        final title = titleCtrl.text.trim();
                        final pts = int.tryParse(pointsCtrl.text.trim()) ?? 0;
                        if (title.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vui lòng nhập tên tiêu chí!'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }
                        if (pts <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Số điểm phải lớn hơn 0!'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }

                        setDialogState(() => isSaving = true);
                        try {
                          await _criteriaService.createCriteria(
                            type: isPlus ? 'plus' : 'minus',
                            title: title,
                            points: pts,
                            description: descCtrl.text.trim(),
                            iconName: iconName,
                          );
                          if (context.mounted) {
                            Navigator.pop(dialogCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã thêm tiêu chí thành công!'),
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
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Lưu Tiêu Chí'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDialogIconChoice(
    String id,
    IconData icon,
    String currentSelected,
    Function(String) onSelect,
  ) {
    final isSelected = id == currentSelected;
    return InkWell(
      onTap: () => onSelect(id),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryMint : Colors.grey.shade100,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 22,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
    );
  }
}
