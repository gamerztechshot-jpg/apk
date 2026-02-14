// features/home/explore_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:karmasu/l10n/app_localizations.dart';
import '../pandit/widgets/pandit_dashboard.dart';
import '../astro/viewmodels/astrologer_viewmodel.dart';
import '../astro/views/widgets/kundli_types_section.dart';
import '../astro/views/widgets/astrologer_list_section.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  @override
  void initState() {
    super.initState();
    // Defer to avoid blocking home - load after 2s
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      context.read<AstrologerViewModel>().initializeData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          l10n.localeName == 'hi' ? 'पुरोहित' : 'Purohit',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.shade50, Colors.white],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Pandit Section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.temple_hindu, color: Colors.orange.shade600),
                        const SizedBox(width: 8),
                        Text(
                          l10n.pandit,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  const PanditDashboard(),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Astrologer Section
            Consumer<AstrologerViewModel>(
              builder: (context, viewModel, child) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.star, color: Colors.orange.shade600),
                            const SizedBox(width: 8),
                            Text(
                              l10n.astrologer,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Content
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Kundli Reports Section
                            if (viewModel.kundliTypes.isNotEmpty) ...[
                              KundliTypesSection(
                                kundliTypes: viewModel.kundliTypes,
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Astrologer List Section
                            AstrologerListSection(
                              astrologers: viewModel.topAstrologers,
                              isLoading: viewModel.isLoading,
                              onViewAll: () {
                                Navigator.pushNamed(
                                  context,
                                  '/view-all-astrologers',
                                );
                              },
                            ),

                            // Show message if no data available
                            if (viewModel.kundliTypes.isEmpty &&
                                viewModel.astrologers.isEmpty &&
                                !viewModel.isLoading)
                              Container(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.star_outline,
                                      size: 48,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      l10n.noAstrologersOrKundliReportsAvailable,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
