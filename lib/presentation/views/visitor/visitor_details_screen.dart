import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:visitor_management_app/app.dart';
import 'package:visitor_management_app/core/widgets/app_error_state.dart';
import 'package:visitor_management_app/core/widgets/app_loading.dart';
import 'package:visitor_management_app/core/widgets/theme_toggle_button.dart';
import 'package:visitor_management_app/data/models/visitor/visitor_response_model.dart';
import 'package:visitor_management_app/presentation/viewmodels/visitor/visitor_state.dart';
import 'package:visitor_management_app/presentation/viewmodels/visitor/visitor_view_model.dart';

class VisitorDetailsScreen extends ConsumerStatefulWidget {
  const VisitorDetailsScreen({
    super.key,
    required this.visitorId,
  });

  final String visitorId;

  @override
  ConsumerState<VisitorDetailsScreen> createState() =>
      _VisitorDetailsScreenState();
}

class _VisitorDetailsScreenState
    extends ConsumerState<VisitorDetailsScreen> {
  VisitorModel? _visitor;
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadVisitor();
  }

  Future<void> _loadVisitor() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final visitor = await ref
          .read(visitorsViewModelProvider.notifier)
          .findById(widget.visitorId);

      if (!mounted) return;

      setState(() {
        _visitor = visitor;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _loadError = 'Unable to load visitor details. Please try again.';
      });
    }
  }

  Future<void> _updateStatus({required bool checkIn}) async {
    final visitor = _visitor;

    if (visitor == null || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final viewModel = ref.read(visitorsViewModelProvider.notifier);

      if (checkIn) {
        await viewModel.checkIn(visitor);
      } else {
        await viewModel.checkOut(visitor);
      }

      if (!mounted) return;

      final state = ref.read(visitorsViewModelProvider);

      if (state.status == VisitorsFormStatus.error) {
        _showMessage(
          state.errorMessage.isNotEmpty
              ? state.errorMessage
              : 'Unable to update visitor status.',
          isError: true,
        );
        return;
      }

      await _loadVisitor();

      if (!mounted) return;

      _showMessage(
        checkIn
            ? 'Visitor checked in successfully.'
            : 'Visitor checked out successfully.',
      );
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        'Unable to update visitor status. Please try again.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showMessage(
      String message, {
        bool isError = false,
      }) {
    final colors = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? colors.error : AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not recorded';

    return DateFormat('dd MMM yyyy, hh:mm a').format(date.toLocal());
  }

  String _normalizedStatus(String status) {
    return status.trim().toLowerCase().replaceAll('_', ' ');
  }

  String _displayStatus(String status) {
    final normalized = _normalizedStatus(status);

    if (normalized.isEmpty) return 'Unknown';

    return normalized
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map(
          (word) => '${word[0].toUpperCase()}${word.substring(1)}',
    )
        .join(' ');
  }

  Color _statusColor(String status, ColorScheme colors) {
    switch (_normalizedStatus(status)) {
      case 'checked in':
        return AppColors.success;
      case 'registered':
        return AppColors.warning;
      default:
        return colors.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(visitorsViewModelProvider);

    VisitorModel? currentVisitor;

    for (final visitor in state.visitors) {
      if (visitor.id == widget.visitorId) {
        currentVisitor = visitor;
        break;
      }
    }

    currentVisitor ??= _visitor;

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          'Visitor Details',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to visitors',
          onPressed: () => context.go('/visitors'),
        ),
        actions: [
          const ThemeToggleButton(),
          IconButton(
            tooltip: 'Refresh details',
            onPressed: _isLoading ? null : _loadVisitor,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _buildBody(currentVisitor),
      ),
    );
  }

  Widget _buildBody(VisitorModel? visitor) {
    if (_isLoading) {
      return const AppLoading(
        message: 'Loading visitor details...',
      );
    }

    if (_loadError != null || visitor == null) {
      return AppErrorState(
        message: _loadError ?? 'Visitor not found.',
        onRetry: _loadVisitor,
      );
    }

    final status = _normalizedStatus(visitor.status);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 760;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isWide ? 28 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildVisitorHeader(visitor),
                  const SizedBox(height: 20),
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildInformationCard(visitor),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 2,
                          child: _buildQrCard(visitor),
                        ),
                      ],
                    )
                  else ...[
                    _buildInformationCard(visitor),
                    const SizedBox(height: 16),
                    _buildQrCard(visitor),
                  ],
                  const SizedBox(height: 20),
                  _buildTimelineCard(visitor),
                  const SizedBox(height: 24),
                  _buildActions(
                    visitor,
                    canCheckIn: status == 'registered',
                    canCheckOut: status == 'checked in',
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVisitorHeader(VisitorModel visitor) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final statusColor = _statusColor(visitor.status, colors);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.person_outline_rounded,
              color: colors.primary,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  visitor.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Visitor ID: ${visitor.id}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              _displayStatus(visitor.status),
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationCard(VisitorModel visitor) {
    return _sectionCard(
      title: 'Visitor Information',
      icon: Icons.badge_outlined,
      child: Column(
        children: [
          _infoRow(
            icon: Icons.phone_outlined,
            label: 'Mobile Number',
            value: visitor.mobile,
          ),
          if (visitor.email?.trim().isNotEmpty ?? false)
            _infoRow(
              icon: Icons.email_outlined,
              label: 'Email Address',
              value: visitor.email!,
            ),
          _infoRow(
            icon: Icons.category_outlined,
            label: 'Visitor Type',
            value: visitor.visitorsType,
          ),
          _infoRow(
            icon: Icons.business_outlined,
            label: 'Project',
            value: visitor.project,
          ),
          _infoRow(
            icon: Icons.description_outlined,
            label: 'Purpose of Visit',
            value: visitor.purpose,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildQrCard(VisitorModel visitor) {
    final colors = Theme.of(context).colorScheme;

    return _sectionCard(
      title: 'Visitor QR Code',
      icon: Icons.qr_code_2_rounded,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: QrImageView(
              data: visitor.id,
              version: QrVersions.auto,
              size: 180,
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Scan this code to identify the visitor.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            visitor.id,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(VisitorModel visitor) {
    final colors = Theme.of(context).colorScheme;

    return _sectionCard(
      title: 'Visit Timeline',
      icon: Icons.schedule_rounded,
      child: Column(
        children: [
          _timelineRow(
            icon: Icons.person_add_alt_1_rounded,
            label: 'Registered',
            value: _formatDate(visitor.createdAt),
            color: colors.primary,
          ),
          _timelineRow(
            icon: Icons.login_rounded,
            label: 'Check-in Time',
            value: _formatDate(visitor.checkInTime),
            color: AppColors.success,
          ),
          _timelineRow(
            icon: Icons.logout_rounded,
            label: 'Check-out Time',
            value: _formatDate(visitor.checkOutTime),
            color: colors.onSurfaceVariant,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActions(
      VisitorModel visitor, {
        required bool canCheckIn,
        required bool canCheckOut,
      }) {
    final colors = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        if (canCheckIn)
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: _isProcessing
                  ? null
                  : () => _updateStatus(checkIn: true),
              icon: _isProcessing
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Icon(Icons.login_rounded),
              label: const Text('Check In'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(horizontal: 22),
              ),
            ),
          ),
        if (canCheckOut)
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: _isProcessing
                  ? null
                  : () => _updateStatus(checkIn: false),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Check Out'),
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 22),
              ),
            ),
          ),
        SizedBox(
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _isProcessing
                ? null
                : () => context.push('/visitors/${visitor.id}/edit'),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Visitor'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.primary,
              side: BorderSide(color: colors.outlineVariant),
              padding: const EdgeInsets.symmetric(horizontal: 22),
            ),
          ),
        ),
        SizedBox(
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _isProcessing ? null : _loadVisitor,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.primary,
              side: BorderSide(color: colors.outlineVariant),
              padding: const EdgeInsets.symmetric(horizontal: 22),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colors.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isLast = false,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text(
              value.trim().isEmpty ? '—' : value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isLast = false,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}