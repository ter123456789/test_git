import 'food_entry.dart';
import 'nutrients.dart';

/// สรุปบันทึกการกินรายวัน ใช้ทั้งหน้าวันนี้และหน้าประวัติ
extension FoodLogStats on Iterable<FoodEntry> {
  /// รายการของวันที่ระบุ เรียงตามเวลาที่กิน
  List<FoodEntry> entriesOn(DateTime day) =>
      where((e) => _sameDay(e.eatenAt, day)).toList()
        ..sort((a, b) => a.eatenAt.compareTo(b.eatenAt));

  Nutrients totalsOn(DateTime day) =>
      Nutrients.sum(entriesOn(day).map((e) => e.nutrients));

  /// พลังงานรวมรายวันย้อนหลัง [days] วัน นับถึง [end] (เรียงจากเก่าไปใหม่)
  /// วันที่ไม่ได้บันทึกเป็น 0
  List<(DateTime, double)> dailyKcal({required DateTime end, int days = 7}) {
    final totals = <DateTime, double>{};
    for (final e in this) {
      final day = _dateOnly(e.eatenAt);
      totals[day] = (totals[day] ?? 0) + e.nutrients.kcal;
    }
    return [
      for (var i = days - 1; i >= 0; i--)
        if (DateTime(end.year, end.month, end.day - i) case final day)
          (day, totals[day] ?? 0),
    ];
  }

  /// วันที่มีการบันทึกอย่างน้อยหนึ่งรายการ
  Set<DateTime> get loggedDays => {for (final e in this) _dateOnly(e.eatenAt)};

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
