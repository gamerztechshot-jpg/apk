// features/mantra_generator/viewmodels/package_viewmodel.dart
import 'package:flutter/foundation.dart';
import '../models/chatbot_package_model.dart';
import '../repositories/package_repository.dart';
import '../repositories/payment_repository.dart';

class PackageViewModel extends ChangeNotifier {
  final PackageRepository _packageRepository = PackageRepository();
  final PaymentRepository _paymentRepository = PaymentRepository();

  List<ChatbotPackage> _packages = [];
  ChatbotPackage? _userActivePackage;
  Map<String, dynamic>? _userPackageDetails;
  bool _isLoading = false;
  String? _error;
  String? _userId;

  // Cache properties
  DateTime? _lastPackagesFetch;
  DateTime? _lastUserPackageFetch;
  static const Duration _cacheExpiry = Duration(minutes: 10);

  // Getters
  List<ChatbotPackage> get packages => _packages;
  ChatbotPackage? get userActivePackage => _userActivePackage;
  Map<String, dynamic>? get userPackageDetails => _userPackageDetails;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Cache validation
  bool _isPackagesCacheValid() {
    if (_lastPackagesFetch == null) return false;
    return DateTime.now().difference(_lastPackagesFetch!) < _cacheExpiry;
  }

  bool _isUserPackageCacheValid() {
    if (_lastUserPackageFetch == null) return false;
    return DateTime.now().difference(_lastUserPackageFetch!) < _cacheExpiry;
  }

  // Initialize with user ID
  void initialize(String userId) {
    _userId = userId;
  }

  // Load packages
  Future<void> loadPackages({bool forceRefresh = false}) async {
    // Check cache
    if (!forceRefresh && _isPackagesCacheValid() && _packages.isNotEmpty) {
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      _packages = await _packageRepository.getActivePackages();
      _lastPackagesFetch = DateTime.now();

      notifyListeners();
    } catch (e) {
      _setError('Failed to load packages: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Get user's active package
  Future<void> getUserPackage({bool forceRefresh = false}) async {
    if (_userId == null) return;

    // Check cache
    if (!forceRefresh &&
        _isUserPackageCacheValid() &&
        _userActivePackage != null) {
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      final details = await _packageRepository.getUserActivePackageWithDetails(
        _userId!,
      );

      if (details != null && details['package'] != null) {
        _userActivePackage = details['package'] as ChatbotPackage;
        _userPackageDetails = details['plan_details'] as Map<String, dynamic>?;
      } else {
        _userActivePackage = null;
        _userPackageDetails = null;
      }

      _lastUserPackageFetch = DateTime.now();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load user package: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Purchase package (creates payment record)
  Future<Map<String, dynamic>> purchasePackage({
    required String packageId,
    required Map<String, dynamic> userInfo,
  }) async {
    if (_userId == null) {
      throw Exception('User ID not set');
    }

    try {
      _setLoading(true);
      _clearError();

      // Get package details
      final package = await _packageRepository.getPackageById(packageId);
      if (package == null) {
        throw Exception('Package not found');
      }

      // Create payment record (status: pending)
      final paymentRecord = await _paymentRepository.createPaymentRecord(
        userId: _userId!,
        packageId: packageId,
        planDetails: {
          'packageId': package.id,
          'packageName': package.packageName,
          'packageType': package.packageType,
          'amount': package.amount,
          'finalAmount': package.finalAmount,
          'aiQuestionLimit': package.aiQuestionLimit,
          'contentAccess': package.contentAccess,
        },
        userInfo: userInfo,
        paymentStatus: 'pending',
      );

      notifyListeners();
      return paymentRecord;
    } catch (e) {
      _setError('Failed to purchase package: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Update payment status after Razorpay payment
  Future<void> updatePaymentStatus({
    required String paymentId,
    required String paymentStatus,
    Map<String, dynamic>? paymentResponse,
  }) async {
    try {
      await _paymentRepository.updatePaymentStatus(
        paymentId: paymentId,
        paymentStatus: paymentStatus,
        paymentResponse: paymentResponse,
      );

      // Refresh user package if payment successful
      if (paymentStatus == 'success') {
        await getUserPackage(forceRefresh: true);
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to update payment status: ${e.toString()}');
    }
  }

  // Refresh packages
  Future<void> refresh() async {
    await Future.wait([
      loadPackages(forceRefresh: true),
      if (_userId != null) getUserPackage(forceRefresh: true),
    ]);
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
