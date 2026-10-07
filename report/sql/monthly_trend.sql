-- Andamento mensile di vendite, costi e margine.
SELECT date_trunc('month', v_sales_line.order_date)::date AS month,
       sum(v_sales_line.sales_amount)                      AS sales_amount,
       sum(v_sales_line.total_cost)                        AS total_cost,
       sum(v_sales_line.margin)                            AS margin
FROM contoso.v_sales_line
JOIN contoso.product ON product.product_key = v_sales_line.product_key
JOIN contoso.store   ON store.store_key     = v_sales_line.store_key
WHERE {{order_date}} AND {{category}} AND {{country}}
GROUP BY 1
ORDER BY 1
