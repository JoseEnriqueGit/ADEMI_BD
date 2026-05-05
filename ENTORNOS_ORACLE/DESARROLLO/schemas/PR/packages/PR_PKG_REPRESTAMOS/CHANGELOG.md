# CHANGELOG - PR_PKG_REPRESTAMOS

> Historial de cambios del paquete principal de represtamos.
> Este es un objeto de alto trafico; se documenta individualmente.

---

<!-- Agregar nuevas entradas al inicio -->

## 2026-05-05 | OPT-017 Bulk collect en P_REGISTRO_SOLICITUD
- **Cambio**: `P_REGISTRO_SOLICITUD` deja de procesar con cursor `FOR` abierto sobre `PR_REPRESTAMOS`; ahora carga los `ID_REPRESTAMO` en memoria con `BULK COLLECT`, cierra el cursor y luego itera la coleccion.
- **Procedimientos afectados**: `P_REGISTRO_SOLICITUD`
- **Motivo**: mitigar el riesgo de `ORA-01555` por patron `FETCH across COMMIT` durante `JOB_PRECALIFICA_REPRESTAMO`.
- **Referencia**: `historias/optimizaciones/OPT-017_BULKCOLLECT_P_REGISTRO_SOLICITUD/README.md`

## 2026-04-16 | OPT-015 Validacion Rigurosa
- **Cambio**: se prepararon artefactos de prueba y handoff para validar equivalencia funcional de OPT-015 en `DESARROLLO`
- **Procedimientos afectados**: sin cambios de codigo en este paso; la validacion se centra en `Precalifica_Repre_Cancelado`, `Precalifica_Repre_Cancelado_hi`, `Actualiza_Precalificacion`, `P_Registrar_Solicitud` y `P_Generar_Bitacora`
- **Motivo**: dejar lista una metodologia deterministica para comparar `PR_REPRESTAMOS`, `PR_SOLICITUD_REPRESTAMO`, `PR_CANALES_REPRESTAMO`, `PR_OPCIONES_REPRESTAMO` y `PR_BITACORA_REPRESTAMO` desde otra PC con acceso a BD
- **Referencia**: `historias/optimizaciones/OPT-015_SETBASED_CANCELADO_REWRITE/PAQUETE_PRUEBAS_RIESGOS/PRUEBAS_OPT015_RIGUROSA.md`

## YYYY-MM-DD | Historia #XXX
- **Cambio**: descripcion del cambio
- **Procedimientos afectados**: P_Nombre1, P_Nombre2
- **Motivo**: razon del cambio
