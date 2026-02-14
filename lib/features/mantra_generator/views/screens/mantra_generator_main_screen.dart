// features/mantra_generator/views/screens/mantra_generator_main_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:karmasu/core/services/language_service.dart';
import 'package:karmasu/core/services/auth_service.dart';
import 'package_list_screen.dart';
import 'wallet_details_screen.dart';
import '../../viewmodels/credit_viewmodel.dart';
import '../../viewmodels/problem_list_viewmodel.dart';
import 'chat_screen.dart';
import '../../models/main_problem_model.dart';
import 'sub_problem_list_screen.dart';

class MantraGeneratorMainScreen extends StatefulWidget {
  const MantraGeneratorMainScreen({super.key});

  @override
  State<MantraGeneratorMainScreen> createState() =>
      _MantraGeneratorMainScreenState();
}

class _MantraGeneratorMainScreenState extends State<MantraGeneratorMainScreen> {
  final TextEditingController _chatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.getCurrentUser()?.id;
      if (userId != null) {
        final creditViewModel = Provider.of<CreditViewModel>(
          context,
          listen: false,
        );
        creditViewModel.initialize(userId);
        creditViewModel.loadCredits();
      }

      final problemViewModel = Provider.of<ProblemListViewModel>(
        context,
        listen: false,
      );
      problemViewModel.loadProblems();
    });
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context, listen: true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.getCurrentUser();
    final userId = user?.id;
    final userName =
        user?.userMetadata?['full_name'] ??
        user?.userMetadata?['name'] ??
        (languageService.isHindi ? 'उपयोगकर्ता' : 'User');
    final isHindi = languageService.isHindi;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isHindi ? 'एआई सखा' : 'AI Sakha',
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
        actions: [
          Consumer<CreditViewModel>(
            builder: (context, creditViewModel, child) {
              return IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined),
                    if (creditViewModel.totalCredits > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 12,
                            minHeight: 12,
                          ),
                          child: Text(
                            '${creditViewModel.totalCredits}',
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
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
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  // Greeting
                  Text(
                    isHindi ? 'नमस्ते $userName' : 'Hello $userName',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w300,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isHindi ? 'मैं आपकी कैसे मदद कर सकता हूं?' : 'How can I help you today?',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isHindi ? 'मैं सखा हूं, मैं सब जानता हूं' : 'I am Sakha, I know everything',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Low Credit Banner
                  Consumer<CreditViewModel>(
                    builder: (context, creditViewModel, child) {
                      if (creditViewModel.totalCredits < 5 &&
                          !creditViewModel.isLoading) {
                        return _buildLowCreditBanner(context, isHindi);
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  const SizedBox(height: 12),
                  // Suggestions Section
                  Text(
                    isHindi ? 'सुझाव' : 'Suggestions',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Consumer<ProblemListViewModel>(
                    builder: (context, viewModel, child) {
                      if (viewModel.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      // Pick top problems and sort by display_order
                      final problems = [...viewModel.mainProblems];
                      problems.sort(
                        (a, b) => a.displayOrder.compareTo(b.displayOrder),
                      );

                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: problems.map((problem) {
                          return _buildProblemChip(
                            context,
                            problem.getTitle(isHindi ? 'hi' : 'en'),
                            () {
                              _handleMainProblemTap(context, problem, userId);
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          // Bottom Chat Input
          Consumer<ProblemListViewModel>(
            builder: (context, viewModel, child) {
              return _buildChatInput(
                context,
                isHindi,
                viewModel: viewModel,
                userId: userId,
              );
            },
          ),
        ],
      ),
    );
  }

  void _handleMainProblemTap(
    BuildContext context,
    MainProblem mainProblem,
    String? userId,
  ) async {
    if (userId == null) return;

    final viewModel = Provider.of<ProblemListViewModel>(context, listen: false);

    // Check if sub-problems exist for this main problem
    await viewModel.loadSubProblems(mainProblem.id);
    final subProblems = viewModel.getSubProblemsForMain(mainProblem.id);

    if (subProblems.isNotEmpty) {
      // Redirect to new page when sub problems are shown
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubProblemListScreen(mainProblem: mainProblem),
        ),
      );
    } else {
      // Direct chat if no sub-problems
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(mainProblem: mainProblem),
        ),
      );
    }
  }

  Widget _buildProblemChip(
    BuildContext context,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.orange.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, color: Colors.orange.shade700, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLowCreditBanner(BuildContext context, bool isHindi) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt, color: Colors.orange.shade800),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isHindi
                  ? 'आपके पास क्रेडिट कम हैं। बेहतर अनुभव के लिए टॉप-अप करें।'
                  : 'You are low on credits. Top-up for a better experience.',
              style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () {
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

  Widget _buildChatInput(
    BuildContext context,
    bool isHindi, {
    required ProblemListViewModel viewModel,
    String? userId,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            offset: const Offset(0, -5),
            blurRadius: 15,
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 8),
              child: Text(
                isHindi ? 'मुझसे कुछ भी पूछें' : 'Try asking anything...',
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.orange.shade100, width: 1.5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      decoration: InputDecoration(
                        hintText: isHindi
                            ? 'अपनी समस्या बताएं...'
                            : 'Describe your problem...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                        ),
                      ),
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty &&
                            viewModel.mainProblems.isNotEmpty) {
                          _navigateToChat(
                            context,
                            viewModel.mainProblems.first,
                            value.trim(),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      if (_chatController.text.trim().isNotEmpty &&
                          viewModel.mainProblems.isNotEmpty) {
                        _navigateToChat(
                          context,
                          viewModel.mainProblems.first,
                          _chatController.text.trim(),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade600,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToChat(
    BuildContext context,
    MainProblem problem,
    String initialMessage,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ChatScreen(mainProblem: problem, initialMessage: initialMessage),
      ),
    );
    _chatController.clear();
  }
}
