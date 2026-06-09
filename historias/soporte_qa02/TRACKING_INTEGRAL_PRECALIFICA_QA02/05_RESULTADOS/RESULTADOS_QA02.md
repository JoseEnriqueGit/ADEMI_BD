# Resultados QA02

Estado: DDL auxiliar, Incremento A e Incremento B aplicados y probados en QA02.

## Validacion base (script 00)

- Fecha: 2026-06-08
- Usuario / conexion: `AJEREZ@QADEMI02_19C`
- Version: Oracle Database 19c Standard Edition 2 (19.0.0.0.0) -> nombres largos validos
- Nombres nuevos: los 6 objetos NO EXISTIAN (libres)
- Tablespace indices: `PR_IDX` existe (286 indices de PR)
- `PR_REPRESTAMOS.ID_REPRESTAMO`: `NUMBER(14)`
- `PA_PARAMETROS_MVP`: columnas NOT NULL sin DEFAULT adicionales = `DES_PARAMETRO`, `ADICIONADO_POR`, `FECHA_ADICION` (incorporadas al script 03)
- Parametro modelo: `LOTE_DE_CARAGA_REPRESTAMO` en `CODIGO_EMPRESA=1` (VALOR=130000); sin filas `TRACK_*` previas
- Incidencia corregida: `;` dentro del `PROMPT 3b` rompia el script en modo "execute as script" (ORA-00900). Resuelto.

## Implementacion - DDL auxiliar

- DDL aplicado: 2026-06-08, `AJEREZ@QADEMI02_19C`, modo "Execute as Script" (F5).

| Script | Resultado en Toad | Objetos |
|---|---|---|
| `01_CREATE_PR_JOB_PRECALIFICA_FILTRO_TRACK_QA02.sql` | 4x `PL/SQL procedure successfully completed` + `Capa B creada/validada` | Tabla `PR_JOB_PRECALIFICA_FILTRO_TRACK` + `SEQ_PR_JOB_PRECAL_FILTRO` + `IX_PRECAL_FILTRO_CONSULTA` + `IX_PRECAL_FILTRO_FECHA` |
| `02_CREATE_PR_JOB_PRECALIFICA_CANDIDATO_TRACK_QA02.sql` | 2x `PL/SQL procedure successfully completed` + `Capa C creada/validada` | Tabla `PR_JOB_PRECALIFICA_CANDIDATO_TRACK` + `IX_PRECAL_CAND_FECHA` |
| `03_PARAMETROS_TRACK_PRECALIFICA_QA02.sql` | `3 rows created` + `Commit complete` | Parametros `TRACK_PRECALIFICA_ACTIVO=S`, `_DETALLE_CURSOR=S`, `_RETENCION_DIAS=90` (empresa 1) |

- Body preparado: 2026-06-09.
- Hash body Incremento A probado:
  `D12032ADE3845CDC1F64C3121665878B0B8679A7988CD1699D1E176796A78397`.
- Body compilado en QA02: 2026-06-09.
- `spec.sql`: sin cambios; hash igual al baseline
  `73C2432FC0C42808C288A70DF90A7B3380B8EB3726498921A265AAE4743B0AB5`.
- Errores: ninguno en la creacion del DDL.

## Prueba funcional

- Fecha: 2026-06-09.
- Job: `PR.JOB_CARGA_PRECALIFICA_RD`.
- ID de ejecucion: `53D427AF4F597DB0E063140311AC14C5`.
- Tracking activo: `TRACK_PRECALIFICA_ACTIVO = S`.
- Fecha de corte capturada: `2026-05-29`.
- Valor de lote capturado: `130000`.
- Cobertura: `31` metricas, `31` ordenes distintos, rango `1..31`,
  resultado `OK`.
- Ventana observada entre la primera y la ultima fila Capa B:
  `10:43:53.793` a `12:18:07.908`, aproximadamente `1:34:14`.
  Esta ventana no sustituye la duracion oficial del encabezado del job.

### Construccion de candidatos

| Flujo | RE antes | RE despues | Neto |
|---|---:|---:|---:|
| `Precalifica_Represtamo` | 0 | 6188 | +6188 |
| `Precalifica_Represtamo_fiadores` | 6188 | 6509 | +321 |
| `Precalifica_Represtamo_fiadores_hi` | 6509 | 6509 | 0 |
| `Precalifica_Repre_Cancelado` | 6509 | 6609 | +100 |
| `Precalifica_Repre_Cancelado_hi` | 6609 | 6654 | +45 |

RE consolidado tras los cinco flujos: `6654`.

### Precalificacion

| Resultado | Cantidad |
|---|---:|
| Entrada `RE` | 6654 |
| `RSB` clasificacion/fiador | 88 |
| `CLS/RCS` clasificacion o castigo | 232 |
| Borrados sin codigo / OFAC | 1165 |
| Salida `RE` con codigo | 5169 |

Conciliacion manual confirmada:

```text
88 + 232 + 1165 + 5169 = 6654
```

### XCORE, solicitud y canal

| Medicion | Cantidad |
|---|---:|
| XCORE entrada | 5169 |
| XCORE procesados | 5169 |
| XCORE salida | 5169 |
| Solicitudes nuevas | 5153 |
| Canales nuevos | 3625 |

`XCORE_RECHAZADOS` quedo como `NO_EJECUTADO`, porque `PVALIDA_XCORE`
permanece comentado en QA02.

### Cierre

| Estado | Cantidad |
|---|---:|
| `NP` | 3481 |
| `CP` | 1455 |
| `RXT` | 233 |
| `AN` | 0 |
| Otro | 0 |

Conciliacion manual confirmada:

```text
3481 + 1455 + 233 + 0 + 0 = 5169
```

## Incremento B - APLICADO Y PROBADO en QA02 (2026-06-09)

- Cambios aplicados:
  - Body canonico: helper `track_candidato` (MERGE autonomo a
    `PR.PR_JOB_PRECALIFICA_CANDIDATO_TRACK`) + captura de la cohorte individual
    en el loop de cierre (`FLUJO='CIERRE'`, `RESULTADO_ULTIMO` = estado observado,
    `NO_CREDITO`, `CODIGO_CLIENTE`). Hash body Incremento B:
    `0C07E500BB10F564B7495B79AE9B41921B2F21692083988D9D073FD88BA499CD`.
  - DDL: `01_DDL/04_ALTER_PR_JOB_PRECALIFICA_CANDIDATO_TRACK_QA02.sql`
    (agrega `NO_CREDITO NUMBER(7)` y `CODIGO_CLIENTE NUMBER(7)`, idempotente).
  - La Capa B no cambia: la corrida debe seguir dando 31 metricas.

### Pasos exactos para probar en Toad (`AJEREZ@QADEMI02_19C`)

1. Ejecutar como script (F5): `01_DDL/04_ALTER_PR_JOB_PRECALIFICA_CANDIDATO_TRACK_QA02.sql`.
   Esperado: `Incremento B: columnas NO_CREDITO y CODIGO_CLIENTE agregadas/validadas`.
2. Ejecutar `03_VALIDACION/04_VALIDAR_ESTRUCTURAS_INCREMENTO_B_QA02.sql`.
   Esperado: 2 columnas nuevas `NUMBER(7)` nullable, PK e indice intactos,
   `TRACK_PRECALIFICA_ACTIVO='S'`.
3. Ejecutar como script (F5) el body canonico:
   `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql`.
   No tocar la `spec.sql`.
4. Ejecutar `03_VALIDACION/05_VALIDAR_COMPILACION_INCREMENTO_B_QA02.sql`.
   Esperado: BODY `VALID`, cero errores, `lineas_track_candidato > 0`,
   `LAST_DDL_TIME` de la spec sin cambios.
5. Ejecutar de forma controlada `PR.JOB_CARGA_PRECALIFICA_RD`.
6. Ejecutar `03_VALIDACION/06_VALIDAR_RESULTADO_INCREMENTO_B_QA02.sql`.
   Esperado: paso 3 `OK` (Capa C == FINAL_* de Capa B), paso 4 `OK`
   (sin nulos, sin duplicados, todo `FLUJO='CIERRE'`), paso 7 `OK` (31 metricas).
7. Comparar la duracion del paso 13 (`LOOP_FINAL_VALIDACIONES_BITACORA`) contra la
   corrida `53D427AF4F597DB0E063140311AC14C5` para medir el costo del MERGE por candidato.
8. Pegar aqui: ID de ejecucion, salidas de los pasos 3/4/7 del script 06 y duraciones.
9. Si algo falla: `04_ROLLBACK/ROLLBACK_INCREMENTO_B_BODY_QA02.sql` (vuelve al body A
   probado); la reversa del ALTER solo con aprobacion explicita.

### Resultados de la prueba (2026-06-09, `AJEREZ@QADEMI02_19C`)

- Secuencia ejecutada: ALTER 04 -> script 04 (estructuras OK: 9 columnas,
  `NO_CREDITO`/`CODIGO_CLIENTE` `NUMBER(7)` nullable, PK/indice intactos) ->
  body compilado -> script 05 (BODY `VALID`, spec `LAST_DDL_TIME` 21-MAY-26 sin
  cambios, 0 errores, 3 lineas con `track_candidato`) -> job -> conciliacion.
- **Para acortar la prueba se redujo `LOTE_DE_CARAGA_REPRESTAMO` de `130000` a
  `1300`** (queda autodocumentado en `VALOR_LOTE` de la Capa B).
  **PENDIENTE: restaurar a `130000`.**
- ID de ejecucion: `53D8BBE0BA0E44D9E063140311AC6BC6`.
- Duracion total del job: `1665.743 s` (27.762 min); `REGISTROS_RE = 1633`.
- Capa B (31/31 metricas): flujos netos `1167 + 321 + 0 + 100 + 45 = 1633` RE;
  precalificacion `88 RSB + 50 CLS/RCS + 193 borrados + 1302 salida = 1633`;
  XCORE 1302/1302; `SOL_CREADA = 1299`, `CANAL_CREADO = 1073`.
- **Conciliacion Capa C vs FINAL_\*: `OK`.** `1302 == 1302` filas; desglose
  exacto `949 NP + 201 CP + 152 RXT + 0 AN + 0 OTRO = 1302`.
- **Calidad de datos: `OK`.** 0 nulos en `NO_CREDITO`/`CODIGO_CLIENTE`/
  `RESULTADO_ULTIMO`, 0 filas con `FLUJO <> 'CIERRE'`, 0 duplicados.
- **Costo del MERGE por candidato (paso 13):** corrida B `1.456 s / 1302` =
  `0.0011 s/cand` vs corrida A baseline `4.757 s / 5169` = `0.0009 s/cand`
  -> sobrecosto de `track_candidato` ~`0.2 ms` por candidato (~1 s extra en una
  corrida full de 5169). Aceptado; no se requiere la variante bulk.
- Incidencias: (1) `;` dentro del PROMPT 2 del script 05 rompia el modo
  "execute as script" (ORA-00900, misma incidencia que el script 00); corregido.
  (2) Toad no volcaba los SELECT del script 06 al Script Output; se agrego
  `03_VALIDACION/07_RESUMEN_INCREMENTO_B_UNA_FILA_QA02.sql` (resumen en una
  fila + duraciones + comparativa de costo, para F9/Data Grid).

## Alcance validado y pendiente

- **Incremento A:** aplicado y probado (2026-06-09,
  `53D427AF4F597DB0E063140311AC14C5`).
- **Incremento B:** aplicado y probado (2026-06-09,
  `53D8BBE0BA0E44D9E063140311AC6BC6`); cohorte individual del cierre
  conciliada al 100% con la Capa B.
- **Incremento C:** pendiente; pertenencia individual a cada flujo.
- **DIAGNOSTICA:** pendiente; desglose de filtros internos comparable con
  `trackers_precalifica_cursor`.
- **Pendiente operativo:** restaurar `LOTE_DE_CARAGA_REPRESTAMO = 130000`
  (se dejo en `1300` para la prueba del B).

## Rollback

- Ejecutado: no.
- Resultado: N/A (los rollbacks de DDL en `04_ROLLBACK/` solo se usan con aprobacion explicita).
- Evidencia: N/A.
