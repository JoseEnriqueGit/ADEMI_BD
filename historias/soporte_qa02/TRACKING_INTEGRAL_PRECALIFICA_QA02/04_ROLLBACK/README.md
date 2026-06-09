# Rollback QA02

## Package body

Hay tres reversas de body, segun el punto al que se quiera volver:

| Archivo | Restaura | SHA-256 |
|---|---|---|
| `ROLLBACK_INCREMENTO_C_BODY_QA02.sql` | Body **Incremento B probado** (deshace solo el C) | `0C07E500BB10F564B7495B79AE9B41921B2F21692083988D9D073FD88BA499CD` |
| `ROLLBACK_INCREMENTO_B_BODY_QA02.sql` | Body **Incremento A probado** (deshace B y C) | `D12032ADE3845CDC1F64C3121665878B0B8679A7988CD1699D1E176796A78397` |
| `ROLLBACK_PR_PKG_REPRESTAMOS_BODY_QA02.sql` | Body **baseline sin instrumentar** (deshace A, B y C) | `EFD9F8588E9D23FD0B2D685B7A777320EDC86187724BE87557E7780939C748E3` |

> La reversa del Incremento B normalmente es solo el body (volver al A probado).
> Las columnas `NO_CREDITO`/`CODIGO_CLIENTE` pueden quedarse: el body del A no las
> referencia. Quitar las columnas (script 04 de abajo) exige haber vuelto antes a un
> body sin `track_candidato`, o el package quedaria `INVALID`.

Pasos:

1. detener o confirmar que el job no esta ejecutandose;
2. ejecutar el body de rollback completo en Toad;
3. ejecutar:

```sql
ALTER PACKAGE PR.PR_PKG_REPRESTAMOS COMPILE BODY;
SHOW ERRORS PACKAGE BODY PR.PR_PKG_REPRESTAMOS;
```

4. validar estado del package;
5. desactivar parametros `TRACK_PRECALIFICA_*`;
6. ejecutar una prueba controlada del job;
7. conservar las tablas de tracking hasta cerrar el diagnostico.

No eliminar tablas con `PURGE` como primera accion de reversa.

## DDL auxiliar

Cada script de creacion en `../01_DDL/` tiene su reversa individual aqui.
Orden inverso al de creacion:

| Reversa | Deshace |
|---|---|
| `04_ROLLBACK_ALTER_PR_JOB_PRECALIFICA_CANDIDATO_TRACK_QA02.sql` | Quita las columnas `NO_CREDITO`/`CODIGO_CLIENTE` del Incremento B (la tabla y sus filas se conservan). Ejecutar solo despues de revertir el body B. |
| `03_ROLLBACK_PARAMETROS_TRACK_PRECALIFICA_QA02.sql` | Borra los 3 parametros `TRACK_PRECALIFICA_*` (o desactivar con `VALOR='N'`, ver script). |
| `02_ROLLBACK_PR_JOB_PRECALIFICA_CANDIDATO_TRACK_QA02.sql` | `DROP` de `PR.PR_JOB_PRECALIFICA_CANDIDATO_TRACK` (Capa C). |
| `01_ROLLBACK_PR_JOB_PRECALIFICA_FILTRO_TRACK_QA02.sql` | `DROP` de la tabla + secuencia de la Capa B. |

- Los `DROP` de tablas **no usan `PURGE`**: dejan el objeto en la papelera para
  recuperarlo con `FLASHBACK` y conservar evidencia.
- Ejecutar la reversa de tablas **solo con aprobacion explicita**; la propuesta
  recomienda conservarlas hasta cerrar el diagnostico.
- Si en QA02 se usaron los **alias cortos 11g** (ver `../01_DDL/README.md`), ajustar
  los nombres en estos rollbacks antes de ejecutarlos.
