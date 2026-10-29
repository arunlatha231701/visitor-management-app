import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:visitor_management_app/app.dart';
import 'package:visitor_management_app/core/widgets/app_empty_state.dart';
import 'package:visitor_management_app/core/widgets/app_error_state.dart';
import 'package:visitor_management_app/core/widgets/app_loading.dart';
import 'package:visitor_management_app/core/widgets/status_badge.dart';
import 'package:visitor_management_app/core/widgets/theme_toggle_button.dart';
import 'package:visitor_management_app/data/models/visitor/visitor_response_model.dart';
import 'package:visitor_management_app/presentation/viewmodels/visitor/visitor_state.dart';
import 'package:visitor_management_app/presentation/viewmodels/visitor/visitor_view_model.dart';

class VisitorListScreen extends ConsumerStatefulWidget {
  const VisitorListScreen({super.key});

  @override
  ConsumerState<VisitorListScreen> createState() =>
      _VisitorListScreenState();
}

class _VisitorListScreenState extends ConsumerState<VisitorListScreen> {
  final TextEditingController _searchController = TextEditingController();

  String? _deletingVisitorId;

  static const List<String> _statusOptions = [
    'All',
    'Registered',
    'Checked In',
    'Checked Out',
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      ref.read(visitorsViewModelProvider.notifier).loadVisitors();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await ref.read(visitorsViewModelProvider.notifier).loadVisitors();
  }

  List<VisitorModel> _filterVisitors(
      List<VisitorModel> visitors,
      VisitorsFormState state,
      ) {
    final query = state.searchQuery.trim().toLowerCase();

    return visitors.where((visitor) {
      final matchesQuery = query.isEmpty ||
          visitor.name.toLowerCase().contains(query) ||
          visitor.mobile.toLowerCase().contains(query);

      final matchesStatus = state.statusFilter == 'All' ||
          visitor.status == state.statusFilter;

      return matchesQuery && matchesStatus;
    }).toList();
  }

  void _clearFilters() {
    _searchController.clear();

    ref.read(visitorsViewModelProvider.notifier).clearVisitorFilters();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _confirmDelete({
    required String visitorId,
    required String visitorName,
  }) async {
    if (_deletingVisitorId != null) return;

    final colors = Theme.of(context).colorScheme;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: Icon(
            Icons.delete_outline_rounded,
            color: colors.error,
            size: 32,
          ),
          title: const Text('Delete visitor?'),
          content: Text(
            'Are you sure you want to delete $visitorName? '
                'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) return;

    setState(() {
      _deletingVisitorId = visitorId;
    });

    try {
      await ref
          .read(visitorsViewModelProvider.notifier)
          .remove(visitorId);

      if (!mounted) return;

      final state = ref.read(visitorsViewModelProvider);

      if (state.status == VisitorsFormStatus.error) {
        _showMessage(
          state.errorMessage.isNotEmpty
              ? state.errorMessage
              : 'Unable to delete visitor.',
        );
      } else {
        _showMessage('Visitor deleted successfully.');
      }
    } catch (_) {
      if (!mounted) return;

      _showMessage('Unable to delete visitor. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _deletingVisitorId = null;
        });
      }
    }
  }

  void _openVisitor(VisitorModel visitor) {
    final id = visitor.id.trim();

    if (id.isEmpty) {
      _showMessage(
        'This visitor has no ID. Please refresh the visitor list.',
      );
      return;
    }

    context.push('/visitors/$id');
  }

  void _editVisitor(VisitorModel visitor) {
    final id = visitor.id.trim();

    if (id.isEmpty) {
      _showMessage(
        'This visitor has no ID and cannot be edited.',
      );
      return;
    }

    context.push('/visitors/$id/edit');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(visitorsViewModelProvider);
    final colors = Theme.of(context).colorScheme;
    final filteredVisitors = _filterVisitors(state.visitors, state);

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text('Visitors'),
        actions: [
          IconButton(
            tooltip: 'Refresh visitors',
            onPressed: state.status == VisitorsFormStatus.loading
                ? null
                : _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const ThemeToggleButton(),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding =
            constraints.maxWidth >= 900 ? 36.0 : 18.0;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        8,
                        horizontalPadding,
                        12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ListIntro(
                            totalCount: state.visitors.length,
                            onRegister: () =>
                                context.push('/visitors/new'),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              ref
                                  .read(
                                visitorsViewModelProvider.notifier,
                              )
                                  .setSearchQuery(value);
                            },
                            decoration: InputDecoration(
                              hintText: 'Search by name or mobile number',
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                              ),
                              suffixIcon: state.searchQuery.isEmpty
                                  ? null
                                  : IconButton(
                                tooltip: 'Clear search',
                                onPressed: () {
                                  _searchController.clear();

                                  ref
                                      .read(
                                    visitorsViewModelProvider
                                        .notifier,
                                  )
                                      .setSearchQuery('');
                                },
                                icon: const Icon(
                                  Icons.close_rounded,
                                ),
                              ),
                              filled: true,
                              fillColor: colors.surfaceContainerHighest
                                  .withValues(alpha: 0.35),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: colors.outlineVariant,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: AppColors.teal,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _statusOptions.map((status) {
                                final selected =
                                    state.statusFilter == status;

                                return Padding(
                                  padding: const EdgeInsets.only(
                                    right: 8,
                                  ),
                                  child: ChoiceChip(
                                    label: Text(status),
                                    selected: selected,
                                    onSelected: (_) {
                                      ref
                                          .read(
                                        visitorsViewModelProvider
                                            .notifier,
                                      )
                                          .setStatusFilter(status);
                                    },
                                    selectedColor: AppColors.navy,
                                    backgroundColor: colors.surface,
                                    labelStyle: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : colors.onSurfaceVariant,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                    side: BorderSide(
                                      color: selected
                                          ? AppColors.navy
                                          : colors.outlineVariant,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        12,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        color: AppColors.teal,
                        onRefresh: _refresh,
                        child: _buildVisitorContent(
                          state: state,
                          visitors: filteredVisitors,
                          horizontalPadding: horizontalPadding,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildVisitorContent({
    required VisitorsFormState state,
    required List<VisitorModel> visitors,
    required double horizontalPadding,
  }) {
    if (state.status == VisitorsFormStatus.loading &&
        state.visitors.isEmpty) {
      return const AppLoading(
        message: 'Loading visitors...',
      );
    }

    if (state.status == VisitorsFormStatus.error &&
        state.visitors.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 50),
          AppErrorState(
            message: state.errorMessage.isNotEmpty
                ? state.errorMessage
                : 'Unable to load visitors.',
            onRetry: _refresh,
          ),
        ],
      );
    }

    if (visitors.isEmpty) {
      final hasFilters = state.searchQuery.trim().isNotEmpty ||
          state.statusFilter != 'All';

      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 40),
          AppEmptyState(
            icon: hasFilters
                ? Icons.search_off_rounded
                : Icons.people_outline_rounded,
            title: hasFilters
                ? 'No matching visitors'
                : 'No visitors yet',
            message: hasFilters
                ? 'Try a different search term or status filter.'
                : 'Register a visitor to see their details here.',
            actionLabel: hasFilters ? 'Clear filters' : 'Register visitor',
            onAction: hasFilters
                ? _clearFilters
                : () => context.push('/visitors/new'),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        4,
        horizontalPadding,
        24,
      ),
      itemCount: visitors.length,
      itemBuilder: (context, index) {
        final visitor = visitors[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _VisitorCard(
            visitor: visitor,
            isDeleting: _deletingVisitorId == visitor.id,
            onTap: () => _openVisitor(visitor),
            onEdit: () => _editVisitor(visitor),
            onDelete: () => _confirmDelete(
              visitorId: visitor.id,
              visitorName: visitor.name,
            ),
          ),
        );
      },
    );
  }
}

class _ListIntro extends StatelessWidget {
  const _ListIntro({
    required this.totalCount,
    required this.onRegister,
  });

  final int totalCount;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Visitor directory',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '$totalCount '
                    '${totalCount == 1 ? 'visitor' : 'visitors'} registered',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        FilledButton.icon(
          onPressed: onRegister,
          icon: const Icon(
            Icons.add_rounded,
            size: 20,
          ),
          label: const Text('Register'),
        ),
      ],
    );
  }
}

class _VisitorCard extends StatelessWidget {
  const _VisitorCard({
    required this.visitor,
    required this.isDeleting,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final VisitorModel visitor;
  final bool isDeleting;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final name = visitor.name.trim();
    final initials = name.isEmpty ? '?' : name[0].toUpperCase();

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isDeleting ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: colors.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 23,
                    backgroundColor: AppColors.teal.withValues(alpha: 0.1),
                    foregroundColor: AppColors.teal,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
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
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          visitor.mobile,
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
                    child: StatusBadge(
                      status: visitor.status,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Divider(
                height: 1,
                color: colors.outlineVariant,
              ),
              const SizedBox(height: 13),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoPill(
                    icon: Icons.business_outlined,
                    label: visitor.project,
                  ),
                  _InfoPill(
                    icon: Icons.badge_outlined,
                    label: visitor.visitorsType,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: isDeleting ? null : onEdit,
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 17,
                    ),
                    label: const Text('Edit'),
                  ),
                  const SizedBox(width: 4),
                  if (isDeleting)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  else
                    IconButton(
                      tooltip: 'Delete visitor',
                      onPressed: onDelete,
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                      ),
                      color: colors.error,
                    ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}