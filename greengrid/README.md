# GreenGrid — Monitoraggio Intensità Carbonica Reti Elettriche

**Sviluppatore:** Francesco Vianello

---

## Descrizione

GreenGrid è un’app mobile in Flutter con backend REST in PHP e MySQL. L’app offre un modo semplice per monitorare l’intensità di carbonio delle reti elettriche in diverse aree del mondo.

L’utente può:
- salvare le zone di interesse con etichette personalizzate e note
- visualizzare il mix energetico in tempo reale
- consultare lo storico

I dati provengono dall’API pubblica di Electricity Maps.

---

## Tecnologie utilizzate

- **Backend:** PHP con MySQL  
- **Client:** Flutter (Android)  
- **API esterna:** Electricity Maps  
- **Cache locale:** sqflite 
- **Architettura:** REST API  

---

## Diario di progetto

### Commit 1 — Setup 

- Creazione della struttura del progetto (`server/` e `client/`)
- Prima definizione del README 
- Prime scelte di sviluppo


### Commit 2 — Database MySQL e configurazione server 

- Creato lo schema del database con due tabelle: zones_monitored e carbon_readings
- Scelta di usare zone_key come chiave unica e foreign key per collegare le due tabelle
- Configurata connessione PDO con error handling
- Creato router REST base con supporto CORS


### Commit 3 — CRUD completo zones_monitored
- Implementati tutti i metodi HTTP per la risorsa zones: GET, POST, PUT, PATCH, DELETE
- PATCH implementato con query dinamica
- Gestione errori con codici HTTP appropriati 
  

### Commit 4 — CRUD carbon_readings e proxy API esterna
- Implementato CRUD completo per la risorsa readings
- Creato il ProxyController che funge da intermediario verso l'API Electricity Maps
- Scelta architetturale: proxy salva automaticamente le letture nel database ad ogni chiamata
- Usato cURL per le chiamate HTTP esterne e gestione errori


---

## Fonti

- Electricity Maps API Docs: https://docs.electricitymaps.com/
- PHP documentation: https://www.php.net/manual/
- Flutter documentation: https://docs.flutter.dev/