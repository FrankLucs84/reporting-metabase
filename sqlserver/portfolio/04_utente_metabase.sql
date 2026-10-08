/* ============================================================================
   PORTFOLIO 04 - Dà all'utente metabase_ro (creato dallo script sqlserver/04)
   il permesso di SOLA LETTURA sullo schema portfolio.
   Se metabase_ro non esiste ancora, eseguite prima sqlserver/04_utente_metabase.sql.
   ============================================================================ */

USE PortfolioLab;
GO

IF USER_ID(N'metabase_ro') IS NULL
    CREATE USER metabase_ro FOR LOGIN metabase_ro;
GO

GRANT SELECT ON SCHEMA::portfolio TO metabase_ro;
GO

PRINT N'metabase_ro può leggere lo schema portfolio.';
