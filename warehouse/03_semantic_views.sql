-- Livello semantico: le misure DAX del modello Power BI tradotte in SQL.
-- Le definizioni vivono qui una sola volta e le domande Metabase le riusano.
--
--   Sales Amount   = SUMX(Sales, Quantity * Net Price)
--   Total Cost     = SUMX(Sales, Quantity * Unit Cost)
--   Margin         = Sales Amount - Total Cost
--   Margin %       = DIVIDE(Margin, Sales Amount)
--   Total Quantity = SUM(Quantity)

CREATE VIEW contoso.v_sales_line AS
SELECT sales.order_number,
       sales.line_number,
       sales.order_date,
       sales.customer_key,
       sales.product_key,
       sales.store_key,
       sales.quantity,
       sales.quantity * sales.net_price                         AS sales_amount,
       sales.quantity * sales.unit_cost                         AS total_cost,
       sales.quantity * (sales.net_price - sales.unit_cost)     AS margin
FROM contoso.sales;

COMMENT ON VIEW contoso.v_sales_line IS
    'Riga di vendita con le misure base (Sales Amount, Total Cost, Margin) già calcolate.';

GRANT SELECT ON ALL TABLES IN SCHEMA contoso TO metabase_ro;
