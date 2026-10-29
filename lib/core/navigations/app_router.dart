import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:visitor_management_app/presentation/views/splash_screen.dart';
import 'package:visitor_management_app/presentation/views/visitor/dashboard_screen.dart';
import 'package:visitor_management_app/presentation/views/visitor/qr_scanner_screen.dart';
import 'package:visitor_management_app/presentation/views/visitor/visitor_details_screen.dart';
import 'package:visitor_management_app/presentation/views/visitor/visitor_form_screen.dart';
import 'package:visitor_management_app/presentation/views/visitor/visitor_list_screen.dart';
import 'package:visitor_management_app/presentation/widgets/app_bottom_navigation.dart';

CustomTransitionPage<void> _fadeTransition({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 180),
    reverseTransitionDuration: const Duration(milliseconds: 150),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  );
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => _fadeTransition(
          state: state,
          child: const SplashScreen(),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) {
          final selectedIndex = state.uri.path == '/' ? 0 : 1;

          return Scaffold(
            body: child,
            bottomNavigationBar: AppBottomNavigation(
              selectedIndex: selectedIndex,
            ),
          );
        },
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => _fadeTransition(
              state: state,
              child: const DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/visitors',
            pageBuilder: (context, state) => _fadeTransition(
              state: state,
              child: const VisitorListScreen(),
            ),
          ),
          GoRoute(
            path: '/visitors/new',
            pageBuilder: (context, state) => _fadeTransition(
              state: state,
              child: const VisitorFormScreen(),
            ),
          ),
          GoRoute(
            path: '/visitors/:id',
            pageBuilder: (context, state) => _fadeTransition(
              state: state,
              child: VisitorDetailsScreen(
                visitorId: state.pathParameters['id']!,
              ),
            ),
          ),
          GoRoute(
            path: '/visitors/:id/edit',
            pageBuilder: (context, state) => _fadeTransition(
              state: state,
              child: VisitorFormScreen(
                visitorId: state.pathParameters['id']!,
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/scan',
        pageBuilder: (context, state) => _fadeTransition(
          state: state,
          child: const QrScannerScreen(),
        ),
      ),
    ],
  );

  ref.onDispose(router.dispose);

  return router;
});