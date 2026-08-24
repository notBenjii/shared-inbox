import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pl'),
  ];

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'syncing...'**
  String get syncing;

  /// No description provided for @notSyncedYet.
  ///
  /// In en, this message translates to:
  /// **'not synced yet'**
  String get notSyncedYet;

  /// No description provided for @lastSynced.
  ///
  /// In en, this message translates to:
  /// **'last synced: {time}'**
  String lastSynced(Object time);

  /// No description provided for @sendHint.
  ///
  /// In en, this message translates to:
  /// **'Paste or type something...'**
  String get sendHint;

  /// No description provided for @emptyStateMessage.
  ///
  /// In en, this message translates to:
  /// **'Nothing synced yet.\nSend something below to get started.'**
  String get emptyStateMessage;

  /// No description provided for @renameDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename device'**
  String get renameDeviceTitle;

  /// No description provided for @renameDeviceHint.
  ///
  /// In en, this message translates to:
  /// **'New device name'**
  String get renameDeviceHint;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @resetSetup.
  ///
  /// In en, this message translates to:
  /// **'Reset setup'**
  String get resetSetup;

  /// No description provided for @failedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load items. Check your connection.'**
  String get failedToLoad;

  /// No description provided for @failedToSend.
  ///
  /// In en, this message translates to:
  /// **'Failed to send item. Check your connection.'**
  String get failedToSend;

  /// No description provided for @noUrlError.
  ///
  /// In en, this message translates to:
  /// **'Server URL is required.'**
  String get noUrlError;

  /// No description provided for @noTokenError.
  ///
  /// In en, this message translates to:
  /// **'Token is required.'**
  String get noTokenError;

  /// No description provided for @noHttpError.
  ///
  /// In en, this message translates to:
  /// **'Must start with http:// or https://'**
  String get noHttpError;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Connect to your sync server to get started.'**
  String get welcomeMessage;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @credentialsInfo.
  ///
  /// In en, this message translates to:
  /// **'Your credentials are stored locally and never shared.'**
  String get credentialsInfo;

  /// No description provided for @serverUrl.
  ///
  /// In en, this message translates to:
  /// **'SERVER URL'**
  String get serverUrl;

  /// No description provided for @token.
  ///
  /// In en, this message translates to:
  /// **'TOKEN'**
  String get token;

  /// No description provided for @resetSetupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Setup reset successfully.'**
  String get resetSetupSuccess;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String minutesAgo(Object count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String hoursAgo(Object count);

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get yesterday;

  /// No description provided for @emptyDeviceNameError.
  ///
  /// In en, this message translates to:
  /// **'Device name cannot be empty.'**
  String get emptyDeviceNameError;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get chooseLanguage;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get systemDefault;

  /// No description provided for @defaultDeviceNamePattern.
  ///
  /// In en, this message translates to:
  /// **'{platform} Device'**
  String defaultDeviceNamePattern(Object platform);

  /// No description provided for @defaultDeviceName.
  ///
  /// In en, this message translates to:
  /// **'My device'**
  String get defaultDeviceName;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @deleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this item?'**
  String get deleteConfirmMessage;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete item'**
  String get deleteConfirmTitle;

  /// No description provided for @failedToDelete.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete item. Check your connection.'**
  String get failedToDelete;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pl':
      return AppLocalizationsPl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
