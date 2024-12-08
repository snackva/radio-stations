import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:radiostations/models/country.dart';
import 'package:radiostations/models/station.dart';
import 'package:radiostations/screens/home.dart';
import 'package:radiostations/screens/player.dart';
import 'package:radiostations/screens/stations.dart';
import 'package:radiostations/theme.dart';
import 'package:vector_math/vector_math_64.dart' as math;

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
        radiusAnimation = CurvedAnimation(parent: ReverseAnimation(animation), curve: const Interval(0.9, 1, curve: Curves.easeOut), reverseCurve: Interval(0.9, 1, curve: Curves.easeOut.flipped)),
        sourceAnimation = CurvedAnimation(parent: ReverseAnimation(animation), curve: const Interval(0.4, 1, curve: Curves.easeInOut)),
        destinationAnimation = CurvedAnimation(parent: animation, curve: const Interval(0.4, 1, curve: Curves.easeInOut));

  static const double scale = 0.75, radius = 16;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ListenableBuilder(
            listenable: sizeAnimation,
            builder: (context, child) {
              final double scale = lerpDouble(1, FadeZoomTransition.scale, sizeAnimation.value)!;

              return BackdropFilter(
                filter: ImageFilter.matrix(Matrix4.compose(
                  math.Vector3(AppTheme.screenWidth * 0.5 * (1 - scale), AppTheme.screenHeight * 0.5 * (1 - scale), 0),
                  math.Quaternion.identity(),
                  math.Vector3(scale, scale, 1),
                ).storage),
                child: ClipPath(
                    clipper: _FadeZoomTransitionBackgroundClipper(
                      sizeAnimation: sizeAnimation,
                      radiusAnimation: radiusAnimation,
                    ),
                    child: child),
              );
            },
            child: ColoredBox(color: AppTheme.backgroundColor),
          ),
          ListenableBuilder(
            listenable: sizeAnimation,
            builder: (context, child) {
              return Positioned(
                left: lerpDouble(source.offset.dx, 0, sizeAnimation.value),
                top: lerpDouble(source.offset.dy, 0, sizeAnimation.value),
                width: lerpDouble(source.size.width, AppTheme.screenWidth, sizeAnimation.value),
                height: lerpDouble(source.size.height, AppTheme.screenHeight, sizeAnimation.value),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(lerpDouble(radius, 0, radiusAnimation.value)!),
                  child: child!,
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
    );
  }
}

class _FadeZoomTransitionBackgroundClipper extends CustomClipper<Path> {
  final Animation<double> sizeAnimation, radiusAnimation;

  _FadeZoomTransitionBackgroundClipper({
    required this.sizeAnimation,
    required this.radiusAnimation,
  }) : super(reclip: Listenable.merge([sizeAnimation, radiusAnimation]));

  @override
  Path getClip(Size size) {
    Path outerPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    Path innerPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(
          lerpDouble(0, size.width * 0.5 * (1 - FadeZoomTransition.scale), sizeAnimation.value)!,
          lerpDouble(0, size.height * 0.5 * (1 - FadeZoomTransition.scale), sizeAnimation.value)!,
          lerpDouble(size.width, size.width * FadeZoomTransition.scale, sizeAnimation.value)!,
          lerpDouble(size.height, size.height * FadeZoomTransition.scale, sizeAnimation.value)!,
        ),
        Radius.circular(lerpDouble(FadeZoomTransition.radius, 0, radiusAnimation.value)!),
      ));

    return Path.combine(PathOperation.difference, outerPath, innerPath);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}
