# Code Review Completa - Errori e Problemi Trovati

## 🔴 ERRORI CRITICI

### 1. **resumeTimer() non riprogramma la notifica**
**File**: `lib/providers/pomodoro_provider.dart:368-372`
**Problema**: Quando il timer viene ripreso dopo una pausa, la notifica programmata è ancora quella vecchia con il tempo sbagliato. La notifica scatterà al momento sbagliato.
```dart
void resumeTimer() {
  if (!_isRunning && _currentSession != null) {
    _startTimer(); // Questo riprogramma la notifica, ma con il tempo sbagliato!
  }
}
```
**Impatto**: La notifica potrebbe scattare prima o dopo il tempo corretto.
**Soluzione**: Quando si riprende il timer, bisogna ricalcolare il tempo rimanente e riprogrammare la notifica con il nuovo tempo.

---

### 2. **_playNotificationSound() fallback non gestito**
**File**: `lib/providers/pomodoro_provider.dart:303-310`
**Problema**: Se anche `beep.mp3` non esiste, il secondo `play()` può crashare.
```dart
try {
  await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
} catch (e) {
  // Se il file audio non esiste, usa un beep di sistema
  await _audioPlayer.play(AssetSource('sounds/beep.mp3')); // ⚠️ Può crashare!
}
```
**Impatto**: Crash se entrambi i file audio mancano.
**Soluzione**: Aggiungere un try-catch anche per il fallback o verificare che i file esistano.

---

### 3. **Race condition nel callback delle notifiche**
**File**: `lib/providers/pomodoro_provider.dart:64-78`
**Problema**: `_currentSession` può essere modificato o reso null durante il delay di 1 secondo. Il riferimento viene catturato ma potrebbe essere obsoleto.
```dart
Future.delayed(const Duration(milliseconds: 1000), () {
  if (_currentSession != null) { // ⚠️ Potrebbe essere cambiato!
    if (_currentSession!.isCompleted) {
      _handleSessionComplete();
    }
  }
});
```
**Impatto**: Comportamento imprevedibile se la sessione viene modificata durante il delay.
**Soluzione**: Salvare una copia locale della sessione o verificare che sia ancora valida.

---

### 4. **TextEditingController dispose nel dialog**
**File**: `lib/screens/group_room_screen.dart:94`
**Problema**: Il controller viene dispose prima che il dialog sia completamente chiuso, potrebbe causare errori se il dialog prova ad accedervi.
```dart
controller.dispose(); // ⚠️ Dispose troppo presto
Navigator.of(context).pop();
```
**Impatto**: Possibile crash se il dialog prova ad accedere al controller dopo dispose.
**Soluzione**: Dispose il controller dopo che il dialog è chiuso o usare un callback.

---

## 🟡 ERRORI MEDI

### 5. **handleAppResumed() non riprende il timer se non è running**
**File**: `lib/providers/pomodoro_provider.dart:422-434`
**Problema**: Se l'app torna in foreground e il timer è in pausa, non viene riavviato automaticamente. L'utente deve riprenderlo manualmente.
```dart
void handleAppResumed() {
  if (_currentSession != null && _isRunning) { // ⚠️ Solo se _isRunning
    // ...
  }
}
```
**Impatto**: UX confusa - il timer potrebbe essere in pausa quando l'app torna in foreground.
**Soluzione**: Gestire anche il caso in cui il timer è in pausa.

---

### 6. **Possibile memory leak con Future.delayed**
**File**: `lib/providers/pomodoro_provider.dart:64`
**Problema**: Se il provider viene dispose durante il delay di 1 secondo, il callback viene comunque eseguito e prova ad accedere a `_currentSession` che potrebbe non essere più valido.
**Impatto**: Memory leak e possibili crash.
**Soluzione**: Salvare un riferimento al provider o verificare che sia ancora valido.

---

### 7. **Notifiche programmate multiple**
**File**: `lib/providers/pomodoro_provider.dart:181-263`
**Problema**: Se `_scheduleCompletionNotification()` viene chiamato più volte rapidamente (es. start/pause/start), vengono programmate più notifiche con lo stesso ID (0), ma potrebbero sovrapporsi.
**Impatto**: Notifiche duplicate o comportamento imprevedibile.
**Soluzione**: Cancellare sempre la notifica precedente prima di programmarne una nuova (già fatto in `_startTimer()`, ma verificare che funzioni).

---

### 8. **Timer continua dopo dispose se chiamato durante esecuzione**
**File**: `lib/providers/pomodoro_provider.dart:170-177`
**Problema**: Se `dispose()` viene chiamato mentre il timer è in esecuzione, il callback del timer potrebbe ancora essere chiamato dopo dispose.
```dart
_timer = Timer.periodic(const Duration(seconds: 1), (timer) {
  notifyListeners(); // ⚠️ Può essere chiamato dopo dispose!
  if (_currentSession?.isCompleted ?? false) {
    _handleSessionComplete();
  }
});
```
**Impatto**: Crash o comportamento imprevedibile.
**Soluzione**: Verificare che il provider sia ancora valido nel callback del timer.

---

### 9. **AudioPlayer può essere usato dopo dispose**
**File**: `lib/providers/pomodoro_provider.dart:303-310, 437-440`
**Problema**: Se `_playNotificationSound()` viene chiamato mentre il provider viene dispose, l'AudioPlayer potrebbe essere già dispose.
**Impatto**: Crash.
**Soluzione**: Verificare che l'AudioPlayer sia ancora valido prima di usarlo.

---

### 10. **handleAppResumed() chiama _handleSessionComplete() che può avviare un nuovo timer**
**File**: `lib/providers/pomodoro_provider.dart:422-434`
**Problema**: Se il timer è scaduto mentre l'app era in background, `handleAppResumed()` chiama `_handleSessionComplete()` che avvia automaticamente una nuova sessione. Questo potrebbe non essere il comportamento desiderato.
**Impatto**: UX confusa - una nuova sessione parte automaticamente.
**Soluzione**: Considerare se questo è il comportamento desiderato o se l'utente dovrebbe confermare.

---

## 🟢 PROBLEMI MINORI

### 11. **Mancanza di validazione nel joinRoom()**
**File**: `lib/providers/room_provider.dart:35-39`
**Problema**: `joinRoom()` accetta qualsiasi stringa senza validazione. Dovrebbe usare `isValidRoomCode()`.
```dart
void joinRoom(String code) {
  _currentRoomCode = code.toUpperCase(); // ⚠️ Nessuna validazione
  // ...
}
```
**Impatto**: Codici stanza non validi possono essere accettati.
**Soluzione**: Validare il codice prima di impostarlo.

---

### 12. **Race condition in _handleSessionComplete()**
**File**: `lib/providers/pomodoro_provider.dart:275-300`
**Problema**: `_handleSessionComplete()` può essere chiamato più volte contemporaneamente (dal timer e dal callback delle notifiche), causando comportamenti duplicati.
**Impatto**: Vibrazione/audio/notifiche duplicate.
**Soluzione**: Aggiungere un flag per prevenire chiamate multiple.

---

### 13. **Mancanza di gestione errori in Vibration.vibrate()**
**File**: `lib/providers/pomodoro_provider.dart:280`
**Problema**: `Vibration.vibrate()` può fallire su alcuni dispositivi, ma non è gestito.
**Impatto**: Possibile crash su dispositivi che non supportano la vibrazione.
**Soluzione**: Aggiungere try-catch.

---

### 14. **didChangeDependencies() può essere chiamato più volte**
**File**: `lib/main.dart:58-74`
**Problema**: `didChangeDependencies()` può essere chiamato più volte, e ogni volta prova ad aggiungere l'observer se non è già stato aggiunto. Anche se c'è un controllo, potrebbe essere chiamato prima che `mounted` sia true.
**Impatto**: Possibile aggiunta multipla dell'observer (anche se protetto da flag).
**Soluzione**: Verificare meglio le condizioni.

---

### 15. **Mancanza di gestione errori in Share.share()**
**File**: `lib/screens/group_room_screen.dart:18-23`
**Problema**: `Share.share()` può fallire, ma non è gestito.
**Impatto**: Crash se la condivisione fallisce.
**Soluzione**: Aggiungere try-catch.

---

### 16. **Mancanza di gestione errori in Clipboard.setData()**
**File**: `lib/screens/group_room_screen.dart:25-33`
**Problema**: `Clipboard.setData()` può fallire, ma non è gestito.
**Impatto**: Crash se la clipboard non è disponibile.
**Soluzione**: Aggiungere try-catch.

---

### 17. **Possibile divisione per zero in progress**
**File**: `lib/models/study_session.dart:124`
**Problema**: Se `duration` è 0, `remainingTime / duration` causa divisione per zero.
```dart
double get progress => 1.0 - (remainingTime / duration); // ⚠️ Se duration == 0
```
**Impatto**: Crash se duration è 0.
**Soluzione**: Gestire il caso duration == 0.

---

### 18. **Mancanza di notificaListeners() in alcuni metodi**
**File**: `lib/providers/pomodoro_provider.dart`
**Problema**: Alcuni metodi modificano lo stato ma non chiamano `notifyListeners()`. Verificare tutti i metodi.
**Impatto**: UI non aggiornata.
**Soluzione**: Verificare che tutti i metodi che modificano lo stato chiamino `notifyListeners()`.

---

## 📋 RACCOMANDAZIONI

1. **Aggiungere logging dettagliato** per tracciare il flusso di esecuzione
2. **Aggiungere test unitari** per i provider
3. **Aggiungere test widget** per le screen
4. **Documentare i metodi pubblici** con commenti
5. **Aggiungere validazione** per tutti gli input utente
6. **Gestire tutti gli errori** con try-catch appropriati
7. **Verificare memory leaks** con strumenti di profiling
8. **Aggiungere timeout** per operazioni asincrone

---

## 🎯 PRIORITÀ DI RISOLUZIONE

1. **CRITICA**: resumeTimer() non riprogramma la notifica correttamente
2. **CRITICA**: _playNotificationSound() fallback non gestito
3. **CRITICA**: Race condition nel callback delle notifiche
4. **CRITICA**: TextEditingController dispose nel dialog
5. **MEDIA**: handleAppResumed() non riprende il timer se in pausa
6. **MEDIA**: Possibile memory leak con Future.delayed
7. **MEDIA**: Timer continua dopo dispose
8. **MEDIA**: AudioPlayer può essere usato dopo dispose
9. **BASSA**: Altri problemi minori


