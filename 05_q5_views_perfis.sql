

USE sakila;




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



SELECT *
FROM vw_n1_painel_gerencial
ORDER BY
    mes,
    receita_total DESC
LIMIT 20;




SELECT *
FROM vw_n1_locacoes_detalhadas
LIMIT 20;


SELECT
    COUNT(*) AS linhas_gerenciais
FROM vw_n1_painel_gerencial;

SELECT
    COUNT(*) AS linhas_detalhadas
FROM vw_n1_locacoes_detalhadas;



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