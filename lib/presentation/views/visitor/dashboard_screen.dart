import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:visitor_management_app/app.dart';
import 'package:visitor_management_app/core/widgets/app_empty_state.dart';
import 'package:visitor_management_app/core/widgets/app_error_state.dart';
import 'package:visitor_management_app/core/widgets/app_loading.dart';
import 'package:visitor_management_app/core/widgets/status_badge.dart';
import 'package:visitor_management_app/core/widgets/theme_toggle_button.dart';
import 'package:visitor_management_app/data/models/visitor/visitor_response_model.dart';
import 'package:visitor_management_app/presentation/viewmodels/visitor/visitor_state.dart';
import 'package:visitor_management_app/presentation/viewmodels/visitor/visitor_view_model.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (mounted) {
        ref.read(visitorsViewModelProvider.notifier).loadVisitors();
      }
    });
  }

  Future<void> _refresh() async {
    await ref.read(visitorsViewModelProvider.notifier).loadVisitors();
  }

  bool _isSameDay(DateTime? date, DateTime today) {
    if (date == null) return false;

    final localDate = date.toLocal();

    return localDate.year == today.year &&
        localDate.month == today.month &&
        localDate.day == today.day;
  }

  void _openVisitor(VisitorModel visitor) {
    final id = visitor.id.trim();

    if (id.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Visitor ID is missing. Please refresh the dashboard.',
            ),
          ),
        );
      return;
    }

    context.push('/visitors/$id');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(visitorsViewModelProvider);
    final visitors = state.visitors;
    final today = DateTime.now();
    final colors = Theme.of(context).colorScheme;

    final totalToday = visitors
        .where((visitor) => _isSameDay(visitor.createdAt, today))
        .length;

    final checkedIn = visitors
        .where((visitor) => visitor.status == 'Checked In')
        .length;

    final checkedOutToday = visitors
        .where((visitor) => _isSameDay(visitor.checkOutTime, today))
        .length;

    final isInitialLoading =
        state.status == VisitorsFormStatus.loading && visitors.isEmpty;

    final hasInitialError =
        state.status == VisitorsFormStatus.error && visitors.isEmpty;

    final recentVisitors = [...visitors]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.teal,
          onRefresh: _refresh,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth >= 900
                  ? 36.0
                  : constraints.maxWidth >= 600
                  ? 28.0
                  : 18.0;

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  20,
                  horizontalPadding,
                  28,
                ),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DashboardHeader(onRefresh: _refresh),
                          const SizedBox(height: 28),

                          Text(
                            DateFormat('EEEE, d MMMM yyyy').format(today),
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 5),

                          Text(
                            'Visitor overview',
                            style: TextStyle(
                              color: colors.onSurface,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),

                          Text(
                            'A quick look at today’s visitor activity.',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 22),

                          LayoutBuilder(
                            builder: (context, constraints) {
                              final columns =
                              constraints.maxWidth >= 650 ? 3 : 2;
                              const gap = 12.0;

                              final cardWidth =
                                  (constraints.maxWidth -
                                      gap * (columns - 1)) /
                                      columns;

                              final stats = [
                                _StatCard(
                                  title: 'Visitors today',
                                  value: totalToday,
                                  icon: Icons.groups_outlined,
                                  color: AppColors.teal,
                                ),
                                _StatCard(
                                  title: 'Currently inside',
                                  value: checkedIn,
                                  icon: Icons.meeting_room_outlined,
                                  color: AppColors.success,
                                ),
                                _StatCard(
                                  title: 'Checked out today',
                                  value: checkedOutToday,
                                  icon: Icons.task_alt_rounded,
                                  color: AppColors.navy,
                                ),
                              ];

                              return Wrap(
                                spacing: gap,
                                runSpacing: gap,
                                children: stats
                                    .map(
                                      (stat) => SizedBox(
                                    width: cardWidth,
                                    child: stat,
                                  ),
                                )
                                    .toList(),
                              );
                            },
                          ),
                          const SizedBox(height: 28),

                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Quick actions',
                                  style: TextStyle(
                                    color: colors.onSurface,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          LayoutBuilder(
                            builder: (context, constraints) {
                              final actions = [
                                _QuickAction(
                                  icon: Icons.person_add_alt_1_rounded,
                                  label: 'Register',
                                  onTap: () =>
                                      context.push('/visitors/new'),
                                ),
                                _QuickAction(
                                  icon: Icons.qr_code_scanner_rounded,
                                  label: 'Scan QR',
                                  onTap: () => context.push('/scan'),
                                ),
                                _QuickAction(
                                  icon: Icons.people_outline_rounded,
                                  label: 'Directory',
                                  onTap: () => context.go('/visitors'),
                                ),
                              ];

                              if (constraints.maxWidth < 380) {
                                return Column(
                                  children: [
                                    for (final action in actions)
                                      Padding(
                                        padding:
                                        const EdgeInsets.only(bottom: 8),
                                        child: action,
                                      ),
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  for (var i = 0; i < actions.length; i++) ...[
                                    if (i > 0) const SizedBox(width: 10),
                                    Expanded(child: actions[i]),
                                  ],
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 30),

                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Recent visitors',
                                  style: TextStyle(
                                    color: colors.onSurface,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.go('/visitors'),
                                child: const Text('View all'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          if (isInitialLoading)
                            const AppLoading(
                              message: 'Loading visitors...',
                            )
                          else if (hasInitialError)
                            AppErrorState(
                              message: state.errorMessage.isNotEmpty
                                  ? state.errorMessage
                                  : 'Unable to load visitors.',
                              onRetry: _refresh,
                            )
                          else if (visitors.isEmpty)
                              AppEmptyState(
                                icon: Icons.people_outline_rounded,
                                title: 'No visitors yet',
                                message:
                                'Register your first visitor to see recent activity.',
                                actionLabel: 'Register visitor',
                                onAction: () =>
                                    context.push('/visitors/new'),
                              )
                            else
                              ...recentVisitors.take(4).map(
                                    (visitor) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _RecentVisitorTile(
                                    visitor: visitor,
                                    onTap: () => _openVisitor(visitor),
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.apartment_rounded,
            color: Colors.white,
            size: 23,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VISITOR MANAGEMENT',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Dashboard',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const ThemeToggleButton(),
        IconButton(
          tooltip: 'Refresh',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      child: Container(
        constraints: const BoxConstraints(minHeight: 112),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const Spacer(),
                Text(
                  value.toString(),
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 66),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: colors.outlineVariant),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: AppColors.teal,
                size: 21,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentVisitorTile extends StatelessWidget {
  const _RecentVisitorTile({
    required this.visitor,
    required this.onTap,
  });

  final VisitorModel visitor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final name = visitor.name.trim();
    final initials = name.isEmpty ? '?' : name[0].toUpperCase();

    return Card(
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: colors.outlineVariant),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.teal.withValues(alpha: 0.1),
                foregroundColor: AppColors.teal,
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visitor.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${visitor.visitorsType} · ${visitor.mobile}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: StatusBadge(status: visitor.status),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}