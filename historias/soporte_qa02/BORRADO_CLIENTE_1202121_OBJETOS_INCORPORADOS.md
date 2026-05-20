# Objetos incorporados - QA02 borrado cliente 1202121

Fecha: 2026-04-24

Origen: DDL pegado por el usuario desde QA ADEMI 02 / QA02.

Motivo: disponer localmente de las tablas involucradas en los errores `ORA-02292` del borrado del cliente/persona `1202121`.

## CC

- `ENTORNOS_ORACLE/QA02/schemas/CC/tables/CUENTA_EFECTIVO.sql`
- `ENTORNOS_ORACLE/QA02/schemas/CC/tables/INT_CUENTA_DIARIO.sql`

## PA

- `ENTORNOS_ORACLE/QA02/schemas/PA/tables/CLIENTE.sql`
- `ENTORNOS_ORACLE/QA02/schemas/PA/tables/DIR_PERSONAS.sql`
- `ENTORNOS_ORACLE/QA02/schemas/PA/tables/PERSONAS.sql`
- `ENTORNOS_ORACLE/QA02/schemas/PA/tables/PERSONAS_FISICAS.sql`

## Pendiente

- `PA.DIAS_IMPORT_PERS`
- `MG.DIAS_IMPORT_PERS`

La captura de Toad muestra que ambas tablas tienen la constraint `FK_DIAS_IMP_PERS_PERS_FISICAS`, pero todavia falta incorporar su DDL completo.
