import 'package:cloud_firestore/cloud_firestore.dart';

class SchoolClassModel {
  final String id;
  final String className;
  final int grade;
  final bool isActive;
  final DateTime? createdAt;

  const SchoolClassModel({
    required this.id,
    required this.className,
    required this.grade,
    this.isActive = true,
    this.createdAt,
  });

  factory SchoolClassModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawName = data['className'] as String? ?? doc.id;
    final cleanName = rawName.trim().toUpperCase();

    // Tự động phân tích khối từ ký tự đầu tiên nếu chưa lưu field grade
    int parsedGrade = (data['grade'] as num?)?.toInt() ?? 0;
    if (parsedGrade == 0 && cleanName.isNotEmpty) {
      parsedGrade = int.tryParse(cleanName[0]) ?? 0;
    }

    return SchoolClassModel(
      id: doc.id,
      className: cleanName,
      grade: parsedGrade,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'className': className,
      'grade': grade,
      'isActive': isActive,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SchoolClassModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
