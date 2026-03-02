import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:form_fields/form_fields.dart';
import 'package:provider/provider.dart';
import 'config/app_router.dart';
import 'state/app_state_notifier.dart';
import 'localization/localizations.dart' as loc;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => View();
}

abstract class PresenterState extends State<MyApp> {
  late final ViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = ViewModel();
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }
}

class View extends PresenterState {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel.appState,
      child: Consumer<AppStateNotifier>(
        builder: (context, appState, _) {
          if (!appState.isInitialized) {
            return const MaterialApp(
              home: Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            );
          }

          return MaterialApp.router(
            title: 'FormFields - Complete Examples',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              useMaterial3: true,
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
                },
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF1F2937),
                foregroundColor: Colors.white,
              ),
            ),
            locale: appState.locale,
            localizationsDelegates: const [
              loc.LocalizationsDelegate(),
              FormFieldsLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: loc.Localizations.supportedLocales,
            routerConfig: viewModel.routerConfig,
          );
        },
      ),
    );
  }
}

class ViewModel {
  final AppStateNotifier appState = AppStateNotifier();
  late final routerConfig = createAppRouter(appState);

  void dispose() {
    appState.dispose();
  }
}
