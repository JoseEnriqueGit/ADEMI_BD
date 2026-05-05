-- Entorno: QA02
-- Caso: borrar cliente/persona 1202121 y dependencias directas reportadas por ORA-02292.
-- Uso sugerido: ejecutar completo en Toad, revisar DBMS_OUTPUT y conteos finales.
-- Seguridad: termina con ROLLBACK. Cambiar por COMMIT solo despues de validar.

SET SERVEROUTPUT ON SIZE UNLIMITED
SET DEFINE ON
SET VERIFY OFF

DEFINE p_cod_cliente = '1202121'

PROMPT ============================================================================
PROMPT 1) Snapshot inicial del cliente/persona/cuentas
PROMPT ============================================================================

SELECT cod_cliente, estado_cliente
  FROM pa.cliente
 WHERE cod_cliente = '&p_cod_cliente';

SELECT cod_persona, cod_per_fisica, es_fisica, nombre, estado_persona
  FROM pa.personas
 WHERE cod_persona = '&p_cod_cliente'
    OR cod_per_fisica = '&p_cod_cliente';

SELECT cod_per_fisica, primer_nombre, segundo_nombre, primer_apellido, segundo_apellido
  FROM pa.personas_fisicas
 WHERE cod_per_fisica = '&p_cod_cliente';

SELECT cod_empresa, num_cuenta, cod_cliente, cod_direccion, ind_estado
  FROM cc.cuenta_efectivo
 WHERE cod_cliente = '&p_cod_cliente';

SELECT cod_persona, cod_direccion, tip_direccion, es_default
  FROM pa.dir_personas
 WHERE cod_persona = '&p_cod_cliente';

SELECT cod_empresa, cod_cliente, COUNT(*) cantidad
  FROM cc.bitacora_tarjetas
 WHERE cod_cliente = '&p_cod_cliente'
 GROUP BY cod_empresa, cod_cliente;

SELECT cod_empresa, cod_cliente, COUNT(*) cantidad
  FROM cc.firmas_cliente
 WHERE cod_cliente = '&p_cod_cliente'
 GROUP BY cod_empresa, cod_cliente;

SELECT cod_empresa, cod_cliente, COUNT(*) cantidad
  FROM cc.tarjetas
 WHERE cod_cliente = '&p_cod_cliente'
 GROUP BY cod_empresa, cod_cliente;

SELECT cod_empresa, cod_cliente, COUNT(*) cantidad
  FROM pa.clientes_productos
 WHERE cod_cliente = '&p_cod_cliente'
 GROUP BY cod_empresa, cod_cliente;

SELECT cod_persona, COUNT(*) cantidad
  FROM pa.ref_personales
 WHERE cod_persona = '&p_cod_cliente'
 GROUP BY cod_persona;

SELECT cod_persona, COUNT(*) cantidad
  FROM pa.dir_envio_x_pers
 WHERE cod_persona = '&p_cod_cliente'
 GROUP BY cod_persona;

SELECT cod_persona, COUNT(*) cantidad
  FROM pa.id_personas
 WHERE cod_persona = '&p_cod_cliente'
 GROUP BY cod_persona;

SELECT cod_persona, COUNT(*) cantidad
  FROM pa.evaluacion_persona
 WHERE cod_persona = '&p_cod_cliente'
 GROUP BY cod_persona;

SELECT cod_persona, COUNT(*) cantidad
  FROM pa.info_prod_sol
 WHERE cod_persona = '&p_cod_cliente'
 GROUP BY cod_persona;

SELECT cod_persona, COUNT(*) cantidad
  FROM pa.info_verif_doc_fis_nacional
 WHERE cod_persona = '&p_cod_cliente'
 GROUP BY cod_persona;

SELECT cod_per_fisica, COUNT(*) cantidad
  FROM pa.empleados
 WHERE cod_per_fisica = '&p_cod_cliente'
 GROUP BY cod_per_fisica;

SELECT cod_per_fisica, COUNT(*) cantidad
  FROM pa.info_laboral
 WHERE cod_per_fisica = '&p_cod_cliente'
 GROUP BY cod_per_fisica;

PROMPT ============================================================================
PROMPT 2) Mapeo real de las constraints que aparecen en tus errores
PROMPT ============================================================================

SELECT c.owner || '.' || c.table_name child_object,
       c.constraint_name,
       LISTAGG(cc.column_name, ', ') WITHIN GROUP (ORDER BY cc.position) child_columns,
       p.owner || '.' || p.table_name parent_object,
       c.r_constraint_name parent_constraint,
       LISTAGG(pc.column_name, ', ') WITHIN GROUP (ORDER BY pc.position) parent_columns,
       c.delete_rule
  FROM all_constraints c
  JOIN all_constraints p
    ON p.owner = c.r_owner
   AND p.constraint_name = c.r_constraint_name
  JOIN all_cons_columns cc
    ON cc.owner = c.owner
   AND cc.constraint_name = c.constraint_name
  JOIN all_cons_columns pc
    ON pc.owner = p.owner
   AND pc.constraint_name = p.constraint_name
   AND pc.position = cc.position
 WHERE c.constraint_type = 'R'
   AND c.constraint_name IN (
       'INT_CUENTA_DIARIO_R01',
       'FK_CTA_EFE_CLIENTES',
       'FK_CTAEFEC_DIRECCION',
       'FK_BITACORATA_CLIENTE',
       'FK_FIRMASCLIENTE_CLIENTE',
       'FK_TARJETAS_CLIENTE',
       'FK_CLIENTES_PRODUCTOS_CLIENTES',
       'FK_CLIENTES_PERSONAS',
       'FK_REFPERSONALES_PERSONAS',
       'FK_DIR_ENVIO_X_PERS_PERSONAS',
       'FK_IDPERSONAS_PERSONAS',
       'FK1_EVALUACION_PERSONA',
       'FK_INFOPRODSOL_PERSONAS',
       'FK_INFOVERIFDOCFISNAC_PERSONAS',
       'FK_EMPLEADOS_PERSONAS_FISICAS',
       'FK_INFO_LABORAL_PER_FISICAS',
       'FK_DIAS_IMP_PERS_PERS_FISICAS'
    )
 GROUP BY c.owner, c.table_name, c.constraint_name,
          p.owner, p.table_name, c.r_constraint_name, c.delete_rule
 ORDER BY parent_object, child_object, c.constraint_name;

PROMPT ============================================================================
PROMPT 2b) Otras FK directas que podrian bloquear estos padres en QA02
PROMPT ============================================================================

SELECT c.owner || '.' || c.table_name child_object,
       c.constraint_name,
       LISTAGG(cc.column_name, ', ') WITHIN GROUP (ORDER BY cc.position) child_columns,
       p.owner || '.' || p.table_name parent_object,
       c.delete_rule
  FROM all_constraints c
  JOIN all_constraints p
    ON p.owner = c.r_owner
   AND p.constraint_name = c.r_constraint_name
  JOIN all_cons_columns cc
    ON cc.owner = c.owner
   AND cc.constraint_name = c.constraint_name
 WHERE c.constraint_type = 'R'
   AND (
          (p.owner = 'CC' AND p.table_name = 'CUENTA_EFECTIVO')
       OR (p.owner = 'PA' AND p.table_name = 'CLIENTE')
       OR (p.owner = 'PA' AND p.table_name = 'DIR_PERSONAS')
       OR (p.owner = 'PA' AND p.table_name = 'PERSONAS')
       OR (p.owner = 'PA' AND p.table_name = 'PERSONAS_FISICAS')
   )
 GROUP BY c.owner, c.table_name, c.constraint_name,
           p.owner, p.table_name, c.delete_rule
 ORDER BY parent_object, child_object, c.constraint_name;

PROMPT ============================================================================
PROMPT 2c) FKs con datos reales que pueden bloquear este borrado
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

PROMPT ============================================================================
PROMPT 3) Borrado en orden de hijos a padres
PROMPT ============================================================================

SAVEPOINT sp_borrado_cliente_1202121;

DECLARE
    v_cod_cliente CONSTANT VARCHAR2(15) := '&p_cod_cliente';

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

    PROCEDURE exec_delete(p_sql IN VARCHAR2, p_label IN VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE p_sql;
        DBMS_OUTPUT.PUT_LINE(RPAD(p_label, 55) || ' -> ' || SQL%ROWCOUNT || ' fila(s)');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('ERROR en ' || p_label || ': ' || SQLERRM);
            DBMS_OUTPUT.PUT_LINE('SQL: ' || p_sql);
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
                'DELETE FROM ' || oname(UPPER(p_owner), UPPER(p_table)) || ' WHERE ' || p_where,
                p_label
            );
        ELSE
            DBMS_OUTPUT.PUT_LINE(RPAD(p_label, 55) || ' -> tabla no visible en ALL_TABLES');
        END IF;
    END;

    PROCEDURE delete_child_by_constraint(
        p_owner IN VARCHAR2,
        p_constraint_name IN VARCHAR2,
        p_parent_filter IN VARCHAR2
    ) IS
        v_child_owner  all_constraints.owner%TYPE;
        v_child_table  all_constraints.table_name%TYPE;
        v_parent_owner all_constraints.owner%TYPE;
        v_parent_table all_constraints.table_name%TYPE;
        v_parent_constraint all_constraints.constraint_name%TYPE;
        v_join         VARCHAR2(32767);
        v_sql          VARCHAR2(32767);
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
            'DELETE FROM ' || oname(v_child_owner, v_child_table) || ' c ' ||
            ' WHERE EXISTS (SELECT 1 FROM ' || oname(v_parent_owner, v_parent_table) || ' p ' ||
            '                WHERE ' || p_parent_filter ||
            '                  AND ' || v_join || ')';

        exec_delete(v_sql, p_owner || '.' || p_constraint_name);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE(
                RPAD(p_owner || '.' || p_constraint_name, 55) ||
                ' -> constraint no visible en ALL_CONSTRAINTS'
            );
    END;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Cliente/persona objetivo: ' || v_cod_cliente);

    -- Tablas observadas en el repo QA que suelen quedar antes de DIRECCIONES/PERSONAS.
    delete_if_exists(
        'PA',
        'CUENTA_CLIENTE_RELACION',
        qname('CODIGO_CLIENTE') || ' = ' || lit(v_cod_cliente),
        'PA.CUENTA_CLIENTE_RELACION por CODIGO_CLIENTE'
    );

    delete_if_exists(
        'PA',
        'TEL_PERSONAS',
        qname('COD_PERSONA') || ' = ' || lit(v_cod_cliente),
        'PA.TEL_PERSONAS por COD_PERSONA'
    );

    -- Hijos de CC.CUENTA_EFECTIVO: resuelve ORA-02292 CC.INT_CUENTA_DIARIO_R01.
    delete_child_by_constraint(
        'CC',
        'INT_CUENTA_DIARIO_R01',
        'p.' || qname('COD_CLIENTE') || ' = ' || lit(v_cod_cliente)
    );

    -- Hijos de PA.PERSONAS_FISICAS: resuelve ORA-02292 PA.FK_DIAS_IMP_PERS_PERS_FISICAS.
    delete_child_by_constraint(
        'PA',
        'FK_DIAS_IMP_PERS_PERS_FISICAS',
        'p.' || qname('COD_PER_FISICA') || ' = ' || lit(v_cod_cliente)
    );

    -- La captura de Toad muestra la misma FK en MG.DIAS_IMPORT_PERS.
    delete_child_by_constraint(
        'MG',
        'FK_DIAS_IMP_PERS_PERS_FISICAS',
        'p.' || qname('COD_PER_FISICA') || ' = ' || lit(v_cod_cliente)
    );

    -- CC.CUENTA_EFECTIVO como hijo de PA.CLIENTE y PA.DIR_PERSONAS.
    delete_child_by_constraint(
        'CC',
        'FK_CTA_EFE_CLIENTES',
        'p.' || qname('COD_CLIENTE') || ' = ' || lit(v_cod_cliente)
    );

    delete_child_by_constraint(
        'CC',
        'FK_CTAEFEC_DIRECCION',
        'p.' || qname('COD_PERSONA') || ' = ' || lit(v_cod_cliente)
    );

    delete_if_exists(
        'CC',
        'CUENTA_EFECTIVO',
        qname('COD_CLIENTE') || ' = ' || lit(v_cod_cliente),
        'CC.CUENTA_EFECTIVO por COD_CLIENTE'
    );

    -- Dependencia real encontrada en la corrida de validacion:
    -- ORA-02292 CC.FK_BITACORATA_CLIENTE, hijo CC.BITACORA_TARJETAS de PA.CLIENTE.
    delete_child_by_constraint(
        'CC',
        'FK_BITACORATA_CLIENTE',
        'p.' || qname('COD_CLIENTE') || ' = ' || lit(v_cod_cliente)
    );

    -- Dependencia real encontrada en la corrida de validacion:
    -- ORA-02292 CC.FK_FIRMASCLIENTE_CLIENTE, hijo CC.FIRMAS_CLIENTE de PA.CLIENTE.
    delete_child_by_constraint(
        'CC',
        'FK_FIRMASCLIENTE_CLIENTE',
        'p.' || qname('COD_CLIENTE') || ' = ' || lit(v_cod_cliente)
    );

    -- Dependencia real encontrada en la corrida de validacion:
    -- ORA-02292 CC.FK_TARJETAS_CLIENTE, hijo CC.TARJETAS de PA.CLIENTE.
    delete_child_by_constraint(
        'CC',
        'FK_TARJETAS_CLIENTE',
        'p.' || qname('COD_CLIENTE') || ' = ' || lit(v_cod_cliente)
    );

    -- Dependencia real encontrada en la corrida de validacion:
    -- ORA-02292 PA.FK_CLIENTES_PRODUCTOS_CLIENTES, hijo PA.CLIENTES_PRODUCTOS de PA.CLIENTE.
    delete_child_by_constraint(
        'PA',
        'FK_CLIENTES_PRODUCTOS_CLIENTES',
        'p.' || qname('COD_CLIENTE') || ' = ' || lit(v_cod_cliente)
    );

    -- PA.CLIENTE como hijo de PA.PERSONAS.
    delete_child_by_constraint(
        'PA',
        'FK_CLIENTES_PERSONAS',
        'p.' || qname('COD_PERSONA') || ' = ' || lit(v_cod_cliente)
    );

    delete_if_exists(
        'PA',
        'CLIENTE',
        qname('COD_CLIENTE') || ' = ' || lit(v_cod_cliente),
        'PA.CLIENTE por COD_CLIENTE'
    );

    -- Dependencia real encontrada en la corrida de validacion:
    -- ORA-02292 PA.FK_DIR_ENVIO_X_PERS_PERSONAS, hijo PA.DIR_ENVIO_X_PERS de PA.PERSONAS.
    delete_child_by_constraint(
        'PA',
        'FK_DIR_ENVIO_X_PERS_PERSONAS',
        'p.' || qname('COD_PERSONA') || ' = ' || lit(v_cod_cliente)
    );

    delete_if_exists(
        'PA',
        'DIR_PERSONAS',
        qname('COD_PERSONA') || ' = ' || lit(v_cod_cliente),
        'PA.DIR_PERSONAS por COD_PERSONA'
    );

    -- Dependencia real encontrada en la corrida de validacion:
    -- ORA-02292 PA.FK_REFPERSONALES_PERSONAS, hijo PA.REF_PERSONALES de PA.PERSONAS.
    delete_child_by_constraint(
        'PA',
        'FK_REFPERSONALES_PERSONAS',
        'p.' || qname('COD_PERSONA') || ' = ' || lit(v_cod_cliente)
    );

    -- Dependencia real encontrada en la corrida de validacion:
    -- ORA-02292 PA.FK_IDPERSONAS_PERSONAS, hijo PA.ID_PERSONAS de PA.PERSONAS.
    delete_child_by_constraint(
        'PA',
        'FK_IDPERSONAS_PERSONAS',
        'p.' || qname('COD_PERSONA') || ' = ' || lit(v_cod_cliente)
    );

    -- Dependencias reales encontradas por el precheck 2c, hijas de PA.PERSONAS.
    delete_child_by_constraint(
        'PA',
        'FK1_EVALUACION_PERSONA',
        'p.' || qname('COD_PERSONA') || ' = ' || lit(v_cod_cliente)
    );

    delete_child_by_constraint(
        'PA',
        'FK_INFOPRODSOL_PERSONAS',
        'p.' || qname('COD_PERSONA') || ' = ' || lit(v_cod_cliente)
    );

    delete_child_by_constraint(
        'PA',
        'FK_INFOVERIFDOCFISNAC_PERSONAS',
        'p.' || qname('COD_PERSONA') || ' = ' || lit(v_cod_cliente)
    );

    delete_if_exists(
        'PA',
        'PERSONAS',
        qname('COD_PERSONA') || ' = ' || lit(v_cod_cliente),
        'PA.PERSONAS por COD_PERSONA'
    );

    -- Dependencias reales encontradas por el precheck 2c, hijas de PA.PERSONAS_FISICAS.
    delete_child_by_constraint(
        'PA',
        'FK_EMPLEADOS_PERSONAS_FISICAS',
        'p.' || qname('COD_PER_FISICA') || ' = ' || lit(v_cod_cliente)
    );

    delete_child_by_constraint(
        'PA',
        'FK_INFO_LABORAL_PER_FISICAS',
        'p.' || qname('COD_PER_FISICA') || ' = ' || lit(v_cod_cliente)
    );

    delete_if_exists(
        'PA',
        'PERSONAS_FISICAS',
        qname('COD_PER_FISICA') || ' = ' || lit(v_cod_cliente),
        'PA.PERSONAS_FISICAS por COD_PER_FISICA'
    );
END;
/

PROMPT ============================================================================
PROMPT 4) Conteos finales antes de decidir COMMIT/ROLLBACK
PROMPT ============================================================================

SELECT 'PA.CLIENTE' tabla, COUNT(*) cantidad
  FROM pa.cliente
 WHERE cod_cliente = '&p_cod_cliente'
UNION ALL
SELECT 'PA.PERSONAS', COUNT(*)
  FROM pa.personas
 WHERE cod_persona = '&p_cod_cliente'
UNION ALL
SELECT 'PA.PERSONAS_FISICAS', COUNT(*)
  FROM pa.personas_fisicas
 WHERE cod_per_fisica = '&p_cod_cliente'
UNION ALL
SELECT 'PA.DIR_PERSONAS', COUNT(*)
  FROM pa.dir_personas
 WHERE cod_persona = '&p_cod_cliente'
UNION ALL
SELECT 'PA.TEL_PERSONAS', COUNT(*)
  FROM pa.tel_personas
 WHERE cod_persona = '&p_cod_cliente'
UNION ALL
SELECT 'PA.CUENTA_CLIENTE_RELACION', COUNT(*)
  FROM pa.cuenta_cliente_relacion
 WHERE codigo_cliente = '&p_cod_cliente'
UNION ALL
SELECT 'CC.CUENTA_EFECTIVO', COUNT(*)
  FROM cc.cuenta_efectivo
 WHERE cod_cliente = '&p_cod_cliente'
UNION ALL
SELECT 'CC.BITACORA_TARJETAS', COUNT(*)
  FROM cc.bitacora_tarjetas
 WHERE cod_cliente = '&p_cod_cliente'
UNION ALL
SELECT 'CC.FIRMAS_CLIENTE', COUNT(*)
  FROM cc.firmas_cliente
 WHERE cod_cliente = '&p_cod_cliente'
UNION ALL
SELECT 'CC.TARJETAS', COUNT(*)
  FROM cc.tarjetas
 WHERE cod_cliente = '&p_cod_cliente'
UNION ALL
SELECT 'PA.CLIENTES_PRODUCTOS', COUNT(*)
  FROM pa.clientes_productos
 WHERE cod_cliente = '&p_cod_cliente'
UNION ALL
SELECT 'PA.REF_PERSONALES', COUNT(*)
  FROM pa.ref_personales
 WHERE cod_persona = '&p_cod_cliente'
UNION ALL
SELECT 'PA.DIR_ENVIO_X_PERS', COUNT(*)
  FROM pa.dir_envio_x_pers
 WHERE cod_persona = '&p_cod_cliente'
UNION ALL
SELECT 'PA.ID_PERSONAS', COUNT(*)
  FROM pa.id_personas
 WHERE cod_persona = '&p_cod_cliente'
UNION ALL
SELECT 'PA.EVALUACION_PERSONA', COUNT(*)
  FROM pa.evaluacion_persona
 WHERE cod_persona = '&p_cod_cliente'
UNION ALL
SELECT 'PA.INFO_PROD_SOL', COUNT(*)
  FROM pa.info_prod_sol
 WHERE cod_persona = '&p_cod_cliente'
UNION ALL
SELECT 'PA.INFO_VERIF_DOC_FIS_NACIONAL', COUNT(*)
  FROM pa.info_verif_doc_fis_nacional
 WHERE cod_persona = '&p_cod_cliente'
UNION ALL
SELECT 'PA.EMPLEADOS', COUNT(*)
  FROM pa.empleados
 WHERE cod_per_fisica = '&p_cod_cliente'
UNION ALL
SELECT 'PA.INFO_LABORAL', COUNT(*)
  FROM pa.info_laboral
 WHERE cod_per_fisica = '&p_cod_cliente'
UNION ALL
SELECT 'PA.DIAS_IMPORT_PERS', COUNT(*)
  FROM pa.dias_import_pers
 WHERE cod_per_fisica = '&p_cod_cliente';

PROMPT ============================================================================
PROMPT 5) Seguridad
PROMPT ============================================================================
PROMPT La primera corrida deja todo como estaba. Si los conteos y DBMS_OUTPUT son correctos,
PROMPT cambia ROLLBACK por COMMIT y ejecuta nuevamente.

ROLLBACK TO sp_borrado_cliente_1202121;
-- COMMIT;
