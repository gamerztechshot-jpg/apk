// features/mantra_generator/viewmodels/credit_viewmodel.dart
import 'package:flutter/foundation.dart';
import '../services/credit_service.dart';
import '../repositories/user_ai_usage_repository.dart';
import '../models/user_ai_usage_model.dart';

class CreditViewModel extends ChangeNotifier {
  final CreditService _creditService = CreditService();
  final UserAIUsageRepository _usageRepository = UserAIUsageRepository();

  int _freeCredits = 0;
  int _topupCredits = 0;
  int _totalCredits = 0;
  int _creditsConsumed = 0;
  bool _isLoading = false;
  String? _error;
  String? _userId;

  // Getters
  int get freeCredits => _freeCredits;
  int get topupCredits => _topupCredits;
  int get totalCredits => _totalCredits;
  int get creditsConsumed => _creditsConsumed;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize with user ID
  void initialize(String userId) {
    _userId = userId;
  }

  // Load credits
  Future<void> loadCredits() async {
    if (_userId == null) return;

    try {
      _setLoading(true);
      _clearError();

      final usage = await _creditService.getUserCredits(_userId!);
      if (usage != null) {
        _freeCredits = usage.freeCreditsLeft;
        _topupCredits = usage.topupCredits;
        _totalCredits = usage.totalCredits;
        _creditsConsumed = usage.creditsConsumed;
      } else {
        // Initialize user credits
        await _creditService.initializeUserCredits(_userId!);
        final newUsage = await _creditService.getUserCredits(_userId!);
        if (newUsage != null) {
          _freeCredits = newUsage.freeCreditsLeft;
          _topupCredits = newUsage.topupCredits;
          _totalCredits = newUsage.totalCredits;
          _creditsConsumed = newUsage.creditsConsumed;
        }
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to load credits: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Refresh credits
  Future<void> refreshCredits() async {
    await loadCredits();
  }

  // Check if credits are low
  bool get isCreditsLow => _totalCredits <= 5;

  // Check if credits are zero
  bool get hasNoCredits => _totalCredits == 0;

  // Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
