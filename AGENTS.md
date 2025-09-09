# Repository Guidelines

## Project Structure & Modules
- Core SQL: `TABLES/` (DDL), `VIEWS/` (views), `PACKAGES/` (PL/SQL specs/bodies), `JOBS/` (schedulers), `SCRIPT/` (one‑off scripts).
- Feature areas: `CHAMPION/` (champion/challenger experiment), `CD/` (certificado digital), `PACKAGES/DIGCERT_SIMULADOR/`.
- Docs & assets: `.vscode/`, `CHAMPION/README.md`, `CD/Instrucciones.md`; backups in `BACK_UP/`. Environment diffs in `COMPARAR PAQUETES/`.
- Naming pattern: files commonly follow `SCHEMA.OBJECT.sql` (e.g., `PR.PR_REPRESTAMOS.sql`).

## Build, Test, and Development Commands
- Apply scripts with Oracle SQL*Plus or SQLcl from repo root:
  - `sqlplus USER/PASS@DB @TABLES/PR.PR_CREDITOS.sql`
  - `sqlplus USER/PASS@DB @PACKAGES/CD.PKG_CD_DEVENG_INTERESES.sql`
  - `sqlplus USER/PASS@DB @VIEWS/PR.PR_V_ENVIO_REPRESTAMOS.sql`
- Jobs/campaigns: `sqlplus ... @JOBS/PR.JOB_CARGA_PRECALIFICA_RD.sql`.
- Run in non‑prod first; include a rollback (DROP/RENAME or restore steps) with each change.

## Coding Style & Naming Conventions
- SQL keywords uppercase; 4‑space indentation; one statement per line; use `--` comments for context and intent.
- Database identifiers: prefer Spanish `snake_case` for new tables/columns; keep existing schemas/object names unchanged.
- Packages: keep specs/bodies grouped in `PACKAGES/`; when split, suffix clearly (e.g., `... SPECS.sql`, `... BODY.sql`).

## Testing Guidelines
- Add lightweight validations under `*/TEST/` with `TEST_` prefix (e.g., `TEST_CARDS.SQL`). Use `SELECT` assertions to verify DDL/DML effects.
- For heavy queries, capture `EXPLAIN PLAN`/`DBMS_XPLAN.DISPLAY` and rowcount deltas before/after.
- Keep scripts idempotent; avoid destructive operations without guards and backups.

## Commit & Pull Request Guidelines
- Commits: concise, imperative, in Spanish when possible. Format: `[CARPETA] Resumen corto` (e.g., `TABLES: Nueva PR_CREDITOS`).
- PRs must include: scope/objetivo, objetos afectados (schema/tablas/paquetes), pasos de migración y rollback, evidencias de prueba (salidas SQL, capturas) y notas de performance.
- Link issues/tickets and include screenshots for changes to dashboards/consultas.

## Security & Configuration
- Never commit credentials or connection strings. Use `TNSNAMES.ORA`, environment variables, or local secure config.
- Align editor settings with `.vscode/settings.json`; do not change global formatting without consensus.
- For environment differences (ADM/QA/PROD), place comparison scripts in `COMPARAR PAQUETES/` and document target.

