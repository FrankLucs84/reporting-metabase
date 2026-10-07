#!/usr/bin/env python3
"""Applica report/report.yml a un'istanza Metabase OSS tramite REST API.

Metabase OSS non include la serializzazione (export/import YAML), che è una
funzione a pagamento: questo script la sostituisce per il nostro report.
È idempotente: crea ciò che manca e aggiorna ciò che esiste, riconoscendo
domande e dashboard dal nome dentro la collection gestita.

Uso:
    python scripts/deploy.py validate          # controlla la definizione, senza Metabase
    python scripts/deploy.py apply             # crea o aggiorna il report
    python scripts/deploy.py apply --prune     # archivia anche le domande non più definite

Configurazione da variabili d'ambiente o dal file .env (vedi .env.example).
"""

import argparse
import json
import os
import re
import sys
import time
import uuid
from pathlib import Path

import requests
import yaml

ROOT = Path(__file__).resolve().parent.parent
REPORT_DIR = ROOT / "report"
ID_NAMESPACE = uuid.UUID("6f6d1c2e-6f0b-4c5e-9d64-7265706f7274")
DISPLAYS = {"scalar", "line", "bar", "combo", "table", "row", "pie", "area"}
GRID_WIDTH = 24


def load_env():
    env_file = ROOT / ".env"
    if env_file.exists():
        for line in env_file.read_text().splitlines():
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                key, value = line.split("=", 1)
                os.environ.setdefault(key.strip(), value.strip())


def env(name, default=None):
    value = os.environ.get(name, default)
    if value is None:
        sys.exit(f"Variabile d'ambiente mancante: {name}")
    return value


def stable_id(*parts):
    return str(uuid.uuid5(ID_NAMESPACE, "/".join(parts)))


# --------------------------------------------------------------------------- validate

def load_report():
    report = yaml.safe_load((REPORT_DIR / "report.yml").read_text())
    for card in report["cards"]:
        card["query"] = (REPORT_DIR / card["sql"]).read_text()
    return report


def validate(report):
    errors = []
    filters = {f["key"]: f for f in report["filters"]}
    card_names = [c["name"] for c in report["cards"]]

    for f in report["filters"]:
        if ("field" in f) == ("values" in f):
            errors.append(f"filtro {f['key']}: serve esattamente uno tra 'field' e 'values'")

    for card in report["cards"]:
        where = f"card '{card['name']}'"
        if card["display"] not in DISPLAYS:
            errors.append(f"{where}: display '{card['display']}' non supportato")
        tags = set(re.findall(r"{{\s*(\w+)\s*}}", card["query"]))
        declared = set(card.get("filters", []))
        if tags != declared:
            errors.append(f"{where}: tag nella query {sorted(tags)} diversi dai filtri dichiarati {sorted(declared)}")
        for key in declared - filters.keys():
            errors.append(f"{where}: filtro '{key}' non definito")

    if len(card_names) != len(set(card_names)):
        errors.append("nomi delle card duplicati")

    dash = report["dashboard"]
    occupied = {}
    for item in dash["layout"]:
        if item["card"] not in card_names:
            errors.append(f"layout: card '{item['card']}' non definita")
        if item["col"] + item["width"] > GRID_WIDTH:
            errors.append(f"layout: '{item['card']}' esce dalla griglia di {GRID_WIDTH} colonne")
        for r in range(item["row"], item["row"] + item["height"]):
            for c in range(item["col"], item["col"] + item["width"]):
                if (r, c) in occupied:
                    errors.append(f"layout: '{item['card']}' si sovrappone a '{occupied[(r, c)]}'")
                    break
                occupied[(r, c)] = item["card"]
            else:
                continue
            break
    for key in set(dash["filters"]) - filters.keys():
        errors.append(f"dashboard: filtro '{key}' non definito")

    return errors


# --------------------------------------------------------------------------- Metabase API

class Metabase:
    def __init__(self, url):
        self.url = url.rstrip("/")
        self.http = requests.Session()

    def call(self, method, path, **kwargs):
        response = self.http.request(method, f"{self.url}/api{path}", timeout=60, **kwargs)
        if response.status_code >= 400:
            raise RuntimeError(f"{method} {path} -> {response.status_code}: {response.text[:500]}")
        return response.json() if response.content else None

    def wait_until_healthy(self, timeout=300):
        deadline = time.time() + timeout
        while time.time() < deadline:
            try:
                if self.http.get(f"{self.url}/api/health", timeout=5).json().get("status") == "ok":
                    return
            except (requests.RequestException, ValueError):
                pass
            time.sleep(3)
        sys.exit(f"Metabase non risponde su {self.url}")

    def login(self, email, password, site_name):
        props = self.call("GET", "/session/properties")
        if not props.get("has-user-setup"):
            print("Prima configurazione di Metabase: creo l'utente amministratore")
            self.call("POST", "/setup", json={
                "token": props["setup-token"],
                "user": {"email": email, "password": password,
                         "first_name": "Admin", "last_name": "Reporting", "site_name": site_name},
                "prefs": {"site_name": site_name, "site_locale": "it", "allow_tracking": False},
            })
        session = self.call("POST", "/session", json={"username": email, "password": password})
        self.http.headers["X-Metabase-Session"] = session["id"]


def as_list(payload):
    return payload["data"] if isinstance(payload, dict) and "data" in payload else payload


def ensure_database(mb, spec):
    details = {
        "host": env("MB_WAREHOUSE_HOST", "warehouse"),
        "port": int(env("MB_WAREHOUSE_PORT", "5432")),
        "dbname": spec["dbname"],
        "user": spec["user"],
        "password": env("WAREHOUSE_RO_PASSWORD"),
        "ssl": False,
        "schema-filters-type": "inclusion",
        "schema-filters-patterns": spec["schema"],
    }
    existing = next((d for d in as_list(mb.call("GET", "/database")) if d["name"] == spec["name"]), None)
    if existing:
        mb.call("PUT", f"/database/{existing['id']}", json={"details": details})
        mb.call("POST", f"/database/{existing['id']}/sync_schema")
        print(f"Database '{spec['name']}' aggiornato (id {existing['id']})")
        return existing["id"]
    created = mb.call("POST", "/database", json={"engine": spec["engine"], "name": spec["name"], "details": details})
    print(f"Database '{spec['name']}' creato (id {created['id']})")
    return created["id"]


def field_ids(mb, db_id, needed, timeout=240):
    """Restituisce {(tabella, colonna): field_id}, attendendo la fine della sincronizzazione."""
    deadline = time.time() + timeout
    while True:
        metadata = mb.call("GET", f"/database/{db_id}/metadata")
        found = {(t["name"], f["name"]): f["id"] for t in metadata["tables"] for f in t["fields"]}
        missing = [n for n in needed if n not in found]
        if not missing:
            return found
        if time.time() > deadline:
            sys.exit(f"Colonne non trovate dopo la sincronizzazione: {missing}")
        time.sleep(5)


def ensure_collection(mb, spec):
    existing = next((c for c in mb.call("GET", "/collection")
                     if c.get("name") == spec["name"] and not c.get("archived")), None)
    if existing:
        return existing["id"]
    return mb.call("POST", "/collection", json={"name": spec["name"], "description": spec.get("description")})["id"]


def collection_items(mb, collection_id, model):
    return {i["name"]: i["id"] for i in as_list(mb.call("GET", f"/collection/{collection_id}/items",
                                                        params={"models": model}))}


def template_tags(card, filters, fields):
    tags = {}
    for key in card.get("filters", []):
        f = filters[key]
        tag = {"id": stable_id("tag", card["name"], key), "name": key, "display-name": f["name"]}
        if "field" in f:
            tag.update({"type": "dimension", "widget-type": f["type"],
                        "dimension": ["field", fields[tuple(f["field"])], None]})
        else:
            tag.update({"type": "text"})
        if "default" in f:
            tag["default"] = f["default"]
        if f.get("required"):
            tag["required"] = True
        tags[key] = tag
    return tags


def visualization_settings(card):
    settings = {}
    if card.get("x"):
        settings["graph.dimensions"] = card["x"]
    if card.get("y"):
        settings["graph.metrics"] = card["y"]
    column_settings = {}
    for column, fmt in (card.get("columns") or {}).items():
        style = {}
        if fmt.get("currency"):
            style.update({"number_style": "currency", "currency": fmt["currency"], "currency_style": "symbol"})
        if fmt.get("percent"):
            style["number_style"] = "percent"
        if fmt.get("title"):
            style["column_title"] = fmt["title"]
        column_settings[json.dumps(["name", column], separators=(",", ":"))] = style
    if column_settings:
        settings["column_settings"] = column_settings
    if card.get("x_title"):
        settings["graph.x_axis.title_text"] = card["x_title"]
    if card.get("y_title"):
        settings["graph.y_axis.title_text"] = card["y_title"]
    # Nei grafici il nome della serie si imposta in series_settings, non in column_settings.
    series = {column: {"title": fmt["title"]} for column, fmt in (card.get("columns") or {}).items()
              if fmt.get("title") and column in card.get("y", [])}
    for column, s in (card.get("series") or {}).items():
        series.setdefault(column, {}).update({k: v for k, v in s.items() if k in ("display", "axis", "title")})
    if series and card["display"] not in ("table", "scalar"):
        settings["series_settings"] = series
    return settings


def upsert_cards(mb, report, db_id, collection_id, fields, prune):
    filters = {f["key"]: f for f in report["filters"]}
    existing = collection_items(mb, collection_id, "card")
    ids = {}
    for card in report["cards"]:
        body = {
            "name": card["name"],
            "description": card.get("description"),
            "collection_id": collection_id,
            "display": card["display"],
            "visualization_settings": visualization_settings(card),
            "dataset_query": {
                "type": "native",
                "database": db_id,
                "native": {"query": card["query"], "template-tags": template_tags(card, filters, fields)},
            },
        }
        if card["name"] in existing:
            ids[card["name"]] = existing[card["name"]]
            mb.call("PUT", f"/card/{ids[card['name']]}", json=body)
            print(f"  aggiornata  {card['name']}")
        else:
            ids[card["name"]] = mb.call("POST", "/card", json=body)["id"]
            print(f"  creata      {card['name']}")
    for name, card_id in existing.items():
        if name not in ids:
            if prune:
                mb.call("PUT", f"/card/{card_id}", json={"archived": True})
                print(f"  archiviata  {name}")
            else:
                print(f"  non gestita {name} (usa --prune per archiviarla)")
    return ids


def upsert_dashboard(mb, report, collection_id, card_ids):
    dash = report["dashboard"]
    filters = {f["key"]: f for f in report["filters"]}
    cards = {c["name"]: c for c in report["cards"]}

    existing = collection_items(mb, collection_id, "dashboard")
    if dash["name"] in existing:
        dash_id = existing[dash["name"]]
    else:
        dash_id = mb.call("POST", "/dashboard", json={"name": dash["name"], "collection_id": collection_id})["id"]

    parameters = []
    for key in dash["filters"]:
        f = filters[key]
        param = {"id": stable_id("param", key)[:8], "name": f["name"], "slug": key, "type": f["type"],
                 "sectionId": "date" if f["type"].startswith("date") else "string"}
        if "values" in f:
            param.update({"values_source_type": "static-list", "values_source_config": {"values": f["values"]}})
        if "default" in f:
            param["default"] = [f["default"]] if f["type"].startswith("string") else f["default"]
        if f.get("required"):
            param["required"] = True
        parameters.append(param)
    param_ids = {p["slug"]: p["id"] for p in parameters}

    dashcards = []
    for i, item in enumerate(dash["layout"], start=1):
        card = cards[item["card"]]
        mappings = []
        for key in card.get("filters", []):
            if key in param_ids:
                kind = "dimension" if "field" in filters[key] else "variable"
                mappings.append({"parameter_id": param_ids[key], "card_id": card_ids[card["name"]],
                                 "target": [kind, ["template-tag", key]]})
        # id negativi = nuove dashcard: il layout viene ricostruito interamente a ogni deploy
        dashcards.append({"id": -i, "card_id": card_ids[card["name"]], "row": item["row"], "col": item["col"],
                          "size_x": item["width"], "size_y": item["height"],
                          "parameter_mappings": mappings, "visualization_settings": {}})

    mb.call("PUT", f"/dashboard/{dash_id}", json={
        "name": dash["name"], "description": dash.get("description"),
        "parameters": parameters, "dashcards": dashcards,
    })
    return dash_id


def apply(report, prune):
    mb = Metabase(env("MB_URL", "http://localhost:3000"))
    mb.wait_until_healthy()
    mb.login(env("MB_ADMIN_EMAIL"), env("MB_ADMIN_PASSWORD"), "Reporting")

    db_id = ensure_database(mb, report["database"])
    needed = [tuple(f["field"]) for f in report["filters"] if "field" in f]
    fields = field_ids(mb, db_id, needed)
    collection_id = ensure_collection(mb, report["collection"])
    print(f"Collection '{report['collection']['name']}' (id {collection_id})")
    card_ids = upsert_cards(mb, report, db_id, collection_id, fields, prune)
    dash_id = upsert_dashboard(mb, report, collection_id, card_ids)
    print(f"Dashboard pronto: {mb.url}/dashboard/{dash_id}")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("command", choices=["validate", "apply"])
    parser.add_argument("--prune", action="store_true", help="archivia le domande non più presenti in report.yml")
    args = parser.parse_args()

    load_env()
    report = load_report()
    errors = validate(report)
    if errors:
        print("Definizione del report non valida:")
        for error in errors:
            print(f"  - {error}")
        sys.exit(1)
    print(f"Definizione valida: {len(report['cards'])} domande, {len(report['dashboard']['layout'])} riquadri")
    if args.command == "apply":
        apply(report, args.prune)


if __name__ == "__main__":
    main()
