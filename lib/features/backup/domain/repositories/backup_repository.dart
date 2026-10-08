import '../entities/backup_summary.dart';

abstract interface class BackupRepository {
  /// ข้อมูลทั้งหมดในเครื่อง (โปรไฟล์ บันทึกการกิน วัตถุดิบที่เก็บไว้) เป็น JSON
  String exportJson({DateTime? now});

  /// ตรวจไฟล์สำรองโดยยังไม่เขียนทับข้อมูล
  ///
  /// throw [InvalidBackupException] ถ้าไฟล์ใช้ไม่ได้
  BackupSummary inspect(String json);

  /// แทนที่ข้อมูลทั้งหมดในเครื่องด้วยข้อมูลจากไฟล์สำรอง
  ///
  /// throw [InvalidBackupException] ถ้าไฟล์ใช้ไม่ได้ (ข้อมูลเดิมไม่ถูกแตะ)
  Future<void> restore(String json);
}
