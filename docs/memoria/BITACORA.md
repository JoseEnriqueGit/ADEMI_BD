# BITÁCORA DE SESIONES — ADEMI_BD

> Diario **append-only** de la memoria del proyecto (engram cronológico). Cada sesión de trabajo
> relevante deja un bloque al **inicio** del archivo (más reciente arriba). Junto con `git log` y
> `historias/INVENTARIO.md`, permite reconstruir el contexto en cualquier máquina sin software extra.
>
> Plantilla del bloque: `docs/memoria/_plantillas/ENTRADA_BITACORA.md`.
> Regla: no editar ni borrar entradas pasadas; solo agregar nuevas arriba.

---

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
