/* ============================================================================
   02 - Carica DATI DI ESEMPIO SINTETICI (non sono i dati reali Contoso).
   Sempre gli stessi a ogni esecuzione: i numeri "casuali" sono calcolati
   da una formula fissa (hash MD5), così i risultati sono confrontabili.
   Tempo di esecuzione: pochi secondi.
   ============================================================================ */

USE ContosoLab;
GO

SET NOCOUNT ON;

DELETE FROM contoso.sales;
DELETE FROM contoso.customer;
DELETE FROM contoso.product;
DELETE FROM contoso.store;
DELETE FROM contoso.[date];

-- Tabella numeri 0..99999 (serve a generare righe senza cicli)
DROP TABLE IF EXISTS #numbers;
WITH d AS (SELECT v FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) AS t(v))
SELECT a.v + 10 * b.v + 100 * c.v + 1000 * e.v + 10000 * f.v AS n
INTO #numbers
FROM d AS a CROSS JOIN d AS b CROSS JOIN d AS c CROSS JOIN d AS e CROSS JOIN d AS f;

-- Paesi usati per clienti e punti vendita
DECLARE @countries TABLE (i int, country nvarchar(50), continent nvarchar(50));
INSERT INTO @countries VALUES
    (0, N'Italia', N'Europa'), (1, N'Germania', N'Europa'), (2, N'Francia', N'Europa'),
    (3, N'Regno Unito', N'Europa'), (4, N'Stati Uniti', N'Nord America'), (5, N'Canada', N'Nord America');

-- Calendario 2023-2025
INSERT INTO contoso.[date] (date_key, [year], [quarter], [month], month_name, year_month)
SELECT d, YEAR(d), DATEPART(quarter, d), MONTH(d), FORMAT(d, 'MMMM', 'it-IT'), FORMAT(d, 'yyyy-MM')
FROM (SELECT DATEADD(day, n, CAST('2023-01-01' AS date)) AS d FROM #numbers WHERE n < 1096) AS x;

-- 12 punti vendita
INSERT INTO contoso.store (store_key, store_name, country, continent)
SELECT s, N'Contoso ' + c.country + N' ' + CAST((s - 1) / 6 + 1 AS nvarchar(5)), c.country, c.continent
FROM (SELECT n AS s FROM #numbers WHERE n BETWEEN 1 AND 12) AS x
JOIN @countries AS c ON c.i = (s - 1) % 6;

-- 500 clienti
INSERT INTO contoso.customer (customer_key, name, city, country, continent)
SELECT k, N'Cliente ' + RIGHT(N'0000' + CAST(k AS nvarchar(5)), 4),
       N'Città ' + CAST(k % 40 + 1 AS nvarchar(5)), c.country, c.continent
FROM (SELECT n AS k FROM #numbers WHERE n BETWEEN 1 AND 500) AS x
JOIN @countries AS c ON c.i = k % 6;

-- 60 prodotti in 6 categorie
DECLARE @categories TABLE (i int, category nvarchar(50), base decimal(12,2));
INSERT INTO @categories VALUES
    (0, N'Audio', 40), (1, N'Computer', 450), (2, N'Fotocamere', 250),
    (3, N'Cellulari', 300), (4, N'TV e Video', 500), (5, N'Casa', 80);

INSERT INTO contoso.product (product_key, product_name, brand, category, subcategory, unit_cost, unit_price)
SELECT p,
       cat.category + N' ' + RIGHT(N'000' + CAST(p AS nvarchar(5)), 3),
       CHOOSE(p % 5 + 1, N'Contoso', N'Fabrikam', N'Litware', N'Proseware', N'Adventure Works'),
       cat.category,
       cat.category + N' - Linea ' + CAST(p % 3 + 1 AS nvarchar(5)),
       ROUND(cat.base * (0.5 + r.v), 2),
       ROUND(ROUND(cat.base * (0.5 + r.v), 2) * (1.3 + (p % 7) * 0.1), 2)
FROM (SELECT n AS p FROM #numbers WHERE n BETWEEN 1 AND 60) AS x
JOIN @categories AS cat ON cat.i = p % 6
CROSS APPLY (SELECT CAST(SUBSTRING(HASHBYTES('MD5', CONCAT(N'prodotto-', p)), 1, 3) AS int) / 16777216.0 AS v) AS r;

-- 30.000 righe di vendita. Ogni byte dell'hash MD5 dà un numero tra 0 e 1.
-- Il cliente è scelto con r^3 per ottenere una curva di Pareto realistica.
INSERT INTO contoso.sales (order_number, line_number, order_date, customer_key, product_key, store_key,
                           quantity, net_price, unit_cost)
SELECT n + 1,
       1,
       DATEADD(day, CAST(r1 * 1095 AS int), CAST('2023-01-01' AS date)),
       1 + CAST(500 * r2 * r2 * r2 AS int),
       pr.product_key,
       1 + CAST(r3 * 12 AS int),
       1 + CAST(r4 * 5 AS int),
       ROUND(pr.unit_price * (0.85 + r5 * 0.15), 2),
       pr.unit_cost
FROM (
    SELECT n,
           CAST(SUBSTRING(h, 1, 3)  AS int) / 16777216.0 AS r1,
           CAST(SUBSTRING(h, 4, 3)  AS int) / 16777216.0 AS r2,
           CAST(SUBSTRING(h, 7, 3)  AS int) / 16777216.0 AS r3,
           CAST(SUBSTRING(h, 10, 3) AS int) / 16777216.0 AS r4,
           CAST(SUBSTRING(h, 13, 3) AS int) / 16777216.0 AS r5,
           1 + CAST(SUBSTRING(h, 16, 1) AS int) % 60     AS product_key
    FROM #numbers
    CROSS APPLY (SELECT HASHBYTES('MD5', CONCAT(N'vendita-', n)) AS h) AS hash
    WHERE n < 30000
) AS x
JOIN contoso.product AS pr ON pr.product_key = x.product_key;

DROP TABLE #numbers;

SELECT (SELECT COUNT(*) FROM contoso.[date])   AS giorni,
       (SELECT COUNT(*) FROM contoso.customer) AS clienti,
       (SELECT COUNT(*) FROM contoso.product)  AS prodotti,
       (SELECT COUNT(*) FROM contoso.store)    AS negozi,
       (SELECT COUNT(*) FROM contoso.sales)    AS righe_vendita;
GO
