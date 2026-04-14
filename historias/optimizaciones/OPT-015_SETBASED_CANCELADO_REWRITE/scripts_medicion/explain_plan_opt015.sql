-- ============================================================================
-- OPT-015: Explain Plans para validar rewrite set-based + NOT EXISTS inline
-- Ejecutar en: JOOGANDO@ADMQA1_19C (DESARROLLO)
-- Fecha: 2026-04-13
--
-- INSTRUCCIONES:
-- 1. Abrir en Toad, conectado a JOOGANDO@ADMQA1_19C
-- 2. Ejecutar cada query con Explain Plan (Ctrl+E en Toad)
-- 3. Anotar el Cost de cada Q1-Q12
-- 4. NO ejecutar los queries realmente (solo Explain Plan)
-- 5. Copiar los resultados al final de este archivo
--
-- PREREQUISITOS (ejecutar A.0.2 y A.0.3 primero):
-- A.0.2: Verificar que IDX_GARANTIAS_TIPO_SB existe
-- A.0.3: Verificar valores de LOTE y COD_EMPRESA
-- ============================================================================


-- ============================================================================
-- A.0.2 - Verificar indice IDX_GARANTIAS_TIPO_SB
-- ============================================================================
SELECT INDEX_NAME, STATUS, TABLESPACE_NAME
FROM ALL_INDEXES
WHERE OWNER = 'PR' AND INDEX_NAME = 'IDX_GARANTIAS_TIPO_SB';
-- Esperado: 1 fila, STATUS = VALID
-- Si no existe, crearlo:
-- CREATE INDEX PR.IDX_GARANTIAS_TIPO_SB
-- ON PR.PR_GARANTIAS (CODIGO_EMPRESA, NUMERO_GARANTIA, CODIGO_TIPO_GARANTIA_SB)
-- TABLESPACE PR_DAT;


-- ============================================================================
-- A.0.3 - Verificar parametros LOTE y COD_EMPRESA
-- ============================================================================
-- Valor de LOTE:
SELECT COD_PARAMETRO, VALOR
FROM PA.PA_PARAMETROS_MVP
WHERE COD_EMPRESA = '1' AND COD_SISTEMA = 'PR'
  AND COD_PARAMETRO = 'LOTE_DE_CARAGA_REPRESTAMO';

-- Valor de f_obt_Empresa_Represtamo:
SELECT PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo FROM DUAL;


-- ============================================================================
-- Q1 - CURSOR Cancelado (DESPUES): NOT EXISTS inline, sin PEP/NEGRA
-- Compara con: cursor original (L.383-484 body.sql) que usa F_TIENE_GARANTIA
-- ============================================================================
-- Ctrl+E para Explain Plan (NO ejecutar)
SELECT a.codigo_empresa,
       a.codigo_cliente,
       a.NO_CREDITO
FROM PR_CREDITOS a,
     PR_tipo_credito_REPRESTAMO c
WHERE ROWNUM <= 5  -- LOTE_DE_CARAGA_REPRESTAMO = 5 (verificado A.0.3)
  AND a.tipo_credito = c.tipo_credito
  AND (EXISTS (SELECT 1
       FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('PERIODOS_CUOTA')) subq
       WHERE a.CODIGO_PERIODO_CUOTA = subq.COLUMN_VALUE)
       OR NOT EXISTS (SELECT 1 FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('PERIODOS_CUOTA')) subq))
  AND A.F_CANCELACION = (SELECT d.F_CANCELACION
                         FROM PR_CREDITOS d
                         WHERE d.F_CANCELACION >= SYSDATE - 365
                           AND d.F_CANCELACION <= SYSDATE
                           AND d.NO_CREDITO = a.NO_CREDITO
                           AND d.ESTADO = 'C')
  AND c.CARGA = 'S'
  AND a.codigo_empresa = 1
  AND NOT EXISTS (SELECT 1
                  FROM PR_CREDITOS C
                  WHERE C.CODIGO_EMPRESA = a.CODIGO_EMPRESA
                    AND C.NO_CREDITO != a.NO_CREDITO
                    AND C.CODIGO_CLIENTE = a.CODIGO_CLIENTE
                    AND C.F_PRIMER_DESEMBOLSO > ADD_MONTHS(SYSDATE, -9)
                    AND C.ESTADO IN (SELECT COLUMN_VALUE FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('ESTADOS_CREDITOS'))))
  AND NOT EXISTS (SELECT 1
                  FROM PR_CREDITOS C
                  WHERE C.CODIGO_EMPRESA = a.CODIGO_EMPRESA
                    AND C.NO_CREDITO != a.NO_CREDITO
                    AND C.CODIGO_CLIENTE = a.CODIGO_CLIENTE
                    AND C.ESTADO = 'E')
  AND EXISTS (SELECT 1
              FROM PERSONAS p
              WHERE p.COD_PERSONA = CAST(a.codigo_cliente AS VARCHAR2(15))
                AND p.ES_FISICA = 'S')
  AND EXISTS (SELECT 1
              FROM ID_PERSONAS ip
              WHERE ip.COD_PERSONA = CAST(a.codigo_cliente AS VARCHAR2(15))
                AND ip.COD_PAIS IN (SELECT COLUMN_VALUE FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('NACIONALIDAD')))
                AND ip.COD_TIPO_ID IN (SELECT COLUMN_VALUE FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('TIPO_DOCUMENTO'))))
  AND NOT EXISTS (SELECT 1
                  FROM pr_represtamos
                  WHERE codigo_empresa = a.codigo_empresa
                    AND no_credito = a.NO_CREDITO
                    AND estado IN (SELECT COLUMN_VALUE FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('ESTADOS_NO_REPROCESO'))))
  AND NOT EXISTS (SELECT 1
                  FROM PR_CREDITOS a1,
                       PR_AVAL_REPRE_X_CREDITO b
                  WHERE a1.codigo_empresa = 1
                    AND a1.no_credito = a.no_credito
                    AND b.codigo_empresa = a1.codigo_empresa
                    AND b.no_credito = a1.no_credito
                    AND b.codigo_aval_repre != a1.codigo_cliente)
  -- NOT EXISTS inline (reemplaza F_TIENE_GARANTIA)
  AND NOT EXISTS (
      SELECT 1
      FROM PR_CREDITOS cr
      JOIN PR_GARANTIAS_X_CREDITO gx ON gx.CODIGO_EMPRESA = cr.CODIGO_EMPRESA
                                     AND gx.NO_CREDITO = cr.NO_CREDITO
      JOIN PR_GARANTIAS g ON g.CODIGO_EMPRESA = gx.CODIGO_EMPRESA
                          AND g.NUMERO_GARANTIA = gx.NUMERO_GARANTIA
      WHERE cr.CODIGO_EMPRESA = 1
        AND cr.NO_CREDITO = a.NO_CREDITO
        AND cr.ESTADO IN ('D','V','M','E','J')
        AND g.CODIGO_TIPO_GARANTIA_SB != 'NA'
  );
  -- PEP y NEGRA ELIMINADOS del cursor (se mueven a DELETE post-INSERT)
-- Anotar cost: Q1 = ______


-- ============================================================================
-- Q2 - CURSOR Cancelado_hi (DESPUES): NOT EXISTS inline con PR_CREDITOS_HI
-- Compara con: cursor original (L.767-865 body.sql) que usa F_TIENE_GARANTIA_HISTORICO
-- ============================================================================
SELECT a.codigo_empresa,
       a.codigo_cliente,
       a.NO_CREDITO
FROM PR_CREDITOS_HI a,
     PR_tipo_credito_REPRESTAMO c
WHERE ROWNUM <= 5  -- LOTE_DE_CARAGA_REPRESTAMO = 5 (verificado A.0.3)
  AND a.tipo_credito = c.tipo_credito
  AND (EXISTS (SELECT 1
       FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('PERIODOS_CUOTA')) subq
       WHERE a.CODIGO_PERIODO_CUOTA = subq.COLUMN_VALUE)
       OR NOT EXISTS (SELECT 1 FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('PERIODOS_CUOTA')) subq))
  AND A.F_CANCELACION = (SELECT d.F_CANCELACION
                         FROM PR_CREDITOS_HI d
                         WHERE d.F_CANCELACION >= SYSDATE - 365
                           AND d.F_CANCELACION <= SYSDATE
                           AND d.NO_CREDITO = a.NO_CREDITO
                           AND d.ESTADO = 'C')
  AND c.CARGA = 'S'
  AND a.codigo_empresa = 1
  AND NOT EXISTS (SELECT 1
                  FROM PR_CREDITOS C
                  WHERE C.CODIGO_EMPRESA = a.CODIGO_EMPRESA
                    AND C.NO_CREDITO != a.NO_CREDITO
                    AND C.CODIGO_CLIENTE = a.CODIGO_CLIENTE
                    AND C.F_PRIMER_DESEMBOLSO > ADD_MONTHS(SYSDATE, -9)
                    AND C.ESTADO IN (SELECT COLUMN_VALUE FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('ESTADOS_CREDITOS'))))
  AND NOT EXISTS (SELECT 1
                  FROM PR_CREDITOS C
                  WHERE C.CODIGO_EMPRESA = a.CODIGO_EMPRESA
                    AND C.NO_CREDITO != a.NO_CREDITO
                    AND C.CODIGO_CLIENTE = a.CODIGO_CLIENTE
                    AND C.ESTADO = 'E')
  AND EXISTS (SELECT 1
              FROM PERSONAS p
              WHERE p.COD_PERSONA = CAST(a.codigo_cliente AS VARCHAR2(15))
                AND p.ES_FISICA = 'S')
  AND EXISTS (SELECT 1
              FROM ID_PERSONAS ip
              WHERE ip.COD_PERSONA = CAST(a.codigo_cliente AS VARCHAR2(15))
                AND ip.COD_PAIS IN (SELECT COLUMN_VALUE FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('NACIONALIDAD')))
                AND ip.COD_TIPO_ID IN (SELECT COLUMN_VALUE FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('TIPO_DOCUMENTO'))))
  AND NOT EXISTS (SELECT 1
                  FROM pr_represtamos
                  WHERE codigo_empresa = a.codigo_empresa
                    AND no_credito = a.NO_CREDITO
                    AND estado IN (SELECT COLUMN_VALUE FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('ESTADOS_NO_REPROCESO'))))
  AND NOT EXISTS (SELECT 1
                  FROM PR_CREDITOS_HI a1,
                       PR_AVAL_REPRE_X_CREDITO b
                  WHERE a1.codigo_empresa = 1
                    AND a1.no_credito = a.no_credito
                    AND b.codigo_empresa = a1.codigo_empresa
                    AND b.no_credito = a1.no_credito
                    AND b.codigo_aval_repre != a1.codigo_cliente)
  -- NOT EXISTS inline (reemplaza F_TIENE_GARANTIA_HISTORICO)
  AND NOT EXISTS (
      SELECT 1
      FROM PR_CREDITOS_HI cr
      JOIN PR_GARANTIAS_X_CREDITO gx ON gx.CODIGO_EMPRESA = cr.CODIGO_EMPRESA
                                     AND gx.NO_CREDITO = cr.NO_CREDITO
      JOIN PR_GARANTIAS g ON g.CODIGO_EMPRESA = gx.CODIGO_EMPRESA
                          AND g.NUMERO_GARANTIA = gx.NUMERO_GARANTIA
      WHERE cr.CODIGO_EMPRESA = 1
        AND cr.NO_CREDITO = a.NO_CREDITO
        AND cr.ESTADO IN ('D','V','M','E','J')
        AND g.CODIGO_TIPO_GARANTIA_SB != 'NA'
  );
-- Anotar cost: Q2 = ______


-- ============================================================================
-- Q3 - UPDATE DIAS_ATRASO set-based (DESPUES)
-- Compara con: FORALL UPDATE original (L.613-630 / L.976-992)
-- ============================================================================
EXPLAIN PLAN FOR
UPDATE PR.PR_REPRESTAMOS y
SET Y.DIAS_ATRASO = (SELECT MAX(D.DIAS_ATRASO)
                     FROM PA.PA_DETALLADO_DE08 D
                     WHERE D.FUENTE = 'PR'
                       AND D.FECHA_CORTE >= ADD_MONTHS(y.FECHA_CORTE, -6)
                       AND D.NO_CREDITO = y.NO_CREDITO
                       AND D.CODIGO_CLIENTE = y.CODIGO_CLIENTE)
WHERE y.ESTADO = 'RE'
  AND y.ADICIONADO_POR = USER
  AND y.FECHA_ADICION >= TRUNC(SYSDATE);

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
-- Anotar cost: Q3 = ______


-- ============================================================================
-- Q4 - UPDATE MTO_CREDITO_ACTUAL set-based (DESPUES)
-- Compara con: FORALL UPDATE original (L.636-650 / L.998-1012)
-- ============================================================================
EXPLAIN PLAN FOR
UPDATE PR.PR_REPRESTAMOS R
SET R.MTO_CREDITO_ACTUAL = (SELECT D.monto_desembolsado
                            FROM PA.PA_DETALLADO_DE08 D
                            WHERE D.FUENTE = 'PR'
                              AND D.NO_CREDITO = R.NO_CREDITO
                              AND D.CODIGO_CLIENTE = R.CODIGO_CLIENTE
                              AND D.FECHA_CORTE = (SELECT MAX(P.FECHA_CORTE)
                                                   FROM PA_DETALLADO_DE08 P
                                                   WHERE P.FUENTE = 'PR'
                                                     AND P.NO_CREDITO = R.NO_CREDITO
                                                     AND P.CODIGO_CLIENTE = R.CODIGO_CLIENTE))
WHERE R.ESTADO = 'RE'
  AND R.ADICIONADO_POR = USER
  AND R.FECHA_ADICION >= TRUNC(SYSDATE);

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
-- Anotar cost: Q4 = ______


-- ============================================================================
-- Q5 - UPDATE ESTADO X3 (TC atraso) set-based (DESPUES)
-- Compara con: FORALL UPDATE original (L.659-675 / L.1021-1037)
-- ============================================================================
EXPLAIN PLAN FOR
UPDATE PR.PR_REPRESTAMOS y
SET y.ESTADO = 'X3',
    Y.OBSERVACIONES = 'EL CLIENTE POSEE TARJETA DE CREDITO CON ATRASO MAYOR A 30 DIAS'
WHERE y.ESTADO = 'RE'
  AND y.ADICIONADO_POR = USER
  AND y.FECHA_ADICION >= TRUNC(SYSDATE)
  AND EXISTS (SELECT 1
              FROM PA_DETALLADO_DE08 D
              WHERE D.FUENTE = 'TC'
                AND D.FECHA_CORTE = y.FECHA_CORTE
                AND D.NO_CREDITO != y.NO_CREDITO
                AND D.CODIGO_CLIENTE = y.CODIGO_CLIENTE
                AND D.CODIGO_EMPRESA = y.CODIGO_EMPRESA
                AND D.DIAS_ATRASO >= 30);

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
-- Anotar cost: Q5 = ______


-- ============================================================================
-- Q6 - UPDATE ESTADO X1 (desembolso reciente) set-based (DESPUES)
-- Compara con: FORALL UPDATE original (L.682-697 / L.1048-1063)
-- ============================================================================
EXPLAIN PLAN FOR
UPDATE PR.PR_REPRESTAMOS y
SET y.ESTADO = 'X1',
    Y.OBSERVACIONES = 'EL CLIENTE TIENE OTRO PRESTAMO DESEMBOLSADO EN LOS ULTIMOS 6 MESES'
WHERE y.ESTADO = 'RE'
  AND y.ADICIONADO_POR = USER
  AND y.FECHA_ADICION >= TRUNC(SYSDATE)
  AND EXISTS (SELECT 1
              FROM PR_CREDITOS C
              WHERE C.CODIGO_EMPRESA = y.CODIGO_EMPRESA
                AND C.NO_CREDITO != y.NO_CREDITO
                AND C.CODIGO_CLIENTE = y.CODIGO_CLIENTE
                AND C.F_PRIMER_DESEMBOLSO > ADD_MONTHS(SYSDATE, -6)
                AND C.ESTADO IN (SELECT COLUMN_VALUE FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('ESTADOS_CREDITOS'))));

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
-- Anotar cost: Q6 = ______


-- ============================================================================
-- Q7 - DELETE PEP post-INSERT (NUEVO)
-- Reemplaza: F_Validar_Listas_PEP en el cursor
-- ============================================================================
EXPLAIN PLAN FOR
DELETE FROM PR_REPRESTAMOS
WHERE ESTADO = 'RE'
  AND ADICIONADO_POR = USER
  AND FECHA_ADICION >= TRUNC(SYSDATE)
  AND PR.PR_PKG_REPRESTAMOS.F_Validar_Listas_PEP(1, CODIGO_CLIENTE) = 1;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
-- Anotar cost: Q7 = ______
-- Nota: El cost NO incluira el costo de la funcion PL/SQL (ejecucion por fila).
-- Esto es aceptable: el volumen es pequeno (solo filas RE recien insertadas).


-- ============================================================================
-- Q8 - DELETE NEGRA post-INSERT (NUEVO)
-- Reemplaza: F_Validar_Lista_NEGRA en el cursor
-- ============================================================================
EXPLAIN PLAN FOR
DELETE FROM PR_REPRESTAMOS
WHERE ESTADO = 'RE'
  AND ADICIONADO_POR = USER
  AND FECHA_ADICION >= TRUNC(SYSDATE)
  AND PR.PR_PKG_REPRESTAMOS.F_Validar_Lista_NEGRA(1, CODIGO_CLIENTE) = 1;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
-- Anotar cost: Q8 = ______


-- ============================================================================
-- Q9 - ANTES: FORALL UPDATE DIAS_ATRASO (single-row, como lo hace el loop)
-- Para comparar con Q3
-- ============================================================================
EXPLAIN PLAN FOR
UPDATE PR.PR_REPRESTAMOS y
SET Y.DIAS_ATRASO = (SELECT MAX(D.DIAS_ATRASO)
                     FROM PA.PA_DETALLADO_DE08 D
                     WHERE D.FUENTE = 'PR'
                       AND D.FECHA_CORTE >= ADD_MONTHS(DATE '2024-09-27', -6)
                       AND D.NO_CREDITO = 1087363
                       AND D.CODIGO_CLIENTE = 1107470)
WHERE y.CODIGO_EMPRESA = 1
  AND y.CODIGO_CLIENTE = 1107470
  AND y.FECHA_CORTE = DATE '2024-09-27'
  AND y.NO_CREDITO = 1087363
  AND y.ESTADO = 'RE';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
-- Anotar cost: Q9 = ______
-- Este cost x N filas = costo real total del FORALL original


-- ============================================================================
-- Q10 - ANTES: FORALL UPDATE MTO_CREDITO_ACTUAL (single-row)
-- Para comparar con Q4
-- ============================================================================
EXPLAIN PLAN FOR
UPDATE PR.PR_REPRESTAMOS R
SET R.MTO_CREDITO_ACTUAL = (SELECT monto_desembolsado
                            FROM PA.PA_DETALLADO_DE08 D
                            WHERE D.FUENTE = 'PR'
                              AND D.NO_CREDITO = 1087363
                              AND D.CODIGO_CLIENTE = 1107470
                              AND D.FECHA_CORTE = (SELECT MAX(P.FECHA_CORTE)
                                                   FROM PA_DETALLADO_DE08 P
                                                   WHERE P.FUENTE = 'PR'
                                                     AND P.NO_CREDITO = 1087363
                                                     AND P.CODIGO_CLIENTE = 1107470))
WHERE R.CODIGO_EMPRESA = 1
  AND R.CODIGO_CLIENTE = 1107470
  AND R.NO_CREDITO = 1087363
  AND R.ESTADO = 'RE';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
-- Anotar cost: Q10 = ______


-- ============================================================================
-- Q11 - ANTES: FORALL UPDATE X3 TC atraso (single-row)
-- Para comparar con Q5
-- ============================================================================
EXPLAIN PLAN FOR
UPDATE PR.PR_REPRESTAMOS y
SET y.ESTADO = 'X3',
    Y.OBSERVACIONES = 'EL CLIENTE POSEE TARJETA DE CREDITO CON ATRASO MAYOR A 30 DIAS'
WHERE y.CODIGO_EMPRESA = 1
  AND y.CODIGO_CLIENTE = 1107470
  AND y.FECHA_CORTE = DATE '2024-09-27'
  AND y.NO_CREDITO = 1087363
  AND y.ESTADO = 'RE'
  AND 1 IN (SELECT 1
            FROM PA_DETALLADO_DE08 D
            WHERE D.FUENTE = 'TC'
              AND D.FECHA_CORTE = DATE '2024-09-27'
              AND D.NO_CREDITO != 1087363
              AND D.CODIGO_CLIENTE = 1107470
              AND D.CODIGO_EMPRESA = 1
              AND D.DIAS_ATRASO >= 30);

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
-- Anotar cost: Q11 = ______


-- ============================================================================
-- Q12 - ANTES: FORALL UPDATE X1 desembolso (single-row)
-- Para comparar con Q6
-- ============================================================================
EXPLAIN PLAN FOR
UPDATE PR.PR_REPRESTAMOS y
SET y.ESTADO = 'X1',
    Y.OBSERVACIONES = 'EL CLIENTE TIENE OTRO PRESTAMO DESEMBOLSADO EN LOS ULTIMOS 6 MESES'
WHERE y.CODIGO_EMPRESA = 1
  AND y.CODIGO_CLIENTE = 1107470
  AND y.FECHA_CORTE = DATE '2024-09-27'
  AND y.NO_CREDITO = 1087363
  AND y.ESTADO = 'RE'
  AND 1 = (SELECT DISTINCT 1
           FROM PR_CREDITOS C
           WHERE C.CODIGO_EMPRESA = 1
             AND C.NO_CREDITO != 1087363
             AND C.CODIGO_CLIENTE = 1107470
             AND C.F_PRIMER_DESEMBOLSO > ADD_MONTHS(SYSDATE, -6)
             AND C.ESTADO IN (SELECT COLUMN_VALUE FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('ESTADOS_CREDITOS'))));

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
-- Anotar cost: Q12 = ______


-- ============================================================================
-- TABLA DE RESULTADOS (llenar al ejecutar)
-- ============================================================================
/*
| Query | Descripcion                        | Cost  | Notas |
|-------|------------------------------------|-------|-------|
| Q1    | Cursor Cancelado (DESPUES)         |       |       |
| Q2    | Cursor Cancelado_hi (DESPUES)      |       |       |
| Q3    | UPDATE DIAS_ATRASO set-based       |       |       |
| Q4    | UPDATE MTO_CREDITO set-based       |       |       |
| Q5    | UPDATE X3 TC atraso set-based      |       |       |
| Q6    | UPDATE X1 desembolso set-based     |       |       |
| Q7    | DELETE PEP post-INSERT             |       |       |
| Q8    | DELETE NEGRA post-INSERT           |       |       |
| Q9    | ANTES: FORALL DIAS_ATRASO (x1)     |       | x N filas |
| Q10   | ANTES: FORALL MTO_CREDITO (x1)     |       | x N filas |
| Q11   | ANTES: FORALL X3 TC (x1)           |       | x N filas |
| Q12   | ANTES: FORALL X1 desembolso (x1)   |       | x N filas |
*/


-- ============================================================================
-- CRITERIOS DE APROBACION PARA PASAR A FASE B
-- ============================================================================
/*
1. Q1 y Q2 (cursores DESPUES):
   - Cost debe ser razonable (< 5,000).
   - El plan debe mostrar ANTI JOIN (HASH o NL) para el NOT EXISTS de garantias,
     NO un FILTER con subquery correlacionada.
   - Si IDX_GARANTIAS_TIPO_SB esta activo, debe aparecer INDEX RANGE SCAN en el plan.

2. Q3-Q6 (UPDATEs set-based DESPUES):
   - Cost total (Q3+Q4+Q5+Q6) debe ser menor que:
     Cost total ANTES = (Q9+Q10+Q11+Q12) x N filas (tipicamente 190).
   - Cada UPDATE set-based puede tener cost mayor que el single-row,
     pero se ejecuta 1 vez vs N veces.

3. Q7-Q8 (DELETEs PEP/NEGRA):
   - Cost bajo esperado (< 100) — operan sobre pocas filas RE.
   - No hay regresion: estas funciones se ejecutaban N veces en el cursor,
     ahora se ejecutan solo sobre filas ya insertadas.

4. Regla general:
   - Ningun query debe mostrar FULL TABLE SCAN en PA_DETALLADO_DE08
     (excepto Q3 si no hay indice en FECHA_CORTE — aceptable si cost < 1000).
   - Si algun query tiene cost > 10,000 o muestra plan inesperado,
     DETENERSE y analizar antes de pasar a Fase B.
*/
