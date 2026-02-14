// features/mantra_generator/services/credit_service.dart
import '../repositories/user_ai_usage_repository.dart';
import '../models/user_ai_usage_model.dart';

class CreditService {
  final UserAIUsageRepository _repository = UserAIUsageRepository();

  /// Get user's current credit status
  /// Initializes credits from backend if user doesn't exist
  Future<UserAIUsage?> getUserCredits(String userId) async {
    try {
      var usage = await _repository.getUserAIUsage(userId);
      if (usage == null) {
        // Initialize user with 11 free credits (via backend function)
        usage = await _repository.createUserAIUsage(userId);
      } else if (usage.freeCreditsLeft == 0 && usage.topupCredits == 0) {
        // If user exists but has no credits, initialize via backend function
        usage = await _repository.createUserAIUsage(userId);
      }
      return usage;
    } catch (e) {
      throw Exception('Failed to get user credits: $e');
    }
  }

  /// Check if user has enough credits
  Future<bool> checkCreditsAvailable(String userId, int required) async {
    try {
      final usage = await getUserCredits(userId);
      if (usage == null) return false;
      return usage.totalCredits >= required;
    } catch (e) {
      return false;
    }
  }

  /// Deduct credits (free credits first, then topup credits)
  Future<void> deductCredits(String userId, int amount) async {
    try {
      final usage = await getUserCredits(userId);
      if (usage == null) {
        throw Exception('User AI usage not found');
      }

      if (usage.totalCredits < amount) {
        throw Exception(
          'Insufficient credits. Required: $amount, Available: ${usage.totalCredits}',
        );
      }

      int remainingAmount = amount;
      int newFreeCredits = usage.freeCreditsLeft;
      int newTopupCredits = usage.topupCredits;

      // Deduct from free credits first
      if (newFreeCredits > 0) {
        if (newFreeCredits >= remainingAmount) {
          newFreeCredits -= remainingAmount;
          remainingAmount = 0;
        } else {
          remainingAmount -= newFreeCredits;
          newFreeCredits = 0;
        }
      }

      // Deduct remaining from topup credits
      if (remainingAmount > 0) {
        newTopupCredits -= remainingAmount;
      }

      // Update credits
      await _repository.updateCredits(
        userId: userId,
        freeCreditsLeft: newFreeCredits,
        topupCredits: newTopupCredits,
        creditsConsumed: usage.creditsConsumed + amount,
      );
    } catch (e) {
      throw Exception('Failed to deduct credits: $e');
    }
  }

  /// Initialize user credits (give 11 free credits via backend function)
  Future<void> initializeUserCredits(String userId) async {
    try {
      final existingUsage = await _repository.getUserAIUsage(userId);
      if (existingUsage == null || 
          (existingUsage.freeCreditsLeft == 0 && existingUsage.topupCredits == 0)) {
        // Create/initialize usage via backend function (sets 11 free credits)
        await _repository.createUserAIUsage(userId);
      }
    } catch (e) {
      throw Exception('Failed to initialize user credits: $e');
    }
  }

  /// Add topup credits (when package is purchased)
  Future<void> addTopupCredits(String userId, int amount) async {
    try {
      final usage = await getUserCredits(userId);
      if (usage == null) {
        throw Exception('User AI usage not found');
      }

      await _repository.updateCredits(
        userId: userId,
        freeCreditsLeft: usage.freeCreditsLeft,
        topupCredits: usage.topupCredits + amount,
        creditsConsumed: usage.creditsConsumed,
      );
    } catch (e) {
      throw Exception('Failed to add topup credits: $e');
    }
  }

  /// Get total available credits
  Future<int> getTotalCredits(String userId) async {
    try {
      final usage = await getUserCredits(userId);
      return usage?.totalCredits ?? 0;
    } catch (e) {
      return 0;
    }
  }
}
