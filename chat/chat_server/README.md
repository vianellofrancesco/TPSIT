# Flutter Chat Client – Documentazione  
Sviluppatore: Francesco Vianello  
Classe: 5IE  

## Descrizione del progetto  
Il progetto implementa un **client Flutter** che si connette a un server TCP per partecipare a una chatroom multi-utente.  
L’app permette a un utente di:

- Inserire username, host e porta  
- Stabilire una connessione TCP con il server  
- Inviare e ricevere messaggi in tempo reale  
- Gestire disconnessioni e riconnessioni  

L’interfaccia è composta da una schermata di login e da una schermata chat con lista messaggi e input.

---

## Scelte di sviluppo  
- Uso della classe **Socket** del package `dart:io` per creare una connessione TCP.  
- Invio automatico dello username al server come primo messaggio.  
- Gestione asincrona della ricezione dati tramite `socket.listen()`.  
- Aggiornamento dell’interfaccia in tempo reale grazie a `setState`.  
- Ritorno alla schermata di login in caso di disconnessione o errore.  
- Organizzazione a due schermate:
  - `LoginScreen` per la connessione  
  - `ChatScreen` per la chat vera e propria  

---

## Struttura del progetto  

### `main()`  
Avvia l’app caricando `ChatApp`, che a sua volta mostra la `LoginScreen`.

---

### `LoginScreen`  
Permette di inserire:

- Username  
- Host  
- Porta  

#### Funzionalità principali  
- **_connect()**:  
  - Valida lo username  
  - Tenta la connessione TCP con `Socket.connect()`  
  - In caso di successo apre la `ChatScreen`  
  - In caso di errore mostra un messaggio tramite `SnackBar`  

---

### `ChatScreen`  
Gestisce la chat vera e propria.

#### Avvio  
- Invia lo username al server al `initState()`  
- Avvia `socket.listen()` per:
  - ricevere messaggi
  - gestire disconnessioni  
- I messaggi ricevuti vengono decodificati in UTF-8 e mostrati nella lista `_messages`.

#### Invio messaggi  
Metodo **_send()**:
- Invia il testo al server aggiungendo newline `\n`  
- Mostra localmente il messaggio come “Tu: ...”  
- Svuota l’input field  

#### Chiusura  
Nel `dispose()`:
- Chiude la connessione con `socket.close()`  
- Libera le risorse della `TextEditingController`

