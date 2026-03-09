import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

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
    Locale('it'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Powerful Buddy'**
  String get appTitle;

  /// No description provided for @modeSelectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You build progress,\nbrick by brick.'**
  String get modeSelectionSubtitle;

  /// No description provided for @modeSelectionQuestion.
  ///
  /// In en, this message translates to:
  /// **'How do you build today?'**
  String get modeSelectionQuestion;

  /// No description provided for @modeOptionSoloTitle.
  ///
  /// In en, this message translates to:
  /// **'Solo'**
  String get modeOptionSoloTitle;

  /// No description provided for @modeOptionSoloSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Build on your own'**
  String get modeOptionSoloSubtitle;

  /// No description provided for @modeOptionGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get modeOptionGroupTitle;

  /// No description provided for @modeOptionGroupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Build together'**
  String get modeOptionGroupSubtitle;

  /// No description provided for @modeSelectionCta.
  ///
  /// In en, this message translates to:
  /// **'LET\'S BUILD'**
  String get modeSelectionCta;

  /// No description provided for @backButton.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backButton;

  /// No description provided for @failedTitle.
  ///
  /// In en, this message translates to:
  /// **'SESSION FAILED'**
  String get failedTitle;

  /// No description provided for @failedMessageSolo.
  ///
  /// In en, this message translates to:
  /// **'You left the app during Deep Building.'**
  String get failedMessageSolo;

  /// No description provided for @failedMessageGroup.
  ///
  /// In en, this message translates to:
  /// **'Someone left the app during a Deep Building session.'**
  String get failedMessageGroup;

  /// No description provided for @failedCtaSolo.
  ///
  /// In en, this message translates to:
  /// **'LET\'S BUILD AGAIN'**
  String get failedCtaSolo;

  /// No description provided for @failedCtaGroup.
  ///
  /// In en, this message translates to:
  /// **'GO BACK'**
  String get failedCtaGroup;

  /// No description provided for @successTitle.
  ///
  /// In en, this message translates to:
  /// **'Congrats!'**
  String get successTitle;

  /// No description provided for @successSubtitleSolo.
  ///
  /// In en, this message translates to:
  /// **'You built a new brick'**
  String get successSubtitleSolo;

  /// No description provided for @successSubtitleGroup.
  ///
  /// In en, this message translates to:
  /// **'You built a new brick together'**
  String get successSubtitleGroup;

  /// No description provided for @successMotivationSolo.
  ///
  /// In en, this message translates to:
  /// **'Remember: every exam is built\none brick at a time.'**
  String get successMotivationSolo;

  /// No description provided for @successMotivationGroup.
  ///
  /// In en, this message translates to:
  /// **'Great teamwork!\nEvery exam is built one brick at a time.'**
  String get successMotivationGroup;

  /// No description provided for @successCta.
  ///
  /// In en, this message translates to:
  /// **'Keep building'**
  String get successCta;

  /// No description provided for @bricksBuiltCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{# brick built} other{# bricks built}}'**
  String bricksBuiltCount(int count);

  /// No description provided for @bricksCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{# brick} other{# bricks}}'**
  String bricksCountLabel(int count);

  /// No description provided for @setupTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'SET TIME'**
  String get setupTimeLabel;

  /// No description provided for @sessionWorkSoloLabel.
  ///
  /// In en, this message translates to:
  /// **'FOCUS'**
  String get sessionWorkSoloLabel;

  /// No description provided for @sessionWorkGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'STUDY'**
  String get sessionWorkGroupLabel;

  /// No description provided for @sessionShortBreakLabel.
  ///
  /// In en, this message translates to:
  /// **'BREAK'**
  String get sessionShortBreakLabel;

  /// No description provided for @sessionLongBreakLabel.
  ///
  /// In en, this message translates to:
  /// **'RELAX'**
  String get sessionLongBreakLabel;

  /// No description provided for @stopLabel.
  ///
  /// In en, this message translates to:
  /// **'STOP'**
  String get stopLabel;

  /// No description provided for @startBuildLabel.
  ///
  /// In en, this message translates to:
  /// **'LET\'S BUILD'**
  String get startBuildLabel;

  /// No description provided for @startGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get startGroupLabel;

  /// No description provided for @createRoomLabel.
  ///
  /// In en, this message translates to:
  /// **'CREATE ROOM'**
  String get createRoomLabel;

  /// No description provided for @joinBrickLabel.
  ///
  /// In en, this message translates to:
  /// **'Join the brick'**
  String get joinBrickLabel;

  /// No description provided for @joinRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'Join the brick'**
  String get joinRoomTitle;

  /// No description provided for @joinRoomPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'9-digit code'**
  String get joinRoomPlaceholder;

  /// No description provided for @cancelLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelLabel;

  /// No description provided for @joinLabel.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get joinLabel;

  /// No description provided for @waitingLabel.
  ///
  /// In en, this message translates to:
  /// **'WAITING'**
  String get waitingLabel;

  /// No description provided for @waitingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The host will start the session'**
  String get waitingSubtitle;

  /// No description provided for @exitLabel.
  ///
  /// In en, this message translates to:
  /// **'EXIT'**
  String get exitLabel;

  /// No description provided for @exitRoomLabel.
  ///
  /// In en, this message translates to:
  /// **'LEAVE ROOM'**
  String get exitRoomLabel;

  /// No description provided for @shareRoomMessage.
  ///
  /// In en, this message translates to:
  /// **'Join my study session!\nCode: {roomCode}\nDuration: {minutes, plural, one{# minute} other{# minutes}}'**
  String shareRoomMessage(Object roomCode, int minutes);

  /// No description provided for @shareRoomSubject.
  ///
  /// In en, this message translates to:
  /// **'Powerful Buddy room code'**
  String get shareRoomSubject;

  /// No description provided for @shareError.
  ///
  /// In en, this message translates to:
  /// **'Share error'**
  String get shareError;

  /// No description provided for @copySuccess.
  ///
  /// In en, this message translates to:
  /// **'Message copied!'**
  String get copySuccess;

  /// No description provided for @copyError.
  ///
  /// In en, this message translates to:
  /// **'Copy failed'**
  String get copyError;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get genericError;

  /// No description provided for @roomCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to create the room. Please try again later.'**
  String get roomCreateFailed;

  /// No description provided for @roomCreateError.
  ///
  /// In en, this message translates to:
  /// **'Error while creating the room.'**
  String get roomCreateError;

  /// No description provided for @roomJoinInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'The room code is invalid.'**
  String get roomJoinInvalidCode;

  /// No description provided for @roomNotFound.
  ///
  /// In en, this message translates to:
  /// **'Room not found.'**
  String get roomNotFound;

  /// No description provided for @roomJoinFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to join the room. Try again.'**
  String get roomJoinFailed;

  /// No description provided for @roomJoinError.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error while joining the room.'**
  String get roomJoinError;

  /// No description provided for @roomLeaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to leave the room right now.'**
  String get roomLeaveFailed;

  /// No description provided for @roomFetchError.
  ///
  /// In en, this message translates to:
  /// **'Error while fetching the room.'**
  String get roomFetchError;

  /// No description provided for @roomCodeGenerateError.
  ///
  /// In en, this message translates to:
  /// **'Could not generate a unique room code.'**
  String get roomCodeGenerateError;

  /// No description provided for @notificationBreakTitle.
  ///
  /// In en, this message translates to:
  /// **'Break time!'**
  String get notificationBreakTitle;

  /// No description provided for @notificationBreakBody.
  ///
  /// In en, this message translates to:
  /// **'Great job! Enjoy a 5-minute break.'**
  String get notificationBreakBody;

  /// No description provided for @notificationWorkTitle.
  ///
  /// In en, this message translates to:
  /// **'Back to work!'**
  String get notificationWorkTitle;

  /// No description provided for @notificationWorkBody.
  ///
  /// In en, this message translates to:
  /// **'Break is over. Let\'s build another brick!'**
  String get notificationWorkBody;

  /// No description provided for @notificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro Timer'**
  String get notificationChannelName;

  /// No description provided for @notificationChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro timer notifications'**
  String get notificationChannelDescription;
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
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
