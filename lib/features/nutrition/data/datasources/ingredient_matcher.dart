import '../../../../core/utils/thai_text.dart';
import '../../domain/entities/ingredient.dart';
import 'thai_food_terms.dart';

/// ค้นวัตถุดิบในเครื่องด้วยภาษาไทยหรืออังกฤษ
///
/// เรียงผลตามความตรง:
/// 1. ชื่อไทยหรืออังกฤษมีคำค้นอยู่ตรงตามที่พิมพ์
/// 2. ตรงเมื่อไม่สนวรรณยุกต์/การันต์/ช่องว่าง
///    (อยู่ลำดับรองเพราะบางคำต่างกันแค่วรรณยุกต์ เช่น "ไข่" กับ "ไขมัน")
/// 3. สะกดผิดเล็กน้อย
/// 4. แปลคำไทยเป็นอังกฤษแล้วตรงกับชื่ออังกฤษ เช่น "อกไก่" เจอ
///    "Chicken, breast, meat and skin, raw" ที่เคยเลือกมาจาก USDA
abstract final class IngredientMatcher {
  /// คำที่บอกสภาพ (ดิบ/สุก) ไม่ใช้จับคู่ เพราะ user ไม่ได้พิมพ์มาเอง
  static const _stateWords = {'raw', 'cooked', 'fresh', 'dry', 'whole'};

  static List<Ingredient> search(List<Ingredient> items, String query) {
    final q = ThaiText.normalize(query);
    if (q.isEmpty) return items;
    final exact = query.trim().toLowerCase();

    final keywords = _translatedKeywords(query);
    final typos = ThaiText.allowedTypos(q.length);
    final ranked = <(int, int, Ingredient)>[];

    for (final (index, item) in items.indexed) {
      final names = [item.name, ?item.nameEn].map(ThaiText.normalize);
      final int? rank;
      if ([
        item.name,
        ?item.nameEn,
      ].any((n) => n.toLowerCase().contains(exact))) {
        rank = 0;
      } else if (names.any((n) => n.contains(q))) {
        rank = 1;
      } else if (typos > 0 &&
          names.any((n) => ThaiText.substringDistance(n, q) <= typos)) {
        rank = 2;
      } else if (keywords.isNotEmpty && _hasAllWords(item, keywords)) {
        rank = 3;
      } else {
        rank = null;
      }
      if (rank != null) ranked.add((rank, index, item));
    }

    ranked.sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2 - b.$2);
    return [for (final (_, _, item) in ranked) item];
  }

  /// คำภาษาอังกฤษที่ได้จากการแปลคำค้นภาษาไทย (ว่างถ้าไม่ใช่ภาษาไทยหรือแปลไม่ได้)
  static List<String> _translatedKeywords(String query) {
    if (!ThaiText.hasThai(query)) return const [];
    final english = ThaiQueryTranslator.toEnglish(query);
    if (english == null) return const [];
    return english
        .toLowerCase()
        .split(RegExp(r'[^a-z]+'))
        .where((w) => w.isNotEmpty && !_stateWords.contains(w))
        .toList();
  }

  static bool _hasAllWords(Ingredient item, List<String> words) {
    final text = '${item.name} ${item.nameEn ?? ''}'.toLowerCase();
    // จับทั้งคำ (ยอมพหูพจน์) เพื่อให้ "egg" ไม่ไปเจอ "eggplant"
    // แต่ "mushroom" ยังเจอ "mushrooms"
    return words.every(
      (w) => RegExp(
        '(^|[^a-z])${RegExp.escape(w)}(s|es)?(\$|[^a-z])',
      ).hasMatch(text),
    );
  }
}
