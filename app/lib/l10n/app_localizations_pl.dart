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

  @override
  String get copiedToClipboard => 'Skopiowano do schowka';

  @override
  String get deleteConfirmMessage => 'Czy na pewno chcesz usunąć ten element?';

  @override
  String get deleteConfirmTitle => 'Usuń element';

  @override
  String get failedToDelete =>
      'Nie udało się usunąć elementu. Sprawdź połączenie.';

  @override
  String get delete => 'Usuń';

  @override
  String get showQrCode => 'Pokaż kod QR';

  @override
  String get failedToGenerateQrCode => 'Nie udało się wygenerować kodu QR.';

  @override
  String get pairYourDevice => 'Sparuj swoje urządzenie';

  @override
  String get scanQrInstead => 'Zeskanuj kod QR';

  @override
  String get failedToRedeemCode =>
      'Nie udało się zrealizować kodu parowania. Sprawdź połączenie.';

  @override
  String get scanQrCode => 'Zeskanuj kod QR';

  @override
  String get signInSubtitle => 'Zaloguj się, aby kontynuować';

  @override
  String get createAccountSubtitle => 'Utwórz swoje konto';

  @override
  String get emailLabel => 'EMAIL';

  @override
  String get passwordLabel => 'HASŁO';

  @override
  String get nicknameLabel => 'NAZWA';

  @override
  String get nicknameHint => 'twojanazwa';

  @override
  String get passwordHintCreate => 'Min. 8 znaków';

  @override
  String get forgotPassword => 'Nie pamiętasz hasła?';

  @override
  String get signIn => 'Zaloguj się';

  @override
  String get createAccount => 'Utwórz konto';

  @override
  String get noAccountPrompt => 'Nie masz konta?';

  @override
  String get haveAccountPrompt => 'Masz już konto?';

  @override
  String get createOne => 'Utwórz je';

  @override
  String get emailRequiredError => 'Email jest wymagany.';

  @override
  String get passwordRequiredError => 'Hasło jest wymagane.';

  @override
  String get invalidEmailError => 'Wprowadź poprawny adres email.';

  @override
  String get passwordTooShortError => 'Hasło musi mieć co najmniej 8 znaków.';

  @override
  String get verifyEmailTitle => 'Zweryfikuj swój email';

  @override
  String get verifyEmailSubtitle => 'Wysłaliśmy 6-cyfrowy kod na';

  @override
  String get verifyEmail => 'Zweryfikuj email';

  @override
  String resendCodeIn(int seconds) {
    return 'Nie otrzymałeś kodu? Wyślij ponownie za ${seconds}s';
  }

  @override
  String get resetPasswordTitle => 'Zresetuj hasło';

  @override
  String get resetPasswordSubtitle =>
      'Wprowadź swój email, a wyślemy link do resetowania hasła';

  @override
  String get sendResetLink => 'Wyślij link resetujący';

  @override
  String get backToSignIn => 'Powrót do logowania';

  @override
  String get back => 'Wstecz';

  @override
  String get emailRegisteredError => 'Ten adres email jest już zarejestrowany.';

  @override
  String get genericError => 'Coś poszło nie tak. Spróbuj ponownie.';
}
