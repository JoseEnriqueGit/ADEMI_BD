# Repository Guidelines

## Project Structure & Modules
- Core DB: `db/tables/` (DDL), `db/views/` (views), `db/packages/` (PL/SQL specs/bodies), `db/jobs/` (schedulers), `db/scripts/` (one‑off scripts).
- Feature areas: `proyectos/CHAMPION/` (champion/challenger), `proyectos/CD/` (certificado digital), dashboards y campañas bajo `proyectos/*`.
- Docs & assets: `.vscode/`, `proyectos/CHAMPION/README.md`, `proyectos/CD/Instrucciones.md`; backups en `backups/`. Dif. de ambientes en `env/comparar_paquetes/`.
- Naming pattern: `SCHEMA.OBJECT.sql` (ej.: `PR.PR_REPRESTAMOS.sql`).

## Build, Test, and Development Commands
- Ejecutar con SQL*Plus/SQLcl desde la raíz del repo:
  - `sqlplus USER/PASS@DB @db/tables/PR.PR_CREDITOS.sql`
  - `sqlplus USER/PASS@DB @db/packages/CD.PKG_CD_DEVENG_INTERESES.sql`
  - `sqlplus USER/PASS@DB @db/views/PR.PR_V_ENVIO_REPRESTAMOS.sql`
- Jobs/campañas: `sqlplus ... @db/jobs/PR.JOB_CARGA_PRECALIFICA_RD.sql`.
- Primero en no‑prod; incluye rollback (DROP/RENAME o restore) por cambio.

## Coding Style & Naming Conventions
- SQL keywords uppercase; 4 espacios; una sentencia por línea; usa `--` para contexto e intención.
- Identificadores: español `snake_case` en objetos nuevos; respeta esquemas/nombres existentes.
- Paquetes: agrupa specs/bodies en `db/packages/`; cuando separe, sufijos claros (`... SPECS.sql`, `... BODY.sql`).

## Testing Guidelines
- Valida bajo `*/TEST/` con prefijo `TEST_` (ej.: `TEST_CARDS.SQL`). Usa `SELECT` de verificación para efectos DDL/DML.
- Para consultas pesadas, captura `EXPLAIN PLAN`/`DBMS_XPLAN.DISPLAY` y diferencias de conteo.
- Mantén scripts idempotentes; evita operaciones destructivas sin guardas y backups.

## Commit & Pull Request Guidelines
- Commits: concisos, imperativos, en español. Formato: `[CARPETA] Resumen corto` (ej.: `db/tables: Nueva PR_CREDITOS`).
- PRs: alcance/objetivo, objetos afectados (schema/tablas/paquetes), pasos de migración/rollback, evidencias (salidas SQL, capturas) y notas de performance.
- Vincula issues/tickets y adjunta capturas para dashboards/consultas.

## Security & Configuration
- No subas credenciales/cadenas de conexión. Usa `TNSNAMES.ORA`, variables de entorno o config segura local.
- Alinea el editor a `.vscode/settings.json`; no cambies formato global sin consenso.
- Diferencias de ambientes (ADM/QA/PROD) en `env/comparar_paquetes/` y documenta el destino.
