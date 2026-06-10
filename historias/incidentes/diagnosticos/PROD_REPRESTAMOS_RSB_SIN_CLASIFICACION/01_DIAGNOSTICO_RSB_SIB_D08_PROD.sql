-- =====================================================================
-- Diagnostico: RSB como primera/ultima bitacora por falta de CLS/DE08
-- Entorno: PRODUCCION. Solo lectura. No modifica datos.
-- Fecha de corte bajo hipotesis: 2026-06-01.
--
-- Uso:
--   1. Poner el cursor dentro de cada query.
--   2. Ejecutar con F9 (Execute Statement) en Toad.
--   3. Guardar los resultados en el README/RESULTADOS del incidente.
--
-- Hipotesis a probar:
--   H1. Los clientes rechazados no existen en PA.PA_DE08_SIB para el
--       corte DATE '2026-06-01'.
--   H2. Al no pasar por CUR_DE08_SIB, no reciben bitacora CLS.
--   H3. ACTUALIZA_XCORE_DIRIGIDA o ACTUALIZA_XCORE_CAMPANA_ESPECIAL
--       toma todo PR_REPRESTAMOS en RE sin CLS y genera RSB.
--   H4. RSB queda como primera bitacora porque la bitacora RE se genera
--       despues de esas rutinas XCORE.
--
-- Nota importante:
--   La ausencia en DE08 no genera RSB directamente. El salto ocurre
--   porque las rutinas XCORE equiparan "sin bitacora CLS" con
--   "Cliente sin clasificacion".
-- =====================================================================

-- Query 1: confirmar el codigo REAL compilado en PROD.
SELECT line,
       text
  FROM all_source
 WHERE owner = 'PR'
   AND name = 'PR_PKG_REPRESTAMOS'
   AND type = 'PACKAGE BODY'
   AND (
       UPPER(text) LIKE '%VALIDACION_CLASIFICACION%'
       OR UPPER(text) LIKE '%CLIENTE SIN CLASIFICACI%'
       OR UPPER(text) LIKE '%ACTUALIZA_XCORE_DIRIGIDA%'
       OR UPPER(text) LIKE '%ACTUALIZA_XCORE_CAMPANA_ESPECIAL%'
   )
 ORDER BY line;

-- Query 2: parametros y fechas de corte vigentes.
SELECT 'DE08_SIB' parametro,
       PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('DE08_SIB') valor
  FROM dual
UNION ALL
SELECT 'CLASIFICACION_SIB',
       PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('CLASIFICACION_SIB')
  FROM dual
UNION ALL
SELECT 'VALIDAR_CLASIFICACION_SIB_CARGADIRIGIDA',
       PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO(
           'VALIDAR_CLASIFICACION_SIB_CARGADIRIGIDA')
  FROM dual
UNION ALL
SELECT 'VALIDAR_CLASIFICACION_SIB_CAMPANA',
       PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO(
           'VALIDAR_CLASIFICACION_SIB_CAMPANA')
  FROM dual
UNION ALL
SELECT 'VALIDAR_XCORE_CARGADIRIGIDA',
       PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO(
           'VALIDAR_XCORE_CARGADIRIGIDA')
  FROM dual
UNION ALL
SELECT 'VALIDAR_XCORE_CAMPANA',
       PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO(
           'VALIDAR_XCORE_CAMPANA')
  FROM dual
UNION ALL
SELECT 'LOTE_PROCESO_XCORE',
       PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO(
           'LOTE_PROCESO_XCORE')
  FROM dual
UNION ALL
SELECT 'MAX_FECHA_CORTE_PA_DE08_SIB',
       TO_CHAR(MAX(fecha_corte), 'YYYY-MM-DD')
  FROM PA.PA_DE08_SIB
UNION ALL
SELECT 'MAX_FECHA_CORTE_PA_DETALLADO_DE08_PR',
       TO_CHAR(MAX(fecha_corte), 'YYYY-MM-DD')
  FROM PA.PA_DETALLADO_DE08
 WHERE fuente = 'PR';

-- Query 2A: ultimas 10 fechas de corte disponibles en PA_DE08_SIB.
-- Ejecutar esta antes de fijar una fecha en las Queries 5-8.
SELECT fecha_corte,
       total_filas,
       total_deudores,
       filas_clasificacion_nula
  FROM (
        SELECT d.fecha_corte,
               COUNT(*) total_filas,
               COUNT(DISTINCT d.id_deudor) total_deudores,
               SUM(CASE
                       WHEN d.clasificacion IS NULL THEN 1
                       ELSE 0
                   END) filas_clasificacion_nula
          FROM PA.PA_DE08_SIB d
         GROUP BY d.fecha_corte
         ORDER BY d.fecha_corte DESC
       )
 WHERE ROWNUM <= 10;

-- Query 3: evolucion mensual de RSB por observacion.
SELECT TRUNC(b.fecha_adicion, 'MM') mes,
       b.observaciones,
       COUNT(*) total_eventos,
       COUNT(DISTINCT b.id_represtamo) represtamos
  FROM PR.PR_BITACORA_REPRESTAMO b
 WHERE b.codigo_empresa =
       PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
   AND b.codigo_estado = 'RSB'
   AND b.fecha_adicion >= DATE '2025-11-01'
 GROUP BY TRUNC(b.fecha_adicion, 'MM'),
          b.observaciones
 ORDER BY mes DESC,
          total_eventos DESC;

-- Query 4: comprobar si RSB fue la primera bitacora y separar el origen.
WITH rsb AS (
    SELECT b.id_represtamo,
           b.id_bitacora,
           b.fecha_adicion,
           b.observaciones
      FROM PR.PR_BITACORA_REPRESTAMO b
     WHERE b.codigo_empresa =
           PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
       AND b.codigo_estado = 'RSB'
       AND b.fecha_adicion >= DATE '2026-06-01'
       AND UPPER(b.observaciones) LIKE 'CLIENTE SIN CLASIFICACI%'
)
SELECT CASE
           WHEN r.id_carga_dirigida IS NOT NULL
            AND r.id_repre_campana_especiales IS NOT NULL
           THEN 'CARGA_DIRIGIDA_Y_CAMPANA'
           WHEN r.id_carga_dirigida IS NOT NULL
           THEN 'CARGA_DIRIGIDA'
           WHEN r.id_repre_campana_especiales IS NOT NULL
           THEN 'CAMPANA_ESPECIAL'
           ELSE 'FLUJO_REGULAR_O_CANCELADO'
       END origen,
       COUNT(*) total_rsb,
       SUM(CASE
               WHEN NOT EXISTS (
                   SELECT 1
                     FROM PR.PR_BITACORA_REPRESTAMO bx
                    WHERE bx.codigo_empresa = r.codigo_empresa
                      AND bx.id_represtamo = x.id_represtamo
                      AND bx.id_bitacora < x.id_bitacora
               )
               THEN 1 ELSE 0
           END) rsb_es_primera_bitacora,
       SUM(CASE
               WHEN NOT EXISTS (
                   SELECT 1
                     FROM PR.PR_BITACORA_REPRESTAMO bx
                    WHERE bx.codigo_empresa = r.codigo_empresa
                      AND bx.id_represtamo = x.id_represtamo
                      AND bx.codigo_estado = 'RE'
                      AND bx.id_bitacora < x.id_bitacora
               )
               THEN 1 ELSE 0
           END) sin_re_previo,
       SUM(CASE
               WHEN NOT EXISTS (
                   SELECT 1
                     FROM PR.PR_BITACORA_REPRESTAMO bx
                    WHERE bx.codigo_empresa = r.codigo_empresa
                      AND bx.id_represtamo = x.id_represtamo
                      AND bx.codigo_estado = 'CLS'
                      AND bx.id_bitacora < x.id_bitacora
               )
               THEN 1 ELSE 0
           END) sin_cls_previo
  FROM rsb x
  JOIN PR.PR_REPRESTAMOS r
    ON r.codigo_empresa =
       PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
   AND r.id_represtamo = x.id_represtamo
 GROUP BY CASE
              WHEN r.id_carga_dirigida IS NOT NULL
               AND r.id_repre_campana_especiales IS NOT NULL
              THEN 'CARGA_DIRIGIDA_Y_CAMPANA'
              WHEN r.id_carga_dirigida IS NOT NULL
              THEN 'CARGA_DIRIGIDA'
              WHEN r.id_repre_campana_especiales IS NOT NULL
              THEN 'CAMPANA_ESPECIAL'
              ELSE 'FLUJO_REGULAR_O_CANCELADO'
          END
 ORDER BY total_rsb DESC;

-- Query 5: prueba principal de la hipotesis del corte 2026-06-01.
WITH clasificaciones_permitidas AS (
    SELECT DISTINCT column_value clasificacion
      FROM TABLE(
           PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS(
               'CLASIFICACION_SIB'))
),
objetivo AS (
    SELECT DISTINCT b.id_represtamo
      FROM PR.PR_BITACORA_REPRESTAMO b
     WHERE b.codigo_empresa =
           PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
       AND b.codigo_estado = 'RSB'
       AND b.fecha_adicion >= DATE '2026-06-01'
       AND UPPER(b.observaciones) LIKE 'CLIENTE SIN CLASIFICACI%'
),
clientes AS (
    SELECT o.id_represtamo,
           PA.OBT_IDENTIFICACION_PERSONA(r.codigo_cliente, '1')
               identificacion
      FROM objetivo o
      JOIN PR.PR_REPRESTAMOS r
        ON r.codigo_empresa =
           PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
       AND r.id_represtamo = o.id_represtamo
),
d08 AS (
    SELECT d.id_deudor,
           COUNT(*) filas_d08,
           SUM(CASE WHEN d.clasificacion IS NULL
                    THEN 1 ELSE 0 END) filas_nulas,
           SUM(CASE
                   WHEN p.clasificacion IS NOT NULL
                   THEN 1 ELSE 0
               END) filas_permitidas,
           SUM(CASE
                   WHEN d.clasificacion IS NOT NULL
                    AND p.clasificacion IS NULL
                   THEN 1 ELSE 0
               END) filas_no_permitidas
      FROM PA.PA_DE08_SIB d
      LEFT JOIN clasificaciones_permitidas p
        ON p.clasificacion = d.clasificacion
     WHERE d.fecha_corte = DATE '2026-06-01'
     GROUP BY d.id_deudor
)
SELECT CASE
           WHEN d.id_deudor IS NULL
           THEN '1_NO_EXISTE_EN_DE08_2026_06_01'
           WHEN d.filas_nulas = d.filas_d08
           THEN '2_EXISTE_PERO_CLASIFICACION_NULA'
           WHEN d.filas_permitidas > 0
            AND d.filas_no_permitidas = 0
           THEN '3_EXISTE_CON_CLASIFICACION_PERMITIDA'
           WHEN d.filas_no_permitidas > 0
            AND d.filas_permitidas = 0
           THEN '4_EXISTE_CON_CLASIFICACION_NO_PERMITIDA'
           ELSE '5_EXISTE_CON_FILAS_MEZCLADAS_O_DUPLICADAS'
       END diagnostico_de08,
       COUNT(*) represtamos
  FROM clientes c
  LEFT JOIN d08 d
    ON d.id_deudor = c.identificacion
 GROUP BY CASE
              WHEN d.id_deudor IS NULL
              THEN '1_NO_EXISTE_EN_DE08_2026_06_01'
              WHEN d.filas_nulas = d.filas_d08
              THEN '2_EXISTE_PERO_CLASIFICACION_NULA'
              WHEN d.filas_permitidas > 0
               AND d.filas_no_permitidas = 0
              THEN '3_EXISTE_CON_CLASIFICACION_PERMITIDA'
              WHEN d.filas_no_permitidas > 0
               AND d.filas_permitidas = 0
              THEN '4_EXISTE_CON_CLASIFICACION_NO_PERMITIDA'
              ELSE '5_EXISTE_CON_FILAS_MEZCLADAS_O_DUPLICADAS'
          END
 ORDER BY diagnostico_de08;

-- Query 6: detalle individual para entregar evidencia.
WITH clasificaciones_permitidas AS (
    SELECT DISTINCT column_value clasificacion
      FROM TABLE(
           PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS(
               'CLASIFICACION_SIB'))
),
rsb AS (
    SELECT b.id_represtamo,
           b.id_bitacora,
           b.fecha_adicion,
           b.observaciones,
           ROW_NUMBER() OVER (
               PARTITION BY b.id_represtamo
               ORDER BY b.id_bitacora
           ) rn_rsb
      FROM PR.PR_BITACORA_REPRESTAMO b
     WHERE b.codigo_empresa =
           PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
       AND b.codigo_estado = 'RSB'
       AND b.fecha_adicion >= DATE '2026-06-01'
       AND UPPER(b.observaciones) LIKE 'CLIENTE SIN CLASIFICACI%'
),
d08 AS (
    SELECT d.id_deudor,
           COUNT(*) filas_d08,
           MIN(NVL(d.clasificacion, '<NULL>')) clasificacion_min,
           MAX(NVL(d.clasificacion, '<NULL>')) clasificacion_max,
           SUM(CASE WHEN d.clasificacion IS NULL
                    THEN 1 ELSE 0 END) filas_nulas,
           SUM(CASE
                   WHEN p.clasificacion IS NOT NULL
                   THEN 1 ELSE 0
               END) filas_permitidas,
           SUM(CASE
                   WHEN d.clasificacion IS NOT NULL
                    AND p.clasificacion IS NULL
                   THEN 1 ELSE 0
               END) filas_no_permitidas
      FROM PA.PA_DE08_SIB d
      LEFT JOIN clasificaciones_permitidas p
        ON p.clasificacion = d.clasificacion
     WHERE d.fecha_corte = DATE '2026-06-01'
     GROUP BY d.id_deudor
)
SELECT *
  FROM (
        SELECT x.id_represtamo,
               r.no_credito,
               r.codigo_cliente,
               PA.OBT_IDENTIFICACION_PERSONA(r.codigo_cliente, '1')
                   identificacion,
               x.fecha_adicion fecha_rsb,
               x.id_bitacora id_bitacora_rsb,
               x.observaciones,
               CASE
                   WHEN r.id_carga_dirigida IS NOT NULL
                   THEN 'CARGA_DIRIGIDA'
                   WHEN r.id_repre_campana_especiales IS NOT NULL
                   THEN 'CAMPANA_ESPECIAL'
                   ELSE 'FLUJO_REGULAR_O_CANCELADO'
               END origen,
               CASE
                   WHEN d.id_deudor IS NULL
                   THEN 'NO_EXISTE_EN_DE08_2026_06_01'
                   WHEN d.filas_nulas = d.filas_d08
                   THEN 'CLASIFICACION_NULA'
                   WHEN d.filas_permitidas > 0
                    AND d.filas_no_permitidas = 0
                   THEN 'CLASIFICACION_PERMITIDA'
                   WHEN d.filas_no_permitidas > 0
                    AND d.filas_permitidas = 0
                   THEN 'CLASIFICACION_NO_PERMITIDA'
                   ELSE 'FILAS_MEZCLADAS_O_DUPLICADAS'
               END diagnostico_de08,
               d.filas_d08,
               d.clasificacion_min,
               d.clasificacion_max,
               CASE
                   WHEN EXISTS (
                       SELECT 1
                         FROM PR.PR_BITACORA_REPRESTAMO bx
                        WHERE bx.codigo_empresa = r.codigo_empresa
                          AND bx.id_represtamo = x.id_represtamo
                          AND bx.codigo_estado = 'RE'
                          AND bx.id_bitacora < x.id_bitacora)
                   THEN 'SI' ELSE 'NO'
               END tiene_re_previo,
               CASE
                   WHEN EXISTS (
                       SELECT 1
                         FROM PR.PR_BITACORA_REPRESTAMO bx
                        WHERE bx.codigo_empresa = r.codigo_empresa
                          AND bx.id_represtamo = x.id_represtamo
                          AND bx.codigo_estado = 'CLS'
                          AND bx.id_bitacora < x.id_bitacora)
                   THEN 'SI' ELSE 'NO'
               END tiene_cls_previo
          FROM rsb x
          JOIN PR.PR_REPRESTAMOS r
            ON r.codigo_empresa =
               PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
           AND r.id_represtamo = x.id_represtamo
          LEFT JOIN d08 d
            ON d.id_deudor =
               PA.OBT_IDENTIFICACION_PERSONA(r.codigo_cliente, '1')
         WHERE x.rn_rsb = 1
         ORDER BY x.fecha_adicion DESC,
                  x.id_represtamo
       )
 WHERE ROWNUM <= 200;

-- Query 7: ausentes el 2026-06-01 que si existian en un corte anterior.
WITH objetivo AS (
    SELECT DISTINCT b.id_represtamo
      FROM PR.PR_BITACORA_REPRESTAMO b
     WHERE b.codigo_empresa =
           PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
       AND b.codigo_estado = 'RSB'
       AND b.fecha_adicion >= DATE '2026-06-01'
       AND UPPER(b.observaciones) LIKE 'CLIENTE SIN CLASIFICACI%'
),
clientes AS (
    SELECT o.id_represtamo,
           PA.OBT_IDENTIFICACION_PERSONA(r.codigo_cliente, '1')
               identificacion
      FROM objetivo o
      JOIN PR.PR_REPRESTAMOS r
        ON r.codigo_empresa =
           PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
       AND r.id_represtamo = o.id_represtamo
),
foto AS (
    SELECT c.id_represtamo,
           c.identificacion,
           MAX(CASE
                   WHEN d.fecha_corte = DATE '2026-06-01'
                   THEN d.fecha_corte
               END) existe_junio,
           MAX(CASE
                   WHEN d.fecha_corte < DATE '2026-06-01'
                   THEN d.fecha_corte
               END) ultimo_corte_anterior
      FROM clientes c
      LEFT JOIN PA.PA_DE08_SIB d
        ON d.id_deudor = c.identificacion
       AND d.fecha_corte <= DATE '2026-06-01'
     GROUP BY c.id_represtamo,
              c.identificacion
)
SELECT CASE
           WHEN existe_junio IS NOT NULL
           THEN '1_EXISTE_EN_JUNIO'
           WHEN ultimo_corte_anterior IS NOT NULL
           THEN '2_NO_ESTA_EN_JUNIO_PERO_EXISTIA_ANTES'
           ELSE '3_NO_TIENE_HISTORICO_HASTA_JUNIO'
       END situacion,
       COUNT(*) represtamos,
       MIN(ultimo_corte_anterior) corte_anterior_min,
       MAX(ultimo_corte_anterior) corte_anterior_max
  FROM foto
 GROUP BY CASE
              WHEN existe_junio IS NOT NULL
              THEN '1_EXISTE_EN_JUNIO'
              WHEN ultimo_corte_anterior IS NOT NULL
              THEN '2_NO_ESTA_EN_JUNIO_PERO_EXISTIA_ANTES'
              ELSE '3_NO_TIENE_HISTORICO_HASTA_JUNIO'
          END
 ORDER BY situacion;

-- Query 8: universo actualmente expuesto al mismo salto.
-- El cursor del package no filtra por origen: toma TODO RE sin CLS.
WITH expuestos AS (
    SELECT r.id_represtamo,
           CASE
               WHEN r.id_carga_dirigida IS NOT NULL
               THEN 'CARGA_DIRIGIDA'
               WHEN r.id_repre_campana_especiales IS NOT NULL
               THEN 'CAMPANA_ESPECIAL'
               ELSE 'FLUJO_REGULAR_O_CANCELADO'
           END origen,
           CASE
               WHEN EXISTS (
                   SELECT 1
                     FROM PA.PA_DE08_SIB d
                    WHERE d.fecha_corte = DATE '2026-06-01'
                      AND d.id_deudor =
                          PA.OBT_IDENTIFICACION_PERSONA(
                              r.codigo_cliente, '1'))
               THEN 'EXISTE_DE08_JUNIO'
               ELSE 'NO_EXISTE_DE08_JUNIO'
           END situacion_de08
      FROM PR.PR_REPRESTAMOS r
     WHERE r.codigo_empresa =
           PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
       AND r.estado = 'RE'
       AND r.fecha_adicion >= DATE '2026-06-01'
       AND NOT EXISTS (
           SELECT 1
             FROM PR.PR_BITACORA_REPRESTAMO b
            WHERE b.codigo_empresa = r.codigo_empresa
              AND b.id_represtamo = r.id_represtamo
              AND b.codigo_estado = 'CLS'
       )
)
SELECT origen,
       situacion_de08,
       COUNT(*) candidatos_expuestos
  FROM expuestos
 GROUP BY origen,
          situacion_de08
 ORDER BY origen,
          situacion_de08;
