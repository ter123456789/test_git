import 'package:equatable/equatable.dart';

import 'nutrients.dart';

enum IngredientSource {
  /// ฐานข้อมูลที่มากับแอป
  builtin,

  /// user เพิ่มเอง
  custom,

  /// ดึงมาจาก USDA FoodData Central
  usda,

  /// สแกนบาร์โค้ดแล้วดึงมาจาก Open Food Facts
  openFoodFacts,
}

class Ingredient extends Equatable {
  const Ingredient({
    required this.id,
    required this.name,
    required this.per100g,
    this.nameEn,
    this.source = IngredientSource.builtin,
    this.barcode,
  });

  final String id;
  final String name;

  /// ชื่อภาษาอังกฤษ ใช้ค้นหาด้วยภาษาอังกฤษ
  final String? nameEn;

  /// ค่าโภชนาการต่อ 100 กรัม
  final Nutrients per100g;

  final IngredientSource source;

  /// บาร์โค้ดสินค้า (EAN/UPC) ใช้หาของที่เคยสแกนแล้วโดยไม่ต้องเรียก API ซ้ำ
  final String? barcode;

  Nutrients nutrientsFor(double grams) => per100g.scale(grams / 100);

  Ingredient withName(String name) => Ingredient(
    id: id,
    name: name,
    nameEn: nameEn,
    per100g: per100g,
    source: source,
    barcode: barcode,
  );

  @override
  List<Object?> get props => [id, name, nameEn, per100g, source, barcode];
}
