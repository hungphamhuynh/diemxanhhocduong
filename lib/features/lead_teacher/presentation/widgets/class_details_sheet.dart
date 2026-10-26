import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils_helper.dart';
import '../../models/score_record_model.dart';
import '../../services/score_record_service.dart';

/// Modal BottomSheet hiển thị Chi Tiết Điểm của một lớp học
/// Đồng bộ 1-1 với phong cách ClassDetailsSheet của app chuẩn:
/// - Không bị phụ thuộc vào Composite Index của Firestore
/// - Có thống kê Điểm Cộng, Điểm Trừ, Điểm Thi Đua
/// - Có bộ lọc Tất cả / Điểm Cộng / Điểm Trừ và lọc theo Kỳ thi đua
class ClassDetailsSheet extends StatefulWidget {
  final String className;
  final int? initialYear;
  final int? initialMonth; // 0 = Cả năm, 1..12 = Tháng cụ thể

  const ClassDetailsSheet({
    super.key,
    required this.className,
    this.initialYear,
    this.initialMonth,
  });

  static void show(
    BuildContext context,
    String className, {
    int? year,
    int? month,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClassDetailsSheet(
        className: className,
        initialYear: year,
        initialMonth: month,
      ),
    );
  }

  @override
  State<ClassDetailsSheet> createState() => _ClassDetailsSheetState();
}

class _ClassDetailsSheetState extends State<ClassDetailsSheet> {
  final ScoreRecordService _recordService = ScoreRecordService();

  late Stream<List<ScoreRecordModel>> _recordsStream;

  // 0: Tất cả, 1: Điểm Cộng, 2: Điểm Trừ
  int _typeFilterIndex = 0;

  // true: Chỉ hiển thị trong kỳ lọc hiện tại (Tháng/Năm), false: Xem toàn bộ lịch sử
  late bool _filterByPeriod;

  @override
  void initState() {
    super.initState();
    _filterByPeriod = widget.initialYear != null;
    _recordsStream = _recordService.getRecordsByClassStream(widget.className);
  }

  @override
  Widget build(BuildContext context) {
    final cleanClass = widget.className.trim().toUpperCase();
    final grade = int.tryParse(cleanClass.isNotEmpty ? cleanClass[0] : '') ?? 0;

    final filterYear = widget.initialYear ?? DateTime.now().year;
    final filterMonth = widget.initialMonth ?? 0;
    final periodLabel = filterMonth == 0
        ? 'Năm $filterYear'
        : 'Tháng $filterMonth/$filterYear';

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Thanh kéo đỉnh Sheet
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header: Thông tin lớp học
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 6, 12, 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryMint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: AppColors.primaryDark,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chi Tiết Điểm Lớp $cleanClass',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            grade > 0
                                ? 'Khối $grade • THCS Nguyễn Thị Hương'
                                : 'THCS Nguyễn Thị Hương',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 22),
                      tooltip: 'Đóng',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Nội dung dữ liệu phiếu chấm
              Expanded(
                child: StreamBuilder<List<ScoreRecordModel>>(
                  stream: _recordsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                size: 48,
                                color: AppColors.error,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Lỗi tải chi tiết: ${snapshot.error}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppColors.error),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final allRecords = snapshot.data ?? [];

                    // 1. Lọc theo kỳ thi đua nếu đang bật
                    final periodRecords = allRecords.where((r) {
                      if (!_filterByPeriod) return true;
                      final dt = r.createdAt;
                      final rYear = dt?.year ?? r.year;
                      final rMonth = dt?.month ?? r.month;

                      if (filterMonth == 0) {
                        return rYear == filterYear;
                      } else {
                        return rYear == filterYear && rMonth == filterMonth;
                      }
                    }).toList();

                    // Tính điểm thống kê trong danh sách đang xét
                    int totalPlus = 0;
                    int totalMinus = 0;
                    for (final r in periodRecords) {
                      if (r.isPlus) {
                        totalPlus += r.points;
                      } else {
                        totalMinus += r.points;
                      }
                    }
                    final netScore = totalPlus - totalMinus;

                    // 2. Lọc theo tab loại điểm (Tất cả / Cộng / Trừ)
                    final displayList = periodRecords.where((r) {
                      if (_typeFilterIndex == 1) return r.isPlus;
                      if (_typeFilterIndex == 2) return r.isMinus;
                      return true;
                    }).toList();

                    return Column(
                      children: [
                        // Thẻ tóm tắt 3 chỉ số điểm trong kỳ
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatTile(
                                  title: 'Tổng Điểm Cộng',
                                  value: '+$totalPlus đ',
                                  color: AppColors.plusColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildStatTile(
                                  title: 'Tổng Điểm Trừ',
                                  value: '-$totalMinus đ',
                                  color: AppColors.minusColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildStatTile(
                                  title: 'Điểm Thi Đua',
                                  value: '${netScore >= 0 ? "+" : ""}$netScore đ',
                                  color: netScore >= 0
                                      ? AppColors.primary
                                      : AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Thanh bộ lọc: Kỳ thi đua & Tab loại điểm
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Nút chuyển đổi kỳ nếu có initialYear
                              if (widget.initialYear != null) ...[
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      ChoiceChip(
                                        label: Text('Kỳ: $periodLabel'),
                                        selected: _filterByPeriod,
                                        onSelected: (val) {
                                          if (val) {
                                            setState(() => _filterByPeriod = true);
                                          }
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      ChoiceChip(
                                        label: Text(
                                            'Tất cả lịch sử (${allRecords.length})'),
                                        selected: !_filterByPeriod,
                                        onSelected: (val) {
                                          if (val) {
                                            setState(() => _filterByPeriod = false);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],

                              // Tab loại điểm (Tất cả / Cộng điểm / Trừ điểm)
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: Row(
                                  children: [
                                    _buildFilterTab(
                                      title: 'Tất cả (${periodRecords.length})',
                                      index: 0,
                                      activeColor: AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    _buildFilterTab(
                                      title: 'Điểm Cộng',
                                      index: 1,
                                      activeColor: AppColors.plusColor,
                                    ),
                                    const SizedBox(width: 4),
                                    _buildFilterTab(
                                      title: 'Điểm Trừ',
                                      index: 2,
                                      activeColor: AppColors.minusColor,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Danh sách chi tiết các phiếu chấm điểm
                        Expanded(
                          child: displayList.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.eco_outlined,
                                          size: 48,
                                          color: Colors.grey.shade400,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          _filterByPeriod
                                              ? 'Lớp $cleanClass chưa có dữ liệu trong $periodLabel'
                                              : 'Lớp $cleanClass chưa có dữ liệu chấm điểm',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  controller: scrollController,
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 6, 16, 24),
                                  itemCount: displayList.length,
                                  separatorBuilder: (_, index) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final item = displayList[index];
                                    final isPlus = item.isPlus;

                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isPlus
                                            ? AppColors.plusColorLight
                                                .withValues(alpha: 0.5)
                                            : AppColors.minusColorLight
                                                .withValues(alpha: 0.5),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isPlus
                                              ? const Color(0xFF86EFAC)
                                              : const Color(0xFFFECACA),
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: isPlus
                                                  ? AppColors.plusColor
                                                  : AppColors.minusColor,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              isPlus
                                                  ? Icons.add_rounded
                                                  : Icons.remove_rounded,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.criteriaTitle,
                                                  style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                if (item.note.isNotEmpty) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'Ghi chú: ${item.note}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontStyle:
                                                          FontStyle.italic,
                                                    ),
                                                  ),
                                                ],
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Người chấm: ${item.recordedByName.isNotEmpty ? item.recordedByName : item.recordedByEmail} • ${DateUtilsHelper.formatDateTime(item.createdAt)}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            isPlus
                                                ? '+${item.points}đ'
                                                : '-${item.points}đ',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: isPlus
                                                  ? AppColors.plusColor
                                                  : AppColors.minusColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatTile({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab({
    required String title,
    required int index,
    required Color activeColor,
  }) {
    final isSelected = _typeFilterIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _typeFilterIndex = index),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
