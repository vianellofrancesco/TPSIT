
# CHRONO – Documentazione

  

**Sviluppatore:** Francesco Vianello

**Classe:** 5IE

  

## Descrizione del progetto

  

Chrono è un'applicazione Flutter che implementa un cronometro digitale. L'utente può avviare, fermare, resettare, mettere in pausa e riprendere il conteggio del tempo. Il cronometro visualizza i minuti e i secondi in formato MM:SS.

  

## Scelte di sviluppo

  

### Stream

  

**`_tickerStream()`** → genera un tick ogni 100 millisecondi

  

**`_secondsStream()`** → trasforma il flusso di tick in un flusso di secondi, emettendo un valore solo quando passa un secondo completo, ogni 10 tick

  

**`_subscription`** → gestisce l'ascolto dello stream, permettendo pause, resume e cancellazioni

  
  

### Enumerazioni

  

**`ChronoState`** → definisce i tre stati principali del cronometro.

**`PauseState`** → gestisce lo stato di pausa.


  

### Metodi principali

  

**`_startChrono()`** → avvia il cronometro creando lo stream di tick e secondi, si mette in ascolto tramite `_subscription` e aggiorna `_seconds` ad ogni nuovo valore emesso. Cambia lo stato a `ChronoState.stop`.

  

**`_stopChrono()`** → ferma il cronometro cancellando la subscription e cambia lo stato a `ChronoState.reset`, mantenendo il tempo visualizzato.

  

**`_resetChrono()`** → azzera il contatore riportando `_seconds` a 0 e ripristina lo stato iniziale `ChronoState.start`.

  

*  **`_pauseChrono()`** → mette in pausa lo stream chiamando `pause()` sulla subscription, congela il tempo senza perdere il conteggio.

  

*  **`_resumeChrono()`** → riprende lo stream chiamando `resume()` sulla subscription, il conteggio riprende da dove era stato interrotto.

  

*  **`_formatTime()`** → converte i secondi totali nel formato `MM:SS`.

  

*  **`_handleChronoButton()`** → gestisce la logica del pulsante principale tramite switch su `_chronoState`, eseguendo start, stop o reset.

  

*  **`_handlePauseButton()`** → gestisce la logica del pulsante pausa/riprendi, attivo solo quando il cronometro è in esecuzione (`ChronoState.stop`).

  

### Variabili

  

**`_seconds`** → contatore dei secondi trascorsi, inizializzato a 0 e aggiornato ogni secondo dallo stream.

  

**`_chronoState`** → stato corrente del cronometro, inizializzato a `ChronoState.start`.

  

**`_pauseState`** → stato di pausa, inizializzato a `PauseState.pause`.

  

**`_subscription`** → riferimento alla subscription dello stream.