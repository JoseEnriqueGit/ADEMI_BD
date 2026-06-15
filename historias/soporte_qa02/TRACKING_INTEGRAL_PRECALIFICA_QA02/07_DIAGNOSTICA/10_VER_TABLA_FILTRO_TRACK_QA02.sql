-- =====================================================================
-- Ver el desglose por filtro DIRECTO de la tabla de tracking.
-- Tabla: PR.PR_JOB_PRECALIFICA_FILTRO_TRACK
-- Entorno: QA02. Solo lectura. Ejecutar cada query con F9 (Data Grid).
-- =====================================================================

--------------------------------------------------------------------------------
-- Query A (F9): ejecuciones disponibles en la tabla (para elegir cual mirar).
--------------------------------------------------------------------------------
SELECT f.id_ejecucion,
       MIN(f.fecha_registro) desde,
       MAX(f.fecha_registro) hasta,
       COUNT(*) total_filas,
       COUNT(CASE WHEN f.tipo_medicion = 'REAL' THEN 1 END) filas_real,
       COUNT(CASE WHEN f.tipo_medicion = 'DIAGNOSTICA' THEN 1 END) filas_diagnostica
  FROM PR.PR_JOB_PRECALIFICA_FILTRO_TRACK f
 GROUP BY f.id_ejecucion
 ORDER BY MAX(f.fecha_registro) DESC;

--------------------------------------------------------------------------------
-- Query B (F9): desglose por filtro de CADA procedimiento, ULTIMA ejecucion.
--   Cada fila = un filtro del cursor / post-cursor, con cuantos entraban,
--   cuantos pasaron y cuantos descarto. Agrupado por procedimiento (FLUJO).
--------------------------------------------------------------------------------
SELECT f.flujo,
       f.fase,
       f.orden_filtro,
       f.codigo_filtro,
       f.descripcion,
       f.candidatos_antes,
       f.candidatos_pasan,
       f.candidatos_descartados,
       f.creditos_descartados,
       f.clientes_descartados,
       f.tipo_medicion,
       f.valor_lote,
       f.fecha_corte
  FROM PR.PR_JOB_PRECALIFICA_FILTRO_TRACK f
 WHERE f.id_ejecucion = (SELECT id_ejecucion
                           FROM (SELECT id_ejecucion
                                   FROM PR.PR_JOB_PRECALIFICA_TRACK
                                  WHERE id_paso = 0
                                  ORDER BY fecha_inicio DESC)
                          WHERE ROWNUM = 1)
   AND f.tipo_medicion = 'DIAGNOSTICA'   -- quitar esta linea para ver tambien las REAL
 ORDER BY f.flujo, f.orden_filtro;

--------------------------------------------------------------------------------
-- Query C (F9): igual que B pero para UNA ejecucion concreta.
--   Reemplazar el ID por uno de los que devuelve la Query A.
--------------------------------------------------------------------------------
SELECT f.flujo,
       f.fase,
       f.orden_filtro,
       f.codigo_filtro,
       f.descripcion,
       f.candidatos_antes,
       f.candidatos_pasan,
       f.candidatos_descartados,
       f.tipo_medicion
  FROM PR.PR_JOB_PRECALIFICA_FILTRO_TRACK f
 WHERE f.id_ejecucion = '5414C315EE2373B7E063140311ACD22C'
 ORDER BY f.tipo_medicion, f.flujo, f.orden_filtro;

--------------------------------------------------------------------------------
-- Query D (F9): desglose DIAGNOSTICA en el ORDEN REAL DE EJECUCION del job.
--   Entre procedimientos respeta el orden en que el job los corrio (pasos
--   2..6 en P_Carga_Precalifica_Cancelado); dentro de cada uno, por
--   orden_filtro (cursor -> lote -> post-cursor -> cleanup).
--   Nota: el orden cronologico exacto del job completo (con horas y
--   duraciones por paso) esta en PR.PR_JOB_PRECALIFICA_TRACK (id_paso 0..14).
--------------------------------------------------------------------------------
SELECT f.flujo,
       f.fase,
       f.orden_filtro,
       f.codigo_filtro,
       f.descripcion,
       f.candidatos_antes,
       f.candidatos_pasan,
       f.candidatos_descartados
  FROM PR.PR_JOB_PRECALIFICA_FILTRO_TRACK f
 WHERE f.id_ejecucion = (SELECT id_ejecucion
                           FROM (SELECT id_ejecucion
                                   FROM PR.PR_JOB_PRECALIFICA_TRACK
                                  WHERE id_paso = 0
                                  ORDER BY fecha_inicio DESC)
                          WHERE ROWNUM = 1)
   AND f.tipo_medicion = 'DIAGNOSTICA'
 ORDER BY CASE f.flujo
            WHEN 'Precalifica_Represtamo'             THEN 2
            WHEN 'Precalifica_Represtamo_fiadores'    THEN 3
            WHEN 'Precalifica_Represtamo_fiadores_hi' THEN 4
            WHEN 'Precalifica_Repre_Cancelado'        THEN 5
            WHEN 'Precalifica_Repre_Cancelado_hi'     THEN 6
            ELSE 99                                   -- TOTAL (XCORE) al final
          END,
          f.orden_filtro;
