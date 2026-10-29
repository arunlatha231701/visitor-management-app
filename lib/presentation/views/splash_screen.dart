import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;

  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.82,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.forward();

    _navigationTimer = Timer(
      const Duration(milliseconds: 1900),
          () {
        if (!mounted) return;

        context.go('/');
      },
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF101D30),
              Color(0xFF172B43),
              Color(0xFF0B1727),
            ],
            stops: [0, 0.55, 1],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -110,
              right: -100,
              child: _decorationCircle(
                size: 290,
                color: const Color(0x1855D6C2),
              ),
            ),
            Positioned(
              bottom: -140,
              left: -110,
              child: _decorationCircle(
                size: 320,
                color: const Color(0x126F9DC8),
              ),
            ),
            SafeArea(
              child: Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildLogo(),
                        const SizedBox(height: 32),
                        const Text(
                          'VISITOR',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 5.5,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'MANAGEMENT SYSTEM',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFB9C8D9),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 3.2,
                          ),
                        ),
                        const SizedBox(height: 26),
                        Container(
                          width: 44,
                          height: 2,
                          decoration: BoxDecoration(
                            color: const Color(0xFF55D6C2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'A smarter welcome starts here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFD4DFE9),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 34,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF55D6C2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'SECURE • SIMPLE • EFFICIENT',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.58),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        color: const Color(0xFF203951),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: const Color(0x6655D6C2),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2255D6C2),
            blurRadius: 34,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(
            Icons.badge_outlined,
            color: Colors.white,
            size: 58,
          ),
          Positioned(
            right: 17,
            bottom: 17,
            child: Container(
              width: 31,
              height: 31,
              decoration: BoxDecoration(
                color: const Color(0xFF55D6C2),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: const Color(0xFF203951),
                  width: 3,
                ),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Color(0xFF102338),
                size: 19,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _decorationCircle({
    required double size,
    required Color color,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}