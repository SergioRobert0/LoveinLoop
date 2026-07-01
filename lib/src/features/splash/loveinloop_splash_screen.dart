import 'package:flutter/material.dart';
import 'package:loveinloop/src/app/loveinloop_theme.dart';

class LoveInLoopSplashScreen extends StatefulWidget {
  const LoveInLoopSplashScreen({
    required this.onFinished,
    required this.isReady,
    super.key,
  });

  final VoidCallback onFinished;
  final bool isReady;

  @override
  State<LoveInLoopSplashScreen> createState() => _LoveInLoopSplashScreenState();
}

class _LoveInLoopSplashScreenState extends State<LoveInLoopSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _fadeOut;
  late final Animation<double> _scale;
  var _finishedAnimation = false;
  var _didNavigate = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.42, curve: Curves.easeOut),
    );
    _fadeOut = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.72, 1, curve: Curves.easeInOut),
      ),
    );
    _scale = Tween<double>(begin: 0.88, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.55, curve: Curves.easeOutBack),
      ),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _finishedAnimation = true;
        _tryFinish();
      }
    });
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant LoveInLoopSplashScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _tryFinish();
  }

  void _tryFinish() {
    if (_didNavigate || !_finishedAnimation || !widget.isReady) {
      return;
    }
    _didNavigate = true;
    widget.onFinished();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              LoveInLoopColors.background,
              LoveInLoopColors.surfaceMuted,
              Color(0xffffc2ad),
            ],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: 96,
              right: -28,
              child: _SoftHeart(size: 132, opacity: 0.16),
            ),
            const Positioned(
              left: -20,
              bottom: 118,
              child: _SoftHeart(size: 104, opacity: 0.14),
            ),
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final opacity = _fadeIn.value * _fadeOut.value;
                  return Opacity(
                    opacity: opacity,
                    child: Transform.scale(scale: _scale.value, child: child),
                  );
                },
                child: Container(
                  width: 168,
                  height: 168,
                  padding: const EdgeInsets.all(18),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x33be123c),
                        blurRadius: 32,
                        offset: Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftHeart extends StatelessWidget {
  const _SoftHeart({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Icon(Icons.favorite, size: size, color: LoveInLoopColors.primary),
    );
  }
}
