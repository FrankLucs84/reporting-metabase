-- Performance per paese del punto vendita (filiali).
SELECT store.country,
       COUNT(DISTINCT store.store_key)                                       AS stores,
       SUM(v_sales_line.sales_amount)                                        AS sales_amount,
       SUM(v_sales_line.margin)                                              AS margin,
       SUM(v_sales_line.margin) / NULLIF(SUM(v_sales_line.sales_amount), 0)  AS margin_pct,
       SUM(v_sales_line.quantity)                                            AS total_quantity
FROM contoso.v_sales_line
JOIN contoso.product ON product.product_key = v_sales_line.product_key
JOIN contoso.store   ON store.store_key     = v_sales_line.store_key
WHERE {{order_date}} AND {{category}} AND {{country}}
GROUP BY store.country
ORDER BY sales_amount DESC
