-- =====================================================================
-- OPT-020 - Snippets de patch para PR.PR_PKG_REPRESTAMOS en QA02
--
-- Este archivo NO es un CREATE PACKAGE BODY completo.
-- Uso:
--   1. Crear vistas con 01_CREATE_VIEWS.sql.
--   2. Validar equivalencia con 02_VALIDAR_EQUIVALENCIA.sql.
--   3. Aplicar estos reemplazos manuales en el body del paquete.
--   4. Compilar package body y ejecutar pruebas.
--
-- No se cambia spec.sql.
-- =====================================================================

-- =====================================================================
-- PATCH 1 - Precalifica_Repre_Cancelado
-- Ubicacion QA02 actual:
--   ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql
--   Lineas 478-479:
--
--     -- Se valida que los clientes no tengan no garantes
--     AND PR.PR_PKG_REPRESTAMOS.F_TIENE_GARANTIA(a.no_credito) = 0
--
-- Reemplazar por:
-- =====================================================================

/*
        -- OPT-020: vista SQL para evitar llamada PL/SQL por fila
        -- Equivalente a F_TIENE_GARANTIA(a.no_credito) = 0
        AND NOT EXISTS (
            SELECT 1
              FROM PR.V_REPRE_CREDITOS_GAR vg
             WHERE vg.codigo_empresa = PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
               AND vg.no_credito = a.no_credito
        )
*/

-- =====================================================================
-- PATCH 2 - Precalifica_Repre_Cancelado_hi
-- Ubicacion QA02 actual:
--   ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql
--   Lineas 860-861:
--
--     -- Se valida que los clientes no tengan no garantes
--     AND PR.PR_PKG_REPRESTAMOS.F_TIENE_GARANTIA_HISTORICO(a.no_credito) = 0
--
-- Reemplazar por:
-- =====================================================================

/*
        -- OPT-020: vista SQL para evitar llamada PL/SQL por fila
        -- Equivalente a F_TIENE_GARANTIA_HISTORICO(a.no_credito) = 0
        AND NOT EXISTS (
            SELECT 1
              FROM PR.V_REPRE_CREDITOS_HI_GAR vg
             WHERE vg.codigo_empresa = PR.PR_PKG_REPRESTAMOS.F_OBT_EMPRESA_REPRESTAMO
               AND vg.no_credito = a.no_credito
        )
*/

-- =====================================================================
-- PATCH 3 - Opcional: reimplementar funciones sobre las vistas
--
-- Esto mantiene el contrato publico de la spec y centraliza la logica.
-- No elimina el costo de llamar funcion desde SQL masivo, por eso los cursores
-- grandes deben usar las vistas directamente.
-- =====================================================================

/*
    FUNCTION F_TIENE_GARANTIA(pNoCredito IN NUMBER)
      RETURN NUMBER IS
      vExiste NUMBER := 0;
    BEGIN
      SELECT NVL(MAX(v.cantidad_garantias), 0)
        INTO vExiste
        FROM PR.V_REPRE_CREDITOS_GAR v
       WHERE v.codigo_empresa = F_Obt_Empresa_Represtamo
         AND v.no_credito = pNoCredito;

      RETURN vExiste;
    END F_TIENE_GARANTIA;

  FUNCTION F_TIENE_GARANTIA_HISTORICO(pNoCredito IN NUMBER)
    RETURN NUMBER IS
    vExiste NUMBER := 0;
  BEGIN
    SELECT NVL(MAX(v.cantidad_garantias), 0)
      INTO vExiste
      FROM PR.V_REPRE_CREDITOS_HI_GAR v
     WHERE v.codigo_empresa = F_Obt_Empresa_Represtamo
       AND v.no_credito = pNoCredito;

    RETURN vExiste;
  END F_TIENE_GARANTIA_HISTORICO;
*/

PROMPT OPT-020: archivo informativo. Copiar los bloques comentados al body del paquete si las validaciones pasan.
