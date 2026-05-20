# OPT-020 - Handoff lote y fecha de corte

Fecha: 2026-05-19

## Estado

Entorno trabajado: `QA02 / QADEMI02_19C`.

Objeto principal: `PR.PR_PKG_REPRESTAMOS`.

Archivo de referencia:

- `historias/optimizaciones/descartados/OPT-020_VISTAS_GARANTIA_REPRESTAMOS/body_actual_QA02_tracking/body_actual_QA02.sql`

## Contexto tecnico

- Existe tracking persistente en `PR.PR_JOB_PRECALIFICA_TRACK` para medir `PR.JOB_CARGA_PRECALIFICA_RD`.
- El paso mas costoso observado fue `P_REGISTRO_SOLICITUD`.
- Se aislo mejora importante en telefonos usando `PR.obt_telefono_persona` con `inCodPersona IN VARCHAR2`, tablas `PA` calificadas y subquery laboral directo por `inCodPersona`.
- Validacion funcional del cambio laboral retorno `DIFERENCIAS = 0`.
- `PA.INFO_LABORAL.COD_PER_FISICA` y `PA.TEL_PERSONAS.COD_PERSONA` fueron validados como `VARCHAR2(15)`.
- `TEL_PERSONAS` ya tiene indices existentes en QA02, por ejemplo `PK_TEL_PERSONAS`, `IDX_TEL_PERSONAS_TIPO` e `IDX_TELP_PER_DEF`.

## Problema pendiente

El parametro `LOTE_DE_CARAGA_REPRESTAMO` esta en `20000`, pero la corrida deja/procesa alrededor de `3000` registros.

El lote limita el cursor, pero no garantiza 20000 registros finales porque antes y despues aplican filtros de negocio:

- fecha de corte en `PA.PA_DETALLADO_DE08`
- tipo de credito con `PR_TIPO_CREDITO_REPRESTAMO.CARGA = 'S'`
- mora, clasificacion SIB y capital pagado
- prestamos recientes, estado `E`, reproceso
- persona fisica, nacionalidad, tipo documento
- avales, garantes, PEP y lista negra

El cursor usa `b.fecha_corte = P_FECHA_CORTE` y el proceso normal toma `MAX(FECHA_CORTE)` para `FUENTE = 'PR'`.

## Fechas candidatas observadas

El usuario observo estos totales brutos en `PA.PA_DETALLADO_DE08`:

| FECHA_CORTE | TOTAL |
|-------------|-------|
| 12/11/2025 | 129727 |
| 31/07/2025 | 259426 |
| 16/07/2025 | 129707 |
| 01/04/2025 | 147009 |
| 31/03/2025 | 147259 |
| 30/03/2025 | 147153 |
| 28/03/2025 | 147709 |
| 27/03/2025 | 147552 |
| 26/03/2025 | 147323 |
| 25/03/2025 | 147142 |

Recomendacion inicial: no cambiar fecha a ciegas. Ejecutar el diagnostico para `12/11/2025` y `31/07/2025`. Si `31/07/2025` conserva mas candidatos en `11_SIN_PEP_NEGRA` y `12_FINAL_CON_LOTE_20000`, usarla para una prueba controlada de volumen.

## Script de diagnostico

Ejecutar:

- `11_DIAGNOSTICO_LOTE_FECHA_CORTE.sql`

Cambiar:

```sql
DEFINE P_FECHA_CORTE = '31/07/2025';
```

Probar minimo:

- `12/11/2025`
- `31/07/2025`

Enviar la salida completa de `Q01`, `Q02` y `Q03`.

## Prompt para continuar

```text
Trabaja en espanol. Repo: C:\Users\joogando\Desktop\ADEMI_BD. Usa docs/instrucciones_ai/BASE_OPERATIVA.md como fuente de verdad.

Entorno: QA02 / QADEMI02_19C. Objeto principal: PR.PR_PKG_REPRESTAMOS. Archivo de trabajo:
historias/optimizaciones/descartados/OPT-020_VISTAS_GARANTIA_REPRESTAMOS/body_actual_QA02_tracking/body_actual_QA02.sql

Contexto:
- Hay tracking persistente en PR.PR_JOB_PRECALIFICA_TRACK para PR.JOB_CARGA_PRECALIFICA_RD.
- El paso P_REGISTRO_SOLICITUD era el cuello de botella. Se mejoro creando/ajustando PR.obt_telefono_persona: inCodPersona paso a VARCHAR2, tablas PA calificadas, subquery de INFO_LABORAL usa x.cod_per_fisica = inCodPersona. Validacion funcional dio 0 diferencias.
- El usuario midio una corrida donde TOTAL_JOB fue aprox. 2822s y P_REGISTRO_SOLICITUD aprox. 1966s, con REGISTROS_RE cercano a 3351.
- Actualmente LOTE_DE_CARAGA_REPRESTAMO esta en 20000, pero el job solo deja/procesa alrededor de 3000 registros.
- El cursor usa ROWNUM <= LOTE_DE_CARAGA_REPRESTAMO y b.fecha_corte = P_FECHA_CORTE. En el body, Precalifica_Represtamo toma MAX(FECHA_CORTE) de PA.PA_DETALLADO_DE08 para FUENTE='PR'.
- Fechas observadas por el usuario: 12/11/2025 tiene 129727 filas; 31/07/2025 tiene 259426 filas; otras fechas marzo/julio 2025 tienen aprox. 147k.
- Objetivo nuevo: aumentar la cantidad de procesados/represtamos generados. Diagnosticar primero por que con lote 20000 solo quedan ~3000. No cambiar spec ni logica de negocio sin propuesta.
- Pedir/analizar salida de 11_DIAGNOSTICO_LOTE_FECHA_CORTE.sql. Comparar 12/11/2025 vs 31/07/2025. Si 31/07/2025 tiene muchos mas candidatos elegibles despues de filtros, proponer prueba controlada usando esa FECHA_CORTE; si no, buscar el filtro que reduce el universo.
```

## Nota de control de git

Al momento del cierre el worktree tenia otros cambios no relacionados. No deben commitearse junto con este handoff salvo revision explicita.
