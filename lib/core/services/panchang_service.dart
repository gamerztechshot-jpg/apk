// core/services/panchang_service.dart
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:convert';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/panchang_model.dart';
import 'cache_service.dart';
import '../config/supabase_config.dart';

class PanchangService {
  // URLs for Excel files (Supabase bucket "punchang") - use SupabaseConfig for single source of truth
  static String get hindiPanchangUrl =>
      '${SupabaseConfig.supabaseUrl}/storage/v1/object/public/punchang/punchang_hindi.xlsx';
  static String get englishPanchangUrl =>
      '${SupabaseConfig.supabaseUrl}/storage/v1/object/public/punchang/punchang_english.xlsx';

  // In-memory per-day cache to avoid repeated parsing/network calls
  final Map<String, PanchangModel> _memoryCache = {};

  // File cache keys
  static const String _fileCachePrefix = 'panchang_file_';
  static const String _fileTimestampPrefix = 'panchang_file_ts_';
  static const Duration _fileCacheDuration = Duration(
    hours: 12,
  ); // 12 hours for Excel files

  static SharedPreferences? _prefs;

  /// Initialize SharedPreferences for file caching
  static Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Check if cached Excel file is still valid
  static Future<bool> _isFileCacheValid(String language) async {
    await _initPrefs();
    final timestampKey = '$_fileTimestampPrefix$language';
    final timestamp = _prefs?.getInt(timestampKey);

    if (timestamp == null) return false;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();

    return now.difference(cacheTime) < _fileCacheDuration;
  }

  /// Cache Excel file bytes
  static Future<void> _cacheExcelFile(String language, Uint8List bytes) async {
    await _initPrefs();
    try {
      final fileKey = '$_fileCachePrefix$language';
      final timestampKey = '$_fileTimestampPrefix$language';

      // Convert bytes to base64 string for storage
      final base64String = base64Encode(bytes);

      await _prefs!.setString(fileKey, base64String);
      await _prefs!.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {}
  }

  /// Get cached Excel file bytes
  static Future<Uint8List?> _getCachedExcelFile(String language) async {
    await _initPrefs();
    try {
      if (!await _isFileCacheValid(language)) {
        return null;
      }

      final fileKey = '$_fileCachePrefix$language';
      final base64String = _prefs!.getString(fileKey);

      if (base64String != null) {
        final bytes = base64Decode(base64String);
        return bytes;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Clear Excel file cache
  static Future<void> _clearExcelFileCache(String language) async {
    await _initPrefs();
    try {
      final fileKey = '$_fileCachePrefix$language';
      final timestampKey = '$_fileTimestampPrefix$language';

      await _prefs!.remove(fileKey);
      await _prefs!.remove(timestampKey);
    } catch (e) {}
  }

  /// Parse cached PanchangModel that handles both serialization formats
  PanchangModel _parseCachedPanchangModel(
    Map<String, dynamic> json,
    bool isHindi,
  ) {
    // Always use toMap format for cached data
    return PanchangModel(
      date: json['date']?.toString() ?? '',
      festival: json['festival']?.toString() ?? '',
      tithi: json['tithi']?.toString() ?? '',
      nakshatra: json['nakshatra']?.toString() ?? '',
      sunrise: json['sunrise']?.toString() ?? '',
      sunset: json['sunset']?.toString() ?? '',
      moonrise: json['moonrise']?.toString() ?? '',
      moonset: json['moonset']?.toString() ?? '',
      suryaRashi: json['suryaRashi']?.toString() ?? '',
      chandraRashi: json['chandraRashi']?.toString() ?? '',
      samvat: json['samvat']?.toString() ?? '',
      karan: json['karan']?.toString() ?? '',
      yoga: json['yoga']?.toString() ?? '',
      dishaShool: json['dishaShool']?.toString() ?? '',
      chandraNivas: json['chandraNivas']?.toString() ?? '',
      ritu: json['ritu']?.toString() ?? '',
      ayan: json['ayan']?.toString() ?? '',
      brahmaMuhurat: json['brahmaMuhurat']?.toString() ?? '',
      abhijitMuhurat: json['abhijitMuhurat']?.toString() ?? '',
      godhuliMuhurat: json['godhuliMuhurat']?.toString() ?? '',
      amritKalam: json['amritKalam']?.toString() ?? '',
      rahuKaal: json['rahuKaal']?.toString() ?? '',
      yamagandaKaal: json['yamagandaKaal']?.toString() ?? '',
    );
  }

  String _cacheKey(DateTime date, bool isHindi) {
    final target = DateTime.utc(date.year, date.month, date.day);
    return '${target.toIso8601String()}_${isHindi ? 'hi' : 'en'}';
  }

  void _remember(DateTime date, bool isHindi, PanchangModel model) {
    _memoryCache[_cacheKey(date, isHindi)] = model;
  }

  PanchangModel? _getFromMemory(DateTime date, bool isHindi) {
    return _memoryCache[_cacheKey(date, isHindi)];
  }

  Future<PanchangModel?> fetchPanchangForDate(
    DateTime date,
    bool isHindi, {
    bool forceRefresh = false,
  }) async {
    final language = isHindi ? 'hindi' : 'english';
    final target = DateTime.utc(date.year, date.month, date.day);

    // 1) Memory cache
    final mem = _getFromMemory(target, isHindi);
    if (!forceRefresh && mem != null) {
      return mem;
    }

    // 2) Parsed data cache
    if (!forceRefresh) {
      final cachedData = await CacheService.getCachedPanchangData(language);
      if (cachedData != null) {
        final models = <PanchangModel>[];
        for (final item in cachedData) {
          try {
            if (item is Map) {
              models.add(_parseCachedPanchangModel(
                  Map<String, dynamic>.from(item), isHindi));
            }
          } catch (_) {}
        }
        final match = findPanchangForDate(models, target, isHindi);
        if (match != null) {
          _remember(target, isHindi, match);
          return match;
        }
      }
    }

    if (!forceRefresh) {
      final cachedBytes = await _getCachedExcelFile(language);
      if (cachedBytes != null) {
        final match = await _findSinglePanchangInExcelBytes(
          cachedBytes,
          isHindi,
          target,
        );
        if (match != null) {
          _remember(target, isHindi, match);
          return match;
        }
      }
    }

    final url = isHindi ? hindiPanchangUrl : englishPanchangUrl;
    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Accept':
                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
              'User-Agent': 'Karmasu/1.0',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        throw Exception(
          'Failed to load panchang data: ${response.statusCode} - ${response.reasonPhrase}',
        );
      }

      final bytes = response.bodyBytes;
      await _cacheExcelFile(language, bytes);

      final match = await _findSinglePanchangInExcelBytes(
        bytes,
        isHindi,
        target,
      );

      if (match != null) {
        _remember(target, isHindi, match);
        // Store/merge parsed cache for this date to accelerate upcoming lookups
        final existing = await CacheService.getCachedPanchangData(language);
        final merged = _mergeCachedEntry(existing, match, isHindi);
        await CacheService.cachePanchangData(language, merged);
        return match;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<PanchangModel?> _findSinglePanchangInExcelBytes(
    Uint8List? bytes,
    bool isHindi,
    DateTime target,
  ) async {
    if (bytes == null || bytes.isEmpty) return null;
    try {
      final result = await compute<FindSingleParams, Map<String, dynamic>?>(
        PanchangService._findSingleInIsolate,
        FindSingleParams(
          bytes,
          isHindi,
          target.year,
          target.month,
          target.day,
        ),
      );
      if (result != null) {
        final model = PanchangModel.fromMap(result, isHindi);
        return model;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Map<String, dynamic>? _findSingleInIsolate(FindSingleParams params) {
    final bytes = params.bytes;
    final isHindi = params.isHindi;
    final ty = params.targetYear;
    final tm = params.targetMonth;
    final td = params.targetDay;
    try {
      final excel = Excel.decodeBytes(bytes);
      final sheetNames = excel.tables.keys.toList()..sort((a, b) {
        final aHas = _sheetLikelyHasMonth(a, tm);
        final bHas = _sheetLikelyHasMonth(b, tm);
        if (aHas && !bHas) return -1;
        if (!aHas && bHas) return 1;
        return 0;
      });
      for (final sheetName in sheetNames) {
        final table = excel.tables[sheetName]!;
        if (table.rows.length < 2) continue;
        final headers = table.rows[0]
            .map((cell) => cell?.value?.toString() ?? '')
            .toList();
        final dateColIdx = _findDateColumnIndex(headers, isHindi);

        for (int i = 1; i < table.rows.length; i++) {
          final row = table.rows[i];
          if (row.isEmpty) continue;
          final dateVal = dateColIdx >= 0 && dateColIdx < row.length
              ? row[dateColIdx]?.value?.toString() ?? ''
              : (row.isNotEmpty ? row[0]?.value?.toString() ?? '' : '');
          if (dateVal.trim().isEmpty) continue;
          final parsedDate = _parseDateStatic(dateVal, isHindi);
          if (parsedDate == null) continue;
          if (parsedDate.year != ty || parsedDate.month != tm || parsedDate.day != td) {
            continue;
          }

          final Map<String, dynamic> rowData = {};
          for (int j = 0; j < headers.length && j < row.length; j++) {
            rowData[headers[j]] = row[j]?.value?.toString() ?? '';
          }
          final std = _normalizeRowForModel(rowData, isHindi);
          if (std == null || (std[isHindi ? 'दिनांक' : 'Date'] ?? '').toString().trim().isEmpty) continue;
          return std;
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  static bool _sheetLikelyHasMonth(String name, int month) {
    final n = name.toLowerCase();
    const en = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
    const hi = ['जन', 'फर', 'मार्च', 'अप्रैल', 'मई', 'जून', 'जुल', 'अग', 'सित', 'अक्टूबर', 'नव', 'दिस'];
    if (month >= 1 && month <= 12) {
      if (n.contains(en[month - 1]) || n.contains(month.toString())) return true;
      if (hi[month - 1].length <= 3 && n.contains(hi[month - 1])) return true;
    }
    return false;
  }

  static int _findDateColumnIndex(List<String> headers, bool isHindi) {
    const enKeys = ['date', 'daydate', 'datetime', 'दिनांक', 'तारीख'];
    for (int i = 0; i < headers.length; i++) {
      final h = headers[i].trim().toLowerCase().replaceAll(' ', '');
      for (final k in enKeys) {
        if (h.contains(k.replaceAll(' ', '')) || h == k) return i;
      }
    }
    return 0;
  }

  static Map<String, dynamic>? _normalizeRowForModel(Map<String, dynamic> row, bool isHindi) {
    final norm = <String, String>{};
    for (final e in row.entries) {
      final k = (e.key ?? '').toString().trim();
      final v = (e.value ?? '').toString();
      if (k.isEmpty) continue;
      norm[k.toLowerCase().replaceAll(' ', '').replaceAll('_', '')] = v;
    }
    String pick(List<String> keys) {
      for (final k in keys) {
        final n = k.toLowerCase().replaceAll(' ', '');
        for (final e in norm.entries) {
          if (e.key == n || e.key.contains(n)) return e.value;
        }
      }
      return '';
    }
    if (isHindi) {
      return {
        'दिनांक': pick(['दिनांक', 'तारीख', 'date']),
        'त्यौहार': pick(['त्यौहार', 'festival']),
        'तिथि': pick(['तिथि', 'tithi']),
        'नक्षत्र': pick(['नक्षत्र', 'nakshatra']),
        'सूर्योदय': pick(['सूर्योदय', 'sunrise']),
        'सूर्यास्त': pick(['सूर्यास्त', 'sunset']),
        'चन्द्रोदय': pick(['चन्द्रोदय', 'moonrise']),
        'चन्द्रास्त': pick(['चन्द्रास्त', 'moonset']),
        'सूर्य राशि': pick(['सूर्यराशि', 'सूर्य राशि', 'surya']),
        'चंद्र राशि': pick(['चंद्रराशि', 'चंद्र राशि', 'chandra']),
        'विक्रम संवत': pick(['विक्रम संवत', 'samvat']),
        'करण': pick(['करण', 'karan']),
        'योग': pick(['योग', 'yoga']),
        'दिशाशूल': pick(['दिशाशूल', 'dishashool']),
        'चंद्र निवास': pick(['चंद्र निवास', 'chandranivas']),
        'ऋतु': pick(['ऋतु', 'ritu']),
        'अयन': pick(['अयन', 'ayan']),
        'ब्रह्म मुहूर्त': pick(['ब्रह्म मुहूर्त', 'brahmamuhurat']),
        'अभिजित मुहूर्त': pick(['अभिजित मुहूर्त', 'abhijitmuhurat']),
        'गोधूलि मुहूर्त': pick(['गोधूलि मुहूर्त', 'godhulimuhurat']),
        'अमृत काल': pick(['अमृत काल', 'amritkalam']),
        'राहुकाल': pick(['राहुकाल', 'rahukaal']),
        'यमघण्टकाल': pick(['यमघण्टकाल', 'yamagandakaal']),
      };
    }
    return {
      'Date': pick(['date', 'daydate', 'datetime', 'दिनांक']),
      'Festival': pick(['festival', 'त्यौहार']),
      'Tithi': pick(['tithi', 'तिथि']),
      'Nakshatra': pick(['nakshatra', 'नक्षत्र']),
      'Sunrise': pick(['sunrise', 'सूर्योदय']),
      'Sunset': pick(['sunset', 'सूर्यास्त']),
      'Moonrise': pick(['moonrise', 'चन्द्रोदय']),
      'Moonset': pick(['moonset', 'चन्द्रास्त']),
      'Surya Rashi': pick(['suryarashi', 'surya rashi', 'सूर्य राशि']),
      'Chandra Rashi': pick(['chandrarashi', 'chandra rashi', 'चंद्र राशि']),
      'Samvat': pick(['samvat', 'विक्रम संवत']),
      'Karan': pick(['karan', 'करण']),
      'Yoga': pick(['yoga', 'योग']),
      'Disha Shool': pick(['dishashool', 'दिशाशूल']),
      'Chandra Nivas': pick(['chandranivas', 'चंद्र निवास']),
      'Ritu': pick(['ritu', 'ऋतु']),
      'Ayan': pick(['ayan', 'अयन']),
      'Brahma Muhurat': pick(['brahmamuhurat', 'ब्रह्म मुहूर्त']),
      'Abhijit Muhurat': pick(['abhijitmuhurat', 'अभिजित मुहूर्त']),
      'Godhuli Muhurat': pick(['godhulimuhurat', 'गोधूलि मुहूर्त']),
      'Amrit Kalam': pick(['amritkalam', 'अमृत काल']),
      'Rahu Kaal': pick(['rahukaal', 'राहुकाल']),
      'Yamaganda Kaal': pick(['yamagandakaal', 'यमघण्टकाल']),
    };
  }

  static const Map<String, int> _hindiMonths = {
    'जनवरी': 1,
    'फ़रवरी': 2,
    'फरवरी': 2,
    'मार्च': 3,
    'अप्रैल': 4,
    'मई': 5,
    'जून': 6,
    'जुलाई': 7,
    'अगस्त': 8,
    'सितम्बर': 9,
    'सितंबर': 9,
    'अक्टूबर': 10,
    'नवम्बर': 11,
    'नवंबर': 11,
    'दिसम्बर': 12,
    'दिसंबर': 12,
  };

  static DateTime? _parseDateStatic(String rawDate, bool isHindi) {
    try {
      if (rawDate.trim().isEmpty) return null;
      final isoMatch = RegExp(r"^\d{4}-\d{2}-\d{2}").firstMatch(rawDate);
      if (isoMatch != null) {
        final dt = DateTime.parse(rawDate);
        return DateTime.utc(dt.toUtc().year, dt.toUtc().month, dt.toUtc().day);
      }
      final dmyMatch = RegExp(r"^(\d{1,2})[-/](\d{1,2})[-/](\d{4})").firstMatch(rawDate);
      if (dmyMatch != null) {
        final d = int.tryParse(dmyMatch.group(1)!);
        final m = int.tryParse(dmyMatch.group(2)!);
        final y = int.tryParse(dmyMatch.group(3)!);
        if (d != null && m != null && y != null && m >= 1 && m <= 12) {
          return DateTime.utc(y, m, d);
        }
      }
      final numVal = double.tryParse(rawDate.trim());
      if (numVal != null) {
        final base = DateTime.utc(1899, 12, 30);
        final dt = base.add(Duration(days: numVal.round()));
        return DateTime.utc(dt.year, dt.month, dt.day);
      }
      final hindiMatch =
          RegExp(r"(\d{1,2})\s+([^\s,]+),?\s+(\d{4})").firstMatch(rawDate);
      if (hindiMatch != null) {
        final day = int.tryParse(hindiMatch.group(1)!);
        final monthName = hindiMatch.group(2)!.trim();
        final year = int.tryParse(hindiMatch.group(3)!);

        final month = _hindiMonths[monthName];

        if (day != null && month != null && year != null) {
          return DateTime.utc(year, month, day);
        }
      }
      final cleaned = rawDate
          .replaceAll(RegExp(r"\s*-\s*"), ' ')
          .replaceAll(RegExp(r","), '')
          .split(RegExp(r"\s+"))
          .join(' ');
      final engMonths = {
        'january': 1, 'jan': 1, 'february': 2, 'feb': 2, 'march': 3, 'mar': 3,
        'april': 4, 'apr': 4, 'may': 5, 'june': 6, 'jun': 6, 'july': 7, 'jul': 7,
        'august': 8, 'aug': 8, 'september': 9, 'sep': 9, 'october': 10, 'oct': 10,
        'november': 11, 'nov': 11, 'december': 12, 'dec': 12,
      };
      final parts = cleaned.split(' ');
      if (parts.length < 3) return null;
      final day = int.tryParse(parts[0]);
      final year = int.tryParse(parts[2]);
      if (day == null || year == null) return null;
      final month = engMonths[parts[1].toLowerCase()] ?? _hindiMonths[parts[1]];
      if (month == null) return null;
      return DateTime.utc(year, month, day);
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>> _mergeCachedEntry(
    List<dynamic>? existing,
    PanchangModel entry,
    bool isHindi,
  ) {
    final list = <Map<String, dynamic>>[];
    final targetDate = parsePanchangDate(entry.date, isHindi: isHindi);
    if (existing != null) {
      for (final item in existing) {
        final model = _parseCachedPanchangModel(
          Map<String, dynamic>.from(item as Map),
          isHindi,
        );
        final d = parsePanchangDate(model.date, isHindi: isHindi);
        if (d != null &&
            targetDate != null &&
            d.year == targetDate.year &&
            d.month == targetDate.month &&
            d.day == targetDate.day) {
          // Skip duplicate date
          continue;
        }
        list.add(model.toMap());
      }
    }
    list.add(entry.toMap());
    return list;
  }

  Future<List<PanchangModel>> fetchPanchangData(
    bool isHindi, {
    bool forceRefresh = false,
  }) async {
    try {
      final language = isHindi ? 'hindi' : 'english';
      final todayUtc = DateTime.now().toUtc();

      if (!forceRefresh) {
        final cachedData = await CacheService.getCachedPanchangData(language);
        if (cachedData != null) {
          final parsed = cachedData
              .map((json) => _parseCachedPanchangModel(json, isHindi))
              .toList();
          _logSampleRows(parsed, language);
          final hasToday = findPanchangForDate(parsed, todayUtc, isHindi) != null;
          if (hasToday) {
            return parsed;
          }
        }
      }

      if (!forceRefresh) {
        final cachedExcelBytes = await _getCachedExcelFile(language);
        if (cachedExcelBytes != null) {
          final panchangData = await _parseExcelDataAsync(
            cachedExcelBytes,
            isHindi,
          );

          final dataToCache = panchangData
              .map((model) => model.toMap())
              .toList();
          await CacheService.cachePanchangData(language, dataToCache);
          final hasToday = findPanchangForDate(panchangData, todayUtc, isHindi) != null;
          if (hasToday) {
            return panchangData;
          }
        }
      }

      final url = isHindi ? hindiPanchangUrl : englishPanchangUrl;

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Accept':
                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
              'User-Agent': 'Karmasu/1.0',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        if (bytes.isEmpty) {
          throw Exception('Empty response received');
        }

        await _cacheExcelFile(language, bytes);

        final panchangData = await _parseExcelDataAsync(bytes, isHindi);

        final dataToCache = panchangData.map((model) => model.toMap()).toList();
        await CacheService.cachePanchangData(language, dataToCache);

        return panchangData;
      } else {
        throw Exception(
          'Failed to load panchang data: ${response.statusCode} - ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return [];
    }
  }

  List<PanchangModel> _parseExcelData(Uint8List bytes, bool isHindi) {
    try {
      final excel = Excel.decodeBytes(bytes);

      final panchangList = <PanchangModel>[];

      for (final sheetName in excel.tables.keys) {
        final table = excel.tables[sheetName]!;
        if (table.rows.length < 2) continue;

        final headers = table.rows[0]
            .map((cell) => cell?.value?.toString() ?? '')
            .toList();

        for (int i = 1; i < table.rows.length; i++) {
          final row = table.rows[i];
          if (row.isEmpty) continue;

          final Map<String, String> normMap = {};
          for (int j = 0; j < headers.length && j < row.length; j++) {
            final keyRaw = (headers[j] ?? '').toString();
            final key = _normalizeKey(keyRaw);
            final val = row[j]?.value?.toString() ?? '';
            if (key.isNotEmpty) normMap[key] = val;
          }

          final std = <String, String>{};
          if (isHindi) {
            std['दिनांक'] = _pick(normMap, [
              'दिनांक',
              'तारीख',
              'तिथidate',
              'date',
            ]);
            std['त्यौहार'] = _pick(normMap, ['त्यौहार', 'त्योहार', 'festival']);
            std['तिथि'] = _pick(normMap, ['तिथि']);
            std['नक्षत्र'] = _pick(normMap, ['नक्षत्र']);
            std['सूर्योदय'] = _pick(normMap, ['सूर्योदय']);
            std['सूर्यास्त'] = _pick(normMap, ['सूर्यास्त']);
            std['चन्द्रोदय'] = _pick(normMap, ['चन्द्रोदय']);
            std['चन्द्रास्त'] = _pick(normMap, ['चन्द्रास्त']);
            std['सूर्य राशि'] = _pick(normMap, [
              'सूर्यराशि',
              'सूर्य राशि',
              'sunsign',
              'surya',
            ]);
            std['चंद्र राशि'] = _pick(normMap, [
              'चंद्रराशि',
              'चंद्र राशि',
              'moonsign',
              'chandra',
            ]);
          } else {
            std['Date'] = _pick(normMap, ['date', 'daydate', 'datetime']);
            std['Festival'] = _pick(normMap, ['festival', 'fest']);
            std['Tithi'] = _pick(normMap, ['tithi']);
            std['Nakshatra'] = _pick(normMap, ['nakshatra']);
            std['Sunrise'] = _pick(normMap, ['sunrise']);
            std['Sunset'] = _pick(normMap, ['sunset']);
            std['Moonrise'] = _pick(normMap, ['moonrise']);
            std['Moonset'] = _pick(normMap, ['moonset']);
            std['Surya Rashi'] = _pick(normMap, [
              'sunsign',
              'surya',
              'suryaRashi',
            ]);
            std['Chandra Rashi'] = _pick(normMap, [
              'moonsign',
              'chandra',
              'chandraRashi',
            ]);
          }

          if ((std[isHindi ? 'दिनांक' : 'Date'] ?? '').trim().isEmpty) {
            std[isHindi ? 'दिनांक' : 'Date'] = row[0]?.value?.toString() ?? '';
          }

          void ensure(String k) {
            std[k] = std[k] ?? '';
          }

          if (isHindi) {
            for (final k in [
              'विक्रम संवत',
              'करण',
              'योग',
              'दिशाशूल',
              'चंद्र निवास',
              'ऋतु',
              'अयन',
              'ब्रह्म मुहूर्त',
              'अभिजित मुहूर्त',
              'गोधूली मुहूर्त',
              'अमृत काल',
              'राहुकाल',
              'यमघण्टकाल',
            ]) {
              ensure(k);
            }
          } else {
            for (final k in [
              'Samvat',
              'Karan',
              'Yoga',
              'Disha Shool',
              'Chandra Nivas',
              'Ritu',
              'Ayan',
              'Brahma Muhurat',
              'Abhijit Muhurat',
              'Godhuli Muhurat',
              'Amrit Kalam',
              'Rahu Kaal',
              'Yamaganda Kaal',
            ]) {
              ensure(k);
            }
          }

          try {
            final p = PanchangModel.fromMap(std, isHindi);
            if (p.date.trim().isNotEmpty) panchangList.add(p);
          } catch (_) {
            continue;
          }
        }
      }

      return panchangList;
    } catch (e) {
      return [];
    }
  }

  Future<List<PanchangModel>> _parseExcelDataAsync(
    Uint8List bytes,
    bool isHindi,
  ) async {
    try {
      return await compute<ParseParams, List<PanchangModel>>(
        _parseInIsolate,
        ParseParams(bytes, isHindi),
      );
    } catch (_) {
      return _parseExcelData(bytes, isHindi);
    }
  }

  static List<PanchangModel> _parseInIsolate(ParseParams params) {
    final bytes = params.bytes;
    final isHindi = params.isHindi;
    final excel = Excel.decodeBytes(bytes);
    final list = <PanchangModel>[];
    for (final sheetName in excel.tables.keys) {
      final table = excel.tables[sheetName]!;
      if (table.rows.length < 2) continue;
      final headers = table.rows[0]
          .map((cell) => cell?.value?.toString() ?? '')
          .toList();
      for (int i = 1; i < table.rows.length; i++) {
        final row = table.rows[i];
        if (row.isEmpty) continue;
        final Map<String, dynamic> rowData = {};
        for (int j = 0; j < headers.length && j < row.length; j++) {
          rowData[headers[j]] = row[j]?.value?.toString() ?? '';
        }
        try {
          final p = PanchangModel.fromMap(rowData, isHindi);
          if (p.date.trim().isNotEmpty) list.add(p);
        } catch (_) {
          continue;
        }
      }
    }
    return list;
  }

  static String _normalizeKey(String raw) {
    final k = raw.trim().toLowerCase().replaceAll(' ', '').replaceAll('_', '');
    return k;
  }

  static String _pick(Map<String, String> m, List<String> keys) {
    for (final k in keys) {
      final n = _normalizeKey(k);
      final hit = m.entries.firstWhere(
        (e) => _normalizeKey(e.key) == n,
        orElse: () => const MapEntry<String, String>('', ''),
      );
      if (hit.key.isNotEmpty && (hit.value).trim().isNotEmpty) return hit.value;
    }
    return '';
  }

  static void _logSampleRows(List<PanchangModel> rows, String lang) {
    if (rows.length < 2) {
      if (rows.isNotEmpty) {
        final r = rows.first;
      }
      return;
    }
    final r1 = rows[0];
    final r2 = rows[1];
  }

  PanchangModel? getTodayPanchang(List<PanchangModel> panchangList) { 
    final today = DateTime.now();
    final found = findPanchangForDate(panchangList, today, null);
    if (found != null) return found;
    return null;
  }


  String _getMonthName(int month, bool isHindi) {
    if (isHindi) {
      const months = [
        '',
        'जनवरी',
        'फरवरी',
        'मार्च',
        'अप्रैल',
        'मई',
        'जून',
        'जुलाई',
        'अगस्त',
        'सितम्बर',
        'अक्टूबर',
        'नवम्बर',
        'दिसम्बर',
      ];
      return months[month];
    } else {
      const months = [
        '',
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      return months[month];
    }
  }

  DateTime? parsePanchangDate(String rawDate, {bool? isHindi}) {
    try {
      if (rawDate.trim().isEmpty) return null;

      final isoMatch = RegExp(r"^\d{4}-\d{2}-\d{2}").firstMatch(rawDate);
      if (isoMatch != null) {
        final dt = DateTime.parse(rawDate);
        return DateTime.utc(dt.toUtc().year, dt.toUtc().month, dt.toUtc().day);
      }

      final numVal = double.tryParse(rawDate);
      if (numVal != null) {
        final base = DateTime.utc(1899, 12, 30);
        final dt = base.add(Duration(days: numVal.round()));
        return DateTime.utc(dt.year, dt.month, dt.day);
      }

      final cleaned = rawDate
          .replaceAll(RegExp(r"\s*-\s*"), ' ')
          .replaceAll(RegExp(r","), '')
          .split(RegExp(r"\s+"))
          .join(' ');

      final engMonths = {
        'january': 1,
        'february': 2,
        'march': 3,
        'april': 4,
        'may': 5,
        'june': 6,
        'july': 7,
        'august': 8,
        'september': 9,
        'october': 10,
        'november': 11,
        'december': 12,
      };

      final hinMonths = {
        'जनवरी': 1,
        'फरवरी': 2,
        'मार्च': 3,
        'अप्रैल': 4,
        'मई': 5,
        'जून': 6,
        'जुलाई': 7,
        'अगस्त': 8,
        'सितम्बर': 9,
        'सितंबर': 9,
        'अक्टूबर': 10,
        'नवम्बर': 11,
        'नवंबर': 11,
        'दिसम्बर': 12,
        'दिसंबर': 12,
      };

      final parts = cleaned.split(' ');
      if (parts.length < 3) return null;

      int? day = int.tryParse(parts[0]);
      final monthToken = parts[1].toLowerCase();
      final year = int.tryParse(parts[2]);

      if (day == null || year == null) return null;

      int? month = engMonths[monthToken];
      if (month == null) {
        month = hinMonths[parts[1]];
      }
      if (month == null) return null;

      return DateTime.utc(year, month, day);
    } catch (_) {
      return null;
    }
  }

  PanchangModel? findPanchangForDate(
    List<PanchangModel> list,
    DateTime date,
    bool? isHindi,
  ) {
    final target = DateTime.utc(date.year, date.month, date.day);
    for (final p in list) {
      final d = parsePanchangDate(p.date, isHindi: isHindi);
      if (d != null &&
          d.year == target.year &&
          d.month == target.month &&
          d.day == target.day) {
        return p;
      }
    }
    return null;
  }

  Future<List<PanchangModel>> refreshPanchangData(bool isHindi) async {
    final language = isHindi ? 'hindi' : 'english';

    await _clearExcelFileCache(language);
    await CacheService.clearDataTypeCache('panchang_data');

    return await fetchPanchangData(isHindi, forceRefresh: true);
  }

  Future<void> clearPanchangCache() async {
    await CacheService.clearDataTypeCache('panchang_data');

    await _clearExcelFileCache('hindi');
    await _clearExcelFileCache('english');
  }

  Future<Map<String, dynamic>> getPanchangCacheStats() async {
    await _initPrefs();

    try {
      final stats = <String, dynamic>{};

      final hindiFileValid = await _isFileCacheValid('hindi');
      final englishFileValid = await _isFileCacheValid('english');

      final hindiDataCache = await CacheService.getCachedPanchangData('hindi');
      final englishDataCache = await CacheService.getCachedPanchangData(
        'english',
      );

      stats['hindi_file_cached'] = hindiFileValid;
      stats['english_file_cached'] = englishFileValid;
      stats['hindi_data_cached'] = hindiDataCache != null;
      stats['english_data_cached'] = englishDataCache != null;
      stats['hindi_data_entries'] = hindiDataCache?.length ?? 0;
      stats['english_data_entries'] = englishDataCache?.length ?? 0;

      return stats;
    } catch (e) {
      return {};
    }
  }

  Future<void> testCachingFix() async {
    try {
      final englishData1 = await fetchPanchangData(false, forceRefresh: true);

      final englishData2 = await fetchPanchangData(false, forceRefresh: false);

      if (englishData1.isNotEmpty && englishData2.isNotEmpty) {
        final first = englishData1.first;
        final second = englishData2.first;

        if (first.tithi == second.tithi &&
            first.nakshatra == second.nakshatra) {
        } else {
        }
      }
    } catch (e) {}
  }
}

class ParseParams {
  final Uint8List bytes;
  final bool isHindi;
  ParseParams(this.bytes, this.isHindi);
}

class FindSingleParams {
  final Uint8List bytes;
  final bool isHindi;
  final int targetYear;
  final int targetMonth;
  final int targetDay;
  FindSingleParams(
      this.bytes, this.isHindi, this.targetYear, this.targetMonth, this.targetDay);
}