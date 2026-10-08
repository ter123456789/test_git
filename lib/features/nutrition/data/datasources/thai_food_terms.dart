/// แปลงคำค้นภาษาไทยเป็นคำค้นภาษาอังกฤษสำหรับ USDA
///
/// USDA ค้นได้แค่ภาษาอังกฤษ จึงใช้ตารางคำที่พบบ่อยแทนการแปลอัตโนมัติ
/// เพิ่มคำใหม่ได้ใน [thaiFoodTerms]
abstract final class ThaiQueryTranslator {
  static final _thaiChars = RegExp(r'[฀-๿]');

  /// คืนคำค้นภาษาอังกฤษ
  ///
  /// - ไม่มีอักษรไทย: คืนคำเดิม
  /// - ตรงกับคำในตาราง: คืนคำแปล
  /// - ขึ้นต้นด้วยคำในตาราง (เช่น "อกไก่ย่าง"): ใช้คำที่ยาวที่สุดที่ตรง
  /// - ไม่เจอเลย: คืน null
  ///
  /// จับเฉพาะคำที่อยู่ต้นคำค้น เพราะภาษาไทยไม่มีช่องว่างคั่นคำ
  /// ถ้าจับคำที่อยู่ตรงไหนก็ได้จะผิดง่าย เช่น "ขนมจีบ" มีคำว่า "นม" อยู่ข้างใน
  static String? toEnglish(String query) {
    final q = query.trim();
    if (!_thaiChars.hasMatch(q)) return q;

    final exact = thaiFoodTerms[q];
    if (exact != null) return exact;

    String? bestKey;
    for (final key in thaiFoodTerms.keys) {
      if (q.startsWith(key) && key.length > (bestKey?.length ?? 0)) {
        bestKey = key;
      }
    }
    return bestKey == null ? null : thaiFoodTerms[bestKey];
  }
}

const thaiFoodTerms = <String, String>{
  // ข้าว แป้ง เส้น
  'ข้าวสวย': 'white rice cooked',
  'ข้าวขาว': 'white rice cooked',
  'ข้าวกล้อง': 'brown rice cooked',
  'ข้าวเหนียว': 'glutinous rice cooked',
  'ข้าวโอ๊ต': 'oats',
  'ข้าวโพด': 'corn sweet yellow',
  'ขนมปัง': 'bread',
  'เส้นก๋วยเตี๋ยว': 'rice noodles cooked',
  'เส้นหมี่': 'rice noodles cooked',
  'วุ้นเส้น': 'glass noodles',
  'บะหมี่': 'egg noodles cooked',
  'พาสต้า': 'pasta cooked',
  'สปาเก็ตตี้': 'spaghetti cooked',
  'มันฝรั่ง': 'potato raw',
  'มันเทศ': 'sweet potato raw',
  'เผือก': 'taro raw',
  'ฟักทอง': 'pumpkin raw',
  // เนื้อสัตว์
  'ไก่': 'chicken raw',
  'อกไก่': 'chicken breast raw',
  'สะโพกไก่': 'chicken thigh raw',
  'น่องไก่': 'chicken drumstick raw',
  'ปีกไก่': 'chicken wing raw',
  'ตับไก่': 'chicken liver raw',
  'หมู': 'pork raw',
  'หมูสับ': 'ground pork raw',
  'หมูบด': 'ground pork raw',
  'หมูสันใน': 'pork tenderloin raw',
  'หมูสันนอก': 'pork loin raw',
  'หมูสามชั้น': 'pork belly raw',
  'ซี่โครงหมู': 'pork spareribs raw',
  'เบคอน': 'bacon',
  'ไส้กรอก': 'sausage',
  'แฮม': 'ham',
  'เนื้อวัว': 'beef raw',
  'เนื้อวัวบด': 'ground beef raw',
  'เนื้อสันใน': 'beef tenderloin raw',
  'เป็ด': 'duck raw',
  'ไข่': 'egg whole raw',
  'ไข่ไก่': 'egg whole raw',
  'ไข่ขาว': 'egg white raw',
  'ไข่แดง': 'egg yolk raw',
  'ไข่เป็ด': 'duck egg',
  // อาหารทะเล
  'ปลา': 'fish raw',
  'ปลาแซลมอน': 'salmon raw',
  'แซลมอน': 'salmon raw',
  'ปลาทูน่า': 'tuna',
  'ทูน่า': 'tuna',
  'ปลานิล': 'tilapia raw',
  'ปลาดุก': 'catfish raw',
  'ปลาทู': 'mackerel raw',
  'กุ้ง': 'shrimp raw',
  'ปลาหมึก': 'squid raw',
  'หอยแมลงภู่': 'mussels raw',
  'หอยนางรม': 'oysters raw',
  'ปู': 'crab raw',
  // ถั่ว เต้าหู้ นม
  'เต้าหู้': 'tofu',
  'เต้าหู้แข็ง': 'tofu firm',
  'เต้าหู้อ่อน': 'tofu soft',
  'นมถั่วเหลือง': 'soymilk',
  'ถั่วเหลือง': 'soybeans',
  'ถั่วลิสง': 'peanuts raw',
  'เนยถั่ว': 'peanut butter',
  'อัลมอนด์': 'almonds',
  'เม็ดมะม่วงหิมพานต์': 'cashew nuts',
  'ถั่วเขียว': 'mung beans',
  'ถั่วแดง': 'kidney beans',
  'นม': 'milk whole',
  'นมวัว': 'milk whole',
  'นมพร่องมันเนย': 'milk lowfat',
  'นมขาดมันเนย': 'milk nonfat',
  'โยเกิร์ต': 'yogurt plain',
  'ชีส': 'cheese cheddar',
  'เนย': 'butter',
  // ผัก
  'ผักบุ้ง': 'water spinach raw',
  'คะน้า': 'chinese broccoli raw',
  'กะหล่ำปลี': 'cabbage raw',
  'ผักกาดขาว': 'chinese cabbage raw',
  'กวางตุ้ง': 'bok choy raw',
  'ผักโขม': 'spinach raw',
  'บรอกโคลี': 'broccoli raw',
  'บร็อคโคลี่': 'broccoli raw',
  'ดอกกะหล่ำ': 'cauliflower raw',
  'แครอท': 'carrot raw',
  'แตงกวา': 'cucumber raw',
  'มะเขือเทศ': 'tomato raw',
  'มะเขือยาว': 'eggplant raw',
  'ถั่วฝักยาว': 'yardlong beans raw',
  'ถั่วงอก': 'mung bean sprouts raw',
  'หอมใหญ่': 'onion raw',
  'หัวหอม': 'onion raw',
  'กระเทียม': 'garlic raw',
  'ขิง': 'ginger raw',
  'พริก': 'chili peppers raw',
  'พริกหวาน': 'sweet pepper raw',
  'เห็ด': 'mushrooms raw',
  'เห็ดหอม': 'shiitake mushrooms',
  'ข้าวโพดอ่อน': 'baby corn',
  'ผักกาดหอม': 'lettuce raw',
  'ต้นหอม': 'scallions raw',
  // ผลไม้
  'กล้วย': 'banana raw',
  'กล้วยหอม': 'banana raw',
  'แอปเปิล': 'apple raw',
  'แอปเปิ้ล': 'apple raw',
  'ส้ม': 'orange raw',
  'มะม่วง': 'mango raw',
  'มะละกอ': 'papaya raw',
  'สับปะรด': 'pineapple raw',
  'แตงโม': 'watermelon raw',
  'ฝรั่ง': 'guava raw',
  'องุ่น': 'grapes raw',
  'ทุเรียน': 'durian raw',
  'มังคุด': 'mangosteen',
  'ลำไย': 'longan raw',
  'ลิ้นจี่': 'litchi raw',
  'เงาะ': 'rambutan',
  'มะพร้าว': 'coconut meat raw',
  'กะทิ': 'coconut milk',
  'อะโวคาโด': 'avocado raw',
  'สตรอว์เบอร์รี': 'strawberries raw',
  'สตรอเบอร์รี่': 'strawberries raw',
  // เครื่องปรุง ไขมัน
  'น้ำมันพืช': 'vegetable oil',
  'น้ำมันมะกอก': 'olive oil',
  'น้ำมันหมู': 'lard',
  'น้ำตาล': 'sugar granulated',
  'น้ำตาลทราย': 'sugar granulated',
  'น้ำผึ้ง': 'honey',
  'น้ำปลา': 'fish sauce',
  'ซีอิ๊ว': 'soy sauce',
  'ซอสหอยนางรม': 'oyster sauce',
  'มายองเนส': 'mayonnaise',
};
