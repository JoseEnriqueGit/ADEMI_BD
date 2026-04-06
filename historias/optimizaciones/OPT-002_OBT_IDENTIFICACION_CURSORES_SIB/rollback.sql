-- ============================================================
-- OPT-002 ROLLBACK: Restaurar cursores originales y eliminar indice
-- Ejecutar en Toad conectado a QA, schema PR
-- ============================================================

-- PASO 1: Recompilar el paquete con los cursores originales
-- En body.sql, reemplazar los cursores CUR_DE08_SIB y CUR_DE05_SIB
-- del procedure Actualiza_Precalificacion con el codigo de BEFORE.sql:
--
--   CURSOR CUR_DE08_SIB IS
--       SELECT B.ROWID ID, b.id_represtamo, NVL(A.CLASIFICACION,'NULA') CLASIFICACION
--       FROM PA_DE08_SIB A,
--            PR_REPRESTAMOS B
--       WHERE A.FECHA_CORTE = (SELECT MAX(FECHA_CORTE) FROM PA_DE08_SIB)
--       AND OBT_IDENTIFICACION_PERSONA(B.CODIGO_CLIENTE,'1') = A.ID_DEUDOR
--       AND B.ESTADO = 'RE'
--       AND PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO ( 'DE08_SIB' ) = 'S' ;
--
--   CURSOR CUR_DE05_SIB IS
--       SELECT B.ROWID ID, b.id_represtamo, A.cedula, a.entidad
--       FROM PA_DE05_SIB A,
--               PR_REPRESTAMOS B
--       WHERE A.FECHA_CASTIGO = (SELECT MAX(FECHA_CASTIGO) FROM PA_DE05_SIB)
--       AND OBT_IDENTIFICACION_PERSONA(B.CODIGO_CLIENTE,'1') = A.cedula
--       AND B.ESTADO = 'RE'
--       AND PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO ( 'CASTIGOS_SIB' ) = 'S';
--
-- Luego compilar el paquete completo en Toad.
--
-- Alternativa por git:
--   git revert 14f64ff
--   (luego recompilar body.sql en Toad)

-- PASO 2: Eliminar el covering index
-- En QA (creado bajo JOOGANDO):
DROP INDEX JOOGANDO.IDX_DE08_SIB_FECHA_DEUDOR;

-- En PRODUCCION (si se creo bajo PA):
-- DROP INDEX PA.IDX_DE08_SIB_FECHA_DEUDOR;

-- NOTA: Eliminar el indice no rompe nada, solo vuelve al rendimiento anterior.
-- El paquete funciona igual con o sin el indice.
