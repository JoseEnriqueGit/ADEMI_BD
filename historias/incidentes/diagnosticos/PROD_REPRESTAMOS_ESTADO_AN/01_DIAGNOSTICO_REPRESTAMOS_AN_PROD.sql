-- =====================================================================
-- Diagnostico: por que los candidatos a represtamo quedan en estado AN
-- Entorno: PRODUCCION. Solo lectura. No modifica datos.
-- Uso: poner el cursor dentro de cada query y ejecutar con F9
--      (Execute Statement) para ver el resultado en el Data Grid.
-- Ventana de analisis: ultimos 2 meses (ajustar el ADD_MONTHS si se
--      necesita otra ventana).
--
-- Rutas que marcan AN en PR.PR_PKG_REPRESTAMOS (body PROD):
--   R1. Cierre del job (P_Carga_Precalifica_* / loop sobre ESTADO='RE'):
--       si tras P_Registrar_Solicitud NO existe fila en
--       PR_SOLICITUD_REPRESTAMO -> AN con motivo
--       'No cumple con los criterios: Solicitudes,Opciones'.
--       (Con solicitud y sin canal -> CP; con ambos -> NP, nunca AN.)
--   R2. P_Anular_Represtamos_Inactivos (previo a la recarga diaria):
--       ESTADO en parametro ESTADOS_ANULAR_REPRESTAMOS_POR_NO_CONCLUIR_
--       PROCESO y LAST_DAY(FECHA_PROCESO) <= hoy -> AN con motivo
--       'Represtamo anulado (Link Vencido) por no concluir proceso.'
--       (variante campana especiales usa DIA_CADUCA_LINK_CANCELADOS).
--   R3. Campana tipo credito (P_Registra_Solicitud_Campana_Tipo_Credito):
--       F_OBTENER_NUEVO_CREDITO = 1 -> AN con motivo
--       'Represtamo anulado por salto de Tipo Credito'.
--   R4. Solicitud de nuevo link: el represtamo anterior queda AN con
--       motivo 'Anulado por Solicitud nuevo Link'.
--
-- Para R1 la solicitud no se crea cuando:
--   a) PR_REPRESTAMOS.CODIGO_CLIENTE es NULL, o
--   b) P_Registrar_Solicitud revienta antes del INSERT (datos primarios/
--      secundarios del cliente, F_OBTENER_NUEVO_CREDITO, error de insert)
--      y el error queda solo en el log de IA.LOGGER/setError.
-- =====================================================================

-- Query 1: parametros vigentes que gobiernan la anulacion
SELECT 'ESTADOS_ANULAR_REPRESTAMOS_POR_NO_CONCLUIR_PROCESO' parametro,
       PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('ESTADOS_ANULAR_REPRESTAMOS_POR_NO_CONCLUIR_PROCESO') valor
  FROM DUAL
UNION ALL
SELECT 'DIA_CADUCA_LINK',
       PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('DIA_CADUCA_LINK')
  FROM DUAL
UNION ALL
SELECT 'DIA_CADUCA_LINK_CANCELADOS',
       PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('DIA_CADUCA_LINK_CANCELADOS')
  FROM DUAL
UNION ALL
SELECT 'ESTADOS_ANULAR_CREDITOS_CANCELADOS',
       PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('ESTADOS_ANULAR_CREDITOS_CANCELADOS')
  FROM DUAL
UNION ALL
SELECT 'DIAS_CANCELACION',
       PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('DIAS_CANCELACION')
  FROM DUAL
UNION ALL
SELECT 'EXPREG_TELEFONO',
       PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('EXPREG_TELEFONO')
  FROM DUAL;

-- Query 2: volumen de AN por mes y por motivo (bitacora)
--          identifica cual de las rutas R1-R4 esta generando los AN
SELECT TRUNC(b.fecha_adicion, 'MM')  mes,
       b.observaciones               motivo,
       COUNT(*)                      total,
       COUNT(DISTINCT b.id_represtamo) represtamos
  FROM PR.PR_BITACORA_REPRESTAMO b
 WHERE b.codigo_empresa = PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
   AND b.codigo_estado = 'AN'
   AND b.fecha_adicion >= ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -2)
 GROUP BY TRUNC(b.fecha_adicion, 'MM'), b.observaciones
 ORDER BY mes DESC, total DESC;

-- Query 3: desde que estado caen a AN (estado previo en la bitacora)
--          R1 cae desde RE; R2 cae desde los estados del parametro
WITH bit AS (
    SELECT b.id_represtamo,
           b.id_bitacora,
           b.codigo_estado,
           b.observaciones,
           b.fecha_adicion,
           LAG(b.codigo_estado)
               OVER (PARTITION BY b.id_represtamo
                     ORDER BY b.id_bitacora) estado_anterior
      FROM PR.PR_BITACORA_REPRESTAMO b
     WHERE b.codigo_empresa = PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
)
SELECT estado_anterior,
       observaciones        motivo,
       COUNT(*)             total,
       MIN(fecha_adicion)   primera,
       MAX(fecha_adicion)   ultima
  FROM bit
 WHERE codigo_estado = 'AN'
   AND fecha_adicion >= ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -2)
 GROUP BY estado_anterior, observaciones
 ORDER BY total DESC;

-- Query 4: AN del cierre (R1) - reproducir la condicion exacta:
--          el cierre marca AN solo cuando NO existe solicitud.
--          Clasifica la causa raiz por represtamo.
--          Nota: solicitud/canal se evaluan HOY; si alguien creo la
--          solicitud despues del job apareceran las filas ANOMALIA.
WITH an_cierre AS (
    SELECT b.id_represtamo,
           MAX(b.fecha_adicion) fecha_an
      FROM PR.PR_BITACORA_REPRESTAMO b
     WHERE b.codigo_empresa = PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
       AND b.codigo_estado = 'AN'
       AND b.observaciones LIKE 'No cumple con los criterios%'
       AND b.fecha_adicion >= ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -2)
     GROUP BY b.id_represtamo
)
SELECT CASE
           WHEN r.codigo_cliente IS NULL
           THEN '1_SIN_CODIGO_CLIENTE: el cierre no pudo crear solicitud'
           WHEN s.id_represtamo IS NULL
           THEN '2_SIN_SOLICITUD: P_Registrar_Solicitud fallo (revisar log de errores IA)'
           WHEN c.id_represtamo IS NULL
           THEN '3_ANOMALIA: hoy tiene solicitud sin canal (el job esperaba CP)'
           ELSE '4_ANOMALIA: hoy tiene solicitud y canal (el job esperaba NP)'
       END causa,
       COUNT(*) total
  FROM an_cierre a
  JOIN PR.PR_REPRESTAMOS r
    ON r.codigo_empresa = PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
   AND r.id_represtamo  = a.id_represtamo
  LEFT JOIN (SELECT DISTINCT s1.id_represtamo
               FROM PR.PR_SOLICITUD_REPRESTAMO s1
              WHERE s1.codigo_empresa = PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO) s
    ON s.id_represtamo = a.id_represtamo
  LEFT JOIN (SELECT DISTINCT c1.id_represtamo
               FROM PR.PR_CANALES_REPRESTAMO c1
              WHERE c1.codigo_empresa = PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO) c
    ON c.id_represtamo = a.id_represtamo
 GROUP BY CASE
              WHEN r.codigo_cliente IS NULL
              THEN '1_SIN_CODIGO_CLIENTE: el cierre no pudo crear solicitud'
              WHEN s.id_represtamo IS NULL
              THEN '2_SIN_SOLICITUD: P_Registrar_Solicitud fallo (revisar log de errores IA)'
              WHEN c.id_represtamo IS NULL
              THEN '3_ANOMALIA: hoy tiene solicitud sin canal (el job esperaba CP)'
              ELSE '4_ANOMALIA: hoy tiene solicitud y canal (el job esperaba NP)'
          END
 ORDER BY causa;

-- Query 5: muestra individual de AN del cierre (50 filas) con los datos
--          que el cierre valida: codigo_cliente, solicitud, canal y si
--          el celular de la solicitud pasa la regex EXPREG_TELEFONO
--          (misma limpieza de parentesis que F_Validar_Telefono)
WITH an_cierre AS (
    SELECT b.id_represtamo,
           MAX(b.fecha_adicion) fecha_an
      FROM PR.PR_BITACORA_REPRESTAMO b
     WHERE b.codigo_empresa = PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
       AND b.codigo_estado = 'AN'
       AND b.observaciones LIKE 'No cumple con los criterios%'
       AND b.fecha_adicion >= ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -2)
     GROUP BY b.id_represtamo
)
SELECT *
  FROM (
        SELECT a.id_represtamo,
               a.fecha_an,
               r.estado            estado_actual,
               r.codigo_cliente,
               r.no_credito,
               CASE WHEN s.id_represtamo IS NULL THEN 'NO' ELSE 'SI' END tiene_solicitud,
               CASE WHEN c.id_represtamo IS NULL THEN 'NO' ELSE 'SI' END tiene_canal,
               s.telefono_celular,
               REGEXP_SUBSTR(
                   REPLACE(REPLACE(s.telefono_celular, '(', ''), ')', ''),
                   PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('EXPREG_TELEFONO')) celular_valido,
               s.tipo_credito      tipo_credito_solicitud
          FROM an_cierre a
          JOIN PR.PR_REPRESTAMOS r
            ON r.codigo_empresa = PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
           AND r.id_represtamo  = a.id_represtamo
          LEFT JOIN PR.PR_SOLICITUD_REPRESTAMO s
            ON s.codigo_empresa = PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
           AND s.id_represtamo  = a.id_represtamo
          LEFT JOIN (SELECT DISTINCT c1.id_represtamo
                       FROM PR.PR_CANALES_REPRESTAMO c1
                      WHERE c1.codigo_empresa = PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO) c
            ON c.id_represtamo = a.id_represtamo
         ORDER BY a.fecha_an DESC, a.id_represtamo
       )
 WHERE ROWNUM <= 50;

-- Query 6: AN por link vencido (R2) - verificar que cumplian la regla:
--          estado previo dentro del parametro y fin de mes de
--          FECHA_PROCESO ya alcanzado al momento de anular
WITH bit AS (
    SELECT b.id_represtamo,
           b.id_bitacora,
           b.codigo_estado,
           b.observaciones,
           b.fecha_adicion,
           LAG(b.codigo_estado)
               OVER (PARTITION BY b.id_represtamo
                     ORDER BY b.id_bitacora) estado_anterior
      FROM PR.PR_BITACORA_REPRESTAMO b
     WHERE b.codigo_empresa = PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
)
SELECT a.estado_anterior,
       CASE WHEN a.estado_anterior IN
                 (SELECT column_value
                    FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS(
                         'ESTADOS_ANULAR_REPRESTAMOS_POR_NO_CONCLUIR_PROCESO')))
            THEN 'SI' ELSE 'NO'
       END estado_en_parametro,
       COUNT(*) total,
       MIN(TRUNC(a.fecha_adicion) - TRUNC(LAST_DAY(r.fecha_proceso))) min_dias_tras_fin_mes,
       MAX(TRUNC(a.fecha_adicion) - TRUNC(LAST_DAY(r.fecha_proceso))) max_dias_tras_fin_mes
  FROM bit a
  JOIN PR.PR_REPRESTAMOS r
    ON r.codigo_empresa = PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
   AND r.id_represtamo  = a.id_represtamo
 WHERE a.codigo_estado = 'AN'
   AND a.observaciones LIKE '%Link Vencido%'
   AND a.fecha_adicion >= ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -2)
 GROUP BY a.estado_anterior,
          CASE WHEN a.estado_anterior IN
                    (SELECT column_value
                       FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS(
                            'ESTADOS_ANULAR_REPRESTAMOS_POR_NO_CONCLUIR_PROCESO')))
               THEN 'SI' ELSE 'NO'
          END
 ORDER BY total DESC;

-- Query 7: foto actual - represtamos hoy en AN con su ultimo motivo
--          (universo vigente, independiente de la ventana)
WITH ultimo_an AS (
    SELECT b.id_represtamo,
           MAX(b.id_bitacora) id_bitacora
      FROM PR.PR_BITACORA_REPRESTAMO b
     WHERE b.codigo_empresa = PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
       AND b.codigo_estado = 'AN'
     GROUP BY b.id_represtamo
)
SELECT b.observaciones              motivo,
       TRUNC(b.fecha_adicion, 'MM') mes_anulacion,
       COUNT(*)                     total
  FROM PR.PR_REPRESTAMOS r
  JOIN ultimo_an u
    ON u.id_represtamo = r.id_represtamo
  JOIN PR.PR_BITACORA_REPRESTAMO b
    ON b.codigo_empresa = PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
   AND b.id_represtamo  = u.id_represtamo
   AND b.id_bitacora    = u.id_bitacora
 WHERE r.codigo_empresa = PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
   AND r.estado = 'AN'
 GROUP BY b.observaciones, TRUNC(b.fecha_adicion, 'MM')
 ORDER BY mes_anulacion DESC, total DESC;
