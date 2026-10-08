import '../../domain/entities/ingredient.dart';
import '../../domain/entities/remote_search_result.dart';
import '../../domain/repositories/ingredient_repository.dart';
import '../datasources/builtin_ingredients.dart';
import '../datasources/nutrition_local_data_source.dart';
import '../datasources/thai_food_terms.dart';
import '../datasources/usda_remote_data_source.dart';
import '../models/nutrition_models.dart';
import '../models/usda_food_mapper.dart';

class IngredientRepositoryImpl implements IngredientRepository {
  const IngredientRepositoryImpl(this._local, this._usda);

  final NutritionLocalDataSource _local;
  final UsdaRemoteDataSource _usda;

  @override
  Future<List<Ingredient>> getAll() async => [
    ...builtinIngredients,
    ..._readSaved(),
  ];

  @override
  Future<void> save(Ingredient ingredient) async {
    final saved = _readSaved();
    if (saved.any((i) => i.id == ingredient.id)) return;
    await _local.writeSavedIngredients(
      [...saved, ingredient].map(NutritionModels.ingredientToJson).toList(),
    );
  }

  @override
  Future<RemoteSearchResult> searchRemote(String query) async {
    final englishQuery = ThaiQueryTranslator.toEnglish(query);
    if (englishQuery == null) throw UntranslatableQueryException(query);

    final foods = await _usda.search(englishQuery);
    return RemoteSearchResult(
      query: englishQuery,
      items: foods.map(UsdaFoodMapper.toIngredient).nonNulls.toList(),
    );
  }

  List<Ingredient> _readSaved() => _local
      .readSavedIngredients()
      .map(NutritionModels.ingredientFromJson)
      .toList();
}
