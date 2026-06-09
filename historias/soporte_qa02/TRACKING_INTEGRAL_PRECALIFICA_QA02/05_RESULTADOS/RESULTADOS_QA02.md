# Resultados QA02

Estado: DDL auxiliar e Incremento A aplicados y probados en QA02.

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

## Alcance validado y pendiente

- **Incremento A:** aplicado y probado.
- **Incremento B:** pendiente; resultado individual de la cohorte final.
- **Incremento C:** pendiente; pertenencia individual a cada flujo.
- **DIAGNOSTICA:** pendiente; desglose de filtros internos comparable con
  `trackers_precalifica_cursor`.

## Rollback

- Ejecutado: no.
- Resultado: N/A (los rollbacks de DDL en `04_ROLLBACK/` solo se usan con aprobacion explicita).
- Evidencia: N/A.
