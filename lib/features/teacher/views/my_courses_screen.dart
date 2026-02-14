import 'package:flutter/material.dart';
import 'package:karmasu/features/teacher/model/course.dart';
import 'package:karmasu/features/teacher/service/enrollment_service.dart';
import 'package:karmasu/features/teacher/service/teacher_service.dart';
import 'package:provider/provider.dart';

import '../../../core/services/auth_service.dart';
import '../../../routes.dart';

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  late EnrollmentService _enrollmentService;
  late TeacherService _teacherService;

  List<Course> _enrolledCourses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _enrollmentService = EnrollmentService();
    _teacherService = TeacherService();
    _loadEnrolledCourses();
  }

  Future<void> _loadEnrolledCourses() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.getCurrentUser();

    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final courseIds = await _enrollmentService.getUserEnrolledCourseIds(
      user.id,
    );

    final courses = await _teacherService.getCoursesByIds(courseIds);

    setState(() {
      _enrolledCourses = courses;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Courses')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _enrolledCourses.isEmpty
          ? _buildEmptyState()
          : _buildCourseList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.school_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No courses enrolled yet'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.home),
            child: const Text('Browse Courses'),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _enrolledCourses.length,
      itemBuilder: (context, index) {
        final course = _enrolledCourses[index];
        return ListTile(
          title: Text(course.title),
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.courseDetail,
            arguments: course,
          ),
        );
      },
    );
  }
}
