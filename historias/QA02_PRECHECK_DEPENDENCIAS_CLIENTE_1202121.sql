-- Entorno: QA02
-- Caso: precheck de dependencias reales para borrar cliente/persona 1202121.
-- Este script no hace DML. Solo cuenta filas hijas por FK.

SET SERVEROUTPUT ON SIZE UNLIMITED
SET DEFINE ON
SET VERIFY OFF

DEFINE p_cod_cliente = '1202121'

PROMPT ============================================================================
PROMPT Precheck de FKs con datos reales para el cliente/persona
PROMPT ============================================================================

DECLARE
    v_cod_cliente CONSTANT VARCHAR2(15) := '&p_cod_cliente';
    v_join        VARCHAR2(32767);
    v_filter      VARCHAR2(32767);
    v_sql         VARCHAR2(32767);
    v_count       NUMBER;

    FUNCTION qname(p_name IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN '"' || REPLACE(p_name, '"', '""') || '"';
    END;

    FUNCTION oname(p_owner IN VARCHAR2, p_table IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN qname(p_owner) || '.' || qname(p_table);
    END;

    FUNCTION lit(p_value IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN '''' || REPLACE(p_value, '''', '''''') || '''';
    END;

    FUNCTION parent_filter(p_owner IN VARCHAR2, p_table IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        IF p_owner = 'CC' AND p_table = 'CUENTA_EFECTIVO' THEN
            RETURN 'p.' || qname('COD_CLIENTE') || ' = ' || lit(v_cod_cliente);
        ELSIF p_owner = 'PA' AND p_table = 'CLIENTE' THEN
            RETURN 'p.' || qname('COD_CLIENTE') || ' = ' || lit(v_cod_cliente);
        ELSIF p_owner = 'PA' AND p_table = 'DIR_PERSONAS' THEN
            RETURN 'p.' || qname('COD_PERSONA') || ' = ' || lit(v_cod_cliente);
        ELSIF p_owner = 'PA' AND p_table = 'PERSONAS' THEN
            RETURN 'p.' || qname('COD_PERSONA') || ' = ' || lit(v_cod_cliente);
        ELSIF p_owner = 'PA' AND p_table = 'PERSONAS_FISICAS' THEN
            RETURN 'p.' || qname('COD_PER_FISICA') || ' = ' || lit(v_cod_cliente);
        END IF;

        RETURN NULL;
    END;
BEGIN
    DBMS_OUTPUT.PUT_LINE(
        RPAD('CHILD_OBJECT', 32) ||
        RPAD('CONSTRAINT_NAME', 36) ||
        RPAD('PARENT_OBJECT', 26) ||
        'ROWS'
    );

    FOR fk IN (
        SELECT c.owner child_owner,
               c.table_name child_table,
               c.constraint_name,
               p.owner parent_owner,
               p.table_name parent_table,
               c.r_constraint_name parent_constraint
          FROM all_constraints c
          JOIN all_constraints p
            ON p.owner = c.r_owner
           AND p.constraint_name = c.r_constraint_name
         WHERE c.constraint_type = 'R'
           AND (
                  (p.owner = 'CC' AND p.table_name = 'CUENTA_EFECTIVO')
               OR (p.owner = 'PA' AND p.table_name = 'CLIENTE')
               OR (p.owner = 'PA' AND p.table_name = 'DIR_PERSONAS')
               OR (p.owner = 'PA' AND p.table_name = 'PERSONAS')
               OR (p.owner = 'PA' AND p.table_name = 'PERSONAS_FISICAS')
           )
         ORDER BY p.owner, p.table_name, c.owner, c.table_name, c.constraint_name
    ) LOOP
        v_filter := parent_filter(fk.parent_owner, fk.parent_table);
        v_join := NULL;

        FOR col IN (
            SELECT cc.column_name child_column,
                   pc.column_name parent_column
              FROM all_cons_columns cc
              JOIN all_cons_columns pc
                ON pc.owner = fk.parent_owner
               AND pc.constraint_name = fk.parent_constraint
               AND pc.position = cc.position
             WHERE cc.owner = fk.child_owner
               AND cc.constraint_name = fk.constraint_name
             ORDER BY cc.position
        ) LOOP
            IF v_join IS NOT NULL THEN
                v_join := v_join || ' AND ';
            END IF;

            v_join := v_join ||
                      'c.' || qname(col.child_column) ||
                      ' = p.' || qname(col.parent_column);
        END LOOP;

        IF v_filter IS NOT NULL AND v_join IS NOT NULL THEN
            v_sql :=
                'SELECT COUNT(*) FROM ' || oname(fk.child_owner, fk.child_table) || ' c ' ||
                ' WHERE EXISTS (SELECT 1 FROM ' || oname(fk.parent_owner, fk.parent_table) || ' p ' ||
                '                WHERE ' || v_filter ||
                '                  AND ' || v_join || ')';

            BEGIN
                EXECUTE IMMEDIATE v_sql INTO v_count;

                IF v_count > 0 THEN
                    DBMS_OUTPUT.PUT_LINE(
                        RPAD(fk.child_owner || '.' || fk.child_table, 32) ||
                        RPAD(fk.constraint_name, 36) ||
                        RPAD(fk.parent_owner || '.' || fk.parent_table, 26) ||
                        v_count
                    );
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    DBMS_OUTPUT.PUT_LINE(
                        RPAD(fk.child_owner || '.' || fk.child_table, 32) ||
                        RPAD(fk.constraint_name, 36) ||
                        RPAD(fk.parent_owner || '.' || fk.parent_table, 26) ||
                        'ERROR: ' || SQLERRM
                    );
            END;
        END IF;
    END LOOP;
END;
/
