import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../../core/providers/shared_preferences_provider.dart';
import '../../../../core/utils/thai_date.dart';
import '../../data/datasources/ingredient_matcher.dart';
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

  /// [nameEn] ใช้ให้ค้นด้วยภาษาอังกฤษเจอ เช่น ชื่อจาก USDA ที่ใช้เติมค่าโภชนาการ
  Future<Ingredient> addCustom({
    required String name,
    required Nutrients per100g,
    String? nameEn,
  }) async {
    final ingredient = Ingredient(
      id: 'custom_${_newId()}',
      name: name,
      nameEn: nameEn,
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

/// หาค่าโภชนาการจากชื่อ ใช้เติมค่าให้อัตโนมัติในหน้าเพิ่มวัตถุดิบใหม่
///
/// ค่าเป็น null ถ้ายังไม่ได้ค้น ไม่งั้นเป็นรายการที่ใกล้เคียง (ตัวแรกตรงที่สุด)
final nutritionLookupProvider =
    AsyncNotifierProvider.autoDispose<NutritionLookup, NutritionLookupResult?>(
      NutritionLookup.new,
    );

typedef NutritionLookupResult = ({String query, List<Ingredient> candidates});

class NutritionLookup extends AsyncNotifier<NutritionLookupResult?> {
  /// จำนวนตัวเลือกสูงสุดที่แสดง
  static const _maxCandidates = 8;

  /// คำที่กำลังค้นอยู่ กันค้นซ้ำ เช่น กด Enter แล้วโฟกัสหลุดจากช่องชื่อทันที
  String? _inFlight;

  @override
  Future<NutritionLookupResult?> build() async => null;

  /// ค้นในเครื่องก่อน ถ้าไม่เจอค่อยค้นจาก USDA (ประหยัดโควตา)
  Future<void> lookup(String name) async {
    final query = name.trim();
    if (query.isEmpty || query == _inFlight || query == state.value?.query) {
      return;
    }
    _inFlight = query;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final all = await ref.read(ingredientsProvider.future);
      final local = IngredientMatcher.search(all, query);
      final candidates = local.isNotEmpty
          ? local
          : (await ref.read(ingredientRepositoryProvider).searchRemote(query))
                .items;
      return (
        query: query,
        candidates: candidates.take(_maxCandidates).toList(),
      );
    });
    // ระหว่างรอ user อาจเปลี่ยนชื่อแล้วค้นใหม่ ผลเก่าทิ้งไป
    if (_inFlight != query) return;
    _inFlight = null;
    state = result;
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
      final query = ref.watch(ingredientQueryProvider);
      return ref
          .watch(ingredientsProvider)
          .whenData((items) => IngredientMatcher.search(items, query));
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

// ---------- บันทึกการกิน ----------

/// ทุกรายการที่เคยบันทึก ใช้ทั้งหน้าวันนี้และหน้าประวัติ
final foodLogProvider = AsyncNotifierProvider<FoodLogNotifier, List<FoodEntry>>(
  FoodLogNotifier.new,
);

class FoodLogNotifier extends AsyncNotifier<List<FoodEntry>> {
  @override
  Future<List<FoodEntry>> build() =>
      ref.watch(foodLogRepositoryProvider).getAll();

  /// เพิ่มรายการ ถ้าระบุ [day] (บันทึกย้อนหลัง) จะใช้เวลาปัจจุบันของวันนั้น
  Future<void> add(Ingredient ingredient, double grams, {DateTime? day}) async {
    final now = DateTime.now();
    final eatenAt = day == null || day.isSameDay(now)
        ? now
        : DateTime(day.year, day.month, day.day, now.hour, now.minute);
    final entry = FoodEntry(
      id: _newId(),
      ingredient: ingredient,
      grams: grams,
      eatenAt: eatenAt,
    );
    await ref.read(foodLogRepositoryProvider).add(entry);
    state = AsyncData([...?state.value, entry]);
  }

  Future<void> remove(String id) async {
    await ref.read(foodLogRepositoryProvider).remove(id);
    state = AsyncData([...?state.value?.where((e) => e.id != id)]);
  }
}
