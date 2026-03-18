# QA — Artefactos por entorno

Coloca aquí las versiones específicas de QA para objetos de base de datos. Mantén sólo lo que difiere de `db/`.

Estructura
- tables/: DDL de tablas (overrides o difs para QA)
- packages/: Paquetes PL/SQL específicos de QA
- functions/: Funciones standalone específicas de QA
- procedures/: Procedimientos standalone específicos de QA

Convenciones
- Nombres iguales al objeto base (`SCHEMA.OBJECT.sql`).
- Incluye al inicio del archivo: propósito del cambio, fecha y referencia a ticket.
- Acompaña cambios con script de rollback cuando aplique.

Ejemplo
- `env/QA/packages/PR.PR_PKG_DESEMBOLSO.sql`

