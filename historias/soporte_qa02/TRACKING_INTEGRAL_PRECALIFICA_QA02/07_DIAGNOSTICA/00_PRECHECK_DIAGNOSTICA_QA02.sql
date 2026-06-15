-- =====================================================================
-- Precheck de ejecucion para la capa DIAGNOSTICA
-- Entorno: QA02. Solo lectura.
-- METODO: colocar el cursor dentro del SELECT y ejecutar con F9.
-- El resultado se muestra en Data Grid. No usar F5.
-- =====================================================================

SELECT SYSTIMESTAMP fecha_precheck,
       SYS_CONTEXT('USERENV', 'DB_NAME') base_datos,
       SYS_CONTEXT('USERENV', 'SESSION_USER') usuario,
       (SELECT MAX(valor)
          FROM PA.PA_PARAMETROS_MVP
         WHERE codigo_empresa = 1
           AND codigo_mvp = 'REPRESTAMOS'
           AND codigo_parametro = 'TRACK_PRECALIFICA_DETALLE_CURSOR')
           gate_detalle_cursor,
       (SELECT MAX(valor)
          FROM PA.PA_PARAMETROS_MVP
         WHERE codigo_empresa = 1
           AND codigo_mvp = 'REPRESTAMOS'
           AND codigo_parametro = 'LOTE_DE_CARAGA_REPRESTAMO')
           valor_lote,
       (SELECT id_ejecucion
          FROM (
                SELECT id_ejecucion
                  FROM PR.PR_JOB_PRECALIFICA_TRACK
                 WHERE id_paso = 0
                 ORDER BY fecha_inicio DESC
               )
         WHERE ROWNUM = 1)
           ultima_ejecucion,
       (SELECT MAX(status)
          FROM ALL_OBJECTS
         WHERE owner = 'PR'
           AND object_name = 'PR_PKG_REPRESTAMOS'
           AND object_type = 'PACKAGE BODY')
           estado_package_body
  FROM dual;
