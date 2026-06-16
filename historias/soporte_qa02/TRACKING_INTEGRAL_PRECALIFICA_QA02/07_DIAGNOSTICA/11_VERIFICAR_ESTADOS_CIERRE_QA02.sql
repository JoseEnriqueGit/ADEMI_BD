-- =====================================================================
-- Verificar los estados de los candidatos que pasaron al CIERRE,
-- contra el estado vigente en PR.PR_REPRESTAMOS.
-- Entorno: QA02. Solo lectura. Ejecutar cada query con F9 (Data Grid).
--
-- Fuente: PR.PR_JOB_PRECALIFICA_CANDIDATO_TRACK (Capa C, Incremento B).
--   Las filas FLUJO='CIERRE' = la cohorte que llego al loop final, con su
--   RESULTADO_ULTIMO (NP/CP/RXT/AN) capturado en la corrida.
--
-- Idea: cada candidato del cierre = un represtamo (mismo ID_REPRESTAMO).
--   Query A confirma que las cantidades calzan. Query B muestra en que
--   estado estaban al cierre vs en que estado estan AHORA (sirve para ver
--   como evolucionaron despues del job: NP->CRN, NP->AN por link vencido, etc.).
--
-- Por defecto apuntan a la ULTIMA ejecucion. Para fijar una corrida
-- concreta, reemplazar el bloque de la ULTIMA ejecucion por el ID literal,
-- p.ej.:  AND c.id_ejecucion = '5414C315EE2373B7E063140311ACD22C'
-- =====================================================================

--------------------------------------------------------------------------------
-- Query A (F9): cuadre de cantidades (esperado: ya_no_existen = 0).
--------------------------------------------------------------------------------
SELECT COUNT(*)                          AS candidatos_cierre,
       COUNT(r.id_represtamo)            AS con_represtamo_existente,
       COUNT(*) - COUNT(r.id_represtamo) AS ya_no_existen
  FROM PR.PR_JOB_PRECALIFICA_CANDIDATO_TRACK c
  LEFT JOIN PR.PR_REPRESTAMOS r
    ON r.id_represtamo = c.id_represtamo
 WHERE c.flujo = 'CIERRE'
   AND c.id_ejecucion = (SELECT id_ejecucion
                           FROM (SELECT id_ejecucion
                                   FROM PR.PR_JOB_PRECALIFICA_TRACK
                                  WHERE id_paso = 0
                                  ORDER BY fecha_inicio DESC)
                          WHERE ROWNUM = 1);

--------------------------------------------------------------------------------
-- Query B (F9): estado al cierre (tracking) vs estado actual (PR_REPRESTAMOS).
--------------------------------------------------------------------------------
SELECT c.resultado_ultimo              AS estado_al_cierre_tracking,
       NVL(r.estado, '(ya no existe)') AS estado_actual,
       COUNT(*)                        AS cantidad
  FROM PR.PR_JOB_PRECALIFICA_CANDIDATO_TRACK c
  LEFT JOIN PR.PR_REPRESTAMOS r
    ON r.id_represtamo = c.id_represtamo
 WHERE c.flujo = 'CIERRE'
   AND c.id_ejecucion = (SELECT id_ejecucion
                           FROM (SELECT id_ejecucion
                                   FROM PR.PR_JOB_PRECALIFICA_TRACK
                                  WHERE id_paso = 0
                                  ORDER BY fecha_inicio DESC)
                          WHERE ROWNUM = 1)
 GROUP BY c.resultado_ultimo, r.estado
 ORDER BY c.resultado_ultimo, r.estado;

--------------------------------------------------------------------------------
-- Query C (F9): detalle individual (hasta 200) de los que CAMBIARON de estado
--   desde el cierre, para revisarlos uno por uno.
--------------------------------------------------------------------------------
SELECT *
  FROM (
        SELECT c.id_represtamo,
               c.no_credito,
               c.codigo_cliente,
               c.resultado_ultimo AS estado_al_cierre,
               r.estado           AS estado_actual,
               c.fecha_registro   AS fecha_cierre
          FROM PR.PR_JOB_PRECALIFICA_CANDIDATO_TRACK c
          LEFT JOIN PR.PR_REPRESTAMOS r
            ON r.id_represtamo = c.id_represtamo
         WHERE c.flujo = 'CIERRE'
           AND c.id_ejecucion = (SELECT id_ejecucion
                                   FROM (SELECT id_ejecucion
                                           FROM PR.PR_JOB_PRECALIFICA_TRACK
                                          WHERE id_paso = 0
                                          ORDER BY fecha_inicio DESC)
                                  WHERE ROWNUM = 1)
           AND NVL(r.estado, '(NULL)') <> c.resultado_ultimo
         ORDER BY c.resultado_ultimo, r.estado, c.id_represtamo
       )
 WHERE ROWNUM <= 200;
