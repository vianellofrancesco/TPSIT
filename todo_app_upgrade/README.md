# zKeep – Documentazione

**Sviluppatore:** Francesco Vianello
**Classe:** 5IE

---

## Descrizione del progetto

zKeep è un'applicazione Flutter per la gestione di note con liste di cose da fare (todo). L'utente può creare note colorate, ognuna delle quali può contenere più todo. Ogni todo può essere spuntato come completato oppure eliminato. Le note e i todo vengono salvati in un database SQLite locale, così i dati persistono anche dopo la chiusura dell'app.

---

## Scelte di sviluppo

### Metodi

- **`DatabaseHelper.init`** → inizializza il database SQLite creando le tabelle `notes` e `todos` se non esistono già.
- **`DatabaseHelper.getNotes`** / **`getTodosForNote`** → recuperano rispettivamente le note e i todo associati a una nota dal database, restituendo liste di oggetti del modello.
- **`DatabaseHelper.insertNote`** / **`insertTodo`** → inseriscono un nuovo record nel database e restituiscono l'id generato automaticamente, usato poi per aggiornare lo stato dell'interfaccia.
- **`DatabaseHelper.updateTodo`** → aggiorna lo stato `checked` di un todo nel database quando l'utente lo spunta o lo deseleziona.
- **`DatabaseHelper.deleteNote`** / **`deleteTodo`** → eliminano un record dal database `deleteNote` elimina prima tutti i todo associati per rispettare il vincolo di chiave esterna.
- **`_addNewNote`** → mostra un `AlertDialog` per inserire il titolo della nuova nota, poi chiama `insertNote` e aggiorna lo stato con `setState`.
- **`_addTodoToNote`** → mostra un `AlertDialog` per inserire il testo del nuovo todo, poi chiama `insertTodo` e aggiunge il todo alla nota corrispondente nello stato.
- **`_toggleTodo`** → inverte il valore di `checked` di un todo e persiste la modifica chiamando `updateTodo`.
- **`_getRandomColor`** → seleziona un colore dalla lista predefinita in base all'indice corrente delle note, garantendo varietà visiva tra le card.

### Variabili

- **`_notes`** → lista di oggetti `Note` che rappresenta lo stato corrente dell'interfaccia; viene aggiornata ad ogni operazione tramite `setState`.
- **`Note.todos`** → lista di `Todo` contenuta all'interno di ogni `Note` non viene salvata nel database direttamente ma viene popolata al caricamento tramite una query separata sulla tabella `todos`.
- **`Note.color`** → colore di sfondo della card, salvato nel database come valore intero (`color.value`) e ricostruito con `Color(map['color'])` al momento della lettura.
- **`Todo.checked`** → unica proprietà mutabile del modello, modificata da `_toggleTodo`; è dichiarata senza `final` proprio per permetterne l'aggiornamento diretto.
