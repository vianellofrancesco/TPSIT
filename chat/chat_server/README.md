
# Chat Server – Documentazione  
Sviluppatore: Francesco Vianello  
Classe: 5IE  

## Descrizione del progetto  
Il progetto implementa un **server TCP in Dart** che gestisce una chatroom multi-utente.  
Ogni client che si connette invia come primo messaggio il proprio username, dopodiché può inviare messaggi che il server redistribuisce a tutti gli altri utenti tramite un sistema di broadcast.

Il server gestisce connessioni multiple, registra automaticamente i partecipanti, rileva disconnessioni e gestisce errori di comunicazione.

---

## Scelte di sviluppo  
- Utilizzo di **ServerSocket.bind** per creare un server TCP su IPv4.  
- Memorizzazione dei client con una **Map<Socket, String>** che associa socket a un username.  
- Utilizzo di **client.listen** per gestire i messaggi ricevuti, disconnessioni ed errori.  
- Funzione `broadcast()` per inviare messaggi a tutti i client tranne quello che li ha generati.  
- Gestione automatica di:
  - registrazione username al primo messaggio  
  - join e leave della chat  
  - chiusura dei socket e pulizia risorse  

---

## Metodi principali  

### `Future<void> start()`  
- Avvia il server sulla porta definita.  
- Stampa IP e porta su cui è in ascolto.  
- Rimane in attesa di connessioni tramite ciclo `await for`.  
- Per ogni nuova connessione richiama `handleClient`.

---

### `void handleClient(Socket client)`  
Gestisce completamente l'interazione con un singolo client:

- Attende il primo messaggio, interpretato come username.  
- Registra il client nella mappa `clients`.  
- Per ogni altro messaggio ricevuto:  
  - lo stampa lato server  
  - lo inoltra tramite `broadcast()`  
- Gestisce:
  - disconnessioni volontarie o improvvise  
  - errori lato socket  
  - pulizia dell’utente rimosso  

---

### `void broadcast(String message, {Socket? exclude})`  
Invia un messaggio a tutti i client attivi, tranne quello indicato in `exclude`.  
Aggiunge automaticamente newline per il corretto parsing lato client.  
Gestisce eventuali errori in scrittura su singoli socket.

---

### `void stop()`  
- Chiude il server.  
- Chiude tutti i socket dei client.  
- Svuota la lista dei partecipanti.  
- Stampa conferma di arresto.
