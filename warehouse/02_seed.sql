-- DATI DI ESEMPIO SINTETICI, generati in modo deterministico.
-- Non sono i dati reali Contoso: servono solo per far girare il report in locale.
-- In produzione questo file non si usa e Metabase punta al warehouse reale.

SELECT setseed(0.42);

INSERT INTO contoso.date
SELECT d,
       extract(year FROM d)::int,
       extract(quarter FROM d)::int,
       extract(month FROM d)::int,
       to_char(d, 'TMMonth'),
       to_char(d, 'YYYY-MM')
FROM generate_series(date '2023-01-01', date '2025-12-31', interval '1 day') AS g(d);

INSERT INTO contoso.store
SELECT s,
       'Contoso ' || c.country || ' ' || ((s - 1) / 6 + 1),
       c.country,
       c.continent
FROM generate_series(1, 12) AS s
JOIN (VALUES (0, 'Italia', 'Europa'), (1, 'Germania', 'Europa'), (2, 'Francia', 'Europa'),
             (3, 'Regno Unito', 'Europa'), (4, 'Stati Uniti', 'Nord America'),
             (5, 'Canada', 'Nord America')) AS c(i, country, continent)
  ON c.i = (s - 1) % 6;

INSERT INTO contoso.customer
SELECT k,
       'Cliente ' || lpad(k::text, 4, '0'),
       'Città ' || (k % 40 + 1),
       c.country,
       c.continent
FROM generate_series(1, 500) AS k
JOIN (VALUES (0, 'Italia', 'Europa'), (1, 'Germania', 'Europa'), (2, 'Francia', 'Europa'),
             (3, 'Regno Unito', 'Europa'), (4, 'Stati Uniti', 'Nord America'),
             (5, 'Canada', 'Nord America')) AS c(i, country, continent)
  ON c.i = k % 6;

INSERT INTO contoso.product
SELECT p,
       cat.category || ' ' || lpad(p::text, 3, '0'),
       (ARRAY['Contoso', 'Fabrikam', 'Litware', 'Proseware', 'Adventure Works'])[p % 5 + 1],
       cat.category,
       cat.category || ' - Linea ' || (p % 3 + 1),
       round((cat.base * (0.5 + random()))::numeric, 2) AS unit_cost,
       0
FROM generate_series(1, 60) AS p
JOIN (VALUES (0, 'Audio', 40), (1, 'Computer', 450), (2, 'Fotocamere', 250),
             (3, 'Cellulari', 300), (4, 'TV e Video', 500), (5, 'Casa', 80)) AS cat(i, category, base)
  ON cat.i = p % 6;

UPDATE contoso.product
SET unit_price = round(unit_cost * (1.3 + (product_key % 7) * 0.1), 2);

-- Distribuzione volutamente sbilanciata (random()^3) per ottenere una curva di Pareto realistica.
INSERT INTO contoso.sales
SELECT o.n + 1                                                AS order_number,
       1                                                      AS line_number,
       date '2023-01-01' + floor(random() * 1095)::int        AS order_date,
       1 + floor(500 * power(random(), 3))::int               AS customer_key,
       pr.product_key,
       1 + floor(random() * 12)::int                          AS store_key,
       1 + floor(random() * 5)::int                           AS quantity,
       round(pr.unit_price * (0.85 + random() * 0.15)::numeric, 2)     AS net_price,
       pr.unit_cost
FROM (SELECT n, 1 + floor(random() * 60)::int AS product_key
      FROM generate_series(0, 29999) AS n) AS o
JOIN contoso.product AS pr ON pr.product_key = o.product_key;

ANALYZE;
