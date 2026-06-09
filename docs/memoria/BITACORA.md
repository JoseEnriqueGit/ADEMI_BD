# BITÁCORA DE SESIONES — ADEMI_BD

> Diario **append-only** de la memoria del proyecto (engram cronológico). Cada sesión de trabajo
> relevante deja un bloque al **inicio** del archivo (más reciente arriba). Junto con `git log` y
> `historias/INVENTARIO.md`, permite reconstruir el contexto en cualquier máquina sin software extra.
>
> Plantilla del bloque: `docs/memoria/_plantillas/ENTRADA_BITACORA.md`.
> Regla: no editar ni borrar entradas pasadas; solo agregar nuevas arriba.

---

## 2026-06-09 - Claude - Incremento B tracking integral precalifica QA02 (implementado Y PROBADO)

- **Objetivo:** implementar en el repo el Incremento B (cohorte individual del cierre en `PR.PR_JOB_PRECALIFICA_CANDIDATO_TRACK`) sin tocar la logica funcional ni la `spec.sql`, y probarlo en QA02.
- **PROBADO en QA02 (mismo dia):** secuencia ALTER 04 -> validar estructuras -> compilar body -> script 05 (BODY `VALID`, spec intacta, 0 errores) -> job -> conciliacion. Ejecucion `53D8BBE0BA0E44D9E063140311AC6BC6` (lote reducido a 1300 para la prueba): Capa C `1302/1302 == FINAL_*` (949 NP + 201 CP + 152 RXT + 0 AN + 0 OTRO), 0 nulos, 0 duplicados, todo `FLUJO='CIERRE'`, Capa B en 31/31. Costo del MERGE por candidato: `0.0011` vs `0.0009` s/cand del baseline A -> ~0.2 ms/candidato; NO se requiere variante bulk. Incidencias: `;` en PROMPT del script 05 (ORA-00900 en Toad, corregido) y Script Output sin volcar SELECTs -> se agrego `03_VALIDACION/07_RESUMEN_INCREMENTO_B_UNA_FILA_QA02.sql` (resumen en una fila, F9). **Decision (mismo dia): el lote queda en `1300` en QA02 a proposito** (corridas de prueba cortas).
- **Hecho:** snapshot del body A probado (`02_PACKAGE/body_QA02_INCREMENTO_A_PROBADO_20260609.sql`, hash `D12032AD...` verificado contra el canonico); helper autonomo `track_candidato` (MERGE idempotente, guard por `TRACK_PRECALIFICA_ACTIVO`, `COMMIT` propio, `ROLLBACK; NULL;` en handler) declarado junto a `track_filtro`; captura en el bloque de tracking por ID del cierre extendiendo el `SELECT` validado del A a `(ESTADO, NO_CREDITO, CODIGO_CLIENTE)` y llamando `track_candidato('CIERRE', id, no_credito, codigo_cliente, estado_observado)`. El `IF` funcional del cierre quedo intacto.
- **Decisiones:** `RESULTADO_ULTIMO` = estado **observado** en `PR_REPRESTAMOS` tras el cierre (no re-derivado): `P_Generar_Bitacora`/`P_Validar_Cambio_Estado` solo aplican el estado si `IND_CAMBIA_ESTADO_REPRE='S'` y tragan errores, asi que lo observado es la realidad; el decidido vive en `PR_BITACORA_REPRESTAMO` (DIAGNOSTICA). La tabla Capa C se extiende por `ALTER` (no se recrea) con `NO_CREDITO NUMBER(7)` y `CODIGO_CLIENTE NUMBER(7)` nullable. MERGE fila a fila aceptado (~5.2k candidatos en la corrida A); alternativa bulk documentada si la medicion muestra sobrecosto.
- **Scripts nuevos:** `01_DDL/04_ALTER_PR_JOB_PRECALIFICA_CANDIDATO_TRACK_QA02.sql` (idempotente), `03_VALIDACION/04..06_*_INCREMENTO_B_QA02.sql` (estructuras, compilacion, conciliacion Capa C vs `FINAL_*`), `04_ROLLBACK/04_ROLLBACK_ALTER_*` y `04_ROLLBACK/ROLLBACK_INCREMENTO_B_BODY_QA02.sql` (= body A probado).
- **Hash body con Incremento B (sin probar):** `0C07E500BB10F564B7495B79AE9B41921B2F21692083988D9D073FD88BA499CD`. La `spec.sql` no cambio.
- **Incremento C codificado (misma sesion, variante procedures elegida por el usuario):** estado package-private `g_track_cand_activo`/`g_track_id_ejecucion` + tipo `t_track_ids` + helper autonomo `track_candidatos_flujo` al tope del body; captura del BRUTO insertado tras el `FORALL INSERT` de las 5 procedures de flujo (Carga_Dirigida/Campana fuera de alcance); set/clear del estado en el job (init, fin OK, `WHEN OTHERS`). Sin DDL nuevo. Snapshot B probado en `02_PACKAGE/body_QA02_INCREMENTO_B_PROBADO_20260609.sql`; reversa `04_ROLLBACK/ROLLBACK_INCREMENTO_C_BODY_QA02.sql`; validaciones `03_VALIDACION/08..09`. Hash body C (sin probar): `2254380E9C4D0CB81D139DD47860F9BD030258C415A0F8A9694FB4759531B7FA`. Los sitios clonados byte a byte de las procedures `_hi` obligaron a cirugia por posicion (script PowerShell UTF-8/CRLF) en vez de edits por contexto.
- **Pendientes:** probar Incremento C en QA02 (body -> 08 -> job -> 09); capa DIAGNOSTICA. No se ejecuto Oracle desde el repo (todo en Toad por el usuario); nada se promovio a PROD; `body copy.sql` intacto.
- **Archivos tocados:** `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql`, `historias/soporte_qa02/TRACKING_INTEGRAL_PRECALIFICA_QA02/{01_DDL,02_PACKAGE,03_VALIDACION,04_ROLLBACK,05_RESULTADOS,06_HANDOFF}/`, `ESTADO.md`, `OBJETOS_AFECTADOS.md`, `docs/memoria/CONTEXTO_ACTUAL.md`, `docs/memoria/BITACORA.md`.

## 2026-06-09 - Codex - Prueba QA02 y cierre documental del Incremento A

- **Objetivo:** registrar la ejecucion real del tracking integral, cerrar la evidencia QA02 y preparar un commit atomico.
- **Hecho:** body compilado y job `PR.JOB_CARGA_PRECALIFICA_RD` ejecutado en QA02; ejecucion `53D427AF4F597DB0E063140311AC14C5` genero 31/31 metricas con orden `1..31` sin duplicados.
- **Resultados:** cinco flujos consolidaron `6654` RE; precalificacion concilio `88 RSB + 232 CLS/RCS + 1165 borrados + 5169 salida`; cierre concilio `3481 NP + 1455 CP + 233 RXT = 5169`.
- **Decisiones:** Incremento A queda probado en QA02; la historia permanece `QA02_EN_PRUEBAS` porque Incrementos B/C y la capa DIAGNOSTICA siguen pendientes. La `spec.sql` no cambio y no se promovio nada a PROD.
- **Rollback:** body baseline y reversas de DDL/parametros permanecen en `04_ROLLBACK/`; no fue necesario ejecutarlos.
- **Archivos:** evidencia y estado en `historias/soporte_qa02/TRACKING_INTEGRAL_PRECALIFICA_QA02/`; body canonico en `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql`.

## 2026-06-09 - Codex - Incremento A tracking integral precalifica QA02

- **Objetivo:** instrumentar `PR.PR_PKG_REPRESTAMOS` para iniciar las pruebas del tracking integral en QA02.
- **Hecho:** modificado unicamente el `body.sql` canonico dentro de `P_Carga_Precalifica_Cancelado`; agregado helper privado autonomo `track_filtro`, gating por `TRACK_PRECALIFICA_ACTIVO` y 31 metricas Capa B para arranque, cinco flujos, consolidado RE, precalificacion, XCORE, solicitud/canal y cierre.
- **Precision de medicion:** `RSB/CLS/RCS` se calculan por delta antes/despues para no sumar historicos; el cierre cuenta el estado real de cada ID de la cohorte procesada. La logica funcional y la `spec.sql` no cambiaron.
- **Validacion local:** `git diff --check` OK; hash del body instrumentado `F3169B1B4B396A606AC95754DDFAD3F9152DBCA66A4AB2670B80B685A1B9DE44`; snapshot previo `EFD9F8588E9D23FD0B2D685B7A777320EDC86187724BE87557E7780939C748E3`; spec identica al baseline.
- **Pruebas preparadas:** scripts Toad para validar estructuras, compilacion y conciliacion de la ultima ejecucion (31 metricas esperadas).
- **Pendientes:** ejecutar el body y las pruebas en Toad/QA02, registrar evidencia y decidir Incremento B/C. No se ejecuto Oracle desde el repo ni se creo commit antes de validar en base.
- **Archivos tocados:** `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql`, `historias/soporte_qa02/TRACKING_INTEGRAL_PRECALIFICA_QA02/02_PACKAGE/`, `03_VALIDACION/`, `05_RESULTADOS/`, `06_HANDOFF/`, `ESTADO.md`, `docs/memoria/BITACORA.md`.

## 2026-06-08 - Claude - DDL y rollbacks tracking integral QA02 + revision adversarial

- **Objetivo:** preparar el DDL auxiliar (Capas B y C) y sus rollbacks del tracking integral, sin ejecutar Oracle, dejandolos revisados.
- **Hecho:** 4 scripts en `01_DDL/` (validacion de existencia, `FILTRO_TRACK`, `CANDIDATO_TRACK`, parametros `TRACK_PRECALIFICA_*`) y 3 reversas en `04_ROLLBACK/`, siguiendo el patron de `PR_JOB_PRECALIFICA_TRACK`. Revision adversarial multiagente (6 dimensiones + verificacion): 11 hallazgos confirmados, 5 refutados.
- **Correcciones aplicadas:** parametros con `CODIGO_EMPRESA=1` explicito (constante `vCodigoEmpresa`, spec.sql:3) -> INSERT de exactamente 3 filas y DELETE de rollback simetrico; `TIPO_MEDICION NOT NULL`; indice `IX_PRECAL_FILTRO_FECHA` (simetria + purga); `ID_REPRESTAMO NUMBER(14)` confirmado en `PR_REPRESTAMOS.sql:6`; secuencia `CACHE 20 NOORDER`; comentarios FLASHBACK condicionados a `RECYCLEBIN=ON`; script 00 valida tambien constraints nombrados (incluye el CHECK).
- **Decisiones:** se conservaron los nombres largos de la propuesta (`PR_JOB_PRECALIFICA_FILTRO_TRACK` 31 bytes, `_CANDIDATO_TRACK` 34 bytes); requieren Oracle 12.2+ y hay alias cortos documentados para 11g. No se ejecuto Oracle ni se hizo commit.
- **Validacion QA02 (2026-06-08):** Oracle 19c (nombres largos validos); `PR_IDX` existe (286 indices); `PA_PARAMETROS_MVP` exige `DES_PARAMETRO`/`ADICIONADO_POR`/`FECHA_ADICION` (NOT NULL sin default) -> script 03 ajustado para cargarlas; `LOTE_DE_CARAGA_REPRESTAMO` en empresa 1 y sin `TRACK_*` previos. Corregido `;` dentro del PROMPT 3b que rompia el script en Toad.
- **Aplicado QA02 (2026-06-08):** scripts `01`/`02`/`03` ejecutados OK (`AJEREZ@QADEMI02_19C`): tablas Capa B/C, secuencia, 3 indices y 3 parametros `TRACK_*` creados (`3 rows created`).
- **Borrador de instrumentacion (2026-06-08):** mapeo del codigo real de las 6 fases + `02_PACKAGE/PROPUESTA_INSTRUMENTACION_BODY_QA02.md` (helpers `track_filtro`/`track_candidato`, instrumentacion por fase con COUNTs reales, por incrementos A/B/C). Revision adversarial multiagente: 14 hallazgos confirmados incorporados (gating de COUNTs por flag, `FECHA_CORTE` poblada, desglose REAL de precalificacion RSB/CLS/RCS/borrados, `FLUJO_RE_NETO` reetiquetado, bloque de cierre concreto). `body.sql` NO modificado.
- **Pendientes:** decision del usuario para codificar el Incremento A en el body; confirmar columnas de `PR_SOLICITUD_REPRESTAMO`/`PR_CANALES_REPRESTAMO` y la fuente de `RSB/CLS/RCS` (estado vs bitacora).
- **Archivos tocados:** `historias/soporte_qa02/TRACKING_INTEGRAL_PRECALIFICA_QA02/01_DDL/*`, `.../04_ROLLBACK/*`, `ESTADO.md`, `OBJETOS_AFECTADOS.md`, READMEs, `docs/memoria/BITACORA.md`.

## 2026-06-08 - Codex - Estructura implementacion tracking integral QA02

- **Objetivo:** preparar la implementacion del tracking integral sobre el body canonico QA02 con reversa verificable.
- **Hecho:** creada historia de soporte con carpetas de baseline, DDL, package, validacion, rollback, resultados y handoff; copiados body y spec actuales; creado body ejecutable de rollback.
- **Decisiones:** modificar solo el `body.sql` canonico; no tocar `body copy.sql` ni `spec.sql`; ejecutar Oracle exclusivamente desde Toad/QA02.
- **Pendientes:** ejecutar validacion base, preparar DDL y comenzar instrumentacion por fases.
- **Archivos tocados:** `historias/soporte_qa02/TRACKING_INTEGRAL_PRECALIFICA_QA02/`, `historias/INVENTARIO.md`, propuesta relacionada y `docs/memoria/BITACORA.md`.

## 2026-06-08 - Codex - Propuesta integral tracking precalifica QA02

- **Objetivo:** ampliar la propuesta de tracking para cubrir el recorrido completo documentado de precalificacion.
- **Hecho:** creada propuesta con tracking real y diagnostico, modelo de datos, puntos de captura, correcciones pendientes de trackers, validacion QA02 y rollback.
- **Decisiones:** mantener `PR_JOB_PRECALIFICA_TRACK` para tiempos; proponer tablas complementarias para filtros y pertenencia al lote; no modificar package ni ejecutar Oracle.
- **Pendientes:** aprobar alcance antes de preparar DDL, parche de body, validacion y rollback ejecutables.
- **Archivos tocados:** `PROPUESTA_TRACKING_INTEGRAL_PRECALIFICA_QA02.md`, documentos diagnosticos relacionados y `docs/memoria/BITACORA.md`.

## 2026-06-08 - Codex - Cierre restauracion y renombre DOCX QA02

- **Objetivo:** registrar la recuperacion del Word editado por el usuario y el nombre final del desglose.
- **Hecho:** confirmado `DOCUMENTACION_FILTROS_CANDIDATOS_QA02.docx` con 3 imagenes y renombrado el desglose a `DESGLOSE FILTROS PRECALIFICA.docx`.
- **Decisiones:** conservar la version del usuario recuperada desde Git y registrar el renombre sin alterar el contenido.
- **Pendientes:** ninguno.
- **Archivos tocados:** `DOCUMENTACION_FILTROS_CANDIDATOS_QA02.docx`, `DESGLOSE FILTROS PRECALIFICA.docx`, `docs/memoria/BITACORA.md`.

## 2026-06-08 - Codex - Restauracion DOCX con imagenes QA02

- **Objetivo:** recuperar `DOCUMENTACION_FILTROS_CANDIDATOS_QA02.docx` como estaba antes de ser sobrescrito desde Markdown.
- **Hecho:** restaurado el DOCX desde un blob recuperable de Git (`b8f7ccef...`) con 671,549 bytes, 3 tablas y 3 imagenes internas.
- **Decisiones:** se reemplazo el DOCX generado desde Markdown por la version editada previamente por el usuario.
- **Pendientes:** decidir si se desea commit de esta restauracion.
- **Archivos tocados:** `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/diagnosticos_precalifica/DOCUMENTACION_FILTROS_CANDIDATOS_QA02.docx`, `docs/memoria/BITACORA.md`.

## 2026-06-08 - Codex - DOCX generado desde desglose simple QA02

- **Objetivo:** convertir `DESGLOSE_SIMPLE_FILTROS_PRECALIFICA_QA02.md` al DOCX del mismo nombre base.
- **Hecho:** generado `DESGLOSE_SIMPLE_FILTROS_PRECALIFICA_QA02.docx` respetando titulos, listas, tablas y contenido del Markdown.
- **Decisiones:** se uso orientacion horizontal por la amplitud de las tablas y no se agregaron encabezados, pies ni contenido adicional.
- **Validacion:** coincidencia de 201 bloques entre Markdown y DOCX; 10 tablas y OpenXML valido.
- **Archivos tocados:** `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/diagnosticos_precalifica/DESGLOSE_SIMPLE_FILTROS_PRECALIFICA_QA02.docx`, `docs/memoria/BITACORA.md`.

## 2026-06-08 - Codex - DOCX sincronizado exactamente con Markdown QA02

- **Objetivo:** convertir `DOCUMENTACION_FILTROS_CANDIDATOS_QA02.md` al DOCX del mismo nombre base.
- **Hecho:** sobrescrito `DOCUMENTACION_FILTROS_CANDIDATOS_QA02.docx` con el contenido exacto del Markdown y eliminado el archivo alterno `_DESDE_MD`.
- **Decisiones:** no se agregaron encabezados, pies ni contenido adicional al documento fuente.
- **Validacion:** coincidencia de 63 bloques entre Markdown y DOCX; OpenXML valido.
- **Archivos tocados:** `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/diagnosticos_precalifica/DOCUMENTACION_FILTROS_CANDIDATOS_QA02.docx`, `docs/memoria/BITACORA.md`.

## 2026-06-08 - Codex - Word generado desde documentacion de filtros QA02

- **Objetivo:** crear un DOCX a partir de `DOCUMENTACION_FILTROS_CANDIDATOS_QA02.md`.
- **Hecho:** generado `DOCUMENTACION_FILTROS_CANDIDATOS_QA02_DESDE_MD.docx` con titulos, listas, tablas y bloque SQL formateados.
- **Decisiones:** se creo un archivo nuevo para no sobrescribir el DOCX existente modificado por el usuario.
- **Pendientes:** ninguno.
- **Archivos tocados:** `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/diagnosticos_precalifica/DOCUMENTACION_FILTROS_CANDIDATOS_QA02_DESDE_MD.docx`, `docs/memoria/BITACORA.md`.

## 2026-06-05 - Codex - Ajuste lenguaje revision lote precalifica QA02

- **Objetivo:** quitar jerga tecnica como "post cursor" del desglose para que sea mas claro para lectores funcionales.
- **Hecho:** reemplazada la seccion "Descartes post cursor" por "Revision adicional del lote" y ajustadas referencias relacionadas.
- **Decisiones:** se mantuvieron nombres tecnicos solo cuando son nombres de scripts, estados o columnas reales.
- **Pendientes:** ninguno.
- **Archivos tocados:** `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/diagnosticos_precalifica/DESGLOSE_SIMPLE_FILTROS_PRECALIFICA_QA02.md`, `docs/memoria/BITACORA.md`.

## 2026-06-05 - Codex - Reorden cronologico desglose precalifica QA02

- **Objetivo:** reorganizar el desglose de filtros como una campana real, desde el arranque del job hasta el cierre de estado.
- **Hecho:** reestructurado `DESGLOSE_SIMPLE_FILTROS_PRECALIFICA_QA02.md` por etapas cronologicas: arranque, carga por flujos, descartes post cursor, candidatos `RE`, precalificacion, XCORE, solicitud/canal y estados finales.
- **Decisiones:** se uso el orden real del job para los flujos y se dejo nota de que la numeracion de scripts corresponde al analisis.
- **Pendientes:** ninguno.
- **Archivos tocados:** `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/diagnosticos_precalifica/DESGLOSE_SIMPLE_FILTROS_PRECALIFICA_QA02.md`, `docs/memoria/BITACORA.md`.

## 2026-06-05 - Codex - Ajuste redaccion XCORE desglose QA02

- **Objetivo:** evitar que el desglose documente XCORE como valor fijo de QA02 cuando el proceso debe entenderse con criterio de produccion.
- **Hecho:** ajustada la redaccion de XCORE en `DESGLOSE_SIMPLE_FILTROS_PRECALIFICA_QA02.md` y agregada referencia al package de produccion.
- **Decisiones:** se dejo XCORE como calculo/asignacion del proceso, no como numero fijo.
- **Pendientes:** ninguno.
- **Archivos tocados:** `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/diagnosticos_precalifica/DESGLOSE_SIMPLE_FILTROS_PRECALIFICA_QA02.md`, `docs/memoria/BITACORA.md`.

## 2026-06-05 - Codex - Ampliacion score y solicitud en desglose QA02

- **Objetivo:** completar el desglose simple con filtros/validaciones posteriores al cursor, incluyendo score/XCORE y creacion de solicitud.
- **Hecho:** ampliado `DESGLOSE_SIMPLE_FILTROS_PRECALIFICA_QA02.md` con proceso comun post filtros, validaciones adicionales, aclaracion XCORE y referencias exactas del body.
- **Decisiones:** se documento que `Actualiza_XCORE_CUSTOM` corre en el job, mientras `PVALIDA_XCORE` y `PVALIDA_WORLD_COMPLIANCE` existen pero estan comentados en el flujo revisado.
- **Pendientes:** decidir si este desglose ampliado tambien debe pasarse al Word.
- **Archivos tocados:** `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/diagnosticos_precalifica/DESGLOSE_SIMPLE_FILTROS_PRECALIFICA_QA02.md`, `docs/memoria/BITACORA.md`.

## 2026-06-05 - Codex - Desglose simple filtros precalifica QA02

- **Objetivo:** explicar uno por uno los filtros de los cinco trackers de precalificacion en lenguaje simple.
- **Hecho:** creado `DESGLOSE_SIMPLE_FILTROS_PRECALIFICA_QA02.md` con secciones por flujo, filtros del cursor, filtros post cursor y resumen corto.
- **Decisiones:** se mantuvo como documentacion funcional, sin SQL extenso ni cambios de logica Oracle.
- **Pendientes:** revisar si se quiere incorporar este desglose al Word existente.
- **Archivos tocados:** `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/diagnosticos_precalifica/DESGLOSE_SIMPLE_FILTROS_PRECALIFICA_QA02.md`, `docs/memoria/BITACORA.md`.

## 2026-06-05 - Codex - Word resultados filtros candidatos QA02

- **Objetivo:** crear un archivo Word con referencias a los cinco scripts de trackers y sus resultados.
- **Hecho:** generado `DOCUMENTACION_FILTROS_CANDIDATOS_QA02.docx` junto a la documentacion Markdown, con tabla de scripts, resumen de resultados, detalle del filtro DE08 y conclusiones.
- **Decisiones:** no se inserto una imagen distinta a la enviada; se dejo apartado de evidencia visual pendiente porque la captura del chat no existe como archivo local.
- **Pendientes:** insertar la captura cuando el usuario la guarde o indique una ruta de imagen valida.
- **Archivos tocados:** `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/diagnosticos_precalifica/DOCUMENTACION_FILTROS_CANDIDATOS_QA02.docx`, `docs/memoria/BITACORA.md`.

## 2026-06-05 - Codex - Documentacion filtros candidatos QA02

- **Objetivo:** documentar de forma corta los filtros trabajados en los trackers de precalificacion de `PR.PR_PKG_REPRESTAMOS`.
- **Hecho:** creada nota `DOCUMENTACION_FILTROS_CANDIDATOS_QA02.md` en `diagnosticos_precalifica`, consolidando los resultados TXT/capturas y explicando el embudo cursor, lote y post cursor.
- **Decisiones:** no se cambio SQL ni logica Oracle; se dejo como evidencia QA02 puntual, separando DE08 con/sin `FECHA_CORTE` y los flujos HI que quedaron en cero por `F_CANCELACION`.
- **Pendientes:** validar nuevamente en Toad si cambian parametros (`DIAS_CANCELACION`, `LOTE_DE_CARAGA_REPRESTAMO`) o llega un nuevo corte DE08.
- **Archivos tocados:** `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/diagnosticos_precalifica/DOCUMENTACION_FILTROS_CANDIDATOS_QA02.md`, `docs/memoria/BITACORA.md`.

## 2026-06-05 · Claude Code · Archivo de rama `claude/cool-yonath` (antes de borrar)

- **Objetivo:** preservar el contenido único de `cool-yonath` antes de borrarla.
- **Hecho:** comparación por hash de blob master vs cool-yonath → de 110 archivos "únicos por ruta",
  solo **40 únicos por contenido**. Extraídos a `docs/memoria/ramas_archivadas/cool-yonath/artefactos/`
  + README de archivo + índice `ramas_archivadas/README.md`.
- **Qué se preservó:** READMEs originales OPT-001..015, MAPA_JOBS.md, HANDOFF OPT-015, scripts de
  medición/explain plans, doc QA02 auto-indexado, baselines alternos de PR_PKG_REPRESTAMOS (QA/QA02)
  y vista PR_V_ENVIO_REPRESTAMOS (marcados como reconciliar, no baseline vivo).
- **Decisión:** no fusionar (historia no relacionada; master ya reorganizó casi todo). Con el archivo
  hecho, la rama remota puede borrarse desde GitHub sin pérdida (tip `d87a427`).
- **Pendiente (usuario):** borrar en GitHub `cool-yonath` y `feature/api-bitacora-logs`.

## 2026-06-05 · Claude Code · Archivo de rama `feature/api-bitacora-logs` (antes de borrar)

- **Objetivo:** documentar razones/objetivo y preservar el código de la rama
  `feature/api-bitacora-logs` (dejada de lado) para poder borrarla sin perder memoria.
- **Hecho:** creado `docs/memoria/ramas_archivadas/feature-api-bitacora-logs/` con README (objetivo,
  motivación, diseño, recuperación) y `artefactos/` (paquete `IA_API_LOGGER`, tablas `IA_API_LOGS` y
  `IA_HTTP_STATUS_CATALOG`, secuencia, doc de flujo y ejemplo ORDS).
- **Resumen del cambio archivado:** componente institucional de bitácora/logs para APIs ORDS con
  transacciones autónomas, saneo de payloads sensibles y clasificación por catálogo HTTP.
- **Decisión:** estado DESCARTADO/dejado de lado; no se fusiona (historia no relacionada). Con el
  archivo hecho, la rama remota ya puede borrarse desde GitHub sin pérdida (tip `a3cedad`).
- **Pendiente (usuario):** borrar en GitHub `feature/api-bitacora-logs` cuando confirme el archivo.

## 2026-06-05 · Claude Code · Consolidación a master + topología de ramas

- **Objetivo:** fusionar el trabajo a la rama principal y limpiar ramas.
- **Hecho:**
  - `master` ← `claude/directory-structure-review-rA8GH` por **fast-forward** limpio (7 commits, 36
    archivos). Pusheado. Rama de trabajo borrada en local.
- **Hallazgos de ramas (fetch):** además de master existen 4 ramas:
  - `anti-regresion-promocion-prod`: 0 commits únicos → **ya contenida en master** (redundante).
  - `claude/cool-yonath`: 166 commits, **historia NO relacionada** con master (sin ancestro común);
    su contenido OPT-015/HANDOFF parece ya estar en master vía `historias/`.
  - `feature/api-bitacora-logs`: 102 commits, **historia NO relacionada**; estructura distinta
    (`SCRIPTS`, `db`, `env`, `proyectos`, `Certificado digital ORACLE FORMS`) con contenido único.
- **Decisiones:** NO fusionar las dos ramas huérfanas (forzar `--allow-unrelated-histories`
  corrompería master). Dejarlas intactas. El borrado remoto se hace desde GitHub (push delete da 403).
- **Pendiente (usuario, en GitHub):** borrar las ramas seguras `claude/directory-structure-review-rA8GH`
  y `anti-regresion-promocion-prod`. Conservar `cool-yonath` y `feature/api-bitacora-logs` hasta
  decidir si rescatar contenido único con cherry-pick.

## 2026-06-05 · Claude Code (web) · Reorganización de directorios + sistema de memoria

- **Objetivo:** criticar la organización del repo y mejorar el contexto/experiencia para Codex y
  Claude Code; idear una "memoria/engram" que viva en el repo (la PC del trabajo no instala software).
- **Hecho:**
  - Creado `docs/memoria/` con `CONTEXTO_ACTUAL.md` (punto de entrada único), `BITACORA.md` (este
    diario) y plantilla de entrada.
  - Nueva skill canónica `memoria-engram` + comandos `/contexto` y `/bitacora` (Claude y Codex).
  - Hook `SessionStart` para autocargar el contexto en Claude Code web.
  - Modelo de higiene de contexto (capas caliente/tibio/frío) en BASE_OPERATIVA y CONTEXTO_ACTUAL;
    reglas "qué leer / qué NO cargar" añadidas a las skills.
  - Script portable `scripts/sync_agent_skills.sh` (equivalente Bash del .ps1).
  - Índice de `NOTAS_HISTORICO.md` (volcado de ~27k líneas del body de PR_PKG_REPRESTAMOS).
  - Cuarentena `_cuarentena/` para SQL sueltos de la raíz y huérfanos confusos de `backups/`.
  - Análisis completo en `docs/memoria/ANALISIS_ESTRUCTURA_2026-06-05.md`.
- **Decisiones:** memoria = índice de contexto vivo + bitácora + hook (todo texto plano + git);
  archivos dudosos a cuarentena sin borrar ni renombrar; reorganizaciones grandes solo propuestas.
- **Decisión adicional (2026-06-05):** la higiene de contexto queda como **guía por instrucción**,
  no como bloqueo `deny` en settings (el usuario prefiere flexibilidad para lecturas legítimas).
  El hook `SessionStart` aplica también en la extensión de VS Code (no es solo web).
- **Pendientes:** clasificar archivos en `_cuarentena/INDICE.md` caso por caso;
  reconciliar discrepancia PROD (INVENTARIO vs CHANGELOG).
- **Archivos tocados:** ver `git log` de la rama `claude/directory-structure-review-rA8GH`.
