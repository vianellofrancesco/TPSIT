
# Chat Client – Documentazione  
Sviluppatore: Francesco Vianello  
Classe: 5IE  

## Descrizione del progetto  
Il progetto implementa un **client TCP in Dart** che permette a un utente di connettersi a una chatroom.  
Una volta connesso, il client invia l’username al server, riceve e stampa i messaggi provenienti dalla chat, e permette all’utente di inviare messaggi dalla console. La disconnessione può essere eseguita manualmente tramite il comando `/quit`.

---

## Scelte di sviluppo  
- Utilizzo della classe **Socket** per gestire la connessione TCP.  
- Ascolto continuo dei messaggi grazie a **socket.listen**, con gestione di *data*, *errori* e *chiusura della connessione*.  
- Uso dello stream di **stdin** per l’inserimento dei messaggi da parte dell’utente.  
- Trasformazioni UTF-8 sia in input che in output per evitare problemi di encoding.  
- Chiusura controllata del client tramite `disconnect()`.

---

## Metodi principali  

### `Future<void> connect(String host, int port, String user)`  
- Stabilisce la connessione TCP al server.  
- Salva l’username e lo invia immediatamente al server.  
- Registra il listener dei messaggi in arrivo tramite `socket.listen`.  
- Gestisce errori, chiusura della connessione ed exit.  
- Attiva un listener su `stdin` per invio dei messaggi digitati dall’utente.  
- Riconosce il comando `/quit` per la disconnessione.

---

### `void disconnect()`  
- Chiude la connessione TCP tramite `socket.close()`.  
- Stampa un messaggio di chiusura.  
- Termina l’esecuzione del client.

