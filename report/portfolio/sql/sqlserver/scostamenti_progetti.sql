-- Scostamento di tempi e costi dei progetti completati (> 0 = ritardo / sopra budget).
SELECT v_progetto_kpi.nome,
       v_progetto_kpi.scostamento_tempi_pct,
       v_progetto_kpi.scostamento_costi_pct
FROM portfolio.v_progetto_kpi
WHERE {{approccio}} AND {{stato}} AND {{settore}}
  AND v_progetto_kpi.stato = N'Completato'
ORDER BY v_progetto_kpi.data_inizio
