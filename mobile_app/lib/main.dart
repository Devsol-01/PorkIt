import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app/app/app.bottomsheets.dart';
import 'package:mobile_app/app/app.dialogs.dart';
import 'package:mobile_app/app/app.locator.dart';
import 'package:mobile_app/app/app.router.dart';
import 'package:mobile_app/firebase_options.dart';
import 'package:mobile_app/l10n/app_localizations.dart';
import 'package:mobile_app/services/localization_service.dart';
import 'package:stacked_services/stacked_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await setupLocator();
  setupDialogUi();
  setupBottomSheetUi();

  // Initialize localization service
  final localizationService = locator<LocalizationService>();
  await localizationService.initialize();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localizationService = locator<LocalizationService>();

    return AnimatedBuilder(
      animation: localizationService,
      builder: (context, child) {
        return MaterialApp(
          initialRoute: Routes.startupView,
          onGenerateRoute: StackedRouter().onGenerateRoute,
          navigatorKey: StackedService.navigatorKey,
          navigatorObservers: [StackedService.routeObserver],
          debugShowCheckedModeBanner: false,
          locale: localizationService.currentLocale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
        );
      },
    );
  }
}
