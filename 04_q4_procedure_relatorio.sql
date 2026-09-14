-- ============================================================
-- TRABALHO PRATICO SQL N1
-- Q4 - AUTOMACAO DE RELATORIO COM STORED PROCEDURE
-- Banco de Dados: Sakila
--
-- OBJETIVO:
-- Criar uma procedure parametrizada que gere um relatorio
-- consolidado do desempenho das categorias de filmes em um
-- periodo informado pelo usuario.
--
-- PARAMETROS:
-- p_data_inicio -> data inicial do periodo
-- p_data_fim    -> data final do periodo
--
-- O relatorio retorna:
-- - categoria
-- - total de locacoes
-- - clientes distintos
-- - receita total
-- - ticket medio
--
-- Tambem sao feitas validacoes para impedir:
-- - datas nulas
-- - data inicial maior que a data final
-- ============================================================

USE sakila;


-- ============================================================
-- 1. REMOVE A PROCEDURE ANTERIOR, CASO JA EXISTA
-- ============================================================

DROP PROCEDURE IF EXISTS sp_n1_relatorio_receita_categoria;


-- ============================================================
-- 2. CRIACAO DA PROCEDURE
-- ============================================================

DELIMITER $$

CREATE PROCEDURE sp_n1_relatorio_receita_categoria (

    IN p_data_inicio DATE,
    IN p_data_fim DATE

)

BEGIN

    -- ========================================================
    -- VALIDACAO 1
    -- As duas datas precisam ser informadas.
    -- ========================================================

    IF p_data_inicio IS NULL OR p_data_fim IS NULL THEN

        SIGNAL SQLSTATE '45000'

        SET MESSAGE_TEXT =
        'As datas inicial e final devem ser informadas.';

    END IF;


    -- ========================================================
    -- VALIDACAO 2
    -- A data inicial nao pode ser posterior a data final.
    -- ========================================================

    IF p_data_inicio > p_data_fim THEN

        SIGNAL SQLSTATE '45000'

        SET MESSAGE_TEXT =
        'A data inicial nao pode ser maior que a data final.';

    END IF;


    -- ========================================================
    -- RELATORIO CONSOLIDADO
    --
    -- A consulta percorre:
    -- payment -> rental -> inventory -> film
    -- -> film_category -> category
    --
    -- Dessa forma, conseguimos relacionar os pagamentos
    -- realizados com as categorias dos filmes alugados.
    -- ========================================================

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


    -- ========================================================
    -- FILTRO POR PERIODO
    --
    -- A data inicial e inclusiva.
    --
    -- Para incluir todo o ultimo dia informado, somamos
    -- um dia a p_data_fim e usamos "<".
    --
    -- Exemplo:
    -- p_data_fim = 2005-08-31
    -- considera registros anteriores a 2005-09-01.
    -- ========================================================

    WHERE

        p.payment_date >= p_data_inicio

        AND p.payment_date < DATE_ADD(
            p_data_fim,
            INTERVAL 1 DAY
        )


    -- ========================================================
    -- AGRUPAMENTO
    --
    -- Cada linha do resultado representa uma categoria.
    -- ========================================================

    GROUP BY

        c.category_id,
        c.name


    -- ========================================================
    -- ORDENACAO
    --
    -- Primeiro aparecem as categorias com maior receita.
    -- Em caso de empate, ordena pelo nome da categoria.
    -- ========================================================

    ORDER BY

        receita_total DESC,
        categoria ASC;


END $$

DELIMITER ;


-- ============================================================
-- 3. VERIFICACAO DA PROCEDURE
-- ============================================================

SHOW PROCEDURE STATUS
WHERE Db = 'sakila'
  AND Name = 'sp_n1_relatorio_receita_categoria';


-- ============================================================
-- 4. TESTE PRINCIPAL
--
-- Exemplo de chamada com um periodo valido.
-- ============================================================

CALL sp_n1_relatorio_receita_categoria(
    '2005-05-01',
    '2005-08-31'
);


-- ============================================================
-- 5. EXEMPLO DE OUTRA CHAMADA
--
-- A mesma procedure pode ser reutilizada para outro periodo
-- sem alterar sua estrutura.
-- ============================================================

CALL sp_n1_relatorio_receita_categoria(
    '2005-06-01',
    '2005-06-30'
);


-- ============================================================
-- 6. TESTE DE VALIDACAO
--
-- O comando abaixo DEVE gerar erro, pois a data inicial
-- e maior que a data final.
--
-- Mensagem esperada:
-- "A data inicial nao pode ser maior que a data final."
--
-- Descomente para testar:
-- ============================================================

-- CALL sp_n1_relatorio_receita_categoria(
--     '2005-08-31',
--     '2005-05-01'
-- );


-- ============================================================
-- RESULTADO ESPERADO
--
-- A procedure deve retornar uma tabela com:
--
-- categoria
-- total_locacoes
-- clientes_distintos
-- receita_total
-- ticket_medio
--
-- Dessa forma, a Q4 atende aos requisitos de:
--
-- - procedure parametrizada
-- - pelo menos dois parametros
-- - JOINs entre varias tabelas
-- - COUNT
-- - SUM
-- - AVG
-- - resultado consolidado
-- - validacao de parametros
-- - tratamento de erro com SIGNAL
-- ============================================================
