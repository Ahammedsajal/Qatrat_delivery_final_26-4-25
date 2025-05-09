import 'dart:io';
import 'package:deliveryboy/Helper/Color.dart';
import 'package:deliveryboy/Helper/Constant.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Helper/PushNotificationService.dart';
import 'Helper/String.dart';
import 'Localization/Demo_Localization.dart';
import 'Localization/Language_Constant.dart';
import 'Provider/Theme.dart';
import 'Screens/Home.dart';
import 'Screens/Splash.dart';

///App version
/// V4.4.1
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final pushNotificationService = PushNotificationService();
  pushNotificationService.initialise();
  FirebaseMessaging.onBackgroundMessage(myForgroundMessageHandler);
  HttpOverrides.global = MyHttpOverrides();
  runApp(
    ChangeNotifierProvider<ThemeNotifier>(
      create: (final BuildContext context) {
        final String? theme = prefs.getString(APP_THEME);
        if (theme == DARK) {
          ISDARK = 'true';
        } else if (theme == LIGHT) {
          ISDARK = 'false';
        }
        if (theme == null || theme == '' || theme == DEFAULT_SYSTEM) {
          prefs.setString(APP_THEME, DEFAULT_SYSTEM);
          final brightness =
              SchedulerBinding.instance.platformDispatcher.platformBrightness;
          ISDARK = (brightness == Brightness.dark).toString();
          return ThemeNotifier(ThemeMode.system);
        }
        return ThemeNotifier(theme == LIGHT ? ThemeMode.light : ThemeMode.dark);
      },
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  static void setLocale(final BuildContext context, final Locale newLocale) {
    final _MyAppState state = context.findAncestorStateOfType<_MyAppState>()!;
    state.setLocale(newLocale);
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

SharedPreferences? globalPrefs;

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    sharedPreference();
    super.initState();
  }

  sharedPreference() async {
    globalPrefs = await SharedPreferences.getInstance();
  }

  Locale? _locale;
  setLocale(final Locale locale) {
    if (mounted) {
      setState(
        () {
          _locale = locale;
        },
      );
    }
  }

  @override
  void didChangeDependencies() {
    getLocale().then(
      (final locale) {
        if (mounted) {
          setState(
            () {
              _locale = locale;
            },
          );
        }
      },
    );
    super.didChangeDependencies();
  }

  @override
  Widget build(final BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    return Selector<ThemeNotifier, ThemeMode>(
      selector: (final _, final themeProvider) => themeProvider.getThemeMode(),
      builder: (final context, final data, final child) {
        return MaterialApp(
          title: appName,
          theme: ThemeData(
            useMaterial3: false,
            colorScheme:
                ColorScheme.fromSwatch(primarySwatch: colors.primary_app)
                    .copyWith(brightness: Brightness.light),
            visualDensity: VisualDensity.adaptivePlatformDensity,
            canvasColor: Theme.of(context).colorScheme.lightWhite,
            cardColor: Theme.of(context).colorScheme.white,
            dialogBackgroundColor: Theme.of(context).colorScheme.white,
            iconTheme: Theme.of(context)
                .iconTheme
                .copyWith(color: Theme.of(context).colorScheme.primary),
            primarySwatch: colors.primary_app,
            primaryColor: Theme.of(context).colorScheme.lightWhite,
            fontFamily: 'opensans',
            textTheme: TextTheme(
              titleLarge: TextStyle(
                color: Theme.of(context).colorScheme.fontColor,
                fontWeight: FontWeight.w600,
              ),
              titleMedium: TextStyle(
                color: Theme.of(context).colorScheme.fontColor,
                fontWeight: FontWeight.bold,
              ),
            ).apply(bodyColor: Theme.of(context).colorScheme.fontColor),
          ),
          debugShowCheckedModeBanner: false,
          initialRoute: '/',
          locale: _locale,
          localizationsDelegates: const [
            DemoLocalization.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale("en", "US"),
            Locale("zh", "CN"),
            Locale("es", "ES"),
            Locale("hi", "IN"),
            Locale("ar", "DZ"),
            Locale("ru", "RU"),
            Locale("ja", "JP"),
            Locale("de", "DE"),
          ],
          localeResolutionCallback: (final locale, final supportedLocales) {
            for (final Locale supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == locale!.languageCode &&
                  supportedLocale.countryCode == locale.countryCode) {
                return supportedLocale;
              }
            }
            return supportedLocales.first;
          },
          routes: {
            '/': (final context) => const Splash(),
            '/home': (final context) => const Home(),
          },
          darkTheme: ThemeData(
            useMaterial3: false,
            canvasColor: Theme.of(context).colorScheme.darkColor,
            cardColor: Theme.of(context).colorScheme.darkColor2,
            dialogBackgroundColor: Theme.of(context).colorScheme.darkColor2,
            primaryColor: Theme.of(context).colorScheme.darkColor,
            textSelectionTheme: TextSelectionThemeData(
              cursorColor: Theme.of(context).colorScheme.lightfontColor,
              selectionColor: Theme.of(context).colorScheme.lightfontColor,
              selectionHandleColor:
                  Theme.of(context).colorScheme.lightfontColor,
            ),
            fontFamily: 'ubuntu',
            brightness: Brightness.dark,
            hintColor: Theme.of(context).colorScheme.white,
            iconTheme: Theme.of(context)
                .iconTheme
                .copyWith(color: Theme.of(context).colorScheme.secondary),
            textTheme: TextTheme(
              titleLarge: TextStyle(
                color: Theme.of(context).colorScheme.fontColor,
                fontWeight: FontWeight.w600,
              ),
              titleMedium: TextStyle(
                color: Theme.of(context).colorScheme.fontColor,
                fontWeight: FontWeight.bold,
              ),
            ).apply(bodyColor: Theme.of(context).colorScheme.fontColor),
            colorScheme: ColorScheme.fromSwatch(
              primarySwatch: colors.primary_app,
            )
                .copyWith(brightness: Brightness.dark)
                .copyWith(secondary: Theme.of(context).colorScheme.darkColor),
            checkboxTheme: CheckboxThemeData(
              fillColor: WidgetStateProperty.resolveWith<Color?>(
                  (final Set<WidgetState> states) {
                if (states.contains(WidgetState.disabled)) {
                  return null;
                }
                if (states.contains(WidgetState.selected)) {
                  return Theme.of(context).colorScheme.primarytheme;
                }
                return null;
              }),
            ),
            radioTheme: RadioThemeData(
              fillColor: WidgetStateProperty.resolveWith<Color?>(
                  (final Set<WidgetState> states) {
                if (states.contains(WidgetState.disabled)) {
                  return null;
                }
                if (states.contains(WidgetState.selected)) {
                  return Theme.of(context).colorScheme.primarytheme;
                }
                return null;
              }),
            ),
            switchTheme: SwitchThemeData(
              thumbColor: WidgetStateProperty.resolveWith<Color?>(
                  (final Set<WidgetState> states) {
                if (states.contains(WidgetState.disabled)) {
                  return null;
                }
                if (states.contains(WidgetState.selected)) {
                  return Theme.of(context).colorScheme.primarytheme;
                }
                return null;
              }),
              trackColor: WidgetStateProperty.resolveWith<Color?>(
                  (final Set<WidgetState> states) {
                if (states.contains(WidgetState.disabled)) {
                  return null;
                }
                if (states.contains(WidgetState.selected)) {
                  return Theme.of(context).colorScheme.primarytheme;
                }
                return null;
              }),
            ),
          ),
          themeMode: themeNotifier.getThemeMode(),
        );
      },
    );
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(final SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (final X509Certificate cert, final String host, final int port) =>
              true;
  }
}
