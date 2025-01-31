import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:radiostations/components/shimmer.dart';
import 'package:radiostations/components/tap_scale.dart';
import 'package:radiostations/providers/favorites.dart';
import 'package:radiostations/models/station.dart';
import 'package:radiostations/services/router.dart';
import 'package:radiostations/theme.dart';

class StationTile extends StatefulWidget {
  final Station? station;
  final ScrollController? scrollController;

  const StationTile({
    super.key,
    required this.station,
    this.scrollController,
  });

  @override
  State<StationTile> createState() => _StationTileState();
}

class _StationTileState extends State<StationTile> {
  final GlobalKey key = GlobalKey();
  final ValueNotifier<double> alignmentNotifier = ValueNotifier(0), scaleNotifier = ValueNotifier(1);

  void scrollControllerListener() {
    if (!(widget.scrollController?.hasClients ?? false)) return;

    final RenderBox? renderBox = key.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) return;

    final double offset = renderBox.localToGlobal(Offset.zero).dy;
    final double height = renderBox.size.height;

    final double screenPercentage = ((offset + (height / 2)) / AppTheme.screenHeight).clamp(0, 1);

    alignmentNotifier.value = (1 - screenPercentage) * 2 - 1;
    scaleNotifier.value = 1;

    const double threshold = 0.15;

    scaleNotifier.value = 1 - screenPercentage < threshold ? lerpDouble(0.75, 1, Curves.easeOutCubic.transform((1 - screenPercentage) * 1 / threshold))! : 1;
  }

  @override
  void initState() {
    widget.scrollController?.addListener(scrollControllerListener);

    WidgetsBinding.instance.addPostFrameCallback((_) => scrollControllerListener());

    super.initState();
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(scrollControllerListener);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: key,
      onTap: widget.station != null
          ? () {
              final RenderBox? renderBox = key.currentContext?.findRenderObject() as RenderBox?;

              if (renderBox != null) {
                final Offset offset = renderBox.localToGlobal(Offset.zero);
                final Size size = renderBox.size;

                RouterService().playerPage(
                  widget.station!,
                  FadeZoomTransitionArguments(
                    child: StationTile(station: widget.station),
                    offset: offset,
                    size: size,
                  ),
                );
              }
            }
          : null,
      child: ValueListenableBuilder(
        valueListenable: scaleNotifier,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: Container(
          height: 96,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              width: 2,
              color: AppTheme.surfaceColor.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: widget.station?.tags.isEmpty ?? false ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Shimmer.lines(
                        enabled: widget.station == null,
                        lineHeight: 32,
                        child: widget.station != null
                            ? Text(
                                widget.station!.name,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.titleMediumStyle,
                                maxLines: 1,
                              )
                            : const SizedBox(
                                width: double.infinity,
                                height: 32,
                              ),
                      ),
                      if (widget.station?.tags.isNotEmpty ?? true)
                        Shimmer.lines(
                          enabled: widget.station == null,
                          lineHeight: 16,
                          child: widget.station != null
                              ? Text(
                                  widget.station!.tags.join(' · '),
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTheme.subtitleStyle.copyWith(color: AppTheme.surfaceColor.withOpacity(0.5)),
                                  maxLines: 1,
                                )
                              : const SizedBox(
                                  width: double.infinity,
                                  height: 16,
                                ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: ValueListenableBuilder(
                  valueListenable: alignmentNotifier,
                  builder: (context, alignment, child) {
                    return Align(
                      alignment: Alignment(0, alignment),
                      child: child!,
                    );
                  },
                  child: Shimmer(
                    enabled: widget.station == null,
                    borderRadius: BorderRadius.circular(24),
                    child: Selector<Favorites, bool>(
                      selector: (context, favorites) => widget.station != null && favorites.contains(widget.station!.uuid),
                      builder: (context, isFavorite, child) {
                        return AnimatedSwitcher(
                          duration: AppTheme.standardAnimationDuration,
                          switchInCurve: Curves.fastOutSlowIn,
                          switchOutCurve: Curves.fastOutSlowIn.flipped,
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(
                              scale: Tween<double>(begin: 0.75, end: 1).animate(animation),
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                          child: TapScale(
                            key: ValueKey(isFavorite),
                            onTap: () {
                              if (widget.station == null) return;

                              final Favorites favorites = Provider.of<Favorites>(context, listen: false);

                              if (isFavorite) {
                                favorites.remove(widget.station!.uuid);
                              } else {
                                favorites.add(widget.station!.uuid);
                              }
                            },
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isFavorite ? AppTheme.primaryColor : null,
                              ),
                              child: Center(
                                child: SvgPicture.asset(
                                  'assets/icons/star.svg',
                                  colorFilter: ColorFilter.mode(isFavorite ? Colors.white : AppTheme.primaryColor, BlendMode.srcIn),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
