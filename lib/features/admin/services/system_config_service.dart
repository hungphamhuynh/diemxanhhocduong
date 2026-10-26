import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/system_config_model.dart';

class SystemConfigService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference get _configRef =>
      _firestore.collection('system_settings').doc('app_config');

  Stream<SystemConfigModel> getConfigStream() {
    return _configRef.snapshots().map((doc) => SystemConfigModel.fromFirestore(doc));
  }

  Future<SystemConfigModel> getConfig() async {
    try {
      final doc = await _configRef.get();
      if (!doc.exists) {
        final initial = SystemConfigModel(
          baseScore: AppConstants.defaultBaseScore,
          academicYear: '2026-2027',
          updatedAt: DateTime.now(),
        );
        await _configRef.set(initial.toMap(), SetOptions(merge: true));
        return initial;
      }
      return SystemConfigModel.fromFirestore(doc);
    } catch (_) {
      return const SystemConfigModel(
        baseScore: AppConstants.defaultBaseScore,
        academicYear: '2026-2027',
      );
    }
  }

  /// Cập nhật Điểm Gốc (Base Score) linh hoạt (Ví dụ: từ 100 thành 120...)
  Future<void> updateBaseScore(int newBaseScore) async {
    if (newBaseScore <= 0) {
      throw Exception('Điểm gốc xuất phát phải lớn hơn 0!');
    }
    await _configRef.set({
      'baseScore': newBaseScore,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Cập nhật Năm học
  Future<void> updateAcademicYear(String academicYear) async {
    await _configRef.set({
      'academicYear': academicYear.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
