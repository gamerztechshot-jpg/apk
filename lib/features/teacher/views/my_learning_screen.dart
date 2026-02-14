import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/course.dart';
import '../model/webinar.dart';
import '../model/quiz_attempt.dart';
import '../service/quiz_service.dart';
import '../service/enrollment_service.dart';
import '../service/teacher_service.dart';
import '../../../routes.dart';

class MyLearningScreen extends StatefulWidget {
  final int initialTabIndex;
  const MyLearningScreen({super.key, this.initialTabIndex = 0});

  @override
  State<MyLearningScreen> createState() => _MyLearningScreenState();
}

class _MyLearningScreenState extends State<MyLearningScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final QuizService _quizService = QuizService();
  final EnrollmentService _enrollmentService = EnrollmentService();
  final TeacherService _teacherService = TeacherService();

  bool _isCoursesLoading = true;
  bool _isWebinarsLoading = true;
  bool _isQuizzesLoading = true;

  List<Course> _enrolledCourses = [];
  List<Webinar> _enrolledWebinars = [];
  List<QuizAttempt> _quizAttempts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    // Load Courses
    _enrollmentService
        .getUserEnrolledCourseIds(userId)
        .then((ids) {
          return _teacherService.getCoursesByIds(ids);
        })
        .then((courses) {
          if (mounted) {
            setState(() {
              _enrolledCourses = courses;
              _isCoursesLoading = false;
            });
          }
        });

    // Load Webinars
    _enrollmentService
        .getUserEnrolledWebinarIds(userId)
        .then((ids) {
          return _teacherService.getWebinarsByIds(ids);
        })
        .then((webinars) {
          if (mounted) {
            setState(() {
              _enrolledWebinars = webinars;
              _isWebinarsLoading = false;
            });
          }
        });

    // Load Quizzes
    _quizService.getUserQuizHistory(userId).then((attempts) {
      if (mounted) {
        setState(() {
          _quizAttempts = attempts;
          _isQuizzesLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFD),
      appBar: AppBar(
        title: const Text(
          'My Learning',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.orange.shade600,
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 4,
          labelPadding: const EdgeInsets.symmetric(vertical: 8),
          indicatorPadding: const EdgeInsets.symmetric(horizontal: 20),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'COURSES', icon: Icon(Icons.auto_stories, size: 20)),
            Tab(text: 'WEBINARS', icon: Icon(Icons.videocam, size: 20)),
            Tab(text: 'QUIZZES', icon: Icon(Icons.analytics, size: 20)),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.shade600, Colors.white, Colors.white],
            stops: const [0.0, 0.15, 1.0],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildCoursesTab(),
            _buildWebinarsTab(),
            _buildQuizzesTab(),
          ],
        ),
      ),
    );
  }

  // ================= COURSES TAB =================

  Widget _buildCoursesTab() {
    if (_isCoursesLoading) return _buildLoading();
    if (_enrolledCourses.isEmpty)
      return _buildEmptyState(
        icon: Icons.school_outlined,
        title: 'No Course Found',
        subtitle: 'Unlock your potential by enrolling in our premium courses.',
        buttonText: 'Explore Courses',
        onPressed: () => Navigator.pop(context),
      );

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _enrolledCourses.length,
      itemBuilder: (context, index) {
        final course = _enrolledCourses[index];
        return _buildEnhancedCourseCard(course);
      },
    );
  }

  Widget _buildEnhancedCourseCard(Course course) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.courseDetail,
        arguments: course,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  child: AspectRatio(
                    aspectRatio: 21 / 9,
                    child: Container(
                      color: Colors.orange.shade50,
                      child: course.thumbnail.startsWith('http')
                          ? Image.network(
                              course.thumbnail,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.broken_image,
                                  size: 40,
                                  color: Colors.orange,
                                );
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  },
                            )
                          : const Icon(
                              Icons.image,
                              color: Colors.orange,
                              size: 40,
                            ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      course.category.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: Color(0xFF1A1A1A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.menu_book,
                              size: 16,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${course.playlist.length} Lessons',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber.shade700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              course.ratings.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Color(0xFF1A1A1A),
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade600,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 28,
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

  // ================= WEBINARS TAB =================

  Widget _buildWebinarsTab() {
    if (_isWebinarsLoading) return _buildLoading();
    if (_enrolledWebinars.isEmpty)
      return _buildEmptyState(
        icon: Icons.videocam_outlined,
        title: 'No Webinar Joined',
        subtitle: 'Knowledge sharing at its best. Join upcoming webinars!',
        buttonText: 'Browse Webinars',
        onPressed: () => Navigator.pop(context),
      );

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _enrolledWebinars.length,
      itemBuilder: (context, index) {
        final webinar = _enrolledWebinars[index];
        return _buildEnhancedWebinarCard(webinar);
      },
    );
  }

  Widget _buildEnhancedWebinarCard(Webinar webinar) {
    final dateStr = DateFormat(
      'MMM dd, yyyy • hh:mm a',
    ).format(webinar.startTime);
    final isUpcoming = webinar.startTime.isAfter(DateTime.now());

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.webinarDetail,
        arguments: webinar,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 70,
              height: 70,
              child: Container(
                color: Colors.orange.shade50,
                child: webinar.thumbnail.startsWith('http')
                    ? Image.network(
                        webinar.thumbnail,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.broken_image,
                            size: 40,
                            color: Colors.orange,
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                      )
                    : const Icon(Icons.videocam, color: Colors.orange),
              ),
            ),
          ),
          title: Text(
            webinar.title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 12,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    dateStr,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isUpcoming ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isUpcoming ? 'UPCOMING' : 'COMPLETED',
                  style: TextStyle(
                    color: isUpcoming
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.orange,
              size: 14,
            ),
          ),
        ),
      ),
    );
  }

  // ================= QUIZZES TAB =================

  Widget _buildQuizzesTab() {
    if (_isQuizzesLoading) return _buildLoading();
    if (_quizAttempts.isEmpty)
      return _buildEmptyState(
        icon: Icons.quiz_outlined,
        title: 'No Quiz Attempted',
        subtitle: 'Sharpen your skills. Try out our daily knowledge tests!',
        buttonText: 'Take a Quiz',
        onPressed: () => Navigator.pop(context),
      );

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _quizAttempts.length,
      itemBuilder: (context, index) {
        final attempt = _quizAttempts[index];
        return _buildEnhancedQuizAttemptCard(attempt);
      },
    );
  }

  Widget _buildEnhancedQuizAttemptCard(QuizAttempt attempt) {
    final isPassed = (attempt.scorePercentage ?? 0) >= 60;
    final dateStr = DateFormat('MMM dd, yyyy').format(attempt.startedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 55,
                  height: 55,
                  child: CircularProgressIndicator(
                    value: (attempt.scorePercentage ?? 0) / 100,
                    strokeWidth: 5,
                    backgroundColor: isPassed
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isPassed ? Colors.green : Colors.red,
                    ),
                  ),
                ),
                Text(
                  '${attempt.scorePercentage?.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: isPassed
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attempt.quizTitle ?? 'Daily Quiz',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dateStr,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildStatChip(
                        Icons.check_circle,
                        '${attempt.correctAnswers} Correct',
                        Colors.green,
                      ),
                      const SizedBox(width: 12),
                      _buildStatChip(
                        Icons.help,
                        '${attempt.totalQuestions} Total',
                        Colors.blueGrey,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              isPassed ? Icons.emoji_events : Icons.refresh,
              color: isPassed ? Colors.amber.shade400 : Colors.orange.shade200,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  // ================= COMMON =================

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: Colors.orange, strokeWidth: 3),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 60, color: Colors.orange.shade200),
            ),
            const SizedBox(height: 32),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 10,
                shadowColor: Colors.orange.withOpacity(0.4),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
