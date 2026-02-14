// features/mantra_generator/views/screens/sub_problem_list_screen.dart
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
import 'chat_screen.dart';
import 'sub_problem_content_cards_screen.dart';
import 'package_list_screen.dart';
import '../../widgets/credit_confirmation_dialog.dart';

class SubProblemListScreen extends StatefulWidget {
  final MainProblem mainProblem;

  const SubProblemListScreen({super.key, required this.mainProblem});

  @override
  State<SubProblemListScreen> createState() => _SubProblemListScreenState();
}

class _SubProblemListScreenState extends State<SubProblemListScreen> {
  final AccessControlService _accessControlService = AccessControlService();
  final UserAIUsageRepository _usageRepository = UserAIUsageRepository();
  List<String> _unlockedIds = [];
  bool _isInitLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitLoaded) {
      _fetchUnlockedProblems();
      _isInitLoaded = true;
    }
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
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context, listen: true);
    final isHindi = languageService.isHindi;
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.getCurrentUser()?.id;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          widget.mainProblem.getTitle(isHindi ? 'hi' : 'en'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Consumer<ProblemListViewModel>(
        builder: (context, viewModel, child) {
          final subProblems = [
            ...viewModel.getSubProblemsForMain(widget.mainProblem.id),
          ];
          subProblems.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

          if (subProblems.isEmpty) {
            return Center(
              child: Text(
                isHindi ? 'कोई उप-समस्या नहीं मिली' : 'No sub-problems found',
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: subProblems.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final sub = subProblems[index];
              final isUnlocked =
                  _unlockedIds.contains(sub.id) || !sub.requiresCredits;

              return _buildSubProblemTile(
                context,
                sub,
                isUnlocked,
                isHindi,
                userId,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSubProblemTile(
    BuildContext context,
    SubProblem sub,
    bool isUnlocked,
    bool isHindi,
    String? userId,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleSubProblemTap(context, sub, userId),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon/Status Indicator
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? Colors.green.shade50
                        : Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isUnlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                    color: isUnlocked
                        ? Colors.green.shade600
                        : Colors.orange.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sub.getTitle(isHindi ? 'hi' : 'en'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            isUnlocked
                                ? (isHindi ? 'खुला है' : 'Unlocked')
                                : (isHindi ? 'लॉक है' : 'Locked'),
                            style: TextStyle(
                              color: isUnlocked
                                  ? Colors.green.shade600
                                  : Colors.orange.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (!isUnlocked && sub.requiresCredits) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${sub.creditCost} ${isHindi ? 'क्रेडिट' : 'credits'}',
                                style: TextStyle(
                                  color: Colors.orange.shade900,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubProblemTap(
    BuildContext context,
    SubProblem subProblem,
    String? userId,
  ) async {
    if (userId == null) return;

    final languageService = Provider.of<LanguageService>(
      context,
      listen: false,
    );
    final isHindi = languageService.isHindi;

    // Reuse logic from ProblemListScreen
    if (!subProblem.requiresCredits || _unlockedIds.contains(subProblem.id)) {
      _navigateToContent(context, subProblem);
      return;
    }

    final creditViewModel = Provider.of<CreditViewModel>(
      context,
      listen: false,
    );
    await creditViewModel.loadCredits();
    final remainingCredits = creditViewModel.totalCredits;

    if (remainingCredits < subProblem.creditCost) {
      _showInsufficientCreditsDialog(
        context,
        subProblem.creditCost,
        remainingCredits,
        isHindi,
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => CreditConfirmationDialog(
        remainingCredits: remainingCredits,
        creditCost: subProblem.creditCost,
        problemTitle: subProblem.getTitle(isHindi ? 'hi' : 'en'),
        onConfirm: () async {
          await _grantAccessAndNavigate(
            context,
            userId,
            subProblem,
            creditViewModel,
          );
        },
        onCancel: () {},
      ),
    );
  }

  Future<void> _grantAccessAndNavigate(
    BuildContext context,
    String userId,
    SubProblem subProblem,
    CreditViewModel creditViewModel,
  ) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final grantStatus = await _accessControlService.grantAccess(
        userId,
        subProblem.id,
      );

      if (context.mounted) Navigator.of(context).pop();

      if (!grantStatus.hasAccess) {
        if (context.mounted)
          _showAccessDeniedDialog(context, grantStatus.message);
        return;
      }

      await creditViewModel.refreshCredits();

      if (context.mounted) {
        setState(() {
          if (!_unlockedIds.contains(subProblem.id))
            _unlockedIds.add(subProblem.id);
        });
        _navigateToContent(context, subProblem);
      }
    } catch (e) {
      if (context.mounted && Navigator.canPop(context))
        Navigator.of(context).pop();
    }
  }

  void _navigateToContent(BuildContext context, SubProblem subProblem) {
    if (subProblem.linkedContentCount > 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubProblemContentCardsScreen(
            mainProblem: widget.mainProblem,
            subProblem: subProblem,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            mainProblem: widget.mainProblem,
            subProblem: subProblem,
          ),
        ),
      );
    }
  }

  void _showInsufficientCreditsDialog(
    BuildContext context,
    int required,
    int available,
    bool isHindi,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isHindi ? 'अपर्याप्त क्रेडिट' : 'Insufficient Credits'),
        content: Text(
          isHindi
              ? 'आपके पास पर्याप्त क्रेडिट नहीं हैं।'
              : 'You do not have enough credits.',
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
            child: Text(isHindi ? 'खरीदें' : 'Buy'),
          ),
        ],
      ),
    );
  }

  void _showAccessDeniedDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Access Denied'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
