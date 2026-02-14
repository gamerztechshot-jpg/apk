// features/punchang/views/panchang_content_view.dart
import 'package:flutter/material.dart';
import '../../../core/models/panchang_model.dart';
import '../viewmodels/panchang_viewmodel.dart';
import 'panchang_date_card.dart';
import 'panchang_info_grid.dart';
import 'panchang_sacred_timings.dart';
import 'panchang_avoid_times.dart';
import 'panchang_guidance.dart';
import 'panchang_timing_section.dart';

class PanchangContentView extends StatelessWidget {
  final PanchangModel panchang;
  final bool isHindi;
  final DateTime selectedDate;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;
  final VoidCallback onDatePicker;
  final VoidCallback onRefresh;
  final PanchangViewModel viewModel;

  const PanchangContentView({
    super.key,
    required this.panchang,
    required this.isHindi,
    required this.selectedDate,
    required this.onPreviousDay,
    required this.onNextDay,
    required this.onDatePicker,
    required this.onRefresh,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
      },
      color: Colors.orange.shade600,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Card with navigation
                  PanchangDateCard(
                    panchang: panchang,
                    isHindi: isHindi,
                    selectedDate: selectedDate,
                    onPreviousDay: onPreviousDay,
                    onNextDay: onNextDay,
                    onDatePicker: onDatePicker,
                    viewModel: viewModel,
                  ),
                  const SizedBox(height: 24),

                  // Information Grid (Nakshatra, Sun/Moon Signs, Paksha)
                  PanchangInfoGrid(
                    panchang: panchang,
                    isHindi: isHindi,
                    viewModel: viewModel,
                  ),
                  const SizedBox(height: 24),

                  // Sacred Timings Section
                  PanchangSacredTimings(panchang: panchang, isHindi: isHindi),
                  const SizedBox(height: 24),

                  // Avoid These Times Section
                  PanchangAvoidTimes(panchang: panchang, isHindi: isHindi),
                  const SizedBox(height: 24),

                  // Directional Guidance
                  PanchangGuidance(panchang: panchang, isHindi: isHindi),
                  const SizedBox(height: 24),

                  // Sun/Moon Timings and Karan/Yoga
                  PanchangTimingSection(panchang: panchang, isHindi: isHindi),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
