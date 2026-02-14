// features/festival_kit/viewmodels/festival_viewmodel.dart
import 'package:flutter/foundation.dart';
import '../models/festival_config_model.dart';
import '../repositories/festival_repository.dart';

class FestivalViewModel extends ChangeNotifier {
  final FestivalRepository _repository = FestivalRepository();

  FestivalConfig? _festivalConfig;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  FestivalConfig? get festivalConfig => _festivalConfig;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isActive => _festivalConfig?.isCurrentlyActive ?? false;
  bool get hasData => _festivalConfig != null;

  /// Load festival configuration
  Future<void> loadFestivalConfig({bool forceRefresh = false}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final config = await _repository.getFestivalConfig(
        forceRefresh: forceRefresh,
      );

      _festivalConfig = config;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load festival data: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh festival configuration
  Future<void> refresh() async {
    await loadFestivalConfig(forceRefresh: true);
  }

  /// Clear cache and reload
  Future<void> clearCacheAndReload() async {
    await _repository.clearCache();
    await loadFestivalConfig(forceRefresh: true);
  }

  /// Get content items by type
  List<FestivalContentItem> getContentItemsByType(String type) {
    if (_festivalConfig == null) return [];
    return _festivalConfig!.contentItems
        .where((item) => item.type == type)
        .toList();
  }

  /// Get all unique content types
  List<String> get contentTypes {
    if (_festivalConfig == null) return [];
    return _festivalConfig!.contentItems
        .map((item) => item.type)
        .toSet()
        .toList();
  }
}
