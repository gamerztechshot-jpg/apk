// features/festival_kit/repositories/festival_repository.dart
import '../models/festival_config_model.dart';
import '../../../core/festival_kit/festival_service.dart';

class FestivalRepository {
  final FestivalService _festivalService = FestivalService();

  /// Get festival configuration
  Future<FestivalConfig?> getFestivalConfig({bool forceRefresh = false}) async {
    try {
      return await _festivalService.fetchFestivalConfig(
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Check if festival is currently active
  Future<bool> isActive({bool forceRefresh = false}) async {
    try {
      return await _festivalService.isFestivalActive(
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      return false;
    }
  }

  /// Clear festival cache
  Future<void> clearCache() async {
    await _festivalService.clearCache();
  }
}
