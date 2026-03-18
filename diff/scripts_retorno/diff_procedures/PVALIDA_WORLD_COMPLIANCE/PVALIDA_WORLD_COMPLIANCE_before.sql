-- PROCEDURE PVALIDA_WORLD_COMPLIANCE (before)
PROCEDURE PVALIDA_WORLD_COMPLIANCE IS CURSOR CARGAR_WORLD_COMPLIANCE IS
SELECT r.id_represtamo,
   r.no_credito,
   pf.primer_apellido,
   pf.primer_nombre,
   b.numero_identificacion
FROM PR_REPRESTAMOS r
   LEFT JOIN PERSONAS_FISICAS pf ON pf.cod_per_fisica = r.codigo_cliente
   LEFT JOIN PR_SOLICITUD_REPRESTAMO s ON s.id_represtamo = r.id_represtamo
   LEFT JOIN CLIENTES_B2000 b ON b.codigo_cliente = r.codigo_cliente
WHERE r.estado = 'RE'
   AND r.world_compliance IS NULL
   AND ROWNUM <= TO_NUMBER(
      PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('LOTE_PROCESO_WORLD_COMPLIANCE')
   );
CURSOR CUR_UPDATE_CREADOS IS
SELECT a.ROWID id,
   a.id_represtamo,
   a.codigo_cliente,
   a.estado,
   s.world_compliance
FROM PR.PR_REPRESTAMOS a
   LEFT JOIN PR_SOLICITUD_REPRESTAMO s ON s.id_represtamo = a.id_represtamo
WHERE a.estado = 'RE';
vTotal_Carga NUMBER(10);
vCantidad_Procesar NUMBER(10);
VALOR NUMBER;
pMensaje VARCHAR2(500);
BEGIN
SELECT COUNT(*) INTO vTotal_Carga
FROM PR.PR_REPRESTAMOS
WHERE estado = 'RE';
vCantidad_Procesar := ROUND(
   vTotal_Carga / TO_NUMBER(
      PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('LOTE_PROCESO_WORLD_COMPLIANCE')
   )
) + 1;
FOR i IN 1..vCantidad_Procesar LOOP FOR a IN CARGAR_WORLD_COMPLIANCE LOOP BEGIN PR.PR_PKG_REPRESTAMOS.OBT_WORLD_COMPLIANCE(
   REPLACE(a.numero_identificacion, '-'),
   UTL_URL.ESCAPE(a.primer_nombre),
   UTL_URL.ESCAPE(a.primer_apellido),
   VALOR,
   pMensaje
);
IF VALOR IS NULL THEN VALOR := 0;
END IF;
UPDATE PR.PR_SOLICITUD_REPRESTAMO
SET world_compliance = VALOR
WHERE id_represtamo = a.id_represtamo;
COMMIT;
-- before: commit por registro
EXCEPTION
WHEN OTHERS THEN NULL;
-- Manejo original omitido
END;
END LOOP;
END LOOP;
FOR a IN CUR_UPDATE_CREADOS LOOP IF NVL(a.world_compliance, 0) > TO_NUMBER(
   PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('WORLD_COMPLIANCE')
) THEN
UPDATE PR.PR_REPRESTAMOS
SET estado = 'RXW'
WHERE id_represtamo = a.id_represtamo;
PR.PR_PKG_REPRESTAMOS.P_GENERAR_BITACORA(
   a.id_represtamo,
   NULL,
   'RXW',
   NULL,
   'Credito cancelado por World Compliance',
   USER
);
COMMIT;
-- before: commit dentro del loop
END IF;
END LOOP;
COMMIT;
-- before: commit global al finalizar
END PVALIDA_WORLD_COMPLIANCE;