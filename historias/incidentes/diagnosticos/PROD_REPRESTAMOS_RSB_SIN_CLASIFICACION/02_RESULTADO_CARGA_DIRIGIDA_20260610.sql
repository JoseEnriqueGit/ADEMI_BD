-- =====================================================================
-- Resultado de la carga dirigida del 2026-06-10: cuantificar los RSB
-- Entorno: PRODUCCION. Solo lectura. No modifica datos.
-- Uso: poner el cursor dentro de cada query y ejecutar con F9 en Toad.
--
-- Contexto (evidencia APEX del 2026-06-10):
--   - Filas CREADO con 'Cliente en clasificacion: A' -> en DE08, ruta sana.
--   - Filas CREADO con 'Cliente sin clasificacion, pero parametro
--     deshabilitado' -> en DE08 con clasificacion NULA/no permitida;
--     VALIDAR_CLASIFICACION_SIB_CARGADIRIGIDA esta en 'N'.
--   - Filas RSB ('RECHAZO POR CLIENTE NO EN A,B EN SB') con 'Cliente sin
--     clasificacion' y XCORE vacio -> ausentes del corte DE08; el loop
--     sin compuerta de ACTUALIZA_XCORE_DIRIGIDA los marco RSB antes de
--     consultar el XCORE.
-- Esperado si la hipotesis es correcta:
--   - Query 2: los RSB caen en NO_EXISTE_EN_DE08 (o ES_FIADOR='S') y
--     todos con XCORE nulo; los CREADO existen en DE08.
--   - Ningun RSB de esta carga deberia tener bitacora CLS previa.
-- =====================================================================

-- Query 1: resumen de la carga por estado y texto SIB de la bitacora
WITH carga AS (
    SELECT r.id_represtamo, r.estado
      FROM PR.PR_REPRESTAMOS r
     WHERE r.codigo_empresa = PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
       AND r.id_carga_dirigida IS NOT NULL
       AND TRUNC(r.fecha_proceso) = DATE '2026-06-10'
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

-- Query 2: cruce con DE08 (ultimo corte) - prueba de la hipotesis:
--          estado vs existencia en DE08, clasificacion, fiador y XCORE
WITH carga AS (
    SELECT r.id_represtamo,
           r.estado,
           r.es_fiador,
           r.xcore_global,
           PA.OBT_IDENTIFICACION_PERSONA(r.codigo_cliente, '1') identificacion
      FROM PR.PR_REPRESTAMOS r
     WHERE r.codigo_empresa = PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
       AND r.id_carga_dirigida IS NOT NULL
       AND TRUNC(r.fecha_proceso) = DATE '2026-06-10'
),
d08 AS (
    SELECT d.id_deudor,
           MIN(NVL(d.clasificacion, '<NULA>')) clas_min,
           MAX(NVL(d.clasificacion, '<NULA>')) clas_max
      FROM PA.PA_DE08_SIB d
     WHERE d.fecha_corte = (SELECT MAX(fecha_corte) FROM PA.PA_DE08_SIB)
     GROUP BY d.id_deudor
)
SELECT PR.PR_PKG_REPRESTAMOS.F_OBT_DESCRIPCION_ESTADO(c.estado) estado_desc,
       CASE WHEN d.id_deudor IS NULL THEN 'NO_EXISTE_EN_DE08'
            ELSE 'EXISTE_EN_DE08' END situacion_de08,
       c.es_fiador,
       NVL(d.clas_min, '-') clas_min,
       NVL(d.clas_max, '-') clas_max,
       CASE WHEN c.xcore_global IS NULL THEN 'SIN_XCORE'
            ELSE 'CON_XCORE' END xcore,
       COUNT(*) total
  FROM carga c
  LEFT JOIN d08 d ON d.id_deudor = c.identificacion
 GROUP BY PR.PR_PKG_REPRESTAMOS.F_OBT_DESCRIPCION_ESTADO(c.estado),
          CASE WHEN d.id_deudor IS NULL THEN 'NO_EXISTE_EN_DE08'
               ELSE 'EXISTE_EN_DE08' END,
          c.es_fiador,
          NVL(d.clas_min, '-'),
          NVL(d.clas_max, '-'),
          CASE WHEN c.xcore_global IS NULL THEN 'SIN_XCORE'
               ELSE 'CON_XCORE' END
 ORDER BY estado_desc, total DESC;

-- Query 3: detalle de los RSB de la carga (evidencia individual)
WITH carga AS (
    SELECT r.id_represtamo,
           r.codigo_cliente,
           r.no_credito,
           r.estado,
           r.es_fiador,
           r.xcore_global,
           PA.OBT_IDENTIFICACION_PERSONA(r.codigo_cliente, '1') identificacion
      FROM PR.PR_REPRESTAMOS r
     WHERE r.codigo_empresa = PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
       AND r.id_carga_dirigida IS NOT NULL
       AND TRUNC(r.fecha_proceso) = DATE '2026-06-10'
       AND r.estado = 'RSB'
)
SELECT c.id_represtamo,
       c.codigo_cliente,
       c.identificacion,
       PA.OBT_NOMBRE_PERSONA(c.codigo_cliente) nombres,
       c.no_credito,
       c.es_fiador,
       c.xcore_global,
       CASE WHEN EXISTS (SELECT 1
                           FROM PA.PA_DE08_SIB d
                          WHERE d.fecha_corte = (SELECT MAX(fecha_corte) FROM PA.PA_DE08_SIB)
                            AND d.id_deudor = c.identificacion)
            THEN 'SI' ELSE 'NO' END existe_en_de08,
       (SELECT MAX(d.clasificacion)
          FROM PA.PA_DE08_SIB d
         WHERE d.fecha_corte = (SELECT MAX(fecha_corte) FROM PA.PA_DE08_SIB)
           AND d.id_deudor = c.identificacion) clasificacion_de08,
       CASE WHEN EXISTS (SELECT 1
                           FROM PR.PR_BITACORA_REPRESTAMO b
                          WHERE b.codigo_empresa = PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
                            AND b.id_represtamo = c.id_represtamo
                            AND b.codigo_estado = 'CLS')
            THEN 'SI' ELSE 'NO' END tiene_cls
  FROM carga c
 ORDER BY c.id_represtamo;

-- Query 4: contraste de negocio - clientes que la validacion SIB apagada
--          dejo pasar (clasificacion NULA o no permitida en DE08) frente
--          a los ausentes de DE08 que el loop sin compuerta rechazo
WITH carga AS (
    SELECT r.id_represtamo,
           r.estado,
           PA.OBT_IDENTIFICACION_PERSONA(r.codigo_cliente, '1') identificacion
      FROM PR.PR_REPRESTAMOS r
     WHERE r.codigo_empresa = PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
       AND r.id_carga_dirigida IS NOT NULL
       AND TRUNC(r.fecha_proceso) = DATE '2026-06-10'
),
permitidas AS (
    SELECT DISTINCT column_value clasificacion
      FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('CLASIFICACION_SIB'))
),
d08 AS (
    SELECT d.id_deudor,
           SUM(CASE WHEN p.clasificacion IS NOT NULL THEN 1 ELSE 0 END) filas_permitidas,
           COUNT(*) filas
      FROM PA.PA_DE08_SIB d
      LEFT JOIN permitidas p ON p.clasificacion = d.clasificacion
     WHERE d.fecha_corte = (SELECT MAX(fecha_corte) FROM PA.PA_DE08_SIB)
     GROUP BY d.id_deudor
)
SELECT CASE
           WHEN d.id_deudor IS NULL
           THEN '1_AUSENTE_DE_DE08 (rechazado RSB pese a parametro apagado)'
           WHEN d.filas_permitidas = 0
           THEN '2_EN_DE08_SIN_CLASIFICACION_PERMITIDA (paso por parametro apagado)'
           ELSE '3_EN_DE08_CON_CLASIFICACION_PERMITIDA (ruta sana)'
       END grupo,
       PR.PR_PKG_REPRESTAMOS.F_OBT_DESCRIPCION_ESTADO(c.estado) estado_desc,
       COUNT(*) total
  FROM carga c
  LEFT JOIN d08 d ON d.id_deudor = c.identificacion
 GROUP BY CASE
              WHEN d.id_deudor IS NULL
              THEN '1_AUSENTE_DE_DE08 (rechazado RSB pese a parametro apagado)'
              WHEN d.filas_permitidas = 0
              THEN '2_EN_DE08_SIN_CLASIFICACION_PERMITIDA (paso por parametro apagado)'
              ELSE '3_EN_DE08_CON_CLASIFICACION_PERMITIDA (ruta sana)'
          END,
          PR.PR_PKG_REPRESTAMOS.F_OBT_DESCRIPCION_ESTADO(c.estado)
 ORDER BY grupo, total DESC;
