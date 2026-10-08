#!/usr/bin/env python3
"""Esporta i dati PUBBLICABILI del portfolio in portfolio-site/data.json.

Legge il database PortfolioLab passando da Metabase (stessa connessione del
report), quindi non servono driver ODBC sul PC. Esporta solo:
  - le righe con pubblicabile = 1;
  - nessun importo in euro: dei costi pubblica solo lo scostamento percentuale.

Uso (Metabase acceso e report portfolio già pubblicato con deploy.py):
    python scripts/export_portfolio.py
Poi pubblicate il file con git (vedi docs/GUIDA_PORTFOLIO.md).
"""

import json
import sys
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import deploy  # noqa: E402  (riusa .env, login e chiamate API)

ROOT = Path(__file__).resolve().parent.parent
OUTPUT = ROOT / "portfolio-site" / "data.json"
DATABASE_NAME = "Portfolio (SQL Server)"

QUERIES = {
    "progetti": """
        SELECT codice, nome, organizzazione, settore, approccio, ruolo, stato,
               data_inizio, data_fine_prevista, data_fine_effettiva, date_indicative,
               scostamento_tempi_pct, scostamento_costi_pct,
               soddisfazione_cliente, descrizione
        FROM portfolio.v_progetto_kpi
        WHERE pubblicabile = 1
        ORDER BY data_inizio, codice""",
    "competenze": """
        SELECT competenza.nome, competenza.area, competenza.livello
        FROM portfolio.competenza
        ORDER BY competenza.area, competenza.nome""",
    "progetto_competenze": """
        SELECT progetto.codice, competenza.nome AS competenza
        FROM portfolio.progetto_competenza
        JOIN portfolio.progetto   ON progetto.progetto_id     = progetto_competenza.progetto_id
        JOIN portfolio.competenza ON competenza.competenza_id = progetto_competenza.competenza_id
        WHERE progetto.pubblicabile = 1""",
    "formazione": """
        SELECT titolo, ente, tipo, area, data_conseguimento, ore, pdu, credenziale_url
        FROM portfolio.formazione
        WHERE pubblicabile = 1
        ORDER BY CASE WHEN data_conseguimento IS NULL THEN 1 ELSE 0 END, data_conseguimento, titolo""",
    "casi": """
        SELECT titolo, dataset, strumenti, data_pubblicazione, link_url, descrizione
        FROM portfolio.caso_analisi
        WHERE pubblicabile = 1
        ORDER BY data_pubblicazione DESC""",
}


def run_query(mb, db_id, sql):
    result = mb.call("POST", "/dataset", json={
        "database": db_id, "type": "native", "native": {"query": sql},
    })
    if result.get("status") != "completed":
        sys.exit(f"Query non riuscita: {result.get('error')}")
    columns = [c["name"] for c in result["data"]["cols"]]
    rows = []
    for values in result["data"]["rows"]:
        row = {}
        for column, value in zip(columns, values):
            if isinstance(value, str) and len(value) >= 10 and value[4] == "-" and "T" in value:
                value = value[:10]  # le date arrivano come timestamp: teniamo AAAA-MM-GG
            row[column] = value
        rows.append(row)
    return rows


def main():
    deploy.load_env()
    mb = deploy.Metabase(deploy.env("MB_URL", "http://localhost:3000"))
    mb.wait_until_healthy(timeout=60)
    mb.login(deploy.env("MB_ADMIN_EMAIL"), deploy.env("MB_ADMIN_PASSWORD"), "Reporting")

    database = next((d for d in deploy.as_list(mb.call("GET", "/database")) if d["name"] == DATABASE_NAME), None)
    if database is None:
        sys.exit(f"Database '{DATABASE_NAME}' non trovato: pubblicate prima il report portfolio con deploy.py")

    data = {name: run_query(mb, database["id"], sql) for name, sql in QUERIES.items()}
    data["contiene_esempi"] = any(p["codice"].startswith("ESEMPIO-") for p in data["progetti"]) or any(
        f["titolo"].startswith("[Esempio]") for f in data["formazione"])
    data["aggiornato_il"] = datetime.now(timezone.utc).strftime("%Y-%m-%d")

    OUTPUT.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Esportati {len(data['progetti'])} progetti, {len(data['formazione'])} attività di formazione, "
          f"{len(data['casi'])} casi di analisi -> {OUTPUT.relative_to(ROOT)}")
    if data["contiene_esempi"]:
        print("ATTENZIONE: l'export contiene ancora dati di esempio (vedi sqlserver/portfolio/05_cancella_esempi.sql)")


if __name__ == "__main__":
    main()
