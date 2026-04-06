-- ============================================================
-- OPT-009 BEFORE: F_Obtener_Nuevo_Credito completa
-- Paquete: PR_PKG_REPRESTAMOS (body.sql, QA, ~linea 9688)
-- Cost rama ELSE: 17,232
-- Este es el codigo ACTUAL en el body.sql
-- ============================================================

FUNCTION F_Obtener_Nuevo_Credito(pIdReprestamo IN NUMBER)
    RETURN NUMBER IS
        NUEVO_TIPO NUMBER;
        CURSOR CREDITO IS
            SELECT TIPO_CREDITO_DESTINO
            FROM PR.PR_REPRESTAMO_CAMPANA_DET
            WHERE TIPO_CREDITO_ORIGEN = (SELECT TIPO_CREDITO FROM PR.PR_SOLICITUD_REPRESTAMO WHERE ID_REPRESTAMO = pIdReprestamo);
    BEGIN
        IF PR.PR_PKG_REPRESTAMOS.F_Validar_Tipo_Represtamo(pIdReprestamo) THEN
        DBMS_OUTPUT.PUT_LINE('EL REPRESTAMO ES DE CAMPANA ESPECIAL');
            FOR A IN CREDITO LOOP
                BEGIN
                    SELECT T.TIPO_CREDITO
                    INTO NUEVO_TIPO
                    FROM PR.PR_TIPO_CREDITO_REPRESTAMO T, PR.PR_REPRESTAMOS R
                    WHERE T.TIPO_CREDITO = A.TIPO_CREDITO_DESTINO
                      AND R.MTO_PREAPROBADO >= (SELECT MIN(MONTO_MIN) FROM PR.PR_PLAZO_CREDITO_REPRESTAMO WHERE TIPO_CREDITO = T.TIPO_CREDITO)
                      AND R.MTO_PREAPROBADO <= (SELECT MAX(MONTO_MAX) FROM PR.PR_PLAZO_CREDITO_REPRESTAMO WHERE TIPO_CREDITO = T.TIPO_CREDITO)
                      AND ROWNUM <= 1
                      AND R.ID_REPRESTAMO = pIdReprestamo;
                    DBMS_OUTPUT.PUT_LINE('CREDITO DE CAMPANA ESPECIAL');
                    DBMS_OUTPUT.PUT_LINE('Nuevo Tipo de Credito: ' || NUEVO_TIPO);
                    RETURN NUEVO_TIPO;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        DBMS_OUTPUT.PUT_LINE('No se encontro un nuevo tipo de credito para el TIPO_CREDITO_DESTINO = ' || A.TIPO_CREDITO_DESTINO);
                    WHEN OTHERS THEN
                        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
                END;
            END LOOP;
        ELSE

            BEGIN
            DBMS_OUTPUT.PUT_LINE('EL REPRESTAMO ES DE NORMAL');
                -- >>> QUERY CON SCALAR SUBQUERIES (PROBLEMA) <<<
                SELECT (
                    SELECT MIN(NT.TIPO_CREDITO)
                    FROM   PR_TIPO_CREDITO                NT
                    JOIN   PR_PLAZO_CREDITO_REPRESTAMO    P
                         ON  P.TIPO_CREDITO = NT.TIPO_CREDITO
                    WHERE R.MTO_PREAPROBADO BETWEEN P.MONTO_MIN AND P.MONTO_MAX
                      AND NT.CODIGO_SUB_APLICACION = T.CODIGO_SUB_APLICACION
                      AND NT.GRUPO_TIPO_CREDITO    = T.GRUPO_TIPO_CREDITO
                      --  Regla de FACILIDAD: Si el ORIGEN (T) es FMO se ignora
                      --                      Si no es FMO debe coincidir
                      AND ( T.TIPO_CREDITO IN (SELECT TIPO_CREDITO                    -- <<< subquery IN
                                               FROM   PR_TIPO_CREDITO_REPRESTAMO
                                               WHERE  CREDITO_FMO = 'S')
                            OR T.FACILIDAD_CREDITIC = NT.FACILIDAD_CREDITIC )
                      -- Excluir tipos de credito FMO
                      AND NT.TIPO_CREDITO NOT IN (SELECT TIPO_CREDITO                 -- <<< subquery NOT IN
                                                  FROM   PR_TIPO_CREDITO_REPRESTAMO
                                                  WHERE  CREDITO_FMO = 'S')
                      -- Vigente y sin campana especial
                      AND EXISTS ( SELECT 1                                            -- <<< subquery EXISTS
                            FROM   PR_TIPO_CREDITO_REPRESTAMO R
                            WHERE  R.TIPO_CREDITO = NT.TIPO_CREDITO AND  R.OBSOLETO = 0 AND  NVL(R.CREDITO_CAMPANA_ESPECIAL,'N') <> 'S'
                      )
                ) INTO NUEVO_TIPO
                FROM PR_REPRESTAMOS   R
                LEFT JOIN PR_CREDITOS      C ON C.NO_CREDITO = R.NO_CREDITO
                LEFT JOIN PR_CREDITOS_HI   H ON H.NO_CREDITO = R.NO_CREDITO       -- <<< sin indice = Full Table Scan
                LEFT JOIN PR_TIPO_CREDITO  T ON T.TIPO_CREDITO = C.TIPO_CREDITO OR T.TIPO_CREDITO = H.TIPO_CREDITO
                WHERE R.ID_REPRESTAMO = pIdReprestamo;
                RETURN NUEVO_TIPO;
                DBMS_OUTPUT.PUT_LINE ( 'NUEVO CREDITO '|| NUEVO_TIPO || 'REPRESTAMOS' || pIdReprestamo);
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    DBMS_OUTPUT.PUT_LINE('No se encontro un nuevo tipo de credito en la parte ELSE');
            END;
        END IF;
        -- Si no se ha retornado un valor hasta este punto, retorna un valor por defecto
        RETURN 1;
    END F_Obtener_Nuevo_Credito;
