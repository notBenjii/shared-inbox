// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get syncing => 'syncing...';

  @override
  String get notSyncedYet => 'not synced yet';

  @override
  String lastSynced(Object time) {
    return 'last synced: $time';
  }

  @override
  String get sendHint => 'Paste or type something...';

  @override
  String get emptyStateMessage =>
      'Nothing synced yet.\nSend something below to get started.';

  @override
  String get renameDeviceTitle => 'Rename device';

  @override
  String get renameDeviceHint => 'New device name';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get logout => 'Log out';

  @override
  String get failedToLoad => 'Failed to load items. Check your connection.';

  @override
  String get failedToSend => 'Failed to send item. Check your connection.';

  @override
  String get logoutSuccess => 'Logged out successfully.';

  @override
  String get justNow => 'just now';

  @override
  String minutesAgo(Object count) {
    return '${count}m ago';
  }

  @override
  String hoursAgo(Object count) {
    return '${count}h ago';
  }

  @override
  String get yesterday => 'yesterday';

  @override
  String get emptyDeviceNameError => 'Device name cannot be empty.';

  @override
  String get chooseLanguage => 'Choose language';

  @override
  String get systemDefault => 'System default';

  @override
  String defaultDeviceNamePattern(Object platform) {
    return '$platform Device';
  }

  @override
  String get defaultDeviceName => 'My device';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get deleteConfirmMessage =>
      'Are you sure you want to delete this item?';

  @override
  String get deleteConfirmTitle => 'Delete item';

  @override
  String get failedToDelete => 'Failed to delete item. Check your connection.';

  @override
  String get delete => 'Delete';

  @override
  String get showQrCode => 'Show QR code';

  @override
  String get failedToGenerateQrCode => 'Failed to generate QR code.';

  @override
  String get pairYourDevice => 'Pair your device';

  @override
  String get scanQrInstead => 'Scan QR code instead';

  @override
  String get failedToRedeemCode =>
      'Failed to redeem pairing code. Check your connection.';

  @override
  String get scanQrCode => 'Scan QR code';

  @override
  String get signInSubtitle => 'Sign in to continue';

  @override
  String get createAccountSubtitle => 'Create your account';

  @override
  String get emailLabel => 'EMAIL';

  @override
  String get passwordLabel => 'PASSWORD';

  @override
  String get nicknameLabel => 'NICKNAME';

  @override
  String get nicknameHint => 'yourname';

  @override
  String get passwordHintCreate => 'Min. 8 characters';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get signIn => 'Sign in';

  @override
  String get createAccount => 'Create account';

  @override
  String get noAccountPrompt => 'Don\'t have an account?';

  @override
  String get haveAccountPrompt => 'Already have an account?';

  @override
  String get createOne => 'Create one';

  @override
  String get emailRequiredError => 'Email is required.';

  @override
  String get passwordRequiredError => 'Password is required.';

  @override
  String get invalidEmailError => 'Enter a valid email address.';

  @override
  String get passwordTooShortError => 'Password must be at least 8 characters.';

  @override
  String get verifyEmailTitle => 'Verify your email';

  @override
  String get verifyEmailSubtitle => 'We sent a 6-digit code to';

  @override
  String get verifyEmail => 'Verify email';

  @override
  String resendCodeIn(int seconds) {
    return 'Didn\'t receive it? Resend in ${seconds}s';
  }

  @override
  String get resetPasswordTitle => 'Reset password';

  @override
  String get resetPasswordSubtitle =>
      'Enter your email and we\'ll send you a reset link';

  @override
  String get sendResetLink => 'Send reset link';

  @override
  String get backToSignIn => 'Back to sign in';

  @override
  String get back => 'Back';

  @override
  String get emailRegisteredError => 'This email is already registered.';

  @override
  String get genericError => 'Something went wrong. Please try again.';

  @override
  String get invalidCredentialsError => 'Invalid email or password.';

  @override
  String get rateLimitedGeneric => 'Too many requests. Please try again later.';

  @override
  String rateLimitedWithTime(int seconds) {
    return 'Too many attempts. Please try again in ${seconds}s.';
  }
}
