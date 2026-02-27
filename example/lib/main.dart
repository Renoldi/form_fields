import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:form_fields/form_fields.dart';
import 'package:provider/provider.dart';
import 'app_router.dart';
import 'providers/app_state_notifier.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppStateNotifier(),
      child: Consumer<AppStateNotifier>(
        builder: (context, appState, _) {
          // Wait for auth state to initialize before showing UI
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
              FormFieldsLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: FormFieldsLocalizations.supportedLocales,
            routerConfig: createAppRouter(appState),
          );
        },
      ),
    );
  }
}
