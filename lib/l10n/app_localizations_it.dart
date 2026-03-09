// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Powerful Buddy';

  @override
  String get modeSelectionSubtitle =>
      'Tutto si costruisce\nun mattoncino alla volta.';

  @override
  String get modeSelectionQuestion => 'Come vuoi costruire oggi?';

  @override
  String get modeOptionSoloTitle => 'Solo';

  @override
  String get modeOptionSoloSubtitle => 'Costruisci individualmente';

  @override
  String get modeOptionGroupTitle => 'Group';

  @override
  String get modeOptionGroupSubtitle => 'Costruisci in compagnia';

  @override
  String get modeSelectionCta => 'INIZIA A COSTRUIRE';

  @override
  String get backButton => 'Indietro';

  @override
  String get failedTitle => 'SESSIONE FALLITA';

  @override
  String get failedMessageSolo =>
      'Hai lasciato l\'app durante una sessione di Deep Building.';

  @override
  String get failedMessageGroup =>
      'Qualcuno ha lasciato l\'app durante una sessione di Deep Building.';

  @override
  String get failedCtaSolo => 'RIPROVA A COSTRUIRE';

  @override
  String get failedCtaGroup => 'TORNA INDIETRO';

  @override
  String get successTitle => 'Complimenti!';

  @override
  String get successSubtitleSolo => 'Hai costruito un nuovo mattoncino';

  @override
  String get successSubtitleGroup => 'Avete costruito un nuovo mattoncino';

  @override
  String get successMotivationSolo =>
      'Ricorda: ogni esame si prepara\nun mattoncino alla volta.';

  @override
  String get successMotivationGroup =>
      'Ottimo lavoro di squadra!\nOgni esame si prepara un mattoncino alla volta.';

  @override
  String get successCta => 'Continua a costruire';

  @override
  String bricksBuiltCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# mattoncini costruiti',
      one: '# mattoncino costruito',
    );
    return '$_temp0';
  }

  @override
  String bricksCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# mattoncini',
      one: '# mattoncino',
    );
    return '$_temp0';
  }

  @override
  String get setupTimeLabel => 'IMPOSTA TEMPO';

  @override
  String get sessionWorkSoloLabel => 'CONCENTRATI';

  @override
  String get sessionWorkGroupLabel => 'STUDIO';

  @override
  String get sessionShortBreakLabel => 'PAUSA';

  @override
  String get sessionLongBreakLabel => 'RELAX';

  @override
  String get stopLabel => 'STOP';

  @override
  String get startBuildLabel => 'INIZIA A COSTRUIRE';

  @override
  String get startGroupLabel => 'INIZIA';

  @override
  String get createRoomLabel => 'CREA STANZA';

  @override
  String get joinBrickLabel => 'Unisciti al mattoncino';

  @override
  String get joinRoomTitle => 'Unisciti al mattoncino';

  @override
  String get joinRoomPlaceholder => 'Codice a 9 cifre';

  @override
  String get cancelLabel => 'Annulla';

  @override
  String get joinLabel => 'Unisciti';

  @override
  String get waitingLabel => 'IN ATTESA';

  @override
  String get waitingSubtitle => 'L\'host avvierà la sessione';

  @override
  String get exitLabel => 'ESCI';

  @override
  String get exitRoomLabel => 'ESCI DALLA STANZA';

  @override
  String shareRoomMessage(Object roomCode, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '# minuti',
      one: '# minuto',
    );
    return 'Unisciti alla mia sessione di studio!\nCodice: $roomCode\nDurata: $_temp0';
  }

  @override
  String get shareRoomSubject => 'Codice stanza Powerful Buddy';

  @override
  String get shareError => 'Errore nella condivisione';

  @override
  String get copySuccess => 'Messaggio copiato!';

  @override
  String get copyError => 'Errore nella copia';

  @override
  String get genericError => 'Si è verificato un errore. Riprova.';

  @override
  String get roomCreateFailed =>
      'Impossibile creare la stanza. Riprova più tardi.';

  @override
  String get roomCreateError => 'Errore durante la creazione della stanza.';

  @override
  String get roomJoinInvalidCode => 'Il codice stanza non è valido.';

  @override
  String get roomNotFound => 'Stanza non trovata.';

  @override
  String get roomJoinFailed => 'Impossibile entrare nella stanza. Riprova.';

  @override
  String get roomJoinError =>
      'Errore sconosciuto durante l\'accesso alla stanza.';

  @override
  String get roomLeaveFailed =>
      'Impossibile uscire dalla stanza in questo momento.';

  @override
  String get roomFetchError => 'Errore nel recupero della stanza.';

  @override
  String get roomCodeGenerateError =>
      'Non è stato possibile generare un codice stanza univoco.';

  @override
  String get notificationBreakTitle => 'Tempo di pausa!';

  @override
  String get notificationBreakBody =>
      'Ottimo lavoro! Goditi una pausa di 5 minuti.';

  @override
  String get notificationWorkTitle => 'Tempo di studiare!';

  @override
  String get notificationWorkBody =>
      'La pausa è finita. Iniziamo un nuovo pomodoro!';

  @override
  String get notificationChannelName => 'Pomodoro Timer';

  @override
  String get notificationChannelDescription =>
      'Notifiche per il timer Pomodoro';
}
