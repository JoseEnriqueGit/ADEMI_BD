# Análisis de estructura y contexto — ADEMI_BD (2026-06-05)

Revisión de cómo están organizados los directorios y de la experiencia de uso para Codex y Claude
Code, con foco en agilizar el trabajo entre máquinas y mantener limpio el contexto. Incluye las
mejoras aplicadas en esta revisión y las que quedan como propuesta.

## 1. Fortalezas (lo que ya está bien y NO hay que tocar)

- **Fuente de verdad única y madura:** `docs/instrucciones_ai/BASE_OPERATIVA.md` con reglas de
  idioma, entorno obligatorio, lectura completa, anti-regresión y flujos formalizados.
- **Skills canónicas** en `.agent-skills/` sincronizadas a `.claude/skills/`, con comandos puente
  bilingües. Un solo lugar de edición, propagación por script.
- **Trazabilidad por estado:** `historias/` separa optimizaciones/incidentes/apex/soporte por
  estado real, con `INVENTARIO.md` como tabla maestra y `ESTADO.md`/`README.md` por caso.
- **Compuerta anti-regresión a PROD:** baseline VIVO, inventario semántico, CHANGELOG por entorno,
  runbook y checklist. Es un control poco común y muy valioso.

## 2. Problemas detectados

### 🔴 Críticos
1. **No había "arranque de memoria".** El contexto estaba repartido (INVENTARIO, CHANGELOGs,
   notas) sin un punto de entrada único. Un agente nuevo (o la misma persona en otra PC) gastaba
   tiempo reconstruyéndolo. → **Resuelto** (Workstream A).
2. **Dependencia de una herramienta no portable ("engram").** La memoria dependía de software
   instalable solo en la PC personal; la PC del trabajo no puede instalarlo por seguridad. →
   **Resuelto:** la memoria ahora es texto plano + git en el repo, consumible por Claude Code web
   (corre en la nube) y Codex sin instalar nada.
3. **Ruido en raíz y `backups/`.** SQL sueltos con espacios en el nombre (`QA 02 REPRE*.sql`,
   `Before/After PKM/Tel.sql`) y huérfanos confusos (`ok.sql`, `PR_REPRESTAMOS_DUBLICADO CH.sql`).
   → **Resuelto:** movidos a `_cuarentena/` con índice de origen (sin borrar).

### 🟡 Importantes
4. **Veneno de contexto por archivos enormes.** `docs/notas/NOTAS_HISTORICO.md` (714 KB / ~27k
   líneas) es en realidad el cuerpo completo de `PR_PKG_REPRESTAMOS`. Cargarlo "para ubicarse"
   degrada el contexto. → **Resuelto:** índice navegable + marcado como zona fría.
5. **Sync solo en PowerShell.** `sync_agent_skills.ps1` no corre en Linux/web. → **Resuelto:**
   `scripts/sync_agent_skills.sh` portable.
6. **Discrepancia PROD.** `INVENTARIO.md` marca como confirmado en PROD solo los 8 índices, pero
   `Produccion/CHANGELOG.md` ya registra el pase del 2026-05-21 (package + vista + índice MVP). →
   **Señalado** en `CONTEXTO_ACTUAL.md`; reconciliar contra PROD (pendiente, requiere confirmación).

### 🟢 Mejorables (propuesta, ver Workstream D)
7. **QA02 con estructura `.gitkeep` parcialmente vacía:** documentar si es intencional.
8. **`Produccion/` con baseline mínimo:** ¿faltan objetos o requiere extracción de DDL VIVO?
9. **Nomenclatura mixta en `historias/apex/`:** IDs heterogéneos (números, IRD-NNN, descripciones).

## 3. Mejoras aplicadas en esta revisión

| # | Mejora | Workstream | Archivos clave |
|---|---|---|---|
| 1 | Memoria operativa (engram) en el repo | A | `docs/memoria/CONTEXTO_ACTUAL.md`, `BITACORA.md`, `_plantillas/` |
| 2 | Skill `memoria-engram` + comandos `/contexto` y `/bitacora` (Claude y Codex) | A | `.agent-skills/memoria-engram/`, `.claude/commands/`, `docs/prompts_codex/` |
| 3 | Hook `SessionStart` que autocarga el contexto en Claude Code web | A | `.claude/hooks/session-start.sh`, `.claude/settings.json` |
| 4 | Higiene de contexto (capas caliente/tibio/frío) + reglas en skills | E | `BASE_OPERATIVA.md`, skills `oracle-adm-bd`/`gestion-historias-opt`/`organizacion-repo-admi` |
| 5 | Índice navegable de `NOTAS_HISTORICO.md` | C | `docs/notas/INDICE_NOTAS_HISTORICO.md` |
| 6 | Sync portable en Bash | C | `scripts/sync_agent_skills.sh` |
| 7 | Cuarentena de archivos dudosos (sin borrar) | B | `_cuarentena/INDICE.md` + `raiz/` + `backups/` |
| 8 | README "Empieza aquí" + árbol actualizado | C | `README.md` |

## 4. Pendientes / propuestas (NO aplicadas)

- **Reconciliar discrepancia PROD** entre `INVENTARIO.md` y `Produccion/CHANGELOG.md`.
- **Clasificar `_cuarentena/`** caso por caso (destino real, nombres sin espacios).
- **Reglas `deny` de zonas frías:** DESCARTADO (2026-06-05). Se mantiene la higiene como guía por
  instrucción (no bloqueo duro), por preferencia del usuario, para no impedir lecturas legítimas.
- **Workstream D:** documentar QA02 vacío, baseline mínimo de PROD y normalización de `historias/apex/`.

## 5. Cómo agiliza esto el uso (Codex y Claude Code)

- **Arranque en 1 archivo:** `/contexto` o el hook llevan al agente directo al estado vivo.
- **Menos ruido = mejores respuestas:** las zonas frías y los índices evitan cargar cientos de KB.
- **Continuidad entre sesiones y máquinas:** la BITÁCORA + `git log` reconstruyen qué se hizo, sin
  depender de la PC personal ni de software externo.
- **Cierre disciplinado:** `/bitacora` deja rastro estandarizado para la siguiente sesión.
