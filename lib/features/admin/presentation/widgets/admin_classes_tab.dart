import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/string_utils.dart';
import '../../../../core/widgets/responsive_container.dart';
import '../../models/school_class_model.dart';
import '../../services/admin_class_service.dart';
import '../../../lead_teacher/presentation/widgets/class_details_sheet.dart';

class AdminClassesTab extends StatefulWidget {
  const AdminClassesTab({super.key});

  @override
  State<AdminClassesTab> createState() => _AdminClassesTabState();
}

class _AdminClassesTabState extends State<AdminClassesTab> {
  final AdminClassService _classService = AdminClassService();

  String _searchQuery = '';
  int _selectedGradeFilter = 0; // 0 = Tất cả khối, 6..9

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SchoolClassModel>>(
      stream: _classService.getClassesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allClasses = snapshot.data ?? [];

        // Nếu database hoàn toàn trống -> Nạp 36 lớp chuẩn
        if (allClasses.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryMint,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.home_work_outlined,
                      size: 64,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Chưa có lớp học nào trong hệ thống',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Bạn có thể nạp nhanh 36 lớp học chuẩn (Khối 6 -> 9) của trường THCS Nguyễn Thị Hương.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () async {
                      final count = await _classService.seedDefault36Classes();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Đã nạp thành công $count lớp học vào hệ thống!',
                            ),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Nạp 36 Lớp Chuẩn (6A1 - 9A12)'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final totalClasses = allClasses.length;
        final activeClasses = allClasses.where((c) => c.isActive).length;
        final inactiveClasses = totalClasses - activeClasses;

        // Lọc theo tìm kiếm và khối
        final filteredClasses = allClasses.where((c) {
          final matchesSearch = _searchQuery.isEmpty ||
              c.className.contains(_searchQuery.toUpperCase());
          final matchesGrade =
              _selectedGradeFilter == 0 || c.grade == _selectedGradeFilter;
          return matchesSearch && matchesGrade;
        }).toList();

        // Sắp xếp tự nhiên
        filteredClasses.sort(
            (a, b) => StringUtils.compareNatural(a.className, b.className));

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
                          title: 'Tổng số lớp',
                          count: '$totalClasses',
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Hoạt động',
                          count: '$activeClasses',
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Tạm ẩn',
                          count: '$inactiveClasses',
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Thanh tìm kiếm và bộ lọc Khối (Mỗi mục 1 dòng độc lập)
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      // Dòng 1: Tìm kiếm theo tên lớp
                      TextField(
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: 'Tìm theo tên lớp (Ví dụ: 6A1, 9A2...)',
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

                      // Dòng 2: Bộ lọc khối dạng Chip ngang
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            FilterChip(
                              selected: _selectedGradeFilter == 0,
                              label: const Text('Tất cả khối'),
                              onSelected: (_) =>
                                  setState(() => _selectedGradeFilter = 0),
                            ),
                            const SizedBox(width: 6),
                            ...[6, 7, 8, 9].map(
                              (g) => Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: FilterChip(
                                  selected: _selectedGradeFilter == g,
                                  label: Text('Khối $g'),
                                  onSelected: (_) =>
                                      setState(() => _selectedGradeFilter = g),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Danh sách lớp học
              if (filteredClasses.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Không tìm thấy lớp học nào phù hợp.',
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
                        final cls = filteredClasses[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: cls.isActive
                                  ? Colors.transparent
                                  : Colors.red.shade200,
                            ),
                          ),
                          child: ListTile(
                            onTap: () => ClassDetailsSheet.show(context, cls.className),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            leading: CircleAvatar(
                              backgroundColor: cls.isActive
                                  ? AppColors.primaryMint
                                  : Colors.grey.shade200,
                              child: Text(
                                cls.className,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: cls.isActive
                                      ? AppColors.primaryDark
                                      : AppColors.textMuted,
                                ),
                              ),
                            ),
                            title: Text(
                              'Lớp ${cls.className}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: cls.isActive ? null : Colors.grey,
                                decoration: cls.isActive
                                    ? null
                                    : TextDecoration.lineThrough,
                              ),
                            ),
                            subtitle: Text(
                              'Khối ${cls.grade} • ${cls.isActive ? "Đang hoạt động" : "Đã tạm ẩn"}',
                              style: TextStyle(
                                fontSize: 12,
                                color: cls.isActive
                                    ? AppColors.textSecondary
                                    : AppColors.textMuted,
                              ),
                            ),
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              tooltip: 'Tùy chọn',
                              onSelected: (action) {
                                switch (action) {
                                  case 'edit':
                                    _showEditClassDialog(context, cls);
                                    break;
                                  case 'toggle':
                                    _classService.toggleClassActive(
                                      classId: cls.id,
                                      currentIsActive: cls.isActive,
                                    );
                                    break;
                                  case 'delete':
                                    _showDeleteConfirm(context, cls);
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
                                  value: 'toggle',
                                  child: Row(
                                    children: [
                                      Icon(
                                        cls.isActive
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        size: 20,
                                        color: cls.isActive
                                            ? Colors.orange.shade800
                                            : Colors.green,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(cls.isActive
                                          ? 'Tạm ẩn lớp'
                                          : 'Kích hoạt lại'),
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
                                      Text('Xóa lớp',
                                          style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: filteredClasses.length,
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

  void _showEditClassDialog(BuildContext context, SchoolClassModel cls) {
    int selectedGrade = cls.grade;
    int selectedClassNum = 1;
    if (cls.className.length > 2 && cls.className.contains('A')) {
      final parts = cls.className.split('A');
      if (parts.length > 1) {
        selectedClassNum = int.tryParse(parts[1]) ?? 1;
      }
    }
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final newClassName = '${selectedGrade}A$selectedClassNum';

          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            title: Text(
              'Chỉnh Sửa Lớp ${cls.className}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                              child: Text('Khối $g',
                                  style: const TextStyle(fontSize: 13)),
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
                              child: Text('Lớp $n',
                                  style: const TextStyle(fontSize: 13)),
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
                          'Lớp sau khi sửa: $newClassName',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const Divider(height: 16),
                        Text(
                          '• Phân loại mới: Khối $selectedGrade',
                          style: const TextStyle(
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
                onPressed: isSaving
                    ? null
                    : () async {
                        setDialogState(() => isSaving = true);
                        try {
                          await _classService.updateClass(
                            classId: cls.id,
                            newClassName: newClassName,
                            grade: selectedGrade,
                          );
                          if (context.mounted) {
                            Navigator.pop(dialogCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã cập nhật thông tin lớp!'),
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
                child: const Text('Lưu'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, SchoolClassModel cls) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác Nhận Xóa Lớp'),
        content: Text(
          'Bạn có chắc chắn muốn xóa lớp ${cls.className} khỏi hệ thống? Thao tác này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _classService.deleteClass(cls.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã xóa lớp ${cls.className} thành công!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi khi xóa lớp: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Xóa Lớp'),
          ),
        ],
      ),
    );
  }
}
