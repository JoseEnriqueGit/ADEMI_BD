# ADM — Artefactos por entorno

Coloca aquí las versiones específicas de ADM para objetos de base de datos. Mantén sólo lo que difiere de `db/`.

Estructura
- tables/: DDL de tablas (overrides o difs para ADM)
- packages/: Paquetes PL/SQL específicos de ADM
- functions/: Funciones standalone específicas de ADM
- procedures/: Procedimientos standalone específicas de ADM

Convenciones
- Nombres iguales al objeto base (`SCHEMA.OBJECT.sql`).
- Incluye al inicio del archivo: propósito del cambio, fecha y referencia a ticket.
- Acompaña cambios con script de rollback cuando aplique.

Ejemplo
- `env/ADM/packages/PR.PR_PKG_DESEMBOLSO.sql`

