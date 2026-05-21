# 2026-05-21 - Pase PR_PKG_REPRESTAMOS, vista de envio e indice MVP a PROD

| Campo | Valor |
|---|---|
| Fecha | 2026-05-21 |
| Origen | QA02 / archivos finales de pase |
| Destino | PROD |
| Schema principal | PR |
| Objetos | Package, vista, sinonimo publico, indice |
| Estado | Preparado para pase |
| Confirmacion en CHANGELOG | [ENTORNOS_ORACLE/Produccion/CHANGELOG.md](../../ENTORNOS_ORACLE/Produccion/CHANGELOG.md) |
| Rollback | [2026-05-21_REPRESTAMOS_PACKAGE_VIEW_INDEX_ROLLBACK.sql](2026-05-21_REPRESTAMOS_PACKAGE_VIEW_INDEX_ROLLBACK.sql) |

## Objetos promovidos

| # | Objeto | Tipo | Archivo |
|---|---|---|---|
| 1 | `PR.PR_PKG_REPRESTAMOS` | Package spec | `ENTORNOS_ORACLE/Produccion/schemas/PR/packages/PR_PKG_REPRESTAMOS/spec.sql` |
| 2 | `PR.PR_PKG_REPRESTAMOS` | Package body | `ENTORNOS_ORACLE/Produccion/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` |
| 3 | `PR.PR_V_ENVIO_REPRESTAMOS` | View | `ENTORNOS_ORACLE/Produccion/schemas/PR/views/PR_V_ENVIO_REPRESTAMOS.sql` |
| 4 | `PUBLIC.PR_V_ENVIO_REPRESTAMOS` | Public synonym | `ENTORNOS_ORACLE/Produccion/schemas/PR/views/PR_V_ENVIO_REPRESTAMOS.sql` |
| 5 | `PA.IDX_PARAM_MVP_EMP_MVP_PARAM` | Index | `ENTORNOS_ORACLE/Produccion/schemas/PA/tables/PA_PARAMETROS_MVP/indexes.sql` |

## Normalizacion de archivos

- `PR_PKG_REPRESTAMOS.pks` fue normalizado como `ENTORNOS_ORACLE/Produccion/schemas/PR/packages/PR_PKG_REPRESTAMOS/spec.sql`.
- `PR_PKG_REPRESTAMOS.pkb` fue normalizado como `ENTORNOS_ORACLE/Produccion/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql`.
- Ambos archivos sueltos de la raiz fueron verificados por SHA256 contra la ruta formal antes de retirarlos de la raiz del repo.
- Los archivos `PR_PKG_REPRESTAMOS 1 1 ORIGINAL.*`, `PR_PKG_REPRESTAMOS 1 21-5.*` y scripts QA no forman parte de esta normalizacion.

## Orden de ejecucion sugerido

1. Compilar `PR.PR_PKG_REPRESTAMOS` spec.
2. Compilar `PR.PR_PKG_REPRESTAMOS` body.
3. Crear o reemplazar `PR.PR_V_ENVIO_REPRESTAMOS`.
4. Crear o reemplazar sinonimo publico `PR_V_ENVIO_REPRESTAMOS`.
5. Crear indice `PA.IDX_PARAM_MVP_EMP_MVP_PARAM` si no existe.
6. Validar objetos invalidos y permisos de consulta.

## Validacion en Toad

```sql
SHOW ERRORS PACKAGE PR.PR_PKG_REPRESTAMOS;
SHOW ERRORS PACKAGE BODY PR.PR_PKG_REPRESTAMOS;
SHOW ERRORS VIEW PR.PR_V_ENVIO_REPRESTAMOS;

SELECT owner, object_name, object_type, status
  FROM all_objects
 WHERE (owner = 'PR' AND object_name IN ('PR_PKG_REPRESTAMOS', 'PR_V_ENVIO_REPRESTAMOS'))
    OR (owner = 'PUBLIC' AND object_name = 'PR_V_ENVIO_REPRESTAMOS')
 ORDER BY owner, object_type, object_name;

SELECT owner, index_name, table_name, tablespace_name, status
  FROM all_indexes
 WHERE owner = 'PA'
   AND index_name = 'IDX_PARAM_MVP_EMP_MVP_PARAM';

SELECT *
  FROM PR.PR_V_ENVIO_REPRESTAMOS
 WHERE ROWNUM <= 10;
```

## Rollback operativo

Script preparado: `historias/_promociones/2026-05-21_REPRESTAMOS_PACKAGE_VIEW_INDEX_ROLLBACK.sql`.

1. Recompilar el `spec` y `body` anteriores de `PR.PR_PKG_REPRESTAMOS` desde el respaldo productivo tomado por DBA antes del pase.
2. Recompilar la version anterior de `PR.PR_V_ENVIO_REPRESTAMOS` si existia en Produccion.
3. Si el sinonimo publico fue creado nuevo y debe retirarse:

```sql
DROP PUBLIC SYNONYM PR_V_ENVIO_REPRESTAMOS;
```

4. Si el indice debe retirarse:

```sql
DROP INDEX PA.IDX_PARAM_MVP_EMP_MVP_PARAM;
```

## Observaciones

- El package final depende del overload `F_OBT_BODY_MENSAJE(pNombres, pFecha, pCanal)` usado por la vista.
- El indice `PA.IDX_PARAM_MVP_EMP_MVP_PARAM` usa tablespace `PA_IDX`.
- La validacion funcional final del job `PR.JOB_CARGA_PRECALIFICA_RD` debe registrarse en QA02/PROD segun resultado de Toad.
