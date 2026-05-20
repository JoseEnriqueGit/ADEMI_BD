-- =====================================================================
-- OPT-020 - Rollback de vistas de garantia
-- Entorno objetivo: QA02
--
-- Si solo se crearon las vistas, este rollback es suficiente.
-- Si ademas se aplicaron snippets al paquete, restaurar el body anterior o
-- revertir manualmente las secciones indicadas en 03_PATCH_PAQUETE_SNIPPETS.sql.
-- =====================================================================

BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW PR.V_REPRE_CREDITOS_GAR';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW PR.V_REPRE_CREDITOS_HI_GAR';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
/

SELECT owner, object_name, object_type, status
  FROM all_objects
 WHERE owner = 'PR'
   AND object_name IN ('V_REPRE_CREDITOS_GAR',
                       'V_REPRE_CREDITOS_HI_GAR');

PROMPT Debe retornar 0 filas.
