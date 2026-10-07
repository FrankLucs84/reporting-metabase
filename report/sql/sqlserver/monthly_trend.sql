-- Andamento mensile di vendite, costi e margine.
SELECT DATEFROMPARTS(YEAR(v_sales_line.order_date), MONTH(v_sales_line.order_date), 1) AS month,
       SUM(v_sales_line.sales_amount)                                                   AS sales_amount,
       SUM(v_sales_line.total_cost)                                                     AS total_cost,
       SUM(v_sales_line.margin)                                                         AS margin
FROM contoso.v_sales_line
JOIN contoso.product ON product.product_key = v_sales_line.product_key
JOIN contoso.store   ON store.store_key     = v_sales_line.store_key
WHERE {{order_date}} AND {{category}} AND {{country}}
GROUP BY DATEFROMPARTS(YEAR(v_sales_line.order_date), MONTH(v_sales_line.order_date), 1)
ORDER BY month
