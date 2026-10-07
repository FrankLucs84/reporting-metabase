/* ============================================================================
   03 - Livello semantico: le misure DAX del modello Power BI tradotte in SQL.
   Le formule vivono qui una sola volta; i grafici di Metabase le riusano.

     Sales Amount   = SUMX(Sales, Quantity * Net Price)
     Total Cost     = SUMX(Sales, Quantity * Unit Cost)
     Margin         = Sales Amount - Total Cost
     Margin %       = DIVIDE(Margin, Sales Amount)     -> calcolata nelle domande
     Total Quantity = SUM(Quantity)                    -> calcolata nelle domande
   ============================================================================ */

USE ContosoLab;
GO

CREATE OR ALTER VIEW contoso.v_sales_line AS
SELECT sales.order_number,
       sales.line_number,
       sales.order_date,
       sales.customer_key,
       sales.product_key,
       sales.store_key,
       sales.quantity,
       sales.quantity * sales.net_price                     AS sales_amount,
       sales.quantity * sales.unit_cost                     AS total_cost,
       sales.quantity * (sales.net_price - sales.unit_cost) AS margin
FROM contoso.sales;
GO

PRINT N'Vista contoso.v_sales_line creata.';
