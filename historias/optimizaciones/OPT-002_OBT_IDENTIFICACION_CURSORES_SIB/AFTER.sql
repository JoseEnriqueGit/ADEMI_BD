-- ============================================================
-- OPT-002 AFTER: Cursores optimizados en Actualiza_Precalificacion
-- Paquete: PR_PKG_REPRESTAMOS (body.sql, QA)
-- Procedure: Actualiza_Precalificacion (primer overload, ~linea 2615)
-- ============================================================
-- Cambio: Se reemplaza la llamada a funcion OBT_IDENTIFICACION_PERSONA
-- por un JOIN directo a PA.ID_PERSONAS, eliminando context switches
-- PL/SQL-to-SQL y permitiendo uso de indices.
-- Cost: 64,753 -> 39 (reduccion 99.9%)
-- ============================================================

-- CURSOR CUR_DE08_SIB
-- Cambio: OBT_IDENTIFICACION_PERSONA(B.CODIGO_CLIENTE,'1') = A.ID_DEUDOR
--      -> JOIN PA.ID_PERSONAS IP ... AND IP.NUM_ID = A.ID_DEUDOR
CURSOR CUR_DE08_SIB IS
    SELECT B.ROWID ID, b.id_represtamo, NVL(A.CLASIFICACION,'NULA') CLASIFICACION
    FROM PA_DE08_SIB A
    JOIN PR_REPRESTAMOS B ON B.ESTADO = 'RE'
    JOIN PA.ID_PERSONAS IP ON IP.COD_PERSONA = TO_CHAR(B.CODIGO_CLIENTE)
                           AND IP.COD_TIPO_ID = '1'
    WHERE A.FECHA_CORTE = (SELECT MAX(FECHA_CORTE) FROM PA_DE08_SIB)
    AND IP.NUM_ID = A.ID_DEUDOR
    AND PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO ( 'DE08_SIB' ) = 'S' ;

-- CURSOR CUR_DE05_SIB
-- Cambio: OBT_IDENTIFICACION_PERSONA(B.CODIGO_CLIENTE,'1') = A.cedula
--      -> JOIN PA.ID_PERSONAS IP ... AND IP.NUM_ID = A.cedula
CURSOR CUR_DE05_SIB IS
    SELECT B.ROWID ID, b.id_represtamo, A.cedula, a.entidad
    FROM PA_DE05_SIB A
    JOIN PR_REPRESTAMOS B ON B.ESTADO = 'RE'
    JOIN PA.ID_PERSONAS IP ON IP.COD_PERSONA = TO_CHAR(B.CODIGO_CLIENTE)
                           AND IP.COD_TIPO_ID = '1'
    WHERE A.FECHA_CASTIGO = (SELECT MAX(FECHA_CASTIGO) FROM PA_DE05_SIB)
    AND IP.NUM_ID = A.cedula
    AND PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO ( 'CASTIGOS_SIB' ) = 'S';

-- INDICE NUEVO (covering index para eliminar TABLE ACCESS a PA_DE08_SIB):
CREATE INDEX PA.IDX_DE08_SIB_FECHA_DEUDOR ON PA.PA_DE08_SIB (FECHA_CORTE, ID_DEUDOR, CLASIFICACION);
-- NOTA: En QA fue creado bajo schema JOOGANDO. En produccion debe ser bajo PA.
