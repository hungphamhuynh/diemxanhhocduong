import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/string_utils.dart';
import '../../../../core/widgets/responsive_container.dart';
import '../../../admin/models/score_criteria_model.dart';
import '../../../admin/models/system_config_model.dart';
import '../../../admin/services/admin_class_service.dart';
import '../../../admin/services/score_criteria_service.dart';
import '../../../admin/services/system_config_service.dart';
import 'class_details_sheet.dart';

/// Tab Xếp Hạng & Thống Kê dành cho Tổng Phụ Trách (Đồng bộ 1-1 với style tich_diem)
/// - Không dùng bục podium, không cộng điểm gốc 100
/// - Bộ lọc chuẩn hóa: Năm, Tháng (Cả năm / Tháng 1..12), Khối (Dropdown Select), Tiêu Chí
/// - Thẻ KPI Gradient tóm tắt điểm trong kỳ
/// - Bảng tổng sắp chi tiết xếp hạng theo dense ranking có nhãn đồng hạng và huân chương 🥇🥈🥉
class SchoolStatisticsLeaderboardView extends StatefulWidget {
  final bool isAdmin;

  const SchoolStatisticsLeaderboardView({
    super.key,
    this.isAdmin = false,
  });

  @override
  State<SchoolStatisticsLeaderboardView> createState() =>
      _SchoolStatisticsLeaderboardViewState();
}

class _SchoolStatisticsLeaderboardViewState
    extends State<SchoolStatisticsLeaderboardView> {
  final SystemConfigService _configService = SystemConfigService();
  final AdminClassService _classService = AdminClassService();
  final ScoreCriteriaService _criteriaService = ScoreCriteriaService();

  late int _selectedYear;
  int _selectedMonth = 0; // 0 = Cả năm, 1..12 = Tháng 1..12
  int _selectedGrade = 0; // 0 = Tất cả các khối, 6..9 = Khối 6..9
  String _selectedCriteriaId = ''; // '' = Tất cả tiêu chí

  late Stream<QuerySnapshot> _recordsStream;
  late final Stream<List<ScoreCriteriaModel>> _criteriaStream;

  Stream<QuerySnapshot> _buildRecordsStream(int year, int month) {
    final collection = FirebaseFirestore.instance.collection('score_records');
    if (month == 0) {
      // Cả năm
      final start = DateTime(year, 1, 1);
      final end = DateTime(year + 1, 1, 1);
      return collection
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThan: Timestamp.fromDate(end))
          .snapshots();
    } else {
      // Tháng cụ thể
      final start = DateTime(year, month, 1);
      final end = month == 12
          ? DateTime(year + 1, 1, 1)
          : DateTime(year, month + 1, 1);
      return collection
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThan: Timestamp.fromDate(end))
          .snapshots();
    }
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month; // Mặc định mở tháng hiện tại
    _recordsStream = _buildRecordsStream(_selectedYear, _selectedMonth);
    _criteriaStream = _criteriaService.getCriteriaStream(onlyActive: true);
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

        return StreamBuilder<List<ScoreCriteriaModel>>(
          stream: _criteriaStream,
          builder: (context, criteriaSnap) {
            final criteriaList = criteriaSnap.data ?? [];

            return StreamBuilder<List<dynamic>>(
              stream: _classService.getClassesStream(onlyActive: true),
              builder: (context, classesSnap) {
                final classes = classesSnap.data ?? [];

                return StreamBuilder<QuerySnapshot>(
                  stream: _recordsStream,
                  builder: (context, recordsSnap) {
                    if (recordsSnap.connectionState ==
                            ConnectionState.waiting &&
                        !recordsSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = recordsSnap.data?.docs ?? [];

                    // 1. Thu thập và tổng hợp số liệu
                    int totalSchoolPlus = 0;
                    int totalSchoolMinus = 0;
                    final Map<String, _ClassScoreData> classMap = {};

                    // Khởi tạo các lớp học đang hoạt động vào bảng
                    for (final c in classes) {
                      final cName = c.className as String;
                      final cGrade = c.grade as int;
                      if (_selectedGrade != 0 && cGrade != _selectedGrade) {
                        continue;
                      }
                      classMap[cName] =
                          _ClassScoreData(className: cName, grade: cGrade);
                    }

                    // Duyệt qua các phiếu chấm
                    for (final doc in docs) {
                      final data = doc.data() as Map<String, dynamic>? ?? {};
                      final className =
                          (data['className'] as String? ?? '').trim().toUpperCase();
                      if (className.isEmpty) continue;

                      final grade = (data['grade'] as num?)?.toInt() ??
                          (int.tryParse(className[0]) ?? 0);

                      if (_selectedGrade != 0 && grade != _selectedGrade) {
                        continue;
                      }

                      final criteriaId = data['criteriaId'] as String? ?? '';
                      if (_selectedCriteriaId.isNotEmpty &&
                          criteriaId != _selectedCriteriaId) {
                        continue;
                      }

                      final type = data['type'] as String? ?? 'plus';
                      final points = (data['points'] as num?)?.toInt() ?? 0;
                      final isPlus = type == 'plus';

                      final stats = classMap.putIfAbsent(
                        className,
                        () => _ClassScoreData(className: className, grade: grade),
                      );

                      if (isPlus) {
                        stats.totalPlus += points;
                        totalSchoolPlus += points;
                      } else {
                        stats.totalMinus += points;
                        totalSchoolMinus += points;
                      }
                      stats.submissionCount++;
                    }

                    // 2. Sắp xếp thứ hạng (Điểm ròng cao nhất lên đầu)
                    final rankedClasses = classMap.values.toList();
                    rankedClasses.sort((a, b) {
                      final cmpNet = b.netScore.compareTo(a.netScore);
                      if (cmpNet != 0) return cmpNet;

                      final cmpMinus = a.totalMinus.compareTo(b.totalMinus);
                      if (cmpMinus != 0) return cmpMinus;

                      final cmpPlus = b.totalPlus.compareTo(a.totalPlus);
                      if (cmpPlus != 0) return cmpPlus;

                      return StringUtils.compareNatural(
                          a.className, b.className);
                    });

                    // 3. Dense Ranking & Đồng hạng
                    int currentRank = 0;
                    num? previousScore;
                    for (int i = 0; i < rankedClasses.length; i++) {
                      final curr = rankedClasses[i];
                      if (previousScore == null ||
                          curr.netScore != previousScore) {
                        currentRank++;
                        previousScore = curr.netScore;
                      }
                      curr.displayRank = currentRank;
                    }

                    for (int i = 0; i < rankedClasses.length; i++) {
                      final curr = rankedClasses[i];
                      final hasScore = curr.submissionCount > 0;
                      final hasSameRankBefore = i > 0 &&
                          rankedClasses[i].displayRank ==
                              rankedClasses[i - 1].displayRank;
                      final hasSameRankAfter = i < rankedClasses.length - 1 &&
                          rankedClasses[i].displayRank ==
                              rankedClasses[i + 1].displayRank;
                      curr.isTie =
                          (hasSameRankBefore || hasSameRankAfter) && hasScore;
                    }

                    final currentYear = DateTime.now().year;
                    final availableYears =
                        List.generate(5, (i) => currentYear - 2 + i);

                    final totalNetScore = totalSchoolPlus - totalSchoolMinus;

                    return ResponsiveContainer(
                      maxWidth: 900,
                      child: CustomScrollView(
                        slivers: [
                          // 1. Thẻ Bộ Lọc Đồng Nhất (Năm, Tháng, Khối Lớp, Tiêu Chí)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                              child: _buildFilterCard(
                                availableYears: availableYears,
                                criteriaList: criteriaList,
                              ),
                            ),
                          ),

                          // 2. Thẻ Tóm Tắt KPI Toàn Trường
                          SliverToBoxAdapter(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: _buildKpiBanner(
                                totalPlus: totalSchoolPlus,
                                totalMinus: totalSchoolMinus,
                                netPoints: totalNetScore,
                                activeClassesCount: rankedClasses.length,
                                academicYear: config.academicYear,
                              ),
                            ),
                          ),

                          // 3. Tiêu đề Bảng Xếp Hạng
                          SliverToBoxAdapter(
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Text(
                                'Bảng Xếp Hạng Các Lớp (${rankedClasses.length})',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),

                          // 4. Danh Sách Chi Tiết Từng Lớp
                          if (rankedClasses.isEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: const BoxDecoration(
                                          color: AppColors.surfaceVariant,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.eco_outlined,
                                          size: 48,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Chưa có dữ liệu chấm điểm trong đợt này',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          else
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final item = rankedClasses[index];
                                    return _buildRankedClassCard(context, item);
                                  },
                                  childCount: rankedClasses.length,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  /// Khung bộ lọc Năm, Tháng, Khối Lớp và Tiêu Chí (Đồng bộ 1-1 dạng Select dropdown)
  Widget _buildFilterCard({
    required List<int> availableYears,
    required List<ScoreCriteriaModel> criteriaList,
  }) {
    // Deduplicate tiêu chí để phòng ngừa dữ liệu lặp id
    final uniqueCriteria = <String, ScoreCriteriaModel>{};
    for (final c in criteriaList) {
      uniqueCriteria[c.id] = c;
    }
    final safeCriteriaList = uniqueCriteria.values.toList();
    final hasCriteria = _selectedCriteriaId.isEmpty ||
        safeCriteriaList.any((c) => c.id == _selectedCriteriaId);
    final currentCriteriaVal = hasCriteria ? _selectedCriteriaId : '';

    final hasYear = availableYears.contains(_selectedYear);
    final currentYearVal = hasYear
        ? _selectedYear
        : (availableYears.isNotEmpty ? availableYears.first : DateTime.now().year);

    final currentMonthVal =
        (_selectedMonth >= 0 && _selectedMonth <= 12) ? _selectedMonth : 0;
    final currentGradeVal =
        const [0, 6, 7, 8, 9].contains(_selectedGrade) ? _selectedGrade : 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dòng 1: Năm & Tháng
          Row(
            children: [
              // Chọn Năm
              Expanded(
                child: DropdownButtonFormField<int>(
                  key: ValueKey('filter_year_$currentYearVal'),
                  initialValue: currentYearVal,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Năm',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: availableYears.map((y) {
                    return DropdownMenuItem<int>(
                      value: y,
                      child: Text(
                        'Năm $y',
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedYear = val;
                        _recordsStream =
                            _buildRecordsStream(_selectedYear, _selectedMonth);
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),

              // Chọn Tháng
              Expanded(
                child: DropdownButtonFormField<int>(
                  key: ValueKey('filter_month_$currentMonthVal'),
                  initialValue: currentMonthVal,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Tháng',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: 0,
                      child: Text(
                        'Cả năm',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...List.generate(12, (i) {
                      final month = i + 1;
                      return DropdownMenuItem<int>(
                        value: month,
                        child: Text(
                          'Tháng $month',
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedMonth = val;
                        _recordsStream =
                            _buildRecordsStream(_selectedYear, _selectedMonth);
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Dòng 2: Khối học (Dạng Select dropdown chuẩn 1-1, không dùng FilterChip)
          DropdownButtonFormField<int>(
            key: ValueKey('filter_grade_$currentGradeVal'),
            initialValue: currentGradeVal,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Khối Lớp',
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: const [
              DropdownMenuItem<int>(
                value: 0,
                child: Text('Tất cả các khối', style: TextStyle(fontSize: 14)),
              ),
              DropdownMenuItem<int>(
                value: 6,
                child: Text('Khối 6', style: TextStyle(fontSize: 14)),
              ),
              DropdownMenuItem<int>(
                value: 7,
                child: Text('Khối 7', style: TextStyle(fontSize: 14)),
              ),
              DropdownMenuItem<int>(
                value: 8,
                child: Text('Khối 8', style: TextStyle(fontSize: 14)),
              ),
              DropdownMenuItem<int>(
                value: 9,
                child: Text('Khối 9', style: TextStyle(fontSize: 14)),
              ),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _selectedGrade = val);
            },
          ),
          const SizedBox(height: 10),

          // Dòng 3: Tiêu chí chấm điểm (Dạng Select dropdown an toàn)
          DropdownButtonFormField<String>(
            key: ValueKey('filter_criteria_$currentCriteriaVal'),
            initialValue: currentCriteriaVal,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Tiêu Chí Chấm Điểm',
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: '',
                child: Text(
                  'Tất cả tiêu chí (Xếp theo điểm)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              ...safeCriteriaList.map((c) {
                return DropdownMenuItem<String>(
                  value: c.id,
                  child: Text(
                    '${c.title} (${c.isPlus ? "+" : "-"}${c.points}đ)',
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _selectedCriteriaId = val);
            },
          ),
        ],
      ),
    );
  }

  /// Banner Tóm Tắt KPI (Style 1-1 gradient app cũ)
  Widget _buildKpiBanner({
    required int totalPlus,
    required int totalMinus,
    required int netPoints,
    required int activeClassesCount,
    required String academicYear,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TỔNG KẾT THI ĐUA',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _selectedMonth == 0
                          ? 'Năm $_selectedYear ${_selectedGrade != 0 ? "• Khối $_selectedGrade" : "• Toàn trường"}'
                          : 'Tháng $_selectedMonth/$_selectedYear ${_selectedGrade != 0 ? "• Khối $_selectedGrade" : "• Toàn trường"}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Niên khóa: $academicYear',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$activeClassesCount Lớp',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3 ô chỉ số KPI
          Row(
            children: [
              Expanded(
                child: _buildKpiStatTile(
                  label: 'Tổng Điểm Cộng',
                  value: '+$totalPlus đ',
                  color: const Color(0xFF86EFAC),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildKpiStatTile(
                  label: 'Tổng Điểm Trừ',
                  value: '-$totalMinus đ',
                  color: const Color(0xFFFECACA),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildKpiStatTile(
                  label: 'Điểm Thi Đua',
                  value: '${netPoints >= 0 ? "+" : ""}$netPoints đ',
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiStatTile({
    required String label,
    required String value,
    Color color = Colors.white,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Thẻ chi tiết từng lớp trong bảng tổng sắp (Style 1-1 app cũ)
  Widget _buildRankedClassCard(
    BuildContext context,
    _ClassScoreData stats,
  ) {
    final rank = stats.displayRank;
    Color rankColor;
    Widget rankBadge;

    if (rank == 1) {
      rankColor = const Color(0xFFEAB308);
      rankBadge = const Text('🥇', style: TextStyle(fontSize: 22));
    } else if (rank == 2) {
      rankColor = const Color(0xFF94A3B8);
      rankBadge = const Text('🥈', style: TextStyle(fontSize: 22));
    } else if (rank == 3) {
      rankColor = const Color(0xFFD97706);
      rankBadge = const Text('🥉', style: TextStyle(fontSize: 22));
    } else {
      rankColor = AppColors.textSecondary;
      rankBadge = Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            '$rank',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: rank <= 3
              ? rankColor.withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
      child: ListTile(
        onTap: () => ClassDetailsSheet.show(
          context,
          stats.className,
          year: _selectedYear,
          month: _selectedMonth,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: rankBadge,
        title: Row(
          children: [
            Text(
              'Lớp ${stats.className}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Khối ${stats.grade}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (stats.isTie) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Đồng hạng',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          '${stats.submissionCount} lượt • +${stats.totalPlus}đ / -${stats.totalMinus}đ',
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: stats.netScore >= 0
                ? AppColors.primaryMint
                : Colors.red.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${stats.netScore >= 0 ? "+" : ""}${stats.netScore} đ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: stats.netScore >= 0
                  ? AppColors.primaryDark
                  : AppColors.error,
            ),
          ),
        ),
      ),
    );
  }
}

class _ClassScoreData {
  final String className;
  final int grade;
  int totalPlus = 0;
  int totalMinus = 0;
  int submissionCount = 0;
  int displayRank = 1;
  bool isTie = false;

  int get netScore => totalPlus - totalMinus;

  _ClassScoreData({
    required this.className,
    required this.grade,
  });
}
