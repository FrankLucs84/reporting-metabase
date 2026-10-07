-- Pareto clienti (equivalente di [Pareto Cumulative] / [Pareto %] in DAX).
-- {{metric}} sostituisce la tabella disconnessa Metric[Measure] di Power BI.
WITH points AS (
    SELECT customer.customer_key,
           customer.name AS customer,
           CASE {{metric}}
               WHEN 'Margin'         THEN SUM(v_sales_line.margin)
               WHEN 'Total Cost'     THEN SUM(v_sales_line.total_cost)
               WHEN 'Total Quantity' THEN SUM(CAST(v_sales_line.quantity AS decimal(18,2)))
               ELSE                       SUM(v_sales_line.sales_amount)
           END AS value
    FROM contoso.v_sales_line
    JOIN contoso.product  ON product.product_key   = v_sales_line.product_key
    JOIN contoso.store    ON store.store_key       = v_sales_line.store_key
    JOIN contoso.customer ON customer.customer_key = v_sales_line.customer_key
    WHERE {{order_date}} AND {{category}} AND {{country}}
    GROUP BY customer.customer_key, customer.name
),
ranked AS (
    SELECT customer,
           value,
           ROW_NUMBER() OVER (ORDER BY value DESC, customer_key) AS rank,
           SUM(value) OVER (ORDER BY value DESC, customer_key
                            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
             / NULLIF(SUM(value) OVER (), 0) AS cumulative_pct
    FROM points
)
SELECT rank, customer, value, cumulative_pct
FROM ranked
ORDER BY rank
