import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/entities/remote_search_result.dart';

/// เรียก Open Food Facts API ไม่ต้องใช้ key
///
/// https://openfoodfacts.github.io/openfoodfacts-server/api/
class OpenFoodFactsRemoteDataSource {
  const OpenFoodFactsRemoteDataSource({required http.Client client})
    : _client = client;

  static const _host = 'world.openfoodfacts.org';

  /// Open Food Facts ขอให้ระบุชื่อแอปใน User-Agent
  static const _userAgent = 'ThaiNutritionApp/1.0 (personal use)';

  /// ขอเฉพาะช่องที่ใช้ response จะเล็กลงมาก
  static const _fields =
      'code,product_name,product_name_th,product_name_en,nutriments';

  final http.Client _client;

  /// คืนข้อมูล `product` หรือ null ถ้าไม่มีสินค้านี้ในฐานข้อมูล
  ///
  /// throw [RateLimitedException] หรือ [RemoteUnavailableException]
  Future<Map<String, dynamic>?> product(String barcode) async {
    final http.Response response;
    try {
      response = await _client.get(
        Uri.https(_host, '/api/v2/product/$barcode', {'fields': _fields}),
        headers: {'User-Agent': _userAgent},
      );
    } on http.ClientException catch (e) {
      throw RemoteUnavailableException(e.message);
    }

    if (response.statusCode == 404) return null;
    if (response.statusCode == 429) throw const RateLimitedException();
    if (response.statusCode != 200) {
      throw RemoteUnavailableException('HTTP ${response.statusCode}');
    }

    final body =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    // status 0 = ไม่พบสินค้า (บางครั้งตอบ 200 มาแทน 404)
    if (body['status'] != 1) return null;
    return body['product'] as Map<String, dynamic>?;
  }
}
