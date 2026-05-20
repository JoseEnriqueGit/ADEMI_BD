-- OPT-008 BEFORE: Loop final de P_Carga_Precalifica_Cancelado
-- Fuente: PR.PR_PKG_REPRESTAMOS body.sql (QA) antes del commit 821d2f1
-- Las funciones F_Existe_* se llaman directamente en las condiciones,
-- resultando en hasta 7 SELECTs por iteracion en el peor caso.

-- (Fragmento del loop final dentro de P_Carga_Precalifica_Cancelado)

                      FOR A IN CUR_REPRESTAMO LOOP
                      DBMS_OUTPUT.PUT_LINE ( 'Entra AL CURSOR CUR_REPRESTAMO = '|| A.ID_REPRESTAMO  );

                        -- validar que tenga solicitud, que tenga canales
                        IF  PR.PR_PKG_REPRESTAMOS.F_Existe_Solicitudes(A.ID_REPRESTAMO)       -- <<< llamada 1
                            AND PR.PR_PKG_REPRESTAMOS.F_Existe_Canales(A.ID_REPRESTAMO)       -- <<< llamada 1
                            AND PR.PR_PKG_REPRESTAMOS.F_EXISTE_CREDITO(A.ID_REPRESTAMO) THEN  -- <<< llamada 1
                         PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(A.ID_REPRESTAMO, NULL, 'NP', NULL, 'Notificacion Pendiente', USER);

                         ELSE

                            IF  PR.PR_PKG_REPRESTAMOS.F_EXISTE_CREDITO(A.ID_REPRESTAMO) = FALSE THEN  -- <<< llamada 2
                             PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(A.ID_REPRESTAMO, NULL, 'RXT', NULL, 'No cumple con los criterios: Tipo de Credito ', USER);
                            ELSE
                                IF F_Existe_Solicitudes(A.ID_REPRESTAMO)                               -- <<< llamada 2
                                   AND F_Existe_Canales(A.ID_REPRESTAMO) = FALSE                       -- <<< llamada 2
                                   AND PR.PR_PKG_REPRESTAMOS.F_EXISTE_CREDITO(A.ID_REPRESTAMO) THEN   -- <<< llamada 3
                                    PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(A.ID_REPRESTAMO, NULL, 'CP', NULL, 'Solicitud Pendiente de Canal', USER);
                                ELSE
                                PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(A.ID_REPRESTAMO, NULL, 'AN', NULL, 'No cumple con los criterios: Solicitudes,Opciones', USER);
                                END IF;

                        END IF;

                       END IF;

                      END LOOP;

-- Conteo de llamadas a funciones por iteracion (peor caso, rama ELSE->ELSE):
-- F_Existe_Solicitudes: 2 veces
-- F_Existe_Canales:     2 veces
-- F_EXISTE_CREDITO:     3 veces
-- Total:                7 SELECTs
