-- Quota di progetti completati entro la data di fine prevista.
-- Esclusi i progetti con date indicative (es. periodo del ruolo): restituisce vuoto se non ce ne sono.
SELECT CAST(SUM(CASE WHEN v_progetto_kpi.date_indicative = 0 AND v_progetto_kpi.data_fine_effettiva <= v_progetto_kpi.data_fine_prevista THEN 1 ELSE 0 END) AS decimal(10,4))
       / NULLIF(SUM(CASE WHEN v_progetto_kpi.date_indicative = 0 AND v_progetto_kpi.stato = N'Completato'
                         AND v_progetto_kpi.data_fine_prevista IS NOT NULL THEN 1 ELSE 0 END), 0) AS puntualita
FROM portfolio.v_progetto_kpi
WHERE {{approccio}} AND {{stato}} AND {{settore}}
