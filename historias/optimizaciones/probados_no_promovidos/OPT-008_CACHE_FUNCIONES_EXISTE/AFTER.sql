-- OPT-008 AFTER: Loop final de P_Carga_Precalifica_Cancelado con variables cacheadas
-- Aplicado en commit 821d2f1
-- Cada funcion se evalua UNA sola vez por iteracion del loop.

-- (Fragmento del loop final dentro de P_Carga_Precalifica_Cancelado)

                      FOR A IN CUR_REPRESTAMO LOOP
                      DBMS_OUTPUT.PUT_LINE ( 'Entra AL CURSOR CUR_REPRESTAMO = '|| A.ID_REPRESTAMO  );

                        -- Cache: evaluar cada funcion una sola vez por iteracion
                        v_tiene_solicitud := PR.PR_PKG_REPRESTAMOS.F_Existe_Solicitudes(A.ID_REPRESTAMO);
                        v_tiene_canales   := PR.PR_PKG_REPRESTAMOS.F_Existe_Canales(A.ID_REPRESTAMO);
                        v_tiene_credito   := PR.PR_PKG_REPRESTAMOS.F_EXISTE_CREDITO(A.ID_REPRESTAMO);

                        -- validar que tenga solicitud, que tenga canales
                        IF  v_tiene_solicitud AND v_tiene_canales AND v_tiene_credito THEN
                         PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(A.ID_REPRESTAMO, NULL, 'NP', NULL, 'Notificacion Pendiente', USER);

                         ELSE

                            IF  v_tiene_credito = FALSE THEN
                             PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(A.ID_REPRESTAMO, NULL, 'RXT', NULL, 'No cumple con los criterios: Tipo de Credito ', USER);
                            ELSE
                                IF v_tiene_solicitud AND v_tiene_canales = FALSE AND v_tiene_credito THEN
                                    PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(A.ID_REPRESTAMO, NULL, 'CP', NULL, 'Solicitud Pendiente de Canal', USER);
                                ELSE
                                PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(A.ID_REPRESTAMO, NULL, 'AN', NULL, 'No cumple con los criterios: Solicitudes,Opciones', USER);
                                END IF;

                        END IF;

                       END IF;

                      END LOOP;

-- Variables necesarias (declarar en el bloque DECLARE del procedimiento):
--   v_tiene_solicitud  BOOLEAN;
--   v_tiene_canales    BOOLEAN;
--   v_tiene_credito    BOOLEAN;
--
-- Conteo de llamadas a funciones por iteracion: siempre 3 (independiente de la rama)
