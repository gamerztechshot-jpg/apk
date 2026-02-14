// features/mantra_generator/viewmodels/problem_list_viewmodel.dart
import 'package:flutter/foundation.dart';
import '../models/main_problem_model.dart';
import '../models/sub_problem_model.dart';
import '../repositories/problem_repository.dart';

class ProblemListViewModel extends ChangeNotifier {
  final ProblemRepository _repository = ProblemRepository();

  List<MainProblem> _mainProblems = [];
  Map<String, List<SubProblem>> _subProblemsMap = {};
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  // Cache properties
  DateTime? _lastFetch;
  static const Duration _cacheExpiry = Duration(minutes: 10);

  // Getters
  List<MainProblem> get mainProblems => _mainProblems;
  Map<String, List<SubProblem>> get subProblemsMap => _subProblemsMap;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  // Get filtered problems based on search
  List<MainProblem> get filteredMainProblems {
    if (_searchQuery.isEmpty) return _mainProblems;
    return _mainProblems
        .where(
          (p) =>
              p.titleEn.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p.titleHi.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  // Cache validation
  bool _isCacheValid() {
    if (_lastFetch == null) return false;
    return DateTime.now().difference(_lastFetch!) < _cacheExpiry;
  }

  // Load main problems
  Future<void> loadProblems({bool forceRefresh = false}) async {
    // Check cache
    if (!forceRefresh && _isCacheValid() && _mainProblems.isNotEmpty) {
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      _mainProblems = await _repository.getMainProblems(
        forceRefresh: forceRefresh,
      );
      _lastFetch = DateTime.now();

      notifyListeners();
    } catch (e) {
      _setError('Failed to load problems: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Load sub-problems for a main problem
  Future<void> loadSubProblems(
    String mainProblemId, {
    bool forceRefresh = false,
  }) async {
    // Check if already loaded
    if (!forceRefresh && _subProblemsMap.containsKey(mainProblemId)) {
      return;
    }

    try {
      final subProblems = await _repository.getSubProblems(
        mainProblemId,
        forceRefresh: forceRefresh,
      );

      _subProblemsMap[mainProblemId] = subProblems;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load sub-problems: ${e.toString()}');
    }
  }

  // Search problems
  Future<void> searchProblems(String query) async {
    _searchQuery = query;
    notifyListeners();

    if (query.isEmpty) {
      await loadProblems();
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      final results = await _repository.searchProblems(query);
      _mainProblems = results['main']!.cast<MainProblem>();
      // Note: Sub-problems search results can be handled separately if needed

      notifyListeners();
    } catch (e) {
      _setError('Failed to search problems: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Get sub-problems for a main problem
  List<SubProblem> getSubProblemsForMain(String mainProblemId) {
    return _subProblemsMap[mainProblemId] ?? [];
  }

  // Refresh data
  Future<void> refresh() async {
    await loadProblems(forceRefresh: true);
  }

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
