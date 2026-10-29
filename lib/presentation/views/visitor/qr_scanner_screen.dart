import 'package:app_settings/app_settings.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:visitor_management_app/app.dart';
import 'package:visitor_management_app/core/widgets/theme_toggle_button.dart';
import 'package:visitor_management_app/presentation/viewmodels/visitor/visitor_view_model.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() =>
      _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen>
    with WidgetsBindingObserver {
  late final MobileScannerController _controller;

  bool _isProcessing = false;
  bool _isCameraAvailable = true;
  bool _isPermissionDenied = false;
  bool _isTorchEnabled = false;

  String? _scanMessage;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    if (state == AppLifecycleState.resumed && !_isProcessing) {
      _startCamera();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _stopCamera();
    }
  }

  void _goBack() {
    if (_isProcessing) return;

    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  Future<void> _startCamera() async {
    try {
      await _controller.start();

      if (!mounted) return;

      setState(() {
        _isCameraAvailable = true;
        _isPermissionDenied = false;
        _scanMessage = null;
      });
    } on MobileScannerException catch (error) {
      if (!mounted) return;

      final permissionDenied =
          error.errorCode == MobileScannerErrorCode.permissionDenied;

      setState(() {
        _isCameraAvailable = false;
        _isPermissionDenied = permissionDenied;
        _scanMessage = permissionDenied
            ? 'Camera permission is required to scan visitor QR codes.'
            : 'Camera could not start. Please try again.';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isCameraAvailable = false;
        _isPermissionDenied = false;
        _scanMessage = 'Camera could not start. Please try again.';
      });
    }
  }

  Future<void> _openAppSettings() async {
    try {
      await AppSettings.openAppSettings();
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        'Unable to open settings. Please open your device settings manually.',
        isError: true,
      );
    }
  }

  Future<void> _stopCamera() async {
    try {
      await _controller.stop();
    } catch (_) {
      // The camera may already be stopped.
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || !_isCameraAvailable) return;

    String? scannedValue;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();

      if (value != null && value.isNotEmpty) {
        scannedValue = value;
        break;
      }
    }

    if (scannedValue == null) {
      _setScanMessage('No readable QR code detected. Try again.');
      return;
    }

    // Visitor QR codes contain the visitor ID.
    if (!RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(scannedValue)) {
      const message =
          'Invalid QR code. Please scan a valid visitor QR code.';

      _setScanMessage(message);
      _showMessage(message, isError: true);
      return;
    }

    setState(() {
      _isProcessing = true;
      _scanMessage = 'Validating visitor...';
    });

    await _stopCamera();

    if (!mounted) return;

    try {
      final visitor = await ref
          .read(visitorsViewModelProvider.notifier)
          .findById(scannedValue);

      if (!mounted) return;

      setState(() {
        _scanMessage = 'Visitor found. Opening details...';
      });

      await Future<void>.delayed(
        const Duration(milliseconds: 250),
      );

      if (!mounted) return;

      await context.push('/visitors/${visitor.id}');

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
        _scanMessage = null;
      });

      await _startCamera();
    } on DioException catch (error) {
      if (!mounted) return;

      final statusCode = error.response?.statusCode;
      final isNetworkFailure = _isNetworkError(error);
      final message = _getScanErrorMessage(
        statusCode: statusCode,
        isNetworkFailure: isNetworkFailure,
      );

      await _handleScanFailure(message);
    } catch (error) {
      if (!mounted) return;

      final errorText = error.toString().toLowerCase();

      final isNotFound = errorText.contains('404') ||
          errorText.contains('not found') ||
          errorText.contains('does not exist');

      final isNetworkFailure = errorText.contains('socket') ||
          errorText.contains('network') ||
          errorText.contains('connection') ||
          errorText.contains('timed out') ||
          errorText.contains('timeout');

      final message = _getScanErrorMessage(
        isNotFound: isNotFound,
        isNetworkFailure: isNetworkFailure,
      );

      await _handleScanFailure(message);
    }
  }

  bool _isNetworkError(DioException error) {
    return error.response == null ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError;
  }

  String _getScanErrorMessage({
    int? statusCode,
    bool isNotFound = false,
    bool isNetworkFailure = false,
  }) {
    if (statusCode == 404 || isNotFound) {
      return 'Visitor not found. Please check the QR code.';
    }

    if (isNetworkFailure) {
      return 'Unable to connect. Check your internet connection and try again.';
    }

    return 'Unable to validate this visitor. Please try again.';
  }

  Future<void> _handleScanFailure(String message) async {
    if (!mounted) return;

    setState(() {
      _isProcessing = false;
      _scanMessage = message;
    });

    _showMessage(message, isError: true);
    await _startCamera();
  }

  void _setScanMessage(String message) {
    if (!mounted) return;

    setState(() {
      _scanMessage = message;
    });
  }

  void _showMessage(
      String message, {
        bool isError = false,
      }) {
    if (!mounted) return;

    final scheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? scheme.error : AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _toggleTorch() async {
    if (_isProcessing || !_isCameraAvailable) return;

    try {
      await _controller.toggleTorch();

      if (!mounted) return;

      setState(() {
        _isTorchEnabled = !_isTorchEnabled;
      });
    } catch (_) {
      _showMessage(
        'The flashlight is not available on this device.',
        isError: true,
      );
    }
  }

  Future<void> _switchCamera() async {
    if (_isProcessing || !_isCameraAvailable) return;

    try {
      await _controller.switchCamera();
    } catch (_) {
      _showMessage(
        'Unable to switch cameras on this device.',
        isError: true,
      );
    }
  }

  Future<void> _retryCamera() async {
    setState(() {
      _isCameraAvailable = true;
      _isPermissionDenied = false;
      _scanMessage = 'Starting camera...';
    });

    await _startCamera();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Go back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _goBack,
        ),
        title: const Text(
          'Scan Visitor QR',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          const ThemeToggleButton(),
          IconButton(
            tooltip: 'Switch camera',
            onPressed:
            _isProcessing || !_isCameraAvailable ? null : _switchCamera,
            icon: const Icon(Icons.cameraswitch_rounded),
          ),
          IconButton(
            tooltip: _isTorchEnabled
                ? 'Turn flashlight off'
                : 'Turn flashlight on',
            onPressed:
            _isProcessing || !_isCameraAvailable ? null : _toggleTorch,
            icon: Icon(
              _isTorchEnabled
                  ? Icons.flashlight_off_rounded
                  : Icons.flashlight_on_rounded,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 760;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isWide ? 28 : 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildIntro(),
                      const SizedBox(height: 24),
                      _buildScannerPreview(
                        height: isWide ? 420 : 340,
                      ),
                      const SizedBox(height: 20),
                      _buildStatus(),
                      const SizedBox(height: 24),
                      _buildInstructions(),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _isProcessing ? null : _goBack,
                          icon: const Icon(Icons.dashboard_outlined),
                          label: const Text('Back to Dashboard'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: scheme.primary,
                            side: BorderSide(
                              color: scheme.outlineVariant,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildIntro() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.qr_code_scanner_rounded,
            size: 34,
            color: scheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Identify a Visitor',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Position the visitor QR code inside the frame to retrieve their details.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildScannerPreview({required double height}) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_isCameraAvailable)
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error) => _buildCameraError(error),
            )
          else
            _buildCameraUnavailable(),
          IgnorePointer(
            child: Center(
              child: SizedBox(
                width: height * 0.62,
                height: height * 0.62,
                child: Stack(
                  children: [
                    _corner(
                      top: 0,
                      left: 0,
                      borderTop: true,
                      borderLeft: true,
                    ),
                    _corner(
                      top: 0,
                      right: 0,
                      borderTop: true,
                      borderRight: true,
                    ),
                    _corner(
                      bottom: 0,
                      left: 0,
                      borderBottom: true,
                      borderLeft: true,
                    ),
                    _corner(
                      bottom: 0,
                      right: 0,
                      borderBottom: true,
                      borderRight: true,
                    ),
                    Center(
                      child: Container(
                        width: 190,
                        height: 2,
                        decoration: BoxDecoration(
                          color: AppColors.teal,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.teal.withValues(alpha: 0.55),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.60),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _isProcessing
                          ? AppColors.warning
                          : AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isProcessing ? 'Processing' : 'Camera ready',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _corner({
    double? top,
    double? bottom,
    double? left,
    double? right,
    bool borderTop = false,
    bool borderBottom = false,
    bool borderLeft = false,
    bool borderRight = false,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          border: Border(
            top: borderTop
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
            bottom: borderBottom
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
            left: borderLeft
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
            right: borderRight
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildStatus() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final message = _scanMessage ??
        (_isProcessing
            ? 'Validating visitor...'
            : 'Camera is ready. Scan a visitor QR code.');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          if (_isProcessing)
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: scheme.primary,
              ),
            )
          else
            Icon(
              Icons.info_outline_rounded,
              color: scheme.primary,
              size: 23,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scanning tips',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          _tip(
            Icons.center_focus_strong_rounded,
            'Keep the QR code inside the frame.',
          ),
          const SizedBox(height: 12),
          _tip(
            Icons.light_mode_outlined,
            'Ensure sufficient lighting for a clear scan.',
          ),
          const SizedBox(height: 12),
          _tip(
            Icons.verified_user_outlined,
            'Visitor details open only after validation.',
          ),
        ],
      ),
    );
  }

  Widget _tip(IconData icon, String text) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: scheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              height: 1.4,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCameraError(MobileScannerException error) {
    final permissionDenied =
        error.errorCode == MobileScannerErrorCode.permissionDenied;

    return _buildCameraErrorPanel(
      permissionDenied: permissionDenied,
      message: permissionDenied
          ? 'Camera permission is required to scan visitor QR codes. Allow access in your device settings, then try again.'
          : 'The camera could not start. Check your device camera and try again.',
    );
  }

  Widget _buildCameraErrorPanel({
    required bool permissionDenied,
    required String message,
  }) {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              permissionDenied
                  ? Icons.no_photography_outlined
                  : Icons.videocam_off_rounded,
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              permissionDenied
                  ? 'Camera permission needed'
                  : 'Camera unavailable',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            if (permissionDenied) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _openAppSettings,
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('Open Settings'),
                ),
              ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _retryCamera,
                child: const Text('Try Again'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraUnavailable() {
    return _buildCameraErrorPanel(
      permissionDenied: _isPermissionDenied,
      message: _isPermissionDenied
          ? 'Camera permission is required to scan visitor QR codes. Allow access in your device settings, then try again.'
          : 'The camera is unavailable. Please check your device camera and try again.',
    );
  }
}