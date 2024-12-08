import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:radiostations/providers/favorites.dart';
import 'package:radiostations/services/router.dart';
import 'package:radiostations/services/storage.dart';
import 'package:radiostations/theme.dart';

void main() {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  WidgetsFlutterBinding.ensureInitialized();

  StorageService().initialize();
  RouterService().initialize(navigatorKey);

  runApp(MainApp(navigatorKey: navigatorKey));
}

class MainApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const MainApp({
    super.key,
    required this.navigatorKey,
  });

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => Favorites(),
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          // localizationsDelegates: Translations.localizationsDelegates,
          // supportedLocales: Translations.supportedLocales,
          // locale: locale,
          theme: AppTheme.data,
          onGenerateRoute: RouterService().routeGenerator,
          scrollBehavior: AppScrollBehavior(),
        );
      },
    );
  }
}
