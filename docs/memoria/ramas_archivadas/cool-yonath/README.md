# Rama archivada — `claude/cool-yonath`

> **Qué es esto.** Memoria de la rama `claude/cool-yonath` y preservación de su contenido **único**
> (lo que NO está en `master` por ningún path), para poder borrar la rama sin pérdida. Zona fría.
>
> `cool-yonath` tenía **historia NO relacionada** con `master` (sin ancestro común). Fue la **línea
> de desarrollo original** donde se hizo el grueso del trabajo OPT-001..015, mediciones, fixes QA02
> y documentación; `master` es una versión **reorganizada** que ya absorbió casi todo ese contenido.

## Identificación

| Campo | Valor |
|---|---|
| Rama | `claude/cool-yonath` |
| Estado | Línea de desarrollo original, **reemplazada por `master` reorganizado** |
| Tip (último commit) | `d87a427` — "Crear carpeta PA.P_DATOS_PERSONA ... instrucciones de versionado" |
| Rango de fechas | 2025-04-07 → 2026-04-13 |
| Autor principal | ogand |
| Commits únicos vs master | 166 |
| Archivos: únicos por **ruta** vs por **contenido** | 110 por ruta, pero solo **40 por contenido** (el resto son los mismos blobs movidos a otras rutas en master) |
| Fecha de archivo | 2026-06-05 |

## Por qué se archiva (no se fusiona)

Su contenido se reorganizó dentro de `master` (`historias/` por tipo/estado, `_cuarentena/`, etc.),
así que **fusionar la historia entera duplicaría todo con conflictos masivos**. Solo 40 archivos
tienen contenido que `master` no posee bajo ninguna ruta; esos se preservan aquí.

## Qué se preservó (40 archivos, en `artefactos/` con su ruta original)

### 1. Conocimiento valioso (documentación y mediciones originales) — CONSERVAR
- **READMEs originales de optimizaciones**: `historias/optimizaciones/OPT-001..015/README.md` y el
  `historias/optimizaciones/README.md`. Son la redacción original de cada OPT (master las reescribió;
  el contenido difiere, por eso son únicas).
- **Mapa y sesión**: `historias/optimizaciones/MAPA_JOBS.md` (22 KB, tabla maestra del Job1 +
  resultados OPT-014) y `SESION_PENDIENTE.md`.
- **Mediciones / explain plans**: `OPT-015/.../explain_plan_opt015.sql`, `OPT-015/.../HANDOFF.md`
  (handoff "para continuar en otra PC"), `scripts_medicion/INSTRUCCIONES_MEDICION*.md`,
  `scripts_medicion/01_DROP_INDICES_ROLLBACK.sql`, `03_CREATE_INDICES_RESTAURAR.sql`.
- **QA02**: `historias/QA02_BUG_AUTOINDEXADO_REPRESTAMOS/README.md` (13.8 KB).
- **Otros**: `docs/profiler/consultas_profiler.md`, `diff/f_obt_body_mensaje/f_obt_body_mensaje.sql`,
  `historias/419_CANALES_HABILITADO/README.md`.

### 2. Baselines alternos del paquete/vista — RECONCILIAR si hace falta
Versiones de objetos que difieren de las de `master`. **No son baseline vivo**; son evidencia
histórica para reconciliar (anti-regresión) si alguna vez se compara contra PROD:
- `ENTORNOS_ORACLE/QA/schemas/PR/packages/PR_PKG_REPRESTAMOS/{spec,body}.sql`
- `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/{spec,body}.sql`
- `ENTORNOS_ORACLE/DESARROLLO/schemas/PR/views/PR_V_ENVIO_REPRESTAMOS.sql`
- CHANGELOGs antiguos de QA / DESARROLLO y el placeholder `P_DATOS_PERSONA/_PENDIENTE_LLENAR.md`.

### 3. Versiones superadas — solo por completitud
Versiones viejas de archivos que `master` cambió a propósito (NO usar, están aquí para no perder
nada): `README.md` (raíz), `historias/README.md`, `.claude/commands/oracle-optimize.md` y
`oracle-explain.md` (comandos antiguos; master los dejó mínimos).

> Todos son **copia de archivo histórico**, NO baseline vivo. Si se retoma algo, incorporarlo por el
> flujo normal (`BASE_OPERATIVA.md` → incorporar objeto) a su ruta real en `ENTORNOS_ORACLE/...`.

## Cómo se obtuvo la lista

Comparación por **hash de contenido** (no por nombre) entre `origin/master` y `origin/claude/cool-yonath`:
de 110 archivos "únicos por ruta", solo 40 tenían blobs ausentes en master. Esos 40 son los que
están en `artefactos/`. El resto eran los mismos contenidos bajo rutas reorganizadas (p. ej.
`backups/ok.sql` → `_cuarentena/backups/ok.sql`).

## Tras confirmar este archivo

La rama remota `claude/cool-yonath` puede borrarse desde GitHub sin pérdida (su contenido único
quedó aquí; el resto ya vivía en `master`). Mientras la rama exista, todo sigue accesible vía el
tip `d87a427`.
