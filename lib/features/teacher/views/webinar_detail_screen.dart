import 'package:flutter/material.dart';
import '../model/webinar.dart';
import '../../../routes.dart';
import 'package:karmasu/features/teacher/service/enrollment_service.dart';
import 'package:provider/provider.dart';

import '../../../core/services/auth_service.dart';
import 'webinar_payment_screen.dart';
import 'widgets/webinar_detail/webinar_bottom_bar.dart';
import 'widgets/webinar_detail/webinar_description.dart';
import 'widgets/webinar_detail/webinar_header.dart';
import 'widgets/webinar_detail/webinar_resources.dart';
import 'widgets/webinar_detail/webinar_sliver_app_bar.dart';
import 'widgets/webinar_detail/webinar_speaker_section.dart';
import 'widgets/webinar_detail/webinar_time_info.dart';

class WebinarDetailScreen extends StatefulWidget {
  final Webinar webinar;

  const WebinarDetailScreen({super.key, required this.webinar});

  @override
  State<WebinarDetailScreen> createState() => _WebinarDetailScreenState();
}

class _WebinarDetailScreenState extends State<WebinarDetailScreen> {
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

    final enrolled = await _enrollmentService.isUserEnrolledInWebinar(
      user.id,
      widget.webinar.id,
    );

    if (mounted) {
      setState(() {
        _isEnrolled = enrolled;
        _isLoading = false;
      });
    }
  }

  void _handleAction() {
    if (_isEnrolled) {
      Navigator.pushNamed(
        context,
        AppRoutes.webinarPlayer,
        arguments: widget.webinar,
      );
    } else {
      // Register logic
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WebinarPaymentScreen(webinar: widget.webinar),
        ),
      ).then((_) => _checkEnrollmentStatus());
    }
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
          WebinarSliverAppBar(webinar: widget.webinar),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WebinarHeader(webinar: widget.webinar),
                  const SizedBox(height: 24),
                  WebinarTimeInfo(webinar: widget.webinar),
                  const SizedBox(height: 24),
                  WebinarSpeakerSection(webinar: widget.webinar),
                  const SizedBox(height: 24),
                  WebinarDescription(webinar: widget.webinar),
                  const SizedBox(height: 24),
                  WebinarResources(
                    webinar: widget.webinar,
                    isEnrolled: _isEnrolled,
                  ),
                  // Bottom padding
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: WebinarBottomBar(
        webinar: widget.webinar,
        isEnrolled: _isEnrolled,
        onAction: _handleAction,
      ),
    );
  }
}
