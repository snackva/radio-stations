import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:radiostations/theme.dart';

class VolumeSlider extends StatefulWidget {
  final double initialValue;
  final void Function(double value) onChange;
  final void Function(double value) onChangeEnd;

  const VolumeSlider({
    super.key,
    required this.initialValue,
    required this.onChange,
    required this.onChangeEnd,
  });

  @override
  State<VolumeSlider> createState() => _VolumeSliderState();
}

class _VolumeSliderState extends State<VolumeSlider> with TickerProviderStateMixin {
  late final ValueNotifier<double> dragValueNotifier;
  final ValueNotifier<bool> pressedDownNotifier = ValueNotifier(false);

  void onDragDown() => pressedDownNotifier.value = true;

  void onDragUpdate({required double dragDistance, required double maxDragDistance}) {
    dragValueNotifier.value = clampDouble(dragValueNotifier.value + dragDistance / maxDragDistance, 0, 1);

    widget.onChange.call(dragValueNotifier.value);
  }

  void onDragUp() {
    pressedDownNotifier.value = false;
    widget.onChangeEnd.call(dragValueNotifier.value);
  }

  double finalPosition(double initialPosition, double initialVelocity, double acceleration, double seconds) {
    return initialPosition + initialVelocity * seconds + 0.5 * acceleration * pow(seconds, 2);
  }

  @override
  void initState() {
    super.initState();

    dragValueNotifier = ValueNotifier(widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant VolumeSlider oldWidget) {
    if (widget.initialValue == dragValueNotifier.value) return;

    final previousDragValue = dragValueNotifier.value;

    final AnimationController controller = AnimationController(
      duration: AppTheme.standardAnimationDuration,
      vsync: this,
    );

    final CurvedAnimation animation = CurvedAnimation(
      parent: controller,
      curve: AppTheme.standardAnimationCurve,
    );

    animation.addListener(() => dragValueNotifier.value = lerpDouble(previousDragValue, widget.initialValue, animation.value) ?? 0);

    controller.forward().then((_) {
      controller.dispose();
      animation.dispose();
    });

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxDragDistance = constraints.maxWidth;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragDown: (details) => onDragDown(),
          onHorizontalDragUpdate: (details) => onDragUpdate(dragDistance: details.primaryDelta ?? 0, maxDragDistance: maxDragDistance),
          onHorizontalDragEnd: (details) => onDragUp(),
          onHorizontalDragCancel: () => onDragUp(),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ValueListenableBuilder(
                valueListenable: pressedDownNotifier,
                builder: (context, pressedDown, child) {
                  return AnimatedContainer(
                    duration: AppTheme.standardAnimationDuration,
                    curve: AppTheme.standardAnimationCurve,
                    decoration: BoxDecoration(
                      border: Border.all(color: pressedDown ? AppTheme.primaryColor : AppTheme.surfaceColor.withOpacity(0.1), width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: child,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ValueListenableBuilder(
                      valueListenable: dragValueNotifier,
                      builder: (context, dragValue, child) {
                        return FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: lerpDouble(28 / (maxDragDistance + 28), 1, dragValue),
                          child: child,
                        );
                      },
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: ValueListenableBuilder(
                  valueListenable: dragValueNotifier,
                  builder: (context, dragValue, child) {
                    final String asset = dragValue > 2 / 3
                        ? 'assets/icons/volume-2.svg'
                        : dragValue > 1 / 3
                            ? 'assets/icons/volume-1.svg'
                            : 'assets/icons/volume.svg';

                    return Padding(
                      padding: EdgeInsets.only(left: lerpDouble(10, 0, dragValue)!),
                      child: SvgPicture.asset(asset),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
