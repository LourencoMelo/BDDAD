--Aluno B Grupo 01 1190811 Lourenço Melo
--EXERCICIO 5---------------------------------------------------------------------------
 
SET SERVEROUTPUT ON;

TRUNCATE TABLE CAMAREIRA_BONUS;
DROP TABLE CAMAREIRA_BONUS;

--Crio uma tabela ligada à tabela Camareira, para ter estes atributos ligados 
--a este problema do bonus para facilitar a resoluçao do problema
--Esta ligada com uma relacao de muitas para 1 Camareira pois,
--Uma Camareira pode ter varias tabelas de varios anos e meses com os seus 
--respectivos bonus
CREATE TABLE CAMAREIRA_BONUS(
    id_camareira NUMBER(20),
    ano INTEGER NOT NULL,
    mes INTEGER NOT NULL,
    valor_bonus NUMBER(*,2) NOT NULL,
    CONSTRAINT pk_camareira_bonus PRIMARY KEY (id_camareira,ano,mes),
    CONSTRAINT fk_idcamareira FOREIGN KEY (id_camareira) references camareira(id)
);

--Create do procedimento com os parametros
CREATE OR REPLACE PROCEDURE prcAtualizarBonusCamareiras(mes INTEGER, ano INTEGER) AS
--Variaveis e excecoes
aux_ano INTEGER;
aux_mes INTEGER;
ANO_MAIOR_INVALIDO EXCEPTION;
ANO_NEGATIVO_INVALIDO EXCEPTION;
ANO_INVALIDO EXCEPTION;
MES_INVALIDO EXCEPTION;
camareira_counter INTEGER;
camareira_bonus NUMBER(20,2);
check_bonus INTEGER;


BEGIN
    --EXCEPTIONS USADAS NO SCRYPT 4
	--ANO MAIOR_INVALIDO
	IF (ano > EXTRACT(YEAR FROM SYSDATE)) THEN
		RAISE ANO_MAIOR_INVALIDO;
	END IF;
	
	--ANO NEGATIVO INVALIDO
	if (ano < 0) THEN
		RAISE ANO_NEGATIVO_INVALIDO;
	END IF;
	
	--ANO INVALIDO
	IF ano IS NOT NULL THEN
		aux_ano := ano;
		IF (ano <= EXTRACT(YEAR FROM SYSDATE)) THEN
			IF ((ano = EXTRACT(YEAR FROM SYSDATE)) AND (mes > EXTRACT(MONTH FROM SYSDATE))) THEN
                RAISE ANO_INVALIDO;
            END IF;
        END IF;    
	ELSE
		aux_ano := (EXTRACT(YEAR FROM SYSDATE) - 1);
	END IF;
				
	--MES INVALIDO
	IF mes IS NOT NULL OR ((mes<1 AND mes>12)) THEN
		RAISE MES_INVALIDO;
	END IF;
    aux_mes := mes;
    
--Procedimento
    
    --Passar o cam_id o select das id das camareiras
    FOR cam_id IN (SELECT id FROM camareira)
    LOOP
    --VERIFICAR SE TEM CAMAREIRAS COM AS SEGUINTES CONDICOES
        SELECT COUNT(*) INTO camareira_counter
            FROM camareira cam INNER JOIN funcionario f ON (cam.id = f.id)
            INNER JOIN linha_conta_consumo cons ON (cam.id = cons.id_camareira)
            WHERE ((cam_id.id = cam.id)
            AND (EXTRACT(YEAR FROM cons.data_registo) = aux_ano)
            AND (EXTRACT(MONTH FROM cons.data_registo) = aux_mes));
    
    --SE TIVER CAMAREIRA COM A CONDICAO...        
        IF camareira_counter >= 1 THEN
        --Somar o total de consumos para a variavel camareira_bonus em que coincide com todas as informações da tabela
            SELECT SUM(cons.quantidade*cons.preco_unitario) INTO camareira_bonus
            FROM funcionario f INNER JOIN camareira cam ON (f.id = cam.id)
            INNER JOIN linha_conta_consumo cons ON (cons.id_camareira = cam.id)
            WHERE (cam_id.id = cam.id)
            AND (EXTRACT(YEAR FROM cons.data_registo) = aux_ano)
            AND (EXTRACT(YEAR FROM cons.data_registo) = aux_mes)
            GROUP BY f.id;
                
    --CHECK UP DOS VALORES DE BONUS DE ACORDO COM A TABELA          
            IF camareira_bonus <= 100 THEN
                camareira_bonus := 0;
            ELSE IF camareira_bonus > 100 AND camareira_bonus <500 THEN
                camareira_bonus := camareira_bonus * 0.05;
            ELSE IF camareira_bonus >=500 AND camareira_bonus <= 1000 THEN
                camareira_bonus := camareira_bonus * 0.1;
            ELSE
                camareira_bonus := camareira_bonus * 0.15;
            END IF;    
        
            --PRINTS
            --Verificar se já existem bonus na tabela CAMAREIRA_BONUS
            SELECT COUNT(valor_bonus) INTO check_bonus
            FROM camareira_bonus camBonus
            WHERE (camBonus.id_camareira = cam_id.id)
            AND  (aux_ano=camBonus)
            AND (aux_mes=camBonus);
            --Se nao existe o valor bonus na linha
            IF(check_bonus = 0) THEN
                INSERT INTO camareira_bonus (id_camareira, ano, mes, camareira_bonus)
                VALUES(cam_id.id, aux_ano, aux_mes, camareira_bonus);
                DBMS_OUTPUT.PUT_LINE('INSERT FEITO NA TABELA CAMAREIRA_BONUS:');
                DBMS_OUTPUT.PUT_LINE('ID da Camareira:              '|| cam_id);
                DBMS_OUTPUT.PUT_LINE('Ano:                          '|| aux_ano);
                DBMS_OUTPUT.PUT_LINE('Mes:                          '|| aux_mes);
                DBMS_OUTPUT.PUT_LINE('Bonus:                '|| camareira_bonus);
            --Se ja existir faz um UPDATE
            ELSE
                UPDATE camareira_bonus camBonus SET camBonus.valor_bonus = camareira_bonus 
                WHERE camBonus.id_camareira = cam_id.id
                AND aux_ano = camBonus.ano
                AND aux_mes = camBonus.mes;
                DBMS_OUTPUT.PUT_LINE('UPDATE FEITO NA TABELA CAMAREIRA_BONUS:');
                DBMS_OUTPUT.PUT_LINE('ID da Camareira:              '|| cam_id);
                DBMS_OUTPUT.PUT_LINE('Ano:                          '|| aux_ano);
                DBMS_OUTPUT.PUT_LINE('Mes:                          '|| aux_mes);
                DBMS_OUTPUT.PUT_LINE('Bonus:                '|| camareira_bonus);
            END IF;    
        ELSE
        --Se nao existir nenhuma camareira com as condicoes imprime...
            DBMS_OUTPUT.PUT_LINE('Nao existe nenhuma camareira com essas condições com o seguinte id' || cam_id.id);
        END IF;
    END LOOP;

--EXCEPTIONS
EXCEPTION WHEN ANO_MAIOR_INVALIDO THEN
	RAISE_APPLICATION_ERROR(-20000, 'Ano maior inválido');
WHEN ANO_INVALIDO THEN
	RAISE_APPLICATION_ERROR(-20001, 'Ano inválido');
WHEN ANO_NEGATIVO_INVALIDO THEN
	RAISE_APPLICATION_ERROR(-20002, 'Ano negativo inválido');
WHEN MES_INVALIDO THEN
	RAISE_APPLICATION_ERROR(-20004, 'Mes inválido');
END;  
/    
--TESTES
--Teste com o mes de março
BEGIN
    prcAtualizarBonusCamareiras(3);
END
    
--Ver a informação da nova tabela    
SELECT * FROM camareira_bonus;   

