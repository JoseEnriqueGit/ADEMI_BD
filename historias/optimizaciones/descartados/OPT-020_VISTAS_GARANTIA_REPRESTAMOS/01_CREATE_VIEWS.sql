-- =====================================================================
-- OPT-020 - Vistas SQL para centralizar validacion de garantias
-- Entorno objetivo: QA02
-- Objeto de apoyo: PR.PR_PKG_REPRESTAMOS
--
-- Objetivo:
--   Centralizar como SQL visible para Oracle la logica de:
--     - F_TIENE_GARANTIA
--     - F_TIENE_GARANTIA_HISTORICO
--
-- Nota:
--   Estas vistas no cambian la spec del paquete. Permiten reemplazar llamadas
--   PL/SQL por NOT EXISTS/EXISTS contra vistas simples en cursores masivos.
-- =====================================================================

PROMPT ================================================================
PROMPT OPT-020 Q00 - Verificacion de columnas requeridas
PROMPT ================================================================

SELECT owner, table_name, column_name
  FROM all_tab_columns
 WHERE owner = 'PR'
   AND (
        (table_name = 'PR_CREDITOS'
         AND column_name IN ('CODIGO_EMPRESA', 'NO_CREDITO', 'ESTADO'))
     OR (table_name = 'PR_CREDITOS_HI'
         AND column_name IN ('CODIGO_EMPRESA', 'NO_CREDITO', 'ESTADO'))
     OR (table_name = 'PR_GARANTIAS_X_CREDITO'
         AND column_name IN ('CODIGO_EMPRESA', 'NO_CREDITO', 'NUMERO_GARANTIA'))
     OR (table_name = 'PR_GARANTIAS'
         AND column_name IN ('CODIGO_EMPRESA', 'NUMERO_GARANTIA', 'CODIGO_TIPO_GARANTIA_SB'))
       )
 ORDER BY table_name, column_name;

PROMPT Deben retornar 12 filas. Si falta alguna, detener el pase.

PROMPT ================================================================
PROMPT OPT-020 Q00B - Verificacion de usuario, schema y privilegios
PROMPT ================================================================

SELECT USER usuario_conectado,
       SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') schema_actual,
       SYS_CONTEXT('USERENV', 'SESSION_USER') session_user
  FROM dual;

SELECT privilege
  FROM session_privs
 WHERE privilege IN ('CREATE VIEW', 'CREATE ANY VIEW')
 ORDER BY privilege;

PROMPT Si USUARIO_CONECTADO no es PR, se requiere CREATE ANY VIEW para crear PR.V_REPRE_*.
PROMPT Si no aparece CREATE VIEW ni CREATE ANY VIEW, el CREATE VIEW fallara por permisos.

PROMPT ================================================================
PROMPT OPT-020 Q01 - Crear vista PR.V_REPRE_CREDITOS_GAR
PROMPT ================================================================

CREATE OR REPLACE VIEW PR.V_REPRE_CREDITOS_GAR AS
SELECT cr.codigo_empresa,
       cr.no_credito,
       COUNT(1) cantidad_garantias
  FROM PR.PR_CREDITOS cr
  JOIN PR.PR_GARANTIAS_X_CREDITO gx
    ON gx.codigo_empresa = cr.codigo_empresa
   AND gx.no_credito = cr.no_credito
  JOIN PR.PR_GARANTIAS g
    ON g.codigo_empresa = gx.codigo_empresa
   AND g.numero_garantia = gx.numero_garantia
 WHERE cr.estado IN ('D', 'V', 'M', 'E', 'J')
   AND g.codigo_tipo_garantia_sb != 'NA'
 GROUP BY cr.codigo_empresa,
          cr.no_credito;

COMMENT ON TABLE PR.V_REPRE_CREDITOS_GAR IS
  'OPT-020: creditos vigentes con garantia valida para reemplazar F_TIENE_GARANTIA en SQL masivo';

COMMENT ON COLUMN PR.V_REPRE_CREDITOS_GAR.CANTIDAD_GARANTIAS IS
  'Cantidad equivalente al COUNT(1) de F_TIENE_GARANTIA para el credito y empresa';

PROMPT ================================================================
PROMPT OPT-020 Q02 - Crear vista PR.V_REPRE_CREDITOS_HI_GAR
PROMPT ================================================================

CREATE OR REPLACE VIEW PR.V_REPRE_CREDITOS_HI_GAR AS
SELECT cr.codigo_empresa,
       cr.no_credito,
       COUNT(1) cantidad_garantias
  FROM PR.PR_CREDITOS_HI cr
  JOIN PR.PR_GARANTIAS_X_CREDITO gx
    ON gx.codigo_empresa = cr.codigo_empresa
   AND gx.no_credito = cr.no_credito
  JOIN PR.PR_GARANTIAS g
    ON g.codigo_empresa = gx.codigo_empresa
   AND g.numero_garantia = gx.numero_garantia
 WHERE cr.estado IN ('D', 'V', 'M', 'E', 'J')
   AND g.codigo_tipo_garantia_sb != 'NA'
 GROUP BY cr.codigo_empresa,
          cr.no_credito;

COMMENT ON TABLE PR.V_REPRE_CREDITOS_HI_GAR IS
  'OPT-020: creditos historicos con garantia valida para reemplazar F_TIENE_GARANTIA_HISTORICO en SQL masivo';

COMMENT ON COLUMN PR.V_REPRE_CREDITOS_HI_GAR.CANTIDAD_GARANTIAS IS
  'Cantidad equivalente al COUNT(1) de F_TIENE_GARANTIA_HISTORICO para el credito y empresa';

PROMPT ================================================================
PROMPT OPT-020 Q03 - Verificar vistas creadas
PROMPT ================================================================

SELECT owner, object_name, object_type, status
  FROM all_objects
 WHERE owner = 'PR'
   AND object_name IN ('V_REPRE_CREDITOS_GAR',
                       'V_REPRE_CREDITOS_HI_GAR')
 ORDER BY object_name;

PROMPT Deben retornar 2 filas con STATUS = VALID.
