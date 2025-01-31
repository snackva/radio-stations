import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:radiostations/components/barrier.dart';
import 'package:radiostations/services/router.dart';
import 'package:radiostations/theme.dart';

class SearchButton extends StatefulWidget {
  final TextEditingController? textEditingController;
  final FocusNode? focusNode;
  final String? hint;

  const SearchButton({
    super.key,
    this.textEditingController,
    this.focusNode,
    this.hint,
  });

  @override
  State<SearchButton> createState() => _SearchButtonState();
}

class _SearchButtonState extends State<SearchButton> {
  final GlobalKey key = GlobalKey();
  final ValueNotifier<bool> barrierVisibleNotifier = ValueNotifier(false);
  late final FocusNode focusNode;

  final Size buttonSize = const Size.square(48), expandedSize = Size(AppTheme.screenWidth - 32, 48);

  @override
  void initState() {
    focusNode = widget.focusNode ?? FocusNode();

    focusNode.addListener(() {
      if (!focusNode.hasFocus && barrierVisibleNotifier.value) RouterService().pop();
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Widget textField = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(buttonSize.height / 2),
        border: Border.all(
          color: AppTheme.primaryColor,
          strokeAlign: BorderSide.strokeAlignOutside,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: buttonSize.width,
            child: SvgPicture.asset('assets/icons/search.svg'),
          ),
          Expanded(
            child: TextFormField(
              controller: widget.textEditingController,
              focusNode: focusNode,
              keyboardAppearance: Brightness.dark,
              maxLines: 1,
              style: AppTheme.subtitleStyle,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: widget.hint,
                hintStyle: AppTheme.subtitleStyle.copyWith(color: AppTheme.surfaceColor.withOpacity(0.5)),
                counterText: '',
                isCollapsed: true,
                contentPadding: const EdgeInsets.only(right: 16),
              ),
            ),
          )
        ],
      ),
    );

    return Center(
      child: ValueListenableBuilder(
        valueListenable: barrierVisibleNotifier,
        builder: (context, barrierVisible, child) {
          return Opacity(
            opacity: barrierVisible ? 0 : 1,
            child: child,
          );
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            final Offset? offset = (key.currentContext?.findRenderObject() as RenderBox?)?.localToGlobal(Offset.zero);

            if (offset == null) return;

            WidgetsBinding.instance.addPostFrameCallback((_) => focusNode.requestFocus());

            barrierVisibleNotifier.value = true;

            Barrier.show(
              context,
              transitionDuration: const Duration(milliseconds: 400),
              contentBuilder: (context, animation, content) {
                final CurvedAnimation curvedAnimation = CurvedAnimation(
                  parent: animation,
                  curve: AppTheme.standardAnimationCurve,
                  reverseCurve: AppTheme.standardAnimationCurve.flipped,
                );

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => focusNode.unfocus(disposition: UnfocusDisposition.previouslyFocusedChild),
                  child: AnimatedBuilder(
                    animation: curvedAnimation,
                    builder: (context, child) {
                      return Padding(
                        padding: EdgeInsets.only(
                          top: lerpDouble(
                            0,
                            AppTheme.statusBarHeight,
                            curvedAnimation.value,
                          )!,
                          bottom: lerpDouble(
                            0,
                            AppTheme.screenHeight * 0.35,
                            curvedAnimation.value,
                          )!,
                        ),
                        child: Align(
                          alignment: Alignment.lerp(
                            Alignment(
                              offset.dx / (AppTheme.screenWidth - buttonSize.width) * 2 - 1,
                              offset.dy / (AppTheme.screenHeight - buttonSize.height) * 2 - 1,
                            ),
                            Alignment.center,
                            curvedAnimation.value,
                          )!,
                          child: SizedBox.fromSize(
                            size: Size.lerp(
                              buttonSize,
                              expandedSize,
                              curvedAnimation.value,
                            ),
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: content,
                  ),
                );
              },
              content: textField,
            ).then((_) => barrierVisibleNotifier.value = false);
          },
          child: IgnorePointer(
            child: SizedBox.fromSize(
              key: key,
              size: buttonSize,
              child: textField,
            ),
          ),
        ),
      ),
    );
  }
}
