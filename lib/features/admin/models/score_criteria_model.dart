import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ScoreCriteriaModel {
  final String id;
  final String type; // 'plus' (Cộng điểm) hoặc 'minus' (Trừ điểm)
  final String title;
  final int points;
  final String description;
  final String iconName;
  final bool isActive;
  final DateTime? createdAt;

  const ScoreCriteriaModel({
    required this.id,
    required this.type,
    required this.title,
    required this.points,
    this.description = '',
    this.iconName = 'eco',
    this.isActive = true,
    this.createdAt,
  });

  bool get isPlus => type == 'plus';
  bool get isMinus => type == 'minus';

  factory ScoreCriteriaModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ScoreCriteriaModel(
      id: doc.id,
      type: data['type'] as String? ?? 'plus',
      title: data['title'] as String? ?? '',
      points: (data['points'] as num?)?.toInt() ?? 1,
      description: data['description'] as String? ?? '',
      iconName: data['iconName'] as String? ?? 'eco',
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'title': title,
      'points': points,
      'description': description,
      'iconName': iconName,
      'isActive': isActive,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  IconData get iconData {
    if (isPlus) {
      switch (iconName) {
        case 'clean':
          return Icons.cleaning_services_rounded;
        case 'plant':
          return Icons.yard_rounded;
        case 'light':
          return Icons.lightbulb_rounded;
        case 'award':
          return Icons.emoji_events_rounded;
        case 'eco':
        default:
          return Icons.eco_rounded;
      }
    } else {
      switch (iconName) {
        case 'fan':
          return Icons.mode_fan_off_rounded;
        case 'light':
          return Icons.lightbulb_outline_rounded;
        case 'trash':
          return Icons.delete_outline_rounded;
        case 'late':
          return Icons.alarm_off_rounded;
        case 'noise':
          return Icons.volume_off_rounded;
        default:
          return Icons.warning_amber_rounded;
      }
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScoreCriteriaModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
