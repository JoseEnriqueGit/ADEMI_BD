-- ============================================================
-- OPT-009 AFTER: F_Obtener_Nuevo_Credito con JOINs directos
-- Paquete: PR_PKG_REPRESTAMOS (body.sql, QA)
-- Cost rama ELSE: 909 (vs 17,232 original)
-- PENDIENTE DE APLICAR al body.sql
-- Requiere indice: PR.IDX_CREDITOS_HI_NOCREDITO ON PR.PR_CREDITOS_HI(NO_CREDITO)
-- ============================================================

-- Paso previo (ya aplicado):
-- CREATE INDEX PR.IDX_CREDITOS_HI_NOCREDITO ON PR.PR_CREDITOS_HI(NO_CREDITO);

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
                -- >>> QUERY OPTIMIZADA CON JOINs DIRECTOS <<<
                -- Scalar subquery eliminado. 3 subqueries IN/NOT IN/EXISTS reemplazadas con JOINs.
                SELECT MIN(NT.TIPO_CREDITO)
                INTO   NUEVO_TIPO
                FROM   PR_REPRESTAMOS          R
                LEFT JOIN PR_CREDITOS           C  ON C.NO_CREDITO    = R.NO_CREDITO
                LEFT JOIN PR_CREDITOS_HI        H  ON H.NO_CREDITO    = R.NO_CREDITO  -- usa indice IDX_CREDITOS_HI_NOCREDITO
                LEFT JOIN PR_TIPO_CREDITO       T  ON T.TIPO_CREDITO  = COALESCE(C.TIPO_CREDITO, H.TIPO_CREDITO)
                -- Tipo de credito destino candidato
                JOIN  PR_TIPO_CREDITO           NT ON NT.CODIGO_SUB_APLICACION = T.CODIGO_SUB_APLICACION
                                                   AND NT.GRUPO_TIPO_CREDITO   = T.GRUPO_TIPO_CREDITO
                -- Rango de monto (reemplaza subqueries MIN/MAX)
                JOIN  PR_PLAZO_CREDITO_REPRESTAMO P ON P.TIPO_CREDITO = NT.TIPO_CREDITO
                                                    AND R.MTO_PREAPROBADO BETWEEN P.MONTO_MIN AND P.MONTO_MAX
                -- Vigente, sin campana especial, no FMO (reemplaza subqueries 2 y 3)
                JOIN  PR_TIPO_CREDITO_REPRESTAMO  RV ON RV.TIPO_CREDITO = NT.TIPO_CREDITO
                                                     AND RV.OBSOLETO = 0
                                                     AND NVL(RV.CREDITO_CAMPANA_ESPECIAL,'N') <> 'S'
                                                     AND NVL(RV.CREDITO_FMO,'N') <> 'S'
                -- Verificar si origen es FMO para regla de facilidad (reemplaza subquery 1)
                LEFT JOIN PR_TIPO_CREDITO_REPRESTAMO FMO ON FMO.TIPO_CREDITO = T.TIPO_CREDITO
                                                         AND FMO.CREDITO_FMO = 'S'
                WHERE R.ID_REPRESTAMO = pIdReprestamo
                  -- Regla FACILIDAD: Si origen es FMO (FMO encontro match), ignorar FACILIDAD
                  -- Si no es FMO, exigir que coincida FACILIDAD
                  AND (FMO.TIPO_CREDITO IS NOT NULL OR T.FACILIDAD_CREDITIC = NT.FACILIDAD_CREDITIC);

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
