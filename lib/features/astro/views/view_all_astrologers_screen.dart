// features/astro/views/view_all_astrologers_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:karmasu/l10n/app_localizations.dart';
import '../viewmodels/astrologer_viewmodel.dart';
import 'widgets/astrologer_card.dart';
import 'astrologer_detail_screen.dart';

class ViewAllAstrologersScreen extends StatefulWidget {
  const ViewAllAstrologersScreen({super.key});

  @override
  State<ViewAllAstrologersScreen> createState() =>
      _ViewAllAstrologersScreenState();
}

class _ViewAllAstrologersScreenState extends State<ViewAllAstrologersScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AstrologerViewModel>().loadAstrologers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.allAstrologers),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchAstrologers,
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey.shade400),
                        onPressed: () {
                          _searchController.clear();
                          context.read<AstrologerViewModel>().loadAstrologers();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {});
                if (value.isEmpty) {
                  context.read<AstrologerViewModel>().loadAstrologers();
                } else {
                  context.read<AstrologerViewModel>().searchAstrologers(value);
                }
              },
            ),
          ),
        ),
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

            if (viewModel.astrologers.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_search,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _searchController.text.isNotEmpty
                          ? l10n.noAstrologersFoundFor(_searchController.text)
                          : l10n.noAstrologersFound,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                    if (_searchController.text.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          _searchController.clear();
                          viewModel.loadAstrologers();
                        },
                        child: Text(l10n.clearSearch),
                      ),
                    ],
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => viewModel.refresh(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: viewModel.astrologers.length,
                itemBuilder: (context, index) {
                  final astrologer = viewModel.astrologers[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: AstrologerCard(
                      astrologer: astrologer,
                      onBook: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AstrologerDetailScreen(astrologer: astrologer),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
