import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/date_utils_helper.dart';
import '../models/score_record_model.dart';

class ScoreRecordService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _recordsCollection =>
      _firestore.collection('score_records');

  /// Thêm một phiếu chấm điểm mới (Cộng hoặc Trừ điểm cho lớp)
  Future<DocumentReference> addRecord({
    required String classId,
    required String className,
    int? grade,
    required String criteriaId,
    required String criteriaTitle,
    required String type, // 'plus' hoặc 'minus'
    required int points,
    required String recordedByUid,
    required String recordedByEmail,
    required String recordedByName,
    String note = '',
    DateTime? recordDate,
  }) async {
    final cleanClassName = className.trim().toUpperCase();
    final date = recordDate ?? DateTime.now();
    final parsedGrade = grade ?? (int.tryParse(cleanClassName[0]) ?? 6);
    final weekNum = DateUtilsHelper.getWeekNumber(date);

    final recordMap = {
      'classId': classId.trim(),
      'className': cleanClassName,
      'grade': parsedGrade,
      'criteriaId': criteriaId,
      'criteriaTitle': criteriaTitle.trim(),
      'type': type,
      'points': points,
      'recordedByUid': recordedByUid,
      'recordedByEmail': recordedByEmail.trim(),
      'recordedByName': recordedByName.trim(),
      'note': note.trim(),
      'weekNumber': weekNum,
      'month': date.month,
      'year': date.year,
      'createdAt': Timestamp.fromDate(date),
    };

    return await _recordsCollection.add(recordMap);
  }

  /// Stream danh sách phiếu chấm điểm mới nhất
  Stream<List<ScoreRecordModel>> getRecentRecordsStream({int limit = 50}) {
    return _recordsCollection
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((d) => ScoreRecordModel.fromFirestore(d)).toList());
  }

  /// Stream danh sách phiếu chấm điểm của một lớp cụ thể (Không đòi hỏi composite index)
  Stream<List<ScoreRecordModel>> getRecordsByClassStream(String className) {
    final cleanName = className.trim().toUpperCase();
    final variants = {
      cleanName,
      cleanName.toLowerCase(),
      className.trim(),
    }.toList();

    return _recordsCollection
        .where('className', whereIn: variants)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ScoreRecordModel.fromFirestore(doc))
          .toList();

      // Sắp xếp thời gian giảm dần (mới nhất lên đầu)
      list.sort((a, b) {
        final aTime = a.createdAt;
        final bTime = b.createdAt;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  /// Stream danh sách phiếu chấm điểm theo khoảng thời gian (dùng cho Thống kê & Xếp hạng)
  Stream<List<ScoreRecordModel>> getRecordsByDateRangeStream({
    required DateTime start,
    required DateTime end,
  }) {
    return _recordsCollection
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((d) => ScoreRecordModel.fromFirestore(d)).toList());
  }

  /// Sửa phiếu chấm điểm
  Future<void> updateRecord({
    required String recordId,
    required int points,
    required String note,
  }) async {
    await _recordsCollection.doc(recordId).update({
      'points': points,
      'note': note.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Xóa phiếu chấm điểm
  Future<void> deleteRecord(String recordId) async {
    await _recordsCollection.doc(recordId).delete();
  }
}
