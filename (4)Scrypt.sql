--Aluno B Grupo 01 1190811 Lourenço Melo

--EXECICIO 4----------------------------------------------------------
--Controla o output de prints
SET SERVEROUTPUT ON;

CREATE OR REPLACE FUNCTION fncObterRegistoMensalCamareira(mes INTEGER, ano INTEGER) 
RETURN SYS_REFCURSOR
AS resultado_final SYS_REFCURSOR;

aux_ano INTEGER;
ANO_MAIOR_INVALIDO EXCEPTION;
ANO_NEGATIVO_INVALIDO EXCEPTION;
ANO_INVALIDO EXCEPTION;
MES_INVALIDO EXCEPTION;
aux_data DATE;
aux_dias_mes INTEGER;
cal_ano INTEGER;
cal_mes INTEGER;
cal_data INTEGER;
aux_string VARCHAR2(30000);

BEGIN
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
		aux_ano := EXTRACT(YEAR FROM SYSDATE) - 1;
	END IF;
				
	--MES INVALIDO
	IF mes IS NOT NULL OR ((mes<1 AND mes>12)) THEN
		RAISE MES_INVALIDO;
	END IF;

    
    --"FUNÇÃO"
    --Passar um NUMBER para CHAR, e depois passara para DATE
    cal_ano := aux_ano * 10000;
    cal_mes := mes * 100;
    cal_data := aux_ano + mes + 1;
    SELECT TO_CHAR(cal_data, '99999999') INTO aux_string FROM DUAL;
    SELECT TO_DATE(aux_string,'yyyy/mm/dd') INTO aux_data FROM DUAL;
    
    --Descubrir o numero total de dias no mes passado por parametro menos 1
    SELECT (LAST_DAY(aux_data)- aux_data) INTO aux_dias_mes FROM DUAL;
    
	OPEN resultado_final FOR
    --Subtrair o numero total de dias do mes com o numero de dias que houve consumos
	SELECT f.id, f.nome, SUM(cons.quantidade*cons.preco_unitario), MIN(cons.data_registo), MAX(cons.data_registo), (aux_dias_mes+1) - COUNT (DISTINCT(EXTRACT(DAY FROM cons.data_registo)))
    FROM funcionario f INNER JOIN camareira cam ON(cam.id = f.id)
    INNER JOIN linha_conta_consumo cons ON ((cons.id_camareira = cam.id))
    WHERE ((aux_ano = EXTRACT(YEAR FROM cons.data_registo)))
    AND  (mes = EXTRACT(MONTH FROM cons.data_registo))
    GROUP BY f.id, f.nome;        
	RETURN resultado_final;

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


DECLARE
	resultado_final SYS_REFCURSOR;
	id funcionario.id%type;
	nome funcionario.nome%type;
	valor_total INTEGER;
	data_primeiro_reg linha_conta_consumo.data_registo%type;
	data_ult_reg linha_conta_consumo.data_registo%type;
	qnt_dias_scons INTEGER;

BEGIN
--Registo mensal de março
	resultado:= fncObterRegistoMensalCamareira(3);
	LOOP
        FETCH resultado_final INTO id, nome, valor_total, data_primeiro_reg, data_ult_reg, qnt_dias_scons;
            EXIT WHEN(resultado_final%NOTFOUND);
 			 DBMS_OUTPUT.PUT_LINE('---------------RESULTADO----------------');
			 DBMS_OUTPUT.PUT_LINE('ID da Camareira:                        '|| id);
			 DBMS_OUTPUT.PUT_LINE('NOME da Camareira:                      '|| nome);
			 DBMS_OUTPUT.PUT_LINE('Valor total:                  	       '|| valor_total);
			 DBMS_OUTPUT.PUT_LINE('Data Primeiro Registo:                  '|| data_primeiro_reg);
			 DBMS_OUTPUT.PUT_LINE('Data Ultimo Registo:                    '|| data_ult_reg);
			 DBMS_OUTPUT.PUT_LINE('Quantidade dias sem consumos:           '|| qnt_dias_scons);
			 DBMS_OUTPUT.PUT_LINE('----------------------------------------');
	END LOOP;
	CLOSE resultado_final;
END;
/

--Testes
--Mostrar se o mes é março e o ano é 2019, das seguintes informacoes etc...
    SELECT cons.id_camareira, SUM(cons.quantidade*cons.preco_unitario), COUNT(DISTINCT(EXTRACT(DAY FROM cons.data_registo))) 
    FROM linha_conta_consumo cons 
    WHERE ((EXTRACT(MONTH FROM cons.data_registo)= 3) 
    AND (EXTRACT(YEAR FROM cons.data_registo)= 2019)) 
    GROUP BY cons.id_camareira 
    ORDER BY cons.id_camareira;