SELECT COALESCE(v_progetto_kpi.approccio, N'Non indicato') AS approccio,
       COUNT(*) AS progetti
FROM portfolio.v_progetto_kpi
WHERE {{approccio}} AND {{stato}} AND {{settore}}
GROUP BY COALESCE(v_progetto_kpi.approccio, N'Non indicato')
ORDER BY progetti DESC
