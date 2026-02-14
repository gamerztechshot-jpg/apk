/// Parses date strings from Excel rows - ISO, DMY, Hindi formats.
class PanchangDateParser {
  PanchangDateParser._();

  // ✅ Correct UTF-8 Hindi month map
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

  static int? getHindiMonthNumber(String name) {
    if (name.isEmpty) return null;
    return _hindiMonths[name.trim()];
  }

  static DateTime? _parseDateStatic(String rawDate, bool isHindi) {
    try {
      if (rawDate.trim().isEmpty) return null;

      // ISO format (2026-02-13)
      final isoMatch = RegExp(r"^\d{4}-\d{2}-\d{2}").firstMatch(rawDate);
      if (isoMatch != null) {
        final dt = DateTime.parse(rawDate);
        return DateTime.utc(dt.year, dt.month, dt.day);
      }

      // dd-mm-yyyy or dd/mm/yyyy
      final dmyMatch =
          RegExp(r"^(\d{1,2})[-/](\d{1,2})[-/](\d{4})").firstMatch(rawDate);
      if (dmyMatch != null) {
        final d = int.parse(dmyMatch.group(1)!);
        final m = int.parse(dmyMatch.group(2)!);
        final y = int.parse(dmyMatch.group(3)!);
        return DateTime.utc(y, m, d);
      }

      // Excel serial date
      final numVal = double.tryParse(rawDate.trim());
      if (numVal != null) {
        final base = DateTime.utc(1899, 12, 30);
        final dt = base.add(Duration(days: numVal.round()));
        return DateTime.utc(dt.year, dt.month, dt.day);
      }

      // Hindi format: 13 फ़रवरी, 2026 शुक्रवार
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

      // English format fallback: 13 February 2026
      final cleaned = rawDate.replaceAll(',', '');
      final parts = cleaned.split(' ');
      if (parts.length >= 3) {
        final day = int.tryParse(parts[0]);
        final monthName = parts[1].toLowerCase();
        final year = int.tryParse(parts[2]);

        const engMonths = {
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

        final month = engMonths[monthName];

        if (day != null && month != null && year != null) {
          return DateTime.utc(year, month, day);
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  static DateTime? parse(String rawDate, bool isHindi) {
    return _parseDateStatic(rawDate, isHindi);
  }

  /// Parse date for public API (used by findPanchangForDate).
  static DateTime? parseForLookup(String rawDate, {bool? isHindi}) {
    return _parseDateStatic(rawDate, isHindi ?? false);
  }
}
