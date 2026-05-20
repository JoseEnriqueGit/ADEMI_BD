--------------------------------------------------------------------------------
-- QA02 - Validaciones RXT / PA_DETALLADO_DE08
-- Caso: lote de represtamos que quedo en RXT desde 2026-05-11
-- Objetivo: reproducir el diagnostico sin modificar datos.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 1. Resumen del lote por estado y avance de flujo
--------------------------------------------------------------------------------
WITH lote AS (
  SELECT r.codigo_empresa, r.id_represtamo, r.no_credito credito_origen,
         r.codigo_cliente, r.estado, r.fecha_adicion
    FROM pr.pr_represtamos r
   WHERE r.fecha_adicion >= DATE '2026-05-11'
     AND r.fecha_adicion <  DATE '2026-05-14'
),
canales AS (
  SELECT codigo_empresa, id_represtamo, COUNT(*) cnt
    FROM pr.pr_canales_represtamo
   GROUP BY codigo_empresa, id_represtamo
),
opciones AS (
  SELECT codigo_empresa, id_represtamo, COUNT(*) cnt
    FROM pr.pr_opciones_represtamo
   GROUP BY codigo_empresa, id_represtamo
),
cred_nuevo AS (
  SELECT codigo_empresa, no_credito, COUNT(*) cnt
    FROM pr.pr_creditos
   GROUP BY codigo_empresa, no_credito
)
SELECT l.estado,
       COUNT(*) total,
       SUM(CASE WHEN s.id_represtamo IS NOT NULL THEN 1 ELSE 0 END) con_solicitud,
       SUM(CASE WHEN NVL(c.cnt,0) > 0 THEN 1 ELSE 0 END) con_canal,
       SUM(CASE WHEN s.tipo_credito IS NOT NULL THEN 1 ELSE 0 END) con_tipo_credito,
       SUM(CASE WHEN NVL(o.cnt,0) > 0 THEN 1 ELSE 0 END) con_opciones,
       SUM(CASE WHEN s.no_credito IS NOT NULL THEN 1 ELSE 0 END) solicitud_con_credito_nuevo,
       SUM(CASE WHEN NVL(cn.cnt,0) > 0 THEN 1 ELSE 0 END) existe_en_pr_creditos
  FROM lote l
  LEFT JOIN pr.pr_solicitud_represtamo s
    ON s.codigo_empresa = l.codigo_empresa
   AND s.id_represtamo = l.id_represtamo
  LEFT JOIN canales c
    ON c.codigo_empresa = l.codigo_empresa
   AND c.id_represtamo = l.id_represtamo
  LEFT JOIN opciones o
    ON o.codigo_empresa = l.codigo_empresa
   AND o.id_represtamo = l.id_represtamo
  LEFT JOIN cred_nuevo cn
    ON cn.codigo_empresa = l.codigo_empresa
   AND cn.no_credito = s.no_credito
 GROUP BY l.estado
 ORDER BY total DESC;

--------------------------------------------------------------------------------
-- 2. Errores del paquete por codigo ORA
--------------------------------------------------------------------------------
SELECT e.programunit,
       REGEXP_SUBSTR(e.errordescription, 'ORA-[0-9]+') ora_code,
       COUNT(*) total,
       MIN(e.errordate) desde,
       MAX(e.errordate) hasta
  FROM ia.log_error e
 WHERE e.errordate >= DATE '2026-05-11'
   AND e.errordate <  DATE '2026-05-14'
   AND e.owner = 'PR'
   AND e.packagename = 'PR_PKG_REPRESTAMOS'
 GROUP BY e.programunit, REGEXP_SUBSTR(e.errordescription, 'ORA-[0-9]+')
 ORDER BY hasta DESC;

--------------------------------------------------------------------------------
-- 3. Buscar evidencia de ORA-01555
--------------------------------------------------------------------------------
SELECT e.iderror,
       e.errordate,
       e.owner,
       e.packagename,
       e.programunit,
       e.errordescription
  FROM ia.log_error e
 WHERE e.errordate >= DATE '2026-05-11'
   AND e.errordate <  DATE '2026-05-14'
   AND (UPPER(e.errordescription) LIKE '%ORA-01555%'
        OR UPPER(e.errordescription) LIKE '%SNAPSHOT TOO OLD%'
        OR DBMS_LOB.INSTR(e.errortrace, 'ORA-01555') > 0)
 ORDER BY e.errordate DESC;

--------------------------------------------------------------------------------
-- 4. Detalle de errores de precalificacion
--------------------------------------------------------------------------------
SELECT e.iderror,
       e.errordate,
       e.programunit,
       e.errordescription,
       DBMS_LOB.SUBSTR(e.errortrace, 4000, 1) errortrace
  FROM ia.log_error e
 WHERE e.errordate >= DATE '2026-05-11'
   AND e.errordate <  DATE '2026-05-14'
   AND e.owner = 'PR'
   AND e.packagename = 'PR_PKG_REPRESTAMOS'
   AND e.programunit IN ('Actualiza_Precalificacion', 'Precalifica_Represtamo')
 ORDER BY e.errordate DESC;

--------------------------------------------------------------------------------
-- 5. Validar monto esperado vs monto preaprobado que quedo en cero
--------------------------------------------------------------------------------
SELECT r.codigo_precalificacion,
       r.dias_atraso,
       cr.codigo_represtamo,
       cr.factor,
       COUNT(*) total,
       MIN(r.mto_credito_actual) min_mto_actual,
       MAX(r.mto_credito_actual) max_mto_actual,
       MIN(r.mto_preaprobado) min_mto_preaprobado,
       MAX(r.mto_preaprobado) max_mto_preaprobado,
       MIN(r.mto_credito_actual * cr.factor) min_esperado,
       MAX(r.mto_credito_actual * cr.factor) max_esperado
  FROM pr.pr_represtamos r
  LEFT JOIN pr.pr_codigos_represtamo cr
    ON cr.codigo_empresa = r.codigo_empresa
   AND r.dias_atraso BETWEEN cr.desde AND cr.hasta
 WHERE r.fecha_adicion >= DATE '2026-05-11'
   AND r.fecha_adicion <  DATE '2026-05-14'
   AND r.estado = 'RXT'
 GROUP BY r.codigo_precalificacion, r.dias_atraso, cr.codigo_represtamo, cr.factor
 ORDER BY total DESC;

--------------------------------------------------------------------------------
-- 6. Registros que devolverian NULL en la subconsulta de Actualiza_Precalificacion
--------------------------------------------------------------------------------
SELECT r.id_represtamo,
       r.no_credito,
       r.codigo_cliente,
       r.mto_credito_actual,
       r.mto_preaprobado,
       (
         SELECT MAX(p.fecha_corte)
           FROM pa.pa_detallado_de08 p
          WHERE p.fuente = 'PR'
            AND p.no_credito = r.no_credito
            AND p.codigo_cliente = r.codigo_cliente
       ) fecha_corte_encontrada,
       (
         SELECT d.monto_desembolsado
           FROM pa.pa_detallado_de08 d
          WHERE d.fuente = 'PR'
            AND d.no_credito = r.no_credito
            AND d.codigo_cliente = r.codigo_cliente
            AND d.fecha_corte = (
                SELECT MAX(p.fecha_corte)
                  FROM pa.pa_detallado_de08 p
                 WHERE p.fuente = 'PR'
                   AND p.no_credito = r.no_credito
                   AND p.codigo_cliente = r.codigo_cliente
            )
       ) monto_de08
  FROM pr.pr_represtamos r
 WHERE r.fecha_adicion >= DATE '2026-05-11'
   AND r.fecha_adicion <  DATE '2026-05-14'
   AND r.estado = 'RXT'
   AND (
       SELECT d.monto_desembolsado
         FROM pa.pa_detallado_de08 d
        WHERE d.fuente = 'PR'
          AND d.no_credito = r.no_credito
          AND d.codigo_cliente = r.codigo_cliente
          AND d.fecha_corte = (
              SELECT MAX(p.fecha_corte)
                FROM pa.pa_detallado_de08 p
               WHERE p.fuente = 'PR'
                 AND p.no_credito = r.no_credito
                 AND p.codigo_cliente = r.codigo_cliente
          )
   ) IS NULL;

--------------------------------------------------------------------------------
-- 7. Ver duplicidad de ID_REPRESTAMO para creditos que disparan el problema
--------------------------------------------------------------------------------
SELECT r.no_credito,
       r.codigo_cliente,
       COUNT(*) total_represtamos,
       LISTAGG(r.id_represtamo, ', ') WITHIN GROUP (ORDER BY r.id_represtamo) ids,
       MIN(r.fecha_adicion) primera_fecha,
       MAX(r.fecha_adicion) ultima_fecha
  FROM pr.pr_represtamos r
 WHERE r.fecha_adicion >= DATE '2026-05-11'
   AND r.fecha_adicion <  DATE '2026-05-14'
   AND r.estado = 'RXT'
   AND r.no_credito IN (1493368, 1716452)
 GROUP BY r.no_credito, r.codigo_cliente;

--------------------------------------------------------------------------------
-- 8. Confirmar el cliente real de esos creditos en PA_DETALLADO_DE08
--------------------------------------------------------------------------------
SELECT fuente,
       no_credito,
       codigo_cliente,
       COUNT(*) total,
       MIN(fecha_corte) min_fecha,
       MAX(fecha_corte) max_fecha,
       MIN(monto_desembolsado) min_monto,
       MAX(monto_desembolsado) max_monto
  FROM pa.pa_detallado_de08
 WHERE no_credito IN (1493368, 1716452)
 GROUP BY fuente, no_credito, codigo_cliente
 ORDER BY no_credito, fuente, codigo_cliente;

--------------------------------------------------------------------------------
-- 9. Simulacion con DBMS_OUTPUT del punto donde abortaria
--------------------------------------------------------------------------------
SET SERVEROUTPUT ON SIZE UNLIMITED;

DECLARE
  v_monto NUMBER;
  v_ok    NUMBER := 0;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Simulando Actualiza_Precalificacion linea 2704');

  FOR y IN (
    SELECT r.id_represtamo, r.no_credito, r.codigo_cliente
      FROM pr.pr_represtamos r
     WHERE r.fecha_adicion >= DATE '2026-05-11'
       AND r.fecha_adicion <  DATE '2026-05-14'
       AND r.estado = 'RXT'
     ORDER BY r.id_represtamo
  ) LOOP
    SELECT (
      SELECT d.monto_desembolsado
        FROM pa.pa_detallado_de08 d
       WHERE d.fuente = 'PR'
         AND d.no_credito = y.no_credito
         AND d.codigo_cliente = y.codigo_cliente
         AND d.fecha_corte = (
             SELECT MAX(p.fecha_corte)
               FROM pa.pa_detallado_de08 p
              WHERE p.fuente = 'PR'
                AND p.no_credito = y.no_credito
                AND p.codigo_cliente = y.codigo_cliente
         )
    )
    INTO v_monto
    FROM dual;

    IF v_monto IS NULL THEN
      DBMS_OUTPUT.PUT_LINE('ABORTARIA AQUI -> ID=' || y.id_represtamo ||
                           ' NO_CREDITO=' || y.no_credito ||
                           ' CODIGO_CLIENTE=' || y.codigo_cliente ||
                           ' MONTO_DE08=NULL');
      RAISE_APPLICATION_ERROR(-20001, 'Simulacion: ORA-01407 por monto null');
    ELSE
      v_ok := v_ok + 1;
      IF v_ok <= 5 THEN
        DBMS_OUTPUT.PUT_LINE('OK -> ID=' || y.id_represtamo ||
                             ' NO_CREDITO=' || y.no_credito ||
                             ' MONTO_DE08=' || v_monto);
      END IF;
    END IF;
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('LLEGARIA al calculo de MTO_PREAPROBADO');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('SALIO DEL LOOP: ' || SQLERRM);
    DBMS_OUTPUT.PUT_LINE('NO LLEGARIA al bloque que calcula MTO_PREAPROBADO');
END;
/

--------------------------------------------------------------------------------
-- 10. Validar efecto del fix propuesto en el cursor inicial
-- Debe excluir los creditos cuyo DE08 pertenece a otro cliente.
--------------------------------------------------------------------------------
SELECT a.no_credito,
       a.codigo_cliente cliente_credito,
       b.codigo_cliente cliente_de08,
       b.fecha_corte,
       b.monto_desembolsado
  FROM pr.pr_creditos a
  JOIN pa.pa_detallado_de08 b
    ON b.no_credito = a.no_credito
   AND b.tipo_credito = a.tipo_credito
   AND b.fuente = 'PR'
   AND b.codigo_empresa = a.codigo_empresa
   AND b.codigo_cliente = a.codigo_cliente
 WHERE a.no_credito IN (1493368, 1716452);

