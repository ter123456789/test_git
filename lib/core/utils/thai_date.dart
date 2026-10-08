/// จัดรูปแบบวันที่เป็นภาษาไทย (ไม่ใช้ package intl เพื่อไม่ต้องโหลด locale)
abstract final class ThaiDate {
  static const _months = [
    'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน', //
    'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
  ];
  static const _shortMonths = [
    'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', //
    'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
  ];

  /// เรียงตาม [DateTime.weekday] (จันทร์ = 1 ... อาทิตย์ = 7)
  static const _weekdays = ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'];
  static const _longWeekdays = [
    'จันทร์', 'อังคาร', 'พุธ', 'พฤหัสบดี', 'ศุกร์', 'เสาร์', 'อาทิตย์', //
  ];

  /// ตุลาคม 2569
  static String monthYear(DateTime d) =>
      '${_months[d.month - 1]} ${d.year + 543}';

  /// วันพุธที่ 8 ต.ค.
  static String long(DateTime d) =>
      'วัน${_longWeekdays[d.weekday - 1]}ที่ ${d.day} ${_shortMonths[d.month - 1]}';

  /// 8 ต.ค.
  static String short(DateTime d) => '${d.day} ${_shortMonths[d.month - 1]}';

  static String weekday(DateTime d) => _weekdays[d.weekday - 1];

  /// 08:30
  static String time(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

extension DateOnly on DateTime {
  DateTime get dateOnly => DateTime(year, month, day);

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}
