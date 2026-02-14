import 'package:flutter/foundation.dart';
import '../services/panchang_service.dart';
import '../models/panchang_model.dart';

class PanchangProvider extends ChangeNotifier {
  final PanchangService _panchangService = PanchangService();

  final Map<String, PanchangModel> _memoryCache = {};
  List<PanchangModel> _allData = [];
  PanchangModel? _todayPanchang;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;
  bool? _lastLanguageIsHindi;

  // Getters
  List<PanchangModel> get allData => _allData;
  PanchangModel? get todayPanchang => _todayPanchang;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  bool get hasData => _allData.isNotEmpty || _memoryCache.isNotEmpty;

  /// Initialize provider with data if not already initialized
  /// This is designed for background preloading
  Future<void> initializeIfNeeded(bool isHindi) async {
    if (_isInitialized || _isLoading) {
      return;
    }
    await fetchForDate(isHindi, date: _selectedDate);
  }

  Future<void> fetchForDate(
    bool isHindi, {
    DateTime? date,
    bool forceRefresh = false,
  }) async {
    final target = DateTime.utc(
      (date ?? _selectedDate).year,
      (date ?? _selectedDate).month,
      (date ?? _selectedDate).day,
    );

    try {
      _lastLanguageIsHindi = isHindi;
      _isLoading = true;
      _error = null;
      notifyListeners();

      final key = _cacheKey(target, isHindi);

      // Memory cache hit
      if (!forceRefresh && _memoryCache.containsKey(key)) {
        _todayPanchang = _memoryCache[key];
        _selectedDate = target;
        _isLoading = false;
        _isInitialized = true;
        notifyListeners();
        return;
      }

      // Fetch single-day data from service
      final result = await _panchangService.fetchPanchangForDate(
        target,
        isHindi,
        forceRefresh: forceRefresh,
      );

      _selectedDate = target;

      if (result != null) {
        _todayPanchang = result;
        _memoryCache[key] = result;

        // Maintain compatibility: keep a lightweight list of fetched days
        _allData.removeWhere((p) {
          final parsed = _panchangService.parsePanchangDate(
            p.date,
            isHindi: isHindi,
          );
          return parsed != null &&
              parsed.year == target.year &&
              parsed.month == target.month &&
              parsed.day == target.day;
        });
        _allData.add(result);

      } else {
        _todayPanchang = null;
      }

      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    } catch (e, stack) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  String _cacheKey(DateTime date, bool isHindi) {
    final target = DateTime.utc(date.year, date.month, date.day);
    return '${target.toIso8601String()}_${isHindi ? 'hi' : 'en'}';
  }

  /// Set selected date
  Future<void> setSelectedDate(DateTime date, bool isHindi) async {
    await fetchForDate(isHindi, date: date);
  }

  /// Get panchang for the currently selected date
  PanchangModel? getSelectedPanchang(bool isHindi) {
    return findPanchangForDate(_selectedDate, isHindi);
  }

  PanchangModel? findPanchangForDate(DateTime date, bool isHindi) {
    final cached = _memoryCache[_cacheKey(date, isHindi)];
    if (cached != null) return cached;
    if (_allData.isEmpty) return null;
    return _panchangService.findPanchangForDate(_allData, date, isHindi);
  }

  /// Navigate to previous day
  Future<void> previousDay() async {
    final isHindi = _lastLanguageIsHindi ?? false;
    final target = _selectedDate.subtract(const Duration(days: 1));
    await fetchForDate(isHindi, date: target);
  }

  /// Navigate to next day
  Future<void> nextDay() async {
    final isHindi = _lastLanguageIsHindi ?? false;
    final target = _selectedDate.add(const Duration(days: 1));
    await fetchForDate(isHindi, date: target);
  }

  /// Clear cache
  Future<void> clearCache() async {
    await _panchangService.clearPanchangCache();
    _allData = [];
    _memoryCache.clear();
    _todayPanchang = null;
    _isInitialized = false;
    _lastLanguageIsHindi = null;
    notifyListeners();
  }
}
