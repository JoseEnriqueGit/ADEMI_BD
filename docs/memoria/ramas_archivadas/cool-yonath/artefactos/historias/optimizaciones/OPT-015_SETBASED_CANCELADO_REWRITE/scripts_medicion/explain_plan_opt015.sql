-- ================================================================
-- OPT-015 Explain Plans  --  FASE A
-- Validacion teorica antes de aplicar el rewrite al paquete.
--
-- Ejecutar en Toad conectado a JOOGANDO@ADMQA1 (DESARROLLO).
-- Recorre 3 pre-requisitos bloqueantes (A.0) + 12 Explain Plans (A.1).
-- Cada bloque marcado con "BLOCK" se ejecuta individualmente con F5.
--
-- Para ver el plan: despues de cada EXPLAIN PLAN, el SELECT de
-- DBMS_XPLAN.DISPLAY muestra el arbol. Guarda los 12 outputs para
-- contrastar con los criterios de aceptacion documentados en
-- C:\Users\ogand\.claude\plans\eager-dreaming-lamport.md (Fase A.2).
-- ================================================================



-- ================================================================
-- A.0  PRE-REQUISITOS BLOQUEANTES (ejecutar ANTES de los Explain Plans)
-- ================================================================

-- ----------------------------------------------------------------
-- BLOCK A.0.1  --  PEP / NEGRA son read-only?
-- Revisar el cuerpo de las 2 funciones en PA.P_DATOS_PERSONA.
-- Buscar "INSERT", "UPDATE", "DELETE" dentro de los cuerpos de
-- esta_en_lista_pep y esta_en_lista_negra.
-- Si NO hay DML dentro de sus cuerpos -> continuar con opcion A.
-- Si HAY DML -> mover PEP/NEGRA al DELETE altera auditoria; avisar.
-- ----------------------------------------------------------------
SELECT LINE, TEXT
  FROM DBA_SOURCE
 WHERE OWNER = 'PA'
   AND NAME = 'P_DATOS_PERSONA'
   AND TYPE = 'PACKAGE BODY'
 ORDER BY LINE;


-- ----------------------------------------------------------------
-- BLOCK A.0.2  --  Indice IDX_GARANTIAS_TIPO_SB existe?
-- Necesario para que Q1/Q7 (NOT EXISTS inline de F_TIENE_GARANTIA)
-- use HASH SEMI JOIN en vez de FULL SCAN sobre PR_GARANTIAS.
-- ----------------------------------------------------------------
SELECT OWNER, INDEX_NAME, STATUS, TABLE_NAME
  FROM DBA_INDEXES
 WHERE OWNER = 'PR'
   AND INDEX_NAME = 'IDX_GARANTIAS_TIPO_SB';

-- Si no existe, crear (descomentar):
-- CREATE INDEX PR.IDX_GARANTIAS_TIPO_SB
--   ON PR.PR_GARANTIAS (CODIGO_EMPRESA, NUMERO_GARANTIA, CODIGO_TIPO_GARANTIA_SB)
--   TABLESPACE PR_DAT;


-- ----------------------------------------------------------------
-- BLOCK A.0.3  --  LOTE_DE_CARAGA_REPRESTAMO y f_obt_Empresa_Represtamo
-- LOTE < 5000  -> OK.  LOTE >= 10000 -> pausar, discutir.
-- f_obt_Empresa_Represtamo DEBE ser 1 para que el rewrite preserve
-- semantica (el original usa literal 1 en varios predicados).
-- ----------------------------------------------------------------
SELECT PR.PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('LOTE_DE_CARAGA_REPRESTAMO') AS LOTE,
       PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo AS COD_EMPRESA
  FROM DUAL;



-- ================================================================
-- A.1  EXPLAIN PLANS  (12 queries)
--
-- Conjunto Q1..Q6 -> Precalifica_Repre_Cancelado (paso 5)
-- Conjunto Q7..Q12 -> Precalifica_Repre_Cancelado_hi (paso 6)
--
-- Los UPDATE/DELETE van contra PR_REPRESTAMOS en ambos procedures
-- -> Q8..Q12 son estructuralmente identicos a Q2..Q6. Si el tiempo
-- de review es escaso, basta con Q1..Q6 + Q7 para validar Fase A.
--
-- TODOS usan v_fecha_corte = 27/09/2024 (valor real observado en DESA).
-- ================================================================

-- Limpia plan table por si quedaron plans de sesiones previas
DELETE FROM PLAN_TABLE WHERE STATEMENT_ID LIKE 'OPT015_%';
COMMIT;


-- ----------------------------------------------------------------
-- Q1  --  INSERT ... SELECT de Precalifica_Repre_Cancelado
--         Reemplaza OPEN/FETCH/BULK COLLECT/FORALL INSERT del BULK LOOP (body L.598-605).
--         Incluye C1 (NOT EXISTS reemplaza F_TIENE_GARANTIA) y SIN PEP/NEGRA (D1, se movio a Q2).
-- ----------------------------------------------------------------
EXPLAIN PLAN SET STATEMENT_ID = 'OPT015_Q1' FOR
INSERT INTO PR.PR_REPRESTAMOS (
    CODIGO_EMPRESA, ID_REPRESTAMO, CODIGO_CLIENTE, FECHA_CORTE, NO_CREDITO,
    ESTADO, CODIGO_PRECALIFICACION, DIAS_ATRASO, FECHA_PROCESO, PIN,
    INTENTOS_PIN, INTENTOS_IDENTIFICACION, IND_SOLICITA_AYUDA,
    MTO_APROBADO, MTO_PREAPROBADO, OBSERVACIONES, ADICIONADO_POR, FECHA_ADICION,
    MODIFICADO_POR, FECHA_MODIFICACION, ESTADO_ORIGINAL, XCORE_GLOBAL, XCORE_CUSTOM,
    ID_CARGA_DIRIGIDA, ID_CAMPANA_ESPECIALES, ES_FIADOR
)
SELECT
    a.codigo_empresa,
    PR.PR_PKG_REPRESTAMOS.f_genera_secuencia,
    a.codigo_cliente,
    TO_DATE('27/09/2024', 'DD/MM/YYYY') AS FECHA_CORTE,
    a.NO_CREDITO,
    'RE' AS ESTADO,
    NULL AS CODIGO_PRECALIFICACION,
    0   AS DIAS_ATRASO,
    SYSDATE AS FECHA_PROCESO,
    0   AS PIN,
    PR.PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('MAX_INTENTOS_PIN'),
    PR.PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('MAX_INTENTOS_IDENTIFICACION'),
    'N' AS IND_SOLICITA_AYUDA,
    0   AS MTO_APROBADO,
    0   AS MTO_PREAPROBADO,
    NULL AS OBSERVACIONES,
    USER AS ADICIONADO_POR,
    SYSDATE AS FECHA_ADICION,
    NULL AS MODIFICADO_POR,
    NULL AS FECHA_MODIFICACION,
    NULL AS ESTADO_ORIGINAL,
    NULL AS XCORE_GLOBAL,
    NULL AS XCORE_CUSTOM,
    NULL AS ID_CARGA_DIRIGIDA,
    NULL AS ID_CAMPANA_ESPECIALES,
    'N'  AS ES_FIADOR
  FROM PR.PR_CREDITOS a,
       PR.PR_TIPO_CREDITO_REPRESTAMO c
 WHERE ROWNUM <= TO_NUMBER(PR.PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('LOTE_DE_CARAGA_REPRESTAMO'))
   AND a.tipo_credito = c.tipo_credito
   AND ( EXISTS (SELECT 1 FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('PERIODOS_CUOTA')) s
                  WHERE a.CODIGO_PERIODO_CUOTA = s.COLUMN_VALUE)
         OR NOT EXISTS (SELECT 1 FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('PERIODOS_CUOTA')) s) )
   AND a.F_CANCELACION = (
          SELECT d.F_CANCELACION
            FROM PR.PR_CREDITOS d
           WHERE d.F_CANCELACION >= SYSDATE - TO_NUMBER(PR.PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('DIAS_CANCELACION'))
             AND d.F_CANCELACION <= SYSDATE
             AND d.NO_CREDITO    = a.NO_CREDITO
             AND d.ESTADO        = 'C' )
   AND c.CARGA = 'S'
   AND a.codigo_empresa = PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
   AND NOT EXISTS (
          SELECT 1 FROM PR.PR_CREDITOS C
           WHERE C.CODIGO_EMPRESA     = a.CODIGO_EMPRESA
             AND C.NO_CREDITO        != a.NO_CREDITO
             AND C.CODIGO_CLIENTE     = a.CODIGO_CLIENTE
             AND C.F_PRIMER_DESEMBOLSO > ADD_MONTHS(SYSDATE, - PR.PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('MESES_MAX_X_DESEMBOLSO'))
             AND C.ESTADO IN (SELECT COLUMN_VALUE FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('ESTADOS_CREDITOS'))) )
   AND NOT EXISTS (
          SELECT 1 FROM PR.PR_CREDITOS C
           WHERE C.CODIGO_EMPRESA = a.CODIGO_EMPRESA
             AND C.NO_CREDITO    != a.NO_CREDITO
             AND C.CODIGO_CLIENTE = a.CODIGO_CLIENTE
             AND C.ESTADO         = 'E' )
   AND EXISTS (
          SELECT 1 FROM PA.PERSONAS p
           WHERE p.COD_PERSONA = CAST(a.codigo_cliente AS VARCHAR2(15))
             AND p.ES_FISICA    = PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('PERSONA_FISICA') )
   AND EXISTS (
          SELECT 1 FROM PA.ID_PERSONAS ip
           WHERE ip.COD_PERSONA = CAST(a.codigo_cliente AS VARCHAR2(15))
             AND ip.COD_PAIS    IN (SELECT COLUMN_VALUE FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('NACIONALIDAD')))
             AND ip.COD_TIPO_ID IN (SELECT COLUMN_VALUE FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('TIPO_DOCUMENTO'))) )
   AND NOT EXISTS (
          SELECT 1 FROM PR.PR_REPRESTAMOS pr
           WHERE pr.codigo_empresa = a.codigo_empresa
             AND pr.no_credito    = a.NO_CREDITO
             AND pr.estado IN (SELECT COLUMN_VALUE FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('ESTADOS_NO_REPROCESO'))) )
   AND NOT EXISTS (
          SELECT 1 FROM PR.PR_CREDITOS a1, PR.PR_AVAL_REPRE_X_CREDITO b
           WHERE a1.codigo_empresa = 1
             AND a1.no_credito    = a.no_credito
             AND b.codigo_empresa = a1.codigo_empresa
             AND b.no_credito     = a1.no_credito
             AND b.codigo_aval_repre != a1.codigo_cliente
             AND PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('CLIENTES_A_SOLA_FIRMA') = 'S' )
   -- OPT-015 C1: NOT EXISTS inline reemplaza F_TIENE_GARANTIA(a.no_credito) = 0
   --             Preserva semantica EXACTA del original:
   --             incluye PR_CREDITOS con filtro estado IN ('D','V','M','E','J').
   AND NOT EXISTS (
          SELECT 1
            FROM PR.PR_CREDITOS cr
            JOIN PR.PR_GARANTIAS_X_CREDITO gxc
              ON gxc.codigo_empresa = cr.codigo_empresa
             AND gxc.no_credito    = cr.no_credito
            JOIN PR.PR_GARANTIAS g
              ON g.codigo_empresa  = gxc.codigo_empresa
             AND g.numero_garantia = gxc.numero_garantia
           WHERE cr.codigo_empresa = PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
             AND cr.no_credito    = a.no_credito
             AND cr.estado         IN ('D','V','M','E','J')
             AND g.codigo_tipo_garantia_sb != 'NA' );

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'OPT015_Q1', 'ALL'));


-- ----------------------------------------------------------------
-- Q2  --  DELETE PEP / NEGRA post-INSERT (D1)
--         Reemplaza los 2 AND "F_Validar_Listas_PEP/NEGRA = 0" que estaban en el WHERE del cursor.
--         Evalua las 2 funciones solo sobre filas sobrevivientes, no sobre TODOS los candidatos.
-- ----------------------------------------------------------------
EXPLAIN PLAN SET STATEMENT_ID = 'OPT015_Q2' FOR
DELETE FROM PR.PR_REPRESTAMOS r
 WHERE r.CODIGO_EMPRESA = PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
   AND r.FECHA_CORTE    = TO_DATE('27/09/2024', 'DD/MM/YYYY')
   AND r.ESTADO         = 'RE'
   AND (    PR.PR_PKG_REPRESTAMOS.F_Validar_Listas_PEP(1, r.codigo_cliente)  = 1
         OR PR.PR_PKG_REPRESTAMOS.F_Validar_Lista_NEGRA(1, r.codigo_cliente) = 1 );

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'OPT015_Q2', 'ALL'));


-- ----------------------------------------------------------------
-- Q3  --  UPDATE DIAS_ATRASO set-based
--         Reemplaza FORALL x del BULK LOOP (body L.613-630).
--         FILTROS DEFENSIVOS: ADICIONADO_POR=USER + FECHA_ADICION >= TRUNC(SYSDATE)
--         garantizan que solo se actualizan filas insertadas por esta corrida
--         (preservando el aislamiento por batch que ten\u00eda el FORALL original).
-- ----------------------------------------------------------------
EXPLAIN PLAN SET STATEMENT_ID = 'OPT015_Q3' FOR
UPDATE PR.PR_REPRESTAMOS y
   SET y.DIAS_ATRASO = (
          SELECT MAX(D.DIAS_ATRASO)
            FROM PA.PA_DETALLADO_DE08 D
           WHERE D.FUENTE         = 'PR'
             AND D.FECHA_CORTE   >= ADD_MONTHS(y.FECHA_CORTE, -6)
             AND D.NO_CREDITO    = y.NO_CREDITO
             AND D.CODIGO_CLIENTE = y.CODIGO_CLIENTE )
 WHERE y.CODIGO_EMPRESA = PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
   AND y.FECHA_CORTE    = TO_DATE('27/09/2024', 'DD/MM/YYYY')
   AND y.ESTADO         = 'RE'
   AND y.ADICIONADO_POR = USER
   AND y.FECHA_ADICION >= TRUNC(SYSDATE);

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'OPT015_Q3', 'ALL'));


-- ----------------------------------------------------------------
-- Q4  --  UPDATE MTO_CREDITO_ACTUAL set-based (patron OPT-004)
--         Reemplaza FORALL y del BULK LOOP (body L.636-650).
--         FILTROS DEFENSIVOS: ADICIONADO_POR=USER + FECHA_ADICION >= TRUNC(SYSDATE).
-- ----------------------------------------------------------------
EXPLAIN PLAN SET STATEMENT_ID = 'OPT015_Q4' FOR
UPDATE PR.PR_REPRESTAMOS R
   SET R.MTO_CREDITO_ACTUAL = (
          SELECT D.monto_desembolsado
            FROM PA.PA_DETALLADO_DE08 D
           WHERE D.FUENTE         = 'PR'
             AND D.NO_CREDITO    = R.NO_CREDITO
             AND D.CODIGO_CLIENTE = R.CODIGO_CLIENTE
             AND D.FECHA_CORTE   = (
                    SELECT MAX(P.FECHA_CORTE)
                      FROM PA.PA_DETALLADO_DE08 P
                     WHERE P.FUENTE         = 'PR'
                       AND P.NO_CREDITO    = R.NO_CREDITO
                       AND P.CODIGO_CLIENTE = R.CODIGO_CLIENTE ) )
 WHERE R.CODIGO_EMPRESA = PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
   AND R.ESTADO         = 'RE'
   AND R.FECHA_CORTE    = TO_DATE('27/09/2024', 'DD/MM/YYYY')
   AND R.ADICIONADO_POR = USER
   AND R.FECHA_ADICION >= TRUNC(SYSDATE);

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'OPT015_Q4', 'ALL'));


-- ----------------------------------------------------------------
-- Q5  --  UPDATE ESTADO='X3' con EXISTS
--         Reemplaza FORALL x del BULK LOOP (body L.659-675).
--         Elimina antipatron "1 IN (SELECT 1 ...)".
--         FILTROS DEFENSIVOS: ADICIONADO_POR=USER + FECHA_ADICION >= TRUNC(SYSDATE).
-- ----------------------------------------------------------------
EXPLAIN PLAN SET STATEMENT_ID = 'OPT015_Q5' FOR
UPDATE PR.PR_REPRESTAMOS y
   SET y.ESTADO        = 'X3',
       y.OBSERVACIONES = 'EL CLIENTE POSEE TARJETA DE CREDITO CON ATRASO MAYOR A 30 DIAS'
 WHERE y.ESTADO        = 'RE'
   AND y.FECHA_CORTE   = TO_DATE('27/09/2024', 'DD/MM/YYYY')
   AND y.ADICIONADO_POR = USER
   AND y.FECHA_ADICION >= TRUNC(SYSDATE)
   AND EXISTS (
          SELECT 1
            FROM PA.PA_DETALLADO_DE08 D
           WHERE D.FUENTE         = 'TC'
             AND D.FECHA_CORTE   = y.FECHA_CORTE
             AND D.NO_CREDITO    != y.NO_CREDITO
             AND D.CODIGO_CLIENTE = y.CODIGO_CLIENTE
             AND D.CODIGO_EMPRESA = y.CODIGO_EMPRESA
             AND D.DIAS_ATRASO   >= 30 );

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'OPT015_Q5', 'ALL'));


-- ----------------------------------------------------------------
-- Q6  --  UPDATE ESTADO='X1' con EXISTS
--         Reemplaza FORALL x del BULK LOOP (body L.682-697).
--         Elimina antipatron "1 = (SELECT DISTINCT 1 ...)".
--         FILTROS DEFENSIVOS: ADICIONADO_POR=USER + FECHA_ADICION >= TRUNC(SYSDATE).
-- ----------------------------------------------------------------
EXPLAIN PLAN SET STATEMENT_ID = 'OPT015_Q6' FOR
UPDATE PR.PR_REPRESTAMOS y
   SET y.ESTADO        = 'X1',
       y.OBSERVACIONES = 'EL CLIENTE TIENE OTRO PRESTAMO DESEMBOLSADO EN LOS ULTIMOS '
                         || PA.OBT_PARAMETROS('1','PR','PRECAL_DESEMBOLSO_PR') || ' MESES'
 WHERE y.ESTADO        = 'RE'
   AND y.FECHA_CORTE   = TO_DATE('27/09/2024', 'DD/MM/YYYY')
   AND y.ADICIONADO_POR = USER
   AND y.FECHA_ADICION >= TRUNC(SYSDATE)
   AND EXISTS (
          SELECT 1
            FROM PR.PR_CREDITOS C
           WHERE C.CODIGO_EMPRESA     = y.CODIGO_EMPRESA
             AND C.NO_CREDITO        != y.NO_CREDITO
             AND C.CODIGO_CLIENTE     = y.CODIGO_CLIENTE
             AND C.F_PRIMER_DESEMBOLSO > ADD_MONTHS(SYSDATE, - PA.OBT_PARAMETROS('1','PR','PRECAL_DESEMBOLSO_PR'))
             AND C.ESTADO IN (SELECT COLUMN_VALUE FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('ESTADOS_CREDITOS'))) );

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'OPT015_Q6', 'ALL'));


-- ----------------------------------------------------------------
-- Q7  --  INSERT ... SELECT de Precalifica_Repre_Cancelado_hi
--         Identico a Q1 pero lee de PR_CREDITOS_HI (no PR_CREDITOS).
--         El subquery F_CANCELACION tambien usa PR_CREDITOS_HI.
-- ----------------------------------------------------------------
EXPLAIN PLAN SET STATEMENT_ID = 'OPT015_Q7' FOR
INSERT INTO PR.PR_REPRESTAMOS (
    CODIGO_EMPRESA, ID_REPRESTAMO, CODIGO_CLIENTE, FECHA_CORTE, NO_CREDITO,
    ESTADO, CODIGO_PRECALIFICACION, DIAS_ATRASO, FECHA_PROCESO, PIN,
    INTENTOS_PIN, INTENTOS_IDENTIFICACION, IND_SOLICITA_AYUDA,
    MTO_APROBADO, MTO_PREAPROBADO, OBSERVACIONES, ADICIONADO_POR, FECHA_ADICION,
    MODIFICADO_POR, FECHA_MODIFICACION, ESTADO_ORIGINAL, XCORE_GLOBAL, XCORE_CUSTOM,
    ID_CARGA_DIRIGIDA, ID_CAMPANA_ESPECIALES, ES_FIADOR
)
SELECT
    a.codigo_empresa,
    PR.PR_PKG_REPRESTAMOS.f_genera_secuencia,
    a.codigo_cliente,
    TO_DATE('27/09/2024', 'DD/MM/YYYY') AS FECHA_CORTE,
    a.NO_CREDITO,
    'RE' AS ESTADO,
    NULL AS CODIGO_PRECALIFICACION,
    0   AS DIAS_ATRASO,
    SYSDATE AS FECHA_PROCESO,
    0   AS PIN,
    PR.PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('MAX_INTENTOS_PIN'),
    PR.PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('MAX_INTENTOS_IDENTIFICACION'),
    'N' AS IND_SOLICITA_AYUDA,
    0   AS MTO_APROBADO,
    0   AS MTO_PREAPROBADO,
    NULL AS OBSERVACIONES,
    USER AS ADICIONADO_POR,
    SYSDATE AS FECHA_ADICION,
    NULL AS MODIFICADO_POR,
    NULL AS FECHA_MODIFICACION,
    NULL AS ESTADO_ORIGINAL,
    NULL AS XCORE_GLOBAL,
    NULL AS XCORE_CUSTOM,
    NULL AS ID_CARGA_DIRIGIDA,
    NULL AS ID_CAMPANA_ESPECIALES,
    'N'  AS ES_FIADOR
  FROM PR.PR_CREDITOS_HI a,
       PR.PR_TIPO_CREDITO_REPRESTAMO c
 WHERE ROWNUM <= TO_NUMBER(PR.PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('LOTE_DE_CARAGA_REPRESTAMO'))
   AND a.tipo_credito = c.tipo_credito
   AND ( EXISTS (SELECT 1 FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('PERIODOS_CUOTA')) s
                  WHERE a.CODIGO_PERIODO_CUOTA = s.COLUMN_VALUE)
         OR NOT EXISTS (SELECT 1 FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('PERIODOS_CUOTA')) s) )
   AND a.F_CANCELACION = (
          SELECT d.F_CANCELACION
            FROM PR.PR_CREDITOS_HI d
           WHERE d.F_CANCELACION >= SYSDATE - TO_NUMBER(PR.PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('DIAS_CANCELACION'))
             AND d.F_CANCELACION <= SYSDATE
             AND d.NO_CREDITO    = a.NO_CREDITO
             AND d.ESTADO        = 'C' )
   AND c.CARGA = 'S'
   AND a.codigo_empresa = PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
   AND NOT EXISTS (
          SELECT 1 FROM PR.PR_CREDITOS C
           WHERE C.CODIGO_EMPRESA     = a.CODIGO_EMPRESA
             AND C.NO_CREDITO        != a.NO_CREDITO
             AND C.CODIGO_CLIENTE     = a.CODIGO_CLIENTE
             AND C.F_PRIMER_DESEMBOLSO > ADD_MONTHS(SYSDATE, - PR.PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('MESES_MAX_X_DESEMBOLSO'))
             AND C.ESTADO IN (SELECT COLUMN_VALUE FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('ESTADOS_CREDITOS'))) )
   AND NOT EXISTS (
          SELECT 1 FROM PR.PR_CREDITOS C
           WHERE C.CODIGO_EMPRESA = a.CODIGO_EMPRESA
             AND C.NO_CREDITO    != a.NO_CREDITO
             AND C.CODIGO_CLIENTE = a.CODIGO_CLIENTE
             AND C.ESTADO         = 'E' )
   AND EXISTS (
          SELECT 1 FROM PA.PERSONAS p
           WHERE p.COD_PERSONA = CAST(a.codigo_cliente AS VARCHAR2(15))
             AND p.ES_FISICA    = PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('PERSONA_FISICA') )
   AND EXISTS (
          SELECT 1 FROM PA.ID_PERSONAS ip
           WHERE ip.COD_PERSONA = CAST(a.codigo_cliente AS VARCHAR2(15))
             AND ip.COD_PAIS    IN (SELECT COLUMN_VALUE FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('NACIONALIDAD')))
             AND ip.COD_TIPO_ID IN (SELECT COLUMN_VALUE FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('TIPO_DOCUMENTO'))) )
   AND NOT EXISTS (
          SELECT 1 FROM PR.PR_REPRESTAMOS pr
           WHERE pr.codigo_empresa = a.codigo_empresa
             AND pr.no_credito    = a.NO_CREDITO
             AND pr.estado IN (SELECT COLUMN_VALUE FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('ESTADOS_NO_REPROCESO'))) )
   AND NOT EXISTS (
          SELECT 1 FROM PR.PR_CREDITOS_HI a1, PR.PR_AVAL_REPRE_X_CREDITO b
           WHERE a1.codigo_empresa = 1
             AND a1.no_credito    = a.no_credito
             AND b.codigo_empresa = a1.codigo_empresa
             AND b.no_credito     = a1.no_credito
             AND b.codigo_aval_repre != a1.codigo_cliente
             AND PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('CLIENTES_A_SOLA_FIRMA') = 'S' )
   -- OPT-015 H1: NOT EXISTS inline reemplaza F_TIENE_GARANTIA_HISTORICO(a.no_credito) = 0
   --             Preserva semantica EXACTA del original:
   --             usa PR_CREDITOS_HI (no PR_CREDITOS) + filtro estado IN ('D','V','M','E','J').
   AND NOT EXISTS (
          SELECT 1
            FROM PR.PR_CREDITOS_HI cr       -- ← _HI porque F_TIENE_GARANTIA_HISTORICO lee aqui
            JOIN PR.PR_GARANTIAS_X_CREDITO gxc
              ON gxc.codigo_empresa = cr.codigo_empresa
             AND gxc.no_credito    = cr.no_credito
            JOIN PR.PR_GARANTIAS g
              ON g.codigo_empresa  = gxc.codigo_empresa
             AND g.numero_garantia = gxc.numero_garantia
           WHERE cr.codigo_empresa = PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
             AND cr.no_credito    = a.no_credito
             AND cr.estado         IN ('D','V','M','E','J')
             AND g.codigo_tipo_garantia_sb != 'NA' );

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'OPT015_Q7', 'ALL'));


-- ----------------------------------------------------------------
-- Q8..Q12  --  DELETE PEP/NEGRA + 4 UPDATEs de _hi
--
-- Son textualmente identicos a Q2..Q6 (los UPDATE/DELETE operan
-- sobre PR_REPRESTAMOS, que es la misma tabla destino en ambos
-- procedures). Para rigor documental se repiten con distinto
-- STATEMENT_ID.
-- ----------------------------------------------------------------

EXPLAIN PLAN SET STATEMENT_ID = 'OPT015_Q8' FOR
DELETE FROM PR.PR_REPRESTAMOS r
 WHERE r.CODIGO_EMPRESA = PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
   AND r.FECHA_CORTE    = TO_DATE('27/09/2024', 'DD/MM/YYYY')
   AND r.ESTADO         = 'RE'
   AND (    PR.PR_PKG_REPRESTAMOS.F_Validar_Listas_PEP(1, r.codigo_cliente)  = 1
         OR PR.PR_PKG_REPRESTAMOS.F_Validar_Lista_NEGRA(1, r.codigo_cliente) = 1 );

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'OPT015_Q8', 'ALL'));


EXPLAIN PLAN SET STATEMENT_ID = 'OPT015_Q9' FOR
UPDATE PR.PR_REPRESTAMOS y
   SET y.DIAS_ATRASO = (
          SELECT MAX(D.DIAS_ATRASO)
            FROM PA.PA_DETALLADO_DE08 D
           WHERE D.FUENTE         = 'PR'
             AND D.FECHA_CORTE   >= ADD_MONTHS(y.FECHA_CORTE, -6)
             AND D.NO_CREDITO    = y.NO_CREDITO
             AND D.CODIGO_CLIENTE = y.CODIGO_CLIENTE )
 WHERE y.CODIGO_EMPRESA = PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
   AND y.FECHA_CORTE    = TO_DATE('27/09/2024', 'DD/MM/YYYY')
   AND y.ESTADO         = 'RE'
   AND y.ADICIONADO_POR = USER
   AND y.FECHA_ADICION >= TRUNC(SYSDATE);

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'OPT015_Q9', 'ALL'));


EXPLAIN PLAN SET STATEMENT_ID = 'OPT015_Q10' FOR
UPDATE PR.PR_REPRESTAMOS R
   SET R.MTO_CREDITO_ACTUAL = (
          SELECT D.monto_desembolsado
            FROM PA.PA_DETALLADO_DE08 D
           WHERE D.FUENTE         = 'PR'
             AND D.NO_CREDITO    = R.NO_CREDITO
             AND D.CODIGO_CLIENTE = R.CODIGO_CLIENTE
             AND D.FECHA_CORTE   = (
                    SELECT MAX(P.FECHA_CORTE)
                      FROM PA.PA_DETALLADO_DE08 P
                     WHERE P.FUENTE         = 'PR'
                       AND P.NO_CREDITO    = R.NO_CREDITO
                       AND P.CODIGO_CLIENTE = R.CODIGO_CLIENTE ) )
 WHERE R.CODIGO_EMPRESA = PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
   AND R.ESTADO         = 'RE'
   AND R.FECHA_CORTE    = TO_DATE('27/09/2024', 'DD/MM/YYYY')
   AND R.ADICIONADO_POR = USER
   AND R.FECHA_ADICION >= TRUNC(SYSDATE);

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'OPT015_Q10', 'ALL'));


EXPLAIN PLAN SET STATEMENT_ID = 'OPT015_Q11' FOR
UPDATE PR.PR_REPRESTAMOS y
   SET y.ESTADO        = 'X3',
       y.OBSERVACIONES = 'EL CLIENTE POSEE TARJETA DE CREDITO CON ATRASO MAYOR A 30 DIAS'
 WHERE y.ESTADO        = 'RE'
   AND y.FECHA_CORTE   = TO_DATE('27/09/2024', 'DD/MM/YYYY')
   AND y.ADICIONADO_POR = USER
   AND y.FECHA_ADICION >= TRUNC(SYSDATE)
   AND EXISTS (
          SELECT 1
            FROM PA.PA_DETALLADO_DE08 D
           WHERE D.FUENTE         = 'TC'
             AND D.FECHA_CORTE   = y.FECHA_CORTE
             AND D.NO_CREDITO    != y.NO_CREDITO
             AND D.CODIGO_CLIENTE = y.CODIGO_CLIENTE
             AND D.CODIGO_EMPRESA = y.CODIGO_EMPRESA
             AND D.DIAS_ATRASO   >= 30 );

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'OPT015_Q11', 'ALL'));


EXPLAIN PLAN SET STATEMENT_ID = 'OPT015_Q12' FOR
UPDATE PR.PR_REPRESTAMOS y
   SET y.ESTADO        = 'X1',
       y.OBSERVACIONES = 'EL CLIENTE TIENE OTRO PRESTAMO DESEMBOLSADO EN LOS ULTIMOS '
                         || PA.OBT_PARAMETROS('1','PR','PRECAL_DESEMBOLSO_PR') || ' MESES'
 WHERE y.ESTADO        = 'RE'
   AND y.FECHA_CORTE   = TO_DATE('27/09/2024', 'DD/MM/YYYY')
   AND y.ADICIONADO_POR = USER
   AND y.FECHA_ADICION >= TRUNC(SYSDATE)
   AND EXISTS (
          SELECT 1
            FROM PR.PR_CREDITOS C
           WHERE C.CODIGO_EMPRESA     = y.CODIGO_EMPRESA
             AND C.NO_CREDITO        != y.NO_CREDITO
             AND C.CODIGO_CLIENTE     = y.CODIGO_CLIENTE
             AND C.F_PRIMER_DESEMBOLSO > ADD_MONTHS(SYSDATE, - PA.OBT_PARAMETROS('1','PR','PRECAL_DESEMBOLSO_PR'))
             AND C.ESTADO IN (SELECT COLUMN_VALUE FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('ESTADOS_CREDITOS'))) );

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, 'OPT015_Q12', 'ALL'));



-- ================================================================
-- Criterios de aceptacion (ver plan eager-dreaming-lamport.md A.2)
--
-- Q1 / Q7  (INSERT): HASH SEMI JOIN en los 4 NOT EXISTS, INDEX USE
--                    en IDX_GARANTIAS_TIPO_SB, HASH JOIN entre
--                    PR_CREDITOS(_HI) y PR_TIPO_CREDITO_REPRESTAMO.
--                    ALERTA si FULL SCAN sobre PR_GARANTIAS o
--                    FILTER con subquery por fila.
-- Q2 / Q8  (DELETE): INDEX SCAN sobre PR_REPRESTAMOS filtrando por
--                    FECHA_CORTE+ESTADO. FILTER con functions es OK
--                    (evaluado en conjunto pequeno).
--                    ALERTA si FULL SCAN sobre PR_REPRESTAMOS.
-- Q3 / Q9  (DIAS_ATRASO): uso de IDX_DE08_SIB_FECHA_DEUDOR o similar.
--                         ALERTA si FULL SCAN sobre PA_DETALLADO_DE08.
-- Q4 / Q10 (MTO_CRED_ACTUAL): plan similar a post-OPT-004.
--                             ALERTA si subquery MAX ejecutada por fila.
-- Q5 / Q11 (ESTADO=X3): HASH SEMI JOIN con PA_DETALLADO_DE08.
--                       ALERTA si FILTER con "1 IN (SELECT 1)".
-- Q6 / Q12 (ESTADO=X1): HASH SEMI JOIN con PR_CREDITOS (PK).
--                       ALERTA si FILTER con "1 = (SELECT DISTINCT 1)".
-- ================================================================
