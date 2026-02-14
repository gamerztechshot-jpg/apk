import 'package:flutter/material.dart';
import '../model/course.dart';
import '../model/webinar.dart';
import '../model/quiz.dart';
import '../model/teacher_model.dart';
import '../service/teacher_service.dart';

class TeacherViewModel extends ChangeNotifier {
  final TeacherService _teacherService = TeacherService();

  List<Course> _courses = [];
  List<Webinar> _webinars = [];
  List<Quiz> _quizzes = [];
  List<TeacherModel> _teachers = [];

  bool _isLoading = false;
  String? _error;

  List<Course> get courses => _courses;
  List<Webinar> get webinars => _webinars;
  List<Quiz> get quizzes => _quizzes;
  List<TeacherModel> get teachers => _teachers;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initializeData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _teacherService.getCourses(),
        _teacherService.getWebinars(),
        _teacherService.getQuizzes(),
        _teacherService.getTeachers(),
      ]);

      _courses = results[0] as List<Course>;
      _webinars = results[1] as List<Webinar>;
      _quizzes = results[2] as List<Quiz>;
      _teachers = results[3] as List<TeacherModel>;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshData() async {
    await initializeData();
  }
}
