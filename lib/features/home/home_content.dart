// features/home/home_content.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/language_service.dart';
import '../../l10n/app_localizations.dart';
import '../../core/widgets/dynamic_content_boxes.dart';
import '../../core/widgets/invite_banner_widget.dart';
import '../mantra_generator/views/screens/mantra_generator_main_screen.dart';
import 'banner.dart';
import 'festival.dart';
import 'widgets/home_bottom_banner.dart';
import 'widgets/home_feature_cards.dart';
import 'widgets/home_footer_section.dart';
import 'widgets/home_header.dart';
import 'widgets/home_highlights_section.dart';
import 'widgets/home_quick_actions.dart';
import 'widgets/home_search_bar.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Panchang loads only when user opens Panchang screen - avoids home hang

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final user = authService.getCurrentUser();
        final userName = user?.userMetadata?['name'] ?? 'User';
        final userProfileImage = user?.userMetadata?['profile_image_url'];

        return Consumer<LanguageService>(
          builder: (context, languageService, child) {
            final l10n = AppLocalizations.of(context)!;
            return Scaffold(
              backgroundColor: Colors.white,
              body: Stack(
                children: [
                  // Main content
                  SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      children: [
                        // Header Section
                        HomeHeader(
                          userName: userName,
                          profileImageUrl: userProfileImage,
                          l10n: l10n,
                        ),

                        // Banner Section
                        const BannerCarousel(),

                        // Search Bar
                        HomeSearchBar(
                          controller: _searchController,
                          l10n: l10n,
                          onChanged: (_) => setState(() {}),
                          onClear: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        ),

                        // Main Feature Cards
                        HomeFeatureCards(l10n: l10n),

                        // Bottom Banner (Naam Japa)
                        HomeBottomBanner(l10n: l10n),

                        // Dynamic Content Boxes
                        const DynamicContentBoxes(),

                        // Festival Card
                        const FestivalCard(),

                        // Home Highlights (after festivals)
                        const HomeHighlightsSection(),

                        // Quick Actions (after pujas)
                        HomeQuickActions(l10n: l10n),

                        // Footer Highlights (after puja list)
                        HomeFooterSection(
                          onBackToTop: () {
                            _scrollController.animateTo(
                              0,
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOut,
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Floating Invite Banner (overlays all content)
                  const InviteBannerWidget(),
                ],
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MantraGeneratorMainScreen(),
                    ),
                  );
                },
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.psychology),
                label: Text(
                  languageService.isHindi ? 'एआई सखा' : 'AI Sakha',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.endFloat,
            );
          },
        );
      },
    );
  }
}
