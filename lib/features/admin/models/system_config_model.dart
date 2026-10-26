import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';

class SystemConfigModel {
  final int baseScore;
  final String academicYear;
  final DateTime? updatedAt;

  const SystemConfigModel({
    required this.baseScore,
    required this.academicYear,
    this.updatedAt,
  });

  factory SystemConfigModel.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists || doc.data() == null) {
      return const SystemConfigModel(
        baseScore: AppConstants.defaultBaseScore,
        academicYear: '2026-2027',
      );
    }
    final data = doc.data() as Map<String, dynamic>;
    return SystemConfigModel(
      baseScore: (data['baseScore'] as num?)?.toInt() ?? AppConstants.defaultBaseScore,
      academicYear: data['academicYear'] as String? ?? '2026-2027',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'baseScore': baseScore,
      'academicYear': academicYear,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
