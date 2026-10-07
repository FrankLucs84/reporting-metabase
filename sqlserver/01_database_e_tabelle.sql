/* ============================================================================
   01 - Crea il database ContosoLab, lo schema "contoso" e le tabelle.
   Da eseguire in SQL Server Management Studio (SSMS) collegati come amministratore.
   Si può rieseguire: le tabelle vengono ricreate da zero (i dati si perdono).
   ============================================================================ */

IF DB_ID(N'ContosoLab') IS NULL
    CREATE DATABASE ContosoLab;
GO

USE ContosoLab;
GO

IF SCHEMA_ID(N'contoso') IS NULL
    EXEC (N'CREATE SCHEMA contoso');
GO

DROP VIEW  IF EXISTS contoso.v_sales_line;
DROP TABLE IF EXISTS contoso.sales;
DROP TABLE IF EXISTS contoso.customer;
DROP TABLE IF EXISTS contoso.product;
DROP TABLE IF EXISTS contoso.store;
DROP TABLE IF EXISTS contoso.[date];
GO

CREATE TABLE contoso.[date] (
    date_key    date         NOT NULL PRIMARY KEY,
    [year]      int          NOT NULL,
    [quarter]   int          NOT NULL,
    [month]     int          NOT NULL,
    month_name  nvarchar(20) NOT NULL,
    year_month  char(7)      NOT NULL
);

CREATE TABLE contoso.customer (
    customer_key int           NOT NULL PRIMARY KEY,
    name         nvarchar(100) NOT NULL,
    city         nvarchar(100) NOT NULL,
    country      nvarchar(50)  NOT NULL,
    continent    nvarchar(50)  NOT NULL
);

CREATE TABLE contoso.product (
    product_key  int           NOT NULL PRIMARY KEY,
    product_name nvarchar(100) NOT NULL,
    brand        nvarchar(50)  NOT NULL,
    category     nvarchar(50)  NOT NULL,
    subcategory  nvarchar(100) NOT NULL,
    unit_cost    decimal(12,2) NOT NULL,
    unit_price   decimal(12,2) NOT NULL
);

CREATE TABLE contoso.store (
    store_key  int           NOT NULL PRIMARY KEY,
    store_name nvarchar(100) NOT NULL,
    country    nvarchar(50)  NOT NULL,
    continent  nvarchar(50)  NOT NULL
);

CREATE TABLE contoso.sales (
    order_number int           NOT NULL,
    line_number  int           NOT NULL,
    order_date   date          NOT NULL REFERENCES contoso.[date] (date_key),
    customer_key int           NOT NULL REFERENCES contoso.customer (customer_key),
    product_key  int           NOT NULL REFERENCES contoso.product (product_key),
    store_key    int           NOT NULL REFERENCES contoso.store (store_key),
    quantity     int           NOT NULL CHECK (quantity > 0),
    net_price    decimal(12,2) NOT NULL,
    unit_cost    decimal(12,2) NOT NULL,
    CONSTRAINT pk_sales PRIMARY KEY (order_number, line_number)
);

CREATE INDEX ix_sales_order_date   ON contoso.sales (order_date);
CREATE INDEX ix_sales_customer_key ON contoso.sales (customer_key);
CREATE INDEX ix_sales_product_key  ON contoso.sales (product_key);
CREATE INDEX ix_sales_store_key    ON contoso.sales (store_key);
GO

PRINT N'Database ContosoLab e tabelle creati.';
