// features/teacher/views/widgets/teacher_dashboard_section.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../routes.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/services/language_service.dart';
import '../../model/course.dart';
import '../../viewmodel/teacher_viewmodel.dart';
import 'course_card.dart';
import 'webinar_card.dart';
import 'quiz_card.dart';
import 'course_banner_carousel.dart';
import '../view_all_quizzes_screen.dart';
import '../../../sadhna/sadhna.dart';
import '../acharya_screen.dart';
import '../my_learning_screen.dart';

class TeacherDashboardSection extends StatefulWidget {
  const TeacherDashboardSection({super.key});

  @override
  State<TeacherDashboardSection> createState() =>
      _TeacherDashboardSectionState();
}

class _TeacherDashboardSectionState extends State<TeacherDashboardSection> {
  static const String _allCategoryKey = 'all';
  final TextEditingController _courseSearchController =
      TextEditingController();
  String _selectedCategoryKey = _allCategoryKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeacherViewModel>().initializeData();
    });
    _courseSearchController.addListener(_onCourseSearchChanged);
  }

  @override
  void dispose() {
    _courseSearchController.removeListener(_onCourseSearchChanged);
    _courseSearchController.dispose();
    super.dispose();
  }

  void _onCourseSearchChanged() {
    setState(() {});
  }

  String _toTitleCase(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  List<_CategoryOption> _buildCategoryOptions(List<Course> courses) {
    final Map<String, String> categoryMap = {};
    for (final course in courses) {
      final raw = course.category.trim();
      if (raw.isEmpty) continue;
      final key = raw.toLowerCase();
      categoryMap.putIfAbsent(key, () => _toTitleCase(raw));
    }

    final options = [
      const _CategoryOption(key: _allCategoryKey, label: 'All'),
      ...categoryMap.entries.map(
        (entry) => _CategoryOption(key: entry.key, label: entry.value),
      ),
    ];

    return options;
  }

  List<Course> _filterCourses(
    List<Course> courses,
    String query,
    String selectedCategoryKey,
  ) {
    final normalizedQuery = query.trim().toLowerCase();
    return courses.where((course) {
      final matchesQuery = normalizedQuery.isEmpty ||
          course.title.toLowerCase().contains(normalizedQuery) ||
          course.description.toLowerCase().contains(normalizedQuery);
      final categoryKey = course.category.trim().toLowerCase();
      final matchesCategory = selectedCategoryKey == _allCategoryKey ||
          categoryKey == selectedCategoryKey;
      return matchesQuery && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TeacherViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading && viewModel.courses.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final l10n = AppLocalizations.of(context);
        
        final categoryOptions = _buildCategoryOptions(viewModel.courses);
        final filteredCourses = _filterCourses(
          viewModel.courses,
          _courseSearchController.text,
          _selectedCategoryKey,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Banners Section (before courses) - Full width
              const CourseBannerCarousel(),
              
              // Our Courses Section
              if (viewModel.courses.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _SectionHeader(title: l10n?.ourCourses ?? 'Our Courses'),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _courseSearchController,
                    decoration: InputDecoration(
                      hintText: l10n?.searchPlaceholder ?? 'Search...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _courseSearchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () => _courseSearchController.clear(),
                              icon: const Icon(Icons.close),
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.orange.shade100),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.orange.shade100),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.orange.shade400),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: categoryOptions.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final option = categoryOptions[index];
                        final isSelected =
                            option.key == _selectedCategoryKey;
                        return ChoiceChip(
                          label: Text(option.label),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              _selectedCategoryKey = option.key;
                            });
                          },
                          selectedColor: Colors.orange.shade400,
                          backgroundColor: Colors.orange.shade50,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.orange.shade800,
                            fontWeight: FontWeight.w700,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    height: 260,
                    child: filteredCourses.isEmpty
                        ? Center(
                            child: Text(
                              'No courses found',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: filteredCourses.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(left: 4.0),
                                child: CourseCard(
                                  course: filteredCourses[index],
                                  onEnroll: () {
                                    // handled by CourseDetailScreen
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // Upcoming Webinars Section
              if (viewModel.webinars.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _SectionHeader(title: l10n?.upcomingWebinars ?? 'Upcoming Webinars'),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: viewModel.webinars
                        .take(3)
                        .map(
                          (webinar) => WebinarCard(
                            webinar: webinar,
                            onSetReminder: () {
                              // TODO: Implement reminder
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // Daily Quiz Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(title: l10n?.quizzes ?? 'Quizzes'),
                    const SizedBox(height: 12),
                    if (viewModel.quizzes.isNotEmpty)
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 1.15,
                            ),
                        itemCount: viewModel.quizzes.length.clamp(0, 4),
                        itemBuilder: (context, index) {
                          final quiz = viewModel.quizzes[index];
                          return QuizCard(
                            quiz: quiz,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.quizPlayer,
                                arguments: {'quiz': quiz, 'courseId': null},
                              );
                            },
                          );
                        },
                      )
                    else
                      Text(l10n?.noQuizzesAvailable ?? 'No quizzes available'),
                    const SizedBox(height: 20),
                    if (viewModel.quizzes.length > 4)
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ViewAllQuizzesScreen(
                                  quizzes: viewModel.quizzes,
                                ),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.orange.shade50,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text(
                            l10n?.viewMore ?? 'View More',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // More on Karmasu Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                      title: (l10n?.localeName == 'hi')
                          ? 'कर्मसु में और भी'
                          : 'More on Karmasu',
                    ),
                    const SizedBox(height: 12),
                    _buildMoreOnKarmasu(context, viewModel),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMoreOnKarmasu(
    BuildContext context,
    TeacherViewModel viewModel,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isHindi =
        Provider.of<LanguageService>(context, listen: false).isHindi;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: isTablet ? 2.0 : 1.25,
      children: [
        _MoreCard(
          title: isHindi ? 'गुरुकुल' : 'Gurukul',
          subtitle: isHindi
              ? 'आचार्यों के मार्गदर्शन में पारंपरिक ज्ञान'
              : 'Traditional wisdom guided by Acharyas',
          icon: Icons.self_improvement,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AcharyaScreen()),
            );
          },
        ),
        _MoreCard(
          title: isHindi ? 'कोर्स' : 'Courses',
          subtitle: isHindi
              ? 'वेद, गीता और शास्त्र की संरचित शिक्षा'
              : 'Structured learning of Ved, Gita & Shastra',
          icon: Icons.menu_book,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MyLearningScreen(initialTabIndex: 0),
              ),
            );
          },
        ),
        _MoreCard(
          title: isHindi ? 'संस्कार' : 'Sanskar',
          subtitle: isHindi
              ? 'पवित्र संस्कार व जीवन विधि मार्गदर्शन'
              : 'Sacred rituals & life ceremonies guidance',
          icon: Icons.emoji_objects,
          onTap: () {
            if (viewModel.quizzes.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isHindi
                        ? 'फिलहाल कोई क्विज़ उपलब्ध नहीं है'
                        : 'No quizzes available right now',
                  ),
                ),
              );
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ViewAllQuizzesScreen(
                  quizzes: viewModel.quizzes,
                ),
              ),
            );
          },
        ),
        _MoreCard(
          title: isHindi ? 'साधना' : 'Sadhana',
          subtitle: isHindi
              ? 'दैनिक आध्यात्मिक अभ्यास और नाम जप'
              : 'Daily spiritual practice & Naam Japa',
          icon: Icons.favorite,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SadhnaScreen()),
            );
          },
        ),
      ],
    );
  }
}

class _CategoryOption {
  final String key;
  final String label;

  const _CategoryOption({required this.key, required this.label});
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: Color(0xFF4E342E), // Brownish color from design
        fontFamily: 'Playfair Display', // Assuming a premium font is used
      ),
    );
  }
}

class _MoreCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _MoreCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(isTablet ? 18 : 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isTablet ? 10 : 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.orange.shade700, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF4E342E),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                subtitle,
                maxLines: isTablet ? 3 : 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
