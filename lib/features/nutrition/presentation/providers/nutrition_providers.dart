import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../../core/providers/shared_preferences_provider.dart';
import '../../data/datasources/nutrition_local_data_source.dart';
import '../../data/datasources/usda_remote_data_source.dart';
import '../../data/repositories/food_log_repository_impl.dart';
import '../../data/repositories/ingredient_repository_impl.dart';
import '../../domain/entities/food_entry.dart';
import '../../domain/entities/ingredient.dart';
import '../../domain/entities/nutrients.dart';
import '../../domain/entities/remote_search_result.dart';
import '../../domain/repositories/food_log_repository.dart';
import '../../domain/repositories/ingredient_repository.dart';

final _nutritionLocalDataSourceProvider = Provider(
  (ref) => NutritionLocalDataSource(ref.watch(sharedPreferencesProvider)),
);

/// ใช้ DEMO_KEY ได้เลย (จำกัดราว 10 ครั้ง/ชั่วโมง)
/// ถ้าโควตาไม่พอ สมัคร key ฟรีแล้วรันด้วย `--dart-define=USDA_API_KEY=...`
const _usdaApiKey = String.fromEnvironment(
  'USDA_API_KEY',
  defaultValue: 'DEMO_KEY',
);

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final _usdaRemoteDataSourceProvider = Provider(
  (ref) => UsdaRemoteDataSource(
    client: ref.watch(httpClientProvider),
    apiKey: _usdaApiKey,
  ),
);

final ingredientRepositoryProvider = Provider<IngredientRepository>(
  (ref) => IngredientRepositoryImpl(
    ref.watch(_nutritionLocalDataSourceProvider),
    ref.watch(_usdaRemoteDataSourceProvider),
  ),
);

final foodLogRepositoryProvider = Provider<FoodLogRepository>(
  (ref) => FoodLogRepositoryImpl(ref.watch(_nutritionLocalDataSourceProvider)),
);

String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

// ---------- วัตถุดิบ ----------

final ingredientsProvider =
    AsyncNotifierProvider<IngredientsNotifier, List<Ingredient>>(
      IngredientsNotifier.new,
    );

class IngredientsNotifier extends AsyncNotifier<List<Ingredient>> {
  @override
  Future<List<Ingredient>> build() =>
      ref.watch(ingredientRepositoryProvider).getAll();

  Future<Ingredient> addCustom({
    required String name,
    required Nutrients per100g,
  }) async {
    final ingredient = Ingredient(
      id: 'custom_${_newId()}',
      name: name,
      per100g: per100g,
      source: IngredientSource.custom,
    );
    await save(ingredient);
    return ingredient;
  }

  /// เก็บวัตถุดิบ (เช่น ที่เลือกจาก USDA) ไว้ในเครื่อง เพื่อค้นเจอแบบออฟไลน์
  Future<void> save(Ingredient ingredient) async {
    await ref.read(ingredientRepositoryProvider).save(ingredient);
    final current = state.value ?? const [];
    if (current.any((i) => i.id == ingredient.id)) return;
    state = AsyncData([...current, ingredient]);
  }
}

/// autoDispose เพื่อให้คำค้นหาล้างเองเมื่อออกจากหน้าเลือกวัตถุดิบ
final ingredientQueryProvider =
    NotifierProvider.autoDispose<IngredientQuery, String>(IngredientQuery.new);

class IngredientQuery extends Notifier<String> {
  @override
  String build() => '';

  void set(String query) => state = query;
}

final filteredIngredientsProvider =
    Provider.autoDispose<AsyncValue<List<Ingredient>>>((ref) {
      final query = ref.watch(ingredientQueryProvider).trim().toLowerCase();
      return ref
          .watch(ingredientsProvider)
          .whenData(
            (items) => query.isEmpty
                ? items
                : items
                      .where((i) => i.name.toLowerCase().contains(query))
                      .toList(),
          );
    });

/// ผลค้นหาจาก USDA ค่าเป็น null ถ้ายังไม่ได้กดค้นหา
///
/// ค้นเฉพาะเมื่อ user สั่ง (ไม่ค้นทุกครั้งที่พิมพ์) เพราะโควตาของ API น้อย
final usdaSearchProvider =
    AsyncNotifierProvider.autoDispose<UsdaSearch, RemoteSearchResult?>(
      UsdaSearch.new,
    );

class UsdaSearch extends AsyncNotifier<RemoteSearchResult?> {
  @override
  Future<RemoteSearchResult?> build() async => null;

  Future<void> search(String query) async {
    if (query.trim().isEmpty) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(ingredientRepositoryProvider).searchRemote(query),
    );
  }

  void clear() => state = const AsyncData(null);
}

// ---------- บันทึกการกินวันนี้ ----------

final todayLogProvider =
    AsyncNotifierProvider<TodayLogNotifier, List<FoodEntry>>(
      TodayLogNotifier.new,
    );

class TodayLogNotifier extends AsyncNotifier<List<FoodEntry>> {
  @override
  Future<List<FoodEntry>> build() =>
      ref.watch(foodLogRepositoryProvider).getEntriesOn(DateTime.now());

  Future<void> add(Ingredient ingredient, double grams) async {
    final entry = FoodEntry(
      id: _newId(),
      ingredient: ingredient,
      grams: grams,
      eatenAt: DateTime.now(),
    );
    await ref.read(foodLogRepositoryProvider).add(entry);
    state = AsyncData([...?state.value, entry]);
  }

  Future<void> remove(String id) async {
    await ref.read(foodLogRepositoryProvider).remove(id);
    state = AsyncData([...?state.value?.where((e) => e.id != id)]);
  }
}

final todayTotalsProvider = Provider<Nutrients>((ref) {
  final entries = ref.watch(todayLogProvider).value ?? const [];
  return Nutrients.sum(entries.map((e) => e.nutrients));
});
