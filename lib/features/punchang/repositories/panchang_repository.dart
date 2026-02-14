// features/punchang/repositories/panchang_repository.dart
import '../../../core/models/panchang_model.dart';
import '../../../core/services/panchang_service.dart';

/// Repository layer for Panchang data access
/// Abstracts the data source and provides a clean API for the viewmodel
class PanchangRepository {
  final PanchangService _panchangService = PanchangService();

  /// Fetch all panchang data for the year
  Future<List<PanchangModel>> fetchPanchangData(
    bool isHindi, {
    bool forceRefresh = false,
  }) async {
    try {
      return await _panchangService.fetchPanchangData(
        isHindi,
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      throw Exception('Failed to fetch panchang data: $e');
    }
  }

  /// Fetch a single day's panchang (preferred for speed)
  Future<PanchangModel?> fetchPanchangForDate(
    DateTime date,
    bool isHindi, {
    bool forceRefresh = false,
  }) async {
    try {
      return await _panchangService.fetchPanchangForDate(
        date,
        isHindi,
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      throw Exception('Failed to fetch panchang for date: $e');
    }
  }

  /// Get today's panchang from the list
  PanchangModel? getTodayPanchang(List<PanchangModel> allData) {
    return _panchangService.getTodayPanchang(allData);
  }

  /// Find panchang for a specific date
  PanchangModel? findPanchangForDate(
    List<PanchangModel> allData,
    DateTime date,
    bool isHindi,
  ) {
    return _panchangService.findPanchangForDate(allData, date, isHindi);
  }

  /// Clear cached data
  Future<void> clearCache() async {
    await _panchangService.clearPanchangCache();
  }

  /// Generate fallback panchang data when no data is available
  PanchangModel generateFallbackData(DateTime date, bool isHindi) {
    final monthNames = isHindi
        ? [
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
          ]
        : [
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

    return PanchangModel(
      date: '${date.day} ${monthNames[date.month]} ${date.year}',
      festival: isHindi
          ? 'कोई त्यौहार उपलब्ध नहीं'
          : 'No festival data available',
      tithi: isHindi ? 'डेटा उपलब्ध नहीं' : 'Data unavailable',
      nakshatra: isHindi ? 'डेटा उपलब्ध नहीं' : 'Data unavailable',
      sunrise: '06:00 AM',
      sunset: '06:00 PM',
      moonrise: isHindi ? 'डेटा उपलब्ध नहीं' : 'Data unavailable',
      moonset: isHindi ? 'डेटा उपलब्ध नहीं' : 'Data unavailable',
      suryaRashi: isHindi ? 'डेटा उपलब्ध नहीं' : 'Data unavailable',
      chandraRashi: isHindi ? 'डेटा उपलब्ध नहीं' : 'Data unavailable',
      samvat: isHindi ? 'डेटा उपलब्ध नहीं' : 'Data unavailable',
      karan: isHindi ? 'डेटा उपलब्ध नहीं' : 'Data unavailable',
      yoga: isHindi ? 'डेटा उपलब्ध नहीं' : 'Data unavailable',
      dishaShool: isHindi ? 'डेटा उपलब्ध नहीं' : 'Data unavailable',
      chandraNivas: isHindi ? 'डेटा उपलब्ध नहीं' : 'Data unavailable',
      ritu: isHindi ? 'डेटा उपलब्ध नहीं' : 'Data unavailable',
      ayan: isHindi ? 'डेटा उपलब्ध नहीं' : 'Data unavailable',
      brahmaMuhurat: '04:00 AM - 05:00 AM',
      abhijitMuhurat: '11:30 AM - 12:30 PM',
      godhuliMuhurat: '06:00 PM - 06:30 PM',
      amritKalam: isHindi ? 'डेटा उपलब्ध नहीं' : 'Data unavailable',
      rahuKaal: isHindi ? 'डेटा उपलब्ध नहीं' : 'Data unavailable',
      yamagandaKaal: isHindi ? 'डेटा उपलब्ध नहीं' : 'Data unavailable',
    );
  }

  /// Check if panchang data is fallback (incomplete)
  bool isFallbackData(PanchangModel panchang) {
    final tithi = panchang.tithi;
    final nakshatra = panchang.nakshatra;
    return (tithi.contains('unavailable') || tithi.contains('उपलब्ध नहीं') ||
        nakshatra.contains('unavailable') || nakshatra.contains('उपलब्ध नहीं'));
  }
}
