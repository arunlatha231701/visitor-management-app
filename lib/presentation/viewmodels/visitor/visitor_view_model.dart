import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:visitor_management_app/core/errors/app_exception.dart';
import 'package:visitor_management_app/core/providers/providers.dart';
import 'package:visitor_management_app/data/models/visitor/visitor_response_model.dart';
import 'package:visitor_management_app/domain/entities/visitor/visitor_entity.dart';
import 'package:visitor_management_app/presentation/viewmodels/visitor/visitor_state.dart';

class VisitorViewModel extends Notifier<VisitorsFormState> {
  @override
  VisitorsFormState build() => const VisitorsFormState();

  Visitor _toEntity(VisitorModel model) {
    return Visitor(
      id: model.id,
      name: model.name,
      mobile: model.mobile,
      email: model.email,
      visitorsType: model.visitorsType,
      project: model.project,
      purpose: model.purpose,
      status: model.status,
      createdAt: model.createdAt,
      checkInTime: model.checkInTime,
      checkOutTime: model.checkOutTime,
    );
  }

  VisitorModel _toModel(Visitor visitor) {
    return VisitorModel(
      id: visitor.id,
      name: visitor.name,
      mobile: visitor.mobile,
      email: visitor.email,
      visitorsType: visitor.visitorsType,
      project: visitor.project,
      purpose: visitor.purpose,
      status: visitor.status,
      createdAt: visitor.createdAt,
      checkInTime: visitor.checkInTime,
      checkOutTime: visitor.checkOutTime,
    );
  }

  String _friendlyErrorMessage(
      Object error, {
        required String fallback,
      }) {
    if (error is AppException && error.message.trim().isNotEmpty) {
      return error.message;
    }

    return fallback;
  }

  Future<void> loadVisitors() async {
    state = state.copyWith(
      status: VisitorsFormStatus.loading,
      errorMessage: '',
      successMessage: '',
    );

    try {
      final visitors = await ref.read(getVisitorsUseCaseProvider).call();

      state = state.copyWith(
        status: VisitorsFormStatus.success,
        visitors: visitors.map(_toModel).toList(),
        errorMessage: '',
      );
    } catch (error) {
      state = state.copyWith(
        status: VisitorsFormStatus.error,
        errorMessage: _friendlyErrorMessage(
          error,
          fallback: 'Unable to load visitors. Please try again.',
        ),
      );
    }
  }

  Future<void> loadVisitorById(String id) async {
    state = state.copyWith(
      status: VisitorsFormStatus.loading,
      errorMessage: '',
      successMessage: '',
    );

    try {
      final visitor = await findById(id);

      final visitors = [
        for (final item in state.visitors)
          if (item.id != visitor.id) item,
        visitor,
      ];

      state = state.copyWith(
        status: VisitorsFormStatus.success,
        visitors: visitors,
        errorMessage: '',
      );
    } catch (error) {
      state = state.copyWith(
        status: VisitorsFormStatus.error,
        errorMessage: _friendlyErrorMessage(
          error,
          fallback: 'Unable to load visitor details. Please try again.',
        ),
      );
    }
  }

  Future<VisitorModel> findById(String id) async {
    final visitor = await ref.read(getVisitorUseCaseProvider).call(id);
    return _toModel(visitor);
  }

  Future<VisitorModel?> register(VisitorModel visitor) async {
    state = state.copyWith(
      status: VisitorsFormStatus.loading,
      errorMessage: '',
      successMessage: '',
    );

    try {
      final entity = await ref
          .read(createVisitorsUseCaseProvider)
          .call(_toEntity(visitor));

      final createdVisitor = _toModel(entity);

      state = state.copyWith(
        status: VisitorsFormStatus.success,
        visitors: [
          createdVisitor,
          ...state.visitors.where(
                (item) => item.id != createdVisitor.id,
          ),
        ],
        errorMessage: '',
        successMessage: 'Visitor registered successfully.',
      );

      // Refresh the list without losing the newly created visitor
      // if refreshing fails or the list response is not up to date.
      try {
        final entities = await ref.read(getVisitorsUseCaseProvider).call();
        final visitors = entities.map(_toModel).toList();

        if (!visitors.any((item) => item.id == createdVisitor.id)) {
          visitors.insert(0, createdVisitor);
        }

        state = state.copyWith(
          status: VisitorsFormStatus.success,
          visitors: visitors,
          errorMessage: '',
          successMessage: 'Visitor registered successfully.',
        );
      } catch (_) {
        // Registration succeeded, so keep the created visitor.
      }

      return createdVisitor;
    } catch (error) {
      state = state.copyWith(
        status: VisitorsFormStatus.error,
        errorMessage: _friendlyErrorMessage(
          error,
          fallback: 'Unable to register visitor. Please try again.',
        ),
        successMessage: '',
      );

      return null;
    }
  }

  Future<void> edit(String id, VisitorModel visitor) async {
    state = state.copyWith(
      status: VisitorsFormStatus.loading,
      errorMessage: '',
      successMessage: '',
    );

    try {
      final entity = await ref
          .read(updateVisitorUseCaseProvider)
          .call(id, _toEntity(visitor));

      final updatedVisitor = _toModel(entity);
      final visitors = state.visitors
          .map((item) => item.id == id ? updatedVisitor : item)
          .toList();

      if (!visitors.any((item) => item.id == id)) {
        visitors.add(updatedVisitor);
      }

      state = state.copyWith(
        status: VisitorsFormStatus.success,
        visitors: visitors,
        errorMessage: '',
        successMessage: 'Visitor updated successfully.',
      );
    } catch (error) {
      state = state.copyWith(
        status: VisitorsFormStatus.error,
        errorMessage: _friendlyErrorMessage(
          error,
          fallback: 'Unable to update visitor. Please try again.',
        ),
        successMessage: '',
      );
    }
  }

  Future<void> remove(String id) async {
    state = state.copyWith(
      status: VisitorsFormStatus.loading,
      errorMessage: '',
      successMessage: '',
    );

    try {
      await ref.read(deleteVisitorUseCaseProvider).call(id);

      state = state.copyWith(
        status: VisitorsFormStatus.success,
        visitors: state.visitors
            .where((visitor) => visitor.id != id)
            .toList(),
        errorMessage: '',
        successMessage: 'Visitor deleted successfully.',
      );
    } catch (error) {
      state = state.copyWith(
        status: VisitorsFormStatus.error,
        errorMessage: _friendlyErrorMessage(
          error,
          fallback: 'Unable to delete visitor. Please try again.',
        ),
        successMessage: '',
      );
    }
  }

  Future<void> checkIn(VisitorModel visitor) async {
    try {
      final latest = await findById(visitor.id);

      if (latest.status != 'Registered') {
        throw const AppException(
          'Only Registered visitors can check in.',
        );
      }

      await edit(
        latest.id,
        latest.copyWith(
          status: 'Checked In',
          checkInTime: DateTime.now(),
        ),
      );

      if (state.status == VisitorsFormStatus.error) {
        throw AppException(state.errorMessage);
      }
    } catch (error) {
      state = state.copyWith(
        status: VisitorsFormStatus.error,
        errorMessage: _friendlyErrorMessage(
          error,
          fallback: 'Unable to check in visitor. Please try again.',
        ),
        successMessage: '',
      );
    }
  }

  Future<void> checkOut(VisitorModel visitor) async {
    try {
      final latest = await findById(visitor.id);

      if (latest.status != 'Checked In') {
        throw const AppException(
          'Only checked-in visitors can check out.',
        );
      }

      await edit(
        latest.id,
        latest.copyWith(
          status: 'Checked Out',
          checkOutTime: DateTime.now(),
        ),
      );

      if (state.status == VisitorsFormStatus.error) {
        throw AppException(state.errorMessage);
      }
    } catch (error) {
      state = state.copyWith(
        status: VisitorsFormStatus.error,
        errorMessage: _friendlyErrorMessage(
          error,
          fallback: 'Unable to check out visitor. Please try again.',
        ),
        successMessage: '',
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setStatusFilter(String status) {
    state = state.copyWith(statusFilter: status);
  }

  void clearVisitorFilters() {
    state = state.copyWith(
      searchQuery: '',
      statusFilter: 'All',
    );
  }

  void resetState() {
    state = const VisitorsFormState();
  }
}

final visitorsViewModelProvider =
NotifierProvider<VisitorViewModel, VisitorsFormState>(
  VisitorViewModel.new,
);