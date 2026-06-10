# INVENTARIO MAESTRO DE HISTORIAS

> Tabla viva con el estado de cada caso del repositorio. Mantener al dia con cada cambio de estado.
> Ultima actualizacion: 2026-05-27.

## Convencion de estados

| Estado | Significado |
|---|---|
| PRODUCCION | Cambio desplegado en PROD. Confirmado en `ENTORNOS_ORACLE/Produccion/CHANGELOG.md`. |
| QA02 | Cambio aplicado en QA02. No confirmado en PROD. |
| QA | Cambio aplicado en QA. No confirmado en PROD. |
| DESARROLLO | Cambio aplicado en DESARROLLO. No confirmado en QA/PROD. |
| PROBADO_NO_PROMOVIDO | Probado en QA/QA02/DESARROLLO con evidencia, decision de no promover (o aun no se promovio). |
| DESCARTADO | No entrega beneficio o reemplazado. Artefactos preservados como historia. |
| DIAGNOSTICO | Investigacion, medicion o explain plan. No modifica objetos productivos. |
| PROPUESTA | Documentada, sin aprobacion. |
| PENDIENTE_CONFIRMAR | Necesita revision manual del responsable para clasificar. |
| INCIDENTE_ABIERTO | Incidente en investigacion / con accion pendiente. |
| SOPORTE | Material reusable (medicion, mapas, plantillas). No es un caso por si. |

## Optimizaciones

| ID | Subcambio | Estado | Entorno probado | Fecha | Ubicacion nueva |
|---|---|---|---|---|---|
| OPT-001 | Codigo SQL227 WORLD_COMPLIANCE | PROBADO_NO_PROMOVIDO | QA | 2026-03-18 | `optimizaciones/probados_no_promovidos/OPT-001_SQL227_WORLD_COMPLIANCE/` |
| OPT-002 | Indice `IDX_DE08_SIB_FECHA_DEUDOR` | PRODUCCION | PROD | 2026-04-23 | `optimizaciones/produccion/INDICES_2026-04-23/` |
| OPT-002 | Codigo cursores SIB | PROBADO_NO_PROMOVIDO | QA | 2026-03-19 | `optimizaciones/probados_no_promovidos/OPT-002_OBT_IDENTIFICACION_CURSORES_SIB/` |
| OPT-003 | COMMIT fuera de loop Actualiza_Precalificacion | PROBADO_NO_PROMOVIDO | QA | 2026-03-19 | `optimizaciones/probados_no_promovidos/OPT-003_COMMITS_ACTUALIZA_PRECALIFICACION/` |
| OPT-004 | Codigo set-based Actualiza_Precalificacion | PROBADO_NO_PROMOVIDO | QA | 2026-03-19 | `optimizaciones/probados_no_promovidos/OPT-004_SETBASED_ACTUALIZAR_MTO_CREDITO/` |
| OPT-004 | Indice `IDX_DE08_NOCRED_CALIF_FECHA` | PRODUCCION | PROD | 2026-04-23 | `optimizaciones/produccion/INDICES_2026-04-23/` |
| OPT-005 | Simplificacion Actualiza_XCORE_CUSTOM | PROBADO_NO_PROMOVIDO | QA | 2026-03-19 | `optimizaciones/probados_no_promovidos/OPT-005_SIMPLIFICAR_ACTUALIZA_XCORE_CUSTOM/` |
| OPT-006 | COMMITs P_REGISTRO_SOLICITUD | PROBADO_NO_PROMOVIDO | QA | 2026-03-19 | `optimizaciones/probados_no_promovidos/OPT-006_COMMITS_P_REGISTRO_SOLICITUD/` |
| OPT-007 | COMMIT PVALIDA_XCORE | PROBADO_NO_PROMOVIDO | QA | 2026-03-19 | `optimizaciones/probados_no_promovidos/OPT-007_COMMIT_PVALIDA_XCORE/` |
| OPT-008 | Cache funciones EXISTE | PROBADO_NO_PROMOVIDO | QA | 2026-03-19 | `optimizaciones/probados_no_promovidos/OPT-008_CACHE_FUNCIONES_EXISTE/` |
| OPT-009 | Codigo subqueries F_Obtener_Nuevo_Credito | PROBADO_NO_PROMOVIDO | QA | 2026-04-06 | `optimizaciones/probados_no_promovidos/OPT-009_SUBQUERIES_F_OBTENER_NUEVO_CREDITO/` |
| OPT-009 | Indice `IDX_CREDITOS_HI_NOCREDITO` | PRODUCCION | PROD | 2026-04-23 | `optimizaciones/produccion/INDICES_2026-04-23/` |
| OPT-010 | NOT EXISTS inline F_TIENE_GARANTIA | PROBADO_NO_PROMOVIDO | QA | 2026-03-19 | `optimizaciones/probados_no_promovidos/OPT-010_INLINE_F_TIENE_GARANTIA/` |
| OPT-010 | Indice `IDX_GARANTIAS_TIPO_SB` | PRODUCCION | PROD | 2026-04-23 | `optimizaciones/produccion/INDICES_2026-04-23/` |
| OPT-011 | Codigo Anular creditos cancelados | PROBADO_NO_PROMOVIDO | QA | 2026-04-07 | `optimizaciones/probados_no_promovidos/OPT-011_SQL371_ANULAR_CREDITOS_CANCELADOS/` |
| OPT-011 | Indice `IDX_REPRESTAMOS_EMP_EST_NOCRED` | PRODUCCION | PROD | 2026-04-23 | `optimizaciones/produccion/INDICES_2026-04-23/` |
| OPT-012 | UPDATE PROMOCION_PERSONA | DESCARTADO | QA | 2026-04-07 | `optimizaciones/descartados/OPT-012_SQL364_UPDATE_PROMOCION_PERSONA/` |
| OPT-013 | Indice `IDX_DE05_SIB_CASTIGO_CEDULA` | PRODUCCION | PROD | 2026-04-23 | `optimizaciones/produccion/INDICES_2026-04-23/` |
| OPT-014 | Medicion real de 4 indices | DIAGNOSTICO | DESARROLLO | 2026-04-13 | `optimizaciones/diagnosticos/OPT-014_INDICES_MEDICION_REAL/` |
| OPT-015 | Set-based Cancelado/Cancelado_hi | PROBADO_NO_PROMOVIDO | DESARROLLO | 2026-04-15 | `optimizaciones/probados_no_promovidos/OPT-015_SETBASED_CANCELADO_REWRITE/` |
| OPT-016 | Indice `IDX_REPRESTAMOS_ESTADO_COV` | PRODUCCION | PROD | 2026-04-23 | `optimizaciones/produccion/INDICES_2026-04-23/` |
| OPT-016 | Indice `IDX_SOLREPRE_IDREPRE_TIPCRED` | PRODUCCION | PROD | 2026-04-23 | `optimizaciones/produccion/INDICES_2026-04-23/` |
| OPT-016 | Codigo P_REGISTRO_SOLICITUD asociado | PROBADO_NO_PROMOVIDO | DESARROLLO | 2026-04 | (Reportado dentro de OPT-017 - sin carpeta propia) |
| OPT-017 | Bulk collect P_REGISTRO_SOLICITUD | PROBADO_NO_PROMOVIDO | DESARROLLO | 2026-05-06 | `optimizaciones/probados_no_promovidos/OPT-017_BULKCOLLECT_P_REGISTRO_SOLICITUD/` |
| OPT-018 | Bulk collect final P_Carga_Precalifica_Cancelado | PROBADO_NO_PROMOVIDO | DESARROLLO | 2026-05-06 | `optimizaciones/probados_no_promovidos/OPT-018_BULKCOLLECT_FINAL_P_CARGA_PRECALIFICA_CANCELADO/` |
| OPT-019 | Explain plan + indice `IDX_PARAM_MVP_EMP_MVP_PARAM` (aprobado para PROD) | DIAGNOSTICO | DESARROLLO | 2026-05-20 | `optimizaciones/diagnosticos/OPT-019_EXPLAIN_PLAN_INDICES_SNAPSHOT/` |
| OPT-020 | Vistas garantia + cambio body QA02 + script PR_V_ENVIO_REPRESTAMOS | DESCARTADO | QA02 | 2026-05-20 | `optimizaciones/descartados/OPT-020_VISTAS_GARANTIA_REPRESTAMOS/` |
| VALIDACION_ACUMULADA | Validacion acumulada base OPT-015 | DIAGNOSTICO | DESARROLLO | 2026-04-17 | `optimizaciones/diagnosticos/VALIDACION_ACUMULADA_REPRESTAMOS_BASE_OPT015/` |
| Propuestas hardcodeo | SQL371 + CURSORES_ANULAR | PROPUESTA | - | 2026-03-19 | `optimizaciones/propuestas/` |
| MAPA_JOBS / PENDIENTES / SESION_PENDIENTE / scripts_medicion | Material reusable | SOPORTE | - | varias | `optimizaciones/soporte/` |

## Incidentes

| Caso | Estado | Entorno | Fecha | Ubicacion nueva |
|---|---|---|---|---|
| INC_SNAPSHOT_TOO_OLD_JOB_PRECALIFICA | INCIDENTE_ABIERTO | PROD reportado, OPT-017/018 en DESARROLLO | 2026-05-01 | `incidentes/abiertos/INC_SNAPSHOT_TOO_OLD_JOB_PRECALIFICA/` |
| QA02_RXT_REPRESTAMOS_LOTE_10000 | DIAGNOSTICO | QA02 | 2026-05-13 | `incidentes/diagnosticos/QA02_RXT_REPRESTAMOS_LOTE_10000/` |

## Soporte QA02 (no son incidentes ni OPT)

| Caso | Estado | Entorno | Fecha | Ubicacion nueva |
|---|---|---|---|---|
| QA02_BUG_AUTOINDEXADO_REPRESTAMOS | QA02 | QA02 | 2026-03-26 | `soporte_qa02/BUG_AUTOINDEXADO_REPRESTAMOS/` |
| QA02_BORRADO_CLIENTE_1202121 | DIAGNOSTICO (objetos incorporados) | QA02 | 2026-04-24 | `soporte_qa02/BORRADO_CLIENTE_1202121/OBJETOS_INCORPORADOS.md` |
| JOB_CARGA_PRECALIFICA_RD_COMPLETA_QA02 | QA02 | QA02 | 2026-05-25 | `soporte_qa02/JOB_CARGA_PRECALIFICA_RD_COMPLETA_QA02/` |
| TRACKERS_PRECALIFICA_CURSOR_QA02 | SOPORTE | QA02 | 2026-05-27 | `soporte_qa02/TRACKERS_PRECALIFICA_CURSOR_QA02/` |
| TRACKING_INTEGRAL_PRECALIFICA_QA02 | QA02_EN_PRUEBAS (A, B y C probados; pendiente DIAGNOSTICA) | QA02 | 2026-06-10 | `soporte_qa02/TRACKING_INTEGRAL_PRECALIFICA_QA02/` |
| INV_REGISTROS_FALTANTES_ONBOARDING | DIAGNOSTICO | - | - | `soporte_qa02/INV_REGISTROS_FALTANTES_ONBOARDING/` |

## APEX / Negocio

| Caso | Estado | Entorno | Fecha | Ubicacion nueva |
|---|---|---|---|---|
| 375_CASOS | PENDIENTE_CONFIRMAR | - | - | `apex/pendientes_confirmacion/375_CASOS/` |
| 419_CANALES_HABILITADO | PENDIENTE_CONFIRMAR | - | - | `apex/pendientes_confirmacion/419_CANALES_HABILITADO/` |
| 421_DASHBOARD_GERENTES | PENDIENTE_CONFIRMAR | - | - | `apex/pendientes_confirmacion/421_DASHBOARD_GERENTES/` |
| 441_453_454 | PENDIENTE_CONFIRMAR | - | - | `apex/pendientes_confirmacion/441_453_454/` |
| 442_OPT_SOLICITUDES | QA (query v1 listo para PROD, indices PENDIENTES) | QA | 2026 | `apex/en_qa/442_OPT_SOLICITUDES/` |
| 519_REPROCESAR_ESTADO_H | DESARROLLO (pruebas OK 2026-04-15) | DESARROLLO | 2026-04-15 | `apex/en_qa/519_REPROCESAR_ESTADO_H/` |
| 530_CARD_INFORMATIVA_BACKOFFICE | QA (validado) | QA | 2026 | `apex/en_qa/530_CARD_INFORMATIVA_BACKOFFICE/` |
| IRD-525_GESTION_ESTADOS_TRAZABILIDAD | QA (validado, pendiente confirmar promocion) | QA | 2026-05-22 | `apex/pendientes_confirmacion/IRD-525_GESTION_ESTADOS_TRAZABILIDAD/` |
| IRD-546_PAGINA_77_ORIGEN_FIADOR_CODIGO_SUCURSAL | PENDIENTE_CONFIRMAR | - | - | `apex/pendientes_confirmacion/IRD-546_PAGINA_77_ORIGEN_FIADOR_CODIGO_SUCURSAL/` |
| MENU_AGRUPAR_PRODUCTOS_DIGITALES | PENDIENTE_CONFIRMAR | - | - | `apex/pendientes_confirmacion/MENU_AGRUPAR_PRODUCTOS_DIGITALES/` |
| PAGINA_134_CARDS_SALDO_PESO_DOLAR | PENDIENTE_CONFIRMAR | - | - | `apex/pendientes_confirmacion/PAGINA_134_CARDS_SALDO_PESO_DOLAR/` |
| PAGINA_134_CUENTAS_DIGITALES_PRODUCTOS_210_211 | QA | QA | 2026-05-01 | `apex/en_qa/PAGINA_134_CUENTAS_DIGITALES_PRODUCTOS_210_211/` |
| PAGINA_135_AGREGAR_NOMBRE_PRODUCTO | PENDIENTE_CONFIRMAR | - | - | `apex/pendientes_confirmacion/PAGINA_135_AGREGAR_NOMBRE_PRODUCTO/` |
| PAGINA_135_CARDS_VIGENCIA_POR_ESTADO | PENDIENTE_CONFIRMAR | - | - | `apex/pendientes_confirmacion/PAGINA_135_CARDS_VIGENCIA_POR_ESTADO/` |
| PAGINA_135_FILTRO_PRODUCTOS_DIGITALES | QA (REVISION_RELEASE preparada) | QA | 2026-05-01 | `apex/en_qa/PAGINA_135_FILTRO_PRODUCTOS_DIGITALES/` |
| CHAMPION (paquete de referencia) | SOPORTE | - | - | `apex/champion/CHAMPION/` |
