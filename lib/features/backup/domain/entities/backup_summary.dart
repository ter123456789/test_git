import 'package:equatable/equatable.dart';

/// สิ่งที่อยู่ในไฟล์สำรอง ใช้แสดงให้ user ยืนยันก่อนนำเข้า
class BackupSummary extends Equatable {
  const BackupSummary({
    required this.exportedAt,
    required this.hasProfile,
    required this.entryCount,
    required this.dayCount,
    required this.ingredientCount,
  });

  final DateTime? exportedAt;
  final bool hasProfile;

  /// จำนวนรายการที่บันทึกการกิน
  final int entryCount;

  /// จำนวนวันที่มีการบันทึก
  final int dayCount;

  /// วัตถุดิบที่เพิ่มเองหรือเลือกจาก USDA
  final int ingredientCount;

  @override
  List<Object?> get props => [
    exportedAt,
    hasProfile,
    entryCount,
    dayCount,
    ingredientCount,
  ];
}

/// ไฟล์ไม่ใช่ไฟล์สำรองของแอปนี้ หรือข้อมูลข้างในเสียหาย
class InvalidBackupException implements Exception {
  const InvalidBackupException([this.detail]);

  final String? detail;

  @override
  String toString() => 'InvalidBackupException: $detail';
}
