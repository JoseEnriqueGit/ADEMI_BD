-- =====================================================================
-- Reversa de la capa DIAGNOSTICA
-- Entorno: QA02. Ejecutar cada sentencia con F9 en Toad.
-- Borra SOLO las filas TIPO_MEDICION='DIAGNOSTICA' de la ULTIMA
-- ejecucion (las REAL de los Incrementos A/B/C no se tocan).
-- Para otra corrida, reemplazar la subconsulta de la ultima ejecucion
-- por el ID_EJECUCION literal.
-- =====================================================================

-- PASO 1 (F9): contar antes de borrar.
SELECT COUNT(*) filas_diagnostica
  FROM PR.PR_JOB_PRECALIFICA_FILTRO_TRACK f
 WHERE f.tipo_medicion = 'DIAGNOSTICA'
   AND f.id_ejecucion = (SELECT id_ejecucion
                           FROM (SELECT id_ejecucion
                                   FROM PR.PR_JOB_PRECALIFICA_TRACK
                                  WHERE id_paso = 0
                                  ORDER BY fecha_inicio DESC)
                          WHERE ROWNUM = 1);

-- PASO 2 (F9): borrar sin confirmar.
DELETE FROM PR.PR_JOB_PRECALIFICA_FILTRO_TRACK f
 WHERE f.tipo_medicion = 'DIAGNOSTICA'
   AND f.id_ejecucion = (SELECT id_ejecucion
                           FROM (SELECT id_ejecucion
                                   FROM PR.PR_JOB_PRECALIFICA_TRACK
                                  WHERE id_paso = 0
                                  ORDER BY fecha_inicio DESC)
                          WHERE ROWNUM = 1);

-- PASO 3 (F9): verificar antes de confirmar. Esperado: 0.
SELECT COUNT(*) filas_diagnostica
  FROM PR.PR_JOB_PRECALIFICA_FILTRO_TRACK f
 WHERE f.tipo_medicion = 'DIAGNOSTICA'
   AND f.id_ejecucion = (SELECT id_ejecucion
                           FROM (SELECT id_ejecucion
                                   FROM PR.PR_JOB_PRECALIFICA_TRACK
                                  WHERE id_paso = 0
                                  ORDER BY fecha_inicio DESC)
                          WHERE ROWNUM = 1);

-- PASO 4 (F9): confirmar solo si el conteo anterior es 0.
COMMIT;
