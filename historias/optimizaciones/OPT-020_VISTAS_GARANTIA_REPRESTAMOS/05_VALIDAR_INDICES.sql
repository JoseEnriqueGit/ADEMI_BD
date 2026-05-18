-- =====================================================================
-- OPT-020 - Validacion de indices de apoyo
-- Entorno objetivo: QA02
--
-- Este script no crea indices. Solo muestra si existen indices utiles para
-- las vistas de garantia.
-- =====================================================================

PROMPT ================================================================
PROMPT OPT-020 Q01 - Indices sobre tablas de garantia y creditos
PROMPT ================================================================

SELECT ic.table_owner,
       ic.table_name,
       ic.index_owner,
       ic.index_name,
       LISTAGG(ic.column_name, ', ') WITHIN GROUP (ORDER BY ic.column_position) columnas
  FROM all_ind_columns ic
 WHERE ic.table_owner = 'PR'
   AND ic.table_name IN ('PR_CREDITOS',
                         'PR_CREDITOS_HI',
                         'PR_GARANTIAS_X_CREDITO',
                         'PR_GARANTIAS')
 GROUP BY ic.table_owner,
          ic.table_name,
          ic.index_owner,
          ic.index_name
 ORDER BY ic.table_name,
          ic.index_name;

PROMPT Revisar que existan indices utiles para:
PROMPT - PR_CREDITOS / PR_CREDITOS_HI: CODIGO_EMPRESA, NO_CREDITO, ESTADO
PROMPT - PR_GARANTIAS_X_CREDITO: CODIGO_EMPRESA, NO_CREDITO, NUMERO_GARANTIA
PROMPT - PR_GARANTIAS: CODIGO_EMPRESA, NUMERO_GARANTIA, CODIGO_TIPO_GARANTIA_SB

PROMPT ================================================================
PROMPT OPT-020 Q02 - Indice de OPT-010 esperado sobre PR_GARANTIAS
PROMPT ================================================================

SELECT owner, index_name, table_owner, table_name, status
  FROM all_indexes
 WHERE owner = 'PR'
   AND index_name = 'IDX_GARANTIAS_TIPO_SB';

PROMPT Si no retorna filas, evaluar crear el indice de OPT-010 antes de medir.
