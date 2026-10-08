import '../entities/food_entry.dart';

abstract interface class FoodLogRepository {
  /// ทุกรายการที่เคยบันทึก ใช้แสดงประวัติย้อนหลัง
  Future<List<FoodEntry>> getAll();

  Future<List<FoodEntry>> getEntriesOn(DateTime day);

  Future<void> add(FoodEntry entry);

  Future<void> remove(String id);
}
