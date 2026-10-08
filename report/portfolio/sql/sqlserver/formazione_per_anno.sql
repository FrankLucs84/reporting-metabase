SELECT YEAR(formazione.data_conseguimento) AS anno,
       SUM(formazione.ore)                  AS ore
FROM portfolio.formazione
GROUP BY YEAR(formazione.data_conseguimento)
ORDER BY anno
