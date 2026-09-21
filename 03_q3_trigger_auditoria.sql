USE sakila;

DROP TRIGGER IF EXISTS trg_n1_bloqueia_cliente_inativo;
DROP TABLE IF EXISTS log_locacao_bloqueada;


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



SHOW TRIGGERS
FROM sakila
WHERE `Trigger` = 'trg_n1_bloqueia_cliente_inativo';


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



SET SESSION sql_log_bin = 0;



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



SET SESSION sql_log_bin = 1;

SELECT @@SESSION.sql_log_bin AS binary_log_sessao;


