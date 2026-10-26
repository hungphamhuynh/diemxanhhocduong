import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/string_utils.dart';
import '../models/school_class_model.dart';

class AdminClassService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _classesCollection =>
      _firestore.collection('classes');

  /// Stream danh sách tất cả các lớp học realtime
  Stream<List<SchoolClassModel>> getClassesStream({bool onlyActive = false}) {
    return _classesCollection.snapshots().map((snapshot) {
      var list = snapshot.docs
          .map((doc) => SchoolClassModel.fromFirestore(doc))
          .toList();
      if (onlyActive) {
        list = list.where((c) => c.isActive).toList();
      }
      list.sort((a, b) => StringUtils.compareNatural(a.className, b.className));
      return list;
    });
  }

  /// Thêm lớp học mới linh hoạt (ví dụ: 6A8, 7A8, 10A1...)
  Future<void> createClass({
    required String className,
    int? grade,
  }) async {
    final cleanName = className.trim().toUpperCase();
    if (cleanName.isEmpty) {
      throw Exception('Tên lớp không được để trống!');
    }

    final parsedGrade = grade ?? (int.tryParse(cleanName[0]) ?? 6);

    // Kiểm tra xem lớp đã tồn tại chưa
    final existingDoc = await _classesCollection.doc(cleanName).get();
    if (existingDoc.exists) {
      throw Exception('Lớp $cleanName đã tồn tại trong danh sách!');
    }

    await _classesCollection.doc(cleanName).set({
      'className': cleanName,
      'grade': parsedGrade,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Cập nhật tên lớp hoặc khối
  Future<void> updateClass({
    required String classId,
    required String newClassName,
    required int grade,
  }) async {
    final cleanName = newClassName.trim().toUpperCase();
    if (cleanName.isEmpty) {
      throw Exception('Tên lớp không được để trống!');
    }

    await _classesCollection.doc(classId).update({
      'className': cleanName,
      'grade': grade,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Bật / Tắt trạng thái hoạt động của lớp
  Future<void> toggleClassActive({
    required String classId,
    required bool currentIsActive,
  }) async {
    await _classesCollection.doc(classId).update({
      'isActive': !currentIsActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Xóa lớp học
  Future<void> deleteClass(String classId) async {
    await _classesCollection.doc(classId).delete();
  }

  /// Khởi tạo sẵn 36 lớp học chuẩn của trường THCS Nguyễn Thị Hương nếu chưa có
  Future<int> seedDefault36Classes() async {
    final existing = await _classesCollection.limit(1).get();
    if (existing.docs.isNotEmpty) {
      return 0; // Đã có dữ liệu, không ghi đè
    }

    final defaultClasses = <String>[
      // Khối 6: 6A1 - 6A7 (7 lớp)
      '6A1', '6A2', '6A3', '6A4', '6A5', '6A6', '6A7',
      // Khối 7: 7A1 - 7A7 (7 lớp)
      '7A1', '7A2', '7A3', '7A4', '7A5', '7A6', '7A7',
      // Khối 8: 8A1 - 8A10 (10 lớp)
      '8A1', '8A2', '8A3', '8A4', '8A5', '8A6', '8A7', '8A8', '8A9', '8A10',
      // Khối 9: 9A1 - 9A12 (12 lớp)
      '9A1', '9A2', '9A3', '9A4', '9A5', '9A6', '9A7', '9A8', '9A9', '9A10', '9A11', '9A12',
    ];

    final batch = _firestore.batch();
    for (final cls in defaultClasses) {
      final grade = int.parse(cls[0]);
      final docRef = _classesCollection.doc(cls);
      batch.set(docRef, {
        'className': cls,
        'grade': grade,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    return defaultClasses.length;
  }
}
