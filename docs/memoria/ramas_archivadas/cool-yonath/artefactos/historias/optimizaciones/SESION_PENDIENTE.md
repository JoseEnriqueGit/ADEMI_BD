# Sesion Pendiente — Continuacion de mediciones OPT

> Documento de contexto para continuar el trabajo de optimizacion en otra PC/sesion.
> Fecha: 2026-04-13 (actualizado)
> Sesion anterior: Claude Code VS Code Extension

---

## Resumen de lo completado (sesion 2026-04-13)

### OPT-014: Medicion real de indices en DESARROLLO (COMPLETADO)
- **Resultado**: 24.2 min → 14.2 min (**-41%**) solo con 4 indices
- **Entorno**: DESARROLLO (ADMQA1 / bmadev0004) — QA estaba ocupado por otro desarrollador
- **Detalle**: Ver `historias/optimizaciones/OPT-014_INDICES_MEDICION_REAL/README.md`
- **Indices creados en DESARROLLO**: Los 4 indices quedaron creados y VALID

### Investigacion pasos 5-6 (CERRADA para indices)
- Se probo 5to indice en PA_DETALLADO_DE08 → descartado (empeoro paso 5)
- Causa raiz: CPU/PL/SQL (funciones por fila, context switching), no I/O
- La solucion requiere cambios de codigo, no indices adicionales

---

## Instrucciones para la proxima sesion

### Tarea principal: Rewrite de codigo en Precalifica_Repre_Cancelado y Cancelado_hi

Los pasos 5 y 6 consumen el **53% del tiempo total** (702 seg de 1,454 sin indices, 624 seg de 854 con indices). No se optimizan con indices — requieren rewrite de codigo.

**Que hacer:**
1. Replicar **OPT-004** (convertir loops row-by-row a UPDATE set-based) en:
   - `Precalifica_Repre_Cancelado` (~linea 412 del body.sql DESARROLLO)
   - `Precalifica_Repre_Cancelado_hi` (~linea 795 del body.sql DESARROLLO)
2. Replicar **OPT-010** (inline de `F_TIENE_GARANTIA` / `F_TIENE_GARANTIA_HISTORICO` como NOT EXISTS) en los mismos procedimientos
3. Medir con el script `05_MEDIR_JOB_CANCELADO_DETALLADO.sql` (restaurar 190 RE antes)

**Patron de cambio (referencia):**
- OPT-004: Loop con UPDATE por fila → 1-2 UPDATEs set-based con subquery
- OPT-010: Llamada a F_TIENE_GARANTIA() en cursor → NOT EXISTS inline en el cursor/query

**Cuello de botella especifico:**
- FORALL UPDATE con `SELECT MAX(DIAS_ATRASO) FROM PA_DETALLADO_DE08` ejecutado en batches de 100
- Funciones `F_TIENE_GARANTIA` / `F_TIENE_GARANTIA_HISTORICO` llamadas por cada fila del cursor
- COMMITs dentro de loops (patron OPT-003)

**Archivos de referencia:**
- Body DESARROLLO: `ENTORNOS_ORACLE/DESARROLLO/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql`
- OPT-004: `historias/optimizaciones/OPT-004_SETBASED_ACTUALIZAR_MTO_CREDITO/README.md`
- OPT-010: `historias/optimizaciones/OPT-010_INLINE_F_TIENE_GARANTIA/README.md`
- Medicion: `historias/optimizaciones/scripts_medicion/05_MEDIR_JOB_CANCELADO_DETALLADO.sql`

**Estado de DESARROLLO:**
- 4 indices OPT creados y VALID
- Paquete de produccion compilado (procedimientos activos)
- Tablas backup: `JOOGANDO.PR_REPRESTAMOS_POST`, `PR.OPT_HIWATER_MARKS`
- Restaurar RE antes de medir: `UPDATE PR.PR_REPRESTAMOS SET ESTADO='RE' WHERE MODIFICADO_POR IS NULL AND FECHA_MODIFICACION >= DATE '2026-04-10' AND ESTADO IN ('AN','NP','CP','RXT','RXC');`

### Otros pendientes (menor prioridad)
- Medir en QA cuando este disponible
- Propuestas de hardcodeo de 3 cursores del job mensual (pendiente aprobacion del jefe)
- Confirmar SQL 151/172 del Quest con companero

---

## Resumen de lo completado (sesion anterior 2026-04-07)

### OPT-013 (COMPLETADO)
- **Indice**: `PA.IDX_DE05_SIB_CASTIGO_CEDULA` en PA.PA_DE05_SIB (FECHA_CASTIGO, CEDULA, ENTIDAD)
- **Cost**: 120,122 → 11
- **Ya creado en QA** bajo schema JOOGANDO
- Documentado en `historias/optimizaciones/OPT-013_INDICE_PA_DE05_SIB/`
- Commits: `3067cbc` (tabla), `3b642ef` (indice + documentacion)

### Mediciones realizadas hoy (todos los ANTES)
| Query | Procedimiento | Cost | Resultado |
|-------|--------------|------|-----------|
| CUR_DE08_SIB (Dirigida) | Actualiza_Preca_Dirigida | 11 | Ya bajo, no optimizar |
| CUR_DE05_SIB (Dirigida) | Actualiza_Preca_Dirigida | 120,122 → 11 | RESUELTO OPT-013 |
| UPDATE MTO_CREDITO_ACTUAL (por fila) | Actualiza_Preca_Dirigida | 324 | Bajo por fila |
| UPDATE ESTADO='RSB' (por fila) | Actualiza_Preca_Dirigida | 43 | Bajo |
| MAX(DIAS_ATRASO) 3 subqueries | Precalifica_Carga_Dirigida | 15 | Bajo |
| Capital pagado JOIN DE08 | Precalifica_Carga_Dirigida | 7 | Bajo |
| Sola firma HAVING+EXISTS | Precalifica_Carga_Dirigida | 10 | Bajo |
| Atraso TC | Precalifica_Carga_Dirigida | 5 | Bajo |
| UPDATE set-based (DESPUES) | Actualiza_Preca_Dirigida | 10 | Bajo |

**Conclusion**: Los queries individuales de Precalifica_Carga_Dirigida y Actualiza_Preca_Dirigida tienen costs bajos. No hay queries SQL que justifiquen optimizacion con indices.

---

## Lo que queda pendiente (4 items)

### 1. Propuestas de hardcodeo — 3 cursores del job mensual (cost total 11,698 → 62)
- **Estado**: Propuestas documentadas, pendientes aprobacion del jefe
- **Archivos**:
  - `historias/optimizaciones/propuestas/SQL371_HARDCODEO_ESTADOS.md` — CUR_Anular_creditos_cancelados (9,748→26)
  - `historias/optimizaciones/propuestas/CURSORES_ANULAR_HARDCODEO_ESTADOS.md` — CUR_Anular (953→18) + CUR_Anular_campana_especiales (997→18)
- **Job afectado**: JOB_ACTUALIZAR_ANULAR_RD (mensual, dia 1 a las 00:00)
- **Cadena**: JOB → P_ACTUALIZAR_ANULAR_REPRESTAMO → P_ANULAR_REPRESTAMOS_INACTIVOS → 3 cursores
- **Accion**: Preguntar al jefe si aprueba el trade-off (hardcodeo vs parametros dinamicos)
- **Alternativas evaluadas**: Subquery directa (cost 929), CARDINALITY hint (cost 952) — ambas descartadas, Oracle solo hace INLIST ITERATOR con literales
- **Si se aprueba**: Aplicar los 3 cambios al body.sql, documentar como OPT-014

#### Como probar el job en Toad (medir tiempo ANTES y DESPUES del cambio)

**Ejecutar el job directamente:**
```sql
BEGIN
  DBMS_SCHEDULER.RUN_JOB('PR.JOB_ACTUALIZAR_ANULAR_RD', USE_CURRENT_SESSION => TRUE);
END;
/
```

**O llamar el procedimiento con medicion de tiempo:**
```sql
SET TIMING ON;
DECLARE
  PMENSAJE VARCHAR2(32767);
BEGIN
  PMENSAJE := NULL;
  PR.PR_PKG_REPRESTAMOS.P_ACTUALIZAR_ANULAR_REPRESTAMO(PMENSAJE);
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Mensaje: ' || PMENSAJE);
END;
/
```

**Proceso de prueba:**
1. Correr el script ANTES de aplicar cambios — anotar tiempo de ejecucion
2. Aplicar los cambios (hardcodeo de los 3 cursores) y recompilar el paquete
3. Correr el mismo script — anotar tiempo DESPUES
4. Comparar tiempos y documentar en la OPT

### 2. SQL 151/172 del Quest (cost 106,783) — Confirmar que son CUR_DE05_SIB
- **Estado**: Probablemente ya resueltos por OPT-013, falta confirmar
- **Accion**: Pedirle al companero que abra el Quest SQL Optimizer y muestre el SQL Text de SQL 151 y SQL 172
- **Si son CUR_DE05_SIB**: Marcar como resueltos por OPT-013
- **Si son otro query**: Analizar el SQL Text y preparar Explain Plan

### 3. UPDATE MTO_CREDITO_ACTUAL — Evaluar conversion a set-based
- **Estado**: Cost 324/fila (ANTES) vs 10 (DESPUES set-based). Mejora depende del volumen
- **Accion**: Averiguar cuantos registros en estado 'RE' procesa tipicamente el job de carga dirigida
- **Si el lote es >50 registros**: Vale la pena convertir a set-based (como OPT-004)
- **Si el lote es <20 registros**: No vale la pena, dejar como esta
- **Script DESPUES** (ya medido, cost 10):
```sql
UPDATE PR.PR_REPRESTAMOS R
SET R.MTO_CREDITO_ACTUAL = (SELECT D.monto_desembolsado
                              FROM PA.PA_DETALLADO_DE08 D
                             WHERE D.FUENTE         = 'PR'
                               AND D.NO_CREDITO     = R.NO_CREDITO
                               AND D.CODIGO_CLIENTE = R.CODIGO_CLIENTE
                               AND D.FECHA_CORTE    = (SELECT MAX(P.FECHA_CORTE)
                                                         FROM PA_DETALLADO_DE08 P
                                                        WHERE P.FUENTE         = 'PR'
                                                          AND P.NO_CREDITO     = R.NO_CREDITO
                                                          AND P.CODIGO_CLIENTE = R.CODIGO_CLIENTE))
WHERE R.CODIGO_EMPRESA = 1
  AND R.ESTADO = 'RE';
```

### 4. COMMITs dentro de loops — Redo I/O
- **Estado**: Aplica a Actualiza_Preca_Dirigida y Actualiza_Preca_Campana_Especiale
- **Accion**: No se mide con Explain Plan. Solo vale la pena si los lotes son grandes (>100 registros)
- **Cambio**: Mover COMMITs al final de cada loop (patron OPT-003)
- **Riesgo**: Si el proceso falla a mitad del loop, se hace rollback completo en vez de conservar filas procesadas

---

## Archivos de referencia importantes

| Archivo | Contenido |
|---------|-----------|
| `historias/optimizaciones/README.md` | Indice de todas las OPT (001-013) |
| `historias/optimizaciones/PENDIENTES.md` | SQLs pendientes del Quest |
| `historias/optimizaciones/MAPA_JOBS.md` | Mapa completo de los 5 jobs y sus procedimientos |
| `historias/optimizaciones/propuestas/SQL371_HARDCODEO_ESTADOS.md` | Propuesta SQL 371 (CUR_Anular_creditos_cancelados) |
| `historias/optimizaciones/propuestas/CURSORES_ANULAR_HARDCODEO_ESTADOS.md` | Propuesta CUR_Anular + CUR_Anular_campana_especiales |
| `historias/optimizaciones/OPT-013_INDICE_PA_DE05_SIB/README.md` | OPT-013 completada |
| `ENTORNOS_ORACLE/QA/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | Paquete principal (13,787 lineas) |

## Valores de referencia para Explain Plan
- **NO_CREDITO**: 1087363
- **CODIGO_CLIENTE**: 1107470
- **FECHA_CORTE**: 27/09/2024
- **CODIGO_EMPRESA**: 1

## Nota sobre herramientas
- En VS Code con Claude Code extension, las skills (`oracle-optimize`, `oracle-explain`) y herramientas son las mismas
- El CLAUDE.md del proyecto se carga automaticamente
- Leer este documento al inicio de la sesion para tener contexto completo

---

## Instrucciones para la proxima sesion

### Tarea principal: Medir ANTES/DESPUES del job mensual con hardcodeo

**Paso 1 — Medir ANTES (sin cambios):**
1. Conectar a QA (JOOGANDO@QAORACEL) en Toad
2. Activar DBMS Output (View > DBMS Output)
3. Abrir `historias/optimizaciones/scripts_medicion/MEDIR_JOB_ANULAR.sql`
4. Ejecutar 3 veces — descartar la 1ra (cold cache), anotar 2da y 3ra como ANTES
5. Copiar la linea "RESULTADO|..." del output

**Paso 2 — Aplicar hardcodeo de los 3 cursores:**
Modificar `P_Anular_Represtamos_Inactivos` en body.sql (linea 9368):

*CUR_Anular (linea 9377) — cambiar:*
```sql
-- ANTES:
and ESTADO in (select COLUMN_VALUE FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ( 'ESTADOS_ANULAR_REPRESTAMOS_POR_NO_CONCLUIR_PROCESO')))
-- DESPUES:
and ESTADO IN ('RE','NP','VR','MS','NR','LA','AEP','AYR','EP','AP','MS','AYN','AYS','BLI','BLP','CP','SC')
-- Valores de PA_PARAMETROS_MVP.ESTADOS_ANULAR_REPRESTAMOS_POR_NO_CONCLUIR_PROCESO
```

*CUR_Anular_campana_especiales (linea 9388) — mismo cambio:*
```sql
-- ANTES:
and ESTADO in (select COLUMN_VALUE FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ( 'ESTADOS_ANULAR_REPRESTAMOS_POR_NO_CONCLUIR_PROCESO')))
-- DESPUES:
and ESTADO IN ('RE','NP','VR','MS','NR','LA','AEP','AYR','EP','AP','MS','AYN','AYS','BLI','BLP','CP','SC')
-- Valores de PA_PARAMETROS_MVP.ESTADOS_ANULAR_REPRESTAMOS_POR_NO_CONCLUIR_PROCESO
```

*CUR_Anular_creditos_cancelados (linea 9395-9399) — cambiar 2 lineas:*
```sql
-- ANTES (linea 9395):
and ESTADO in (select COLUMN_VALUE FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ( 'ESTADOS_ANULAR_CREDITOS_CANCELADOS')))
-- DESPUES:
and ESTADO IN ('RE','NP','VR','MS','NR','LA','AEP','AYR','CP')
-- Valores de PA_PARAMETROS_MVP.ESTADOS_ANULAR_CREDITOS_CANCELADOS

-- ANTES (linea 9399):
and estado in (select COLUMN_VALUE FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros ( 'ESTADOS_ANULAR_CREDITOS')))
-- DESPUES:
and estado IN ('D','V','M','E','J','C')
-- Valores de PA_PARAMETROS_MVP.ESTADOS_ANULAR_CREDITOS
```

Compilar el paquete en Toad (sin errores).

**Paso 3 — Medir DESPUES:**
1. Ejecutar `MEDIR_JOB_ANULAR.sql` 3 veces — anotar 2da y 3ra como DESPUES
2. Copiar la linea "RESULTADO|..." del output
3. Comparar con los resultados del Paso 1

**Paso 4 — Documentar:**
1. Si mejora: crear carpeta OPT-014 y documentar con ANTES/DESPUES
2. Si no mejora o es marginal: revertir body.sql y anotar en SESION_PENDIENTE

**Paso 5 — Rollback (si algo sale mal):**
Revertir los 3 cursores a la version original con TABLE(F_Obt_Valor_Parametros(...)) y recompilar.

### Otros items pendientes (menor prioridad)
1. Confirmar SQL 151/172 del Quest con companero
2. Evaluar UPDATE MTO_CREDITO_ACTUAL set-based (preguntar volumen de lote)
3. Evaluar COMMITs en loops (preguntar volumen de lote)

### Al finalizar la sesion
1. Actualizar este documento con los resultados de las mediciones
2. Hacer commit y push de todo
3. Si se creo OPT-014, agregar entrada al README.md de optimizaciones
