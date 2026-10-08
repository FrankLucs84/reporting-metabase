-- Competenze ordinate per numero di progetti in cui sono state usate.
SELECT competenza.nome AS competenza,
       competenza.area,
       COUNT(*)        AS progetti
FROM portfolio.v_progetto_kpi
JOIN portfolio.progetto_competenza ON progetto_competenza.progetto_id = v_progetto_kpi.progetto_id
JOIN portfolio.competenza          ON competenza.competenza_id        = progetto_competenza.competenza_id
WHERE {{approccio}} AND {{stato}} AND {{settore}}
GROUP BY competenza.nome, competenza.area
ORDER BY progetti DESC, competenza.nome
