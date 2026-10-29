import 'package:visitor_management_app/data/models/visitor/visitor_response_model.dart';

enum VisitorsFormStatus {
  initial,
  loading,
  success,
  error,
}

class VisitorsFormState {
  const VisitorsFormState({
    this.status = VisitorsFormStatus.initial,
    this.visitors = const [],
    this.errorMessage = '',
    this.successMessage = '',
    this.searchQuery = '',
    this.statusFilter = 'All',
  });

  final VisitorsFormStatus status;
  final List<VisitorModel> visitors;
  final String errorMessage;
  final String successMessage;
  final String searchQuery;
  final String statusFilter;

  VisitorsFormState copyWith({
    VisitorsFormStatus? status,
    List<VisitorModel>? visitors,
    String? errorMessage,
    String? successMessage,
    String? searchQuery,
    String? statusFilter,
  }) {
    return VisitorsFormState(
      status: status ?? this.status,
      visitors: visitors ?? this.visitors,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}