import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/responsive_container.dart';
import '../../../auth/services/auth_service.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../widgets/lead_teacher_history_tab.dart';
import '../widgets/record_score_sheet.dart';
import '../widgets/school_statistics_leaderboard_view.dart';

class LeadTeacherDashboardScreen extends StatefulWidget {
  const LeadTeacherDashboardScreen({super.key});

  @override
  State<LeadTeacherDashboardScreen> createState() =>
      _LeadTeacherDashboardScreenState();
}

class _LeadTeacherDashboardScreenState
    extends State<LeadTeacherDashboardScreen> {
  final AuthService _authService = AuthService();
  int _currentTabIndex = 0; // 0 = Thống Kê & Xếp Hạng, 1 = Nhật Ký Toàn Trường

  void _showRecordScoreSheet(
    BuildContext context, {
    required String userUid,
    required String userEmail,
    required String userName,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RecordScoreSheet(
        userUid: userUid,
        userEmail: userEmail,
        userName: userName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email ?? '';
    final userUid = user?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.surfaceVariant,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          _currentTabIndex == 0 ? 'Thống Kê & Xếp Hạng' : 'Nhật Ký Chấm Điểm',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Hồ sơ cá nhân',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () => _authService.signOut(),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTabIndex,
        onDestinationSelected: (index) =>
            setState(() => _currentTabIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.leaderboard_outlined),
            selectedIcon: Icon(Icons.leaderboard_rounded),
            label: 'Xếp Hạng & Thống Kê',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Nhật Ký',
          ),
        ],
      ),
      floatingActionButton: StreamBuilder<DocumentSnapshot>(
        stream: user != null
            ? FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots()
            : null,
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final userName = data?['fullName'] as String? ?? userEmail.split('@').first;

          return FloatingActionButton.extended(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_task_rounded),
            label: const Text(
              'Chấm Điểm Lớp',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () => _showRecordScoreSheet(
              context,
              userUid: userUid,
              userEmail: userEmail,
              userName: userName,
            ),
          );
        },
      ),
      body: ResponsiveContainer(
        maxWidth: 900,
        child: _currentTabIndex == 0
            ? const SchoolStatisticsLeaderboardView()
            : const LeadTeacherHistoryTab(),
      ),
    );
  }
}
