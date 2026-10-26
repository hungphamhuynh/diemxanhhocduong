import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/user_role.dart';
import '../../../core/network/network_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final hasNet = await NetworkService.isConnected();
    if (!hasNet) {
      throw const SocketException('Chưa kết nối mạng! Vui lòng kiểm tra Wi-Fi hoặc 4G/5G.');
    }

    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Stream<UserRole> getUserRoleStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return UserRole.leadTeacher;
      final data = doc.data();
      final roleStr = data?['role'] as String?;
      return UserRole.fromString(roleStr);
    });
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}

class SocketException implements Exception {
  final String message;
  const SocketException(this.message);

  @override
  String toString() => message;
}
