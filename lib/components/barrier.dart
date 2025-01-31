import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:radiostations/services/router.dart';
import 'package:radiostations/theme.dart';
import 'package:vector_math/vector_math_64.dart' as math;

class Barrier {
  static double outcomingScaling = 16 / AppTheme.screenWidth;
  static double incomingScaling = 4 * outcomingScaling;

  static Future<void> show(
    BuildContext context, {
    void Function()? onDismiss,
    Duration? transitionDuration,
    Widget Function(BuildContext context, Animation<double> animation, Widget content)? contentBuilder,
    required Widget content,
  }) {
    final Completer<void> completer = Completer();

    showGeneralDialog(
      context: context,
      barrierColor: AppTheme.backgroundColor.withOpacity(0.2),
      transitionDuration: transitionDuration ?? AppTheme.slowAnimationDuration,
      transitionBuilder: (context, animation, secondaryAnimation, page) {
        final CurvedAnimation curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: AppTheme.standardAnimationCurve,
          reverseCurve: AppTheme.standardAnimationCurve.flipped,
        );

        return ValueListenableBuilder(
          valueListenable: curvedAnimation,
          builder: (context, animationValue, child) {
            final double blur = 16 * animationValue;
            final double outcomingTranslation = 0.5 * outcomingScaling * animationValue;
            final double outcomingScale = lerpDouble(1, 1 - outcomingScaling, animationValue)!;

            return BackdropFilter(
              filter: ImageFilter.compose(
                outer: ImageFilter.blur(
                  sigmaX: blur,
                  sigmaY: blur,
                  tileMode: TileMode.mirror,
                ),
                inner: ImageFilter.matrix(
                  Matrix4.compose(
                    math.Vector3(
                      AppTheme.screenWidth * outcomingTranslation,
                      AppTheme.screenHeight * outcomingTranslation,
                      0,
                    ),
                    math.Quaternion.identity(),
                    math.Vector3(outcomingScale, outcomingScale, 1),
                  ).storage,
                ),
              ),
              child: child,
            );
          },
          child: page,
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        final CurvedAnimation curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: AppTheme.standardAnimationCurve,
          reverseCurve: AppTheme.standardAnimationCurve.flipped,
        );

        bool popping = false;

        animation.addStatusListener(
          (status) {
            if (status == AnimationStatus.dismissed) {
              completer.complete();
            }
          },
        );

        return PopScope(
          onPopInvoked: (didPop) {
            if (didPop) {
              onDismiss?.call();
            }
          },
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (popping) return;

                popping = true;
                RouterService().pop();
              },
              child: contentBuilder?.call(context, animation, content) ??
                  ValueListenableBuilder(
                    valueListenable: curvedAnimation,
                    builder: (context, animationValue, child) {
                      final double incomingTranslation = -0.5 * incomingScaling * (1 - animationValue);
                      final double incomingScale = lerpDouble(1 + incomingScaling, 1, animationValue)!;

                      return ImageFiltered(
                        imageFilter: ImageFilter.matrix(
                          Matrix4.compose(
                            math.Vector3(
                              AppTheme.screenWidth * incomingTranslation,
                              AppTheme.screenHeight * incomingTranslation,
                              0,
                            ),
                            math.Quaternion.identity(),
                            math.Vector3(incomingScale, incomingScale, 1),
                          ).storage,
                        ),
                        child: Opacity(
                          opacity: animationValue,
                          child: child,
                        ),
                      );
                    },
                    child: content,
                  ),
            ),
          ),
        );
      },
    );

    return completer.future;
  }
}
