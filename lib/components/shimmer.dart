import 'dart:math';
import 'package:flutter/material.dart';
import 'package:radiostations/theme.dart';

typedef ShimmerWidget = Widget Function(CurvedAnimation animation);

class Shimmer extends StatefulWidget {
  const Shimmer._internal({
    required this.enabled,
    required this.animate,
    required this.shimmerWidget,
    required this.child,
  });

  final bool enabled, animate;
  final ShimmerWidget shimmerWidget;
  final Widget child;

  factory Shimmer({
    required bool enabled,
    required BorderRadius borderRadius,
    bool animate = true,
    Color? color,
    required Widget child,
  }) {
    return Shimmer._internal(
      enabled: enabled,
      animate: animate,
      shimmerWidget: (CurvedAnimation loadingAnimation) {
        return ClipRRect(
          borderRadius: borderRadius,
          child: ValueListenableBuilder(
            valueListenable: loadingAnimation,
            builder: (context, loadingAnimationValue, child) {
              return Opacity(
                opacity: loadingAnimationValue * 0.25 + 0.5,
                child: child,
              );
            },
            child: ColoredBox(color: color ?? AppTheme.surfaceColor.withOpacity(0.1)),
          ),
        );
      },
      child: child,
    );
  }

  factory Shimmer.lines({
    required Widget child,
    required bool enabled,
    bool animate = true,
    Color? color,
    BorderRadius? borderRadius,
    List<double> linesWidthRatio = const [1],
    double lineHeight = 12,
    Alignment alignment = Alignment.centerLeft,
    EdgeInsets? padding,
  }) {
    assert(linesWidthRatio.isNotEmpty, 'number of lines must be bigger than 0');
    assert(lineHeight >= 0, 'lineHeight must be positive');
    assert(!linesWidthRatio.any((lineWidthRatio) => lineWidthRatio < 0 || lineWidthRatio > 1), 'linesWidthRatio must be between 0 and 1');

    return Shimmer._internal(
      enabled: enabled,
      animate: animate,
      shimmerWidget: (CurvedAnimation loadingAnimation) {
        return Padding(
          padding: padding ?? EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List<Widget>.generate(
              linesWidthRatio.length,
              (index) {
                return SizedBox(
                  height: lineHeight,
                  child: FractionallySizedBox(
                    widthFactor: linesWidthRatio[index],
                    alignment: alignment,
                    child: ClipRRect(
                      borderRadius: borderRadius ?? BorderRadius.circular(lineHeight / 2),
                      child: ValueListenableBuilder(
                        valueListenable: loadingAnimation,
                        builder: (context, loadingAnimationValue, child) {
                          return Opacity(
                            opacity: loadingAnimationValue * 0.25 + 0.5,
                            child: child,
                          );
                        },
                        child: ColoredBox(color: color ?? AppTheme.surfaceColor.withOpacity(0.1)),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
      child: child,
    );
  }

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with TickerProviderStateMixin {
  late final AnimationController loadingAnimationController, loadedAnimationController;
  late final CurvedAnimation loadingAnimation, loadedAnimation;
  late final Widget shimmerWidget;

  Future<void> _onLoaded() async {
    loadingAnimationController.stop();

    if (widget.animate) {
      await loadedAnimationController.forward();
    } else {
      loadedAnimationController.value = 1;
    }
  }

  Future<void> _onUnloaded() async {
    loadingAnimationController.repeat(reverse: true);

    if (widget.animate) {
      await loadedAnimationController.reverse();
    } else {
      loadedAnimationController.value = 0;
    }
  }

  @override
  void initState() {
    super.initState();

    loadingAnimationController = (AnimationController(vsync: this, duration: const Duration(seconds: 1))..value = Random().nextDouble());
    loadedAnimationController = AnimationController(vsync: this, duration: AppTheme.standardAnimationDuration);
    loadingAnimation = CurvedAnimation(parent: loadingAnimationController, curve: Curves.easeInOut);
    loadedAnimation = CurvedAnimation(parent: loadedAnimationController, curve: Curves.easeInOut);

    shimmerWidget = widget.shimmerWidget(loadingAnimation);

    if (!widget.enabled) {
      loadedAnimationController.value = 1;
      _onLoaded();
    }
  }

  @override
  void didUpdateWidget(covariant Shimmer oldWidget) {
    if (widget.enabled) {
      _onUnloaded();
    } else {
      _onLoaded();
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    loadingAnimationController.dispose();
    loadingAnimation.dispose();
    loadedAnimationController.dispose();
    loadedAnimation.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: ValueListenableBuilder(
            valueListenable: loadedAnimation,
            builder: (context, loadedAnimationValue, child) {
              return Visibility(
                visible: loadedAnimationValue < 1,
                maintainState: true,
                maintainAnimation: true,
                maintainSize: true,
                child: Opacity(
                  opacity: 1 - loadedAnimationValue,
                  child: child,
                ),
              );
            },
            child: shimmerWidget,
          ),
        ),
        ValueListenableBuilder(
          valueListenable: loadedAnimation,
          builder: (context, loadedAnimationValue, child) {
            return Opacity(
              opacity: loadedAnimationValue,
              child: child,
            );
          },
          child: widget.child,
        ),
      ],
    );
  }
}
