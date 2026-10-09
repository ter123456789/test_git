import '../entities/ingredient.dart';
import '../entities/remote_search_result.dart';

abstract interface class IngredientRepository {
  /// วัตถุดิบที่ใช้ได้แบบออฟไลน์: ฐานข้อมูลในแอป วัตถุดิบที่ user เพิ่มเอง
  /// และวัตถุดิบจากแหล่งข้อมูลภายนอกที่เคยเลือกไว้
  Future<List<Ingredient>> getAll();

  /// เก็บวัตถุดิบลงเครื่อง ถ้ามี id นี้อยู่แล้วจะไม่เก็บซ้ำ
  Future<void> save(Ingredient ingredient);

  /// ค้นหาจากแหล่งข้อมูลภายนอก
  ///
  /// throw [IngredientSearchException] เมื่อค้นหาไม่สำเร็จ
  Future<RemoteSearchResult> searchRemote(String query);

  /// หาวัตถุดิบจากบาร์โค้ด ดูของที่เก็บในเครื่องก่อน ไม่เจอค่อยถามแหล่งข้อมูลภายนอก
  ///
  /// คืน null ถ้าไม่พบสินค้า หรือสินค้านั้นไม่มีข้อมูลโภชนาการ
  /// throw [IngredientSearchException] เมื่อค้นหาไม่สำเร็จ
  Future<Ingredient?> lookupBarcode(String barcode);
}
