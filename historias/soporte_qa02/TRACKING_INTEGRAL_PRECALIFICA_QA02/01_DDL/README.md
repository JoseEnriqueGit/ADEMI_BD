# DDL auxiliar (QA02)

Todos los scripts fueron **aplicados en Toad/QA02** (01..03 el 2026-06-08; 04 el
2026-06-09; evidencia en `../05_RESULTADOS/RESULTADOS_QA02.md`). Son idempotentes,
pero no hace falta volver a ejecutarlos. Orden de ejecucion:

| # | Script | Crea | Estado |
|---|---|---|---|
| 0 | `00_VALIDAR_EXISTENCIA_OBJETOS_QA02.sql` | Solo lectura. Confirma version, nombres libres, tipo de `ID_REPRESTAMO`, tablespace `PR_IDX` y columnas de `PA_PARAMETROS_MVP`. | Ejecutado 2026-06-08 |
| 1 | `01_CREATE_PR_JOB_PRECALIFICA_FILTRO_TRACK_QA02.sql` | Tabla `PR.PR_JOB_PRECALIFICA_FILTRO_TRACK` (Capa B) + secuencia `SEQ_PR_JOB_PRECAL_FILTRO` + indices `IX_PRECAL_FILTRO_CONSULTA` e `IX_PRECAL_FILTRO_FECHA`. | Aplicado 2026-06-08 |
| 2 | `02_CREATE_PR_JOB_PRECALIFICA_CANDIDATO_TRACK_QA02.sql` | Tabla `PR.PR_JOB_PRECALIFICA_CANDIDATO_TRACK` (Capa C) + indice `IX_PRECAL_CAND_FECHA`. | Aplicado 2026-06-08 |
| 3 | `03_PARAMETROS_TRACK_PRECALIFICA_QA02.sql` | Parametros `TRACK_PRECALIFICA_*` en `PA.PA_PARAMETROS_MVP` (`CODIGO_MVP='REPRESTAMOS'`). | Aplicado 2026-06-08 |
| 4 | `04_ALTER_PR_JOB_PRECALIFICA_CANDIDATO_TRACK_QA02.sql` | **Incremento B:** agrega `NO_CREDITO NUMBER(7)` y `CODIGO_CLIENTE NUMBER(7)` (nullable) a la Capa C. No recrea la tabla ni toca PK/indices. | Aplicado 2026-06-09 |

Cada script es **idempotente** (no falla al reejecutarse) y sigue el patron de la tabla
existente `PR_JOB_PRECALIFICA_TRACK`. La reversa individual esta en `../04_ROLLBACK/`.

> **Incremento B:** ejecutar el script 04 **antes** de compilar el body con
> `track_candidato`; el `MERGE` referencia las columnas nuevas y sin ellas el body
> queda `INVALID`.

## Supuestos a confirmar con el script 00 antes de crear

1. **Version de Oracle / longitud de identificadores.** ✅ **Confirmado 2026-06-08:
   QA02 = Oracle 19c (limite 128 bytes); los nombres largos son validos y NO se
   requieren los alias cortos.** (Contexto: `PR_JOB_PRECALIFICA_FILTRO_TRACK` (31) y
   `PR_JOB_PRECALIFICA_CANDIDATO_TRACK` (34) solo fallarian en Oracle <= 11.2, que no
   es el caso. La tabla de alias cortos se conserva solo como referencia historica.)

   | Nombre largo (propuesta) | Alias corto 11g (<=30) |
   |---|---|
   | `PR_JOB_PRECALIFICA_FILTRO_TRACK` | `PR_JOB_PRECAL_FILTRO_TRACK` |
   | `PR_JOB_PRECALIFICA_CANDIDATO_TRACK` | `PR_JOB_PRECAL_CAND_TRACK` |

2. **Tipo de `PR.PR_REPRESTAMOS.ID_REPRESTAMO`.** Confirmado `NUMBER(14)` en el DDL del repo
   (`PR_REPRESTAMOS.sql:6`); la Capa C usa `NUMBER(14)`. El paso 5 del script 00 reconfirma
   el tipo vivo en QA02.

3. **Columnas obligatorias de `PA.PA_PARAMETROS_MVP`.** ✅ Validado en QA02: el INSERT carga
   `CODIGO_EMPRESA=1`, `CODIGO_MVP='REPRESTAMOS'`, `CODIGO_PARAMETRO`, `VALOR` y las 3 columnas
   `NOT NULL` sin `DEFAULT` detectadas (`DES_PARAMETRO`, `ADICIONADO_POR`, `FECHA_ADICION`).
   Empresa 1 = constante `vCodigoEmpresa` que usa `F_Obt_Parametro_Represtamo` para leer.

4. **Tablespace `PR_IDX`.** Los indices y llaves usan `TABLESPACE PR_IDX` (estandar ADEMI:
   indices fuera de tablespace DATA). Confirmar que exista en QA02.

Ningun DDL se considera aplicado hasta registrar fecha, usuario y resultado en
`../05_RESULTADOS/RESULTADOS_QA02.md`.
