// features/mantra_generator/services/access_control_service.dart
import '../repositories/package_repository.dart';
import '../models/chatbot_package_model.dart';
import '../repositories/user_ai_usage_repository.dart';
import '../repositories/problem_repository.dart';
import '../models/access_status_model.dart';
import '../models/main_problem_model.dart';
import '../models/sub_problem_model.dart';
import '../services/credit_service.dart';

class AccessControlService {
  final PackageRepository _packageRepository = PackageRepository();
  final UserAIUsageRepository _usageRepository = UserAIUsageRepository();
  final ProblemRepository _problemRepository = ProblemRepository();
  final CreditService _creditService = CreditService();

  /// Check if user has access to a problem (package OR credits)
  Future<AccessStatus> checkProblemAccess(
    String userId,
    String problemId,
  ) async {
    try {
      // Step 1: Get problem details first
      final problem = await _problemRepository.getProblemById(problemId);
      if (problem == null) {
        return AccessStatus.problemNotFound();
      }

      // Step 2: Get credit cost (all problems now require credits)
      int creditCost = 0;
      if (problem is MainProblem) {
        // Default to 1 credit if not set
        creditCost = problem.creditCost > 0 ? problem.creditCost : 1;
      } else if (problem is SubProblem) {
        // Default to 1 credit if not set
        creditCost = problem.creditCost > 0 ? problem.creditCost : 1;
      }

      // Step 3: Check if user has package access
      final packageAccess = await checkPackageAccess(userId, problemId);
      bool hasPackageAccess = packageAccess.hasAccess;

      // Step 4: Check credits availability
      final usage = await _usageRepository.getUserAIUsage(userId);
      if (usage == null) {
        // Initialize user credits
        await _creditService.initializeUserCredits(userId);
        final newUsage = await _usageRepository.getUserAIUsage(userId);
        if (newUsage == null) {
          // No credits and no package = deny access
          if (!hasPackageAccess) {
            return AccessStatus.noPackage();
          }
          return AccessStatus.insufficientCredits(
            requiredCredits: creditCost,
            availableCredits: 0,
          );
        }
      }

      final finalUsage = await _usageRepository.getUserAIUsage(userId);
      if (finalUsage == null) {
        // No credits and no package = deny access
        if (!hasPackageAccess) {
          return AccessStatus.noPackage();
        }
        return AccessStatus.insufficientCredits(
          requiredCredits: creditCost,
          availableCredits: 0,
        );
      }

      // Step 5: Check if already accessed (prevent duplicate deduction)
      if (finalUsage.hasAccessedProblem(problemId)) {
        // Already accessed, grant access without deducting credits again
        return AccessStatus.granted();
      }

      // Step 6: Allow access if user has package OR has enough credits
      if (hasPackageAccess) {
        // User has package access, check credits for deduction
        final totalCredits = finalUsage.totalCredits;
        if (totalCredits < creditCost) {
          return AccessStatus.insufficientCredits(
            requiredCredits: creditCost,
            availableCredits: totalCredits,
          );
        }
        return AccessStatus.granted();
      } else {
        // No package, but check if user has credits
        final totalCredits = finalUsage.totalCredits;
        if (totalCredits >= creditCost) {
          // User has credits, allow access
          return AccessStatus.granted();
        } else {
          // No package and insufficient credits
          return AccessStatus.insufficientCredits(
            requiredCredits: creditCost,
            availableCredits: totalCredits,
          );
        }
      }
    } catch (e) {
      return AccessStatus.problemNotFound();
    }
  }

  /// Check if user's package has access to the problem
  Future<AccessStatus> checkPackageAccess(
    String userId,
    String problemId,
  ) async {
    try {
      // Get user's active package with details
      final activeData = await _packageRepository
          .getUserActivePackageWithDetails(userId);
      if (activeData == null) {
        return AccessStatus.noPackage();
      }

      final package = activeData['package'] as ChatbotPackage;

      // Check if package is active
      if (!package.isActive) {
        return AccessStatus.packageInactive();
      }

      // Check if problem is in content_access
      if (!package.hasAccessToProblem(problemId)) {
        return AccessStatus.notInPackage();
      }

      return AccessStatus.granted();
    } catch (e) {
      return AccessStatus.noPackage();
    }
  }

  /// Grant access to problem (deduct credits and mark as accessed)
  Future<AccessStatus> grantAccess(String userId, String problemId) async {
    try {
      // Check access first
      final accessStatus = await checkProblemAccess(userId, problemId);
      if (!accessStatus.hasAccess) {
        return accessStatus;
      }

      // Get problem to get credit cost
      final problem = await _problemRepository.getProblemById(problemId);
      if (problem == null) {
        return AccessStatus.problemNotFound();
      }

      // Get credit cost (all problems now require credits)
      int creditCost = 0;
      if (problem is MainProblem) {
        // Default to 1 credit if not set
        creditCost = problem.creditCost > 0 ? problem.creditCost : 1;
      } else if (problem is SubProblem) {
        // Default to 1 credit if not set
        creditCost = problem.creditCost > 0 ? problem.creditCost : 1;
      }

      // Check if already accessed
      final usage = await _usageRepository.getUserAIUsage(userId);
      if (usage != null && usage.hasAccessedProblem(problemId)) {
        // Already accessed, no need to deduct credits again
        return AccessStatus.granted();
      }

      // Deduct credits (always required now)
      await _creditService.deductCredits(userId, creditCost);

      // Mark as accessed
      await _usageRepository.addAccessedProblem(
        userId: userId,
        problemId: problemId,
      );

      return AccessStatus.granted();
    } catch (e) {
      return AccessStatus.problemNotFound();
    }
  }

  /// Check if problem is accessible (quick check)
  Future<bool> isProblemAccessible(String userId, String problemId) async {
    try {
      final accessStatus = await checkProblemAccess(userId, problemId);
      return accessStatus.hasAccess;
    } catch (e) {
      return false;
    }
  }
}
