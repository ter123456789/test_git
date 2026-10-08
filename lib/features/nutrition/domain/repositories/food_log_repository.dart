import '../entities/food_entry.dart';

abstract interface class FoodLogRepository {
  Future<List<FoodEntry>> getEntriesOn(DateTime day);

  Future<void> add(FoodEntry entry);

  Future<void> remove(String id);
}
