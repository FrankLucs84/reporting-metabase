SELECT v_progetto_kpi.approccio,
       COUNT(*) AS progetti
FROM portfolio.v_progetto_kpi
WHERE {{approccio}} AND {{stato}} AND {{settore}}
GROUP BY v_progetto_kpi.approccio
ORDER BY progetti DESC
