import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:visitor_management_app/app.dart';
import 'package:visitor_management_app/core/widgets/app_error_state.dart';
import 'package:visitor_management_app/core/widgets/app_loading.dart';
import 'package:visitor_management_app/data/models/visitor/visitor_response_model.dart';
import 'package:visitor_management_app/presentation/viewmodels/visitor/visitor_state.dart';
import 'package:visitor_management_app/presentation/viewmodels/visitor/visitor_view_model.dart';

class VisitorFormScreen extends ConsumerStatefulWidget {
  const VisitorFormScreen({super.key, this.visitorId});

  final String? visitorId;

  @override
  ConsumerState<VisitorFormScreen> createState() =>
      _VisitorFormScreenState();
}

class _VisitorFormScreenState extends ConsumerState<VisitorFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _purposeController = TextEditingController();

  static const List<String> _visitorTypes = [
    'Customer',
    'Vendor',
    'Other',
  ];

  static const List<String> _projects = [
    'Project A',
    'Project B',
    'Project C',
  ];

  String _visitorType = 'Customer';
  String _project = 'Project A';

  VisitorModel? _oldVisitor;

  bool _loading = false;
  bool _submitting = false;
  bool _loadFailed = false;

  String _formError = '';

  bool get _isEditing => widget.visitorId != null;

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      _loadVisitor();
    }
  }

  Future<void> _loadVisitor() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
      _formError = '';
    });

    try {
      final visitor = await ref
          .read(visitorsViewModelProvider.notifier)
          .findById(widget.visitorId!);

      if (!mounted) return;

      _oldVisitor = visitor;

      _nameController.text = visitor.name;
      _mobileController.text = visitor.mobile;
      _emailController.text = visitor.email ?? '';
      _purposeController.text = visitor.purpose;

      if (_visitorTypes.contains(visitor.visitorsType)) {
        _visitorType = visitor.visitorsType;
      }

      if (_projects.contains(visitor.project)) {
        _project = visitor.project;
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadFailed = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _purposeController.dispose();

    super.dispose();
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }

    return null;
  }

  String? _mobileValidator(String? value) {
    final mobile = value?.trim() ?? '';

    if (mobile.isEmpty) {
      return 'Mobile number is required';
    }

    if (!RegExp(r'^[0-9]{10}$').hasMatch(mobile)) {
      return 'Enter exactly 10 digits';
    }

    return null;
  }

  String? _emailValidator(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return null;
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (_submitting) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _submitting = true;
      _formError = '';
    });

    try {
      if (_isEditing && _oldVisitor == null) {
        _oldVisitor = await ref
            .read(visitorsViewModelProvider.notifier)
            .findById(widget.visitorId!);
      }

      if (!mounted) return;

      final existing = _oldVisitor;

      final visitor = VisitorModel(
        id: existing?.id ?? '',
        name: _nameController.text.trim(),
        mobile: _mobileController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        visitorsType: _visitorType,
        project: _project,
        purpose: _purposeController.text.trim(),
        status: existing?.status ?? 'Registered',
        createdAt: existing?.createdAt ?? DateTime.now(),
        checkInTime: existing?.checkInTime,
        checkOutTime: existing?.checkOutTime,
      );

      final notifier = ref.read(visitorsViewModelProvider.notifier);

      if (_isEditing) {
        await notifier.edit(widget.visitorId!, visitor);

        if (!mounted) return;

        final latestState = ref.read(visitorsViewModelProvider);

        if (latestState.status == VisitorsFormStatus.error) {
          setState(() {
            _formError = latestState.errorMessage.isNotEmpty
                ? latestState.errorMessage
                : 'Unable to update visitor. Please try again.';
          });

          return;
        }

        _showMessage('Visitor updated successfully.');
        context.pop();
        return;
      }

      final createdVisitor = await notifier.register(visitor);

      if (!mounted) return;

      if (createdVisitor == null) {
        final latestState = ref.read(visitorsViewModelProvider);

        setState(() {
          _formError = latestState.errorMessage.isNotEmpty
              ? latestState.errorMessage
              : 'Unable to register visitor. Please try again.';
        });

        return;
      }

      if (createdVisitor.id.trim().isEmpty) {
        setState(() {
          _formError =
          'Visitor was created, but the visitor ID is missing.';
        });

        return;
      }

      _showMessage('Visitor registered successfully.');
      context.go('/visitors/${createdVisitor.id}');
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _formError = 'Unable to save visitor. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final availableTypes = <String>{
      ..._visitorTypes,
      if (_visitorType.trim().isNotEmpty) _visitorType,
    }.toList();

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit visitor' : 'Register visitor',
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const AppLoading(
          message: 'Loading visitor details...',
        )
            : _loadFailed
            ? AppErrorState(
          message:
          'Unable to load visitor details. Check your connection and try again.',
          onRetry: _loadVisitor,
        )
            : LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding =
            constraints.maxWidth >= 800 ? 36.0 : 18.0;

            return Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  12,
                  horizontalPadding,
                  28,
                ),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 760,
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          _FormHero(isEditing: _isEditing),
                          const SizedBox(height: 26),

                          const _SectionHeading(
                            title: 'Personal information',
                            subtitle:
                            'Enter the visitor’s contact details.',
                          ),
                          const SizedBox(height: 16),

                          _PremiumTextField(
                            controller: _nameController,
                            label: 'Full name',
                            hint: 'Enter visitor name',
                            icon: Icons.person_outline_rounded,
                            validator: _requiredValidator,
                            capitalization:
                            TextCapitalization.words,
                            textInputAction:
                            TextInputAction.next,
                          ),
                          const SizedBox(height: 16),

                          _PremiumTextField(
                            controller: _mobileController,
                            label: 'Mobile number',
                            hint: 'Enter 10-digit mobile number',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter
                                  .digitsOnly,
                              LengthLimitingTextInputFormatter(
                                10,
                              ),
                            ],
                            validator: _mobileValidator,
                            textInputAction:
                            TextInputAction.next,
                          ),
                          const SizedBox(height: 16),

                          _PremiumTextField(
                            controller: _emailController,
                            label: 'Email address (optional)',
                            hint: 'name@example.com',
                            icon: Icons.mail_outline_rounded,
                            keyboardType:
                            TextInputType.emailAddress,
                            validator: _emailValidator,
                            textInputAction:
                            TextInputAction.next,
                          ),
                          const SizedBox(height: 28),

                          const _SectionHeading(
                            title: 'Visit information',
                            subtitle:
                            'Select the visit category and project.',
                          ),
                          const SizedBox(height: 16),

                          _PremiumDropdown(
                            label: 'Visitor type',
                            icon: Icons.badge_outlined,
                            value: _visitorType,
                            items: availableTypes,
                            onChanged: (value) {
                              if (value == null) return;

                              setState(() {
                                _visitorType = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          _PremiumDropdown(
                            label: 'Project',
                            icon: Icons.business_outlined,
                            value: _project,
                            items: _projects,
                            onChanged: (value) {
                              if (value == null) return;

                              setState(() {
                                _project = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          _PremiumTextField(
                            controller: _purposeController,
                            label: 'Purpose of visit',
                            hint:
                            'Briefly explain the reason for the visit',
                            icon: Icons.notes_rounded,
                            validator: _requiredValidator,
                            capitalization:
                            TextCapitalization.sentences,
                            minLines: 3,
                            maxLines: 5,
                            textInputAction:
                            TextInputAction.newline,
                          ),

                          if (_formError.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _InlineError(message: _formError),
                          ],

                          const SizedBox(height: 26),

                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton.icon(
                              onPressed:
                              _submitting ? null : _save,
                              icon: _submitting
                                  ? const SizedBox(
                                height: 19,
                                width: 19,
                                child:
                                CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                                  : Icon(
                                _isEditing
                                    ? Icons.save_outlined
                                    : Icons
                                    .person_add_alt_1_rounded,
                              ),
                              label: Text(
                                _submitting
                                    ? 'Please wait...'
                                    : _isEditing
                                    ? 'Save changes'
                                    : 'Register visitor',
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton(
                              onPressed: _submitting
                                  ? null
                                  : () => context.pop(),
                              child: const Text('Cancel'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FormHero extends StatelessWidget {
  const _FormHero({required this.isEditing});

  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.navy,
            AppColors.navyLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              isEditing
                  ? Icons.edit_note_rounded
                  : Icons.person_add_alt_1_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing
                      ? 'Update visitor details'
                      : 'New visitor registration',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isEditing
                      ? 'Keep the visitor record accurate and up to date.'
                      : 'Complete the details below to create a visitor record.',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.45,
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

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _PremiumTextField extends StatelessWidget {
  const _PremiumTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.capitalization = TextCapitalization.none,
    this.inputFormatters,
    this.minLines = 1,
    this.maxLines = 1,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextCapitalization capitalization;
  final List<TextInputFormatter>? inputFormatters;
  final int minLines;
  final int maxLines;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textCapitalization: capitalization,
      inputFormatters: inputFormatters,
      minLines: minLines,
      maxLines: maxLines,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Padding(
          padding: EdgeInsets.only(
            bottom: maxLines > 1 ? 42 : 0,
          ),
          child: Icon(icon),
        ),
        alignLabelWithHint: maxLines > 1,
        filled: true,
        fillColor: colors.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: colors.outlineVariant,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: AppColors.teal,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: colors.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: colors.error,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class _PremiumDropdown extends StatelessWidget {
  const _PremiumDropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: colors.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: colors.outlineVariant,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: AppColors.teal,
            width: 1.5,
          ),
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: colors.error.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: colors.onErrorContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: colors.onErrorContainer,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}