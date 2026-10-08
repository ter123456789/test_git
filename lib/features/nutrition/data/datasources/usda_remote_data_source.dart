import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/entities/remote_search_result.dart';

/// เรียก USDA FoodData Central API
///
/// https://fdc.nal.usda.gov/api-guide
class UsdaRemoteDataSource {
  const UsdaRemoteDataSource({
    required http.Client client,
    required String apiKey,
  }) : _client = client,
       _apiKey = apiKey;

  static const _host = 'api.nal.usda.gov';
  static const _searchPath = '/fdc/v1/foods/search';

  /// Foundation และ SR Legacy เป็นวัตถุดิบทั่วไป (ไม่ใช่สินค้าแบรนด์)
  /// และค่าโภชนาการเป็นค่าต่อ 100 กรัม
  static const _dataTypes = ['Foundation', 'SR Legacy'];

  final http.Client _client;
  final String _apiKey;

  /// คืนรายการ `foods` จากผลค้นหา
  ///
  /// throw [RateLimitedException] หรือ [RemoteUnavailableException]
  Future<List<Map<String, dynamic>>> search(
    String query, {
    int pageSize = 25,
  }) async {
    final http.Response response;
    try {
      response = await _client.post(
        Uri.https(_host, _searchPath, {'api_key': _apiKey}),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': query,
          'dataType': _dataTypes,
          'pageSize': pageSize,
        }),
      );
    } on http.ClientException catch (e) {
      throw RemoteUnavailableException(e.message);
    }

    if (response.statusCode == 429) throw const RateLimitedException();
    if (response.statusCode != 200) {
      throw RemoteUnavailableException('HTTP ${response.statusCode}');
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    return ((body as Map<String, dynamic>)['foods'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
  }
}
