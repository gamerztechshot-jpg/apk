// features/punchang/viewmodels/panchang_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/panchang_provider.dart';
import '../../../core/services/language_service.dart';
import '../../../core/models/panchang_model.dart';

class PanchangViewModel extends ChangeNotifier {
  DateTime _selectedDate = DateTime.now();

  DateTime get selectedDate => _selectedDate;

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  Future<void> loadPanchangData(BuildContext context) async {
    final languageService = Provider.of<LanguageService>(
      context,
      listen: false,
    );
    final isHindi = languageService.isHindi;

    // Fetch data via provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PanchangProvider>(context, listen: false).fetchForDate(
            isHindi,
            date: _selectedDate,
          );
    });
  }

  Future<void> pickDate(
    BuildContext context,
    String helpText,
    String cancelText,
    String confirmText,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year - 1, 1, 1),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
      helpText: helpText,
      cancelText: cancelText,
      confirmText: confirmText,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange.shade600,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
            dialogBackgroundColor: Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.orange.shade600,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setSelectedDate(picked);

      final languageService = Provider.of<LanguageService>(
        context,
        listen: false,
      );
      final isHindi = languageService.isHindi;
      final provider = Provider.of<PanchangProvider>(context, listen: false);
      await provider.fetchForDate(isHindi, date: picked);
    }
  }

  String getPaksha(String tithi, bool isHindi) {
    if (tithi.toLowerCase().contains('shukla') ||
        tithi.toLowerCase().contains('शुक्ल')) {
      return isHindi ? 'शुक्ल पक्ष' : 'Shukla Paksha';
    } else if (tithi.toLowerCase().contains('krishna') ||
        tithi.toLowerCase().contains('कृष्ण')) {
      return isHindi ? 'कृष्ण पक्ष' : 'Krishna Paksha';
    }
    return isHindi ? 'अज्ञात' : 'Unknown';
  }

  String getMonthName(int month, bool isHindi) {
    if (month < 1 || month > 12) return isHindi ? '' : '';
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

  PanchangModel getFallbackPanchangData() {
    final today = DateTime.now();
    return PanchangModel(
      date: '${today.day} ${getMonthName(today.month, false)} ${today.year}',
      festival: 'No festival data available',
      tithi: 'Data unavailable',
      nakshatra: 'Data unavailable',
      sunrise: '06:00 AM',
      sunset: '06:00 PM',
      moonrise: 'Data unavailable',
      moonset: 'Data unavailable',
      suryaRashi: 'Data unavailable',
      chandraRashi: 'Data unavailable',
      samvat: 'Data unavailable',
      karan: 'Data unavailable',
      yoga: 'Data unavailable',
      dishaShool: 'Data unavailable',
      chandraNivas: 'Data unavailable',
      ritu: 'Data unavailable',
      ayan: 'Data unavailable',
      brahmaMuhurat: '04:00 AM - 05:00 AM',
      abhijitMuhurat: '11:30 AM - 12:30 PM',
      godhuliMuhurat: '06:00 PM - 06:30 PM',
      amritKalam: 'Data unavailable',
      rahuKaal: 'Data unavailable',
      yamagandaKaal: 'Data unavailable',
    );
  }

  bool isFallbackData(PanchangModel panchang) {
    return panchang.tithi.contains('Data unavailable') ||
        panchang.nakshatra.contains('Data unavailable') ||
        panchang.suryaRashi.contains('Data unavailable') ||
        panchang.chandraRashi.contains('Data unavailable');
  }

  String getDayName(int weekday, [bool isHindi = false]) {
    if (weekday < 1 || weekday > 7) return isHindi ? '' : '';
    if (isHindi) {
      const days = [
        '',
        'सोमवार',
        'मंगलवार',
        'बुधवार',
        'गुरुवार',
        'शुक्रवार',
        'शनिवार',
        'रविवार',
      ];
      return days[weekday];
    } else {
      const days = [
        '',
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      return days[weekday];
    }
  }

  String formatDisplayDate(String dateString, bool isHindi) {
    try {
      // Handle ISO format: "2025-09-16T00:00:00.000Z"
      if (dateString.contains('T') && dateString.contains('Z')) {
        final dateTime = DateTime.parse(dateString);
        final day = dateTime.day;
        final month = getMonthName(dateTime.month, isHindi);
        final year = dateTime.year;
        final dayName = getDayName(dateTime.weekday, isHindi);

        if (isHindi) {
          return '$day $month $year $dayName';
        } else {
          return '$day $month $year $dayName';
        }
      }

      // Handle Excel format: "16 September 2025 Tuesday"
      if (dateString.contains('September') ||
          dateString.contains('सितम्बर') ||
          dateString.contains('January') ||
          dateString.contains('जनवरी') ||
          dateString.contains('February') ||
          dateString.contains('फरवरी') ||
          dateString.contains('March') ||
          dateString.contains('मार्च') ||
          dateString.contains('April') ||
          dateString.contains('अप्रैल') ||
          dateString.contains('May') ||
          dateString.contains('मई') ||
          dateString.contains('June') ||
          dateString.contains('जून') ||
          dateString.contains('July') ||
          dateString.contains('जुलाई') ||
          dateString.contains('August') ||
          dateString.contains('अगस्त') ||
          dateString.contains('October') ||
          dateString.contains('अक्टूबर') ||
          dateString.contains('November') ||
          dateString.contains('नवम्बर') ||
          dateString.contains('December') ||
          dateString.contains('दिसम्बर')) {
        return dateString;
      }

      // Handle simple date formats: "16 September 2025"
      final parts = dateString.trim().split(' ');
      if (parts.length >= 3) {
        final day = parts[0];
        final month = parts[1];
        final year = parts[2];

        try {
          final dayNum = int.tryParse(day);
          final monthNum = _getMonthNumber(month);
          final yearNum = int.tryParse(year);

          if (dayNum != null && monthNum != null && yearNum != null) {
            final dateTime = DateTime(yearNum, monthNum, dayNum);
            final dayName = getDayName(dateTime.weekday, isHindi);
            return '$day $month $year $dayName';
          }
        } catch (e) {
          // If parsing fails, return the original string
        }
      }

      return dateString;
    } catch (e) {
      return dateString;
    }
  }

  int? _getMonthNumber(String monthName) {
    final monthMap = {
      'January': 1,
      'Jan': 1,
      'जनवरी': 1,
      'February': 2,
      'Feb': 2,
      'फरवरी': 2,
      'March': 3,
      'Mar': 3,
      'मार्च': 3,
      'April': 4,
      'Apr': 4,
      'अप्रैल': 4,
      'May': 5,
      'मई': 5,
      'June': 6,
      'Jun': 6,
      'जून': 6,
      'July': 7,
      'Jul': 7,
      'जुलाई': 7,
      'August': 8,
      'Aug': 8,
      'अगस्त': 8,
      'September': 9,
      'Sep': 9,
      'सितम्बर': 9,
      'सितंबर': 9,
      'October': 10,
      'Oct': 10,
      'अक्टूबर': 10,
      'November': 11,
      'Nov': 11,
      'नवम्बर': 11,
      'नवंबर': 11,
      'December': 12,
      'Dec': 12,
      'दिसम्बर': 12,
      'दिसंबर': 12,
    };
    return monthMap[monthName];
  }
}
