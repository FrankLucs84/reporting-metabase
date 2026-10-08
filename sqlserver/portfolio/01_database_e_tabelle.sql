/* ============================================================================
   PORTFOLIO 01 - Crea il database PortfolioLab, lo schema "portfolio" e le tabelle.
   Da eseguire in SSMS collegati come amministratore.
   ATTENZIONE: rieseguirlo CANCELLA le tabelle e i dati inseriti.
   ============================================================================ */

IF DB_ID(N'PortfolioLab') IS NULL
    CREATE DATABASE PortfolioLab;
GO

USE PortfolioLab;
GO

IF SCHEMA_ID(N'portfolio') IS NULL
    EXEC (N'CREATE SCHEMA portfolio');
GO

DROP VIEW  IF EXISTS portfolio.v_progetto_kpi;
DROP TABLE IF EXISTS portfolio.progetto_competenza;
DROP TABLE IF EXISTS portfolio.progetto;
DROP TABLE IF EXISTS portfolio.competenza;
DROP TABLE IF EXISTS portfolio.formazione;
DROP TABLE IF EXISTS portfolio.caso_analisi;
GO

-- Progetti seguiti come PM / BA
CREATE TABLE portfolio.progetto (
    progetto_id           int IDENTITY PRIMARY KEY,
    codice                nvarchar(20)  NOT NULL UNIQUE,       -- es. PRJ-2025-01
    nome                  nvarchar(150) NOT NULL,
    organizzazione        nvarchar(100) NULL,                  -- azienda o cliente (se citabile)
    settore               nvarchar(80)  NOT NULL,              -- es. Metalmeccanico, GDO, IT
    approccio             nvarchar(20)  NULL                   -- NULL = non indicato
        CHECK (approccio IN (N'Predittivo', N'Agile', N'Ibrido')),
    ruolo                 nvarchar(80)  NOT NULL,              -- es. Project Manager, Business Analyst
    stato                 nvarchar(20)  NOT NULL
        CHECK (stato IN (N'Pianificato', N'In corso', N'Completato', N'Sospeso')),
    data_inizio           date          NOT NULL,
    data_fine_prevista    date          NULL,                  -- vuota se non pianificata o non nota
    data_fine_effettiva   date          NULL,                  -- vuota se non ancora concluso
    date_indicative       bit           NOT NULL DEFAULT 0,    -- 1 = date approssimate (es. periodo del ruolo):
                                                               --     escluse dai KPI su tempi e puntualità
    budget_previsto       decimal(14,2) NULL,                  -- facoltativo
    costo_effettivo       decimal(14,2) NULL,                  -- facoltativo
    soddisfazione_cliente tinyint       NULL CHECK (soddisfazione_cliente BETWEEN 1 AND 5),
    descrizione           nvarchar(500) NULL,
    pubblicabile          bit           NOT NULL DEFAULT 0,    -- 1 = può comparire sulla pagina pubblica
    CHECK (data_fine_prevista IS NULL OR data_fine_prevista >= data_inizio),
    CHECK (data_fine_effettiva IS NULL OR data_fine_effettiva >= data_inizio)
);

-- Competenze, con livello di padronanza da 1 a 5 (facoltativo)
CREATE TABLE portfolio.competenza (
    competenza_id int IDENTITY PRIMARY KEY,
    nome          nvarchar(80) NOT NULL UNIQUE,
    area          nvarchar(50) NOT NULL
        CHECK (area IN (N'Project Management', N'Business Analysis', N'ICT ed ERP', N'Dati e reporting',
                        N'Intelligenza artificiale e conformità', N'Sviluppo', N'Competenze trasversali')),
    livello       tinyint      NULL CHECK (livello BETWEEN 1 AND 5)
);

-- Quali competenze sono state usate in quali progetti
CREATE TABLE portfolio.progetto_competenza (
    progetto_id   int NOT NULL REFERENCES portfolio.progetto (progetto_id) ON DELETE CASCADE,
    competenza_id int NOT NULL REFERENCES portfolio.competenza (competenza_id) ON DELETE CASCADE,
    PRIMARY KEY (progetto_id, competenza_id)
);

-- Certificazioni, corsi, webinar, eventi
CREATE TABLE portfolio.formazione (
    formazione_id      int IDENTITY PRIMARY KEY,
    titolo             nvarchar(150) NOT NULL,
    ente               nvarchar(100) NOT NULL,              -- es. PMI, IIBA, università
    tipo               nvarchar(20)  NOT NULL
        CHECK (tipo IN (N'Certificazione', N'Corso', N'Webinar', N'Evento', N'Titolo di studio')),
    area               nvarchar(50)  NOT NULL,              -- stesse aree delle competenze
    data_conseguimento date          NULL,                  -- vuota se non indicata
    ore                decimal(6,1)  NULL,                  -- vuota se non indicate
    pdu                decimal(6,1)  NULL,                  -- PDU PMI, se applicabili
    credenziale_url    nvarchar(300) NULL,                  -- es. link Credly
    pubblicabile       bit           NOT NULL DEFAULT 0
);

-- Casi di analisi dati (dashboard, report, studi)
CREATE TABLE portfolio.caso_analisi (
    caso_id            int IDENTITY PRIMARY KEY,
    titolo             nvarchar(150) NOT NULL,
    dataset            nvarchar(150) NOT NULL,              -- es. Contoso (dati sintetici)
    strumenti          nvarchar(150) NOT NULL,              -- es. SQL Server, Metabase, Power BI
    data_pubblicazione date          NOT NULL,
    link_url           nvarchar(300) NULL,                  -- es. repository GitHub
    descrizione        nvarchar(500) NULL,
    pubblicabile       bit           NOT NULL DEFAULT 0
);
GO

PRINT N'Database PortfolioLab e tabelle creati.';
