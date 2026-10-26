import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum UserRole {
  admin,
  leadTeacher;

  static UserRole fromString(String? role) {
    switch (role) {
      case 'admin':
        return UserRole.admin;
      case 'leadTeacher':
      default:
        return UserRole.leadTeacher;
    }
  }

  String get code {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.leadTeacher:
        return 'leadTeacher';
    }
  }

  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Quản Trị Viên';
      case UserRole.leadTeacher:
        return 'Tổng Phụ Trách';
    }
  }

  Color get color {
    switch (this) {
      case UserRole.admin:
        return AppColors.roleAdmin;
      case UserRole.leadTeacher:
        return AppColors.roleLeadTeacher;
    }
  }

  Color get lightColor {
    switch (this) {
      case UserRole.admin:
        return AppColors.roleAdminLight;
      case UserRole.leadTeacher:
        return AppColors.roleLeadTeacherLight;
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.admin:
        return Icons.admin_panel_settings_rounded;
      case UserRole.leadTeacher:
        return Icons.verified_user_rounded;
    }
  }
}
