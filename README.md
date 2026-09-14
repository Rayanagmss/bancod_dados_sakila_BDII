# Trabalho Prático SQL N1 — Sakila

1. Sobre o projeto

Este repositório contém o desenvolvimento do Trabalho Prático SQL N1, utilizando o banco de dados Sakila, disponibilizado oficialmente como banco de exemplo do MySQL.

O objetivo do trabalho é aplicar conceitos de SQL avançado em um banco relacional realista, utilizando:

CTEs;

funções de janela;

views;

triggers;

stored procedures;

agregações;

JOINs;

validações;

regras de negócio;

auditoria;

diferentes níveis de consumo da informação.

O banco Sakila representa o funcionamento de uma locadora de filmes e possui informações sobre clientes, filmes, categorias, estoques, locações, pagamentos, funcionários e lojas.

2. Banco de dados utilizado

Sakila

O Sakila foi escolhido por possuir:

várias tabelas relacionadas;

chaves primárias e estrangeiras;

dados temporais;

dados de clientes;

informações de filmes e categorias;

registros de locações;

pagamentos;

estrutura adequada para consultas analíticas e regras de negócio.

Entre as principais tabelas utilizadas no trabalho estão:

customer

rental

payment

inventory

film

film_category

category

staff

Relacionamento principal utilizado

customer
   ↓
rental
   ↓
inventory
   ↓
film
   ↓
film_category
   ↓
category

rental
   ↓
payment

3. Estrutura sugerida do repositório

trabalho-sql-n1-sakila/
│
├── README.md
│
├── banco/
│   ├── sakila-schema.sql
│   └── sakila-data.sql
│
├── scripts/
│   ├── 01_q1_panorama_ranking.sql
│   ├── 02_q2_view_analitica.sql
│   ├── 03_q3_trigger_auditoria.sql
│   ├── 04_q4_procedure_relatorio.sql
│   └── 05_q5_views_perfis.sql
│
├── documentacao/
│   ├── Guia_Detalhado_SQL_N1_Q1_Q2_Q3.pdf
│   ├── Guia_Detalhado_SQL_N1_Q4_Q5.pdf
│   └── Ebook_SQL_N1_Sakila_Do_Zero_a_Apresentacao.pdf
│
└── apresentacao/
    └── Apresentacao_SQL_N1_Sakila_Com_Falas.pptx

4. Preparação do banco

O banco deve ser criado antes da execução das questões.

Passo 1 — executar o schema

Abrir e executar:

sakila-schema.sql

Esse arquivo cria:

o schema sakila;

tabelas;

chaves;

relacionamentos;

views;

triggers;

procedures originais do banco.

Passo 2 — carregar os dados

Executar:

sakila-data.sql

Esse arquivo insere os dados nas tabelas.

Passo 3 — validar a importação

USE sakila;

SELECT COUNT(*) AS quantidade_filmes
FROM film;

SELECT COUNT(*) AS quantidade_clientes
FROM customer;

SELECT COUNT(*) AS quantidade_alugueis
FROM rental;

SELECT COUNT(*) AS quantidade_pagamentos
FROM payment;

No banco utilizado no projeto, foram encontrados:

filmes:      1000
clientes:     599
aluguéis:   16044
pagamentos: 16044

5. Q1 — Panorama temporal e ranking

Objetivo

Identificar as 3 categorias de filmes com maior receita em cada mês e analisar a variação da receita em relação ao período anterior.

Conceitos utilizados

WITH / CTE;

SUM;

GROUP BY;

LAG;

DENSE_RANK;

PARTITION BY;

ORDER BY;

DATE_FORMAT;

funções de janela.

Lógica

A consulta foi dividida em três etapas.

1. Receita mensal

Calcula a soma dos pagamentos para cada categoria em cada mês.

mês + categoria → receita

2. Comparação com o período anterior

Utiliza:

LAG(receita)

para recuperar a receita da mesma categoria no mês anterior.

3. Ranking

Utiliza:

DENSE_RANK()

para classificar as categorias por receita dentro de cada mês.

A função DENSE_RANK() também permite tratar empates corretamente.

Resultado final

A consulta retorna:

mês;

categoria;

receita atual;

receita do mês anterior;

variação da receita;

posição no ranking.

O resultado final é filtrado para:

WHERE posicao <= 3

ou seja, somente o Top 3 de cada mês.

Arquivo

01_q1_panorama_ranking.sql

6. Q2 — View analítica de locações atrasadas

Objetivo

Criar uma view para identificar locações devolvidas depois do prazo permitido e classificá-las por prioridade.

Regra utilizada

Uma locação é considerada atrasada quando:

dias em que o cliente ficou com o filme
>
dias permitidos para aluguel

O prazo permitido está armazenado em:

film.rental_duration

Cálculo do atraso

Foi utilizada a função:

DATEDIFF(return_date, rental_date)

Depois:

dias_locado - dias_permitidos = dias_atraso

Priorização

A regra definida foi:

1 dia de atraso       → Score 1 → BAIXA
2 a 4 dias de atraso  → Score 2 → MEDIA
5 dias ou mais        → Score 3 → ALTA

A classificação foi implementada utilizando:

CASE

View criada

vw_n1_locacoes_atrasadas

Ela apresenta informações como:

aluguel;

cliente;

filme;

categoria;

loja;

data do aluguel;

data da devolução;

dias permitidos;

dias utilizados;

dias de atraso;

valor pago;

score;

prioridade.

Arquivo

02_q2_view_analitica.sql

7. Q3 — Trigger com auditoria

Objetivo

Garantir uma regra de negócio através de um trigger e registrar tentativas de violação.

Regra definida

Um cliente inativo não pode realizar uma nova locação.

O status é obtido através da coluna:

customer.active

Trigger criado

trg_n1_bloqueia_cliente_inativo

Ele é executado:

BEFORE INSERT ON rental

Funcionamento

Quando uma nova locação é tentada:

INSERT em rental
        ↓
trigger é executado
        ↓
verifica customer.active
        ↓
cliente ativo?
   ├─ SIM → operação continua
   └─ NÃO
        ↓
registra tentativa
        ↓
SIGNAL bloqueia a operação

Tabela de auditoria

Foi criada:

log_locacao_bloqueada

Ela registra:

data e hora;

usuário;

operação;

cliente;

item do inventário;

motivo do bloqueio.

Bloqueio

A operação inválida é interrompida com:

SIGNAL SQLSTATE '45000'

Observação sobre o ambiente utilizado

Durante os testes, o servidor MySQL utilizado estava com GTID ativo.

Como a tabela de auditoria utiliza MyISAM e a tabela rental utiliza InnoDB, foi necessário desativar temporariamente o binary log apenas na sessão de demonstração:

SET SESSION sql_log_bin = 0;

Depois do teste:

SET SESSION sql_log_bin = 1;

Essa adaptação é utilizada apenas na demonstração do ambiente em que o projeto foi desenvolvido.

Arquivo

03_q3_trigger_auditoria.sql

8. Q4 — Stored Procedure para relatório parametrizado

Objetivo

Criar uma stored procedure que gere um relatório consolidado das categorias de filmes dentro de um período escolhido pelo usuário.

Procedure criada

sp_n1_relatorio_receita_categoria

Parâmetros

IN p_data_inicio DATE,
IN p_data_fim DATE

O usuário informa:

data inicial;

data final.

Exemplo:

CALL sp_n1_relatorio_receita_categoria(
    '2005-05-01',
    '2005-08-31'
);

Resultado

A procedure retorna:

categoria;

total de locações;

clientes distintos;

receita total;

ticket médio.

Funções utilizadas

COUNT

COUNT(DISTINCT r.rental_id)

Conta as locações.

COUNT DISTINCT

COUNT(DISTINCT r.customer_id)

Conta clientes diferentes.

SUM

SUM(p.amount)

Calcula a receita total.

AVG

AVG(p.amount)

Calcula o valor médio dos pagamentos.

ROUND

ROUND(valor, 2)

Mantém duas casas decimais.

Validações

A procedure valida:

Datas obrigatórias

Se alguma data for NULL, é gerado um erro.

Ordem das datas

A data inicial não pode ser posterior à data final.

O erro é gerado através de:

SIGNAL SQLSTATE '45000'

Arquivo

04_q4_procedure_relatorio.sql

9. Q5 — Views para diferentes perfis

Objetivo

Criar duas views destinadas a perfis diferentes de usuários.

Foram definidos:

perfil gerencial
perfil analítico

9.1 View gerencial

Nome

vw_n1_painel_gerencial

Objetivo

Apresentar uma visão resumida do negócio.

Cada linha representa:

mês + categoria

Indicadores

total de locações;

clientes distintos;

receita total;

ticket médio.

Resultado validado

A view retornou:

80 linhas

Isso ocorre porque os dados foram agregados.

9.2 View analítica

Nome

vw_n1_locacoes_detalhadas

Objetivo

Permitir a investigação das operações individuais.

A view apresenta:

ID da locação;

data da locação;

data da devolução;

ID do cliente;

cliente;

ID do filme;

filme;

categoria;

loja;

pagamento;

data do pagamento;

valor pago.

Resultado validado

A view retornou:

16044 linhas

Ela possui muito mais registros porque mantém o nível operacional detalhado.

Diferença entre as duas views

VIEW GERENCIAL
      ↓
dados agregados
      ↓
visão estratégica


VIEW ANALÍTICA
      ↓
dados detalhados
      ↓
investigação operacional

Arquivo

05_q5_views_perfis.sql

10. Resumo das entregas

Questão

Recurso principal

Implementação

Q1

CTE + função de janela

Top 3 categorias por receita mensal

Q2

View analítica

locações atrasadas e priorização

Q3

Trigger + auditoria

bloqueio de locação para cliente inativo

Q4

Stored Procedure

relatório por intervalo de datas

Q5

Views por perfil

visão gerencial e visão detalhada

11. Como executar os scripts

A ordem recomendada é:

1. sakila-schema.sql
2. sakila-data.sql

3. 01_q1_panorama_ranking.sql
4. 02_q2_view_analitica.sql
5. 03_q3_trigger_auditoria.sql
6. 04_q4_procedure_relatorio.sql
7. 05_q5_views_perfis.sql

Antes de executar qualquer questão:

USE sakila;

12. Demonstração sugerida

Q1

Executar a consulta e mostrar:

mês;

categoria;

receita;

receita anterior;

variação;

ranking.

Destacar:

LAG()
DENSE_RANK()
PARTITION BY

Q2

Executar:

SELECT *
FROM vw_n1_locacoes_atrasadas
ORDER BY
    score_prioridade DESC,
    dias_atraso DESC
LIMIT 15;

Mostrar:

atrasos;

score;

prioridade.

Q3

Selecionar um cliente inativo e tentar inserir uma locação.

Resultado esperado:

Operacao bloqueada:
cliente inativo nao pode realizar locacao.

Depois consultar:

SELECT *
FROM log_locacao_bloqueada
ORDER BY log_id DESC;

Q4

Executar:

CALL sp_n1_relatorio_receita_categoria(
    '2005-05-01',
    '2005-08-31'
);

Depois alterar o período para demonstrar que a procedure é reutilizável.

Q5

Consultar a view gerencial:

SELECT *
FROM vw_n1_painel_gerencial
ORDER BY receita_total DESC
LIMIT 10;

Depois consultar a view detalhada:

SELECT *
FROM vw_n1_locacoes_detalhadas
LIMIT 10;

Explicar a diferença de granularidade.

13. Conceitos principais do projeto

CTE

Uma CTE é um resultado temporário nomeado dentro de uma consulta.

WITH nome AS (
    SELECT ...
)
SELECT *
FROM nome;

Ela ajuda a dividir consultas maiores em etapas.

Função de janela

Realiza cálculos sobre grupos de linhas sem necessariamente reduzir o resultado como um GROUP BY.

Exemplos utilizados:

LAG()
DENSE_RANK()

VIEW

Uma view funciona como uma consulta salva.

CREATE VIEW nome AS
SELECT ...

Depois:

SELECT *
FROM nome;

TRIGGER

Um trigger é executado automaticamente quando determinado evento acontece em uma tabela.

Exemplo:

BEFORE INSERT ON rental

STORED PROCEDURE

Uma procedure é um programa SQL armazenado dentro do banco.

Pode receber parâmetros e ser executada através de:

CALL nome(...);

JOIN

Relaciona dados presentes em tabelas diferentes.

Exemplo:

JOIN rental r
    ON p.rental_id = r.rental_id

GROUP BY

Agrupa registros para realizar cálculos como:

SUM
COUNT
AVG

CASE

Permite criar decisões dentro de uma consulta.

Exemplo:

CASE
    WHEN condicao THEN resultado
    ELSE outro_resultado
END

SIGNAL

Permite gerar um erro controlado pelo próprio código SQL.

SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT = 'Mensagem';

14. Conclusão

O trabalho demonstra diferentes formas de utilizar SQL para além de consultas simples.

As cinco questões trabalham:

análise temporal;

rankings;

funções de janela;

organização com CTEs;

detecção e priorização de problemas;

criação de views;

aplicação automática de regras de negócio;

auditoria;

procedures parametrizadas;

agregações;

diferentes níveis de consumo da informação.

A combinação desses recursos mostra como um banco de dados pode ser utilizado não apenas para armazenar informações, mas também para:

analisar;

organizar;

automatizar;

validar;

proteger;

disponibilizar dados para diferentes usuários.

Arquivos principais

01_q1_panorama_ranking.sql
02_q2_view_analitica.sql
03_q3_trigger_auditoria.sql
04_q4_procedure_relatorio.sql
05_q5_views_perfis.sql

Banco:

sakila-schema.sql
sakila-data.sql