# Report Contoso su Metabase OSS (report as code)

Porting del report Power BI "Vendite e Pareto clienti" su **Metabase Open Source**, gestito interamente da file versionati in Git.

![Dashboard](docs/dashboard.png)

*Screenshot generato con i dati di esempio sintetici di `warehouse/02_seed.sql`.*

📘 **[Guida e confronto con Power BI](docs/GUIDA_PowerBI_vs_Metabase.md)**: mappa dei concetti, equivalenza delle misure DAX, ciclo di vita, quando scegliere cosa, rischi.

## Perché "manutenibile"

Metabase OSS salva domande e dashboard nel proprio database applicativo; la serializzazione in YAML è una funzione delle edizioni a pagamento. Qui la fonte di verità è il repository:

| Livello | File | Cosa contiene |
|---|---|---|
| Infrastruttura | `docker-compose.yml`, `.env.example` | Metabase (versione fissata), warehouse PostgreSQL, database applicativo |
| Dati | `warehouse/01_schema.sql` | Star schema: `sales`, `customer`, `product`, `store`, `date` |
| Livello semantico | `warehouse/03_semantic_views.sql` | Misure DAX tradotte in SQL, definite una sola volta |
| Query | `report/sql/*.sql` | Una domanda Metabase per file, SQL leggibile e revisionabile |
| Report | `report/report.yml` | Filtri, card, formattazione e layout del dashboard |
| Deploy | `scripts/deploy.py` | Applica `report.yml` a Metabase tramite REST API, in modo idempotente |
| Controllo | `.github/workflows/metabase-report.yml` | Valida la definizione ed esegue ogni query a ogni pull request |

Le modifiche fatte a mano nell'interfaccia di Metabase vengono sovrascritte al deploy successivo. Per l'esplorazione libera conviene usare una collection diversa da quella gestita.

## Avvio in locale

Servono Docker e Python 3.10 o successivo.

```bash
cp .env.example .env              # poi cambiare le password
docker compose --env-file .env up -d
pip install -r scripts/requirements.txt
python scripts/deploy.py apply
```

Al primo avvio lo script crea l'utente amministratore (`MB_ADMIN_EMAIL` / `MB_ADMIN_PASSWORD`), collega il warehouse con l'utente in sola lettura `metabase_ro` e pubblica il dashboard. L'indirizzo del dashboard viene stampato alla fine (di norma http://localhost:3000/dashboard/2).

## Contenuto del dashboard

| Card | Misura DAX di origine |
|---|---|
| Vendite totali, Margine, Margine %, Quantità totale | `Sales Amount`, `Margin`, `Margin %`, `Total Quantity` |
| Andamento mensile | Vendite, costi e margine per mese |
| Vendite per categoria | `Sales Amount` per `Product[Category]` |
| Performance per paese | KPI per paese della filiale |
| Pareto clienti | `Pareto Amount` + `Pareto %` (barre + linea cumulata) |
| Classificazione ABC clienti | A fino all'80% del valore cumulato, B fino al 95%, C il resto |

Filtri: **Periodo**, **Categoria prodotto**, **Paese filiale** (applicati a tutte le card) e **Misura Pareto** (Sales Amount, Margin, Total Cost, Total Quantity), che sostituisce la tabella disconnessa `Metric[Measure]` del modello Power BI.

## Modificare il report

1. **Cambiare una query**: modificare il file in `report/sql/` ed eseguire `python scripts/deploy.py apply`.
2. **Aggiungere una card**: creare il file SQL, aggiungere la voce in `cards:` e la posizione in `dashboard.layout` (griglia di 24 colonne). I filtri si inseriscono nella query come `{{nome_filtro}}` e vanno elencati in `filters:` della card.
3. **Aggiungere un filtro**: definirlo in `filters:` (con `field: [tabella, colonna]` per collegarlo a una colonna, oppure con `values:` per un elenco fisso) e aggiungerlo a `dashboard.filters`.
4. **Rimuovere una card**: toglierla da `report.yml` ed eseguire `python scripts/deploy.py apply --prune`, che la archivia.
5. **Aggiornare Metabase**: cambiare `METABASE_VERSION` in `.env`, riavviare e rieseguire il deploy.

`python scripts/deploy.py validate` controlla la definizione senza bisogno di Metabase: tag delle query coerenti con i filtri dichiarati, card esistenti, layout senza sovrapposizioni.

Le card sono riconosciute **per nome** all'interno della collection gestita: rinominare una card equivale a crearne una nuova (la vecchia si archivia con `--prune`).

## Regole per le query

- I field filter di Metabase generano riferimenti del tipo `"contoso"."v_sales_line"."order_date"`: per questo le tabelle nelle query **non usano alias**.
- Un field filter senza valore diventa `1 = 1`, quindi `WHERE {{order_date}} AND {{category}} AND {{country}}` funziona anche senza filtri attivi.
- Le misure base vanno lette da `contoso.v_sales_line`, non ricalcolate nelle singole query.

## Passaggio al warehouse reale

`02_seed.sql` genera dati sintetici solo per la demo. Per usare il database Contoso reale:

1. creare sul database di produzione lo schema e la vista di `03_semantic_views.sql` (o adattarla ai nomi delle colonne reali);
2. creare un utente in sola lettura;
3. impostare `MB_WAREHOUSE_HOST`, `MB_WAREHOUSE_PORT`, `WAREHOUSE_RO_PASSWORD` e, in `report.yml`, `database.dbname`, `database.user` ed eventualmente `database.engine` (ad esempio `sqlserver`, se si resta su SQL Server; in quel caso le query vanno adattate al dialetto T-SQL).
