import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Model representing a news ticker banner (text-based announcements)
class BannerModel extends Equatable {
  final String id;
  final String text;           // النص الذي سيظهر في الشريط
  final String? iconUrl;       // أيقونة اختيارية
  final String? actionUrl;     // رابط اختياري عند النقر
  final String priority;       // أولوية العرض: high, medium, low
  final DateTime? expiryDate;  // تاريخ انتهاء الإعلان

  const BannerModel({
    required this.id,
    required this.text,
    this.iconUrl,
    this.actionUrl,
    this.priority = 'medium',
    this.expiryDate,
  });

  /// Create model from Firestore document
  factory BannerModel.fromFirestore(Map<String, dynamic> doc, String id) {
    return BannerModel(
      id: id,
      text: doc['text'] as String? ?? '',
      iconUrl: doc['iconUrl'] as String?,
      actionUrl: doc['actionUrl'] as String?,
      priority: doc['priority'] as String? ?? 'medium',
      expiryDate: doc['expiryDate'] != null
          ? (doc['expiryDate'] as Timestamp).toDate()
          : null,
    );
  }

  /// Check if banner is still valid (not expired)
  bool get isValid {
    if (expiryDate == null) return true;
    return DateTime.now().isBefore(expiryDate!);
  }

  /// Get priority weight for sorting
  int get priorityWeight {
    switch (priority) {
      case 'high':
        return 3;
      case 'medium':
        return 2;
      case 'low':
        return 1;
      default:
        return 2;
    }
  }

  @override
  List<Object?> get props => [id, text, iconUrl, actionUrl, priority, expiryDate];
}