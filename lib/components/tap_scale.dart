import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class TapScale extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const TapScale({
    super.key,
    required this.onTap,
    required this.child,
  });

  static double scale(double longestSide) => 1 - min(0.1, 10 / longestSide);

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final CurvedAnimation _curvedAnimation;
  final GlobalKey _key = GlobalKey();

  TickerFuture _tickerFuture = TickerFuture.complete();
  double _scale = 0.9;

  void onTapStart() {
    _animationController.stop();
    _tickerFuture = _animationController.forward();
  }

  void onTapEnd() {
    if (_animationController.isAnimating) {
      _tickerFuture.whenComplete(() => _tickerFuture = _animationController.reverse());
    } else {
      _tickerFuture = _animationController.reverse();
    }
  }

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _curvedAnimation = CurvedAnimation(parent: _animationController, curve: Curves.fastOutSlowIn);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _curvedAnimation.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? renderBox = _key.currentContext?.findRenderObject() as RenderBox?;

      if (renderBox == null) return;

      _scale = TapScale.scale(renderBox.size.longestSide);
    });

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        onTapStart();
      },
      onTapUp: (_) {
        onTapEnd();
        widget.onTap();
      },
      onTapCancel: () {
        onTapEnd();
      },
      child: AnimatedBuilder(
        animation: _curvedAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: lerpDouble(1, _scale, _curvedAnimation.value),
            child: child,
          );
        },
        child: SizedBox(
          key: _key,
          child: widget.child,
        ),
      ),
    );
  }
}
