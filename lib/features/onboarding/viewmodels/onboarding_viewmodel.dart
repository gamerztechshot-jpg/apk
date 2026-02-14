// features/onboarding/viewmodels/onboarding_viewmodel.dart
import 'package:flutter/foundation.dart';
import '../models/onboarding_item.dart';
import '../repositories/onboarding_repository.dart';

class OnboardingViewModel extends ChangeNotifier {
  final OnboardingRepository _repository = OnboardingRepository();

  List<OnboardingItem> _items = [];
  bool _isLoading = false;
  String? _error;
  int _currentIndex = 0;

  List<OnboardingItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentIndex => _currentIndex;
  bool get hasItems => _items.isNotEmpty;
  bool get isLast => _items.isNotEmpty && _currentIndex == _items.length - 1;

  OnboardingViewModel() {
    // Show defaults immediately for instant first paint
    _items = OnboardingRepository.getDefaultItems();
  }

  Future<void> load() async {
    if (_isLoading) return;
    _setLoading(true);
    _clearError();

    try {
      final fetched = await _repository.fetchItems();
      if (fetched.isNotEmpty) {
        _items = fetched;
        _currentIndex = 0;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to load onboarding media: $e');
    } finally {
      _setLoading(false);
    }
  }

  void setIndex(int index) {
    if (index == _currentIndex) return;
    _currentIndex = index;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
