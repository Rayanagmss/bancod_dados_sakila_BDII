USE sakila;




DROP PROCEDURE IF EXISTS sp_n1_relatorio_receita_categoria;




DELIMITER $$

CREATE PROCEDURE sp_n1_relatorio_receita_categoria (

    IN p_data_inicio DATE,
    IN p_data_fim DATE

)

BEGIN


    IF p_data_inicio IS NULL OR p_data_fim IS NULL THEN

        SIGNAL SQLSTATE '45000'

        SET MESSAGE_TEXT =
        'As datas inicial e final devem ser informadas.';

    END IF;




    IF p_data_inicio > p_data_fim THEN

        SIGNAL SQLSTATE '45000'

        SET MESSAGE_TEXT =
        'A data inicial nao pode ser maior que a data final.';

    END IF;



    SELECT

        -- Nome da categoria do filme
        c.name AS categoria,


        -- Quantidade de locacoes diferentes da categoria
        COUNT(
            DISTINCT r.rental_id
        ) AS total_locacoes,


        -- Quantidade de clientes diferentes que realizaram
        -- locacoes daquela categoria
        COUNT(
            DISTINCT r.customer_id
        ) AS clientes_distintos,


        -- Soma de todos os pagamentos daquela categoria
        -- dentro do periodo informado
        ROUND(
            SUM(p.amount),
            2
        ) AS receita_total,


        -- Valor medio dos pagamentos daquela categoria
        ROUND(
            AVG(p.amount),
            2
        ) AS ticket_medio


    FROM payment p


    -- Relaciona o pagamento com a locacao
    JOIN rental r
        ON p.rental_id = r.rental_id


    -- Relaciona a locacao com o item do estoque
    JOIN inventory i
        ON r.inventory_id = i.inventory_id


    -- Descobre qual filme pertence ao item alugado
    JOIN film f
        ON i.film_id = f.film_id


    -- Relaciona o filme com sua categoria
    JOIN film_category fc
        ON f.film_id = fc.film_id


    -- Recupera o nome da categoria
    JOIN category c
        ON fc.category_id = c.category_id



    WHERE

        p.payment_date >= p_data_inicio

        AND p.payment_date < DATE_ADD(
            p_data_fim,
            INTERVAL 1 DAY
        )




    GROUP BY

        c.category_id,
        c.name



    ORDER BY

        receita_total DESC,
        categoria ASC;


END $$

DELIMITER ;



SHOW PROCEDURE STATUS
WHERE Db = 'sakila'
  AND Name = 'sp_n1_relatorio_receita_categoria';



CALL sp_n1_relatorio_receita_categoria(
    '2005-05-01',
    '2005-08-31'
);



CALL sp_n1_relatorio_receita_categoria(
    '2005-06-01',
    '2005-06-30'
);