/* ============================================================================
   PORTFOLIO 02 - Vista con i KPI di progetto (tempi e costi).
     durata_prevista_gg   = giorni tra inizio e fine prevista
     durata_effettiva_gg  = giorni tra inizio e fine effettiva (vuota se in corso)
     scostamento_tempi_pct= (durata effettiva - prevista) / prevista   (> 0 = ritardo)
     scostamento_costi_pct= (costo effettivo - budget) / budget        (> 0 = sopra budget)
                            calcolato solo sui progetti Completati: a progetto in corso
                            il costo sostenuto finora non è confrontabile con il budget totale
   ============================================================================ */

USE PortfolioLab;
GO

CREATE OR ALTER VIEW portfolio.v_progetto_kpi AS
SELECT progetto.progetto_id,
       progetto.codice,
       progetto.nome,
       progetto.settore,
       progetto.approccio,
       progetto.ruolo,
       progetto.stato,
       progetto.data_inizio,
       progetto.data_fine_prevista,
       progetto.data_fine_effettiva,
       YEAR(progetto.data_inizio)                                            AS anno_inizio,
       DATEDIFF(day, progetto.data_inizio, progetto.data_fine_prevista)      AS durata_prevista_gg,
       DATEDIFF(day, progetto.data_inizio, progetto.data_fine_effettiva)     AS durata_effettiva_gg,
       CAST(DATEDIFF(day, progetto.data_inizio, progetto.data_fine_effettiva)
            - DATEDIFF(day, progetto.data_inizio, progetto.data_fine_prevista) AS decimal(10,4))
         / NULLIF(DATEDIFF(day, progetto.data_inizio, progetto.data_fine_prevista), 0)
                                                                             AS scostamento_tempi_pct,
       progetto.budget_previsto,
       progetto.costo_effettivo,
       CASE WHEN progetto.stato = N'Completato'
            THEN (progetto.costo_effettivo - progetto.budget_previsto)
                 / NULLIF(progetto.budget_previsto, 0)
       END                                                                   AS scostamento_costi_pct,
       progetto.soddisfazione_cliente,
       progetto.descrizione,
       progetto.pubblicabile
FROM portfolio.progetto;
GO

PRINT N'Vista portfolio.v_progetto_kpi creata.';
