# Guida all'uso di Metabase in locale con SQL Server

Guida pratica per chi impara **da autodidatta** e vuole creare sul proprio PC Windows un piccolo ambiente di reportistica:

- **SQL Server**, come database di appoggio;
- **Metabase Open Source**, per domande, grafici e dashboard;
- **il report Contoso** di questa repository, come esempio funzionante da cui partire.

> **Legenda**
> - ✅ **Provato**: verificato con la stessa configurazione di questa repository (Metabase v0.56.6, SQL Server 2022, dati di esempio).
> - **[Non verificato]**: dipende dal vostro PC, dalla versione o da condizioni di licenza; va controllato.
> - **[Inferenza]**: consiglio ragionato, non una regola.
>
> Tutte le prove sono state fatte su Linux con Docker. **I passaggi specifici di Windows** (installazioni, menu di SSMS, Configuration Manager, Docker Desktop) **sono descritti dalla documentazione e non sono stati eseguiti su un PC Windows** [Non verificato].

---

## Indice

0. [Il percorso in sintesi](#0-il-percorso-in-sintesi)
1. [Come è fatto l'ambiente](#1-come-è-fatto-lambiente)
2. [Preparare SQL Server](#2-preparare-sql-server)
3. [Installare Docker Desktop](#3-installare-docker-desktop)
4. [Scaricare il progetto e configurarlo](#4-scaricare-il-progetto-e-configurarlo)
5. [Avviare Metabase](#5-avviare-metabase)
6. [Collegare i dati e pubblicare il report](#6-collegare-i-dati-e-pubblicare-il-report)
7. [Usare Metabase: i concetti](#7-usare-metabase-i-concetti)
8. [Esercitazioni passo-passo](#8-esercitazioni-passo-passo)
9. [Gestire l'ambiente nel tempo](#9-gestire-lambiente-nel-tempo)
10. [Risoluzione dei problemi](#10-risoluzione-dei-problemi)
11. [Alternativa senza Docker](#11-alternativa-senza-docker)
12. [Piano di apprendimento](#12-piano-di-apprendimento)
13. [Fonti, rischi e domande aperte](#13-fonti-rischi-e-domande-aperte)

---

## 0. Il percorso in sintesi

| Fase | Cosa fate | Risultato | Tempo indicativo [Inferenza] |
|---|---|---|---|
| 1 | Verificate o installate SQL Server e lo configurate | Il database risponde dalla rete locale | 30–60 min |
| 2 | Eseguite 4 script in SSMS | Database `ContosoLab` con dati di esempio e utente in sola lettura | 10 min |
| 3 | Installate Docker Desktop | Docker funzionante | 20–40 min (con riavvio) |
| 4 | Scaricate questa repository e compilate il file `.env` | Configurazione pronta | 10 min |
| 5 | Avviate Metabase con un comando | Metabase su http://localhost:3000 | 5 min |
| 6 | Pubblicate il report con lo script, oppure collegate il database a mano | Dashboard Contoso funzionante | 10 min |
| 7–8 | Fate le esercitazioni | Sapete creare domande, misure, dashboard e filtri | Qualche sera |

---

## 1. Come è fatto l'ambiente

```
 ┌──────────────────────── IL VOSTRO PC WINDOWS ────────────────────────┐
 │                                                                      │
 │   SQL Server (servizio Windows)          Docker Desktop              │
 │   ┌───────────────────────────┐          ┌────────────────────────┐  │
 │   │ Database ContosoLab       │  legge   │ Metabase   :3000       │  │
 │   │  schema contoso           │◄─────────│                        │  │
 │   │  tabelle + vista misure   │  1433    │ appdb (PostgreSQL)     │  │
 │   └───────────────────────────┘          │  memoria di Metabase   │  │
 │          ▲                               └────────────────────────┘  │
 │          │ gestite con SSMS                         ▲                │
 │                                                     │ browser        │
 │                                          http://localhost:3000       │
 └──────────────────────────────────────────────────────────────────────┘
```

| Componente | Che cos'è | Dove vive |
|---|---|---|
| **SQL Server** | Il database con i **vostri dati** | Installato su Windows |
| **SSMS** | Il programma con cui **guardate e gestite** SQL Server. **Non è il database**: è solo il "volante" | Già installato sul vostro PC |
| **Metabase** | Il programma di **reportistica**: lo usate dal browser | Container Docker |
| **appdb** | Il database dove Metabase salva **domande, dashboard e utenti** (non i vostri dati) | Container Docker |
| **Docker Desktop** | Il programma che fa girare Metabase in "scatole" isolate (container), senza installarlo davvero su Windows | Installato su Windows |

**Perché così?** [Inferenza]
- SQL Server lo conoscete già e il Contoso originale vive lì.
- Docker evita di installare Java e Metabase a mano: si aggiorna cambiando un numero di versione.
- Tenere le dashboard in un database separato (appdb) rende il backup semplice.

---

## 2. Preparare SQL Server

### 2.1 Avete già il motore SQL Server?

SSMS da solo non basta. Per verificare:

1. Premete `Win + R`, scrivete `services.msc` e premete Invio.
2. Cercate un servizio chiamato **SQL Server (MSSQLSERVER)** oppure **SQL Server (SQLEXPRESS)** (o con un altro nome tra parentesi).
3. Se esiste ed è **In esecuzione**, il motore c'è. Il nome tra parentesi è l'**istanza**:

   | Istanza | Come vi collegate in SSMS |
   |---|---|
   | `MSSQLSERVER` (istanza predefinita) | `localhost` |
   | `SQLEXPRESS` o altro nome | `localhost\SQLEXPRESS` |

Se il servizio non c'è, installate SQL Server (passo 2.2).

### 2.2 Installare SQL Server (solo se manca)

Dalla pagina ufficiale Microsoft dei download di SQL Server scegliete una edizione gratuita:

| Edizione | Quando sceglierla |
|---|---|
| **Developer** | Per imparare e sviluppare: ha tutte le funzioni, ma **non si può usare in produzione** |
| **Express** | Uso leggero anche in produzione, con limiti di dimensione del database (pochi GB) |

[Non verificato] Nomi delle edizioni, limiti e condizioni di licenza vanno controllati sul sito Microsoft al momento dell'installazione.

Durante l'installazione scegliete **"Autenticazione mista"** e impostate una password per l'utente `sa`. Così il passo 2.3 non serve più.

### 2.3 Attivare l'autenticazione mista

Metabase si collega con **utente e password SQL** (non con l'utente Windows), quindi SQL Server deve accettare entrambi i tipi di accesso.

1. In SSMS fate clic destro sul server → **Proprietà** → **Sicurezza**.
2. Selezionate **"Autenticazione di SQL Server e di Windows"**.
3. Confermate e **riavviate il servizio** SQL Server, da `services.msc` oppure in SSMS con clic destro sul server → Riavvia.

### 2.4 Attivare la connessione di rete (TCP/IP, porta 1433)

Metabase gira in un container: per lui SQL Server è "un altro computer" e ci arriva via rete.

1. Aprite **SQL Server Configuration Manager**. Si trova cercando "SQL Server 2022 Configuration Manager" nel menu Start [Non verificato: il nome cambia con la versione].
2. Andate su **Configurazione di rete SQL Server** → **Protocolli per <istanza>**.
3. **TCP/IP** → clic destro → **Abilita**.
4. Solo per le istanze con nome (es. `SQLEXPRESS`): doppio clic su TCP/IP → scheda **Indirizzi IP** → sezione **IPAll**:
   - **Porte dinamiche TCP**: vuoto;
   - **Porta TCP**: `1433`.
5. Riavviate il servizio SQL Server.

Per verificare, in SSMS collegatevi a `localhost,1433` (con la **virgola**). Se funziona, la porta è aperta.

### 2.5 Creare database, dati e utente: i 4 script

Nella cartella `sqlserver/` di questa repository:

| Script | Cosa fa | Note |
|---|---|---|
| `01_database_e_tabelle.sql` | Crea il database **ContosoLab**, lo schema `contoso` e le 5 tabelle (sales, customer, product, store, date) | Si può rieseguire: ricrea le tabelle **vuote** |
| `02_dati_esempio.sql` | Carica dati **sintetici**: 500 clienti, 60 prodotti, 12 negozi, 30.000 vendite 2023–2025 | Sempre gli stessi numeri a ogni esecuzione |
| `03_vista_misure.sql` | Crea la vista `contoso.v_sales_line` con le misure (vendite, costo, margine) | È il "livello semantico", l'equivalente delle misure DAX |
| `04_utente_metabase.sql` | Crea l'utente **`metabase_ro`**, che **può solo leggere** lo schema `contoso` | **Cambiate la password prima di eseguirlo** |

Come eseguirli in SSMS:

1. Collegatevi al server come amministratore (Windows o `sa`).
2. **File → Apri → File…** e scegliete `01_database_e_tabelle.sql`.
3. Premete **F5** (Esegui). In basso, nella scheda *Messaggi*, deve comparire `Database ContosoLab e tabelle creati.`
4. Ripetete per 02, 03 e 04, nell'ordine.

✅ Provato: al termine lo script 02 mostra `1096 giorni, 500 clienti, 60 prodotti, 12 negozi, 30000 righe_vendita`.

**Verifica finale.** Aprite una nuova query in SSMS ed eseguite:

```sql
USE ContosoLab;
SELECT SUM(sales_amount) AS vendite, SUM(margin) AS margine
FROM contoso.v_sales_line;
```

✅ Provato: con i dati di esempio il risultato è circa **36,6 milioni** di vendite e **11,5 milioni** di margine.

### 2.6 Usare i vostri dati invece di quelli di esempio

Avete tre strade, dalla più semplice alla più pulita:

1. **Database Contoso già presente** sul vostro SQL Server: create una vista come `03_vista_misure.sql` che legga dalle vostre tabelle. Poi adattate le query in `report/sql/sqlserver/` ai nomi reali delle colonne.
2. **Dati in Excel o CSV**: in SSMS usate clic destro sul database → **Attività → Importa dati…** (procedura guidata di importazione) e caricateli in una tabella dello schema `contoso`.
3. **Dati da un gestionale**: chiedete all'IT un accesso in sola lettura oppure un'esportazione periodica.

[Inferenza] Tenete separato `ContosoLab` (palestra) da qualunque database aziendale reale.

---

## 3. Installare Docker Desktop

1. Scaricate **Docker Desktop per Windows** dal sito ufficiale di Docker.
2. Durante l'installazione lasciate attiva l'opzione **WSL 2** (il "Linux dentro Windows" che Docker usa).
3. Riavviate il PC se richiesto e aprite Docker Desktop: in basso a sinistra deve comparire lo stato *Engine running*.
4. Aprite **PowerShell** ed eseguite:

   ```powershell
   docker run --rm hello-world
   ```

   Se compare `Hello from Docker!`, Docker funziona.

> ⚠️ **Licenza [Non verificato]:** Docker Desktop è gratuito per uso personale, formazione e piccole aziende. Per aziende oltre certe soglie di dipendenti o fatturato richiede un abbonamento a pagamento. Su un **PC aziendale** verificate le condizioni attuali con l'IT. Se Docker non è utilizzabile, seguite la [sezione 11](#11-alternativa-senza-docker).

---

## 4. Scaricare il progetto e configurarlo

### 4.1 Scaricare la repository

- **Senza Git**: su GitHub aprite la repository → pulsante verde **Code → Download ZIP** → estraete il file, per esempio in `C:\Progetti\reporting-metabase`.
- **Con Git** (consigliato per aggiornarla nel tempo):

  ```powershell
  cd C:\Progetti
  git clone https://github.com/FrankLucs84/reporting-metabase.git
  ```

### 4.2 Creare il file di configurazione `.env`

Nella cartella del progetto:

```powershell
cd C:\Progetti\reporting-metabase
Copy-Item .env.sqlserver.example .env
notepad .env
```

Modificate almeno queste righe:

| Riga | Cosa mettere |
|---|---|
| `MB_APPDB_PASSWORD` | Una password a scelta, per il database interno di Metabase |
| `MB_ADMIN_EMAIL` / `MB_ADMIN_PASSWORD` | Le credenziali con cui entrerete in Metabase |
| `WAREHOUSE_RO_PASSWORD` | **La stessa password** messa nello script `04_utente_metabase.sql` |
| `MB_WAREHOUSE_PORT` | `1433`, salvo che abbiate scelto un'altra porta al passo 2.4 |

`MB_WAREHOUSE_HOST=host.docker.internal` **non va cambiato**: è il nome con cui un container Docker raggiunge il vostro PC.

> Il file `.env` contiene password: **non va mai caricato su GitHub**. È già escluso tramite `.gitignore`.

---

## 5. Avviare Metabase

Da PowerShell, nella cartella del progetto:

```powershell
docker compose -f docker-compose.sqlserver.yml --env-file .env up -d
```

- La **prima volta** Docker scarica le immagini (alcune centinaia di MB) [Inferenza: 2–10 minuti a seconda della connessione].
- Metabase impiega circa **1–2 minuti** ad avviarsi. Per vedere a che punto è:

  ```powershell
  docker compose -f docker-compose.sqlserver.yml ps
  ```

  Quando la colonna *STATUS* di `metabase` indica `healthy`, aprite il browser su **http://localhost:3000**.

Per spegnere tutto (i dati restano salvati):

```powershell
docker compose -f docker-compose.sqlserver.yml --env-file .env down
```

✅ Provato: con questo file Metabase si avvia e raggiunge SQL Server tramite `host.docker.internal:1433`.

---

## 6. Collegare i dati e pubblicare il report

Ci sono due strade. **Scegliete la A per avere subito il report Contoso**; la B serve per imparare il collegamento a mano.

### Strada A — Automatica con lo script (consigliata per iniziare)

1. Installate **Python 3.10 o successivo** dal sito python.org, spuntando **"Add python.exe to PATH"**.
2. In PowerShell, nella cartella del progetto:

   ```powershell
   py -m pip install -r scripts\requirements.txt
   py scripts\deploy.py apply
   ```

3. Lo script:
   - crea l'amministratore di Metabase con le credenziali del `.env`;
   - collega il database **Contoso DW (SQL Server)** con l'utente `metabase_ro`;
   - crea la collezione **Contoso - Report Pareto** con 9 domande;
   - crea il dashboard **Contoso - Vendite e Pareto clienti**.
4. Alla fine stampa l'indirizzo del dashboard, di solito http://localhost:3000/dashboard/2.

✅ Provato su SQL Server 2022: il dashboard funziona con tutti i filtri.

![Dashboard su SQL Server](img/dashboard-sqlserver.png)

> Lo script è **ripetibile**: se cambiate una query in `report/sql/sqlserver/` e rilanciate `py scripts\deploy.py apply`, le domande vengono aggiornate senza creare doppioni.

### Strada B — A mano dall'interfaccia

1. Al primo accesso su http://localhost:3000 Metabase propone una **configurazione guidata**: lingua, nome, email e password dell'amministratore.

   > Se poi volete usare anche la strada A, usate **le stesse credenziali** scritte nel `.env`.

2. Al passo **"Aggiungi i tuoi dati"** (oppure dopo, da ⚙️ → **Impostazioni amministratore → Database → Aggiungi database**) compilate:

   | Campo (come appare nell'interfaccia) | Valore |
   |---|---|
   | Tipo database | **SQL Server** |
   | Nome da visualizzare | `Contoso DW (SQL Server)` |
   | Ospite *(è l'host: traduzione letterale)* | `host.docker.internal` |
   | Porta | `1433` |
   | Nome del database | `ContosoLab` |
   | Database instance name | vuoto, se avete fissato la porta 1433 al passo 2.4 |
   | Nome utente | `metabase_ro` |
   | Password | quella dello script 04 |
   | Usa una connessione sicura (SSL) | attivo |
   | **Mostra opzioni avanzate** → Opzioni stringhe di connessione JDBC aggiuntive | `trustServerCertificate=true` |

   ![Modulo di connessione SQL Server](img/connessione-sqlserver.png)

   `trustServerCertificate=true` dice a Metabase di accettare il certificato "fatto in casa" di un SQL Server locale. Senza, la connessione cifrata di norma fallisce [Inferenza]. Su un server aziendale con un certificato valido non serve.

3. Salvate. Metabase **sincronizza** il database: legge l'elenco di tabelle e colonne, senza copiare i dati.

![Pagina del database in Metabase](img/admin-database.png)

> **Come legge i dati Metabase?** Ogni volta che aprite un grafico, Metabase manda una query a SQL Server e mostra il risultato. I dati non vengono copiati: se aggiornate una tabella in SSMS, il grafico mostra subito il dato nuovo. La "sincronizzazione" aggiorna solo l'elenco di tabelle e colonne. Di default Metabase fa una sincronizzazione leggera ogni ora e una scansione dei valori una volta al giorno (✅ indicato nelle opzioni avanzate del modulo). Potete forzarla con **"Sincronizza lo schema del database"**.

---

## 7. Usare Metabase: i concetti

### 7.1 Dizionario minimo (con l'equivalente Power BI)

| Metabase (interfaccia italiana) | Cos'è | Equivalente Power BI |
|---|---|---|
| **Domanda** | Una singola interrogazione con il suo grafico o tabella | Un visual |
| **Query SQL** | Una domanda scritta in SQL invece che con l'editor visuale | Visual su una query nativa / DAX avanzato |
| **Cruscotto** (dashboard) | Una pagina con più domande e filtri comuni | Una pagina di report |
| **Collezione** | Una cartella che raccoglie domande e cruscotti, con i suoi permessi | Workspace / cartella |
| **Modello** | Una tabella "pulita" e documentata, costruita da una domanda, da riusare come base | Tabella del modello semantico |
| **Metrica** | Una misura salvata con un nome (es. "Margine") e riusabile in altre domande | Misura DAX |
| **Filtro del cruscotto** | Un selettore collegato a una o più domande | Slicer |
| **Metadati della tabella** | Descrizioni, tipi di colonna, colonne nascoste | Proprietà delle colonne nel modello |

### 7.2 Dove si trovano le cose

- **+ Nuovo** (in alto a destra) → **Domanda**, **Query SQL**, **Cruscotto**.
- Barra laterale → sezione **Dati** → **Database**, **Modelli**, **Metriche**.
- ⚙️ (in alto a destra) → **Impostazioni amministratore**: database, persone, permessi.

![Menu Nuovo e barra laterale](img/menu-nuovo.png)

### 7.3 I tre modi per creare una misura

| Livello | Dove | Esempio | Quando usarlo |
|---|---|---|---|
| **1. Nel database** (SQL) | Vista in SQL Server, come `contoso.v_sales_line` | `quantity * net_price AS sales_amount` | Misure base usate ovunque: una sola definizione, un solo posto |
| **2. In Metabase, senza codice** | Editor visuale → **Riassume**, oppure espressione personalizzata, oppure **Metrica** salvata | `Sum([Margin]) / Sum([Sales Amount])` | Misure di analisi, create anche da chi non scrive SQL |
| **3. In una Query SQL** | Domanda SQL | Pareto con funzioni finestra (`SUM() OVER`) | Logiche complesse, come i cumulati o la classificazione ABC |

[Inferenza] Regola pratica: **misure base nel database, misure di analisi in Metabase, logiche complesse in SQL**. È la scelta fatta nel report di esempio.

---

## 8. Esercitazioni passo-passo

Le esercitazioni usano il database di esempio. Salvate le vostre prove in **La sua collezione personale**, così non toccate la collezione del report gestita dallo script.

### Esercizio 1 — Prima domanda con l'editor visuale (senza codice)

**Obiettivo:** vendite totali per anno.

1. **+ Nuovo → Domanda**.
2. **Dati**: scegliete il database `Contoso DW (SQL Server)` e poi la tabella **V Sales Line**.
3. **Riassume**: scegliete **Somma di… → Sales Amount**.
4. **per**: scegliete **Order Date → Anno**.
5. Premete **Visualizza**: compare un grafico a barre con 3 anni.
6. **Salva**, con un nome chiaro, per esempio "Vendite per anno".

![Editor visuale](img/editor-visuale.png)

![Risultato](img/risultato-domanda.png)

✅ Provato: con i dati di esempio ogni anno vale circa 12 milioni.

> 💡 Il pulsante **Visualizza SQL** mostra la query SQL che Metabase ha generato: ottimo per imparare l'SQL guardando.

### Esercizio 2 — Collegare le tabelle (join) e filtrare

**Obiettivo:** vendite per categoria di prodotto, solo in Italia.

1. Nuova domanda su **V Sales Line**.
2. **Dati in join** → tabella **Product**, collegando `Product Key` = `Product Key`.
3. Di nuovo **Dati in join** → tabella **Store**, su `Store Key`.
4. **Filtro** → **Store → Country** è **Italia**.
5. **Riassume**: Somma di Sales Amount **per** Product → Category.
6. **Visualizzazione** → **Barre**.

È esattamente quello che in Power BI fanno le relazioni del modello. [Inferenza] Per non rifare ogni volta i join, dichiarate le chiavi esterne in **Impostazioni amministratore → Metadati della tabella**, oppure create un Modello (esercizio 4).

### Esercizio 3 — Una misura con espressione personalizzata (come DAX `DIVIDE`)

**Obiettivo:** il margine % per categoria.

1. Partite dall'esercizio 2, senza filtro.
2. In **Riassume** fate clic su **+** → **Espressione personalizzata**.
3. Scrivete:

   ```
   Sum([Margin]) / Sum([Sales Amount])
   ```

4. Nome: `Margine %`. In **Visualizzazione → impostazioni della colonna** scegliete lo stile **Percentuale**.

Equivalenza DAX: `DIVIDE([Margin], [Sales Amount])`.

Altre espressioni utili [Non verificato: elenco completo nella documentazione "Custom expressions"]:

| Espressione | Cosa fa |
|---|---|
| `[Quantity] * [Net Price]` | Colonna calcolata riga per riga (in **Colonna personalizzata**) |
| `case([Margin] < 0, "Perdita", "Utile")` | Classificazione, come `IF` / `SWITCH` |
| `SumIf([Sales Amount], [Category] = "Audio")` | Somma condizionata, come `CALCULATE` con un filtro |
| `CountIf([Quantity] > 3)` | Conteggio condizionato |
| `Distinct([Customer Key])` | Conteggio distinto, come `DISTINCTCOUNT` |

### Esercizio 4 — Un Modello: la "tabella pulita" da riusare

**Obiettivo:** una tabella vendite già unita a prodotto e negozio, con nomi di colonna chiari.

1. Ricreate la domanda dell'esercizio 2, senza filtri né riassunto: solo i join.
2. Salvatela, poi dal menu **…** scegliete **Trasforma in modello** [Non verificato: la voce può cambiare nome tra versioni].
3. Nel modello rinominate le colonne in italiano e aggiungete una descrizione.
4. Da qui in poi create le domande partendo da **Modelli → il vostro modello**: niente più join.

### Esercizio 5 — Una Metrica: la misura con un nome

**Obiettivo:** definire "Margine" una sola volta e riusarlo.

1. Barra laterale → sezione **Dati** → **Metriche** → pulsante per creare una nuova metrica [Non verificato: etichetta esatta del pulsante; in questa versione il menu **+ Nuovo** non ha la voce Metrica].
2. Fonte: **V Sales Line**, oppure il modello dell'esercizio 4.
3. Misura: **Somma di Margin**. Nome: `Margine`. Salvate.
4. In una nuova domanda, in **Riassume**, la trovate tra le **metriche** e potete usarla per qualunque raggruppamento.

✅ Provato via API su questa versione: una metrica "Somma di Margin" restituisce 11.506.738,94, lo stesso valore della vista SQL.

### Esercizio 6 — Query SQL con variabili (filtri nel codice)

**Obiettivo:** capire come funzionano le query del report.

1. **+ Nuovo → Query SQL** → database `Contoso DW (SQL Server)`.
2. Incollate:

   ```sql
   SELECT product.category,
          SUM(v_sales_line.sales_amount) AS vendite
   FROM contoso.v_sales_line
   JOIN contoso.product ON product.product_key = v_sales_line.product_key
   WHERE {{periodo}}
   GROUP BY product.category
   ORDER BY vendite DESC
   ```

3. A destra compare il pannello della variabile `periodo`:
   - **Tipo di variabile**: **Filtro di campo**;
   - **Campo**: `V Sales Line → Order Date`;
   - **Tipo di widget**: data.
4. Eseguite: in alto compare un selettore di date funzionante.

Due regole importanti, usate in tutto il report:

- Con i **filtri di campo** le tabelle **non vanno rinominate con alias** (scrivete `contoso.product`, non `contoso.product p`). Metabase genera il filtro usando il nome completo della tabella.
- Una variabile di **testo**, per esempio `{{metric}}` nel Pareto, viene sostituita con un valore tra apici (`'Margin'`). Così una sola query può calcolare misure diverse, come la tabella disconnessa `Metric` di Power BI.

### Esercizio 7 — Un cruscotto con filtri

1. **+ Nuovo → Cruscotto** → nome "Il mio primo cruscotto".
2. Aggiungete le domande degli esercizi 1, 3 e 6 (icona **+**), poi trascinate e ridimensionate i riquadri.
3. Aggiungete un **filtro**: icona del filtro → **Data** → **Tutte le opzioni**.
4. **Collegate** il filtro a ogni riquadro, scegliendo la colonna data (o la variabile `periodo` per la domanda SQL).
5. **Salva**. Ora un solo selettore filtra tutto il cruscotto, come uno slicer.

---

## 9. Gestire l'ambiente nel tempo

### 9.1 Comandi di uso quotidiano (PowerShell, nella cartella del progetto)

| Azione | Comando |
|---|---|
| Avviare | `docker compose -f docker-compose.sqlserver.yml --env-file .env up -d` |
| Spegnere | `docker compose -f docker-compose.sqlserver.yml --env-file .env down` |
| Stato | `docker compose -f docker-compose.sqlserver.yml ps` |
| Leggere i log di Metabase | `docker compose -f docker-compose.sqlserver.yml logs --tail 100 metabase` |
| Ripubblicare il report | `py scripts\deploy.py apply` |
| Controllare il report senza pubblicarlo | `py scripts\deploy.py validate` |

> Con `restart: unless-stopped` i container ripartono da soli quando Docker Desktop si avvia. Se volete che Metabase parta all'accensione del PC, attivate in Docker Desktop **Settings → General → Start Docker Desktop when you sign in** [Non verificato: il nome dell'opzione può cambiare].

### 9.2 Backup

| Cosa | Perché | Come |
|---|---|---|
| **Dashboard, domande e utenti di Metabase** | Sono nel database appdb, non nei file | Vedi i comandi qui sotto |
| **Dati di SQL Server** | Sono i vostri dati | In SSMS: clic destro su `ContosoLab` → **Attività → Backup…** |
| **Report gestito da codice** | È già salvato in Git | `git commit` e `git push` |

Backup del database interno di Metabase:

```powershell
docker compose -f docker-compose.sqlserver.yml exec appdb pg_dump -U metabase -f /tmp/backup.sql metabase
docker compose -f docker-compose.sqlserver.yml cp appdb:/tmp/backup.sql .\backup_metabase.sql
```

> Questi due comandi evitano il simbolo `>` di PowerShell, che può salvare il file con una codifica sbagliata.

### 9.3 Aggiornare Metabase

1. Fate il **backup** (9.2).
2. In `.env` cambiate `METABASE_VERSION` con la nuova versione (per esempio `v0.57.x`) [Non verificato: scegliete una versione stabile dalle release ufficiali].
3. Rilanciate il comando di avvio: Docker scarica la nuova versione e Metabase aggiorna da solo il suo database.
4. Rilanciate `py scripts\deploy.py apply` e controllate il dashboard.

[Inferenza] Aggiornate una versione alla volta e non subito il giorno dell'uscita.

### 9.4 Ricominciare da zero

```powershell
docker compose -f docker-compose.sqlserver.yml --env-file .env down -v
```

L'opzione `-v` **cancella** domande e dashboard di Metabase; i dati di SQL Server restano. Per azzerare anche quelli, rieseguite gli script 01 e 02.

---

## 10. Risoluzione dei problemi

| Sintomo | Causa probabile | Soluzione |
|---|---|---|
| `docker` non è riconosciuto | Docker Desktop non installato o non avviato | Avviate Docker Desktop e attendete *Engine running* |
| http://localhost:3000 non risponde | Metabase ancora in avvio | Attendete 1–2 minuti e controllate con `ps` (9.1) |
| Collegando il database: *Connection refused* / *timeout* | TCP/IP disattivato, porta diversa da 1433 o servizio SQL Server fermo | Ripetete il passo 2.4 e verificate in SSMS con `localhost,1433` |
| *Login failed for user 'metabase_ro'* | Password diversa tra script 04 e `.env`, oppure autenticazione mista disattivata | Allineate le password e ripetete il passo 2.3 |
| Errore di certificato / *SSL* / *PKIX* / *encrypt* | La connessione è cifrata e il certificato del SQL Server locale non è riconosciuto | Aggiungete `trustServerCertificate=true` in **Opzioni stringhe di connessione JDBC aggiuntive** (6.B); lo script lo fa da solo |
| Le tabelle non compaiono in Metabase | Sincronizzazione non ancora fatta, oppure mancano i permessi | ⚙️ → Database → **Sincronizza lo schema**; verificate di aver eseguito lo script 04 |
| `py scripts\deploy.py apply` dice *Metabase non risponde* | Metabase spento o su una porta diversa | Controllate `MB_URL` nel `.env` e che Metabase sia avviato |
| Lo script si ferma con *401* o *password* | Credenziali admin diverse da quelle usate nella configurazione guidata | Allineate `MB_ADMIN_EMAIL` e `MB_ADMIN_PASSWORD` nel `.env` |
| Firewall: funziona in SSMS ma non da Metabase | Il firewall di Windows blocca la porta 1433 dal "lato Docker" [Non verificato] | Aggiungete una regola in ingresso per la porta TCP 1433 (Windows Defender Firewall → Impostazioni avanzate) |

---

## 11. Alternativa senza Docker

Se Docker Desktop non si può usare (per esempio per la licenza su un PC aziendale), Metabase gira anche come **singolo file JAR**:

1. Installate **Java** nella versione richiesta dalla release di Metabase [Non verificato: per le versioni recenti è Java 21; controllate le note di rilascio].
2. Scaricate `metabase.jar` dalla pagina ufficiale (versione Open Source) in una cartella, per esempio `C:\Metabase`.
3. Avviatelo:

   ```powershell
   cd C:\Metabase
   java -jar metabase.jar
   ```

4. Aprite http://localhost:3000. Nel collegamento al database usate **Host `localhost`** invece di `host.docker.internal`.
5. Per lo script di deploy, nel `.env` impostate `MB_WAREHOUSE_HOST=localhost`.

Differenze rispetto a Docker:

| Aspetto | JAR | Docker (questa repository) |
|---|---|---|
| Installazione | Serve Java | Serve Docker Desktop |
| Memoria di Metabase | File locale H2 (`metabase.db.mv.db`) nella cartella | Database PostgreSQL dedicato (appdb) |
| Adatto a | Imparare, prove personali | Uso più stabile e duraturo |
| Avvio automatico | Da configurare a mano (es. Utilità di pianificazione) | Automatico con Docker Desktop |

[Inferenza] Metabase stesso sconsiglia il database H2 per l'uso in produzione. Per imparare va benissimo, ma fate copie del file `.mv.db` a Metabase spento.

---

## 12. Piano di apprendimento

| Settimana | Obiettivo | Attività | Risultato verificabile |
|---|---|---|---|
| 1 | Ambiente funzionante | Sezioni 2–6 | Dashboard Contoso visibile su localhost:3000 |
| 2 | Domande senza codice | Esercizi 1–3 | 3 domande salvate nella collezione personale |
| 3 | Riuso | Esercizi 4–5, metadati delle tabelle | 1 modello e 2 metriche usati in nuove domande |
| 4 | SQL e filtri | Esercizi 6–7 | Un cruscotto con almeno un filtro collegato a tutte le domande |
| 5 | Dati vostri | Sezione 2.6 con un vostro file Excel o CSV | Un cruscotto con dati reali, non di esempio |
| 6 | Manutenzione "as code" | Aggiungere una card al `report.yml` e pubblicarla con lo script | Modifica salvata in Git e visibile nel dashboard |

**Come fare la settimana 6** (aggiungere una domanda al report gestito da codice):

1. Create `report/sql/sqlserver/vendite_per_brand.sql` (e la versione PostgreSQL in `report/sql/postgres/`, se usate anche quella).
2. Aggiungete la voce in `cards:` e la posizione in `dashboard.layout`, nel file `report/report.yml`.
3. `py scripts\deploy.py validate`, poi `py scripts\deploy.py apply`.
4. `git add`, `git commit`, `git push`: la CI su GitHub ricontrolla tutto.

---

## 13. Fonti, rischi e domande aperte

### Fonti ufficiali

| Fonte | Indirizzo |
|---|---|
| Documentazione Metabase | https://www.metabase.com/docs/latest/ |
| Tutorial Metabase (Learn) | https://www.metabase.com/learn/ |
| Codice sorgente Metabase | https://github.com/metabase/metabase |
| Download SQL Server (Microsoft) | pagina "SQL Server downloads" sul sito Microsoft |
| Docker Desktop | https://docs.docker.com/desktop/ |

### Rischi e vincoli

| ID | Rischio / vincolo | Impatto | Mitigazione | Stato |
|---|---|---|---|---|
| R1 | Licenza Docker Desktop su PC aziendale | Uso non conforme | Verifica con l'IT, oppure alternativa JAR (sezione 11) | [Non verificato] |
| R2 | Passaggi Windows (SSMS, Configuration Manager, firewall) non provati su Windows | Bloccanti all'avvio | Tabella della sezione 10; segnalare l'errore esatto | [Non verificato] |
| R3 | Dati di esempio scambiati per dati reali | Decisioni errate | Il nome `ContosoLab` e i commenti negli script segnalano dati sintetici | Certo |
| R4 | Perdita di dashboard create a mano | Lavoro perso | Backup di appdb (9.2); il report gestito da codice è in Git | Certo |
| R5 | Le modifiche a mano nella collezione "Contoso - Report Pareto" vengono sovrascritte dallo script | Lavoro perso | Lavorare nella collezione personale o in un'altra collezione | Certo |
| R6 | Le edizioni gratuite (SQL Server Express, Metabase OSS) hanno funzioni limitate (dimensione DB, RLS, SSO) | Limiti in crescita | Rivalutare le edizioni quando l'ambiente passa da "palestra" a "servizio" | [Non verificato: limiti attuali] |

### Domande aperte

1. Che istanza SQL Server avete: predefinita (`MSSQLSERVER`) o con nome (`SQLEXPRESS`)? Cambia il passo 2.4.
2. Docker Desktop è consentito sul vostro PC? Altrimenti seguite la sezione 11.
3. Quali dati reali volete analizzare per primi (file Excel, Contoso, gestionale)? Determina il passo 2.6.
