/// เครื่องมือเทียบข้อความภาษาไทยแบบหลวม ๆ สำหรับการค้นหา
abstract final class ThaiText {
  static final _thaiChars = RegExp(r'[฀-๿]');

  /// ไม้ไต่คู้ วรรณยุกต์ การันต์ นิคหิต ยามักการ
  static final _marks = RegExp(r'[็-๎]');
  static final _ignored = RegExp(r'''[\s\-_.,()'"/]+''');

  static bool hasThai(String text) => _thaiChars.hasMatch(text);

  /// ตัดสิ่งที่คนมักพิมพ์ไม่ตรงกันออก: วรรณยุกต์ การันต์ ช่องว่าง เครื่องหมาย
  /// และตัวพิมพ์ใหญ่เล็ก เช่น "สตรอว์เบอร์รี่" กับ "สตรอวเบอรรี" ได้ค่าเดียวกัน
  static String normalize(String text) => text
      .toLowerCase()
      // สระอำบางแป้นพิมพ์ออกมาเป็น นิคหิต + สระอา
      .replaceAll('ํา', 'ำ')
      .replaceAll(_marks, '')
      .replaceAll(_ignored, '');

  /// จำนวนตัวอักษรที่ยอมให้พิมพ์ผิดได้ ตามความยาวคำค้น
  /// คำสั้นต้องตรงเป๊ะ ไม่งั้นเจอทุกอย่าง
  static int allowedTypos(int length) => switch (length) {
    < 4 => 0,
    < 8 => 1,
    _ => 2,
  };

  /// ระยะ Levenshtein ระหว่างสองข้อความ
  static int distance(String a, String b) {
    var prev = List<int>.generate(b.length + 1, (j) => j);
    for (var i = 1; i <= a.length; i++) {
      final curr = List<int>.filled(b.length + 1, 0)..[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        curr[j] = _min3(prev[j] + 1, curr[j - 1] + 1, prev[j - 1] + cost);
      }
      prev = curr;
    }
    return prev[b.length];
  }

  /// ระยะที่น้อยที่สุดระหว่าง [pattern] กับข้อความช่วงใดก็ได้ใน [text]
  /// (approximate substring matching แบบ Sellers)
  static int substringDistance(String text, String pattern) {
    // แถวแรกเป็น 0 ทั้งหมด = เริ่มจับคู่ตรงไหนของ text ก็ได้ฟรี
    var prev = List<int>.filled(text.length + 1, 0);
    for (var i = 1; i <= pattern.length; i++) {
      final curr = List<int>.filled(text.length + 1, 0)..[0] = i;
      for (var j = 1; j <= text.length; j++) {
        final cost = pattern.codeUnitAt(i - 1) == text.codeUnitAt(j - 1)
            ? 0
            : 1;
        curr[j] = _min3(prev[j] + 1, curr[j - 1] + 1, prev[j - 1] + cost);
      }
      prev = curr;
    }
    return prev.reduce((a, b) => a < b ? a : b);
  }

  static int _min3(int a, int b, int c) =>
      a < b ? (a < c ? a : c) : (b < c ? b : c);
}
