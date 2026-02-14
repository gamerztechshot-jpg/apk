// core/models/panchang_model.dart
class PanchangModel {
  final String date;
  final String festival;
  final String tithi;
  final String nakshatra;
  final String sunrise;
  final String sunset;
  final String moonrise;
  final String moonset;
  final String suryaRashi;
  final String chandraRashi;
  final String samvat;
  final String karan;
  final String yoga;
  final String dishaShool;
  final String chandraNivas;
  final String ritu;
  final String ayan;
  final String brahmaMuhurat;
  final String abhijitMuhurat;
  final String godhuliMuhurat;
  final String amritKalam;
  final String rahuKaal;
  final String yamagandaKaal;

  PanchangModel({
    required this.date,
    required this.festival,
    required this.tithi,
    required this.nakshatra,
    required this.sunrise,
    required this.sunset,
    required this.moonrise,
    required this.moonset,
    required this.suryaRashi,
    required this.chandraRashi,
    required this.samvat,
    required this.karan,
    required this.yoga,
    required this.dishaShool,
    required this.chandraNivas,
    required this.ritu,
    required this.ayan,
    required this.brahmaMuhurat,
    required this.abhijitMuhurat,
    required this.godhuliMuhurat,
    required this.amritKalam,
    required this.rahuKaal,
    required this.yamagandaKaal,
  });

  factory PanchangModel.fromMap(Map<String, dynamic> map, bool isHindi) {
    return PanchangModel(
      date: map[isHindi ? 'दिनांक' : 'Date']?.toString() ?? '',
      festival: map[isHindi ? 'त्यौहार' : 'Festival']?.toString() ?? '',
      tithi: map[isHindi ? 'तिथि' : 'Tithi']?.toString() ?? '',
      nakshatra: map[isHindi ? 'नक्षत्र' : 'Nakshatra']?.toString() ?? '',
      sunrise: map[isHindi ? 'सूर्योदय' : 'Sunrise']?.toString() ?? '',
      sunset: map[isHindi ? 'सूर्यास्त' : 'Sunset']?.toString() ?? '',
      moonrise: map[isHindi ? 'चन्द्रोदय' : 'Moonrise']?.toString() ?? '',
      moonset: map[isHindi ? 'चन्द्रास्त' : 'Moonset']?.toString() ?? '',
      suryaRashi: map[isHindi ? 'सूर्य राशि' : 'Surya Rashi']?.toString() ?? '',
      chandraRashi:
          map[isHindi ? 'चंद्र राशि' : 'Chandra Rashi']?.toString() ?? '',
      samvat: map[isHindi ? 'विक्रम संवत' : 'Samvat']?.toString() ?? '',
      karan: map[isHindi ? 'करण' : 'Karan']?.toString() ?? '',
      yoga: map[isHindi ? 'योग' : 'Yoga']?.toString() ?? '',
      dishaShool: map[isHindi ? 'दिशाशूल' : 'Disha Shool']?.toString() ?? '',
      chandraNivas:
          map[isHindi ? 'चंद्र निवास' : 'Chandra Nivas']?.toString() ?? '',
      ritu: map[isHindi ? 'ऋतु' : 'Ritu']?.toString() ?? '',
      ayan: map[isHindi ? 'अयन' : 'Ayan']?.toString() ?? '',
      brahmaMuhurat:
          map[isHindi ? 'ब्रह्म मुहूर्त' : 'Brahma Muhurat']?.toString() ?? '',
      abhijitMuhurat:
          map[isHindi ? 'अभिजित मुहूर्त' : 'Abhijit Muhurat']?.toString() ?? '',
      godhuliMuhurat:
          map[isHindi ? 'गोधूलि मुहूर्त' : 'Godhuli Muhurat']?.toString() ?? '',
      amritKalam: map[isHindi ? 'अमृत काल' : 'Amrit Kalam']?.toString() ?? '',
      rahuKaal: map[isHindi ? 'राहुकाल' : 'Rahu Kaal']?.toString() ?? '',
      yamagandaKaal:
          map[isHindi ? 'यमघण्टकाल' : 'Yamaganda Kaal']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'festival': festival,
      'tithi': tithi,
      'nakshatra': nakshatra,
      'sunrise': sunrise,
      'sunset': sunset,
      'moonrise': moonrise,
      'moonset': moonset,
      'suryaRashi': suryaRashi,
      'chandraRashi': chandraRashi,
      'samvat': samvat,
      'karan': karan,
      'yoga': yoga,
      'dishaShool': dishaShool,
      'chandraNivas': chandraNivas,
      'ritu': ritu,
      'ayan': ayan,
      'brahmaMuhurat': brahmaMuhurat,
      'abhijitMuhurat': abhijitMuhurat,
      'godhuliMuhurat': godhuliMuhurat,
      'amritKalam': amritKalam,
      'rahuKaal': rahuKaal,
      'yamagandaKaal': yamagandaKaal,
    };
  }

  @override
  String toString() {
    return 'PanchangModel(date: $date, festival: $festival, tithi: $tithi, nakshatra: $nakshatra)';
  }
}
