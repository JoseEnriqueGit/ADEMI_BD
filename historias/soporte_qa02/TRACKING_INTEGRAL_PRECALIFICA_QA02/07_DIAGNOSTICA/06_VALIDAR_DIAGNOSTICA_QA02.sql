-- =====================================================================
-- Validacion de la capa DIAGNOSTICA
-- Entorno: QA02. Solo lectura. Ejecutar DESPUES de los wrappers 01-05.
-- Uso: cursor dentro de cada query y F9 (Data Grid).
-- Esperado:
--   - Query 1: 5 flujos con filas DIAGNOSTICA; las REAL siguen en 31.
--   - Query 2: el funnel del cursor por flujo es monotono decreciente.
--   - Query 3: DIAG_LOTE (pasan) ~= BRUTO_C (pertenencia real del
--     Incremento C). Diferencias = deriva temporal entre el job y el
--     diagnostico (datos vivos), no un error del tracker.
-- =====================================================================

-- Query 1: cobertura - filas por flujo/tipo de medicion de la ultima ejecucion
WITH ultima AS (
    SELECT id_ejecucion
      FROM (
            SELECT id_ejecucion
              FROM PR.PR_JOB_PRECALIFICA_TRACK
             WHERE id_paso = 0
             ORDER BY fecha_inicio DESC
           )
     WHERE ROWNUM = 1
)
SELECT t.tipo_medicion,
       t.flujo,
       COUNT(*) filas,
       MIN(t.fecha_registro) primera_fila,
       MAX(t.fecha_registro) ultima_fila
  FROM PR.PR_JOB_PRECALIFICA_FILTRO_TRACK t
  JOIN ultima u ON u.id_ejecucion = t.id_ejecucion
 GROUP BY t.tipo_medicion, t.flujo
 ORDER BY t.tipo_medicion, t.flujo;

-- Query 2: funnel del cursor por flujo (solo DIAGNOSTICA)
WITH ultima AS (
    SELECT id_ejecucion
      FROM (
            SELECT id_ejecucion
              FROM PR.PR_JOB_PRECALIFICA_TRACK
             WHERE id_paso = 0
             ORDER BY fecha_inicio DESC
           )
     WHERE ROWNUM = 1
)
SELECT t.flujo,
       t.fase,
       t.orden_filtro,
       t.codigo_filtro,
       t.descripcion,
       t.candidatos_antes,
       t.candidatos_pasan,
       t.candidatos_descartados
  FROM PR.PR_JOB_PRECALIFICA_FILTRO_TRACK t
  JOIN ultima u ON u.id_ejecucion = t.id_ejecucion
 WHERE t.tipo_medicion = 'DIAGNOSTICA'
 ORDER BY t.flujo, t.orden_filtro;

-- Query 3: cruce de las tres fuentes por flujo
--   DIAG_LOTE (simulacion del cursor) vs BRUTO_C (pertenencia real del
--   Incremento C) vs NETO_B (RE sobreviviente segun Capa B)
WITH ultima AS (
    SELECT id_ejecucion
      FROM (
            SELECT id_ejecucion
              FROM PR.PR_JOB_PRECALIFICA_TRACK
             WHERE id_paso = 0
             ORDER BY fecha_inicio DESC
           )
     WHERE ROWNUM = 1
),
diag AS (
    SELECT t.flujo,
           MAX(CASE WHEN t.codigo_filtro = 'DIAG_LOTE'
                    THEN t.candidatos_pasan END) diag_lote_pasan
      FROM PR.PR_JOB_PRECALIFICA_FILTRO_TRACK t
      JOIN ultima u ON u.id_ejecucion = t.id_ejecucion
     WHERE t.tipo_medicion = 'DIAGNOSTICA'
     GROUP BY t.flujo
),
bruto_c AS (
    SELECT c.flujo, COUNT(*) bruto_insertado
      FROM PR.PR_JOB_PRECALIFICA_CANDIDATO_TRACK c
      JOIN ultima u ON u.id_ejecucion = c.id_ejecucion
     WHERE c.flujo <> 'CIERRE'
     GROUP BY c.flujo
),
neto_b AS (
    SELECT t.flujo,
           TO_NUMBER(SUBSTR(t.parametros,
                            INSTR(t.parametros, 'NETO=') + 5)) neto_capa_b
      FROM PR.PR_JOB_PRECALIFICA_FILTRO_TRACK t
      JOIN ultima u ON u.id_ejecucion = t.id_ejecucion
     WHERE t.codigo_filtro = 'RE_ACUMULADO_TRAS_FLUJO'
)
SELECT d.flujo,
       d.diag_lote_pasan,
       bc.bruto_insertado bruto_c,
       nb.neto_capa_b,
       d.diag_lote_pasan - NVL(bc.bruto_insertado, 0) deriva_diag_vs_real
  FROM diag d
  LEFT JOIN bruto_c bc ON bc.flujo = d.flujo
  LEFT JOIN neto_b nb ON nb.flujo = d.flujo
 ORDER BY d.flujo;
