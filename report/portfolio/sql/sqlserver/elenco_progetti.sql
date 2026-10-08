SELECT v_progetto_kpi.codice,
       v_progetto_kpi.nome,
       v_progetto_kpi.settore,
       v_progetto_kpi.approccio,
       v_progetto_kpi.ruolo,
       v_progetto_kpi.stato,
       v_progetto_kpi.data_inizio,
       v_progetto_kpi.data_fine_prevista,
       v_progetto_kpi.data_fine_effettiva,
       v_progetto_kpi.pubblicabile
FROM portfolio.v_progetto_kpi
WHERE {{approccio}} AND {{stato}} AND {{settore}}
ORDER BY v_progetto_kpi.data_inizio DESC
