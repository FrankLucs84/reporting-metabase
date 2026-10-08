SELECT COUNT(*) AS progetti
FROM portfolio.v_progetto_kpi
WHERE {{approccio}} AND {{stato}} AND {{settore}}
