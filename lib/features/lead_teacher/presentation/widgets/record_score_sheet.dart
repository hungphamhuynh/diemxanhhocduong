import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/string_utils.dart';
import '../../../admin/models/school_class_model.dart';
import '../../../admin/models/score_criteria_model.dart';
import '../../../admin/services/admin_class_service.dart';
import '../../../admin/services/score_criteria_service.dart';
import '../../services/score_record_service.dart';

class RecordScoreSheet extends StatefulWidget {
  final String userUid;
  final String userEmail;
  final String userName;
  final String? initialClassName;

  const RecordScoreSheet({
    super.key,
    required this.userUid,
    required this.userEmail,
    required this.userName,
    this.initialClassName,
  });

  @override
  State<RecordScoreSheet> createState() => _RecordScoreSheetState();
}

class _RecordScoreSheetState extends State<RecordScoreSheet> {
  final AdminClassService _classService = AdminClassService();
  final ScoreCriteriaService _criteriaService = ScoreCriteriaService();
  final ScoreRecordService _recordService = ScoreRecordService();

  final TextEditingController _noteCtrl = TextEditingController();

  String? _selectedClassName;
  String? _selectedCriteriaId;
  ScoreCriteriaModel? _selectedCriteria;
  int _scoreTypeIndex = 0; // 0 = Cộng điểm, 1 = Trừ điểm
  bool _isSaving = false;

  bool get _isPlus => _scoreTypeIndex == 0;
  String get _currentType => _isPlus ? 'plus' : 'minus';

  @override
  void initState() {
    super.initState();
    _selectedClassName = widget.initialClassName;
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(bottom: viewInsets),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thanh kéo trên đỉnh
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 6),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Thanh tiêu đề có nút Đóng chuẩn đồng bộ với app cũ
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 12, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Chấm Điểm Nề Nếp & Hành Động Xanh',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                      overflow: TextOverflow.ellipsis,
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

            // Phần nội dung cuộn mượt mà không bao giờ lỗi pixel khi bật bàn phím
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. CHỌN LỚP HỌC
                    StreamBuilder<List<SchoolClassModel>>(
                      stream: _classService.getClassesStream(onlyActive: true),
                      builder: (context, snapshot) {
                        final classes = snapshot.data ?? [];
                        // Loại bỏ trùng lặp nếu có và sắp xếp tự nhiên
                        final uniqueClasses = <String, SchoolClassModel>{};
                        for (final c in classes) {
                          uniqueClasses[c.className] = c;
                        }
                        final sortedClasses = uniqueClasses.values.toList()
                          ..sort((a, b) =>
                              StringUtils.compareNatural(a.className, b.className));

                        final hasMatchingClass = sortedClasses
                            .any((c) => c.className == _selectedClassName);
                        final currentClassVal =
                            hasMatchingClass ? _selectedClassName : null;

                        return DropdownButtonFormField<String>(
                          key: ValueKey('dropdown_class_${currentClassVal ?? "none"}'),
                          initialValue: currentClassVal,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Chọn lớp học cần chấm điểm *',
                            prefixIcon: Icon(Icons.school_rounded),
                          ),
                          items: sortedClasses
                              .map(
                                (c) => DropdownMenuItem<String>(
                                  value: c.className,
                                  child: Text(
                                    'Lớp ${c.className} (Khối ${c.grade})',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setState(() => _selectedClassName = val);
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // 2. CHỌN LOẠI ĐIỂM: CỘNG HOẶC TRỪ
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _scoreTypeIndex = 0;
                                  _selectedCriteriaId = null;
                                  _selectedCriteria = null;
                                });
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _isPlus
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
                                      color: _isPlus
                                          ? Colors.white
                                          : AppColors.plusColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Cộng Điểm',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: _isPlus
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
                              onTap: () {
                                setState(() {
                                  _scoreTypeIndex = 1;
                                  _selectedCriteriaId = null;
                                  _selectedCriteria = null;
                                });
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: !_isPlus
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
                                      color: !_isPlus
                                          ? Colors.white
                                          : AppColors.minusColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Trừ Điểm',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: !_isPlus
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
                    const SizedBox(height: 16),

                    // 3. CHỌN TIÊU CHÍ (TỰ ĐỘNG LẤY ĐIỂM TƯƠNG ỨNG - KHÔNG CRASH DROPDOWN)
                    StreamBuilder<List<ScoreCriteriaModel>>(
                      stream: _criteriaService.getCriteriaStream(
                        type: _currentType,
                        onlyActive: true,
                      ),
                      builder: (context, snapshot) {
                        final rawList = snapshot.data ?? [];
                        // Deduplicate theo ID để đảm bảo 100% không bao giờ bị duplicate value assertion
                        final uniqueMap = <String, ScoreCriteriaModel>{};
                        for (final item in rawList) {
                          uniqueMap[item.id] = item;
                        }
                        final criteriaList = uniqueMap.values.toList();

                        // Kiểm tra an toàn xem id đã chọn có nằm trong danh sách hiện hành không
                        final hasMatchingItem = criteriaList
                            .any((c) => c.id == _selectedCriteriaId);
                        final currentVal =
                            hasMatchingItem ? _selectedCriteriaId : null;

                        // Đồng bộ _selectedCriteria nếu cần
                        if (currentVal != null && _selectedCriteria?.id != currentVal) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() {
                                _selectedCriteria = uniqueMap[currentVal];
                              });
                            }
                          });
                        }

                        return DropdownButtonFormField<String>(
                          key: ValueKey('criteria_picker_${_scoreTypeIndex}_${currentVal ?? "none"}'),
                          initialValue: currentVal,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: _isPlus
                                ? 'Chọn hành động cộng điểm *'
                                : 'Chọn vi phạm trừ điểm *',
                            prefixIcon: Icon(
                              _isPlus
                                  ? Icons.eco_rounded
                                  : Icons.warning_amber_rounded,
                              color: _isPlus
                                  ? AppColors.plusColor
                                  : AppColors.minusColor,
                            ),
                          ),
                          items: criteriaList
                              .map(
                                (c) => DropdownMenuItem<String>(
                                  value: c.id,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          c.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _isPlus
                                              ? AppColors.plusColorLight
                                              : AppColors.minusColorLight,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${_isPlus ? "+" : "-"}${c.points}đ',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: _isPlus
                                                ? AppColors.plusColor
                                                : AppColors.minusColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedCriteriaId = val;
                              _selectedCriteria =
                                  val != null ? uniqueMap[val] : null;
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // 4. KHUNG XEM TRƯỚC MỨC ĐIỂM TỰ ĐỘNG ÁP DỤNG (KHÔNG CẦN NHẬP TỰ DO)
                    if (_selectedCriteria != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _isPlus
                              ? AppColors.plusColorLight.withValues(alpha: 0.6)
                              : AppColors.minusColorLight.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _isPlus
                                ? const Color(0xFF86EFAC)
                                : const Color(0xFFFECACA),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: _isPlus
                                  ? AppColors.plusColor
                                  : AppColors.minusColor,
                              child: Icon(
                                _isPlus ? Icons.add_rounded : Icons.remove_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isPlus
                                        ? 'Mức điểm thưởng tự động:'
                                        : 'Mức điểm trừ tự động:',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _selectedCriteria!.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (_selectedCriteria!.description.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      _selectedCriteria!.description,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: _isPlus
                                    ? AppColors.plusColor
                                    : AppColors.minusColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_isPlus ? "+" : "-"}${_selectedCriteria!.points}đ',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 5. GHI CHÚ BỔ SUNG (TÙY CHỌN)
                    TextFormField(
                      controller: _noteCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú / Chi tiết vi phạm hoặc tuyên dương (Tùy chọn)',
                        hintText: 'Ví dụ: Dãy phòng A, tổ 2 quên tắt quạt khi ra về...',
                        prefixIcon: Icon(Icons.edit_note_rounded),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // NÚT LƯU PHIẾU
                    FilledButton.icon(
                      onPressed: _isSaving
                          ? null
                          : () async {
                              if (_selectedClassName == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Vui lòng chọn lớp học!'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                                return;
                              }

                              if (_selectedCriteria == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      _isPlus
                                          ? 'Vui lòng chọn hành động cộng điểm!'
                                          : 'Vui lòng chọn lỗi vi phạm trừ điểm!',
                                    ),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                                return;
                              }

                              final pts = _selectedCriteria!.points;

                              setState(() => _isSaving = true);
                              try {
                                await _recordService.addRecord(
                                  classId: _selectedClassName!,
                                  className: _selectedClassName!,
                                  criteriaId: _selectedCriteria!.id,
                                  criteriaTitle: _selectedCriteria!.title,
                                  type: _currentType,
                                  points: pts,
                                  recordedByUid: widget.userUid,
                                  recordedByEmail: widget.userEmail,
                                  recordedByName: widget.userName,
                                  note: _noteCtrl.text.trim(),
                                );

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Đã ${_isPlus ? "cộng" : "trừ"} $pts điểm cho Lớp $_selectedClassName thành công!',
                                      ),
                                      backgroundColor: _isPlus
                                          ? AppColors.plusColor
                                          : AppColors.minusColor,
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
                                  setState(() => _isSaving = false);
                                }
                              }
                            },
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_rounded),
                      label: Text(
                        _isSaving
                            ? 'Đang Lưu...'
                            : (_isPlus
                                ? 'Xác Nhận Cộng Điểm Cho Lớp'
                                : 'Xác Nhận Trừ Điểm Lớp'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: _isPlus ? AppColors.plusColor : AppColors.minusColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
