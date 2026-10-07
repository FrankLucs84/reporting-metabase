# Guida: dal report Power BI al report Metabase OSS

Confronto operativo tra il report Contoso "Vendite e Pareto clienti" in **Power BI** (repository `Reporting`, file `.pbix`, misure DAX in `script.cs`) e la sua versione in **Metabase Open Source** gestita come codice (questa repository).

> **Legenda epistemica**
> - **Certo**: verificato in questo progetto (codice eseguito, report pubblicato e interrogato) o caratteristica documentata e stabile del prodotto.
> - **[Inferenza]**: deduzione ragionata, da confermare nel vostro contesto.
> - **[Non verificato]**: informazione che può cambiare (licenze, prezzi, stato delle funzioni) e va controllata sulle fonti ufficiali prima di decidere.

---

## 1. Risposta sintetica

| Domanda | Power BI | Metabase OSS |
|---|---|---|
| Dove sta la logica di calcolo? | Nel modello semantico (DAX) dentro il `.pbix` | In SQL: vista `v_sales_line` e file `report/sql/*.sql` |
| Il report è versionabile in Git? | Il `.pbix` è un file binario: diff non leggibile. Esiste il formato progetto PBIP/TMDL, testuale [Non verificato: stato e funzioni da controllare sulla versione di Power BI Desktop in uso] | Sì, tutto testuale: SQL + YAML + Python (Certo) |
| Come si pubblica? | Pubblicazione manuale da Desktop al servizio, oppure pipeline di deployment (richiedono licenze specifiche [Non verificato]) | `python scripts/deploy.py apply`, idempotente (Certo) |
| Costo di licenza | Licenze per utente o capacità [Non verificato: verificare il listino Microsoft corrente] | Software AGPL gratuito; costi di hosting e gestione a carico vostro (Certo); edizioni Pro/Enterprise a pagamento |
| Punto di forza | Modellazione ricca, DAX, ecosistema Microsoft 365 | Semplicità, SQL standard, self-hosting, "report as code" |
| Punto debole | Versionamento e revisione del codice meno naturali con il `.pbix` | Niente motore semantico tipo DAX; diverse funzioni di governance solo nelle edizioni a pagamento |

**Raccomandazione [Inferenza]:** non sono strumenti mutuamente esclusivi. Metabase OSS è adatto a dashboard operativi diffusi, a basso costo e manutenibili via Git. Power BI resta più adatto ad analisi con modelli semantici complessi (time intelligence, calculation group, what-if) e in contesti già standardizzati su Microsoft 365.

---

## 2. Mappa dei concetti

| Power BI | Metabase OSS | Nota |
|---|---|---|
| Dataset / modello semantico | Database collegato + viste SQL | Il "livello semantico" qui è `warehouse/03_semantic_views.sql` |
| Tabella dei fatti `Sales` | `contoso.sales` / `contoso.v_sales_line` | La vista precalcola le misure base |
| Relazioni del modello (`Sales[CustomerKey] → Customer[CustomerKey]`) | `JOIN` espliciti in ogni query | In Metabase si possono anche dichiarare le chiavi esterne nei metadati |
| Misura DAX | Espressione SQL aggregata | Vedi §3 |
| Tabella disconnessa `Metric[Measure]` + `SWITCH` | Variabile di testo `{{metric}}` + `CASE` | Filtro "Misura Pareto" |
| Slicer | Filtro del dashboard (field filter) | `{{order_date}}`, `{{category}}`, `{{country}}` |
| Visual | Domanda (card) | Una per file SQL |
| Pagina del report | Dashboard | Layout in `report.yml`, griglia di 24 colonne |
| Workspace | Collection | `Contoso - Report Pareto` |
| Pubblicazione al servizio | `deploy.py apply` | Via REST API |
| Tabular Editor / script C# | `report.yml` + `deploy.py` | Stesso obiettivo: gestire il modello da codice |
| Aggiornamento pianificato (refresh) | Non serve: le query vanno sul database a ogni apertura (eventuale cache configurabile) | [Inferenza] su grandi volumi servono indici o tabelle aggregate |
| Row-Level Security | Sandboxing dei dati: **solo edizioni Pro/Enterprise** | In OSS si ottiene con permessi per collection/database o viste dedicate |

---

## 3. Equivalenza delle misure DAX

Le misure provengono da `script.cs` (Tabular Editor) nel repository `Reporting`. L'equivalenza numerica è stata controllata solo sui dati sintetici di questa repository (Certo); sui dati reali Contoso va riverificata [Non verificato].

| Misura DAX | Definizione DAX | Equivalente SQL | Dove |
|---|---|---|---|
| Sales Amount | `SUMX(Sales, Sales[Quantity] * Sales[Net Price])` | `sum(quantity * net_price)` | `v_sales_line.sales_amount` |
| Total Cost | `SUMX(Sales, Sales[Quantity] * Sales[Unit Cost])` | `sum(quantity * unit_cost)` | `v_sales_line.total_cost` |
| Margin | `[Sales Amount] - [Total Cost]` | `sum(margin)` | `v_sales_line.margin` |
| Margin % | `DIVIDE([Margin], [Sales Amount])` | `sum(margin) / nullif(sum(sales_amount), 0)` | `kpi_margin_pct.sql` |
| Total Quantity | `SUM(Sales[Quantity])` | `sum(quantity)` | `kpi_total_quantity.sql` |
| Metric Value | `SWITCH(SELECTEDVALUE(Metric[Measure]), ...)` | `CASE {{metric}} WHEN 'Margin' THEN ... END` | `pareto_customers.sql` |
| Pareto Amount | `WINDOW(x_pos, ABS, x_pos, ABS, points, ORDERBY([@Value], DESC, ...))` | `value` per riga ordinata | `pareto_customers.sql` |
| Pareto Cumulative | `WINDOW(1, ABS, x_pos, ABS, ...)` + `SUMX` | `sum(value) OVER (ORDER BY value DESC ROWS UNBOUNDED PRECEDING)` | `pareto_customers.sql` |
| Pareto % | `DIVIDE([Pareto Cumulative], [Metric Value])` | cumulato / `sum(value) OVER ()` | `cumulative_pct` |
| Customer Name (per posizione) | `WINDOW` + `SELECTCOLUMNS` | colonna `customer` con `rank` | `pareto_customers.sql` |
| Pareto Classic / Classic % | `FILTER(points, [@Value] >= current_value)` | stessa logica con la funzione finestra | `pareto_customers.sql` |
| (nuova) Classe ABC | — | soglie 80% / 95% sul cumulato | `pareto_abc.sql` |

**Differenze da conoscere:**
- **Contesto di filtro**: in DAX una misura si ricalcola automaticamente in base a slicer e visual. In SQL ogni query deve applicare i filtri in modo esplicito; qui lo fanno i `{{tag}}` nella clausola `WHERE`.
- **Parità di valore**: `ORDERBY(..., Customer[CustomerKey], ASC)` in DAX e `ORDER BY value DESC, customer_key` in SQL usano lo stesso criterio per i clienti con valore uguale, quindi l'ordinamento è deterministico in entrambi.
- **DIVIDE**: `DIVIDE` restituisce BLANK se il denominatore è zero; `nullif(..., 0)` restituisce NULL. Il comportamento è equivalente.

---

## 4. Ciclo di vita del report a confronto

Riferimento: i Process Groups del PMI (Process Groups: A Practice Guide, 2023), applicati al ciclo di vita del report come prodotto.

| Process Group | Power BI (attuale) | Metabase as code (proposto) |
|---|---|---|
| **Initiating** | Richiesta di report, identificazione della fonte dati | Uguale; in più la scelta dell'hosting di Metabase |
| **Planning** | Modello a stella, elenco misure DAX, mockup | Modello a stella, viste SQL, `report.yml` come specifica revisionabile |
| **Executing** | Sviluppo in Desktop, Tabular Editor, pubblicazione manuale | Modifica dei file SQL/YAML, pull request, `deploy.py apply` |
| **Monitoring & Controlling** | Revisione visiva; controllo versioni limitato con il `.pbix` | CI su ogni PR (validazione + esecuzione delle query); storico Git delle modifiche |
| **Closing** | Archiviazione del `.pbix` | Tag Git di rilascio; `--prune` per archiviare le card dismesse |

### Knowledge Areas più impattate

- **Integration / Change control**: in Metabase as code ogni modifica è una pull request revisionabile. Questo copre in modo naturale il controllo integrato delle modifiche.
- **Quality**: la CI esegue tutte le query a ogni modifica e ferma le regressioni di sintassi. Non controlla la correttezza dei numeri, che resta un test di accettazione con l'utente di business.
- **Cost**: si sposta il costo dalle licenze all'operatività (hosting, backup, aggiornamenti) [Inferenza].
- **Resource**: servono competenze SQL e minime di Git/Docker al posto delle competenze DAX.
- **Risk**: vedi §7.

---

## 5. Guida operativa: modificare il report in Metabase

| Attività | In Power BI si faceva… | In Metabase as code si fa… |
|---|---|---|
| Correggere una misura | Modifica DAX in Desktop o Tabular Editor, ripubblicazione | Modifica di `warehouse/03_semantic_views.sql` o del file in `report/sql/`, poi `deploy.py apply` |
| Aggiungere un visual | Trascinare il visual sulla pagina | Nuovo file SQL + voce in `cards:` + posizione in `dashboard.layout` |
| Aggiungere uno slicer | Inserire lo slicer e collegarlo alle tabelle | Voce in `filters:` + `{{tag}}` nelle query + filtro in `dashboard.filters` |
| Cambiare formato (€, %) | Formato della misura | `columns:` nella card (`currency: EUR`, `percent: true`) |
| Rimuovere un visual | Eliminarlo dalla pagina | Toglierlo da `report.yml` e lanciare `deploy.py apply --prune` |
| Revisionare una modifica | Confronto manuale tra file `.pbix` | Diff della pull request + CI |
| Tornare indietro | Ripristinare una copia del `.pbix` | `git revert` + `deploy.py apply` |

Prima di ogni deploy: `python scripts/deploy.py validate`.

---

## 6. Quando scegliere cosa

| Scenario | Scelta consigliata | Motivazione |
|---|---|---|
| Dashboard operativi per molti utenti, budget licenze limitato | Metabase OSS | Nessuna licenza per utente [Non verificato: confrontare con il listino Power BI corrente] |
| Analisi con time intelligence complessa, calculation group, what-if | Power BI | DAX e motore VertiPaq sono progettati per questo |
| Organizzazione standardizzata su Microsoft 365 / Entra ID | Power BI | Integrazione nativa con Teams, SharePoint e sicurezza Microsoft |
| Requisiti forti di versionamento, revisione e audit delle modifiche | Metabase as code | Tutto il report è testuale e revisionabile |
| Row-Level Security per molti profili | Power BI, oppure Metabase Pro/Enterprise | In Metabase OSS il sandboxing dei dati non è disponibile |
| Dati che devono restare on-premise | Metabase self-hosted, oppure Power BI Report Server [Non verificato: requisiti di licenza] | Controllo completo dell'infrastruttura |

---

## 7. Rischi, vincoli, dipendenze

| ID | Tipo | Descrizione | Mitigazione | Stato |
|---|---|---|---|---|
| R1 | Rischio | Modifiche fatte dall'interfaccia Metabase sovrascritte dal deploy | Collection separata per l'esplorazione; regola di team "si modifica solo da Git" | Certo (comportamento dello script) |
| R2 | Rischio | Gli aggiornamenti di Metabase cambiano la REST API e il deploy si rompe | Versione fissata in `.env`; prova del deploy in staging prima di aggiornare | [Inferenza] |
| R3 | Rischio | Divergenza numerica tra Power BI e Metabase sui dati reali | Test di riconciliazione dei KPI su uno stesso periodo prima del go-live | [Non verificato] |
| R4 | Vincolo | Niente RLS, SSO SAML/JWT e serializzazione nativa in OSS | Valutare le edizioni Pro/Enterprise se diventano requisiti | Certo (funzioni a pagamento) [Non verificato: perimetro esatto per la versione in uso] |
| R5 | Dipendenza | Serve un'infrastruttura (container, backup del database applicativo) | Ownership IT definita; backup del database `appdb` | [Inferenza] |
| R6 | Vincolo | Le query sono scritte per PostgreSQL | Per SQL Server vanno adattate a T-SQL insieme ai parametri di connessione in `deploy.py` | Certo |

---

## 8. Criteri di accettazione per la migrazione

1. Tutti i KPI del dashboard Metabase coincidono con quelli Power BI su almeno un periodo chiuso, con tolleranza da concordare con il business owner.
2. La CI è verde sul branch principale.
3. Un secondo `deploy.py apply` non crea duplicati: è idempotente (Certo, verificato sui dati sintetici).
4. Un utente di business ha usato i filtri (Periodo, Categoria, Paese, Misura Pareto) e ha confermato che il dashboard è utilizzabile.
5. Le procedure di backup e di aggiornamento di Metabase sono documentate e assegnate a un responsabile.

## 9. Dati mancanti / domande aperte

- Fonte dati di produzione: il report resta su SQL Server Contoso o passa a un warehouse PostgreSQL?
- Numero e profili degli utenti finali: serve Row-Level Security?
- Hosting di Metabase: server interno o cloud, e chi ne è responsabile?
- Il report Power BI va mantenuto in parallelo, e per quanto tempo?
