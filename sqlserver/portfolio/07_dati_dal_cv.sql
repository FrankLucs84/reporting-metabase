/* ============================================================================
   PORTFOLIO 07 - DATI REALI tratti dal CV "CV_Francesco_Lucignano_2026".
   Sostituisce gli esempi: da eseguire dopo 01 e 02, al posto di 03.

   Regole usate per non inventare nulla:
   - ogni progetto corrisponde a un'attività descritta nel CV;
   - le DATE sono quelle del RUOLO in cui si è svolta l'attività (il CV non riporta
     le date dei singoli progetti): per questo date_indicative = 1, e i KPI su
     tempi e puntualità non le usano;
   - APPROCCIO = NULL (non indicato): il CV non lo specifica per i singoli progetti;
   - STATO: "Completato" per i ruoli conclusi; "In corso" per le attività del ruolo
     attuale (Head of PMO, dal 01/2026) -> DA CONFERMARE progetto per progetto;
   - nessun budget, costo o soddisfazione: il CV non li riporta per progetto;
   - COMPETENZE: elenco "Competenze chiave" del CV, senza livello (non indicato);
     i collegamenti progetto-competenza derivano dal testo di ciascuna attività.
   Rieseguibile: cancella e ricarica i dati del portfolio.
   ============================================================================ */

USE PortfolioLab;
GO

SET NOCOUNT ON;

DELETE FROM portfolio.progetto_competenza;
DELETE FROM portfolio.progetto;
DELETE FROM portfolio.competenza;
DELETE FROM portfolio.formazione;
DELETE FROM portfolio.caso_analisi;

-- COMPETENZE (CV, sezione "Competenze chiave") ----------------------------------
INSERT INTO portfolio.competenza (nome, area) VALUES
    (N'Governance di portafoglio e PMO',            N'Project Management'),
    (N'Project charter e WBS',                      N'Project Management'),
    (N'Pianificazione e schedulazione',             N'Project Management'),
    (N'Risk management e RAID log',                 N'Project Management'),
    (N'Stakeholder management',                     N'Project Management'),
    (N'Change control',                             N'Project Management'),
    (N'Agile e Scrum',                              N'Project Management'),
    (N'Raccolta e formalizzazione dei requisiti',   N'Business Analysis'),
    (N'Analisi funzionale e gap analysis',          N'Business Analysis'),
    (N'Mappatura e reingegnerizzazione dei processi', N'Business Analysis'),
    (N'Collaudo e UAT',                             N'Business Analysis'),
    (N'Documentazione tecnico-funzionale',          N'Business Analysis'),
    (N'SAP',                                        N'ICT ed ERP'),
    (N'HelpdeskAdvanced (HDA)',                     N'ICT ed ERP'),
    (N'Migrazioni di piattaforma',                  N'ICT ed ERP'),
    (N'Integrazione tra sistemi',                   N'ICT ed ERP'),
    (N'E-commerce',                                 N'ICT ed ERP'),
    (N'Fatturazione elettronica e conservazione digitale', N'ICT ed ERP'),
    (N'SQL',                                        N'Dati e reporting'),
    (N'Power BI',                                   N'Dati e reporting'),
    (N'KNIME Analytics Platform',                   N'Dati e reporting'),
    (N'KPI e cruscotti direzionali',                N'Dati e reporting'),
    (N'Analisi di magazzino e logistica',           N'Dati e reporting'),
    (N'Casi d''uso e adozione dell''IA',            N'Intelligenza artificiale e conformità'),
    (N'AI Act (Reg. UE 2024/1689)',                 N'Intelligenza artificiale e conformità'),
    (N'NIS2 (D.lgs. 138/2024)',                     N'Intelligenza artificiale e conformità'),
    (N'Python',                                     N'Sviluppo'),
    (N'Change management',                          N'Competenze trasversali'),
    (N'Formazione degli utenti',                    N'Competenze trasversali'),
    (N'Mediazione dei conflitti organizzativi',     N'Competenze trasversali');

-- PROGETTI (CV, sezione "Esperienza professionale") ----------------------------
INSERT INTO portfolio.progetto (codice, nome, organizzazione, settore, approccio, ruolo, stato,
                                data_inizio, data_fine_prevista, data_fine_effettiva, date_indicative,
                                descrizione, pubblicabile)
VALUES
-- Maurelli Group S.p.A. - Head of PMO (01/2026 - presente)
    (N'MAU-PMO-01', N'Modello di governance di progetto secondo gli standard PMI', N'Maurelli Group S.p.A.', N'Metalmeccanico', NULL, N'Head of PMO', N'In corso',
     '2026-01-01', NULL, NULL, 1, N'Project charter, WBS, RAID log, registro dei rischi e reportistica periodica per la direzione, sul portafoglio ICT del gruppo.', 1),
    (N'MAU-PMO-02', N'Migrazione di HelpdeskAdvanced alla versione 11', N'Maurelli Group S.p.A.', N'Metalmeccanico', NULL, N'Head of PMO', N'In corso',
     '2026-01-01', NULL, NULL, 1, N'Ricostruzione dell''architettura applicativa, analisi di impatto e pianificazione del porting.', 1),
    (N'MAU-PMO-03', N'Integrazione dell''intelligenza artificiale nei processi aziendali', N'Maurelli Group S.p.A.', N'Metalmeccanico', NULL, N'Head of PMO', N'In corso',
     '2026-01-01', NULL, NULL, 1, N'Avvio dell''integrazione di strumenti di IA, con presidio degli obblighi di trasparenza dell''art. 50 dell''AI Act.', 1),
    (N'MAU-PMO-04', N'Adeguamento alla direttiva NIS2', N'Maurelli Group S.p.A.', N'Metalmeccanico', NULL, N'Head of PMO', N'In corso',
     '2026-01-01', NULL, NULL, 1, N'Analisi del perimetro, gap analysis e piano di remediation (D.lgs. 138/2024).', 1),
    (N'MAU-PMO-05', N'Modello di collaborazione uomo-IA (Human in the Loop)', N'Maurelli Group S.p.A.', N'Metalmeccanico', NULL, N'Head of PMO', N'In corso',
     '2026-01-01', NULL, NULL, 1, N'Modello strutturato per i team di progetto, con procedure di verifica e tracciabilità degli output.', 1),
-- Maurelli Group S.p.A. - Project Manager (09/2022 - 12/2025)
    (N'MAU-PM-01', N'ERP SAP per i processi di magazzino e CEDI', N'Maurelli Group S.p.A.', N'Metalmeccanico', NULL, N'Project Manager', N'Completato',
     '2022-09-01', NULL, '2025-12-31', 1, N'Analisi funzionale e configurazione: mappatura dei flussi, definizione dei requisiti, collaudo e avviamento in esercizio.', 1),
    (N'MAU-PM-02', N'Piattaforma di ticketing HelpdeskAdvanced su tutti i dipartimenti', N'Maurelli Group S.p.A.', N'Metalmeccanico', NULL, N'Project Manager', N'Completato',
     '2022-09-01', NULL, '2025-12-31', 1, N'Implementazione e gestione della piattaforma HDA in tutti i dipartimenti aziendali.', 1),
    (N'MAU-PM-03', N'Cruscotti KPI sui livelli di servizio HDA', N'Maurelli Group S.p.A.', N'Metalmeccanico', NULL, N'Project Manager', N'Completato',
     '2022-09-01', NULL, '2025-12-31', 1, N'Query SQL e cruscotti sulla base dati HDA per il monitoraggio dei livelli di servizio e dei carichi di lavoro.', 1),
    (N'MAU-PM-04', N'Analisi dei costi logistici e delle anomalie di fatturazione', N'Maurelli Group S.p.A.', N'Metalmeccanico', NULL, N'Project Manager', N'Completato',
     '2022-09-01', NULL, '2025-12-31', 1, N'Strumenti di analisi in Power BI e KNIME per il controllo dei costi logistici e l''individuazione di anomalie di fatturazione.', 1),
    (N'MAU-PM-05', N'Change management e formazione utenti su oltre 45 filiali', N'Maurelli Group S.p.A.', N'Metalmeccanico', NULL, N'Project Manager', N'Completato',
     '2022-09-01', NULL, '2025-12-31', 1, N'Mediazione dei conflitti organizzativi nell''adozione dei nuovi sistemi e formazione diretta degli utenti chiave.', 1),
-- Multiesse S.r.l. - Controllo di gestione / Business Controller (09/2019 - 08/2022)
    (N'MLT-BC-01', N'Reportistica direzionale settimanale', N'Multiesse S.r.l.', N'Grande Distribuzione Organizzata', NULL, N'Business Controller', N'Completato',
     '2019-09-01', NULL, '2022-08-31', 1, N'Reporting su marginalità, costi operativi e rotazione di magazzino per 14 punti vendita.', 1),
    (N'MLT-BC-02', N'Automazione dell''elaborazione dei dati di reporting', N'Multiesse S.r.l.', N'Grande Distribuzione Organizzata', NULL, N'Business Controller', N'Completato',
     '2019-09-01', NULL, '2022-08-31', 1, N'Strumenti che hanno ridotto i tempi di chiusura del reporting da mesi a giorni.', 1),
    (N'MLT-BC-03', N'Laboratorio di produzione (centro cottura) integrato con l''ERP', N'Multiesse S.r.l.', N'Grande Distribuzione Organizzata', NULL, N'Business Controller', N'Completato',
     '2019-09-01', NULL, '2022-08-31', 1, N'Avvio e gestione del laboratorio, con integrazione software tra i sistemi di lottizzazione e l''ERP.', 1),
-- Multiesse S.r.l. - Impiegato commerciale e sviluppo progetti (04/2017 - 08/2022)
    (N'MLT-COM-01', N'Sito e-commerce durante l''emergenza pandemica', N'Multiesse S.r.l.', N'Grande Distribuzione Organizzata', NULL, N'Commerciale e sviluppo progetti', N'Completato',
     '2017-04-01', NULL, '2022-08-31', 1, N'Avvio del sito fino a 300 consegne al giorno; cambio del gateway di pagamento e gestione del catalogo.', 1),
-- Multiesse S.r.l. - Impiegato amministrativo-contabile (01/2015 - 03/2017)
    (N'MLT-AMM-01', N'Archiviazione digitale sostitutiva e fatturazione elettronica', N'Multiesse S.r.l.', N'Grande Distribuzione Organizzata', NULL, N'Amministrativo-contabile', N'Completato',
     '2015-01-01', NULL, '2017-03-31', 1, N'Avvio dei progetti con registrazione automatica in contabilità.', 1);

-- COLLEGAMENTI PROGETTO - COMPETENZA (dal testo di ciascuna attività del CV) ------
INSERT INTO portfolio.progetto_competenza (progetto_id, competenza_id)
SELECT p.progetto_id, c.competenza_id
FROM (VALUES
    (N'MAU-PMO-01', N'Governance di portafoglio e PMO'), (N'MAU-PMO-01', N'Project charter e WBS'),
    (N'MAU-PMO-01', N'Risk management e RAID log'), (N'MAU-PMO-01', N'Stakeholder management'),
    (N'MAU-PMO-02', N'HelpdeskAdvanced (HDA)'), (N'MAU-PMO-02', N'Migrazioni di piattaforma'),
    (N'MAU-PMO-02', N'Analisi funzionale e gap analysis'), (N'MAU-PMO-02', N'Pianificazione e schedulazione'),
    (N'MAU-PMO-03', N'Casi d''uso e adozione dell''IA'), (N'MAU-PMO-03', N'AI Act (Reg. UE 2024/1689)'),
    (N'MAU-PMO-04', N'NIS2 (D.lgs. 138/2024)'), (N'MAU-PMO-04', N'Analisi funzionale e gap analysis'),
    (N'MAU-PMO-05', N'Casi d''uso e adozione dell''IA'), (N'MAU-PMO-05', N'Mappatura e reingegnerizzazione dei processi'),
    (N'MAU-PM-01', N'SAP'), (N'MAU-PM-01', N'Analisi funzionale e gap analysis'),
    (N'MAU-PM-01', N'Mappatura e reingegnerizzazione dei processi'), (N'MAU-PM-01', N'Raccolta e formalizzazione dei requisiti'),
    (N'MAU-PM-01', N'Collaudo e UAT'), (N'MAU-PM-01', N'Analisi di magazzino e logistica'),
    (N'MAU-PM-02', N'HelpdeskAdvanced (HDA)'), (N'MAU-PM-02', N'Integrazione tra sistemi'),
    (N'MAU-PM-03', N'SQL'), (N'MAU-PM-03', N'KPI e cruscotti direzionali'), (N'MAU-PM-03', N'HelpdeskAdvanced (HDA)'),
    (N'MAU-PM-04', N'Power BI'), (N'MAU-PM-04', N'KNIME Analytics Platform'), (N'MAU-PM-04', N'Analisi di magazzino e logistica'),
    (N'MAU-PM-05', N'Change management'), (N'MAU-PM-05', N'Formazione degli utenti'),
    (N'MAU-PM-05', N'Mediazione dei conflitti organizzativi'), (N'MAU-PM-05', N'Stakeholder management'),
    (N'MLT-BC-01', N'KPI e cruscotti direzionali'), (N'MLT-BC-01', N'Analisi di magazzino e logistica'),
    (N'MLT-BC-02', N'KPI e cruscotti direzionali'), (N'MLT-BC-02', N'Mappatura e reingegnerizzazione dei processi'),
    (N'MLT-BC-03', N'Integrazione tra sistemi'),
    (N'MLT-COM-01', N'E-commerce'), (N'MLT-COM-01', N'Integrazione tra sistemi'),
    (N'MLT-AMM-01', N'Fatturazione elettronica e conservazione digitale'), (N'MLT-AMM-01', N'Mappatura e reingegnerizzazione dei processi')
) AS link (codice, competenza)
JOIN portfolio.progetto   AS p ON p.codice = link.codice
JOIN portfolio.competenza AS c ON c.nome   = link.competenza;

-- FORMAZIONE (CV: certificazioni, formazione continua, istruzione) --------------
-- Date e ore non indicate nel CV: NULL. La laurea ha l'anno di conseguimento (2010).
INSERT INTO portfolio.formazione (titolo, ente, tipo, area, data_conseguimento, ore, pdu, credenziale_url, pubblicabile) VALUES
    (N'ISIPM-Base®',                                     N'Istituto Italiano di Project Management', N'Certificazione', N'Project Management', NULL, NULL, NULL, NULL, 1),
    (N'Certificazione PAT per HelpdeskAdvanced (HDA)',   N'HelpdeskAdvanced',                        N'Certificazione', N'ICT ed ERP',          NULL, NULL, NULL, NULL, 1),
    (N'KNIME Analytics Platform - Basic Proficiency',    N'KNIME',                                   N'Certificazione', N'Dati e reporting',    NULL, NULL, NULL, NULL, 1),
    (N'Microsoft PL-300 Power BI Data Analyst - percorso di preparazione all''esame', N'Coursera', N'Corso',      N'Dati e reporting',    NULL, NULL, NULL, NULL, 1),
    (N'Google Data Analytics: Foundations - Data, Data, Everywhere', N'Coursera',               N'Corso',          N'Dati e reporting',    NULL, NULL, NULL, NULL, 1),
    (N'Agile Project Management',                        N'Alison',                                  N'Corso',          N'Project Management', NULL, NULL, NULL, NULL, 1),
    (N'Laurea in Economia Aziendale',                    N'Università degli Studi di Napoli Federico II', N'Titolo di studio', N'Competenze trasversali', '2010-12-31', NULL, NULL, NULL, 1);

-- CASI DI ANALISI ----------------------------------------------------------------
INSERT INTO portfolio.caso_analisi (titolo, dataset, strumenti, data_pubblicazione, link_url, descrizione, pubblicabile) VALUES
    (N'Vendite e Pareto clienti', N'Contoso (dati sintetici)', N'SQL Server, Metabase, Power BI', '2026-10-08',
     N'https://github.com/FrankLucs84/reporting-metabase',
     N'Report gestito come codice: KPI, andamento, Pareto e classificazione ABC dei clienti.', 1),
    (N'Portfolio professionale', N'PortfolioLab (progetti dal CV)', N'SQL Server, Metabase, GitHub Pages', '2026-10-08',
     N'https://github.com/FrankLucs84/reporting-metabase',
     N'Questa pagina: dati in SQL Server, report in Metabase, pubblicazione automatica dei soli dati pubblicabili.', 1);

SELECT (SELECT COUNT(*) FROM portfolio.progetto)            AS progetti,
       (SELECT COUNT(*) FROM portfolio.competenza)          AS competenze,
       (SELECT COUNT(*) FROM portfolio.progetto_competenza) AS collegamenti,
       (SELECT COUNT(*) FROM portfolio.formazione)          AS formazione,
       (SELECT COUNT(*) FROM portfolio.caso_analisi)        AS casi;
GO
