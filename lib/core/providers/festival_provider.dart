import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:excel/excel.dart' as excel;
import 'package:intl/intl.dart';
import '../models/festival_model.dart';

class FestivalProvider extends ChangeNotifier {
  List<Festival> _festivals = [];
  bool _isLoading = false;
  String? _error;
  bool _hasLoaded = false;

  List<Festival> get festivals => _festivals;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasLoaded => _hasLoaded;

  Future<void> fetchFestivals(
    String languageCode, {
    bool forceRefresh = false,
  }) async {
    if (_hasLoaded && !forceRefresh) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final festivals = await _fetchFestivalsFromExcel(languageCode);
      _festivals = festivals;
      _hasLoaded = true;
      _isLoading = false;

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Festival>> _fetchFestivalsFromExcel(String languageCode) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              'https://fwhblztexcyxjrfhrrsb.supabase.co/storage/v1/object/public/punchang/festival_sheet.xlsx',
            ),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                'Request timeout - please check your internet connection',
              );
            },
          );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to download Excel file: ${response.statusCode}',
        );
      }

      final bytes = response.bodyBytes;
      final excelFile = excel.Excel.decodeBytes(bytes);
      final sheet = excelFile.tables['Sheet1'] ?? excelFile.tables.values.first;

      if (excelFile.tables.isEmpty) {
        throw Exception('No sheet found in Excel file');
      }

      final festivals = <Festival>[];
      final today = DateTime.now();

      final useEnglish = languageCode == 'en';

      final dateCol = 3;
      final festivalCol = useEnglish ? 4 : 1;
      final monthCol = useEnglish ? 5 : 2;
      final imageCol = 6;

      for (int i = 1; i < sheet.maxRows; i++) {
        final row = sheet.rows[i];
        final requiredLength = 7;
        if (row.length < requiredLength) {
          continue;
        }

        try {
          final dateStr = row[dateCol]?.value?.toString() ?? '';
          if (dateStr.isEmpty) continue;

          final parsedDate = _parseDate(dateStr);
          if (parsedDate == null) {
            continue;
          }

          if (parsedDate.isBefore(today.subtract(const Duration(days: 1)))) {
            continue;
          }

          final festivalName = row[festivalCol]?.value?.toString() ?? '';
          final monthName = row[monthCol]?.value?.toString() ?? '';

          if (useEnglish && festivalName.isEmpty) {
            final hindiFestivalName = row[1]?.value?.toString() ?? '';
            final hindiMonthName = row[2]?.value?.toString() ?? '';

            if (hindiFestivalName.isNotEmpty) {
              final festival = Festival(
                date: row[0]?.value?.toString() ?? dateStr,
                festivalName: hindiFestivalName,
                month: hindiMonthName,
                imageUrl: row[imageCol]?.value?.toString(),
                parsedDate: parsedDate,
              );
              festivals.add(festival);
            }
          } else {
            String displayDate = dateStr;
            if (!useEnglish) {
              displayDate = row[0]?.value?.toString() ?? dateStr;
            }

            final festival = Festival(
              date: displayDate,
              festivalName: festivalName,
              month: monthName,
              imageUrl: row[imageCol]?.value?.toString(),
              parsedDate: parsedDate,
            );

            if (festival.festivalName.isNotEmpty) {
              festivals.add(festival);
            }
          }
        } catch (e) {
          continue;
        }
      }

      festivals.sort((a, b) => a.parsedDate.compareTo(b.parsedDate));

      return festivals;
    } catch (e) {
      rethrow;
    }
  }

  DateTime? _parseDate(String dateStr) {
    try {
      final isoDate = DateTime.tryParse(dateStr);
      if (isoDate != null) {
        return isoDate;
      }

      final hindiDate = _parseHindiDate(dateStr);
      if (hindiDate != null) {
        return hindiDate;
      }

      final englishDate = _parseEnglishDate(dateStr);
      if (englishDate != null) {
        return englishDate;
      }

      final formats = [
        'dd/MM/yyyy',
        'd/MM/yyyy',
        'dd/M/yyyy',
        'd/M/yyyy',
        'yyyy-MM-dd',
        'MM/dd/yyyy',
        'd-MMM-yyyy',
        'dd-MMM-yyyy',
        'dd MMM yyyy',
        'd MMM yyyy',
        'dd MMMM yyyy',
        'd MMMM yyyy',
      ];

      for (final format in formats) {
        try {
          return DateFormat(format).parse(dateStr);
        } catch (_) {
          continue;
        }
      }

      return DateTime.parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  DateTime? _parseEnglishDate(String dateStr) {
    try {
      final formats = [
        'dd MMM yyyy',
        'd MMM yyyy',
        'dd MMMM yyyy',
        'd MMMM yyyy',
        'dd/MM/yyyy',
        'd/MM/yyyy',
        'MM/dd/yyyy',
        'yyyy-MM-dd',
      ];

      for (final format in formats) {
        try {
          final parsedDate = DateFormat(format).parse(dateStr);
          return parsedDate;
        } catch (_) {
          continue;
        }
      }

      final directParse = DateTime.parse(dateStr);
      return directParse;
    } catch (e) {
      return null;
    }
  }

  DateTime? _parseHindiDate(String dateStr) {
    try {
      final regex = RegExp(r'(\d+)\s+([^\s,]+),\s*(\d{4})');
      final match = regex.firstMatch(dateStr);

      if (match == null) return null;

      final day = int.parse(match.group(1)!);
      final monthName = match.group(2)!;
      final year = int.parse(match.group(3)!);

      final monthMap = {
        'जनवरी': 1,
        'फरवरी': 2,
        'फरवरी': 2,
        'मार्च': 3,
        'अप्रैल': 4,
        'मई': 5,
        'जून': 6,
        'जुलाई': 7,
        'अगस्त': 8,
        'सितंबर': 9,
        'सितंबर': 9,
        'अक्टूबर': 10,
        'नवंबर': 11,
        'नवंबर': 11,
        'दिसंबर': 12,
        'दिसंबर': 12,
      };

      final month = monthMap[monthName];
      if (month == null) {
        return null;
      }

      final parsedDate = DateTime(year, month, day);
      return parsedDate;
    } catch (e) {
      return null;
    }
  }
}
