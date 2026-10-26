import 'package:cloud_firestore/cloud_firestore.dart';

class ScoreRecordModel {
  final String id;
  final String classId;
  final String className;
  final int grade;
  final String criteriaId;
  final String criteriaTitle;
  final String type; // 'plus' hoặc 'minus'
  final int points;
  final String recordedByUid;
  final String recordedByEmail;
  final String recordedByName;
  final String note;
  final int weekNumber;
  final int month;
  final int year;
  final DateTime? createdAt;

  const ScoreRecordModel({
    required this.id,
    required this.classId,
    required this.className,
    required this.grade,
    required this.criteriaId,
    required this.criteriaTitle,
    required this.type,
    required this.points,
    required this.recordedByUid,
    required this.recordedByEmail,
    required this.recordedByName,
    this.note = '',
    required this.weekNumber,
    required this.month,
    required this.year,
    this.createdAt,
  });

  bool get isPlus => type == 'plus';
  bool get isMinus => type == 'minus';

  factory ScoreRecordModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final cleanClassName = (data['className'] as String? ?? '').trim().toUpperCase();

    int parsedGrade = (data['grade'] as num?)?.toInt() ?? 0;
    if (parsedGrade == 0 && cleanClassName.isNotEmpty) {
      parsedGrade = int.tryParse(cleanClassName[0]) ?? 0;
    }

    return ScoreRecordModel(
      id: doc.id,
      classId: data['classId'] as String? ?? cleanClassName,
      className: cleanClassName,
      grade: parsedGrade,
      criteriaId: data['criteriaId'] as String? ?? '',
      criteriaTitle: data['criteriaTitle'] as String? ?? '',
      type: data['type'] as String? ?? 'plus',
      points: (data['points'] as num?)?.toInt() ?? 0,
      recordedByUid: data['recordedByUid'] as String? ?? '',
      recordedByEmail: data['recordedByEmail'] as String? ?? '',
      recordedByName: data['recordedByName'] as String? ?? '',
      note: data['note'] as String? ?? '',
      weekNumber: (data['weekNumber'] as num?)?.toInt() ?? 1,
      month: (data['month'] as num?)?.toInt() ?? (createdAt?.month ?? 1),
      year: (data['year'] as num?)?.toInt() ?? (createdAt?.year ?? DateTime.now().year),
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'classId': classId,
      'className': className,
      'grade': grade,
      'criteriaId': criteriaId,
      'criteriaTitle': criteriaTitle,
      'type': type,
      'points': points,
      'recordedByUid': recordedByUid,
      'recordedByEmail': recordedByEmail,
      'recordedByName': recordedByName,
      'note': note,
      'weekNumber': weekNumber,
      'month': month,
      'year': year,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
