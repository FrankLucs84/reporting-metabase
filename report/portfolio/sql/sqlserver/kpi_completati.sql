SELECT SUM(CASE WHEN v_progetto_kpi.stato = N'Completato' THEN 1 ELSE 0 END) AS completati
FROM portfolio.v_progetto_kpi
WHERE {{approccio}} AND {{stato}} AND {{settore}}
