// features/punchang/viewmodels/panchang_screen_viewmodel.dart
import 'package:flutter/material.dart';
import '../models/panchang_ui_state.dart';
import '../repositories/panchang_repository.dart';
import '../../../core/models/panchang_model.dart';

/// Screen-level ViewModel for Panchang
/// Manages UI state, date selection, and coordinates data loading
class PanchangScreenViewModel extends ChangeNotifier {
  final PanchangRepository _repository = PanchangRepository();

  PanchangUIState _state = PanchangUIState.initial();
  List<PanchangModel> _allData = [];

  PanchangUIState get state => _state;
  List<PanchangModel> get allData => _allData;

  /// Load panchang data
  Future<void> loadData(bool isHindi, {bool forceRefresh = false}) async {
    if (_state.isLoading) return;

    _state = PanchangUIState.loading(_state.selectedDate);
    notifyListeners();

    try {
      final panchang = await _repository.fetchPanchangForDate(
        _state.selectedDate,
        isHindi,
        forceRefresh: forceRefresh,
      );

      // keep lightweight cache of fetched days
      if (panchang != null) {
        _allData.removeWhere((p) {
          final d = _repository.findPanchangForDate([p], _state.selectedDate, isHindi);
          return d != null;
        });
        _allData.add(panchang);
      }

      if (panchang != null) {
        if (_repository.isFallbackData(panchang)) {
          _state = PanchangUIState.fallback(panchang, _state.selectedDate);
        } else {
          _state = PanchangUIState.success(panchang, _state.selectedDate);
        }
      } else {
        // No data for this date - generate fallback
        final fallback = _repository.generateFallbackData(
          _state.selectedDate,
          isHindi,
        );
        _state = PanchangUIState.fallback(fallback, _state.selectedDate);
      }
    } catch (e) {
      _state = PanchangUIState.error(e.toString(), _state.selectedDate);
    }

    notifyListeners();
  }

  /// Select a new date
  Future<void> selectDate(DateTime date, bool isHindi) async {
    _state = _state.copyWith(selectedDate: date);
    notifyListeners();
    await loadData(isHindi);
  }

  /// Navigate to previous day
  Future<void> previousDay(bool isHindi) async {
    final newDate = _state.selectedDate.subtract(const Duration(days: 1));
    await selectDate(newDate, isHindi);
  }

  /// Navigate to next day
  Future<void> nextDay(bool isHindi) async {
    final newDate = _state.selectedDate.add(const Duration(days: 1));
    await selectDate(newDate, isHindi);
  }

  /// Retry loading data
  Future<void> retry(bool isHindi) async {
    await loadData(isHindi, forceRefresh: true);
  }

  /// Clear cache and reload
  Future<void> clearCacheAndReload(bool isHindi) async {
    await _repository.clearCache();
    _allData = [];
    await loadData(isHindi, forceRefresh: true);
  }
}
