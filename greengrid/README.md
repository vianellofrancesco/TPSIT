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
  
---

## Fonti

- Electricity Maps API Docs: https://docs.electricitymaps.com/
- PHP documentation: https://www.php.net/manual/