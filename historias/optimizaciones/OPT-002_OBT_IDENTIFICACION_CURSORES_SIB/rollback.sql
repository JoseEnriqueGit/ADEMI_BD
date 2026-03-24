-- ============================================================
-- OPT-002 ROLLBACK: Restaurar cursores originales y eliminar indice
-- Ejecutar en Toad conectado a QA, schema PR
-- ============================================================

-- PASO 1: Recompilar el paquete con los cursores originales
-- Restaurar CUR_DE08_SIB y CUR_DE05_SIB en body.sql con el codigo de BEFORE.sql
-- y compilar el paquete completo en Toad.
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
