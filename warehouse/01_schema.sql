-- Star schema Contoso (sottoinsieme usato dal report Pareto).
-- Rispecchia le tabelle del modello Power BI: Sales, Customer, Product, Store, Date.

CREATE SCHEMA IF NOT EXISTS contoso;

CREATE TABLE contoso.date (
    date_key    date PRIMARY KEY,
    year        int  NOT NULL,
    quarter     int  NOT NULL,
    month       int  NOT NULL,
    month_name  text NOT NULL,
    year_month  text NOT NULL
);

CREATE TABLE contoso.customer (
    customer_key int  PRIMARY KEY,
    name         text NOT NULL,
    city         text NOT NULL,
    country      text NOT NULL,
    continent    text NOT NULL
);

CREATE TABLE contoso.product (
    product_key  int     PRIMARY KEY,
    product_name text    NOT NULL,
    brand        text    NOT NULL,
    category     text    NOT NULL,
    subcategory  text    NOT NULL,
    unit_cost    numeric(12,2) NOT NULL,
    unit_price   numeric(12,2) NOT NULL
);

CREATE TABLE contoso.store (
    store_key  int  PRIMARY KEY,
    store_name text NOT NULL,
    country    text NOT NULL,
    continent  text NOT NULL
);

CREATE TABLE contoso.sales (
    order_number int  NOT NULL,
    line_number  int  NOT NULL,
    order_date   date NOT NULL REFERENCES contoso.date (date_key),
    customer_key int  NOT NULL REFERENCES contoso.customer (customer_key),
    product_key  int  NOT NULL REFERENCES contoso.product (product_key),
    store_key    int  NOT NULL REFERENCES contoso.store (store_key),
    quantity     int  NOT NULL CHECK (quantity > 0),
    net_price    numeric(12,2) NOT NULL,
    unit_cost    numeric(12,2) NOT NULL,
    PRIMARY KEY (order_number, line_number)
);

CREATE INDEX ON contoso.sales (order_date);
CREATE INDEX ON contoso.sales (customer_key);
CREATE INDEX ON contoso.sales (product_key);
CREATE INDEX ON contoso.sales (store_key);
