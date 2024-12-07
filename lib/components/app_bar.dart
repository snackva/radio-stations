import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:radiostations/components/tap_scale.dart';
import 'package:radiostations/theme.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final ScrollController? scrollController;
  final Widget content;
  final List<AppBarButton> buttons;

  const CustomAppBar({
    super.key,
    this.scrollController,
    required this.content,
    this.buttons = const [],
  });

  static const double height = 64;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  final ValueNotifier<bool> elevatedNotifier = ValueNotifier(false);

  void _scrollControllerListener(ScrollController scrollController) {
    elevatedNotifier.value = scrollController.offset > 16;
  }

  @override
  void initState() {
    widget.scrollController?.addListener(() => _scrollControllerListener(widget.scrollController!));

    super.initState();
  }

  @override
  void didUpdateWidget(covariant CustomAppBar oldWidget) {
    if (oldWidget.scrollController != widget.scrollController && widget.scrollController != null) {
      widget.scrollController?.addListener(() => _scrollControllerListener(widget.scrollController!));
      elevatedNotifier.value = widget.scrollController!.offset > 16;
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: ValueListenableBuilder(
          valueListenable: elevatedNotifier,
          builder: (context, elevated, child) {
            return AnimatedContainer(
              duration: AppTheme.standardAnimationDuration,
              curve: AppTheme.standardAnimationCurve,
              color: Colors.black.withOpacity(elevated ? 0.05 : 0),
              child: child,
            );
          },
          child: SafeArea(
            bottom: false,
            maintainBottomViewPadding: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(child: widget.content),
                ListView.separated(
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(right: 8),
                  itemCount: widget.buttons.length,
                  separatorBuilder: (context, index) => const SizedBox(
                    width: 8,
                  ),
                  itemBuilder: (context, index) {
                    return widget.buttons[index];
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppBarButton extends StatelessWidget {
  final String iconAsset;
  final VoidCallback onPressed;

  const AppBarButton({
    super.key,
    required this.iconAsset,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onPressed,
      child: SizedBox(
        height: 48,
        width: 48,
        child: Center(
          child: SvgPicture.asset(iconAsset),
        ),
      ),
    );
  }
}
