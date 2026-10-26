import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/score_criteria_model.dart';

class ScoreCriteriaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _criteriaCollection =>
      _firestore.collection('score_criteria');

  /// Stream danh sách tiêu chí (có thể lọc theo 'plus' hoặc 'minus')
  Stream<List<ScoreCriteriaModel>> getCriteriaStream({
    String? type,
    bool onlyActive = false,
  }) {
    Query query = _criteriaCollection;
    if (type != null && type.isNotEmpty) {
      query = query.where('type', isEqualTo: type);
    }
    return query.snapshots().map((snapshot) {
      var list = snapshot.docs
          .map((doc) => ScoreCriteriaModel.fromFirestore(doc))
          .toList();
      if (onlyActive) {
        list = list.where((c) => c.isActive).toList();
      }
      list.sort((a, b) => a.title.compareTo(b.title));
      return list;
    });
  }

  /// Thêm tiêu chí mới
  Future<void> createCriteria({
    required String type, // 'plus' hoặc 'minus'
    required String title,
    required int points,
    String description = '',
    String iconName = 'eco',
  }) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      throw Exception('Tên tiêu chí không được để trống!');
    }
    if (points <= 0) {
      throw Exception('Số điểm phải lớn hơn 0!');
    }

    await _criteriaCollection.add({
      'type': type,
      'title': cleanTitle,
      'points': points,
      'description': description.trim(),
      'iconName': iconName,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Cập nhật tiêu chí
  Future<void> updateCriteria({
    required String id,
    required String title,
    required int points,
    String description = '',
    String iconName = 'eco',
  }) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      throw Exception('Tên tiêu chí không được để trống!');
    }
    if (points <= 0) {
      throw Exception('Số điểm phải lớn hơn 0!');
    }

    await _criteriaCollection.doc(id).update({
      'title': cleanTitle,
      'points': points,
      'description': description.trim(),
      'iconName': iconName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Bật / Tắt tiêu chí
  Future<void> toggleCriteriaActive({
    required String id,
    required bool currentIsActive,
  }) async {
    await _criteriaCollection.doc(id).update({
      'isActive': !currentIsActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Xóa tiêu chí
  Future<void> deleteCriteria(String id) async {
    await _criteriaCollection.doc(id).delete();
  }

  /// Khởi tạo danh mục tiêu chí mẫu ban đầu nếu trống
  Future<void> seedDefaultCriteria() async {
    final snap = await _criteriaCollection.limit(1).get();
    if (snap.docs.isNotEmpty) return;

    final defaultItems = [
      // MỤC CỘNG ĐIỂM (+)
      {
        'type': 'plus',
        'title': 'Chăm sóc tốt bồn hoa / Công trình măng non',
        'points': 5,
        'description': 'Bồn hoa phân công cho lớp luôn xanh tốt, nhổ sạch cỏ dại, không có rác',
        'iconName': 'plant',
      },
      {
        'type': 'plus',
        'title': 'Lớp học Xanh - Sạch - Đẹp tiêu biểu trong tuần',
        'points': 5,
        'description': 'Phòng học sạch bóng, bàn ghế ngay ngắn, có góc cây xanh chăm sóc tươi tốt',
        'iconName': 'clean',
      },
      {
        'type': 'plus',
        'title': 'Thực hành tiết kiệm điện tốt trong lớp học',
        'points': 3,
        'description': 'Chủ động mở cửa đón gió và ánh sáng tự nhiên, tắt bớt đèn quạt không cần thiết',
        'iconName': 'light',
      },
      {
        'type': 'plus',
        'title': 'Chi đội chủ động ra quân dọn dẹp mảng xanh trường',
        'points': 5,
        'description': 'Lớp tích cực tham gia tổng vệ sinh bồn cây, vườn trường, khuôn viên chung',
        'iconName': 'eco',
      },
      {
        'type': 'plus',
        'title': 'Đạt giải phong trào Môi trường / Sáng tạo Xanh',
        'points': 10,
        'description': 'Chi đội đạt giải phong trào làm sản phẩm tái chế, báo tường, thời trang xanh cấp trường',
        'iconName': 'award',
      },

      // MỤC TRỪ ĐIỂM (-)
      {
        'type': 'minus',
        'title': 'Sử dụng điện lãng phí / Quên tắt thiết bị điện',
        'points': 3,
        'description': 'Quên tắt quạt, đèn, tivi khi ra khỏi lớp hoặc bật lãng phí khi đủ ánh sáng tự nhiên',
        'iconName': 'fan',
      },
      {
        'type': 'minus',
        'title': 'Để rác trong hộc bàn / góc lớp',
        'points': 5,
        'description': 'Hộc bàn có vỏ hộp sữa, túi bánh kẹo, rác ăn vặt nhét bừa bãi',
        'iconName': 'trash',
      },
      {
        'type': 'minus',
        'title': 'Không đổ rác cuối ngày / Phòng học chưa trực nhật',
        'points': 3,
        'description': 'Tan học không quét dọn, để sọt rác đầy ứ qua đêm trong lớp gây mùi',
        'iconName': 'trash',
      },
      {
        'type': 'minus',
        'title': 'Vứt rác bừa bãi trước cửa lớp / hành lang',
        'points': 3,
        'description': 'Khu vực hành lang, trước cửa lớp có rác thải, vỏ chai, túi nilon không được quét dọn',
        'iconName': 'trash',
      },
      {
        'type': 'minus',
        'title': 'Xâm hại cây xanh / Giẫm bồn hoa, bẻ cành',
        'points': 5,
        'description': 'Học sinh của lớp bị bắt gặp giẫm đạp bồn hoa, ngắt hoa, bẻ cành cây của trường',
        'iconName': 'warning',
      },
    ];

    final batch = _firestore.batch();
    for (final item in defaultItems) {
      final docRef = _criteriaCollection.doc();
      batch.set(docRef, {
        ...item,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}
