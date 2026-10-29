import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visitor_management_app/core/network/api_service.dart';
import 'package:visitor_management_app/data/datasources/visitor/visitor_remote_data_source.dart';
import 'package:visitor_management_app/data/repositories_impl/visitor/visitor_repository_impl.dart';
import 'package:visitor_management_app/domain/repositories/visitor/visitor_repository.dart';
import 'package:visitor_management_app/domain/usecases/visitor/create_visitor_use_case.dart';
import 'package:visitor_management_app/domain/usecases/visitor/delete_visitor_use_case.dart';
import 'package:visitor_management_app/domain/usecases/visitor/get_visitor_use_case.dart';
import 'package:visitor_management_app/domain/usecases/visitor/get_visitors_use_case.dart';
import 'package:visitor_management_app/domain/usecases/visitor/update_visitor_use_case.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final visitorRemoteDataSourceProvider =
Provider<VisitorRemoteDataSource>(
      (ref) => VisitorRemoteDataSourceImpl(
    ref.watch(apiServiceProvider),
  ),
);

final visitorRepositoryProvider = Provider<VisitorRepository>(
      (ref) => VisitorRepositoryImpl(
    ref.watch(visitorRemoteDataSourceProvider),
  ),
);

final createVisitorsUseCaseProvider = Provider<CreateVisitorUseCase>(
  (ref) => CreateVisitorUseCase(ref.read(visitorRepositoryProvider)),
);

final getVisitorsUseCaseProvider = Provider<GetVisitorsUseCase>(
  (ref) => GetVisitorsUseCase(ref.read(visitorRepositoryProvider)),
);

final getVisitorUseCaseProvider = Provider<GetVisitorUseCase>(
  (ref) => GetVisitorUseCase(ref.read(visitorRepositoryProvider)),
);

final updateVisitorUseCaseProvider = Provider<UpdateVisitorUseCase>(
  (ref) => UpdateVisitorUseCase(ref.read(visitorRepositoryProvider)),
);

final deleteVisitorUseCaseProvider = Provider<DeleteVisitorUseCase>(
  (ref) => DeleteVisitorUseCase(ref.read(visitorRepositoryProvider)),
);




class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }
}

final themeModeProvider =
NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
