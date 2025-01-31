import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:radiostations/components/shimmer.dart';
import 'package:radiostations/models/country.dart';
import 'package:radiostations/services/router.dart';
import 'package:radiostations/theme.dart';

class CountryTile extends StatefulWidget {
  final Country? country;
  final ScrollController? scrollController;

  const CountryTile({
    super.key,
    required this.country,
    this.scrollController,
  });

  @override
  State<CountryTile> createState() => _CountryTileState();
}

class _CountryTileState extends State<CountryTile> {
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
    return LayoutBuilder(
      key: key,
      builder: (context, constraints) {
        return GestureDetector(
          onTap: widget.country != null
              ? () {
                  final RenderBox? renderBox = key.currentContext?.findRenderObject() as RenderBox?;

                  if (renderBox != null) {
                    final Offset offset = renderBox.localToGlobal(Offset.zero);
                    final Size size = renderBox.size;

                    RouterService().stationsPage(
                      widget.country!,
                      FadeZoomTransitionArguments(
                        child: CountryTile(
                          country: widget.country,
                          scrollController: widget.scrollController,
                        ),
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
            child: SizedBox(
              height: 48,
              child: Row(
                children: [
                  Flexible(
                    child: Shimmer(
                      enabled: widget.country == null,
                      borderRadius: BorderRadius.circular(20),
                      child: widget.country != null
                          ? Text(
                              widget.country!.name,
                              style: AppTheme.titleLargeStyle,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            )
                          : SizedBox(
                              width: lerpDouble(
                                constraints.maxWidth * 0.4,
                                constraints.maxWidth * 0.8,
                                Random().nextDouble(),
                              ),
                              height: 40,
                            ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, top: 6),
                    child: ValueListenableBuilder(
                      valueListenable: alignmentNotifier,
                      builder: (context, alignment, child) {
                        return Align(
                          alignment: Alignment(0, alignment),
                          child: child!,
                        );
                      },
                      child: Shimmer(
                        enabled: widget.country == null,
                        borderRadius: BorderRadius.circular(10),
                        child: Text(
                          '(${widget.country?.stationCount})',
                          style: AppTheme.subtitleStyle.copyWith(color: AppTheme.primaryColor),
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
    );
  }
}
