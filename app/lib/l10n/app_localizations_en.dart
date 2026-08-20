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
  String get resetSetup => 'Reset setup';

  @override
  String get failedToLoad => 'Failed to load items. Check your connection.';

  @override
  String get failedToSend => 'Failed to send item. Check your connection.';

  @override
  String get noUrlError => 'Server URL is required.';

  @override
  String get noTokenError => 'Token is required.';

  @override
  String get noHttpError => 'Must start with http:// or https://';

  @override
  String get welcomeMessage => 'Connect to your sync server to get started.';

  @override
  String get connect => 'Connect';

  @override
  String get credentialsInfo =>
      'Your credentials are stored locally and never shared.';

  @override
  String get serverUrl => 'SERVER URL';

  @override
  String get token => 'TOKEN';

  @override
  String get resetSetupSuccess => 'Setup reset successfully.';

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
  String get yesterday => 'Yesterday';

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
}
