// routes.dart
import 'package:flutter/material.dart';
import 'package:karmasu/features/teacher/views/course_payment_screen.dart';
import 'package:karmasu/features/teacher/views/my_learning_screen.dart';
import 'package:karmasu/features/teacher/views/quiz_player_screen.dart';
import 'package:karmasu/features/teacher/views/webinar_payment_screen.dart';
import 'features/auth/login.dart';
import 'features/home/home.dart';
import 'features/punchang/punnchang.dart';
import 'features/puja_booking/puja_list.dart';
import 'features/puja_booking/puja_detail_screen.dart';
import 'features/astro/views/astrologer_screen.dart';
import 'features/astro/views/view_all_astrologers_screen.dart';
import 'features/astro/views/your_astrologers_screen.dart';
import 'core/models/puja_model.dart';
import 'features/teacher/views/course_detail_screen.dart';
import 'features/teacher/views/webinar_detail_screen.dart';
import 'features/teacher/views/webinar_player_screen.dart';
import 'features/teacher/views/lesson_player_screen.dart';
import 'features/teacher/model/course.dart';
import 'features/teacher/model/webinar.dart';
import 'features/ramnam_lekhan/screens/profile_section/profile_section.dart';

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String panchang = '/panchang';
  static const String pujaList = '/puja-list';
  static const String pujaDetail = '/puja-detail';
  static const String astrologer = '/astrologer';
  static const String viewAllAstrologers = '/view-all-astrologers';
  static const String yourAstrologers = '/your-astrologers';
  static const String courseDetail = '/course-detail';
  static const String webinarDetail = '/webinar-detail';
  static const String lessonPlayer = '/lesson-player';
  static const String coursePayment = '/course-payment';
  static const String webinarPayment = '/webinar-payment';
  static const String quizPlayer = '/quiz-player';
  static const String myCourses = '/my-courses';
  static const String myLearning = '/my-learning';
  static const String webinarPlayer = '/webinar-player';
  static const String sadhnaDashboard = '/sadhna-dashboard';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case panchang:
        return MaterialPageRoute(builder: (_) => const PanchangScreen());
      case pujaList:
        return MaterialPageRoute(builder: (_) => const PujaListScreen());
      case pujaDetail:
        final puja = settings.arguments as PujaModel?;
        if (puja != null) {
          return MaterialPageRoute(
            builder: (_) => PujaDetailScreen(puja: puja),
          );
        }
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Puja not found'))),
        );
      case astrologer:
        return MaterialPageRoute(builder: (_) => const AstrologerScreen());
      case viewAllAstrologers:
        return MaterialPageRoute(
          builder: (_) => const ViewAllAstrologersScreen(),
        );
      case yourAstrologers:
        return MaterialPageRoute(builder: (_) => const YourAstrologersScreen());
      case courseDetail:
        final course = settings.arguments as Course?;
        if (course != null) {
          return MaterialPageRoute(
            builder: (_) => CourseDetailScreen(course: course),
          );
        }
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Course not found'))),
        );
      case lessonPlayer:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null && args['course'] is Course) {
          return MaterialPageRoute(
            builder: (_) => LessonPlayerScreen(
              course: args['course'],
              initialLessonIndex: args['initialIndex'] ?? 0,
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Lesson data missing'))),
        );
      case webinarDetail:
        final webinar = settings.arguments as Webinar?;
        if (webinar != null) {
          return MaterialPageRoute(
            builder: (_) => WebinarDetailScreen(webinar: webinar),
          );
        }
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Webinar not found'))),
        );
      case coursePayment:
        final course = settings.arguments as Course;
        return MaterialPageRoute(
          builder: (_) => CoursePaymentScreen(course: course),
        );

      case webinarPayment:
        final webinar = settings.arguments as Webinar;
        return MaterialPageRoute(
          builder: (_) => WebinarPaymentScreen(webinar: webinar),
        );

      case quizPlayer:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) =>
              QuizPlayerScreen(quiz: args['quiz'], courseId: args['courseId']),
        );

      case webinarPlayer:
        final webinar = settings.arguments as Webinar?;
        if (webinar != null) {
          return MaterialPageRoute(
            builder: (_) => WebinarPlayerScreen(webinar: webinar),
          );
        }
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Webinar not found'))),
        );

      case myCourses:
      case myLearning:
        final initialTab = settings.arguments as int? ?? 0;
        return MaterialPageRoute(
          builder: (_) => MyLearningScreen(initialTabIndex: initialTab),
        );

      case sadhnaDashboard:
        return MaterialPageRoute(
          builder: (_) => const NaamJapaProfileSection(),
        );

      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Route not found'))),
        );
    }
  }
}
