// features/astro/views/astrologer_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:karmasu/l10n/app_localizations.dart';
import '../viewmodels/astrologer_viewmodel.dart';
import 'widgets/kundli_types_section.dart';
import 'widgets/astrologer_list_section.dart';

class AstrologerScreen extends StatefulWidget {
  const AstrologerScreen({super.key});

  @override
  State<AstrologerScreen> createState() => _AstrologerScreenState();
}

class _AstrologerScreenState extends State<AstrologerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AstrologerViewModel>().initializeData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            Text(
              l10n.astrologer,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.shade50, Colors.white],
          ),
        ),
        child: Consumer<AstrologerViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading && viewModel.astrologers.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (viewModel.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      viewModel.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.red.shade600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => viewModel.refresh(),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              );
            }

            // Show empty state if no data available
            if (viewModel.astrologers.isEmpty &&
                viewModel.kundliTypes.isEmpty &&
                !viewModel.isLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.star_outline,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.noAstrologersOrKundliReportsAvailable,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => viewModel.refresh(),
                      child: Text(l10n.refresh),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => viewModel.refresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kundli Types Section
                    if (viewModel.kundliTypes.isNotEmpty) ...[
                      KundliTypesSection(kundliTypes: viewModel.kundliTypes),
                      const SizedBox(height: 24),
                    ],

                    // Astrologer List Section
                    AstrologerListSection(
                      astrologers: viewModel.topAstrologers,
                      isLoading: viewModel.isLoading,
                      onViewAll: () {
                        Navigator.pushNamed(context, '/view-all-astrologers');
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
