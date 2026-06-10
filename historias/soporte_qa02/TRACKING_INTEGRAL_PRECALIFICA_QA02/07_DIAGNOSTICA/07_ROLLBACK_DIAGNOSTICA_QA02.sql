-- =====================================================================
-- Reversa de la capa DIAGNOSTICA
-- Entorno: QA02. Ejecutar como script (F5) en Toad.
-- Borra SOLO las filas TIPO_MEDICION='DIAGNOSTICA' de la ULTIMA
-- ejecucion (las REAL de los Incrementos A/B/C no se tocan).
-- Para otra corrida, reemplazar la subconsulta de la ultima ejecucion
-- por el ID_EJECUCION literal.
-- =====================================================================

PROMPT Filas DIAGNOSTICA de la ultima ejecucion ANTES de borrar

SELECT COUNT(*) filas_diagnostica
  FROM PR.PR_JOB_PRECALIFICA_FILTRO_TRACK f
 WHERE f.tipo_medicion = 'DIAGNOSTICA'
   AND f.id_ejecucion = (SELECT id_ejecucion
                           FROM (SELECT id_ejecucion
                                   FROM PR.PR_JOB_PRECALIFICA_TRACK
                                  WHERE id_paso = 0
                                  ORDER BY fecha_inicio DESC)
                          WHERE ROWNUM = 1);

DELETE FROM PR.PR_JOB_PRECALIFICA_FILTRO_TRACK f
 WHERE f.tipo_medicion = 'DIAGNOSTICA'
   AND f.id_ejecucion = (SELECT id_ejecucion
                           FROM (SELECT id_ejecucion
                                   FROM PR.PR_JOB_PRECALIFICA_TRACK
                                  WHERE id_paso = 0
                                  ORDER BY fecha_inicio DESC)
                          WHERE ROWNUM = 1);

COMMIT;

PROMPT Filas DIAGNOSTICA de la ultima ejecucion DESPUES de borrar (esperado: 0)

SELECT COUNT(*) filas_diagnostica
  FROM PR.PR_JOB_PRECALIFICA_FILTRO_TRACK f
 WHERE f.tipo_medicion = 'DIAGNOSTICA'
   AND f.id_ejecucion = (SELECT id_ejecucion
                           FROM (SELECT id_ejecucion
                                   FROM PR.PR_JOB_PRECALIFICA_TRACK
                                  WHERE id_paso = 0
                                  ORDER BY fecha_inicio DESC)
                          WHERE ROWNUM = 1);
