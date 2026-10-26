import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/responsive_container.dart';
import '../../models/score_criteria_model.dart';
import '../../services/score_criteria_service.dart';

class AdminCriteriaTab extends StatefulWidget {
  const AdminCriteriaTab({super.key});

  @override
  State<AdminCriteriaTab> createState() => _AdminCriteriaTabState();
}

class _AdminCriteriaTabState extends State<AdminCriteriaTab> {
  final ScoreCriteriaService _criteriaService = ScoreCriteriaService();

  String _searchQuery = '';
  int _selectedTypeIndex = 0; // 0 = Cộng điểm (+), 1 = Trừ điểm (-)

  String get _currentType => _selectedTypeIndex == 0 ? 'plus' : 'minus';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ScoreCriteriaModel>>(
      stream: _criteriaService.getCriteriaStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allItems = snapshot.data ?? [];

        // Nếu database hoàn toàn trống -> Gợi ý nút nạp 10 tiêu chí mẫu chuẩn
        if (allItems.isEmpty) {
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
                      Icons.rule_folder_rounded,
                      size: 64,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Chưa có tiêu chí thi đua nào',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Bạn có thể nạp nhanh 10 tiêu chí Hành Động Xanh chuẩn (5 mục cộng và 5 mục trừ) của trường.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () async {
                      await _criteriaService.seedDefaultCriteria();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Đã nạp 10 tiêu chí Hành Động Xanh thành công!',
                            ),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Nạp 10 Tiêu Chí Chuẩn Ban Đầu'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final totalCriteria = allItems.length;
        final plusCount = allItems.where((c) => c.isPlus).length;
        final minusCount = allItems.where((c) => c.isMinus).length;

        // Lọc theo loại (Cộng / Trừ) và tìm kiếm
        final filteredItems = allItems.where((c) {
          final matchesType = c.type == _currentType;
          final matchesSearch = _searchQuery.isEmpty ||
              c.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              c.description.toLowerCase().contains(_searchQuery.toLowerCase());
          return matchesType && matchesSearch;
        }).toList();

        final isPlus = _selectedTypeIndex == 0;

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
                          title: 'Tổng tiêu chí',
                          count: '$totalCriteria',
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Điểm Cộng',
                          count: '$plusCount',
                          color: AppColors.plusColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Điểm Trừ',
                          count: '$minusCount',
                          color: AppColors.minusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Bộ lọc Chuyển Tab (Cộng / Trừ) & Tìm kiếm
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      // Dòng 1: Tìm kiếm theo tên tiêu chí
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Tìm theo tên tiêu chí...',
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
                      const SizedBox(height: 10),

                      // Dòng 2: Chuyển tab Cộng Điểm (+) vs Trừ Điểm (-)
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () =>
                                    setState(() => _selectedTypeIndex = 0),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _selectedTypeIndex == 0
                                        ? AppColors.plusColor
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_circle_outline_rounded,
                                        size: 18,
                                        color: _selectedTypeIndex == 0
                                            ? Colors.white
                                            : AppColors.plusColor,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Điểm Cộng',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: _selectedTypeIndex == 0
                                              ? Colors.white
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: InkWell(
                                onTap: () =>
                                    setState(() => _selectedTypeIndex = 1),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _selectedTypeIndex == 1
                                        ? AppColors.minusColor
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.remove_circle_outline_rounded,
                                        size: 18,
                                        color: _selectedTypeIndex == 1
                                            ? Colors.white
                                            : AppColors.minusColor,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Điểm Trừ',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: _selectedTypeIndex == 1
                                              ? Colors.white
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
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

              // 3. Danh sách tiêu chí
              if (filteredItems.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        isPlus
                            ? 'Không có tiêu chí cộng điểm nào phù hợp.'
                            : 'Không có tiêu chí trừ điểm nào phù hợp.',
                        style: const TextStyle(color: AppColors.textSecondary),
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
                        final item = filteredItems[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: item.isActive
                                  ? Colors.transparent
                                  : Colors.red.shade200,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            leading: CircleAvatar(
                              backgroundColor: item.isActive
                                  ? (isPlus
                                      ? AppColors.plusColorLight
                                      : AppColors.minusColorLight)
                                  : Colors.grey.shade200,
                              child: Icon(
                                item.iconData,
                                color: item.isActive
                                    ? (isPlus
                                        ? AppColors.plusColor
                                        : AppColors.minusColor)
                                    : AppColors.textMuted,
                              ),
                            ),
                            title: Text(
                              item.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: item.isActive ? null : Colors.grey,
                                decoration: item.isActive
                                    ? null
                                    : TextDecoration.lineThrough,
                              ),
                            ),
                            subtitle: item.description.isNotEmpty
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      item.description,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  )
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isPlus
                                        ? AppColors.plusColorLight
                                        : AppColors.minusColorLight,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isPlus
                                        ? '+${item.points}đ'
                                        : '-${item.points}đ',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isPlus
                                          ? AppColors.plusColor
                                          : AppColors.minusColor,
                                    ),
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert),
                                  tooltip: 'Tùy chọn',
                                  onSelected: (action) {
                                    switch (action) {
                                      case 'edit':
                                        _showEditCriteriaDialog(context, item);
                                        break;
                                      case 'toggle':
                                        _criteriaService.toggleCriteriaActive(
                                          id: item.id,
                                          currentIsActive: item.isActive,
                                        );
                                        break;
                                      case 'delete':
                                        _showDeleteConfirm(context, item);
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
                                            item.isActive
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            size: 20,
                                            color: item.isActive
                                                ? Colors.orange.shade800
                                                : Colors.green,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(item.isActive
                                              ? 'Tạm ẩn tiêu chí'
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
                                          Text('Xóa tiêu chí',
                                              style: TextStyle(
                                                  color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: filteredItems.length,
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

  void _showEditCriteriaDialog(BuildContext context, ScoreCriteriaModel item) {
    final titleCtrl = TextEditingController(text: item.title);
    final pointsCtrl = TextEditingController(text: item.points.toString());
    final descCtrl = TextEditingController(text: item.description);
    String iconName = item.iconName;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isPlus = item.isPlus;

          return AlertDialog(
            title: Text('Sửa Tiêu Chí ${isPlus ? "Cộng Điểm" : "Trừ Điểm"}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tên tiêu chí',
                      prefixIcon: Icon(Icons.title_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: pointsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: isPlus ? 'Số điểm cộng' : 'Số điểm trừ',
                      suffixText: 'điểm',
                      prefixIcon: Icon(
                        isPlus ? Icons.add : Icons.remove,
                        color:
                            isPlus ? AppColors.plusColor : AppColors.minusColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả hướng dẫn',
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
                onPressed: isSaving
                    ? null
                    : () async {
                        final title = titleCtrl.text.trim();
                        final pts = int.tryParse(pointsCtrl.text.trim()) ?? 0;
                        if (title.isEmpty || pts <= 0) return;

                        setDialogState(() => isSaving = true);
                        try {
                          await _criteriaService.updateCriteria(
                            id: item.id,
                            title: title,
                            points: pts,
                            description: descCtrl.text.trim(),
                            iconName: iconName,
                          );
                          if (context.mounted) {
                            Navigator.pop(dialogCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã cập nhật tiêu chí!'),
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

  void _showDeleteConfirm(BuildContext context, ScoreCriteriaModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác Nhận Xóa Tiêu Chí'),
        content: Text('Bạn có chắc muốn xóa tiêu chí "${item.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await _criteriaService.deleteCriteria(item.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã xóa tiêu chí thành công!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Xóa'),
          ),
        ],
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
