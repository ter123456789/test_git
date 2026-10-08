import '../../domain/entities/food_entry.dart';
import '../../domain/repositories/food_log_repository.dart';
import '../datasources/nutrition_local_data_source.dart';
import '../models/nutrition_models.dart';

class FoodLogRepositoryImpl implements FoodLogRepository {
  const FoodLogRepositoryImpl(this._local);

  final NutritionLocalDataSource _local;

  @override
  Future<List<FoodEntry>> getEntriesOn(DateTime day) async => _readAll()
      .where(
        (e) =>
            e.eatenAt.year == day.year &&
            e.eatenAt.month == day.month &&
            e.eatenAt.day == day.day,
      )
      .toList();

  @override
  Future<void> add(FoodEntry entry) => _writeAll([..._readAll(), entry]);

  @override
  Future<void> remove(String id) =>
      _writeAll(_readAll().where((e) => e.id != id).toList());

  List<FoodEntry> _readAll() =>
      _local.readFoodLog().map(NutritionModels.entryFromJson).toList();

  Future<void> _writeAll(List<FoodEntry> entries) =>
      _local.writeFoodLog(entries.map(NutritionModels.entryToJson).toList());
}
