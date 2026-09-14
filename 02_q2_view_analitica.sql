-- ============================================================
-- TRABALHO PRÁTICO SQL N1
-- Q2 - VIEW ANALÍTICA: LOCAÇÕES DEVOLVIDAS COM ATRASO
-- Banco de Dados: Sakila
-- ============================================================

USE sakila;

-- ============================================================
-- OBJETIVO
--
-- Identificar locações em que o cliente devolveu o filme
-- depois do prazo permitido e classificá-las de acordo com
-- uma prioridade.
--
-- REGRA ANALÍTICA:
-- Uma locação é considerada atrasada quando:
--
-- dias que o cliente ficou com o filme
-- >
-- quantidade de dias permitidos para aluguel
--
-- O prazo permitido está armazenado em:
-- film.rental_duration
--
-- PRIORIZAÇÃO:
--
-- 1 dia de atraso      -> Score 1 -> BAIXA
-- 2 a 4 dias de atraso -> Score 2 -> MEDIA
-- 5 dias ou mais       -> Score 3 -> ALTA
--
-- Quanto maior o score, maior a prioridade de análise.
-- ============================================================


-- ============================================================
-- CRIAÇÃO DA VIEW
-- ============================================================

CREATE OR REPLACE VIEW vw_n1_locacoes_atrasadas AS

SELECT

    -- Identificação do aluguel
    r.rental_id AS aluguel_id,


    -- Nome completo do cliente
    CONCAT(
        cu.first_name,
        ' ',
        cu.last_name
    ) AS cliente,


    -- Filme alugado
    f.title AS filme,


    -- Categoria do filme
    c.name AS categoria,


    -- Loja responsável pelo item
    i.store_id AS loja,


    -- Data em que o aluguel foi realizado
    r.rental_date AS data_aluguel,


    -- Data em que o filme foi devolvido
    r.return_date AS data_devolucao,


    -- Quantidade de dias permitidos para o aluguel
    f.rental_duration AS dias_permitidos,


    -- Quantidade real de dias que o cliente ficou com o filme
    DATEDIFF(
        r.return_date,
        r.rental_date
    ) AS dias_locado,


    -- Quantidade de dias que ultrapassaram o prazo permitido
    DATEDIFF(
        r.return_date,
        r.rental_date
    ) - f.rental_duration AS dias_atraso,


    -- Valor relacionado ao pagamento da locação
    p.amount AS valor_pago,


    -- ========================================================
    -- SCORE NUMÉRICO DE PRIORIDADE
    -- ========================================================

    CASE

        -- 5 dias ou mais de atraso = prioridade alta
        WHEN (
            DATEDIFF(
                r.return_date,
                r.rental_date
            ) - f.rental_duration
        ) >= 5
            THEN 3


        -- Entre 2 e 4 dias = prioridade média
        WHEN (
            DATEDIFF(
                r.return_date,
                r.rental_date
            ) - f.rental_duration
        ) BETWEEN 2 AND 4
            THEN 2


        -- Caso contrário: 1 dia de atraso
        ELSE 1

    END AS score_prioridade,


    -- ========================================================
    -- DESCRIÇÃO DA PRIORIDADE
    -- ========================================================

    CASE

        WHEN (
            DATEDIFF(
                r.return_date,
                r.rental_date
            ) - f.rental_duration
        ) >= 5
            THEN 'ALTA'


        WHEN (
            DATEDIFF(
                r.return_date,
                r.rental_date
            ) - f.rental_duration
        ) BETWEEN 2 AND 4
            THEN 'MEDIA'


        ELSE 'BAIXA'

    END AS prioridade


-- ============================================================
-- TABELAS UTILIZADAS
-- ============================================================

FROM rental r


-- Cliente responsável pelo aluguel
JOIN customer cu
    ON r.customer_id = cu.customer_id


-- Item do estoque relacionado ao aluguel
JOIN inventory i
    ON r.inventory_id = i.inventory_id


-- Filme relacionado ao item do estoque
JOIN film f
    ON i.film_id = f.film_id


-- Relacionamento entre filme e categoria
JOIN film_category fc
    ON f.film_id = fc.film_id


-- Categoria do filme
JOIN category c
    ON fc.category_id = c.category_id


-- Pagamento relacionado ao aluguel
LEFT JOIN payment p
    ON r.rental_id = p.rental_id


-- ============================================================
-- FILTRO
--
-- Consideramos apenas:
-- 1. Filmes que já possuem data de devolução;
-- 2. Devoluções realizadas depois do prazo permitido.
-- ============================================================

WHERE

    r.return_date IS NOT NULL

    AND DATEDIFF(
        r.return_date,
        r.rental_date
    ) > f.rental_duration;


-- ============================================================
-- CONSULTA PARA DEMONSTRAÇÃO DA VIEW
--
-- Mostra somente 15 registros para evitar exibir milhares
-- de linhas durante a apresentação.
-- ============================================================

SELECT
    aluguel_id,
    cliente,
    filme,
    categoria,
    dias_permitidos,
    dias_locado,
    dias_atraso,
    score_prioridade,
    prioridade

FROM vw_n1_locacoes_atrasadas

ORDER BY
    score_prioridade DESC,
    dias_atraso DESC

LIMIT 15;


-- ============================================================
-- RESUMO DA QUANTIDADE POR PRIORIDADE
-- ============================================================

SELECT
    prioridade,
    score_prioridade,
    COUNT(*) AS quantidade

FROM vw_n1_locacoes_atrasadas

GROUP BY
    prioridade,
    score_prioridade

ORDER BY
    score_prioridade DESC;