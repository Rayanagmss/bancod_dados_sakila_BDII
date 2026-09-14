USE sakila;

WITH receita_mensal AS (

    SELECT
        DATE_FORMAT(p.payment_date, '%Y-%m') AS mes,
        c.name AS categoria,
        SUM(p.amount) AS receita

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
        DATE_FORMAT(p.payment_date, '%Y-%m'),
        c.name
),

comparacao_mensal AS (

    SELECT
        mes,
        categoria,
        receita,

        LAG(receita) OVER (
            PARTITION BY categoria
            ORDER BY mes
        ) AS receita_mes_anterior

    FROM receita_mensal
),

ranking_mensal AS (

    SELECT
        mes,
        categoria,
        receita,
        receita_mes_anterior,

        receita - receita_mes_anterior AS variacao_receita,

        DENSE_RANK() OVER (
            PARTITION BY mes
            ORDER BY receita DESC
        ) AS posicao

    FROM comparacao_mensal
)

SELECT
    mes,
    categoria,
    receita,
    receita_mes_anterior,
    variacao_receita,
    posicao

FROM ranking_mensal

WHERE posicao <= 3

ORDER BY
    mes,
    posicao,
    categoria;