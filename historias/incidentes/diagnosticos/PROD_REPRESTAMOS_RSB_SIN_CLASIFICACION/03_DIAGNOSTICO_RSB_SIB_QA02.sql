-- =====================================================================
-- Reproduccion controlada en QA02: RSB por falta de CLS/DE08
-- Entorno: QA02. Solo lectura. No modifica datos.
-- Uso: poner el cursor dentro de cada query y ejecutar con F9 en Toad.
--
-- Orden de ejecucion:
--   1. Queries 1, 2 y 3 ANTES de correr la carga dirigida.
--      La Query 3 PREDICE quienes caeran en RSB.
--   2. Correr la carga dirigida en QA02 (P_Carga_Precalifica_Manual via
--      el flujo APEX/job habitual; requiere CARGA_DIRIGIDA_PROCESO_ACTIVO='S'
--      y filas pendientes en PR_CARGA_DIRECCIONADA con ESTADO='T').
--   3. Queries 4, 5 y 6 DESPUES de la corrida, el mismo dia.
--
-- Hipotesis confirmada en PROD (ver README): cliente ausente del ultimo
-- corte de PA_DE08_SIB no recibe CLS y el loop sin compuerta de
-- ACTUALIZA_XCORE_DIRIGIDA lo marca RSB antes de consultar el XCORE.
-- La reproduccion queda confirmada si la prediccion de la Query 3
-- coincide con el resultado de las Queries 4 y 5.
-- =====================================================================

-- ============================ ANTES ==================================

-- Query 1: confirmar el codigo compilado en QA02: loop RSB activo en
--          dirigida/campana y comentado en XCORE_CUSTOM
SELECT line,
       text
  FROM all_source
 WHERE owner = 'PR'
   AND name = 'PR_PKG_REPRESTAMOS'
   AND type = 'PACKAGE BODY'
   AND (
       UPPER(text) LIKE '%VALIDACION_CLASIFICACION%'
       OR UPPER(text) LIKE '%CLIENTE SIN CLASIFICACI%'
   )
 ORDER BY line;

-- Query 2: parametros QA02 y cobertura de los ultimos cortes DE08
--          (QA02 suele tener cortes mas viejos que PROD: anotar cual es
--          el MAX porque es el que usara CUR_DE08_SIB)
SELECT 'DE08_SIB' parametro,
       PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('DE08_SIB') valor
  FROM dual
UNION ALL
SELECT 'VALIDAR_CLASIFICACION_SIB_CARGADIRIGIDA',
       PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('VALIDAR_CLASIFICACION_SIB_CARGADIRIGIDA')
  FROM dual
UNION ALL
SELECT 'VALIDAR_CLASIFICACION_SIB_CAMPANA',
       PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('VALIDAR_CLASIFICACION_SIB_CAMPANA')
  FROM dual
UNION ALL
SELECT 'CLASIFICACION_SIB',
       PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('CLASIFICACION_SIB')
  FROM dual
UNION ALL
SELECT 'CARGA_DIRIGIDA_PROCESO_ACTIVO',
       PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('CARGA_DIRIGIDA_PROCESO_ACTIVO')
  FROM dual
UNION ALL
SELECT 'LOTE_PROCESO_XCORE',
       PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('LOTE_PROCESO_XCORE')
  FROM dual
UNION ALL
SELECT 'MAX_FECHA_CORTE_PA_DE08_SIB',
       TO_CHAR(MAX(fecha_corte), 'YYYY-MM-DD')
  FROM PA.PA_DE08_SIB
UNION ALL
SELECT 'FILAS_EN_ESE_CORTE',
       TO_CHAR(COUNT(*))
  FROM PA.PA_DE08_SIB
 WHERE fecha_corte = (SELECT MAX(fecha_corte) FROM PA.PA_DE08_SIB)
UNION ALL
SELECT 'PENDIENTES_CARGA_DIRECCIONADA_T',
       TO_CHAR(COUNT(*))
  FROM PR.PR_CARGA_DIRECCIONADA
 WHERE estado = 'T';

-- Query 3: PREDICCION - pendientes de la carga (ESTADO='T') cruzados con
--          el ultimo corte DE08. El grupo 1 deberia terminar en RSB
--          'Cliente sin clasificacion' tras la corrida.
--          (cliente derivado de PR_CREDITOS/PR_CREDITOS_HI por NO_CREDITO,
--          igual que el reporte APEX)
WITH pendientes AS (
    SELECT cd.no_credito,
           NVL(c.codigo_cliente, h.codigo_cliente) codigo_cliente
      FROM PR.PR_CARGA_DIRECCIONADA cd
      LEFT JOIN PR.PR_CREDITOS    c ON c.no_credito = cd.no_credito
      LEFT JOIN PR.PR_CREDITOS_HI h ON h.no_credito = cd.no_credito
     WHERE cd.estado = 'T'
),
permitidas AS (
    SELECT DISTINCT column_value clasificacion
      FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('CLASIFICACION_SIB'))
),
d08 AS (
    SELECT d.id_deudor,
           SUM(CASE WHEN p.clasificacion IS NOT NULL THEN 1 ELSE 0 END) filas_permitidas
      FROM PA.PA_DE08_SIB d
      LEFT JOIN permitidas p ON p.clasificacion = d.clasificacion
     WHERE d.fecha_corte = (SELECT MAX(fecha_corte) FROM PA.PA_DE08_SIB)
     GROUP BY d.id_deudor
)
SELECT CASE
           WHEN pe.codigo_cliente IS NULL
           THEN '0_SIN_CREDITO_EN_QA02 (no se podra derivar cliente)'
           WHEN d.id_deudor IS NULL
           THEN '1_AUSENTE_DE_DE08 (prediccion: RSB Cliente sin clasificacion)'
           WHEN d.filas_permitidas = 0
           THEN '2_EN_DE08_SIN_CLASIFICACION_PERMITIDA (CLS si parametro=N, RSB si =S)'
           ELSE '3_EN_DE08_CON_CLASIFICACION_PERMITIDA (prediccion: CLS y sigue)'
       END grupo,
       COUNT(*) total
  FROM pendientes pe
  LEFT JOIN d08 d
    ON d.id_deudor = PA.OBT_IDENTIFICACION_PERSONA(pe.codigo_cliente, '1')
 GROUP BY CASE
              WHEN pe.codigo_cliente IS NULL
              THEN '0_SIN_CREDITO_EN_QA02 (no se podra derivar cliente)'
              WHEN d.id_deudor IS NULL
              THEN '1_AUSENTE_DE_DE08 (prediccion: RSB Cliente sin clasificacion)'
              WHEN d.filas_permitidas = 0
              THEN '2_EN_DE08_SIN_CLASIFICACION_PERMITIDA (CLS si parametro=N, RSB si =S)'
              ELSE '3_EN_DE08_CON_CLASIFICACION_PERMITIDA (prediccion: CLS y sigue)'
          END
 ORDER BY grupo;

-- =========================== DESPUES =================================

-- Query 4: resumen de la corrida de HOY por estado y texto SIB
WITH carga AS (
    SELECT r.id_represtamo, r.estado
      FROM PR.PR_REPRESTAMOS r
     WHERE r.codigo_empresa = PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
       AND r.id_carga_dirigida IS NOT NULL
       AND TRUNC(r.fecha_proceso) = TRUNC(SYSDATE)
)
SELECT c.estado,
       PR.PR_PKG_REPRESTAMOS.F_OBT_DESCRIPCION_ESTADO(c.estado) estado_desc,
       TRIM(PR.PR_PKG_REPRESTAMOS.F_OBTIENE_DESC_BITACORA(c.id_represtamo, 'CLS') || ' ' ||
            PR.PR_PKG_REPRESTAMOS.F_OBTIENE_DESC_BITACORA(c.id_represtamo, 'RSB')) texto_sib,
       COUNT(*) total
  FROM carga c
 GROUP BY c.estado,
          PR.PR_PKG_REPRESTAMOS.F_OBT_DESCRIPCION_ESTADO(c.estado),
          TRIM(PR.PR_PKG_REPRESTAMOS.F_OBTIENE_DESC_BITACORA(c.id_represtamo, 'CLS') || ' ' ||
               PR.PR_PKG_REPRESTAMOS.F_OBTIENE_DESC_BITACORA(c.id_represtamo, 'RSB'))
 ORDER BY total DESC;

-- Query 5: firma del salto en los RSB de hoy - debe dar para cada uno:
--          rsb_primera_bitacora=SI, tiene_cls=NO, xcore nulo y
--          existe_en_de08=NO (o es_fiador=S, que tambien queda fuera
--          del cursor CUR_DE08_SIB)
WITH rsb_hoy AS (
    SELECT r.id_represtamo,
           r.codigo_cliente,
           r.no_credito,
           r.es_fiador,
           r.xcore_global,
           PA.OBT_IDENTIFICACION_PERSONA(r.codigo_cliente, '1') identificacion
      FROM PR.PR_REPRESTAMOS r
     WHERE r.codigo_empresa = PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
       AND r.id_carga_dirigida IS NOT NULL
       AND TRUNC(r.fecha_proceso) = TRUNC(SYSDATE)
       AND r.estado = 'RSB'
)
SELECT c.id_represtamo,
       c.no_credito,
       c.identificacion,
       c.es_fiador,
       c.xcore_global,
       CASE WHEN (SELECT MIN(b.id_bitacora)
                    FROM PR.PR_BITACORA_REPRESTAMO b
                   WHERE b.codigo_empresa = PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
                     AND b.id_represtamo = c.id_represtamo) =
                 (SELECT MIN(b.id_bitacora)
                    FROM PR.PR_BITACORA_REPRESTAMO b
                   WHERE b.codigo_empresa = PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
                     AND b.id_represtamo = c.id_represtamo
                     AND b.codigo_estado = 'RSB')
            THEN 'SI' ELSE 'NO' END rsb_primera_bitacora,
       CASE WHEN EXISTS (SELECT 1
                           FROM PR.PR_BITACORA_REPRESTAMO b
                          WHERE b.codigo_empresa = PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
                            AND b.id_represtamo = c.id_represtamo
                            AND b.codigo_estado = 'CLS')
            THEN 'SI' ELSE 'NO' END tiene_cls,
       CASE WHEN EXISTS (SELECT 1
                           FROM PA.PA_DE08_SIB d
                          WHERE d.fecha_corte = (SELECT MAX(fecha_corte) FROM PA.PA_DE08_SIB)
                            AND d.id_deudor = c.identificacion)
            THEN 'SI' ELSE 'NO' END existe_en_de08
  FROM rsb_hoy c
 ORDER BY c.id_represtamo;

-- Query 6: contraste de negocio en la corrida de hoy - ausentes de DE08
--          rechazados vs clasificacion mala que paso
WITH carga AS (
    SELECT r.id_represtamo,
           r.estado,
           PA.OBT_IDENTIFICACION_PERSONA(r.codigo_cliente, '1') identificacion
      FROM PR.PR_REPRESTAMOS r
     WHERE r.codigo_empresa = PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
       AND r.id_carga_dirigida IS NOT NULL
       AND TRUNC(r.fecha_proceso) = TRUNC(SYSDATE)
),
permitidas AS (
    SELECT DISTINCT column_value clasificacion
      FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('CLASIFICACION_SIB'))
),
d08 AS (
    SELECT d.id_deudor,
           SUM(CASE WHEN p.clasificacion IS NOT NULL THEN 1 ELSE 0 END) filas_permitidas
      FROM PA.PA_DE08_SIB d
      LEFT JOIN permitidas p ON p.clasificacion = d.clasificacion
     WHERE d.fecha_corte = (SELECT MAX(fecha_corte) FROM PA.PA_DE08_SIB)
     GROUP BY d.id_deudor
)
SELECT CASE
           WHEN d.id_deudor IS NULL
           THEN '1_AUSENTE_DE_DE08'
           WHEN d.filas_permitidas = 0
           THEN '2_EN_DE08_SIN_CLASIFICACION_PERMITIDA'
           ELSE '3_EN_DE08_CON_CLASIFICACION_PERMITIDA'
       END grupo,
       PR.PR_PKG_REPRESTAMOS.F_OBT_DESCRIPCION_ESTADO(c.estado) estado_desc,
       COUNT(*) total
  FROM carga c
  LEFT JOIN d08 d ON d.id_deudor = c.identificacion
 GROUP BY CASE
              WHEN d.id_deudor IS NULL
              THEN '1_AUSENTE_DE_DE08'
              WHEN d.filas_permitidas = 0
              THEN '2_EN_DE08_SIN_CLASIFICACION_PERMITIDA'
              ELSE '3_EN_DE08_CON_CLASIFICACION_PERMITIDA'
          END,
          PR.PR_PKG_REPRESTAMOS.F_OBT_DESCRIPCION_ESTADO(c.estado)
 ORDER BY grupo, total DESC;

-- Query 7: embudo completo de PR_CARGA_DIRECCIONADA - los descartes
--          PREVIOS a PR_REPRESTAMOS quedan aqui con estado 'E' y el
--          motivo en OBSERVACIONES (no tipo de credito valido, no es
--          fisico, represtamo activo...); 'T' = pendiente, 'F' =
--          procesado (incluye los que el loop RSB marco F).
--          Estos 'E' nunca llegan a la bitacora: completan el panorama
--          de "cuantos se quedan en el camino" de cada carga.
SELECT cd.estado,
       NVL(cd.observaciones, '(sin observacion)') observaciones,
       COUNT(*) total,
       MIN(cd.fecha_modificacion) primera_modificacion,
       MAX(cd.fecha_modificacion) ultima_modificacion
  FROM PR.PR_CARGA_DIRECCIONADA cd
 GROUP BY cd.estado,
          NVL(cd.observaciones, '(sin observacion)')
 ORDER BY cd.estado, total DESC;
