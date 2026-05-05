-- Entorno: QA02
-- Proposito: borrar un cliente/persona y sus dependencias conocidas.
-- Uso:
--   1) Cambiar p_cod_clientes. Separar multiples clientes con coma.
--   2) Ejecutar con F5. Este script borra definitivamente y hace COMMIT.

SET SERVEROUTPUT ON SIZE UNLIMITED
SET DEFINE ON
SET VERIFY OFF

DEFINE p_cod_clientes = '1202121'

DECLARE
    v_cod_clientes_raw CONSTANT VARCHAR2(32767) := '&p_cod_clientes';
    v_clientes_in      VARCHAR2(32767);
    v_parentes         NUMBER;

    FUNCTION qname(p_name IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN '"' || REPLACE(p_name, '"', '""') || '"';
    END;

    FUNCTION oname(p_owner IN VARCHAR2, p_table IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN qname(UPPER(p_owner)) || '.' || qname(UPPER(p_table));
    END;

    FUNCTION lit(p_value IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN '''' || REPLACE(p_value, '''', '''''') || '''';
    END;

    FUNCTION build_clientes_in(p_values IN VARCHAR2) RETURN VARCHAR2 IS
        v_rest   VARCHAR2(32767) := p_values || ',';
        v_pos    PLS_INTEGER;
        v_item   VARCHAR2(4000);
        v_result VARCHAR2(32767);
        v_count  PLS_INTEGER := 0;
    BEGIN
        LOOP
            v_pos := INSTR(v_rest, ',');
            EXIT WHEN v_pos = 0;

            v_item := TRIM(SUBSTR(v_rest, 1, v_pos - 1));
            v_rest := SUBSTR(v_rest, v_pos + 1);

            IF v_item IS NOT NULL THEN
                IF (SUBSTR(v_item, 1, 1) = '''' AND SUBSTR(v_item, -1) = '''')
                   OR (SUBSTR(v_item, 1, 1) = '"' AND SUBSTR(v_item, -1) = '"') THEN
                    v_item := SUBSTR(v_item, 2, LENGTH(v_item) - 2);
                END IF;

                IF LENGTH(v_item) > 15 THEN
                    RAISE_APPLICATION_ERROR(-20002, 'Codigo de cliente demasiado largo: ' || v_item);
                END IF;

                v_count := v_count + 1;
                IF v_count > 1000 THEN
                    RAISE_APPLICATION_ERROR(-20003, 'Oracle permite maximo 1000 valores en un IN');
                END IF;

                IF v_result IS NOT NULL THEN
                    v_result := v_result || ', ';
                END IF;

                v_result := v_result || lit(v_item);
            END IF;
        END LOOP;

        IF v_result IS NULL THEN
            RAISE_APPLICATION_ERROR(-20004, 'Debes indicar al menos un cliente en p_cod_clientes');
        END IF;

        RETURN v_result;
    END;

    FUNCTION col_ref(p_alias IN VARCHAR2, p_column IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        IF p_alias IS NULL THEN
            RETURN qname(p_column);
        END IF;

        RETURN p_alias || '.' || qname(p_column);
    END;

    FUNCTION in_filter(p_alias IN VARCHAR2, p_column IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN col_ref(p_alias, p_column) || ' IN (' || v_clientes_in || ')';
    END;

    FUNCTION table_exists(p_owner IN VARCHAR2, p_table IN VARCHAR2) RETURN BOOLEAN IS
        v_count PLS_INTEGER;
    BEGIN
        SELECT COUNT(*)
          INTO v_count
          FROM all_tables
         WHERE owner = UPPER(p_owner)
           AND table_name = UPPER(p_table);

        RETURN v_count > 0;
    END;

    PROCEDURE put_line(p_text IN VARCHAR2) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(p_text);
    END;

    PROCEDURE exec_delete(p_sql IN VARCHAR2, p_label IN VARCHAR2) IS
        v_start PLS_INTEGER;
        v_secs  NUMBER;
    BEGIN
        DBMS_APPLICATION_INFO.SET_ACTION(SUBSTR(p_label, 1, 64));
        v_start := DBMS_UTILITY.GET_TIME;
        EXECUTE IMMEDIATE p_sql;
        v_secs := (DBMS_UTILITY.GET_TIME - v_start) / 100;
        put_line(
            RPAD(p_label, 58) ||
            ' -> ' || SQL%ROWCOUNT || ' fila(s)' ||
            ' (' || TO_CHAR(v_secs, 'FM9999990D00') || 's)'
        );
    EXCEPTION
        WHEN OTHERS THEN
            put_line('ERROR en ' || p_label || ': ' || SQLERRM);
            put_line('SQL: ' || p_sql);
            RAISE;
    END;

    PROCEDURE delete_if_exists(
        p_owner IN VARCHAR2,
        p_table IN VARCHAR2,
        p_where IN VARCHAR2,
        p_label IN VARCHAR2
    ) IS
    BEGIN
        IF table_exists(p_owner, p_table) THEN
            exec_delete(
                'DELETE FROM ' || oname(p_owner, p_table) || ' WHERE ' || p_where,
                p_label
            );
        ELSE
            put_line(RPAD(p_label, 58) || ' -> tabla no visible');
        END IF;
    END;

    PROCEDURE delete_child_by_constraint(
        p_owner IN VARCHAR2,
        p_constraint_name IN VARCHAR2,
        p_parent_filter IN VARCHAR2
    ) IS
        v_child_owner       all_constraints.owner%TYPE;
        v_child_table       all_constraints.table_name%TYPE;
        v_parent_owner      all_constraints.owner%TYPE;
        v_parent_table      all_constraints.table_name%TYPE;
        v_parent_constraint all_constraints.constraint_name%TYPE;
        v_join              VARCHAR2(32767);
        v_sql               VARCHAR2(32767);
        v_parent_count      NUMBER;
    BEGIN
        SELECT c.owner, c.table_name, p.owner, p.table_name, c.r_constraint_name
          INTO v_child_owner, v_child_table, v_parent_owner, v_parent_table, v_parent_constraint
          FROM all_constraints c
          JOIN all_constraints p
            ON p.owner = c.r_owner
           AND p.constraint_name = c.r_constraint_name
         WHERE c.owner = UPPER(p_owner)
           AND c.constraint_name = UPPER(p_constraint_name)
           AND c.constraint_type = 'R';

        v_join := NULL;

        FOR r IN (
            SELECT cc.column_name child_column,
                   pc.column_name parent_column
              FROM all_cons_columns cc
              JOIN all_cons_columns pc
                ON pc.owner = v_parent_owner
               AND pc.constraint_name = v_parent_constraint
               AND pc.position = cc.position
             WHERE cc.owner = v_child_owner
               AND cc.constraint_name = UPPER(p_constraint_name)
             ORDER BY cc.position
        ) LOOP
            IF v_join IS NOT NULL THEN
                v_join := v_join || ' AND ';
            END IF;

            v_join := v_join ||
                      'c.' || qname(r.child_column) ||
                      ' = p.' || qname(r.parent_column);
        END LOOP;

        IF v_join IS NULL THEN
            RAISE_APPLICATION_ERROR(
                -20001,
                'No se pudieron resolver columnas para ' ||
                p_owner || '.' || p_constraint_name
            );
        END IF;

        v_sql :=
            'SELECT COUNT(*) FROM ' || oname(v_parent_owner, v_parent_table) || ' p ' ||
            ' WHERE ' || p_parent_filter;

        EXECUTE IMMEDIATE v_sql INTO v_parent_count;

        IF v_parent_count = 0 THEN
            put_line(
                RPAD(p_owner || '.' || p_constraint_name, 58) ||
                ' -> 0 fila(s) (sin padre, omitido)'
            );
            RETURN;
        END IF;

        v_sql :=
            'DELETE FROM ' || oname(v_child_owner, v_child_table) || ' c ' ||
            ' WHERE EXISTS (SELECT 1 FROM ' || oname(v_parent_owner, v_parent_table) || ' p ' ||
            '                WHERE ' || p_parent_filter ||
            '                  AND ' || v_join || ')';

        exec_delete(v_sql, p_owner || '.' || p_constraint_name);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            put_line(RPAD(p_owner || '.' || p_constraint_name, 58) || ' -> constraint no visible');
    END;

    PROCEDURE print_count(
        p_owner IN VARCHAR2,
        p_table IN VARCHAR2,
        p_where IN VARCHAR2,
        p_label IN VARCHAR2
    ) IS
        v_sql   VARCHAR2(32767);
        v_count NUMBER;
    BEGIN
        IF table_exists(p_owner, p_table) THEN
            v_sql := 'SELECT COUNT(*) FROM ' || oname(p_owner, p_table) || ' WHERE ' || p_where;
            EXECUTE IMMEDIATE v_sql INTO v_count;
            put_line(RPAD(p_label, 42) || ' -> ' || v_count);
        ELSE
            put_line(RPAD(p_label, 42) || ' -> tabla no visible');
        END IF;
    END;

    PROCEDURE print_final_counts IS
    BEGIN
        put_line('Conteos despues del borrado antes de confirmar/rollback');
        print_count('PA', 'CLIENTE', in_filter(NULL, 'COD_CLIENTE'), 'PA.CLIENTE');
        print_count('PA', 'PERSONAS', in_filter(NULL, 'COD_PERSONA'), 'PA.PERSONAS');
        print_count('PA', 'PERSONAS_FISICAS', in_filter(NULL, 'COD_PER_FISICA'), 'PA.PERSONAS_FISICAS');
        print_count('PA', 'DIR_PERSONAS', in_filter(NULL, 'COD_PERSONA'), 'PA.DIR_PERSONAS');
        print_count('PA', 'TEL_PERSONAS', in_filter(NULL, 'COD_PERSONA'), 'PA.TEL_PERSONAS');
        print_count('PA', 'CUENTA_CLIENTE_RELACION', in_filter(NULL, 'CODIGO_CLIENTE'), 'PA.CUENTA_CLIENTE_RELACION');
        print_count('CC', 'CUENTA_EFECTIVO', in_filter(NULL, 'COD_CLIENTE'), 'CC.CUENTA_EFECTIVO');
        print_count('CC', 'BITACORA_TARJETAS', in_filter(NULL, 'COD_CLIENTE'), 'CC.BITACORA_TARJETAS');
        print_count('CC', 'FIRMAS_CLIENTE', in_filter(NULL, 'COD_CLIENTE'), 'CC.FIRMAS_CLIENTE');
        print_count('CC', 'TARJETAS', in_filter(NULL, 'COD_CLIENTE'), 'CC.TARJETAS');
        print_count('PA', 'CLIENTES_PRODUCTOS', in_filter(NULL, 'COD_CLIENTE'), 'PA.CLIENTES_PRODUCTOS');
        print_count('PA', 'REF_PERSONALES', in_filter(NULL, 'COD_PERSONA'), 'PA.REF_PERSONALES');
        print_count('PA', 'DIR_ENVIO_X_PERS', in_filter(NULL, 'COD_PERSONA'), 'PA.DIR_ENVIO_X_PERS');
        print_count('PA', 'ID_PERSONAS', in_filter(NULL, 'COD_PERSONA'), 'PA.ID_PERSONAS');
        print_count('PA', 'EVALUACION_PERSONA', in_filter(NULL, 'COD_PERSONA'), 'PA.EVALUACION_PERSONA');
        print_count('PA', 'INFO_PROD_SOL', in_filter(NULL, 'COD_PERSONA'), 'PA.INFO_PROD_SOL');
        print_count('PA', 'INFO_VERIF_DOC_FIS_NACIONAL', in_filter(NULL, 'COD_PERSONA'), 'PA.INFO_VERIF_DOC_FIS_NACIONAL');
        print_count('PA', 'EMPLEADOS', in_filter(NULL, 'COD_PER_FISICA'), 'PA.EMPLEADOS');
        print_count('PA', 'INFO_LABORAL', in_filter(NULL, 'COD_PER_FISICA'), 'PA.INFO_LABORAL');
        print_count('PA', 'DIAS_IMPORT_PERS', in_filter(NULL, 'COD_PER_FISICA'), 'PA.DIAS_IMPORT_PERS');
    END;

    FUNCTION count_parentes RETURN NUMBER IS
        v_count NUMBER;
    BEGIN
        EXECUTE IMMEDIATE
            'SELECT SUM(cantidad)
               FROM (
                     SELECT COUNT(*) cantidad FROM PA.CLIENTE WHERE ' || in_filter(NULL, 'COD_CLIENTE') || '
                     UNION ALL
                     SELECT COUNT(*) cantidad FROM PA.PERSONAS WHERE ' || in_filter(NULL, 'COD_PERSONA') || '
                     UNION ALL
                     SELECT COUNT(*) cantidad FROM PA.PERSONAS_FISICAS WHERE ' || in_filter(NULL, 'COD_PER_FISICA') || '
                     UNION ALL
                     SELECT COUNT(*) cantidad FROM CC.CUENTA_EFECTIVO WHERE ' || in_filter(NULL, 'COD_CLIENTE') || '
                    )'
            INTO v_count;

        RETURN NVL(v_count, 0);
    END;
BEGIN
    SAVEPOINT sp_borrado_cliente;

    v_clientes_in := build_clientes_in(v_cod_clientes_raw);

    DBMS_APPLICATION_INFO.SET_MODULE('QA02_BORRADO_CLIENTE', 'INICIO');
    put_line('Clientes/personas objetivo: ' || v_clientes_in);
    put_line('Modo: BORRADO DEFINITIVO CON COMMIT');

    v_parentes := count_parentes;
    put_line('Filas padre encontradas: ' || v_parentes);

    IF v_parentes = 0 THEN
        put_line('No hay filas padre para esos clientes. No se ejecutan deletes.');
        COMMIT;
        RETURN;
    END IF;

    put_line('Borrando dependencias...');

    delete_if_exists('PA', 'CUENTA_CLIENTE_RELACION', in_filter(NULL, 'CODIGO_CLIENTE'), 'PA.CUENTA_CLIENTE_RELACION');
    delete_if_exists('PA', 'TEL_PERSONAS', in_filter(NULL, 'COD_PERSONA'), 'PA.TEL_PERSONAS');

    delete_child_by_constraint('CC', 'INT_CUENTA_DIARIO_R01', in_filter('p', 'COD_CLIENTE'));

    delete_child_by_constraint('PA', 'FK_DIAS_IMP_PERS_PERS_FISICAS', in_filter('p', 'COD_PER_FISICA'));
    delete_child_by_constraint('MG', 'FK_DIAS_IMP_PERS_PERS_FISICAS', in_filter('p', 'COD_PER_FISICA'));

    delete_child_by_constraint('CC', 'FK_CTA_EFE_CLIENTES', in_filter('p', 'COD_CLIENTE'));
    delete_child_by_constraint('CC', 'FK_CTAEFEC_DIRECCION', in_filter('p', 'COD_PERSONA'));
    delete_if_exists('CC', 'CUENTA_EFECTIVO', in_filter(NULL, 'COD_CLIENTE'), 'CC.CUENTA_EFECTIVO');

    delete_child_by_constraint('CC', 'FK_BITACORATA_CLIENTE', in_filter('p', 'COD_CLIENTE'));
    delete_child_by_constraint('CC', 'FK_FIRMASCLIENTE_CLIENTE', in_filter('p', 'COD_CLIENTE'));
    delete_child_by_constraint('CC', 'FK_TARJETAS_CLIENTE', in_filter('p', 'COD_CLIENTE'));
    delete_child_by_constraint('PA', 'FK_CLIENTES_PRODUCTOS_CLIENTES', in_filter('p', 'COD_CLIENTE'));

    delete_child_by_constraint('PA', 'FK_CLIENTES_PERSONAS', in_filter('p', 'COD_PERSONA'));
    delete_if_exists('PA', 'CLIENTE', in_filter(NULL, 'COD_CLIENTE'), 'PA.CLIENTE');

    delete_child_by_constraint('PA', 'FK_DIR_ENVIO_X_PERS_PERSONAS', in_filter('p', 'COD_PERSONA'));
    delete_child_by_constraint('PA', 'FK_DIRPERSONAS_PERSONAS', in_filter('p', 'COD_PERSONA'));
    delete_if_exists('PA', 'DIR_PERSONAS', in_filter(NULL, 'COD_PERSONA'), 'PA.DIR_PERSONAS');

    delete_child_by_constraint('PA', 'FK_REFPERSONALES_PERSONAS', in_filter('p', 'COD_PERSONA'));
    delete_child_by_constraint('PA', 'FK_IDPERSONAS_PERSONAS', in_filter('p', 'COD_PERSONA'));
    delete_child_by_constraint('PA', 'FK1_EVALUACION_PERSONA', in_filter('p', 'COD_PERSONA'));
    delete_child_by_constraint('PA', 'FK_INFOPRODSOL_PERSONAS', in_filter('p', 'COD_PERSONA'));
    delete_child_by_constraint('PA', 'FK_INFOVERIFDOCFISNAC_PERSONAS', in_filter('p', 'COD_PERSONA'));

    delete_child_by_constraint('PA', 'FK_PERS_PERFISICAS', in_filter('p', 'COD_PER_FISICA'));
    delete_if_exists('PA', 'PERSONAS', in_filter(NULL, 'COD_PERSONA'), 'PA.PERSONAS');

    delete_child_by_constraint('PA', 'FK_EMPLEADOS_PERSONAS_FISICAS', in_filter('p', 'COD_PER_FISICA'));
    delete_child_by_constraint('PA', 'FK_INFO_LABORAL_PER_FISICAS', in_filter('p', 'COD_PER_FISICA'));
    delete_if_exists('PA', 'PERSONAS_FISICAS', in_filter(NULL, 'COD_PER_FISICA'), 'PA.PERSONAS_FISICAS');

    print_final_counts;

    COMMIT;
    DBMS_APPLICATION_INFO.SET_ACTION('COMMIT');
    put_line('COMMIT ejecutado.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO SAVEPOINT sp_borrado_cliente;
        DBMS_APPLICATION_INFO.SET_ACTION('ERROR_ROLLBACK');
        put_line('ERROR: ' || SQLERRM);
        put_line('ROLLBACK ejecutado por error. No se hizo COMMIT.');
        RAISE;
END;
/
