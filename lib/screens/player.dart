import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:radiostations/components/app_bar.dart';
import 'package:radiostations/components/tap_scale.dart';
import 'package:radiostations/components/volume_slider.dart';
import 'package:radiostations/providers/favorites.dart';
import 'package:radiostations/models/station.dart';
import 'package:radiostations/services/router.dart';
import 'package:radiostations/services/storage.dart';
import 'package:radiostations/theme.dart';
import 'package:text_scroll/text_scroll.dart';

class PlayerScreenArguments {
  final Station station;
  final FadeZoomTransitionArguments stationTile;

  PlayerScreenArguments({
    required this.station,
    required this.stationTile,
  });
}

class PlayerScreen extends StatefulWidget {
  final Station station;

  const PlayerScreen({
    super.key,
    required this.station,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with TickerProviderStateMixin {
  final AudioPlayer player = AudioPlayer();
  final ValueNotifier<bool> loadingNotifier = ValueNotifier(true);
  late final AnimationController visualizerController, playingController;
  StreamSubscription<bool>? playingSubscription;

  @override
  void initState() {
    visualizerController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();

    playingController = AnimationController(
      duration: AppTheme.standardAnimationDuration,
      vsync: this,
      value: 1,
    );

    player.setUrl(widget.station.streamUrl);
    player.play().then((_) {
      loadingNotifier.value = false;
      playingSubscription = player.playingStream.listen((playing) {
        if (playing) {
          playingController.forward();
        } else {
          playingController.reverse();
        }
      });
    });

    super.initState();
  }

  @override
  void dispose() {
    playingSubscription?.cancel();
    visualizerController.dispose();
    playingController.dispose();
    loadingNotifier.dispose();
    player.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CustomAppBar(
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            widget.station.name,
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
        valueListenable: loadingNotifier,
        builder: (context, loading, child) {
          return IgnorePointer(
            ignoring: loading,
            child: AnimatedOpacity(
              opacity: loading ? 0.5 : 1,
              duration: AppTheme.standardAnimationDuration,
              child: child,
            ),
          );
        },
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: FractionallySizedBox(
                heightFactor: 0.5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const int visualizerCount = 20;
                      const double separatorWidth = 2;
                      final double visualizerWidth = (constraints.maxWidth - separatorWidth * (visualizerCount - 1)) / visualizerCount;

                      return ValueListenableBuilder(
                        valueListenable: loadingNotifier,
                        builder: (context, loading, child) {
                          return AnimatedSwitcher(
                            duration: const Duration(seconds: 1),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: CurvedAnimation(
                                  parent: animation,
                                  curve: const Interval(0.5, 1, curve: Curves.easeOut),
                                ),
                                child: child,
                              );
                            },
                            child: ListView.separated(
                              key: ValueKey(loading),
                              scrollDirection: Axis.horizontal,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: visualizerCount,
                              separatorBuilder: (context, index) => const SizedBox(width: separatorWidth),
                              itemBuilder: (context, index) {
                                final double animationShift = loading ? (index / visualizerCount * 2 - 1).abs() : Random().nextDouble();
                                final double maxHeight = loading ? 0.25 : lerpDouble(0.75, 1, Random().nextDouble())!;
                                final double minHeight = loading ? 0 : lerpDouble(0.25, 0.5, Random().nextDouble())!;

                                return Center(
                                  child: ListenableBuilder(
                                    listenable: Listenable.merge([playingController, visualizerController]),
                                    builder: (context, child) {
                                      double value = visualizerController.value - animationShift;
                                      value = value - value.toInt();
                                      value = (sin(value * 2 * pi) + 1) / 2;

                                      return SizedBox(
                                        width: visualizerWidth,
                                        height: lerpDouble(
                                          visualizerWidth,
                                          lerpDouble(
                                            visualizerWidth,
                                            constraints.maxHeight,
                                            lerpDouble(minHeight, maxHeight, value)!,
                                          ),
                                          (playingController.status == AnimationStatus.reverse ? AppTheme.standardAnimationCurve.flipped : AppTheme.standardAnimationCurve).transform(playingController.value),
                                        )!,
                                        child: child,
                                      );
                                    },
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(visualizerWidth / 2),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: StreamBuilder(
                stream: player.icyMetadataStream,
                builder: (context, snapshot) {
                  final String title = snapshot.data?.info?.title ?? '';

                  return AnimatedSwitcher(
                    duration: AppTheme.standardAnimationDuration,
                    switchInCurve: Curves.fastOutSlowIn,
                    switchOutCurve: Curves.fastOutSlowIn.flipped,
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        alignment: Alignment.centerLeft,
                        scale: Tween<double>(begin: 0.75, end: 1).animate(animation),
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: TextScroll(
                      key: ValueKey(title),
                      ' $title       ',
                      delayBefore: const Duration(seconds: 1),
                      pauseBetween: const Duration(seconds: 2),
                      style: AppTheme.titleMediumStyle,
                      textAlign: TextAlign.left,
                      fadedBorder: true,
                      fadedBorderWidth: 8 / AppTheme.screenWidth,
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TapScale(
                        onTap: () => player.playerState.playing ? player.pause() : player.play(),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: StreamBuilder(
                              stream: player.playingStream,
                              initialData: true,
                              builder: (context, snapshot) {
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
                                  child: Text(
                                    key: UniqueKey(),
                                    snapshot.data! ? 'Pause' : 'Play',
                                    style: AppTheme.titleSmallStyle.copyWith(color: Colors.white),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: Selector<Favorites, bool>(
                              selector: (context, favorites) => favorites.stations.contains(widget.station.uuid),
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
                                      final Favorites favorites = Provider.of<Favorites>(context, listen: false);

                                      if (isFavorite) {
                                        favorites.remove(widget.station.uuid);
                                      } else {
                                        favorites.add(widget.station.uuid);
                                      }
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isFavorite ? AppTheme.primaryColor : null,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: AppTheme.surfaceColor.withOpacity(0.1), width: 2),
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
                          const SizedBox(height: 8),
                          Expanded(
                            child: VolumeSlider(
                              initialValue: StorageService().getDouble('volume') ?? 0.5,
                              onChange: (value) {
                                player.setVolume(value * 2);
                              },
                              onChangeEnd: (value) {
                                StorageService().setDouble('volume', value);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: max(8, AppTheme.bottomPadding)),
          ],
        ),
      ),
    );
  }
}
