import '../../../../core/utils/thai_text.dart';

/// แปลงคำค้นภาษาไทยเป็นคำค้นภาษาอังกฤษสำหรับ USDA
///
/// USDA ค้นได้แค่ภาษาอังกฤษ จึงใช้ตารางคำที่พบบ่อยแทนการแปลอัตโนมัติ
/// เพิ่มคำใหม่ได้ใน [thaiFoodTerms]
abstract final class ThaiQueryTranslator {
  /// [thaiFoodTerms] ที่ normalize คีย์แล้ว
  static final _terms = {
    for (final MapEntry(:key, :value) in thaiFoodTerms.entries)
      ThaiText.normalize(key): value,
  };

  /// คืนคำค้นภาษาอังกฤษ
  ///
  /// - ไม่มีอักษรไทย: คืนคำเดิม
  /// - ตรงกับคำในตาราง: คืนคำแปล
  /// - ขึ้นต้นด้วยคำในตาราง (เช่น "อกไก่ย่าง"): ใช้คำที่ยาวที่สุดที่ตรง
  /// - สะกดผิดเล็กน้อย (เช่น "บรอคโคลี"): ใช้คำในตารางที่ใกล้ที่สุด
  /// - ไม่เจอเลย: คืน null
  ///
  /// ไม่สนวรรณยุกต์ การันต์ และช่องว่าง (ดู [ThaiText.normalize])
  ///
  /// จับเฉพาะคำที่อยู่ต้นคำค้น เพราะภาษาไทยไม่มีช่องว่างคั่นคำ
  /// ถ้าจับคำที่อยู่ตรงไหนก็ได้จะผิดง่าย เช่น "ขนมจีบ" มีคำว่า "นม" อยู่ข้างใน
  static String? toEnglish(String query) {
    final q = query.trim();
    if (!ThaiText.hasThai(q)) return q;
    final n = ThaiText.normalize(q);

    final exact = _terms[n];
    if (exact != null) return exact;

    String? bestKey;
    for (final key in _terms.keys) {
      if (n.startsWith(key) && key.length > (bestKey?.length ?? 0)) {
        bestKey = key;
      }
    }
    if (bestKey != null) return _terms[bestKey];

    return _closest(n);
  }

  /// คำในตารางที่ใกล้ที่สุด เทียบทั้งคำค้น หรือส่วนต้นของคำค้นที่ยาวพอ ๆ กัน
  static String? _closest(String n) {
    String? best;
    var bestScore = (distance: 1 << 30, length: 0);
    for (final MapEntry(:key, :value) in _terms.entries) {
      final allowed = ThaiText.allowedTypos(key.length);
      if (allowed == 0) continue;
      var d = ThaiText.distance(n, key);
      for (var len = key.length - 1; len <= key.length + 1; len++) {
        if (len > 0 && len < n.length) {
          final p = ThaiText.distance(n.substring(0, len), key);
          if (p < d) d = p;
        }
      }
      if (d > allowed) continue;
      // ระยะน้อยกว่าชนะ ถ้าเท่ากันเลือกคำที่ยาวกว่า (เจาะจงกว่า)
      if (d < bestScore.distance ||
          (d == bestScore.distance && key.length > bestScore.length)) {
        best = value;
        bestScore = (distance: d, length: key.length);
      }
    }
    return best;
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
  // ---- เพิ่มเติม ----
  // ข้าว แป้ง ธัญพืช
  'ขนมปังขาว': 'bread white',
  'ขนมปังโฮลวีท': 'bread whole wheat',
  'แป้งสาลี': 'wheat flour white',
  'แป้งข้าวเจ้า': 'rice flour white',
  'แป้งมัน': 'tapioca',
  'สาคู': 'tapioca pearl dry',
  'ซีเรียล': 'cereal ready-to-eat',
  'กราโนล่า': 'granola',
  'แครกเกอร์': 'crackers',
  'มักกะโรนี': 'macaroni cooked',
  'บะหมี่กึ่งสำเร็จรูป': 'ramen noodles dry',
  'มาม่า': 'ramen noodles dry',
  'ข้าวบาร์เลย์': 'barley pearled cooked',
  'ควินัว': 'quinoa cooked',
  'มันสำปะหลัง': 'cassava raw',
  // เนื้อสัตว์ ไข่
  'เนื้อไก่': 'chicken meat raw',
  'หนังไก่': 'chicken skin',
  'ตีนไก่': 'chicken feet',
  'ไก่งวง': 'turkey raw',
  'คอหมู': 'pork shoulder raw',
  'ขาหมู': 'pork leg raw',
  'ตับหมู': 'pork liver raw',
  'กุนเชียง': 'chinese sausage',
  'เนื้อสันนอก': 'beef sirloin raw',
  'สเต๊ก': 'beef steak raw',
  'เนื้อแกะ': 'lamb raw',
  'ไข่ต้ม': 'egg whole hard-boiled',
  'ไข่ดาว': 'egg whole fried',
  'ไข่เจียว': 'egg omelet',
  'ไข่นกกระทา': 'quail egg',
  // อาหารทะเล
  'ปลากะพง': 'sea bass raw',
  'ปลาเก๋า': 'grouper raw',
  'ปลาค็อด': 'cod raw',
  'ปลาซาบะ': 'mackerel raw',
  'ปลาซาร์ดีน': 'sardine canned',
  'หอยลาย': 'clams raw',
  'หอยเชลล์': 'scallops raw',
  'ปูอัด': 'surimi',
  'ล็อบสเตอร์': 'lobster raw',
  // ถั่ว เมล็ด นม
  'ถั่วดำ': 'black beans',
  'ถั่วลูกไก่': 'chickpeas',
  'ถั่วแระ': 'edamame',
  'ถั่วลันเตา': 'green peas raw',
  'งา': 'sesame seeds',
  'เมล็ดเจีย': 'chia seeds',
  'เมล็ดฟักทอง': 'pumpkin seeds',
  'วอลนัท': 'walnuts',
  'พิสตาชิโอ': 'pistachio nuts',
  'นมอัลมอนด์': 'almond milk',
  'นมข้าวโอ๊ต': 'oat milk',
  'กรีกโยเกิร์ต': 'greek yogurt plain',
  'มอสซาเรลลา': 'mozzarella cheese',
  'ครีมชีส': 'cream cheese',
  'วิปปิ้งครีม': 'cream heavy whipping',
  'นมข้นหวาน': 'condensed milk sweetened',
  'นมข้นจืด': 'evaporated milk',
  'เวย์โปรตีน': 'whey protein powder',
  // ผัก สมุนไพร
  'ผักกาดเขียว': 'mustard greens raw',
  'ผักกาดแก้ว': 'iceberg lettuce',
  'ผักสลัด': 'lettuce raw',
  'ผักชี': 'coriander leaves raw',
  'กะเพรา': 'basil fresh',
  'โหระพา': 'basil fresh',
  'ตะไคร้': 'lemongrass',
  'มะนาว': 'lime raw',
  'มะระ': 'balsam pear raw',
  'ฟักเขียว': 'wax gourd raw',
  'หน่อไม้': 'bamboo shoots',
  'สาหร่าย': 'seaweed',
  'ถั่วแขก': 'green beans raw',
  'ถั่วพู': 'winged beans',
  'กะหล่ำปลีม่วง': 'red cabbage raw',
  'ขึ้นฉ่าย': 'celery raw',
  'คื่นช่าย': 'celery raw',
  'ซูกินี': 'zucchini raw',
  'บีทรูท': 'beets raw',
  'หัวไชเท้า': 'radish daikon raw',
  'กระเจี๊ยบเขียว': 'okra raw',
  'เห็ดนางฟ้า': 'oyster mushrooms',
  'เห็ดเข็มทอง': 'enoki mushrooms',
  'เห็ดฟาง': 'straw mushrooms',
  'เห็ดแชมปิญอง': 'white mushrooms',
  'พริกไทย': 'black pepper',
  // ผลไม้
  'ส้มโอ': 'pummelo raw',
  'ส้มเขียวหวาน': 'tangerine raw',
  'แก้วมังกร': 'pitaya',
  'ขนุน': 'jackfruit raw',
  'น้อยหน่า': 'sugar apple',
  'ละมุด': 'sapodilla',
  'มะขาม': 'tamarind',
  'ลูกพลับ': 'persimmon',
  'ลูกพีช': 'peach raw',
  'สาลี่': 'asian pear raw',
  'ลูกแพร์': 'pear raw',
  'กีวี': 'kiwifruit',
  'บลูเบอร์รี่': 'blueberries raw',
  'เชอร์รี่': 'cherries sweet raw',
  'แคนตาลูป': 'cantaloupe raw',
  'เมลอน': 'melon honeydew',
  'ลูกเกด': 'raisins',
  'อินทผลัม': 'dates medjool',
  'มะพร้าวน้ำหอม': 'coconut water',
  // เครื่องดื่ม ของว่าง
  'กาแฟ': 'coffee brewed',
  'ชา': 'tea brewed',
  'ชาเขียว': 'tea green brewed',
  'น้ำส้ม': 'orange juice',
  'น้ำมะพร้าว': 'coconut water',
  'โกโก้': 'cocoa',
  'ช็อกโกแลต': 'chocolate dark',
  'ไอศกรีม': 'ice cream vanilla',
  'น้ำอัดลม': 'cola carbonated',
  'โค้ก': 'cola',
  'เบียร์': 'beer',
  'ไวน์': 'wine table',
  'มันฝรั่งทอด': 'potato chips',
  'เฟรนช์ฟรายส์': 'french fries',
  'ป๊อปคอร์น': 'popcorn',
  'คุกกี้': 'cookies',
  'เค้ก': 'cake',
  'โดนัท': 'doughnuts',
  'พิซซ่า': 'pizza',
  'แฮมเบอร์เกอร์': 'hamburger',
  // เครื่องปรุง น้ำมัน
  'น้ำมันรำข้าว': 'rice bran oil',
  'น้ำมันมะพร้าว': 'coconut oil',
  'น้ำมันงา': 'sesame oil',
  'เนยเทียม': 'margarine',
  'แยม': 'jam',
  'ซอสมะเขือเทศ': 'ketchup',
  'ซอสพริก': 'chili sauce',
  'มิโซะ': 'miso',
  'เกลือ': 'salt table',
};
