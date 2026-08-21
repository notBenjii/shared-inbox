// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get syncing => 'synchronizowanie...';

  @override
  String get notSyncedYet => 'jeszcze nie zsynchronizowano';

  @override
  String lastSynced(Object time) {
    return 'ostatnia synchronizacja: $time';
  }

  @override
  String get sendHint => 'Wklej lub wpisz coś...';

  @override
  String get emptyStateMessage =>
      'Brak elementów.\nWyślij coś poniżej, aby zacząć.';

  @override
  String get renameDeviceTitle => 'Zmień nazwę urządzenia';

  @override
  String get renameDeviceHint => 'Nowa nazwa urządzenia';

  @override
  String get cancel => 'Anuluj';

  @override
  String get save => 'Zapisz';

  @override
  String get resetSetup => 'Zresetuj konfigurację';

  @override
  String get failedToLoad =>
      'Nie udało się wczytać elementów. Sprawdź połączenie.';

  @override
  String get failedToSend =>
      'Nie udało się wysłać elementu. Sprawdź połączenie.';

  @override
  String get noUrlError => 'Adres URL serwera jest wymagany.';

  @override
  String get noTokenError => 'Token jest wymagany.';

  @override
  String get noHttpError => 'Musi zaczynać się od http:// lub https://';

  @override
  String get welcomeMessage => 'Połącz się z serwerem, aby zacząć.';

  @override
  String get connect => 'Połącz';

  @override
  String get credentialsInfo =>
      'Twoje dane logowania są przechowywane lokalnie i nigdy nie są udostępniane.';

  @override
  String get serverUrl => 'ADRES URL SERWERA';

  @override
  String get token => 'TOKEN';

  @override
  String get resetSetupSuccess => 'Konfiguracja została pomyślnie zresetowana.';

  @override
  String get justNow => 'teraz';

  @override
  String minutesAgo(Object count) {
    return '${count}m temu';
  }

  @override
  String hoursAgo(Object count) {
    return '${count}h temu';
  }

  @override
  String get yesterday => 'wczoraj';

  @override
  String get emptyDeviceNameError => 'Nazwa urządzenia nie może być pusta.';

  @override
  String get chooseLanguage => 'Wybierz język';

  @override
  String get systemDefault => 'Domyślny systemowy';

  @override
  String defaultDeviceNamePattern(Object platform) {
    return 'Urządzenie $platform';
  }

  @override
  String get defaultDeviceName => 'Moje urządzenie';
}
