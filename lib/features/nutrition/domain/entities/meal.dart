/// มื้ออาหาร เรียงตามลำดับที่กินในหนึ่งวัน
///
/// ของว่างอยู่ก่อนมื้อเย็น เพราะส่วนใหญ่กินช่วงบ่าย และควรไปลดเป้ามื้อเย็น
enum Meal {
  breakfast('มื้อเช้า', 0.25),
  lunch('มื้อกลางวัน', 0.35),
  snack('ของว่าง', 0.10),
  dinner('มื้อเย็น', 0.30);

  const Meal(this.label, this.share);

  final String label;

  /// สัดส่วนของพลังงานทั้งวันตามแผนปกติ (รวมกันได้ 1)
  final double share;

  /// เดามื้อจากเวลา ใช้เป็นค่าเริ่มต้นและกับข้อมูลเก่าที่ยังไม่มีมื้อ
  static Meal fromTime(DateTime time) => switch (time.hour) {
    >= 5 && < 11 => breakfast,
    >= 11 && < 15 => lunch,
    >= 17 && < 22 => dinner,
    _ => snack,
  };
}
