# BITÁCORA DE SESIONES — ADEMI_BD

> Diario **append-only** de la memoria del proyecto (engram cronológico). Cada sesión de trabajo
> relevante deja un bloque al **inicio** del archivo (más reciente arriba). Junto con `git log` y
> `historias/INVENTARIO.md`, permite reconstruir el contexto en cualquier máquina sin software extra.
>
> Plantilla del bloque: `docs/memoria/_plantillas/ENTRADA_BITACORA.md`.
> Regla: no editar ni borrar entradas pasadas; solo agregar nuevas arriba.

---

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
