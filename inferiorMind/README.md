# INFERIOR MIND – Documentazione

**Sviluppatore:** Francesco Vianello  
**Classe:** 5IE  

## Descrizione del progetto
Inferior Mind è un’applicazione che implementa un gioco in cui l’utente deve indovinare una sequenza di quattro colori.  
I colori sono rappresentati su quattro pulsanti che, quando premuti, cambiano colore.  
Quando l’utente pensa di aver indovinato la combinazione, può premere il pulsante **“Invio”**.  
Se la sequenza è corretta, viene mostrato un messaggio di vittoria; altrimenti, i pulsanti vengono resettati e l’utente può provare nuovamente.



## Scelte di sviluppo

### Metodi
- **generateColorSetToGuess** --> utilizza Random per selezionare colori dalla lista availableColors la lista generata viene salvata in colorSetToGuess.  
- **changeColor** --> cambia gli indici nella lista buttonsColors, modificando il colore dei pulsanti e aggiornando l’UI.  
- **checkVictory** --> incrementa il contatore dei tentativi di 1, verifica se la sequenza di colori in buttonsColors corrisponde a colorSetToGuess. Se la sequenza corrisponde, mostra un messaggio di vittoria e resetta il gioco invece se non corrisponde, resetta i pulsanti.

### Variabili
- **availableColors** --> lista dei colori possibili, dichiarata static const perché appartiene alla classe, è immutabile e nota a compile-time.  
- **buttonsColors** --> lista in cui ogni indice rappresenta uno dei quattro pulsanti e il colore corrispondente.  
- **colorSetToGuess** --> lista contenente la sequenza di colori da indovinare; dichiarata late perché inizializzata dopo la creazione dello stato.  
- **count** --> tiene traccia del numero di tentativi effettuati.
