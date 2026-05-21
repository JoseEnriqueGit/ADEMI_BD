-- OPT-019: Recrea el indice sobre PA.PA_PARAMETROS_MVP con el nombre y tablespace finales
-- Cambios respecto a la primera creacion en DESARROLLO:
--   1. Nombre: IDX_PA_PARAM_MVP_01  ->  IDX_PARAM_MVP_EMP_MVP_PARAM
--      (sin prefijo de esquema y con sufijo descriptivo, alineado con los 8 indices ya en PROD)
--   2. Tablespace explicito: PA_IDX (estandar ADEMI; evita que caiga en PA_DAT por default)
-- Requiere owner PA o usuario DBA.
-- Idempotente: tolera que el indice viejo no exista y que el nuevo ya exista.

SET SERVEROUTPUT ON

DECLARE
    e_index_missing  EXCEPTION;
    e_index_exists   EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_index_missing, -1418);   -- ORA-01418: specified index does not exist
    PRAGMA EXCEPTION_INIT(e_index_exists,  -955);    -- ORA-00955: name is already used by an existing object
BEGIN
    -- 1) Eliminar el indice con nombre viejo si quedo creado en DESARROLLO
    BEGIN
        EXECUTE IMMEDIATE 'DROP INDEX PA.IDX_PA_PARAM_MVP_01';
        DBMS_OUTPUT.PUT_LINE('Eliminado PA.IDX_PA_PARAM_MVP_01 (nombre viejo).');
    EXCEPTION
        WHEN e_index_missing THEN
            DBMS_OUTPUT.PUT_LINE('PA.IDX_PA_PARAM_MVP_01 no existe; se continua.');
    END;

    -- 2) Eliminar el indice con nombre nuevo si ya existe (idempotencia ante reejecuciones)
    BEGIN
        EXECUTE IMMEDIATE 'DROP INDEX PA.IDX_PARAM_MVP_EMP_MVP_PARAM';
        DBMS_OUTPUT.PUT_LINE('Eliminado PA.IDX_PARAM_MVP_EMP_MVP_PARAM previo.');
    EXCEPTION
        WHEN e_index_missing THEN
            DBMS_OUTPUT.PUT_LINE('PA.IDX_PARAM_MVP_EMP_MVP_PARAM no existia previo; se continua.');
    END;

    -- 3) Crear el indice final con tablespace explicito PA_IDX
    BEGIN
        EXECUTE IMMEDIATE
            'CREATE INDEX PA.IDX_PARAM_MVP_EMP_MVP_PARAM ' ||
            'ON PA.PA_PARAMETROS_MVP (CODIGO_EMPRESA, CODIGO_MVP, CODIGO_PARAMETRO) ' ||
            'TABLESPACE PA_IDX';
        DBMS_OUTPUT.PUT_LINE('Creado PA.IDX_PARAM_MVP_EMP_MVP_PARAM en TABLESPACE PA_IDX.');
    EXCEPTION
        WHEN e_index_exists THEN
            DBMS_OUTPUT.PUT_LINE('PA.IDX_PARAM_MVP_EMP_MVP_PARAM ya existia; no se recrea.');
    END;

    -- 4) Refrescar estadisticas de la tabla y el indice nuevo
    DBMS_STATS.GATHER_TABLE_STATS(
        ownname => 'PA',
        tabname => 'PA_PARAMETROS_MVP',
        cascade => TRUE
    );
    DBMS_OUTPUT.PUT_LINE('Estadisticas recolectadas para PA.PA_PARAMETROS_MVP (cascade=TRUE).');
END;
/

-- Verificacion: confirmar nombre, tabla, tablespace y columnas del indice creado
SELECT i.owner,
       i.index_name,
       i.table_name,
       i.tablespace_name,
       i.status,
       LISTAGG(c.column_name, ', ') WITHIN GROUP (ORDER BY c.column_position) AS columnas
  FROM all_indexes      i
  JOIN all_ind_columns  c ON c.index_owner = i.owner
                         AND c.index_name  = i.index_name
 WHERE i.owner      = 'PA'
   AND i.index_name = 'IDX_PARAM_MVP_EMP_MVP_PARAM'
 GROUP BY i.owner, i.index_name, i.table_name, i.tablespace_name, i.status;
