--Aluno B Grupo 01 1190811 Lourenço Melo
--EXERCICIO 6-------------------------------------------------------

CREATE OR REPLACE TRIGGER trgCorrigirAlteracaoBonus
BEFORE INSERT OR UPDATE ON camareira_Bonus
FOR EACH ROW

BEGIN
    --If que funciona se for um INSERT
    IF INSERTING THEN
        IF (:old.valor_bonus > :new.valor_bonus) THEN
            RAISE_APPLICATION_ERROR(-20008, 'O Bonus nao pode ser reduzido!');
        END IF;
        IF((:old.valor_bonus > 0) and (:new.valor_bonus >(:old.valor_bonus * 0.5 + old.valor_bonus)))THEN
            RAISE_APPLICATION_ERROR(-20009, 'O bonus chegou a mais de 50%!');
        END IF;
    --Else que funciona se for um UPDATE    
    ELSE IF UPDATING THEN
        IF (:old.valor_bonus > :new.valor_bonus) THEN
            RAISE_APPLICATION_ERROR(-200010, 'O Bonus nao pode ser reduzido!');
        END IF;
        IF((:old.valor_bonus > 0) and (:new.valor_bonus >(:old.valor_bonus * 0.5 + old.valor_bonus)))THEN
            RAISE_APPLICATION_ERROR(-20011, 'O bonus chegou a mais de 50%!');
        END IF;
    ELSE
        RAISE_APPLICATION_ERROR(-20012,'Nao é permitida esta alteracao ao bonus!');
    END IF;    
END;

    
--TESTES
--UPDATE na tabela camareira_bonus
UPDATE camareira_bonus camBonus SET
cambo.valor_bonus = 2000
WHERE id_camareira = 11   
AND mes = 11;

--INSERT na tabela camareira_bonus
INSERT INTO camareira_bonus(id_camareira, ano, mes, valor_bonus)
VALUES (20, 2020, 10, 2300);
       
--Mostrar todos os valores da camareira bonus     
SELECT * FROM camareira_bonus;