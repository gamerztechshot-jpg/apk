// features/onboarding/views/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/onboarding_viewmodel.dart';
import '../widgets/onboarding_media.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinish;

  const OnboardingScreen({super.key, required this.onFinish});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  bool _didAutoFinish = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnboardingViewModel()..load(),
      child: Consumer<OnboardingViewModel>(
        builder: (context, viewModel, _) {
          // Show content immediately when we have items (defaults or loaded)
          if (viewModel.hasItems) {
            return _buildOnboardingContent(context, viewModel);
          }

          if (viewModel.isLoading && !viewModel.hasItems) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (viewModel.error != null && !viewModel.hasItems) {
            return Scaffold(
              body: Center(child: Text(viewModel.error!)),
            );
          }

          if (!viewModel.hasItems) {
            if (!_didAutoFinish) {
              _didAutoFinish = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  widget.onFinish();
                }
              });
            }
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return _buildOnboardingContent(context, viewModel);
        },
      ),
    );
  }

  Widget _buildOnboardingContent(
    BuildContext context,
    OnboardingViewModel viewModel,
  ) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: viewModel.items.length,
                onPageChanged: viewModel.setIndex,
                itemBuilder: (context, index) {
                  final item = viewModel.items[index];
                  return OnboardingMedia(
                    item: item,
                    isActive: index == viewModel.currentIndex,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            _PageIndicator(
              count: viewModel.items.length,
              currentIndex: viewModel.currentIndex,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: widget.onFinish,
                    child: const Text(
                      'Skip',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (viewModel.isLast) {
                        widget.onFinish();
                        return;
                      }
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final int count;
  final int currentIndex;

  const _PageIndicator({required this.count, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: isActive ? 20 : 8,
          decoration: BoxDecoration(
            color: isActive ? Colors.orange : Colors.white54,
            borderRadius: BorderRadius.circular(12),
          ),
        );
      }),
    );
  }
}
