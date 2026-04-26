# GreenGrid — Monitoraggio Intensità Carbonica Reti Elettriche  

**Sviluppatore:** Francesco  

## Abstract  
GreenGrid è un’app mobile sviluppata in Flutter con backend REST in PHP + MySQL. Permette di monitorare l’intensità di carbonio in diverse aree del mondo. L’utente può salvare le zone di interesse I dati provengono dall’API pubblica di Electricity Maps e vengono gestiti tramite un proxy backend. L’app include anche una cache locale con SQLite per funzionare offline.

---

## Tecnologie utilizzate  
- **Backend:** PHP con MySQL  
- **Client:** Flutter 
- **API esterna:** Electricity Maps
- **Cache locale:** sqflite 
- **Architettura:** REST API con CRUD completo  

---

## Diario di progetto  

### fase 1 — Setup iniziale e struttura progetto  
- Creata la struttura base: `server/` e `client/`  
- Redatto il README iniziale  


---

### fase 2 — Database e configurazione server  
- Creato schema MySQL con due tabelle:  
  - `zones_monitored`  
  - `carbon_readings`  
- Uso di `zone_key` come identificatore univoco e foreign key  
- Campo `power_breakdown_json` salvato come TEXT per flessibilità  
- Configurata connessione PDO con gestione errori  
- Implementato router REST base con supporto CORS  

---

### fase 3 — CRUD completo zones  
- Implementati tutti i metodi HTTP 
- Utilizzo di prepared statements 
- Gestione errori con codici HTTP appropriati  

---

### fase 4 — CRUD readings e proxy API  
- CRUD completo per `carbon_readings`  
- Implementato ProxyController verso Electricity Maps  
- Salvataggio automatico delle letture nel DB   
- Chiamate HTTP via cURL con timeout e gestione errori  

---

### fase 5 — Flutter: base app, modelli e servizi  
- Struttura progetto organizzata (`models/`, `services/`, `screens/`, ecc.)    
- Creato `ApiService` per comunicazione backend  
- Uso di `connectivity_plus` per stato rete  
- UI

---

### fase 6 — UI completa e cache locale  
- Implementata cache SQLite speculare al backend  
- Creati widget riutilizzabili:  
  - ZoneCard  
  - PowerMixBar  
  - OfflineBanner  
- Schermate complete  


---

### fase 7 — Logica offline completa  

