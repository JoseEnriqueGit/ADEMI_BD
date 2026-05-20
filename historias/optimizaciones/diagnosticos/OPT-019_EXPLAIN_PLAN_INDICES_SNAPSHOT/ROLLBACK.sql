-- OPT-019 ROLLBACK
-- Elimina el indice candidato firme creado para la validacion.
-- Requiere owner PA o usuario DBA para eliminar indices en ese schema.

SET SERVEROUTPUT ON

DECLARE
    e_index_missing EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_index_missing, -1418);
BEGIN
    EXECUTE IMMEDIATE 'DROP INDEX PA.IDX_PA_PARAM_MVP_01';
    DBMS_OUTPUT.PUT_LINE('Eliminado PA.IDX_PA_PARAM_MVP_01');
EXCEPTION
    WHEN e_index_missing THEN
        DBMS_OUTPUT.PUT_LINE('PA.IDX_PA_PARAM_MVP_01 no existe; se continua.');
END;
/

-- IDX_REPRE_ESTADO_ID_01 queda como candidato historico no recomendado si Q00
-- muestra IDX_REPRESTAMOS_ESTADO_COV o cualquier indice con prefijo
-- (ESTADO, ID_REPRESTAMO). Si se creo manualmente durante pruebas, eliminarlo
-- de forma explicita despues de confirmar que no es un indice preexistente.
