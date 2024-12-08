import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:radiostations/components/shimmer.dart';
import 'package:radiostations/components/tap_scale.dart';
import 'package:radiostations/models/favorites.dart';
import 'package:radiostations/models/station.dart';
import 'package:radiostations/services/router.dart';
import 'package:radiostations/theme.dart';

class StationTile extends StatelessWidget {
  final Station? station;

  const StationTile({
    super.key,
    required this.station,
  });

  @override
  Widget build(BuildContext context) {
    final GlobalKey key = GlobalKey();

    return GestureDetector(
      key: key,
      onTap: station != null
          ? () {
              final RenderBox? renderBox = key.currentContext?.findRenderObject() as RenderBox?;

              if (renderBox != null) {
                final Offset offset = renderBox.localToGlobal(Offset.zero);
                final Size size = renderBox.size;

                RouterService().playerPage(
                  station!,
                  FadeZoomTransitionArguments(
                    child: StationTile(station: station),
                    offset: offset,
                    size: size,
                  ),
                );
              }
            }
          : null,
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
                  mainAxisAlignment: station?.tags.isEmpty ?? false ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Shimmer.lines(
                      enabled: station == null,
                      lineHeight: 32,
                      child: station != null
                          ? Text(
                              station!.name,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.titleMediumStyle,
                              maxLines: 1,
                            )
                          : const SizedBox(
                              width: double.infinity,
                              height: 32,
                            ),
                    ),
                    if (station?.tags.isNotEmpty ?? true)
                      Shimmer.lines(
                        enabled: station == null,
                        lineHeight: 16,
                        child: station != null
                            ? Text(
                                station!.tags.join(' · '),
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
              child: Shimmer(
                enabled: station == null,
                borderRadius: BorderRadius.circular(24),
                child: Selector<Favorites, bool>(
                  selector: (context, favorites) => station != null && favorites.contains(station!.uuid),
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
                          if (station == null) return;

                          final Favorites favorites = Provider.of<Favorites>(context, listen: false);

                          if (isFavorite) {
                            favorites.remove(station!.uuid);
                          } else {
                            favorites.add(station!.uuid);
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
          ],
        ),
      ),
    );
  }
}
