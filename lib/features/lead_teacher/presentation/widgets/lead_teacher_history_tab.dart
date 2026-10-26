import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils_helper.dart';
import '../../../../core/widgets/responsive_container.dart';
import '../../models/score_record_model.dart';
import '../../services/score_record_service.dart';

class LeadTeacherHistoryTab extends StatefulWidget {
  final bool isAdmin;

  const LeadTeacherHistoryTab({
    super.key,
    this.isAdmin = false,
  });

  @override
  State<LeadTeacherHistoryTab> createState() => _LeadTeacherHistoryTabState();
}

class _LeadTeacherHistoryTabState extends State<LeadTeacherHistoryTab> {
  final ScoreRecordService _recordService = ScoreRecordService();
  String _searchQuery = '';
  int _filterTypeIndex = 0; // 0 = Tất cả, 1 = Điểm cộng, 2 = Điểm trừ

  void _showDeleteConfirm(BuildContext context, ScoreRecordModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác Nhận Xóa Phiếu'),
        content: Text(
          'Bạn có chắc chắn muốn xóa phiếu "${item.criteriaTitle}" (${item.points}đ) của lớp ${item.className}?',
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
              await _recordService.deleteRecord(item.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã xóa phiếu chấm điểm thành công!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Xóa Phiếu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ScoreRecordModel>>(
      stream: _recordService.getRecentRecordsStream(limit: 150),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allRecords = snapshot.data ?? [];
        final totalCount = allRecords.length;
        final plusCount = allRecords.where((r) => r.isPlus).length;
        final minusCount = allRecords.where((r) => r.isMinus).length;

        // Lọc danh sách theo tìm kiếm và loại
        final filteredRecords = allRecords.where((r) {
          final query = _searchQuery.trim().toLowerCase();
          final matchesSearch = query.isEmpty ||
              r.className.toLowerCase().contains(query) ||
              r.criteriaTitle.toLowerCase().contains(query) ||
              r.note.toLowerCase().contains(query);

          final matchesType = _filterTypeIndex == 0 ||
              (_filterTypeIndex == 1 && r.isPlus) ||
              (_filterTypeIndex == 2 && r.isMinus);

          return matchesSearch && matchesType;
        }).toList();

        return ResponsiveContainer(
          maxWidth: 900,
          child: CustomScrollView(
            slivers: [
              // 1. Thống kê nhanh 3 chỉ số đồng bộ với các tab
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Tổng phiếu',
                          count: '$totalCount',
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

              // 2. Ô Tìm kiếm & Bộ lọc Chip ngang cuộn an toàn chống tràn pixel
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      // Ô tìm kiếm full-width
                      TextField(
                        decoration: InputDecoration(
                          hintText:
                              'Tìm theo lớp (6A1, 9A2...) hoặc tiêu chí...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
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
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                      const SizedBox(height: 8),

                      // Thanh chip lọc cuộn ngang an toàn
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildTypeChip('Tất cả ($totalCount)', 0),
                            const SizedBox(width: 8),
                            _buildTypeChip('Điểm Cộng ($plusCount)', 1),
                            const SizedBox(width: 8),
                            _buildTypeChip('Điểm Trừ ($minusCount)', 2),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Danh sách phiếu chấm điểm
              if (filteredRecords.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 56,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Chưa có nhật ký chấm điểm nào phù hợp.',
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
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
                        final item = filteredRecords[index];
                        final isPlus = item.isPlus;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isPlus
                                  ? Colors.green.shade100
                                  : Colors.red.shade100,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            leading: CircleAvatar(
                              backgroundColor: isPlus
                                  ? AppColors.plusColorLight
                                  : AppColors.minusColorLight,
                              child: Icon(
                                isPlus
                                    ? Icons.add_rounded
                                    : Icons.remove_rounded,
                                color: isPlus
                                    ? AppColors.plusColor
                                    : AppColors.minusColor,
                              ),
                            ),
                            title: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryMint,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Lớp ${item.className}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.criteriaTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (item.note.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    item.note,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 3),
                                Text(
                                  '${item.recordedByName.isNotEmpty ? item.recordedByName : item.recordedByEmail} • ${DateUtilsHelper.formatDateTime(item.createdAt)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isPlus
                                        ? AppColors.plusColorLight
                                        : AppColors.minusColorLight,
                                    borderRadius: BorderRadius.circular(8),
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
                                  icon: const Icon(
                                    Icons.more_vert,
                                    size: 18,
                                    color: AppColors.textSecondary,
                                  ),
                                  tooltip: 'Tùy chọn',
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  onSelected: (action) {
                                    if (action == 'delete') {
                                      _showDeleteConfirm(context, item);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline_rounded,
                                              size: 18, color: AppColors.error),
                                          SizedBox(width: 8),
                                          Text('Xóa phiếu',
                                              style: TextStyle(
                                                  color: AppColors.error)),
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
                      childCount: filteredRecords.length,
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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String label, int index) {
    return FilterChip(
      selected: _filterTypeIndex == index,
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onSelected: (_) => setState(() => _filterTypeIndex = index),
    );
  }
}
