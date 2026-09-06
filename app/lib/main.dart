import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'const/app_config.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;
  final _authService = AuthService(AuthApiService(serverUrl: AppConfig.serverUrl));

  @override
  void initState() {
    super.initState();
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final saved = await StorageService().getLanguage();
    if (saved != null) {
      setState(() => _locale = Locale(saved));
    }
  }

  void _changeLocale(Locale? locale) async {
    setState(() => _locale = locale);
    await StorageService().saveLanguage(locale?.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClipSync',
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('pl')],
      theme: AppTheme.dark,
      home: FutureBuilder<String?>(
        future: StorageService().getToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: AppColors.background,
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.data == null) {
            return LoginScreen(authService: _authService, onLocaleChange: _changeLocale);
          }
          return HomeScreen(title: 'ClipSync', authService: _authService, onLocaleChange: _changeLocale);
        },
      ),
    );
  }
}
