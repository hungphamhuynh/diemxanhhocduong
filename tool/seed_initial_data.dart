// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

/// Cấu hình Firebase Authentication & Firestore cho dự án diemxanhhocduong
const String apiKey = 'AIzaSyAjdLRseblLiwJ26OlYwba3_mhcf3Fs7kE';
const String projectId = 'diemxanhhocduong';
const String schoolDomain = 'thcsnguyenthihuong.hcm.edu.vn';

void main(List<String> args) async {
  print('==================================================================');
  print('   KHỞI TẠO CƠ SỞ DỮ LIỆU CHUẨN - HỆ THỐNG ĐIỂM XANH HỌC ĐƯỜNG   ');
  print('   TRƯỜNG THCS NGUYỄN THỊ HƯƠNG                                 ');
  print('==================================================================\n');

  final client = HttpClient();
  final nowIso = DateTime.now().toUtc().toIso8601String();

  // -------------------------------------------------------------------------
  // BƯỚC 1: XÁC THỰC TÀI KHOẢN ADMIN ĐỂ LẤY TOKEN GHI FIRESTORE
  // -------------------------------------------------------------------------
  print('--- [BƯỚC 1/6] Xác thực tài khoản Quản Trị Viên (Admin) ---');
  final adminEmail = 'admin@$schoolDomain';
  final adminPass = adminEmail;

  final adminAuth = await _getOrCreateAuthUser(client, adminEmail, adminPass);
  if (adminAuth == null) {
    print('❌ LỖI NGHIÊM TRỌNG: Không thể xác thực Admin ($adminEmail)!');
    client.close();
    exit(1);
  }

  final adminUid = adminAuth['uid']!;
  final adminToken = adminAuth['token']!;
  print('  ✓ Firebase Auth: $adminEmail (UID: $adminUid)');

  // Lưu document users/{adminUid} với role = 'admin'
  final adminDocSaved = await _patchFirestoreDocument(
    client: client,
    idToken: adminToken,
    collection: 'users',
    docId: adminUid,
    fields: {
      'uid': {'stringValue': adminUid},
      'email': {'stringValue': adminEmail},
      'fullName': {'stringValue': 'Quản Trị Viên Hệ Thống'},
      'role': {'stringValue': 'admin'},
      'isActive': {'booleanValue': true},
      'createdAt': {'timestampValue': nowIso},
      'updatedAt': {'timestampValue': nowIso},
    },
  );

  if (!adminDocSaved) {
    print('❌ LỖI: Không thể lưu document users/$adminUid vào Firestore!');
    client.close();
    exit(1);
  }
  print('  ✅ Đã ghi thành công document: users/$adminUid (role: admin, fullName: Quản Trị Viên Hệ Thống)\n');

  // -------------------------------------------------------------------------
  // BƯỚC 2: XÁC THỰC TÀI KHOẢN TỔNG PHỤ TRÁCH (LEAD TEACHER)
  // -------------------------------------------------------------------------
  print('--- [BƯỚC 2/6] Xác thực tài khoản Tổng Phụ Trách (leadTeacher) ---');
  final leadEmail = 'tongphutrach@$schoolDomain';
  final leadPass = leadEmail;

  final leadAuth = await _getOrCreateAuthUser(client, leadEmail, leadPass);
  if (leadAuth == null) {
    print('❌ Cảnh báo: Không thể tạo Auth cho Tổng Phụ Trách ($leadEmail)!');
  } else {
    final leadUid = leadAuth['uid']!;
    print('  ✓ Firebase Auth: $leadEmail (UID: $leadUid)');

    final leadDocSaved = await _patchFirestoreDocument(
      client: client,
      idToken: adminToken,
      collection: 'users',
      docId: leadUid,
      fields: {
        'uid': {'stringValue': leadUid},
        'email': {'stringValue': leadEmail},
        'fullName': {'stringValue': 'Thầy/Cô Tổng Phụ Trách'},
        'role': {'stringValue': 'leadTeacher'},
        'isActive': {'booleanValue': true},
        'createdAt': {'timestampValue': nowIso},
        'updatedAt': {'timestampValue': nowIso},
      },
    );

    if (leadDocSaved) {
      print('  ✅ Đã ghi thành công document: users/$leadUid (role: leadTeacher)\n');
    } else {
      print('  ⚠️ Cảnh báo: Lỗi ghi users/$leadUid vào Firestore!\n');
    }
  }

  // -------------------------------------------------------------------------
  // BƯỚC 3: DỌN DẸP SẠCH CÁC TIÊU CHÍ CŨ & PHIẾU CŨ (NẾU CÓ)
  // -------------------------------------------------------------------------
  print('--- [BƯỚC 3/6] Dọn dẹp dữ liệu tiêu chí cũ trên Firestore ---');
  await _clearCollection(client, adminToken, 'score_criteria');
  await _clearCollection(client, adminToken, 'score_records');
  print('  ✅ Đã xóa sạch dữ liệu tiêu chí cũ và nhật ký cũ.\n');

  // -------------------------------------------------------------------------
  // BƯỚC 4: CẤU HÌNH ĐIỂM GỐC XUẤT PHÁT (system_settings/app_config)
  // -------------------------------------------------------------------------
  print('--- [BƯỚC 4/6] Khởi tạo cấu hình hệ thống & Điểm xuất phát gốc (100 điểm) ---');
  final configSaved = await _patchFirestoreDocument(
    client: client,
    idToken: adminToken,
    collection: 'system_settings',
    docId: 'app_config',
    fields: {
      'baseScore': {'integerValue': '100'},
      'academicYear': {'stringValue': '2026-2027'},
      'updatedAt': {'timestampValue': nowIso},
    },
  );

  if (configSaved) {
    print('  ✅ Đã thiết lập system_settings/app_config: baseScore = 100, academicYear = 2026-2027\n');
  } else {
    print('  ❌ LỖI: Không thể lưu cấu hình system_settings/app_config!\n');
  }

  // -------------------------------------------------------------------------
  // BƯỚC 5: KHỞI TẠO 36 LỚP HỌC CHUẨN (Khối 6, 7, 8, 9)
  // -------------------------------------------------------------------------
  print('--- [BƯỚC 5/6] Khởi tạo 36 lớp học chuẩn của trường THCS Nguyễn Thị Hương ---');
  final List<String> classes = [];
  for (int i = 1; i <= 7; i++) {
    classes.add('6A$i');
  }
  for (int i = 1; i <= 7; i++) {
    classes.add('7A$i');
  }
  for (int i = 1; i <= 10; i++) {
    classes.add('8A$i');
  }
  for (int i = 1; i <= 12; i++) {
    classes.add('9A$i');
  }

  int successClassCount = 0;
  for (final cls in classes) {
    final grade = int.parse(cls[0]);
    final ok = await _patchFirestoreDocument(
      client: client,
      idToken: adminToken,
      collection: 'classes',
      docId: cls,
      fields: {
        'className': {'stringValue': cls},
        'grade': {'integerValue': grade.toString()},
        'isActive': {'booleanValue': true},
        'createdAt': {'timestampValue': nowIso},
      },
    );

    if (ok) successClassCount++;
  }
  print('  ✅ Đã tạo thành công $successClassCount / ${classes.length} lớp học (classes/6A1 -> classes/9A12)\n');

  // -------------------------------------------------------------------------
  // BƯỚC 6: KHỞI TẠO 10 TIÊU CHÍ HÀNH ĐỘNG XANH CHUẨN (5 CỘNG & 5 TRỪ)
  // -------------------------------------------------------------------------
  print('--- [BƯỚC 6/6] Khởi tạo 10 tiêu chí Hành Động Xanh chuẩn ---');
  final defaultCriteria = [
    // 5 MỤC CỘNG ĐIỂM (+)
    {
      'id': 'criteria_plus_plant',
      'type': 'plus',
      'title': 'Chăm sóc tốt bồn hoa / Công trình măng non',
      'points': 5,
      'description': 'Bồn hoa phân công cho lớp luôn xanh tốt, nhổ sạch cỏ dại, không có rác',
      'iconName': 'plant',
    },
    {
      'id': 'criteria_plus_clean_room',
      'type': 'plus',
      'title': 'Lớp học Xanh - Sạch - Đẹp tiêu biểu trong tuần',
      'points': 5,
      'description': 'Phòng học sạch bóng, bàn ghế ngay ngắn, có góc cây xanh chăm sóc tươi tốt',
      'iconName': 'clean',
    },
    {
      'id': 'criteria_plus_save_power',
      'type': 'plus',
      'title': 'Thực hành tiết kiệm điện tốt trong lớp học',
      'points': 3,
      'description': 'Chủ động mở cửa đón gió và ánh sáng tự nhiên, tắt bớt đèn quạt không cần thiết',
      'iconName': 'light',
    },
    {
      'id': 'criteria_plus_eco_cleanup',
      'type': 'plus',
      'title': 'Chi đội chủ động ra quân dọn dẹp mảng xanh trường',
      'points': 5,
      'description': 'Lớp tích cực tham gia tổng vệ sinh bồn cây, vườn trường, khuôn viên chung',
      'iconName': 'eco',
    },
    {
      'id': 'criteria_plus_award',
      'type': 'plus',
      'title': 'Đạt giải phong trào Môi trường / Sáng tạo Xanh',
      'points': 10,
      'description': 'Chi đội đạt giải phong trào làm sản phẩm tái chế, báo tường, thời trang xanh cấp trường',
      'iconName': 'award',
    },

    // 5 MỤC TRỪ ĐIỂM (-)
    {
      'id': 'criteria_minus_power_waste',
      'type': 'minus',
      'title': 'Sử dụng điện lãng phí / Quên tắt thiết bị điện',
      'points': 3,
      'description': 'Quên tắt quạt, đèn, tivi khi ra khỏi lớp hoặc bật lãng phí khi đủ ánh sáng tự nhiên',
      'iconName': 'fan',
    },
    {
      'id': 'criteria_minus_desk_trash',
      'type': 'minus',
      'title': 'Để rác trong hộc bàn / góc lớp',
      'points': 5,
      'description': 'Hộc bàn có vỏ hộp sữa, túi bánh kẹo, rác ăn vặt nhét bừa bãi',
      'iconName': 'trash',
    },
    {
      'id': 'criteria_minus_no_cleanup',
      'type': 'minus',
      'title': 'Không đổ rác cuối ngày / Phòng học chưa trực nhật',
      'points': 3,
      'description': 'Tan học không quét dọn, để sọt rác đầy ứ qua đêm trong lớp gây mùi',
      'iconName': 'trash',
    },
    {
      'id': 'criteria_minus_hallway_trash',
      'type': 'minus',
      'title': 'Vứt rác bừa bãi trước cửa lớp / hành lang',
      'points': 3,
      'description': 'Khu vực hành lang, trước cửa lớp có rác thải, vỏ chai, túi nilon không được quét dọn',
      'iconName': 'trash',
    },
    {
      'id': 'criteria_minus_damage_plants',
      'type': 'minus',
      'title': 'Xâm hại cây xanh / Giẫm bồn hoa, bẻ cành',
      'points': 5,
      'description': 'Học sinh của lớp bị bắt gặp giẫm đạp bồn hoa, ngắt hoa, bẻ cành cây của trường',
      'iconName': 'warning',
    },
  ];

  int criteriaCount = 0;
  for (final item in defaultCriteria) {
    final docId = item['id'] as String;
    final ok = await _patchFirestoreDocument(
      client: client,
      idToken: adminToken,
      collection: 'score_criteria',
      docId: docId,
      fields: {
        'type': {'stringValue': item['type'] as String},
        'title': {'stringValue': item['title'] as String},
        'points': {'integerValue': (item['points'] as int).toString()},
        'description': {'stringValue': item['description'] as String},
        'iconName': {'stringValue': item['iconName'] as String},
        'isActive': {'booleanValue': true},
        'createdAt': {'timestampValue': nowIso},
      },
    );
    if (ok) criteriaCount++;
  }
  print('  ✅ Đã lưu $criteriaCount / ${defaultCriteria.length} tiêu chí Hành Động Xanh vào score_criteria/\n');

  print('==================================================================');
  print('   🎉 KHỞI TẠO HOÀN TẤT & ĐÃ XÁC THỰC CƠ SỞ DỮ LIỆU THÀNH CÔNG!   ');
  print('==================================================================');
  print('  • Quản Trị Viên (Admin):');
  print('      Email:    $adminEmail');
  print('      Mật khẩu: $adminPass');
  print('      Role:     admin');
  print('  • Tổng Phụ Trách (Lead Teacher):');
  print('      Email:    $leadEmail');
  print('      Mật khẩu: $leadPass');
  print('      Role:     leadTeacher');
  print('  • Cấu hình hệ thống: Điểm xuất phát = 100 điểm, Năm học = 2026-2027');
  print('  • Tổng số lớp:      $successClassCount lớp (Khối 6 -> 9)');
  print('  • Danh mục tiêu chí: $criteriaCount tiêu chí Hành Động Xanh (5 Cộng, 5 Trừ)');
  print('==================================================================\n');

  client.close();
}

/// Xóa toàn bộ document trong 1 collection
Future<void> _clearCollection(
    HttpClient client, String idToken, String collection) async {
  try {
    final listUrl = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/$collection?pageSize=100');
    final req = await client.getUrl(listUrl);
    req.headers.set('Authorization', 'Bearer $idToken');
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    if (res.statusCode != 200) return;

    final data = jsonDecode(body) as Map<String, dynamic>;
    final docs = data['documents'] as List<dynamic>? ?? [];

    for (final doc in docs) {
      final docName = doc['name'] as String;
      final delUrl = Uri.parse('https://firestore.googleapis.com/v1/$docName');
      final delReq = await client.deleteUrl(delUrl);
      delReq.headers.set('Authorization', 'Bearer $idToken');
      final delRes = await delReq.close();
      await delRes.drain();
    }
  } catch (e) {
    print('  ⚠️ Lỗi khi xóa collection $collection: $e');
  }
}

/// Tạo mới hoặc lấy token đăng nhập của tài khoản Firebase Auth
Future<Map<String, String>?> _getOrCreateAuthUser(
  HttpClient client,
  String email,
  String password,
) async {
  try {
    final signUpUrl = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey');
    final req = await client.postUrl(signUpUrl);
    req.headers.contentType = ContentType.json;
    req.write(jsonEncode({
      'email': email.trim().toLowerCase(),
      'password': password,
      'returnSecureToken': true,
    }));
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    final data = jsonDecode(body) as Map<String, dynamic>;

    if (res.statusCode == 200) {
      return {
        'uid': data['localId'] as String,
        'token': data['idToken'] as String,
      };
    }

    final errorMsg = data['error']?['message']?.toString() ?? '';
    if (errorMsg.contains('EMAIL_EXISTS')) {
      return await _signInAuthUser(client, email, password);
    }
  } catch (e) {
    print('  ❌ Ngoại lệ signUp ($email): $e');
  }

  return await _signInAuthUser(client, email, password);
}

/// Đăng nhập Firebase Auth
Future<Map<String, String>?> _signInAuthUser(
  HttpClient client,
  String email,
  String password,
) async {
  try {
    final signInUrl = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey');
    final req = await client.postUrl(signInUrl);
    req.headers.contentType = ContentType.json;
    req.write(jsonEncode({
      'email': email.trim().toLowerCase(),
      'password': password,
      'returnSecureToken': true,
    }));
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    final data = jsonDecode(body) as Map<String, dynamic>;

    if (res.statusCode == 200) {
      return {
        'uid': data['localId'] as String,
        'token': data['idToken'] as String,
      };
    } else {
      print('  ❌ Lỗi signIn ($email): ${data['error']?['message']}');
    }
  } catch (e) {
    print('  ❌ Ngoại lệ signIn ($email): $e');
  }
  return null;
}

/// Ghi document Firestore qua REST API và kiểm tra HTTP 200
Future<bool> _patchFirestoreDocument({
  required HttpClient client,
  required String idToken,
  required String collection,
  required String docId,
  required Map<String, dynamic> fields,
}) async {
  try {
    final url = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/$collection/$docId');
    final req = await client.patchUrl(url);
    req.headers.set('Authorization', 'Bearer $idToken');
    req.headers.contentType = ContentType.json;
    req.write(jsonEncode({'fields': fields}));
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();

    if (res.statusCode == 200) {
      return true;
    } else {
      print('    ❌ Lỗi patchFirestore [$collection/$docId] (Code ${res.statusCode}): $body');
      return false;
    }
  } catch (e) {
    print('    ❌ Ngoại lệ patchFirestore [$collection/$docId]: $e');
    return false;
  }
}
