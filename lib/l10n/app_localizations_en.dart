// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Powerful Buddy';

  @override
  String get modeSelectionSubtitle => 'You build progress,\nbrick by brick.';

  @override
  String get modeSelectionQuestion => 'How do you build today?';

  @override
  String get modeOptionSoloTitle => 'Solo';

  @override
  String get modeOptionSoloSubtitle => 'Build on your own';

  @override
  String get modeOptionGroupTitle => 'Group';

  @override
  String get modeOptionGroupSubtitle => 'Build together';

  @override
  String get modeSelectionCta => 'LET\'S BUILD';

  @override
  String get backButton => 'Back';

  @override
  String get failedTitle => 'SESSION FAILED';

  @override
  String get failedMessageSolo => 'You left the app during Deep Building.';

  @override
  String get failedMessageGroup =>
      'Someone left the app during a Deep Building session.';

  @override
  String get failedCtaSolo => 'LET\'S BUILD AGAIN';

  @override
  String get failedCtaGroup => 'GO BACK';

  @override
  String get successTitle => 'Congrats!';

  @override
  String get successSubtitleSolo => 'You built a new brick';

  @override
  String get successSubtitleGroup => 'You built a new brick together';

  @override
  String get successMotivationSolo =>
      'Remember: every exam is built\none brick at a time.';

  @override
  String get successMotivationGroup =>
      'Great teamwork!\nEvery exam is built one brick at a time.';

  @override
  String get successCta => 'Keep building';

  @override
  String bricksBuiltCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# bricks built',
      one: '# brick built',
    );
    return '$_temp0';
  }

  @override
  String bricksCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# bricks',
      one: '# brick',
    );
    return '$_temp0';
  }

  @override
  String get setupTimeLabel => 'SET TIME';

  @override
  String get sessionWorkSoloLabel => 'FOCUS';

  @override
  String get sessionWorkGroupLabel => 'STUDY';

  @override
  String get sessionShortBreakLabel => 'BREAK';

  @override
  String get sessionLongBreakLabel => 'RELAX';

  @override
  String get stopLabel => 'STOP';

  @override
  String get startBuildLabel => 'LET\'S BUILD';

  @override
  String get startGroupLabel => 'START';

  @override
  String get createRoomLabel => 'CREATE ROOM';

  @override
  String get joinBrickLabel => 'Join the brick';

  @override
  String get joinRoomTitle => 'Join the brick';

  @override
  String get joinRoomPlaceholder => '9-digit code';

  @override
  String get cancelLabel => 'Cancel';

  @override
  String get joinLabel => 'Join';

  @override
  String get waitingLabel => 'WAITING';

  @override
  String get waitingSubtitle => 'The host will start the session';

  @override
  String get exitLabel => 'EXIT';

  @override
  String get exitRoomLabel => 'LEAVE ROOM';

  @override
  String shareRoomMessage(Object roomCode, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '# minutes',
      one: '# minute',
    );
    return 'Join my study session!\nCode: $roomCode\nDuration: $_temp0';
  }

  @override
  String get shareRoomSubject => 'Powerful Buddy room code';

  @override
  String get shareError => 'Share error';

  @override
  String get copySuccess => 'Message copied!';

  @override
  String get copyError => 'Copy failed';

  @override
  String get genericError => 'Something went wrong. Try again.';

  @override
  String get roomCreateFailed =>
      'Unable to create the room. Please try again later.';

  @override
  String get roomCreateError => 'Error while creating the room.';

  @override
  String get roomJoinInvalidCode => 'The room code is invalid.';

  @override
  String get roomNotFound => 'Room not found.';

  @override
  String get roomJoinFailed => 'Unable to join the room. Try again.';

  @override
  String get roomJoinError => 'Unexpected error while joining the room.';

  @override
  String get roomLeaveFailed => 'Unable to leave the room right now.';

  @override
  String get roomFetchError => 'Error while fetching the room.';

  @override
  String get roomCodeGenerateError => 'Could not generate a unique room code.';

  @override
  String get notificationBreakTitle => 'Break time!';

  @override
  String get notificationBreakBody => 'Great job! Enjoy a 5-minute break.';

  @override
  String get notificationWorkTitle => 'Back to work!';

  @override
  String get notificationWorkBody =>
      'Break is over. Let\'s build another brick!';

  @override
  String get notificationChannelName => 'Pomodoro Timer';

  @override
  String get notificationChannelDescription => 'Pomodoro timer notifications';

  @override
  String get chatSkillLabel => 'Mode';

  @override
  String get chatSkillSheetTitle => 'Study skill';

  @override
  String get chatSkillApply => 'Apply';

  @override
  String get chatSkillDefault => 'General';

  @override
  String get chatSkillAuto => 'Auto';

  @override
  String get chatSkillAutoRouting => 'Automatic routing';

  @override
  String get chatSkillAutoRoutingHint =>
      'The skill is chosen from your message (keywords). Turn off to pick manually.';
}
