import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:radiostations/components/shimmer.dart';
import 'package:radiostations/models/country.dart';
import 'package:radiostations/services/router.dart';
import 'package:radiostations/theme.dart';

class CountryTile extends StatelessWidget {
  final Country? country;

  const CountryTile({
    super.key,
    required this.country,
  });

  @override
  Widget build(BuildContext context) {
    final GlobalKey key = GlobalKey();

    return LayoutBuilder(
      key: key,
      builder: (context, constraints) {
        return GestureDetector(
          onTap: country != null
              ? () {
                  final RenderBox? renderBox = key.currentContext?.findRenderObject() as RenderBox?;

                  if (renderBox != null) {
                    final Offset offset = renderBox.localToGlobal(Offset.zero);
                    final Size size = renderBox.size;

                    RouterService().stationsPage(
                      country!,
                      FadeZoomTransitionArguments(
                        child: CountryTile(country: country),
                        offset: offset,
                        size: size,
                      ),
                    );
                  }
                }
              : null,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Shimmer(
                  enabled: country == null,
                  borderRadius: BorderRadius.circular(20),
                  child: country != null
                      ? Text(
                          country!.name,
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
                child: Shimmer(
                  enabled: country == null,
                  borderRadius: BorderRadius.circular(10),
                  child: Text(
                    '(${country?.stationCount})',
                    style: AppTheme.subtitleStyle.copyWith(color: AppTheme.primaryColor),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
