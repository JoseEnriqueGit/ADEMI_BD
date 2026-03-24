-- ============================================================
-- OPT-002 BEFORE: Cursores originales en Actualiza_Precalificacion
-- Paquete: PR_PKG_REPRESTAMOS (body.sql, QA)
-- ============================================================

-- CURSOR CUR_DE08_SIB (linea ~2615 original)
CURSOR CUR_DE08_SIB IS
    SELECT B.ROWID ID, b.id_represtamo, NVL(A.CLASIFICACION,'NULA') CLASIFICACION
    FROM PA_DE08_SIB A,
         PR_REPRESTAMOS B
    WHERE A.FECHA_CORTE = TO_DATE('19/11/2024','DD/MM/YYYY')
    AND OBT_IDENTIFICACION_PERSONA(B.CODIGO_CLIENTE,'1') = A.ID_DEUDOR
    AND B.ESTADO = 'RE'
    AND PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO ( 'DE08_SIB' ) = 'S' ;

-- CURSOR CUR_DE05_SIB (linea ~2631 original)
CURSOR CUR_DE05_SIB IS
    SELECT B.ROWID ID, b.id_represtamo, A.cedula, a.entidad
    FROM PA_DE05_SIB A,
            PR_REPRESTAMOS B
    WHERE A.FECHA_CASTIGO = (SELECT MAX(FECHA_CASTIGO) FROM PA_DE05_SIB)
    AND OBT_IDENTIFICACION_PERSONA(B.CODIGO_CLIENTE,'1') = A.cedula
    AND B.ESTADO = 'RE'
    AND PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO ( 'CASTIGOS_SIB' ) = 'S';

-- INDICE: No existia ningun indice en PA_DE08_SIB sobre FECHA_CORTE
