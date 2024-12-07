import 'dart:math';

import 'package:flutter/material.dart';
import 'package:radiostations/components/station_tile.dart';
import 'package:radiostations/services/api.dart';
import 'package:radiostations/components/app_bar.dart';
import 'package:radiostations/models/country.dart';
import 'package:radiostations/models/station.dart';
import 'package:radiostations/services/router.dart';
import 'package:radiostations/theme.dart';

class StationsScreenArguments {
  final Country country;
  final FadeZoomTransitionArguments countryTile;

  StationsScreenArguments({
    required this.country,
    required this.countryTile,
  });
}

class StationsScreen extends StatefulWidget {
  final Country country;

  const StationsScreen({
    super.key,
    required this.country,
  });

  @override
  State<StationsScreen> createState() => _StationsScreenState();
}

class _StationsScreenState extends State<StationsScreen> {
  static const int limit = 10;

  final ScrollController stationsScrollController = ScrollController();

  final ValueNotifier<List<Station>> stationsNotifier = ValueNotifier([]);
  bool ongoingStationsRequest = false, canFetchMoreStations = true;

  Future<void> fetchStations() async {
    if (ongoingStationsRequest || !canFetchMoreStations) return;
    ongoingStationsRequest = true;

    if (stationsScrollController.position.pixels + AppTheme.screenHeight >= stationsScrollController.position.maxScrollExtent) {
      final List<Station>? stations = await ApiService().countryStations(country: widget.country, limit: limit, offset: stationsNotifier.value.length);

      if (stations != null) {
        stationsNotifier.value = [...stationsNotifier.value, ...stations];
        if (stations.length < limit) {
          canFetchMoreStations = false;
        }
      }
    }

    ongoingStationsRequest = false;
  }

  @override
  void initState() {
    stationsScrollController.addListener(() => fetchStations());

    WidgetsBinding.instance.addPostFrameCallback((_) => fetchStations());

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        scrollController: stationsScrollController,
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            widget.country.name,
            style: AppTheme.titleSmallStyle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        buttons: [
          AppBarButton(
            iconAsset: 'assets/icons/x.svg',
            onPressed: () => RouterService().pop(),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: stationsNotifier,
        builder: (context, stations, child) {
          return AnimatedSwitcher(
            duration: AppTheme.standardAnimationDuration,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: CurvedAnimation(parent: animation, curve: const Interval(0.5, 1)),
                child: child,
              );
            },
            child: ListView.separated(
              controller: stationsScrollController,
              padding: EdgeInsets.fromLTRB(
                16,
                AppTheme.statusBarHeight + CustomAppBar.height + 32,
                16,
                max(16, AppTheme.bottomPadding),
              ),
              itemCount: stations.length + (canFetchMoreStations ? limit : 0),
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final Station? station = index < stations.length ? stations[index] : null;

                return StationTile(station: station);
              },
            ),
          );
        },
      ),
    );
  }
}
