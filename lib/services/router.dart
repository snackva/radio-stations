import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:radiostations/models/country.dart';
import 'package:radiostations/models/station.dart';
import 'package:radiostations/screens/home.dart';
import 'package:radiostations/screens/player.dart';
import 'package:radiostations/screens/stations.dart';
import 'package:radiostations/theme.dart';

class RouterService {
  static final RouterService _instance = RouterService._internal();

  late final GlobalKey<NavigatorState> _navigatorKey;

  factory RouterService() => _instance;

  RouterService._internal();

  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    _navigatorKey = navigatorKey;
  }

  // Routes
  static const String homePath = '/';
  static const String stationsPath = '/stations';
  static const String playerPath = '/player';

  static final Map<String, WidgetBuilder Function(Object? arguments)> _builders = {
    homePath: (_) => (context) => const HomeScreen(),
    stationsPath: (arguments) => (context) => StationsScreen(country: (arguments as StationsScreenArguments).country),
    playerPath: (arguments) => (context) => PlayerScreen(station: (arguments as PlayerScreenArguments).station),
  };

  Route<dynamic>? routeGenerator(RouteSettings settings) {
    String routePath = settings.name ?? homePath;

    switch (routePath) {
      case stationsPath:
        final StationsScreenArguments arguments = settings.arguments as StationsScreenArguments;
        return FadeZoomPageRoute(
          source: arguments.countryTile,
          builder: _builders[routePath]!.call(arguments),
          settings: settings,
        );
      case playerPath:
        final PlayerScreenArguments arguments = settings.arguments as PlayerScreenArguments;
        return FadeZoomPageRoute(
          source: arguments.stationTile,
          builder: _builders[routePath]!.call(arguments),
          settings: settings,
        );
      default:
        final WidgetBuilder Function(Object? arguments)? builder = _builders[routePath];

        if (builder == null) return null;

        return Platform.isIOS
            ? CupertinoPageRoute(
                builder: builder.call(settings.arguments),
                settings: settings,
              )
            : MaterialPageRoute(
                builder: builder.call(settings.arguments),
                settings: settings,
              );
    }
  }

  void homePage() => _navigatorKey.currentState?.pushNamedAndRemoveUntil(homePath, (route) => false);
  void stationsPage(Country country, FadeZoomTransitionArguments countryTile) => _navigatorKey.currentState?.pushNamed(
        stationsPath,
        arguments: StationsScreenArguments(country: country, countryTile: countryTile),
      );
  void playerPage(Station station, FadeZoomTransitionArguments stationTile) => _navigatorKey.currentState?.pushNamed(
        playerPath,
        arguments: PlayerScreenArguments(station: station, stationTile: stationTile),
      );

  void pop() => _navigatorKey.currentState?.pop();
}

class FadeZoomTransitionArguments {
  final Widget child;
  final Offset offset;
  final Size size;

  FadeZoomTransitionArguments({
    required this.child,
    required this.offset,
    required this.size,
  });
}

class FadeZoomPageRoute extends MaterialPageRoute {
  final FadeZoomTransitionArguments source;

  FadeZoomPageRoute({
    required this.source,
    required super.builder,
    super.settings,
  });

  @override
  Duration get transitionDuration => AppTheme.slowAnimationDuration;

  @override
  Color? get barrierColor => Colors.transparent;

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return FadeZoomTransition(
      animation: animation,
      source: source,
      child: child,
    );
  }
}

class FadeZoomTransition extends StatelessWidget {
  final FadeZoomTransitionArguments source;
  final Widget child;
  final Animation<double> sizeAnimation, radiusAnimation, sourceAnimation, destinationAnimation;

  FadeZoomTransition({
    super.key,
    required Animation<double> animation,
    required this.source,
    required this.child,
  })  : sizeAnimation = CurvedAnimation(parent: animation, curve: Curves.fastOutSlowIn, reverseCurve: Curves.fastOutSlowIn.flipped),
        radiusAnimation = CurvedAnimation(parent: animation, curve: const Interval(0.8, 1, curve: Curves.easeOut), reverseCurve: Interval(0.8, 1, curve: Curves.easeOut.flipped)),
        sourceAnimation = CurvedAnimation(parent: ReverseAnimation(animation), curve: const Interval(0.4, 1, curve: Curves.easeInOut)),
        destinationAnimation = CurvedAnimation(parent: animation, curve: const Interval(0.4, 1, curve: Curves.easeInOut));

  static const double scale = 0.75, radius = 16;

  @override
  Widget build(BuildContext context) {
    final ValueNotifier<Offset> translationNotifier = ValueNotifier(Offset.zero);

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onPanUpdate: (details) {
          translationNotifier.value += details.delta;
        },
        onPanEnd: (details) {
          if (translationNotifier.value.distance > 200 || (translationNotifier.value.distance > 100 && details.velocity.pixelsPerSecond.distance > 0)) {
            RouterService().pop();
          } else {
            final Offset initialTranslation = translationNotifier.value, finalTranslation = Offset.zero;
            late Ticker cancelPopTicker;

            cancelPopTicker = Ticker((elapsed) {
              final double elapsedFraction = elapsed.inMilliseconds / AppTheme.standardAnimationDuration.inMilliseconds;

              if (elapsedFraction < 1) {
                translationNotifier.value = Offset.lerp(
                  initialTranslation,
                  finalTranslation,
                  AppTheme.standardAnimationCurve.transform(elapsedFraction),
                )!;
              } else {
                translationNotifier.value = finalTranslation;
                cancelPopTicker.stop();
              }
            })
              ..start();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: source.offset.dx,
              top: source.offset.dy,
              width: source.size.width,
              height: source.size.height,
              child: ColoredBox(color: AppTheme.backgroundColor),
            ),
            ListenableBuilder(
              listenable: sizeAnimation,
              builder: (context, child) {
                return BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16 * sizeAnimation.value, sigmaY: 16 * sizeAnimation.value),
                  child: child,
                );
              },
              child: FadeTransition(
                opacity: sizeAnimation,
                child: ColoredBox(color: Color.alphaBlend(AppTheme.backgroundColor.withOpacity(0.9), AppTheme.surfaceColor)),
              ),
            ),
            ListenableBuilder(
              listenable: Listenable.merge([sizeAnimation, translationNotifier]),
              builder: (context, child) {
                return Positioned(
                  left: lerpDouble(source.offset.dx, translationNotifier.value.dx / 2, sizeAnimation.value),
                  top: lerpDouble(source.offset.dy, translationNotifier.value.dy / 2, sizeAnimation.value),
                  width: lerpDouble(source.size.width, AppTheme.screenWidth, sizeAnimation.value),
                  height: lerpDouble(source.size.height, AppTheme.screenHeight, sizeAnimation.value),
                  child: Transform.scale(
                    scale: 1 - translationNotifier.value.distance / 5 / AppTheme.screenWidth,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(lerpDouble(radius, translationNotifier.value.distance > 0 ? radius : 0, radiusAnimation.value)!),
                      child: child!,
                    ),
                  ),
                );
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: AppTheme.backgroundColor),
                  FadeTransition(
                    opacity: destinationAnimation,
                    child: FittedBox(
                      fit: BoxFit.fill,
                      child: SizedBox.fromSize(
                        size: Size(AppTheme.screenWidth, AppTheme.screenHeight),
                        child: child,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ListenableBuilder(
              listenable: sizeAnimation,
              builder: (context, child) {
                return Positioned(
                  left: source.offset.dx,
                  top: lerpDouble(source.offset.dy, (AppTheme.screenHeight - source.size.height) / 2, sizeAnimation.value),
                  child: child!,
                );
              },
              child: IgnorePointer(
                child: FadeTransition(
                  opacity: sourceAnimation,
                  child: FittedBox(
                    child: SizedBox.fromSize(
                      size: source.size,
                      child: source.child,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
