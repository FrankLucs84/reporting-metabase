/* ============================================================================
   PORTFOLIO 03 - DATI DI ESEMPIO, INVENTATI, per vedere subito il report.
   Tutti i codici iniziano con "ESEMPIO-" e i nomi con "[Esempio]":
   si cancellano con lo script 05 quando inserite i vostri dati.
   ============================================================================ */

USE PortfolioLab;
GO

SET NOCOUNT ON;

INSERT INTO portfolio.competenza (nome, area, livello) VALUES
    (N'Pianificazione e WBS',          N'Project Management',       5),
    (N'Gestione dei rischi',           N'Project Management',       4),
    (N'Gestione stakeholder',          N'Project Management',       4),
    (N'Scrum / Agile',                 N'Project Management',       4),
    (N'Analisi dei requisiti',         N'Business Analysis',        5),
    (N'Modellazione dei processi',     N'Business Analysis',        4),
    (N'SQL',                           N'Dati e Reporting',         4),
    (N'Power BI / DAX',                N'Dati e Reporting',         4),
    (N'Metabase',                      N'Dati e Reporting',         3),
    (N'Gestione progetti AI (CPMAI)',  N'Intelligenza Artificiale', 3),
    (N'Prompt engineering',            N'Intelligenza Artificiale', 3),
    (N'MS Project / Jira',             N'Strumenti',                4);

INSERT INTO portfolio.progetto (codice, nome, settore, approccio, ruolo, stato, data_inizio,
                                data_fine_prevista, data_fine_effettiva, budget_previsto,
                                costo_effettivo, soddisfazione_cliente, descrizione, pubblicabile)
VALUES
    (N'ESEMPIO-01', N'[Esempio] Migrazione ERP',              N'Manifattura',  N'Predittivo', N'Project Manager',  N'Completato', '2023-02-01', '2023-10-31', '2023-12-15', 180000, 196000, 4, N'Passaggio al nuovo gestionale con migrazione dati e formazione utenti.', 1),
    (N'ESEMPIO-02', N'[Esempio] Portale clienti',             N'Servizi',      N'Agile',      N'Product Owner',    N'Completato', '2023-05-15', '2023-12-20', '2023-12-18',  95000,  91000, 5, N'Portale self-service sviluppato in sprint di due settimane.', 1),
    (N'ESEMPIO-03', N'[Esempio] Audit sicurezza IT',          N'IT',           N'Predittivo', N'Project Manager',  N'Completato', '2024-01-10', '2024-04-30', '2024-05-20',  40000,  43500, 4, N'Assessment, piano di rimedio e verifica di chiusura.', 1),
    (N'ESEMPIO-04', N'[Esempio] Reporting direzionale',       N'Manifattura',  N'Ibrido',     N'Business Analyst', N'Completato', '2024-03-01', '2024-07-31', '2024-07-25',  30000,  27800, 5, N'Cruscotto KPI per la direzione con modello dati a stella.', 1),
    (N'ESEMPIO-05', N'[Esempio] Directory aziendale AD/LDAP', N'IT',           N'Predittivo', N'Project Manager',  N'Completato', '2024-06-01', '2024-11-30', '2025-01-20',  60000,  66000, 3, N'Consolidamento delle identità e delle policy di accesso.', 1),
    (N'ESEMPIO-06', N'[Esempio] Automazione flussi dati',     N'Servizi',      N'Agile',      N'Business Analyst', N'Completato', '2024-09-01', '2025-02-28', '2025-02-28',  45000,  44200, 4, N'Pipeline di integrazione dati con controlli di qualità.', 1),
    (N'ESEMPIO-07', N'[Esempio] Assistente AI per il supporto',N'Servizi',     N'Ibrido',     N'Project Manager',  N'In corso',   '2025-03-01', '2025-12-31', NULL,          120000,  78000, NULL, N'Pilota di assistente conversazionale secondo il metodo CPMAI.', 1),
    (N'ESEMPIO-08', N'[Esempio] Pianificazione produzione',   N'Manifattura',  N'Ibrido',     N'Project Manager',  N'Pianificato','2026-01-15', '2026-09-30', NULL,           85000,   NULL, NULL, N'Nuovo processo di pianificazione con simulazione degli scenari.', 0);

-- Competenze usate nei progetti (per codice progetto e nome competenza)
INSERT INTO portfolio.progetto_competenza (progetto_id, competenza_id)
SELECT p.progetto_id, c.competenza_id
FROM (VALUES
    (N'ESEMPIO-01', N'Pianificazione e WBS'), (N'ESEMPIO-01', N'Gestione dei rischi'), (N'ESEMPIO-01', N'Gestione stakeholder'), (N'ESEMPIO-01', N'MS Project / Jira'),
    (N'ESEMPIO-02', N'Scrum / Agile'), (N'ESEMPIO-02', N'Analisi dei requisiti'), (N'ESEMPIO-02', N'MS Project / Jira'),
    (N'ESEMPIO-03', N'Pianificazione e WBS'), (N'ESEMPIO-03', N'Gestione dei rischi'),
    (N'ESEMPIO-04', N'Analisi dei requisiti'), (N'ESEMPIO-04', N'SQL'), (N'ESEMPIO-04', N'Power BI / DAX'), (N'ESEMPIO-04', N'Modellazione dei processi'),
    (N'ESEMPIO-05', N'Pianificazione e WBS'), (N'ESEMPIO-05', N'Gestione stakeholder'), (N'ESEMPIO-05', N'Gestione dei rischi'),
    (N'ESEMPIO-06', N'Scrum / Agile'), (N'ESEMPIO-06', N'SQL'), (N'ESEMPIO-06', N'Modellazione dei processi'),
    (N'ESEMPIO-07', N'Gestione progetti AI (CPMAI)'), (N'ESEMPIO-07', N'Prompt engineering'), (N'ESEMPIO-07', N'Gestione stakeholder'), (N'ESEMPIO-07', N'Scrum / Agile'),
    (N'ESEMPIO-08', N'Pianificazione e WBS'), (N'ESEMPIO-08', N'Analisi dei requisiti')
) AS link (codice, competenza)
JOIN portfolio.progetto   AS p ON p.codice = link.codice
JOIN portfolio.competenza AS c ON c.nome   = link.competenza;

INSERT INTO portfolio.formazione (titolo, ente, tipo, area, data_conseguimento, ore, pdu, credenziale_url, pubblicabile) VALUES
    (N'[Esempio] Certificazione di project management', N'Ente certificatore', N'Certificazione', N'Project Management',       '2023-06-20', 35, 35, NULL, 1),
    (N'[Esempio] Corso Agile e Scrum',                  N'Ente formativo',     N'Corso',          N'Project Management',       '2023-11-10', 16, 16, NULL, 1),
    (N'[Esempio] SQL per l''analisi dati',              N'Ente formativo',     N'Corso',          N'Dati e Reporting',         '2024-02-15', 24, NULL, NULL, 1),
    (N'[Esempio] Business analysis: requisiti',         N'Ente formativo',     N'Corso',          N'Business Analysis',        '2024-05-08', 21, 21, NULL, 1),
    (N'[Esempio] Webinar AI nei progetti',              N'Associazione',       N'Webinar',        N'Intelligenza Artificiale', '2024-10-03',  2,  2, NULL, 1),
    (N'[Esempio] Gestione di progetti AI',              N'Ente formativo',     N'Certificazione', N'Intelligenza Artificiale', '2025-04-18', 30, 30, NULL, 1),
    (N'[Esempio] Convegno annuale PM',                  N'Associazione',       N'Evento',         N'Project Management',       '2025-10-24',  8,  8, NULL, 1);

INSERT INTO portfolio.caso_analisi (titolo, dataset, strumenti, data_pubblicazione, link_url, descrizione, pubblicabile) VALUES
    (N'Vendite e Pareto clienti', N'Contoso (dati sintetici)', N'SQL Server, Metabase, Power BI', '2026-10-08',
     N'https://github.com/FrankLucs84/reporting-metabase',
     N'Report gestito come codice: KPI, andamento, Pareto e classificazione ABC dei clienti.', 1);

SELECT (SELECT COUNT(*) FROM portfolio.progetto)            AS progetti,
       (SELECT COUNT(*) FROM portfolio.competenza)          AS competenze,
       (SELECT COUNT(*) FROM portfolio.progetto_competenza) AS collegamenti,
       (SELECT COUNT(*) FROM portfolio.formazione)          AS formazione,
       (SELECT COUNT(*) FROM portfolio.caso_analisi)        AS casi;
GO
