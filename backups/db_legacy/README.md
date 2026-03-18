# db/ — Base de Datos

Este directorio centraliza artefactos de BD. Úsalo para DDL/DML y objetos que viven en Oracle.

- tables/: DDL de tablas, secuencias y datos semilla.
- views/: definiciones de vistas.
- packages/: paquetes PL/SQL (specs y bodies).
- jobs/: definiciones de jobs/schedulers.
- scripts/: scripts utilitarios/one‑off (idempotentes cuando sea posible).
- procedimientos/: procedimientos puntuales no empaquetados.

Ejecución (SQL*Plus/SQLcl) desde la raíz del repo:
- Crear/actualizar tablas: `sqlplus USER/PASS@DB @db/tables/PR.PR_CREDITOS.sql`
- Vistas: `sqlplus USER/PASS@DB @db/views/PR.PR_V_ENVIO_REPRESTAMOS.sql`
- Paquetes: `sqlplus USER/PASS@DB @db/packages/PR.PR_PKG_DESEMBOLSO.sql`
- Jobs: `sqlplus USER/PASS@DB @db/jobs/PR.JOB_CARGA_PRECALIFICA_RD.sql`

Orden recomendado de despliegue:
1) tables → 2) views → 3) packages → 4) jobs → 5) scripts.

Buenas prácticas
- Primero en no‑prod; cada cambio con plan de rollback.
- Mantén nombres de archivos tal como están (no renombrar).
- Sin credenciales en el repositorio; usa TNS/variables de entorno.
- Para rendimiento, captura EXPLAIN PLAN/DBMS_XPLAN cuando cambies consultas críticas.

