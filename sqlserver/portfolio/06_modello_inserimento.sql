/* ============================================================================
   PORTFOLIO 06 - MODELLO per inserire i VOSTRI dati.
   Copiate un blocco, sostituite i valori tra apici ed eseguite (F5).
   Regole:
     - le date si scrivono 'AAAA-MM-GG', per esempio '2025-03-31';
     - i testi vanno tra N'...'; un apostrofo nel testo si scrive doppio: N'l''analisi';
     - NULL (senza apici) = dato non disponibile;
     - pubblicabile: 1 = compare sulla pagina pubblica, 0 = resta privato.
   ============================================================================ */

USE PortfolioLab;
GO

-- 1) UN PROGETTO ------------------------------------------------------------
INSERT INTO portfolio.progetto (codice, nome, organizzazione, settore, approccio, ruolo, stato, data_inizio,
                                data_fine_prevista, data_fine_effettiva, date_indicative, budget_previsto,
                                costo_effettivo, soddisfazione_cliente, descrizione, pubblicabile)
VALUES (N'PRJ-2025-01',              -- codice univoco a vostra scelta
        N'Nome del progetto',
        N'Organizzazione',           -- azienda o cliente, se citabile (NULL altrimenti)
        N'Settore',                  -- es. Metalmeccanico, GDO, IT, Servizi
        N'Ibrido',                   -- Predittivo | Agile | Ibrido | NULL se non indicato
        N'Project Manager',          -- il vostro ruolo
        N'Completato',               -- Pianificato | In corso | Completato | Sospeso
        '2025-01-15',                -- data inizio
        '2025-06-30',                -- data fine prevista (NULL se non nota)
        '2025-07-10',                -- data fine effettiva (NULL se non concluso)
        0,                           -- date_indicative: 1 se le date sono approssimate
        50000,                       -- budget previsto (NULL se non volete indicarlo)
        52000,                       -- costo effettivo (NULL se non disponibile)
        4,                           -- soddisfazione cliente 1-5 (NULL se non rilevata)
        N'Breve descrizione, senza dati riservati.',
        0);                          -- 0 = privato finché non decidete di pubblicarlo

-- 2) UNA COMPETENZA -----------------------------------------------------------
INSERT INTO portfolio.competenza (nome, area, livello)
VALUES (N'Nome competenza',
        N'Project Management',       -- Project Management | Business Analysis | ICT ed ERP | Dati e reporting |
                                     -- Intelligenza artificiale e conformità | Sviluppo | Competenze trasversali
        4);                          -- livello 1-5 (NULL se non volete indicarlo)

-- 3) COLLEGARE UNA COMPETENZA A UN PROGETTO ----------------------------------
INSERT INTO portfolio.progetto_competenza (progetto_id, competenza_id)
SELECT p.progetto_id, c.competenza_id
FROM portfolio.progetto AS p, portfolio.competenza AS c
WHERE p.codice = N'PRJ-2025-01' AND c.nome = N'Nome competenza';

-- 4) UNA CERTIFICAZIONE O UN CORSO -----------------------------------------
INSERT INTO portfolio.formazione (titolo, ente, tipo, area, data_conseguimento, ore, pdu, credenziale_url, pubblicabile)
VALUES (N'Titolo', N'Ente', N'Corso',  -- Certificazione | Corso | Webinar | Evento | Titolo di studio
        N'Project Management', '2025-05-20', 16, 16, NULL, 1);   -- data e ore: NULL se non note

-- 5) UN CASO DI ANALISI -----------------------------------------------------
INSERT INTO portfolio.caso_analisi (titolo, dataset, strumenti, data_pubblicazione, link_url, descrizione, pubblicabile)
VALUES (N'Titolo', N'Dataset usato', N'SQL Server, Metabase', '2025-09-01',
        N'https://github.com/...', N'Breve descrizione.', 1);

-- Per correggere un dato: UPDATE portfolio.progetto SET stato = N'Completato' WHERE codice = N'PRJ-2025-01';
-- Per cancellarlo:        DELETE FROM portfolio.progetto WHERE codice = N'PRJ-2025-01';
