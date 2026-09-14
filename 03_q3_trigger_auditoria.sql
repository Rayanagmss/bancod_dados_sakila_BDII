-- ============================================================
-- TRABALHO PRATICO SQL N1
-- Q3 - GARANTIA DE REGRA DE NEGOCIO
-- TRIGGER COM AUDITORIA
-- Banco de Dados: Sakila
--
-- REGRA:
-- Cliente inativo (customer.active = 0) nao pode realizar
-- uma nova locacao.
--
-- A tentativa invalida deve:
-- 1) ser registrada em uma tabela de log;
-- 2) ser bloqueada pelo trigger.
--
-- OBSERVACAO IMPORTANTE:
-- O ambiente utilizado no desenvolvimento usa GTID.
-- Por isso, para a demonstracao com log MyISAM, o binary log
-- precisa ser desativado SOMENTE na sessao de teste.
-- Depois do teste, ele deve ser reativado.
-- ============================================================

USE sakila;


-- ============================================================
-- 1. LIMPEZA SEGURA DOS OBJETOS DA Q3
-- ============================================================

DROP TRIGGER IF EXISTS trg_n1_bloqueia_cliente_inativo;
DROP TABLE IF EXISTS log_locacao_bloqueada;


-- ============================================================
-- 2. TABELA DE AUDITORIA
--
-- MyISAM foi usado porque o log precisa permanecer gravado
-- mesmo quando o SIGNAL cancela o INSERT em rental.
-- ============================================================

CREATE TABLE log_locacao_bloqueada (

    log_id INT NOT NULL AUTO_INCREMENT,

    data_hora TIMESTAMP NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    usuario VARCHAR(100) NOT NULL,

    operacao VARCHAR(20) NOT NULL,

    customer_id SMALLINT UNSIGNED,

    inventory_id MEDIUMINT UNSIGNED,

    motivo VARCHAR(255) NOT NULL,

    PRIMARY KEY (log_id)

) ENGINE = MyISAM;


-- ============================================================
-- 3. TRIGGER
--
-- ATENCAO:
-- A definicao abaixo foi mantida sem acentos/comentarios
-- internos para evitar problemas de codificacao no cliente
-- mysql usado durante os testes.
-- ============================================================

DELIMITER $$

CREATE TRIGGER trg_n1_bloqueia_cliente_inativo
BEFORE INSERT ON rental
FOR EACH ROW
BEGIN

    DECLARE v_cliente_ativo TINYINT;

    SELECT active
    INTO v_cliente_ativo
    FROM customer
    WHERE customer_id = NEW.customer_id;

    IF v_cliente_ativo = 0 THEN

        INSERT INTO log_locacao_bloqueada (
            data_hora,
            usuario,
            operacao,
            customer_id,
            inventory_id,
            motivo
        )
        VALUES (
            CURRENT_TIMESTAMP,
            CURRENT_USER(),
            'INSERT',
            NEW.customer_id,
            NEW.inventory_id,
            'Tentativa de locacao realizada por cliente inativo'
        );

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
        'Operacao bloqueada: cliente inativo nao pode realizar locacao.';

    END IF;

END $$

DELIMITER ;


-- ============================================================
-- 4. VERIFICACAO DA CRIACAO DO TRIGGER
-- ============================================================

SHOW TRIGGERS
FROM sakila
WHERE `Trigger` = 'trg_n1_bloqueia_cliente_inativo';


-- ============================================================
-- 5. PREPARACAO DOS DADOS PARA DEMONSTRACAO
-- ============================================================

SET @cliente_inativo = (
    SELECT customer_id
    FROM customer
    WHERE active = 0
    LIMIT 1
);

SET @inventory_teste = (
    SELECT inventory_id
    FROM inventory
    LIMIT 1
);

SET @staff_teste = (
    SELECT staff_id
    FROM staff
    LIMIT 1
);

SELECT
    @cliente_inativo AS cliente_inativo,
    @inventory_teste AS inventory_teste,
    @staff_teste AS funcionario_teste;

SELECT
    customer_id,
    first_name,
    last_name,
    active
FROM customer
WHERE customer_id = @cliente_inativo;


-- ============================================================
-- 6. DEMONSTRACAO DA REGRA
--
-- IMPORTANTE:
-- No ambiente testado, GTID esta ativo.
-- Por isso, desativamos o binary log SOMENTE nesta sessao.
--
-- Se o servidor do professor nao usar GTID ou nao apresentar
-- o erro 1785, esta linha pode ser dispensada.
-- ============================================================

SET SESSION sql_log_bin = 0;


-- ============================================================
-- 7. TESTE QUE DEVE SER BLOQUEADO
--
-- O comando abaixo DEVE gerar:
--
-- ERROR 1644 (45000):
-- Operacao bloqueada: cliente inativo nao pode realizar locacao.
--
-- Esse erro e o comportamento esperado.
-- ============================================================

INSERT INTO rental (
    rental_date,
    inventory_id,
    customer_id,
    return_date,
    staff_id
)
VALUES (
    NOW(),
    @inventory_teste,
    @cliente_inativo,
    NULL,
    @staff_teste
);


-- ============================================================
-- 8. CONSULTA DO LOG
--
-- Mesmo com a locacao bloqueada, a tentativa deve aparecer.
-- ============================================================

SELECT
    log_id,
    data_hora,
    usuario,
    operacao,
    customer_id,
    inventory_id,
    motivo
FROM log_locacao_bloqueada
ORDER BY log_id DESC;


-- ============================================================
-- 9. REATIVACAO DO BINARY LOG NA SESSAO
-- ============================================================

SET SESSION sql_log_bin = 1;

SELECT @@SESSION.sql_log_bin AS binary_log_sessao;


-- ============================================================
-- RESULTADO ESPERADO
--
-- 1) O cliente inativo e identificado.
-- 2) O trigger e executado automaticamente antes do INSERT.
-- 3) A tentativa e registrada em log_locacao_bloqueada.
-- 4) SIGNAL SQLSTATE '45000' bloqueia a locacao.
-- 5) O aluguel invalido nao entra em rental.
-- 6) O log permanece registrado para auditoria.
-- ============================================================
