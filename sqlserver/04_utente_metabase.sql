/* ============================================================================
   04 - Crea l'utente con cui Metabase legge i dati: SOLO LETTURA, solo schema contoso.
   PRIMA DI ESEGUIRE: sostituire la password qui sotto con una vostra.
   Requisito: SQL Server in "autenticazione mista" (vedi la guida, passo 2.3).
   ============================================================================ */

USE master;
GO

IF SUSER_ID(N'metabase_ro') IS NULL
    CREATE LOGIN metabase_ro WITH PASSWORD = N'Cambiami-Metabase-2026!', CHECK_POLICY = ON;
GO

USE ContosoLab;
GO

IF USER_ID(N'metabase_ro') IS NULL
    CREATE USER metabase_ro FOR LOGIN metabase_ro;
GO

GRANT SELECT ON SCHEMA::contoso TO metabase_ro;
GO

PRINT N'Utente metabase_ro pronto (sola lettura sullo schema contoso).';
