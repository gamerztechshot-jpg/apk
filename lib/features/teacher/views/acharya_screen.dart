import 'package:flutter/material.dart';
import 'widgets/teacher_dashboard_section.dart';
import '../../../routes.dart';
import '../../../l10n/app_localizations.dart';

class AcharyaScreen extends StatelessWidget {
  const AcharyaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            return Text(
              l10n?.acharya ?? 'Gurukul',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            );
          },
        ),
        backgroundColor: Colors.orange.shade600,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_added, color: Colors.white),
            tooltip: 'My Learning',
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.myLearning);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.shade50, Colors.white],
          ),
        ),
        child: const SingleChildScrollView(
          padding: EdgeInsets.only(top: 0, bottom: 20),
          child: TeacherDashboardSection(),
        ),
      ),
    );
  }
}
