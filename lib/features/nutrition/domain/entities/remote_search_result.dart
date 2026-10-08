import 'package:equatable/equatable.dart';

import 'ingredient.dart';

class RemoteSearchResult extends Equatable {
  const RemoteSearchResult({required this.query, required this.items});

  /// คำที่ใช้ค้นจริง (อาจแปลจากภาษาไทยเป็นภาษาอังกฤษแล้ว)
  final String query;

  final List<Ingredient> items;

  @override
  List<Object?> get props => [query, items];
}

/// ข้อผิดพลาดจากการค้นหาวัตถุดิบจากแหล่งข้อมูลภายนอก
sealed class IngredientSearchException implements Exception {
  const IngredientSearchException();
}

/// พิมพ์ภาษาไทยที่ไม่มีในตารางแปล จึงค้นหาจากแหล่งข้อมูลภาษาอังกฤษไม่ได้
class UntranslatableQueryException extends IngredientSearchException {
  const UntranslatableQueryException(this.query);

  final String query;
}

/// ใช้โควตาการค้นหาเกินกำหนด
class RateLimitedException extends IngredientSearchException {
  const RateLimitedException();
}

/// เชื่อมต่อไม่ได้ หรือเซิร์ฟเวอร์ตอบกลับผิดปกติ
class RemoteUnavailableException extends IngredientSearchException {
  const RemoteUnavailableException([this.detail]);

  final String? detail;
}
