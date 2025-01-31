import 'dart:math';

import 'package:flutter/material.dart';
import 'package:radiostations/components/search_button.dart';
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

  String searchPrevious = '';
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();

  final ValueNotifier<List<Station>> stationsNotifier = ValueNotifier([]);
  bool ongoingStationsRequest = false, canFetchMoreStations = true;

  Future<void> fetchStations() async {
    if (ongoingStationsRequest || !canFetchMoreStations) return;
    ongoingStationsRequest = true;

    if (stationsScrollController.hasClients && (stationsScrollController.position.pixels + AppTheme.screenHeight >= stationsScrollController.position.maxScrollExtent || stationsNotifier.value.isEmpty)) {
      final List<Station>? stations = await ApiService().countryStations(
        country: widget.country,
        nameContent: searchController.text,
        limit: limit,
        offset: stationsNotifier.value.length,
      );

      if (stations != null) {
        stationsNotifier.value = [...stationsNotifier.value, ...stations];
        if (stations.length < limit) {
          canFetchMoreStations = false;
        }
      }
    }

    ongoingStationsRequest = false;
  }

  void searchFocusListener() {
    if (!searchFocus.hasFocus && searchController.text != searchPrevious) {
      stationsNotifier.value = [];
      canFetchMoreStations = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => fetchStations());
    }

    searchPrevious = searchController.text;
  }

  @override
  void initState() {
    stationsScrollController.addListener(fetchStations);
    searchFocus.addListener(searchFocusListener);

    WidgetsBinding.instance.addPostFrameCallback((_) => fetchStations());

    super.initState();
  }

  @override
  void dispose() {
    stationsScrollController.removeListener(fetchStations);
    searchFocus.removeListener(searchFocusListener);
    searchController.dispose();
    stationsNotifier.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
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
          SearchButton(
            hint: 'Search for a station...',
            textEditingController: searchController,
            focusNode: searchFocus,
          ),
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
            child: stations.isEmpty && !canFetchMoreStations
                ? Center(
                    child: Text(
                      'No stations available',
                      style: AppTheme.subtitleStyle,
                    ),
                  )
                : ListView.separated(
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

                      return StationTile(
                        station: station,
                        scrollController: stationsScrollController,
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}
