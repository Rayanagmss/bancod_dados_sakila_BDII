-- ============================================================
-- TRABALHO PRATICO SQL N1
-- Q5 - VIEWS PARA DIFERENTES PERFIS
-- Banco de Dados: Sakila
--
-- OBJETIVO:
-- Criar duas views para perfis distintos de consumo:
--
-- 1) Perfil gerencial:
--    visualiza indicadores resumidos e agregados.
--
-- 2) Perfil analitico:
--    visualiza registros detalhados para investigacao.
--
-- VIEWS CRIADAS:
-- vw_n1_painel_gerencial
-- vw_n1_locacoes_detalhadas
-- ============================================================

USE sakila;


-- ============================================================
-- 1. VIEW GERENCIAL
--
-- Objetivo:
-- Exibir uma visao resumida do desempenho da locadora
-- por mes e categoria.
--
-- Indicadores:
-- - total de locacoes
-- - clientes distintos
-- - receita total
-- - ticket medio
--
-- Cada linha representa uma combinacao:
-- mes + categoria
-- ============================================================

CREATE OR REPLACE VIEW vw_n1_painel_gerencial AS

SELECT

    DATE_FORMAT(
        p.payment_date,
        '%Y-%m'
    ) AS mes,

    c.name AS categoria,

    COUNT(
        DISTINCT r.rental_id
    ) AS total_locacoes,

    COUNT(
        DISTINCT r.customer_id
    ) AS clientes_distintos,

    ROUND(
        SUM(p.amount),
        2
    ) AS receita_total,

    ROUND(
        AVG(p.amount),
        2
    ) AS ticket_medio

FROM payment p

JOIN rental r
    ON p.rental_id = r.rental_id

JOIN inventory i
    ON r.inventory_id = i.inventory_id

JOIN film f
    ON i.film_id = f.film_id

JOIN film_category fc
    ON f.film_id = fc.film_id

JOIN category c
    ON fc.category_id = c.category_id

GROUP BY

    DATE_FORMAT(
        p.payment_date,
        '%Y-%m'
    ),

    c.category_id,

    c.name;


-- ============================================================
-- 2. VIEW ANALITICA / DETALHADA
--
-- Objetivo:
-- Exibir os registros individuais das locacoes e pagamentos.
--
-- O perfil analitico pode usar esta view para investigar
-- os dados que deram origem aos indicadores gerenciais.
-- ============================================================

CREATE OR REPLACE VIEW vw_n1_locacoes_detalhadas AS

SELECT

    r.rental_id AS aluguel_id,

    r.rental_date AS data_aluguel,

    r.return_date AS data_devolucao,

    cu.customer_id AS cliente_id,

    CONCAT(
        cu.first_name,
        ' ',
        cu.last_name
    ) AS cliente,

    f.film_id AS filme_id,

    f.title AS filme,

    c.name AS categoria,

    i.store_id AS loja,

    p.payment_id AS pagamento_id,

    p.payment_date AS data_pagamento,

    p.amount AS valor_pago

FROM rental r

JOIN customer cu
    ON r.customer_id = cu.customer_id

JOIN inventory i
    ON r.inventory_id = i.inventory_id

JOIN film f
    ON i.film_id = f.film_id

JOIN film_category fc
    ON f.film_id = fc.film_id

JOIN category c
    ON fc.category_id = c.category_id

LEFT JOIN payment p
    ON r.rental_id = p.rental_id;


-- ============================================================
-- 3. TESTE DA VIEW GERENCIAL
-- ============================================================

SELECT *
FROM vw_n1_painel_gerencial
ORDER BY
    mes,
    receita_total DESC
LIMIT 20;


-- ============================================================
-- 4. TESTE DA VIEW ANALITICA
-- ============================================================

SELECT *
FROM vw_n1_locacoes_detalhadas
LIMIT 20;


-- ============================================================
-- 5. COMPARACAO DO NIVEL DE DETALHE
--
-- No ambiente testado:
--
-- vw_n1_painel_gerencial      -> 80 linhas
-- vw_n1_locacoes_detalhadas   -> 16044 linhas
--
-- Isso demonstra que:
--
-- - a view gerencial agrega e resume informacoes;
-- - a view analitica preserva o detalhamento operacional.
-- ============================================================

SELECT
    COUNT(*) AS linhas_gerenciais
FROM vw_n1_painel_gerencial;

SELECT
    COUNT(*) AS linhas_detalhadas
FROM vw_n1_locacoes_detalhadas;


-- ============================================================
-- 6. EXEMPLO DE CONSULTA GERENCIAL
--
-- Mostra as maiores receitas entre todos os meses/categorias.
-- ============================================================

SELECT

    mes,
    categoria,
    total_locacoes,
    clientes_distintos,
    receita_total,
    ticket_medio

FROM vw_n1_painel_gerencial

ORDER BY
    receita_total DESC

LIMIT 10;


-- ============================================================
-- 7. EXEMPLO DE CONSULTA ANALITICA
--
-- Mostra registros individuais para investigacao.
-- ============================================================

SELECT

    aluguel_id,
    data_aluguel,
    cliente,
    filme,
    categoria,
    loja,
    valor_pago

FROM vw_n1_locacoes_detalhadas

LIMIT 10;


-- ============================================================
-- RESULTADO / JUSTIFICATIVA
--
-- A view gerencial e voltada para usuarios que precisam
-- acompanhar indicadores estrategicos e resumidos.
--
-- A view analitica e voltada para usuarios que precisam
-- investigar operacoes individuais do dia a dia.
--
-- Assim, os mesmos dados do banco sao apresentados em
-- diferentes niveis de detalhamento conforme a necessidade
-- de cada perfil.
-- ============================================================
