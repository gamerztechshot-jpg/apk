// features/mantra_generator/views/screens/problem_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:karmasu/core/services/language_service.dart';
import 'package:karmasu/core/services/auth_service.dart';
import '../../models/main_problem_model.dart';
import '../../models/sub_problem_model.dart';
import '../../viewmodels/problem_list_viewmodel.dart';
import '../../viewmodels/credit_viewmodel.dart';
import '../../services/access_control_service.dart';
import '../../repositories/user_ai_usage_repository.dart';
import '../widgets/problem_card.dart';
import 'chat_screen.dart';
import 'sub_problem_content_cards_screen.dart';
import 'package_list_screen.dart';
import 'wallet_details_screen.dart';
import '../../widgets/credit_confirmation_dialog.dart';

class ProblemListScreen extends StatefulWidget {
  const ProblemListScreen({super.key});

  @override
  State<ProblemListScreen> createState() => _ProblemListScreenState();
}

class _ProblemListScreenState extends State<ProblemListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AccessControlService _accessControlService = AccessControlService();
  final UserAIUsageRepository _usageRepository = UserAIUsageRepository();
  List<String> _unlockedIds = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUnlockedProblems();
    });
  }

  Future<void> _fetchUnlockedProblems() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.getCurrentUser()?.id;
      if (userId != null) {
        final usage = await _usageRepository.getUserAIUsage(userId);
        if (usage != null && mounted) {
          setState(() {
            _unlockedIds = usage.accessedProblems;
          });
        }
      }
    } catch (e) {
      // Silent error
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context, listen: true);
    final isHindi = languageService.isHindi;
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.getCurrentUser()?.id;

    return ChangeNotifierProvider(
      create: (_) {
        final viewModel = CreditViewModel();
        if (userId != null) {
          viewModel.initialize(userId);
          viewModel.loadCredits();
        }
        return viewModel;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: Text(
            isHindi ? 'समस्याएं' : 'Problems',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          backgroundColor: Colors.orange.shade600,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          actions: [
            // Wallet Icon
            Consumer<CreditViewModel>(
              builder: (context, creditViewModel, child) {
                return IconButton(
                  icon: Stack(
                    children: [
                      const Icon(Icons.account_balance_wallet_rounded),
                      if (creditViewModel.totalCredits > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '${creditViewModel.totalCredits}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  tooltip: isHindi ? 'वॉलेट' : 'Wallet',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WalletDetailsScreen(),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
        body: ChangeNotifierProvider(
          create: (_) => ProblemListViewModel()..loadProblems(),
          child: Consumer<ProblemListViewModel>(
            builder: (context, viewModel, child) {
              return Column(
                children: [
                  // Search Bar
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: isHindi ? 'खोजें...' : 'Search...',
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.orange.shade600,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: Colors.grey.shade600,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  viewModel.searchProblems('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        viewModel.searchProblems(value);
                      },
                    ),
                  ),
                  // Problems List
                  Expanded(
                    child: viewModel.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : viewModel.error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  viewModel.error!,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () => viewModel.refresh(),
                                  icon: const Icon(Icons.refresh),
                                  label: Text(
                                    isHindi ? 'पुनः लोड करें' : 'Retry',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange.shade600,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : viewModel.filteredMainProblems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  isHindi
                                      ? 'कोई समस्या नहीं मिली'
                                      : 'No problems found',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => viewModel.refresh(),
                            color: Colors.orange.shade600,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: viewModel.filteredMainProblems.length,
                              itemBuilder: (context, index) {
                                final problem =
                                    viewModel.filteredMainProblems[index];
                                final subProblems = viewModel
                                    .getSubProblemsForMain(problem.id);

                                // Load sub-problems if not already loaded
                                if (subProblems.isEmpty) {
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    viewModel.loadSubProblems(problem.id);
                                  });
                                }

                                return ProblemCard(
                                  problem: problem,
                                  subProblems: subProblems,
                                  unlockedIds:
                                      _unlockedIds, // Pass unlocked IDs
                                  onMainProblemTap: (mainProblem) {
                                    // Main problem tap only expands/collapses sub-problems
                                    // No credit deduction, just show sub-problems
                                    // This is handled by ProblemCard's expand/collapse logic
                                  },
                                  onSubProblemTap: (subProblem) async {
                                    await _handleSubProblemTap(
                                      context,
                                      problem,
                                      subProblem,
                                      userId,
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Handle sub-problem tap with credit confirmation dialog
  Future<void> _handleSubProblemTap(
    BuildContext context,
    MainProblem mainProblem,
    SubProblem subProblem,
    String? userId,
  ) async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to access problems'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final languageService = Provider.of<LanguageService>(
      context,
      listen: false,
    );
    final isHindi = languageService.isHindi;

    // Step 1: Check if free (skip everything)
    if (!subProblem.requiresCredits) {
      _navigateToContent(context, mainProblem, subProblem);
      return;
    }

    // Step 2: Check if already accessed (skip dialog if already accessed)
    final usage = await _usageRepository.getUserAIUsage(userId);
    if (usage != null && usage.hasAccessedProblem(subProblem.id)) {
      // Already accessed - navigate directly to content (no dialog, no deduction)
      _navigateToContent(context, mainProblem, subProblem);
      return;
    }

    // Step 2: Get current credits from CreditViewModel
    final creditViewModel = Provider.of<CreditViewModel>(
      context,
      listen: false,
    );
    await creditViewModel.loadCredits();
    final remainingCredits = creditViewModel.totalCredits;

    // Step 4: Get credit cost for this sub-problem
    final creditCost = subProblem.creditCost;

    // Step 4: Check if user has enough credits
    if (remainingCredits < creditCost) {
      _showInsufficientCreditsDialog(
        context,
        creditCost,
        remainingCredits,
        isHindi,
      );
      return;
    }

    // Step 5: Show confirmation dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => CreditConfirmationDialog(
        remainingCredits: remainingCredits,
        creditCost: creditCost,
        problemTitle: subProblem.getTitle(isHindi ? 'hi' : 'en'),
        onConfirm: () async {
          // User confirmed - proceed with access
          await _grantAccessAndNavigate(
            context,
            userId,
            mainProblem,
            subProblem,
            creditViewModel,
          );
        },
        onCancel: () {
          // User cancelled - do nothing
        },
      ),
    );
  }

  /// Grant access, deduct credits, and navigate to content
  Future<void> _grantAccessAndNavigate(
    BuildContext context,
    String userId,
    MainProblem mainProblem,
    SubProblem subProblem,
    CreditViewModel creditViewModel,
  ) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFB366)),
          ),
        ),
      );

      // Grant access (deduct credits and mark as accessed)
      final grantStatus = await _accessControlService.grantAccess(
        userId,
        subProblem.id,
      );

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (!grantStatus.hasAccess) {
        if (context.mounted) {
          _showAccessDeniedDialog(context, grantStatus.message);
        }
        return;
      }

      // Refresh credits after deduction
      await creditViewModel.refreshCredits();

      // Success! Reload credits and update unlocked state
      if (context.mounted) {
        Provider.of<CreditViewModel>(context, listen: false).loadCredits();
        setState(() {
          if (!_unlockedIds.contains(subProblem.id)) {
            _unlockedIds.add(subProblem.id);
          }
        });
        _navigateToContent(context, mainProblem, subProblem);
      }
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to access problem: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                _grantAccessAndNavigate(
                  context,
                  userId,
                  mainProblem,
                  subProblem,
                  creditViewModel,
                );
              },
            ),
          ),
        );
      }
    }
  }

  /// Navigate to content screen based on problem type
  void _navigateToContent(
    BuildContext context,
    MainProblem mainProblem,
    SubProblem subProblem,
  ) {
    // Determine if this is a pre-built problem with linked content or AI problem
    final hasLinkedContent = subProblem.linkedContentCount > 0;

    if (hasLinkedContent) {
      // Pre-built problem: Show all content cards (ebook, puja, dharma store, etc.)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubProblemContentCardsScreen(
            mainProblem: mainProblem,
            subProblem: subProblem,
          ),
        ),
      );
    } else {
      // AI problem: Navigate to chat screen for custom problem
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ChatScreen(mainProblem: mainProblem, subProblem: subProblem),
        ),
      );
    }
  }

  /// Show insufficient credits dialog
  void _showInsufficientCreditsDialog(
    BuildContext context,
    int requiredCredits,
    int availableCredits,
    bool isHindi,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            Text(isHindi ? 'अपर्याप्त क्रेडिट' : 'Insufficient Credits'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isHindi
                  ? 'इस सब-समस्या तक पहुंचने के लिए आपके पास पर्याप्त क्रेडिट नहीं हैं।'
                  : 'You do not have enough credits to access this sub-problem.',
            ),
            const SizedBox(height: 16),
            _buildCreditInfoRow(
              isHindi ? 'आवश्यक क्रेडिट' : 'Required Credits',
              '$requiredCredits',
              Colors.red.shade700,
            ),
            const SizedBox(height: 8),
            _buildCreditInfoRow(
              isHindi ? 'उपलब्ध क्रेडिट' : 'Available Credits',
              '$availableCredits',
              Colors.blue.shade700,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isHindi ? 'ठीक है' : 'OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PackageListScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
            ),
            child: Text(isHindi ? 'पैकेज देखें' : 'View Packages'),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditInfoRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  void _showAccessDeniedDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock, color: Colors.orange),
            SizedBox(width: 8),
            Text('Access Denied'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PackageListScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('View Packages'),
          ),
        ],
      ),
    );
  }
}
