/* ============================================================================
   PORTFOLIO 05 - Cancella SOLO i dati di esempio (codici "ESEMPIO-", titoli "[Esempio]").
   I vostri dati restano. Restano anche le competenze e il caso di analisi
   "Vendite e Pareto clienti" (è il report reale di questa repository):
   modificateli o cancellateli a mano se non vi rappresentano.
   ============================================================================ */

USE PortfolioLab;
GO

DELETE FROM portfolio.progetto     WHERE codice LIKE N'ESEMPIO-%';
DELETE FROM portfolio.formazione   WHERE titolo LIKE N'\[Esempio\]%' ESCAPE N'\';

PRINT N'Dati di esempio cancellati.';
