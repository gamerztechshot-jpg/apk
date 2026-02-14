// features/punchang/punnchang.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/language_service.dart';
import '../../core/providers/panchang_provider.dart';
import '../../l10n/app_localizations.dart';
import 'models/panchang_ui_state.dart';
import 'viewmodels/panchang_viewmodel.dart';
import 'views/panchang_widgets.dart';
import 'views/panchang_content_view.dart';
import 'repositories/panchang_repository.dart';

class PanchangScreen extends StatefulWidget {
  const PanchangScreen({super.key});

  @override
  State<PanchangScreen> createState() => _PanchangScreenState();
}

class _PanchangScreenState extends State<PanchangScreen> {
  late PanchangViewModel _viewModel;
  final PanchangRepository _repository = PanchangRepository();

  @override
  void initState() {
    super.initState();
    _viewModel = PanchangViewModel();
    // Ensure we have data for today when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        final isHindi = Provider.of<LanguageService>(
          context,
          listen: false,
        ).isHindi;
        await Provider.of<PanchangProvider>(context, listen: false).fetchForDate(
          isHindi,
          date: DateTime.now(),
        );
      } catch (e) {
      }
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _pickDate(AppLocalizations l10n, bool isHindi) async {
    final provider = Provider.of<PanchangProvider>(context, listen: false);

    final picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: DateTime(DateTime.now().year - 1, 1, 1),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
      helpText: isHindi ? 'तारीख चुनें' : 'Select date',
      cancelText: isHindi ? 'रद्द करें' : 'Cancel',
      confirmText: isHindi ? 'ठीक है' : 'OK',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange.shade600,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
            dialogBackgroundColor: Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.orange.shade600,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      await provider.fetchForDate(isHindi, date: picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final languageService = Provider.of<LanguageService>(context);
    final isHindi = languageService.isHindi;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dailyPanchang),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        color: Colors.white,
        child: Consumer<PanchangProvider>(
          builder: (context, provider, child) {
            try {
            // Loading state
            if (provider.isLoading) {
              return PanchangWidgets.buildLoadingScreen();
            }

            // Error state
            if (provider.error != null && !provider.hasData) {
              return PanchangWidgets.buildErrorWidget(
                context,
                null,
                () => provider.fetchForDate(
                  isHindi,
                  date: provider.selectedDate,
                  forceRefresh: true,
                ),
                () => provider.fetchForDate(
                  isHindi,
                  date: provider.selectedDate,
                  forceRefresh: true,
                ),
              );
            }

            // Get panchang for selected date
            final panchang = provider.findPanchangForDate(
              provider.selectedDate,
              isHindi,
            );

            // No data state
            if (panchang == null) {
              return PanchangWidgets.buildSimpleDateDisplay(
                isHindi,
                _viewModel,
                () => provider.fetchForDate(
                  isHindi,
                  date: provider.selectedDate,
                  forceRefresh: true,
                ),
              );
            }

            // Check if this is fallback data
            final isFallback = _repository.isFallbackData(panchang);

            // Fallback state
            if (isFallback) {
              return PanchangWidgets.buildFallbackDisplay(
                panchang,
                isHindi,
                _viewModel,
                () => provider.fetchForDate(
                  isHindi,
                  date: provider.selectedDate,
                  forceRefresh: true,
                ),
                () => provider.fetchForDate(
                  isHindi,
                  date: provider.selectedDate,
                  forceRefresh: true,
                ),
              );
            }

            // Success state - show full content
            return PanchangContentView(
              panchang: panchang,
              isHindi: isHindi,
              selectedDate: provider.selectedDate,
              onPreviousDay: () => provider.previousDay(),
              onNextDay: () => provider.nextDay(),
              onDatePicker: () => _pickDate(l10n, isHindi),
              onRefresh: () async {
                await provider.fetchForDate(
                  isHindi,
                  date: provider.selectedDate,
                  forceRefresh: true,
                );
              },
              viewModel: _viewModel,
            );
            } catch (e, stack) {
              return PanchangWidgets.buildErrorWidget(
                context,
                provider,
                () => provider.fetchForDate(isHindi, date: provider.selectedDate, forceRefresh: true),
                () => provider.fetchForDate(isHindi, date: provider.selectedDate, forceRefresh: true),
              );
            }
          },
        ),
      ),
    );
  }
}
