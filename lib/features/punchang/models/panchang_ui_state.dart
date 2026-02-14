// features/punchang/models/panchang_ui_state.dart
import '../../../core/models/panchang_model.dart';

/// Represents the UI state of the Panchang screen
enum PanchangUIStatus { initial, loading, success, error, fallback }

class PanchangUIState {
  final PanchangUIStatus status;
  final PanchangModel? panchang;
  final String? errorMessage;
  final DateTime selectedDate;

  PanchangUIState({
    required this.status,
    this.panchang,
    this.errorMessage,
    required this.selectedDate,
  });

  factory PanchangUIState.initial() {
    return PanchangUIState(
      status: PanchangUIStatus.initial,
      selectedDate: DateTime.now(),
    );
  }

  factory PanchangUIState.loading(DateTime selectedDate) {
    return PanchangUIState(
      status: PanchangUIStatus.loading,
      selectedDate: selectedDate,
    );
  }

  factory PanchangUIState.success(
    PanchangModel panchang,
    DateTime selectedDate,
  ) {
    return PanchangUIState(
      status: PanchangUIStatus.success,
      panchang: panchang,
      selectedDate: selectedDate,
    );
  }

  factory PanchangUIState.error(String message, DateTime selectedDate) {
    return PanchangUIState(
      status: PanchangUIStatus.error,
      errorMessage: message,
      selectedDate: selectedDate,
    );
  }

  factory PanchangUIState.fallback(
    PanchangModel panchang,
    DateTime selectedDate,
  ) {
    return PanchangUIState(
      status: PanchangUIStatus.fallback,
      panchang: panchang,
      selectedDate: selectedDate,
    );
  }

  PanchangUIState copyWith({
    PanchangUIStatus? status,
    PanchangModel? panchang,
    String? errorMessage,
    DateTime? selectedDate,
  }) {
    return PanchangUIState(
      status: status ?? this.status,
      panchang: panchang ?? this.panchang,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }

  bool get isLoading => status == PanchangUIStatus.loading;
  bool get isSuccess => status == PanchangUIStatus.success;
  bool get isError => status == PanchangUIStatus.error;
  bool get isFallback => status == PanchangUIStatus.fallback;
  bool get hasData => panchang != null;
}
