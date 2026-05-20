# OPT-020 â€” Handoff: aumentar candidatos en Precalifica_Represtamo

## Entorno y objeto
- **Entorno:** QA02 / QADEMI02_19C
- **Objeto:** `PR.PR_PKG_REPRESTAMOS`
- **Archivo de trabajo:** `historias/optimizaciones/descartados/OPT-020_VISTAS_GARANTIA_REPRESTAMOS/body_actual_QA02_tracking/body_actual_QA02.sql`
- **Objetivo:** aumentar la cantidad de candidatos/represtamos procesados por el job `PR.JOB_CARGA_PRECALIFICA_RD`.

## DiagnÃ³stico realizado

### Universo en `PA.PA_DETALLADO_DE08` (fuente='PR')
- `12/11/2025`: 129,727 filas
- `31/07/2025`: 259,426 filas

### Funnel progresivo de `Precalifica_Represtamo` (ruta por FECHA_CORTE)

| Paso | 12/11/2025 | 31/07/2025 |
|---|---|---|
| Universo (post periodos) | 67,328 | 134,644 |
| **04 â€” MORA+CLASIF+CAPITAL** | **287** | **605** |
| 05 â€” sin desembolso reciente | 285 | 603 |
| 06 â€” sin estado E | 285 | 603 |
| 07 â€” persona fÃ­sica + nacionalidad | 284 | 602 |
| 08 â€” sin reproceso | 126 | 443 |
| 09 â€” sin aval / no sola firma | 22 | 247 |
| 10 â€” sin garante | 15 | 237 |
| **FINAL** | **15** | **237** |

**Hallazgo central:** el **filtro 04 descarta el 99.5%** del universo. Es el bloque de 3 condiciones del cursor de `Precalifica_Represtamo`, justo despuÃ©s de `b.fecha_corte = P_FECHA_CORTE`: mora, clasificaciÃ³n SIB y capital pagado.

### DescomposiciÃ³n del filtro 04 (Q04b, corte 12/11)

| CondiciÃ³n sola | Pasan (de 67,328) |
|---|---|
| Solo MORA (`dias_atraso <= PRECAL_MORA_MAYOR_PR`) | 1,858 |
| Solo CLASIFICACIÃ“N SIB | 17,198 |
| Solo CAPITAL pagado â‰¥ 60% | 13,049 |
| MORA + CAPITAL | 293 |
| Los tres (= s04) | 287 |

La **mora es la condiciÃ³n dominante**. La clasificaciÃ³n casi no recorta una vez aplicadas mora+capital (293 â†’ 287).

### ParÃ¡metros
- `CAPITAL_PAGADO = 60`
- `PRECAL_MORA_MAYOR_PR = 30` (en `PA.PA_PARAMETROS_MVP`, codigo_mvp='REPRESTAMOS')

### DistribuciÃ³n de `dias_atraso` (corte 31/07/2025)

| Rango | CrÃ©ditos | % |
|---|---|---|
| = 0 | 4,490 | 3.3% |
| 1-15 | 110 | 0.1% |
| 16-30 | 102 | 0.1% |
| 31-45 | 7,350 | 5.4% |
| 46-60 | 50,648 | 37.5% |
| 61-90 | 45,252 | 33.5% |
| > 90 | 27,128 | 20.1% |

El 91% tiene 46+ dÃ­as de atraso â†’ el universo elegible es legÃ­timamente pequeÃ±o.

## What-if por umbral de mora (Q07)

Candidatos finales manteniendo clasif+capital+filtros 05-10, variando solo el umbral de mora:

| Umbral | 31/07/2025 | 12/11/2025 |
|---|---|---|
| 30 (actual) | 380 | 158 |
| 45 | 711 | 206 |
| 60 | 2,762 | 254 |
| 90 | 3,229 | 285 |
| sin lÃ­mite | 3,846 | 2,076 |

(La discrepancia entre el FINAL del funnel Q03 y el UMBRAL_30 de Q07 es esperable: `PR_REPRESTAMOS` cambia entre corridas â€” el job o la anulaciÃ³n liberan crÃ©ditos del filtro 08.)

## Conclusiones

1. **El lote (`LOTE_DE_CARAGA_REPRESTAMO=20000`) es irrelevante** â€” nunca se acerca; ni el techo (3,846) lo alcanza. No tocar.
2. **El job procesa ~3000 registros, pero `Precalifica_Represtamo` aporta muy pocos** (15-237). El grueso viene de `Precalifica_Repre_Cancelado`/`_hi` (lÃ³gica por `F_CANCELACION`, no por FECHA_CORTE).
3. **`31/07/2025` es mejor fecha** que 12/11 (mÃ¡s universo, mÃ¡s sensible al umbral). Pero el job toma la fecha con `MAX(FECHA_CORTE)` internamente â€” forzar 31/07 requerirÃ­a cambio de cÃ³digo.
4. **DecisiÃ³n tomada:** en vez de comentar el filtro 04, **subir el parÃ¡metro `PRECAL_MORA_MAYOR_PR`** (cambio de config, reversible, quirÃºrgico â€” solo toca la mora, conserva clasif+capital).

## Pendientes / riesgos abiertos (IMPORTANTE)

1. **`valor_x2` SIN CONFIRMAR (bloqueante).** `PRECAL_MORA_MAYOR_PR` se lee de dos formas:
   - El **cursor** lo lee con `f_obt_parametro_Represtamo` â†’ `PA.PA_PARAMETROS_MVP` (= 30, confirmado).
   - El **UPDATE a estado `X2`** lo lee con `OBT_PARAMETROS('1','PR','PRECAL_MORA_MAYOR_PR')` â†’ posible otra tabla, valor NO confirmado.
   - Si X2 sigue en 30, el cursor admite mÃ¡s pero el paso X2 los borra (`DELETE ... ESTADO LIKE 'X%'`). **Hay que verificar y subir ambos.**
2. **El paso X2 usa `PR_REPRESTAMOS.DIAS_ATRASO` = mÃ¡ximo de atraso de los Ãºltimos 6 meses**, no el del corte. Aun subiendo ambos parÃ¡metros, X2 puede borrar crÃ©ditos admitidos. El conteo real definitivo es correr el job de prueba.
3. **Umbral para la prueba sin elegir** â€” recomendado 45 (conservador) o 60 (salto grande).

## Cambios hechos en el repo

- Modificado `08_CONSULTAR_TRACKING_JOB_PRECALIFICA_RD.sql`: se agregÃ³ **Q05** (comparaciÃ³n automÃ¡tica de las 2 Ãºltimas ejecuciones) y **Q06** (comparaciÃ³n de 2 ejecuciones por `id_ejecucion`), con `delta_seg`/`delta_pct` y `registros_re` de ambas.
- No se creÃ³ copia de body con filtro 04 comentado â€” se descartÃ³ a favor del cambio de parÃ¡metro.

## PrÃ³ximos pasos

1. Correr `SELECT OBT_PARAMETROS('1','PR','PRECAL_MORA_MAYOR_PR') FROM dual;` y ubicar dÃ³nde vive ese valor.
2. Elegir umbral (45 o 60).
3. Armar los `UPDATE` (cursor + X2) con su rollback a 30.
4. Correr job baseline â†’ anotar `id_ejecucion`; cambiar parÃ¡metros; correr job de prueba; comparar con Q06 (`re_a` vs `re_b`).

## Contexto previo (sigue vigente)
- Existe tracking persistente en `PR.PR_JOB_PRECALIFICA_TRACK`.
- El cuello de tiempo era `P_REGISTRO_SOLICITUD`; se mejorÃ³ ajustando `PR.obt_telefono_persona` (validaciÃ³n funcional: 0 diferencias).
- Baseline de tiempo del job: ~2822s total, `P_REGISTRO_SOLICITUD` ~1966s, `REGISTROS_RE` ~3351.

## Riesgo de negocio
Subir `PRECAL_MORA_MAYOR_PR` significa dar reprÃ©stamos a clientes con mÃ¡s dÃ­as de atraso â€” es criterio de riesgo. Para la prueba en QA02 estÃ¡ bien y es reversible; para producciÃ³n necesita visto bueno de negocio.
