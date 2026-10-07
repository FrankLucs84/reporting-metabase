SELECT SUM(v_sales_line.margin) / NULLIF(SUM(v_sales_line.sales_amount), 0) AS margin_pct
FROM contoso.v_sales_line
JOIN contoso.product ON product.product_key = v_sales_line.product_key
JOIN contoso.store   ON store.store_key     = v_sales_line.store_key
WHERE {{order_date}} AND {{category}} AND {{country}}
