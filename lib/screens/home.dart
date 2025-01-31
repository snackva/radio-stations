import 'dart:math';
import 'dart:ui';
import 'package:animated_reorderable_list/animated_reorderable_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:radiostations/components/country_tile.dart';
import 'package:radiostations/components/station_tile.dart';
import 'package:radiostations/providers/favorites.dart';
import 'package:radiostations/services/api.dart';
import 'package:radiostations/components/app_bar.dart';
import 'package:radiostations/components/tap_scale.dart';
import 'package:radiostations/models/country.dart';
import 'package:radiostations/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const int limit = 15;

  final PageController pageController = PageController();
  final ScrollController countriesScrollController = ScrollController(), favoritesScrollController = ScrollController();

  final ValueNotifier<double> pageNotifier = ValueNotifier(0);
  final ValueNotifier<int> tabNotifier = ValueNotifier(0);

  final ValueNotifier<List<Country>> countriesNotifier = ValueNotifier([]);
  bool ongoingCountriesRequest = false, canFetchMoreCountries = true;

  Future<void> fetchCountries() async {
    if (ongoingCountriesRequest || !canFetchMoreCountries) return;
    ongoingCountriesRequest = true;

    if (countriesScrollController.hasClients && (countriesScrollController.position.pixels + AppTheme.screenHeight >= countriesScrollController.position.maxScrollExtent || countriesNotifier.value.isEmpty)) {
      final List<Country>? countries = await ApiService().countries(
        limit: limit,
        offset: countriesNotifier.value.length,
      );

      if (countries != null) {
        countriesNotifier.value = [...countriesNotifier.value, ...countries];
        if (countries.length < limit) {
          canFetchMoreCountries = false;
        }
      }
    }

    ongoingCountriesRequest = false;
  }

  @override
  void initState() {
    pageController.addListener(() => pageNotifier.value = pageController.page ?? 0);

    countriesScrollController.addListener(() => fetchCountries());

    WidgetsBinding.instance.addPostFrameCallback((_) => fetchCountries());

    super.initState();
  }

  @override
  void dispose() {
    pageController.dispose();
    countriesScrollController.dispose();
    favoritesScrollController.dispose();
    pageNotifier.dispose();
    tabNotifier.dispose();
    countriesNotifier.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      TapScale(
        onTap: () => pageController.animateToPage(0, duration: AppTheme.slowAnimationDuration, curve: AppTheme.standardAnimationCurve),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Text('Countries', style: AppTheme.titleSmallStyle),
        ),
      ),
      TapScale(
        onTap: () => pageController.animateToPage(1, duration: AppTheme.slowAnimationDuration, curve: AppTheme.standardAnimationCurve),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Text('Favorites', style: AppTheme.titleSmallStyle),
        ),
      ),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(CustomAppBar.height),
        child: ValueListenableBuilder(
          valueListenable: tabNotifier,
          builder: (context, tab, child) {
            return CustomAppBar(
              scrollController: tab == 0 ? countriesScrollController : favoritesScrollController,
              content: child!,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: List.generate(tabs.length, (index) {
                return ValueListenableBuilder(
                  valueListenable: pageNotifier,
                  builder: (context, page, child) {
                    return Opacity(
                      opacity: lerpDouble(
                        1,
                        0.25,
                        (page - index).abs().clamp(0, 1),
                      )!,
                      child: child,
                    );
                  },
                  child: tabs[index],
                );
              }),
            ),
          ),
        ),
      ),
      body: PageView(
        controller: pageController,
        onPageChanged: (value) => tabNotifier.value = value,
        children: [
          ValueListenableBuilder(
            valueListenable: countriesNotifier,
            builder: (context, countries, child) {
              return ListView.separated(
                key: const PageStorageKey('countries'),
                controller: countriesScrollController,
                padding: EdgeInsets.fromLTRB(
                  16,
                  AppTheme.statusBarHeight + CustomAppBar.height + 32,
                  16,
                  max(16, AppTheme.bottomPadding),
                ),
                itemCount: countries.length + (canFetchMoreCountries ? limit : 0),
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final Country? country = index < countries.length ? countries[index] : null;

                  return CountryTile(
                    country: country,
                    scrollController: countriesScrollController,
                  );
                },
              );
            },
          ),
          Selector<Favorites, List<String>>(
            selector: (context, favorites) => favorites.stations,
            builder: (context, favorites, child) {
              return AnimatedSwitcher(
                duration: AppTheme.standardAnimationDuration,
                child: favorites.isEmpty
                    ? SingleChildScrollView(
                        controller: favoritesScrollController,
                        child: Center(
                          child: FractionallySizedBox(
                            widthFactor: 0.5,
                            child: Text(
                              'You haven\'t marked any station as favorite yet',
                              style: AppTheme.subtitleStyle.copyWith(color: AppTheme.surfaceColor.withOpacity(0.5)),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      )
                    : AnimatedListView(
                        key: const PageStorageKey('favorites'),
                        controller: favoritesScrollController,
                        padding: EdgeInsets.fromLTRB(
                          16,
                          AppTheme.statusBarHeight + CustomAppBar.height + 28,
                          16,
                          max(12, AppTheme.bottomPadding),
                        ),
                        items: favorites,
                        itemBuilder: (context, index) {
                          return Padding(
                            key: ValueKey(favorites[index]),
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: FutureBuilder(
                              future: ApiService().station(uuid: favorites[index]),
                              builder: (context, snapshot) {
                                return StationTile(
                                  station: snapshot.data,
                                  scrollController: favoritesScrollController,
                                );
                              },
                            ),
                          );
                        },
                      ),
              );
            },
          ),
        ],
      ),
    );
  }
}
