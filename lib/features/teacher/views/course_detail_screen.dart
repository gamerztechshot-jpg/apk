import 'package:flutter/material.dart';
import 'package:karmasu/features/teacher/model/course.dart';
import 'package:karmasu/features/teacher/service/enrollment_service.dart';
import 'package:provider/provider.dart';

import '../../../core/services/auth_service.dart';
import 'course_payment_screen.dart';
import 'widgets/course_detail/course_description.dart';
import 'widgets/course_detail/course_header.dart';
import 'widgets/course_detail/course_metrics.dart';
import 'widgets/course_detail/course_playlist_view.dart';
import 'widgets/course_detail/course_reviews.dart';
import 'widgets/course_detail/course_sliver_app_bar.dart';
import 'widgets/course_detail/enroll_bottom_bar.dart';
import 'widgets/course_detail/instructor_section.dart';

class CourseDetailScreen extends StatefulWidget {
  final Course course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  late EnrollmentService _enrollmentService;

  bool _isEnrolled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _enrollmentService = EnrollmentService();
    _checkEnrollmentStatus();
  }

  Future<void> _checkEnrollmentStatus() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.getCurrentUser();

    if (user == null) {
      if (mounted) {
        setState(() {
          _isEnrolled = false;
          _isLoading = false;
        });
      }
      return;
    }

    final enrolled = await _enrollmentService.isUserEnrolledInCourse(
      user.id,
      widget.course.id,
    );

    if (mounted) {
      setState(() {
        _isEnrolled = enrolled;
        _isLoading = false;
      });
    }
  }

  void _handleEnroll() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CoursePaymentScreen(course: widget.course),
      ),
    ).then((_) => _checkEnrollmentStatus());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          CourseSliverAppBar(course: widget.course),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CourseHeader(course: widget.course),
                  const SizedBox(height: 16),
                  CourseMetrics(course: widget.course),
                  const SizedBox(height: 16),
                  CourseDescription(course: widget.course),
                  const SizedBox(height: 16),
                  InstructorSection(course: widget.course),
                  const SizedBox(height: 16),
                  CoursePlaylistView(
                    course: widget.course,
                    isEnrolled: _isEnrolled,
                    onLessonTap: (index) {
                      Navigator.pushNamed(
                        context,
                        '/lesson-player',
                        arguments: {
                          'course': widget.course,
                          'initialIndex': index,
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  CourseReviews(course: widget.course),
                  const SizedBox(height: 120), // Bottom bar space
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: EnrollBottomBar(
        course: widget.course,
        isEnrolled: _isEnrolled,
        onEnroll: _handleEnroll,
      ),
    );
  }
}
