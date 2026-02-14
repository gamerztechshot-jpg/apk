// features/astro/viewmodels/astrologer_viewmodel.dart
import 'package:flutter/foundation.dart';
import '../models/astrologer_model.dart';
import '../models/kundli_type_model.dart';
import '../reposistries/astrologer_repository.dart';

class AstrologerViewModel extends ChangeNotifier {
  final AstrologerRepository _repository = AstrologerRepository();

  List<AstrologerModel> _astrologers = [];
  List<KundliTypeModel> _kundliTypes = [];
  bool _isLoading = false;
  String? _error;

  // Cache properties
  DateTime? _lastAstrologersFetch;
  DateTime? _lastKundliTypesFetch;
  static const Duration _cacheExpiry = Duration(
    minutes: 10,
  ); // 10 minutes cache

  // Getters
  List<AstrologerModel> get astrologers => _astrologers;
  List<KundliTypeModel> get kundliTypes => _kundliTypes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get top astrologers (for home display) - filtered by priority 1,2,3 and sorted
  List<AstrologerModel> get topAstrologers {
    final filteredAstrologers =
        _astrologers
            .where(
              (a) => a.priority != null && a.priority! >= 1 && a.priority! <= 3,
            )
            .toList()
          ..sort((a, b) => a.priority!.compareTo(b.priority!));

    return filteredAstrologers.take(3).toList();
  }

  // Cache validation methods
  bool _isAstrologersCacheValid() {
    if (_lastAstrologersFetch == null) return false;
    return DateTime.now().difference(_lastAstrologersFetch!) < _cacheExpiry;
  }

  bool _isKundliTypesCacheValid() {
    if (_lastKundliTypesFetch == null) return false;
    return DateTime.now().difference(_lastKundliTypesFetch!) < _cacheExpiry;
  }

  // Initialize data with cache support
  Future<void> initializeData({bool forceRefresh = false}) async {
    // Test database connection first
    final connectionTest = await _repository.testConnection();
    if (!connectionTest) {
      _setError(
        'Database connection failed. Please check your internet connection.',
      );
      return;
    }

    // Load data with cache validation
    await Future.wait([
      loadAstrologers(forceRefresh: forceRefresh),
      loadKundliTypes(forceRefresh: forceRefresh),
    ]);
  }

  // Load astrologers with cache support
  Future<void> loadAstrologers({int? limit, bool forceRefresh = false}) async {
    // Check cache validity
    if (!forceRefresh &&
        _isAstrologersCacheValid() &&
        _astrologers.isNotEmpty) {
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      _astrologers = await _repository.getAstrologers(limit: limit);
      _lastAstrologersFetch = DateTime.now(); // Update cache timestamp


      for (int i = 0; i < _astrologers.length; i++) {
        final astrologer = _astrologers[i];

      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to load astrologers: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load kundli types with cache support
  Future<void> loadKundliTypes({bool forceRefresh = false}) async {
    // Check cache validity
    if (!forceRefresh &&
        _isKundliTypesCacheValid() &&
        _kundliTypes.isNotEmpty) {
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      _kundliTypes = await _repository.getKundliTypes();
      _lastKundliTypesFetch = DateTime.now(); // Update cache timestamp
      notifyListeners();
    } catch (e) {
      _setError('Failed to load kundli types: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Search astrologers
  Future<void> searchAstrologers(String query) async {
    if (query.isEmpty) {
      await loadAstrologers();
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      _astrologers = await _repository.searchAstrologers(query);
      notifyListeners();
    } catch (e) {
      _setError('Failed to search astrologers: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Book astrologer
  Future<bool> bookAstrologer({
    required String astrologerId,
    required String userId,
    required String consultationType,
    required DateTime scheduledTime,
    String? notes,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _repository.bookAstrologer(
        astrologerId: astrologerId,
        userId: userId,
        consultationType: consultationType,
        scheduledTime: scheduledTime,
        notes: notes,
      );

      if (success) {
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Failed to book astrologer: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Download kundli report
  Future<bool> downloadKundliReport({
    required String kundliTypeId,
    required String userId,
    required Map<String, dynamic> userDetails,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _repository.downloadKundliReport(
        kundliTypeId: kundliTypeId,
        userId: userId,
        userDetails: userDetails,
      );

      return success;
    } catch (e) {
      _setError('Failed to download kundli report: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get astrologer by ID
  Future<AstrologerModel?> getAstrologerById(String id) async {
    try {
      return await _repository.getAstrologerById(id);
    } catch (e) {
      _setError('Failed to get astrologer details: $e');
      return null;
    }
  }

  // Get kundli type by ID
  Future<KundliTypeModel?> getKundliTypeById(String id) async {
    try {
      return await _repository.getKundliTypeById(id);
    } catch (e) {
      _setError('Failed to get kundli type details: $e');
      return null;
    }
  }

  // Helper methods
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

  void clearError() {
    _clearError();
  }

  // Refresh data
  Future<void> refresh() async {
    await initializeData(forceRefresh: true);
  }

  // Cache management methods
  void clearCache() {
    _lastAstrologersFetch = null;
    _lastKundliTypesFetch = null;
    _astrologers.clear();
    _kundliTypes.clear();
    notifyListeners();
  }

  void clearAstrologersCache() {
    _lastAstrologersFetch = null;
    _astrologers.clear();
    notifyListeners();
  }

  void clearKundliTypesCache() {
    _lastKundliTypesFetch = null;
    _kundliTypes.clear();
    notifyListeners();
  }

  // Get cache status
  bool get isAstrologersCacheValid => _isAstrologersCacheValid();
  bool get isKundliTypesCacheValid => _isKundliTypesCacheValid();
  Duration? get astrologersCacheAge => _lastAstrologersFetch != null
      ? DateTime.now().difference(_lastAstrologersFetch!)
      : null;
  Duration? get kundliTypesCacheAge => _lastKundliTypesFetch != null
      ? DateTime.now().difference(_lastKundliTypesFetch!)
      : null;
}
