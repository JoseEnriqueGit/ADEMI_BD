# Mapa de Jobs y Orquestadores — PR_PKG_REPRESTAMOS (QA)

> Arbol de llamadas de cada job scheduler que invoca procedimientos del paquete.
> Los procedimientos marcados con ✅ ya fueron optimizados en OPT-001 a OPT-013.
> La columna "Medido OPT-014" indica si el impacto se valido en tiempo real (no solo Explain Plan).
> Los marcados con 🔍 requieren analisis con Explain Plan en Toad.

---

## 1. JOB_CARGA_PRECALIFICA_RD → `P_Carga_Precalifica_Cancelado` (linea 8115)

**Estado: OPTIMIZACIONES APLICADAS (OPT-001 a OPT-013) — medicion real parcial en OPT-014.**

### Tabla maestra: pasos del orquestador con OPTs aplicadas y medicion real

> Orden segun la medicion real de OPT-014 en DESARROLLO (2026-04-13, 190 represtamos en estado RE).
> **Medido real** = impacto validado en tiempo real en OPT-014. **Explain Plan** = validado solo con cost teorico.

| # | Procedimiento | OPTs aplicadas | Tipo | Medido OPT-014 (solo indices) | ANTES (s) | DESPUES (s) | Δ |
|---|---------------|----------------|------|-------------------------------|-----------|-------------|---|
| 1 | P_Actualizar_Anular_Represtamo       | OPT-011 (indice IDX_REPRESTAMOS_EMP_EST_NOCRED) | Indice | ✅ | 1.4 | 1.3 | = |
| 2 | Precalifica_Represtamo               | OPT-009 (indice+codigo), OPT-010 (codigo NOT EXISTS en CREDITOS_PROCESAR) | Indice + Codigo | Indice ✅ / Codigo ❌ no medido | 278.7 | 98.0 | **-65%** |
| 3 | Precalifica_Represtamo_fiadores      | OPT-010 (codigo), OPT-002 (indirecto PA_DE08_SIB) | Indice + Codigo | Indice ✅ / Codigo ❌ no medido | 190.8 | 53.8 | **-72%** |
| 4 | Precalifica_Represtamo_fiadores_hi   | OPT-002 (indice PA_DE08_SIB) | Indice | ✅ | 177.9 | 36.9 | **-79%** |
| 5 | Precalifica_Repre_Cancelado          | OPT-010 (codigo), OPT-009 (indirecto) | Indice + Codigo | Indice ✅ / Codigo ❌ no medido | 391.7 | 231.5 | **-41%** |
| 6 | Precalifica_Repre_Cancelado_hi       | (ninguna efectiva) | — | N/A | 381.6 | 392.5 | +3% (NO MEJORO — requiere rewrite) |
| 7 | Actualiza_Precalificacion            | OPT-002 (indice+codigo), OPT-003 (commits), OPT-004 (set-based), OPT-013 (indice PA_DE05_SIB) | Indice + Codigo + Estructural | Indices ✅ / Codigo ❌ no medido | 13.3 | 3.2 | **-76%** |
| 8 | Actualiza_XCORE_CUSTOM               | OPT-005 (loop→1 UPDATE) | Codigo | ❌ no medido (codigo no aplicado en DESA) | 0 | 12.5 | n/a |
| 9 | P_REGISTRO_SOLICITUD                 | OPT-006 (commits), OPT-012 (UPDATE PROMOCION_PERSONA no optimizable) | Estructural | ❌ no medido | 18.6 | 23.9 | +28% (mas RE procesados) |
| 10 | PVALIDA_WORLD_COMPLIANCE            | OPT-001 (cost 18,293→15) | Codigo + Estructural | ❌ no medido | 0.1 | 0.8 | n/a |
| 11 | PVALIDA_XCORE                       | OPT-007 (commits) | Estructural | ❌ no medido | 0 | 0 | = |
| 12 | Loop Bitacora+Validaciones          | OPT-008 (cache F_Existe_*) | Codigo | ❌ no medido | 0 | 0 | = |
|    | **TOTAL**                           |                | | | **1,454 s (24.2 min)** | **854 s (14.2 min)** | **-41%** |

### Arbol de llamadas (orden de ejecucion)

```
P_Carga_Precalifica_Cancelado
├── 1. P_Actualizar_Anular_Represtamo        ✅ OPT-011 (indice, medido real)
├── 2. Precalifica_Represtamo                ✅ OPT-009 + OPT-010
├── 3. Precalifica_Represtamo_fiadores       ✅ OPT-010
├── 4. Precalifica_Represtamo_fiadores_hi    ✅ OPT-002 (indice PA_DE08_SIB)
├── 5. Precalifica_Repre_Cancelado           ✅ OPT-010 / ⚠️ requiere rewrite (codigo)
├── 6. Precalifica_Repre_Cancelado_hi        ⚠️ NO MEJORO con indices — requiere rewrite (OPT-004 + OPT-010)
├── 7. Actualiza_Precalificacion             ✅ OPT-002 + OPT-003 + OPT-004 + OPT-013
├── 8. Actualiza_XCORE_CUSTOM                ✅ OPT-005
├── 9. P_REGISTRO_SOLICITUD                  ✅ OPT-006 + OPT-012
├── 10. PVALIDA_WORLD_COMPLIANCE             ✅ OPT-001 (cost 18,293→15)
├── 11. PVALIDA_XCORE                        ✅ OPT-007
├── 12. LOOP Bitacora:
│     ├── F_Existe_Solicitudes               ✅ OPT-008 (cache)
│     ├── F_Existe_Canales                   ✅ OPT-008 (cache)
│     └── F_EXISTE_CREDITO                   ✅ OPT-008 (cache)
└── (interno) CUR_Anular_creditos_cancelados ✅ OPT-011 (cost 10,656→9,748) — dentro de P_Actualizar_Anular_Represtamo
```

### Proximo trabajo pendiente (desde OPT-014)

- **Pasos 5 y 6 consumen 53% del tiempo total (624 s de 854 s con indices)** — no se optimizan con indices adicionales (5to indice descartado: empeoro paso 5 +43%).
- **Rewrite requerido**: replicar OPT-004 (set-based UPDATE) + OPT-010 (inline NOT EXISTS) en `Precalifica_Repre_Cancelado` y `Precalifica_Repre_Cancelado_hi`.
- **Cuello de botella real**: funciones PL/SQL por fila (F_TIENE_GARANTIA, F_TIENE_GARANTIA_HISTORICO), context switching SQL↔PL/SQL, FORALL con subqueries correladas. Ver `SESION_PENDIENTE.md`.

---

## 2. JOB_PRECALIFICA_REPRESTAMO → `P_Carga_Precalifica_Represtamo` (linea 7938)

**Estado: POR ANALIZAR**

Arbol de llamadas:
```
P_Carga_Precalifica_Represtamo
├── 1. P_Actualizar_Anular_Represtamo(pMensaje)   ✅ Compartido con Job 1 (OPT-011)
├── 2. Precalifica_Represtamo()                    ✅ Compartido con Job 1 (OPT-002)
├── 3. Actualiza_Precalificacion()                 ✅ Compartido con Job 1 (OPT-003/004)
├── 4. Actualiza_XCORE_CUSTOM()                    ✅ Compartido con Job 1 (OPT-005)
├── 5. LOOP CUR_REPRESTAMO (ESTADO='RE'):
│   ├── P_Registrar_Solicitud(ID, USER, MSG)       ✅ Compartido con Job 1 (OPT-006)
│   └── p_generar_bitacora(...)                    — Ligero (INSERT simple)
├── 6. LOOP CUR_REPRESTAMO:
│   ├── F_Existe_Solicitudes(ID)                   ✅ Compartido con Job 1 (OPT-008)
│   └── F_Existe_Canales(ID)                       ✅ Compartido con Job 1 (OPT-008)
└── COMMIT
```

**Nota:** Este orquestador reutiliza casi todos los procedimientos ya optimizados del Job 1.
No tiene llamadas unicas significativas. **Beneficio automatico de OPT-001 a OPT-011.**

🔍 **Verificar:** Que no haya queries costosos en `Precalifica_Represtamo()` que
no se hayan capturado en el Quest (el Quest se corrio sobre el Job 1, no sobre este).

---

## 3. JOB_CARGA_MANUAL_RD → `P_Carga_Precalifica_Manual` (linea 8303)

**Estado: POR ANALIZAR**

Arbol de llamadas:
```
P_Carga_Precalifica_Manual
├── 0. F_OBT_PARAMETRO_REPRESTAMO('CARGA_DIRIGIDA_PROCESO_ACTIVO')  — Check param
├── [Si proceso activo = 'S']:
│   ├── 1. Precalifica_Carga_Dirigida              🔍 UNICO — requiere analisis
│   ├──    COUNT(*) PR_REPRESTAMOS WHERE ESTADO='RE' — Ligero
│   ├── 2. Actualiza_Preca_Dirigida                🔍 UNICO — requiere analisis
│   ├── 3. ACTUALIZA_XCORE_DIRIGIDA                🔍 UNICO — requiere analisis
│   ├── 4. LOOP CUR_REPRESTAMO:
│   │   └── P_Registra_Solicitud_Dirigida(...)     🔍 UNICO — requiere analisis
│   ├── 5. PVALIDA_XCORE() (condicional)           ✅ Compartido (OPT-007)
│   ├── 6. LOOP CUR_REPRESTAMO:
│   │   ├── p_generar_bitacora(...)                — Ligero
│   │   ├── UPDATE PR_CARGA_DIRECCIONADA           🔍 Revisar indices
│   │   ├── F_Existe_Solicitudes(ID)               ✅ Compartido (OPT-008)
│   │   ├── F_Existe_Canales(ID)                   ✅ Compartido (OPT-008)
│   │   └── F_EXISTE_CREDITO(ID)                   🔍 Verificar performance
│   └── 7. UPDATE PA_PARAMETROS_MVP (JSON append)  — Ligero (1 row)
└── COMMIT
```

**Procedimientos UNICOS a analizar (4):**
1. `Precalifica_Carga_Dirigida` — Equivalente "dirigido" de Precalifica_Represtamo
2. `Actualiza_Preca_Dirigida` — Equivalente "dirigido" de Actualiza_Precalificacion
3. `ACTUALIZA_XCORE_DIRIGIDA` — Equivalente "dirigido" de Actualiza_XCORE_CUSTOM
4. `P_Registra_Solicitud_Dirigida` — Equivalente "dirigido" de P_Registrar_Solicitud

---

## 4. JOB_CAMPANAS_ESPECIALES_RD → `P_Carga_Precalifica_Campana_Especial` (linea 8415)

**Estado: POR ANALIZAR**

Arbol de llamadas:
```
P_Carga_Precalifica_Campana_Especial
├── 0. F_OBT_PARAMETRO_REPRESTAMO('CAMPANA_ESPECIAL_PROCESO_ACTIVO')  — Check param
├── [Si proceso activo = 'S']:
│   ├── 1. Precalifica_Campana_Especiales          🔍 UNICO — requiere analisis
│   ├──    COUNT(*) PR_REPRESTAMOS WHERE ESTADO='RE' — Ligero
│   ├── 2. Actualiza_Preca_Campana_Especiale       🔍 UNICO — requiere analisis
│   ├── 3. ACTUALIZA_XCORE_CAMPANA_ESPECIAL        🔍 UNICO — requiere analisis
│   ├── 4. LOOP CUR_REPRESTAMO (con JOIN PR_CAMPANA_ESPECIALES):
│   │   └── P_Registra_Solicitud_Campana(...)      🔍 UNICO — requiere analisis
│   ├── 5. PVALIDA_XCORE() (condicional)           ✅ Compartido (OPT-007)
│   ├── 6. LOOP CUR_REPRESTAMO:
│   │   ├── p_generar_bitacora(...)                — Ligero
│   │   ├── UPDATE PR_CAMPANA_ESPECIALES           🔍 Revisar indices
│   │   ├── F_Existe_Solicitudes(ID)               ✅ Compartido (OPT-008)
│   │   ├── F_Existe_Canales(ID)                   ✅ Compartido (OPT-008)
│   │   └── F_EXISTE_CREDITO(ID)                   🔍 Verificar performance
│   └── 7. UPDATE PA_PARAMETROS_MVP (JSON append)  — Ligero (1 row)
└── COMMIT
```

**CUR_REPRESTAMO especial (linea 8420):**
```sql
SELECT R.ID_REPRESTAMO, C.TIPO_CREDITO, R.ESTADO, R.XCORE_GLOBAL, R.NO_CREDITO
FROM PR_REPRESTAMOS R
LEFT JOIN PR_CAMPANA_ESPECIALES C
  ON C.NO_CREDITO = R.NO_CREDITO
  AND C.ID_CAMPANA_ESPECIALES = R.ID_REPRE_CAMPANA_ESPECIALES
WHERE R.ESTADO = 'RE';
```
🔍 Revisar plan de este cursor — el LEFT JOIN podria ser costoso sin indice en PR_CAMPANA_ESPECIALES.

**Procedimientos UNICOS a analizar (4):**
1. `Precalifica_Campana_Especiales`
2. `Actualiza_Preca_Campana_Especiale`
3. `ACTUALIZA_XCORE_CAMPANA_ESPECIAL`
4. `P_Registra_Solicitud_Campana`

---

## 5. XCORE_SOLICITUD_CR_JOB → `P_REGISTRO_SOLICITUD` (linea 8031)

**Estado: POR ANALIZAR**

Arbol de llamadas:
```
P_REGISTRO_SOLICITUD
├── CUR_REPRESTAMO: SELECT ... FROM PR_REPRESTAMOS WHERE ESTADO = 'RE'
├── LOOP CUR_REPRESTAMO:
│   ├── P_Registrar_Solicitud(ID, USER, MSG)       ✅ Compartido (OPT-006)
│   └── P_GENERAR_BITACORA(...)                    — Ligero
└── COMMIT por iteracion
```

**Nota:** Este job es el mas ligero — solo llama a `P_Registrar_Solicitud` en loop.
Ya se beneficia de OPT-006. El unico riesgo es el COMMIT por iteracion dentro del loop.
Considerar si conviene mover el COMMIT fuera del loop (como se hizo en OPT-006 para
P_Carga_Precalifica_Cancelado).

---

## Resumen de procedimientos por analizar

### Totalmente nuevos (no compartidos con Job 1):
| # | Procedimiento                      | Job que lo usa       | Prioridad |
|---|-----------------------------------|---------------------|-----------|
| 1 | Precalifica_Carga_Dirigida        | JOB_CARGA_MANUAL    | Alta      |
| 2 | Actualiza_Preca_Dirigida          | JOB_CARGA_MANUAL    | Alta      |
| 3 | ACTUALIZA_XCORE_DIRIGIDA          | JOB_CARGA_MANUAL    | Media     |
| 4 | P_Registra_Solicitud_Dirigida     | JOB_CARGA_MANUAL    | Media     |
| 5 | Precalifica_Campana_Especiales    | JOB_CAMPANAS_ESP    | Alta      |
| 6 | Actualiza_Preca_Campana_Especiale | JOB_CAMPANAS_ESP    | Alta      |
| 7 | ACTUALIZA_XCORE_CAMPANA_ESPECIAL  | JOB_CAMPANAS_ESP    | Media     |
| 8 | P_Registra_Solicitud_Campana      | JOB_CAMPANAS_ESP    | Media     |
| 9 | F_EXISTE_CREDITO                  | Ambos (Manual+Camp) | Media     |

### Puntos adicionales a revisar:
| # | Item                               | Job              | Nota                        |
|---|-----------------------------------|------------------|-----------------------------|
| A | CUR_REPRESTAMO con LEFT JOIN      | JOB_CAMPANAS_ESP | Posible falta de indice     |
| B | UPDATE PR_CARGA_DIRECCIONADA      | JOB_CARGA_MANUAL | Verificar indice en (NO_CREDITO, ESTADO) |
| C | UPDATE PR_CAMPANA_ESPECIALES      | JOB_CAMPANAS_ESP | Verificar indice en (NO_CREDITO, ESTADO) |
| D | COMMIT dentro del loop            | XCORE_SOLICITUD  | Mover fuera si es seguro    |

---

## Analisis de complejidad — Procedimientos unicos

### 1. `Precalifica_Carga_Dirigida` (lineas 1895-2251, ~356 lineas) — PRIORIDAD ALTA

**Patron:** Loop row-by-row sobre PR_CARGA_DIRECCIONADA (estado 'P'), luego BULK COLLECT+FORALL.

**Queries por iteracion del loop (11 SELECTs + 1 UPDATE por fila):**
| # | Query | Tablas | Riesgo |
|---|-------|--------|--------|
| 1 | MAX(FECHA_CORTE) con subquery anidada | PA_DETALLADO_DE08 | Alto — subquery correlada x2, ejecutada 1 vez |
| 2 | COUNT(*) persona fisica | PERSONAS | Bajo — filtro por PK |
| 3 | COUNT(*) nacionalidad con IN (TABLE()) | ID_PERSONAS | Medio — TABLE() function |
| 4 | COUNT(*) sola firma con EXISTS+HAVING | PR_CREDITOS + PR_AVAL_REPRE_X_CREDITO | Alto — JOIN + subquery |
| 5 | COUNT(*) creditos estado E | PR_CREDITOS | Bajo — filtro indexado |
| 6 | COUNT(*) represtamo activo con IN(TABLE()) | PR_REPRESTAMOS | Medio |
| 7 | COUNT(*) tipo credito valido | PR_TIPO_CREDITO_REPRESTAMO + PR_CREDITOS | Bajo |
| 8 | COUNT(*) credito activo con IN(TABLE()) | PR_CREDITOS | Medio |
| 9 | MAX(DIAS_ATRASO) con subquery anidada x3 | PA_DETALLADO_DE08 | **MUY ALTO** — 3 subqueries anidadas |
| 10 | COUNT(*) cancelacion | PR_CREDITOS | Bajo |
| 11 | COUNT(*) capital pagado (JOIN DE08) | PR_CREDITOS + PA_DETALLADO_DE08 | Alto — JOIN pesado |
| 12 | COUNT(*) atraso TC | PA_DETALLADO_DE08 | Medio |

**Funciones llamadas en loop:** F_TIENE_GARANTIA, F_VALIDAR_EDAD, F_Validar_Listas_PEP, F_Validar_Lista_NEGRA

**BULK COLLECT (lineas 2204-2231):**
- INSERT FORALL → PR_REPRESTAMOS (OK)
- UPDATE FORALL con subquery correlada MAX(DIAS_ATRASO) en PA_DETALLADO_DE08 — **potencialmente costoso**

**Antipatron:** COMMIT dentro del loop (linea 2201). Mismo problema que OPT-003/006.

**Queries sospechosos para Explain Plan:**
1. Query 9 (MAX DIAS_ATRASO con 3 subqueries) — probable >10,000 cost
2. Query 4 (sola firma con HAVING) — probable >5,000 cost
3. Query 11 (capital pagado con JOIN PA_DETALLADO_DE08)
4. FORALL UPDATE con subquery correlada (linea 2215-2227)

---

### 2. `Precalifica_Campana_Especiales` (lineas 2253-2611, ~358 lineas) — PRIORIDAD ALTA

**Patron:** Identico a Precalifica_Carga_Dirigida, pero opera sobre PR_CAMPANA_ESPECIALES en vez de PR_CARGA_DIRECCIONADA.

**Diferencias vs Carga Dirigida:**
- Cursor lee de PR_CAMPANA_ESPECIALES (no PR_CARGA_DIRECCIONADA)
- Query adicional: `SELECT COUNT(*) FROM PR_REPRESTAMO_CAMPANA_DET` (linea 2323) — con subquery ORDER BY + ROWNUM, **potencialmente costoso**
- Los UPDATEs de rechazo van a PR_CAMPANA_ESPECIALES (no PR_CARGA_DIRECCIONADA)
- F_TIENE_GARANTIA esta comentada (no se ejecuta)

**Mismos 11 queries del loop + 1 adicional.** Mismos riesgos que Carga Dirigida.

**Query adicional sospechoso (linea 2323-2324):**
```sql
SELECT COUNT(*) FROM PR_REPRESTAMO_CAMPANA_DET C
WHERE C.TIPO_CREDITO_ORIGEN = (
  SELECT TIPO_CREDITO FROM (
    SELECT TIPO_CREDITO FROM PR_CAMPANA_ESPECIALES
    WHERE CODIGO_CLIENTE = A.CODIGO_CLIENTE
    ORDER BY FECHA_ADICION DESC
  ) WHERE ROWNUM = 1
) AND ESTADO = 1;
```
**Riesgo:** ORDER BY + ROWNUM sin indice en (CODIGO_CLIENTE, FECHA_ADICION) = FULL TABLE SCAN

---

### 3. `Actualiza_Preca_Dirigida` (lineas 2919-3118, ~200 lineas) — PRIORIDAD ALTA

**Patron:** 4 loops secuenciales con COMMITs por iteracion.

**Loop 1 — Actualizar_Mto_Credito_Actual (linea 2984):**
```sql
UPDATE PR_REPRESTAMOS SET MTO_CREDITO_ACTUAL = (
  SELECT monto_desembolsado FROM PA_DETALLADO_DE08
  WHERE ... AND FECHA_CORTE = (SELECT MAX(FECHA_CORTE) FROM PA_DETALLADO_DE08 WHERE ...)
)
```
- UPDATE row-by-row con subquery correlada + MAX anidado — **mismo patron que OPT-004**
- Ademas: UPDATE PR_REPRESTAMOS SET ESTADO='RSB' con subquery a PA_DETALLADO_DE08 + TABLE() function
- COMMIT por iteracion

**Loop 2 — PRECALIFICADOS (linea 3024):**
- UPDATE por ROWID (eficiente) pero COMMIT por iteracion

**Loop 3 — CUR_DE08_SIB (linea 3052):**
- SELECT con CONNECT BY para parsear CSV de parametros — **mismo patron que OPT-002**
- Llama OBT_IDENTIFICACION_PERSONA() en la condicion JOIN — **context switch costoso por fila**

**Loop 4 — CUR_DE05_SIB (linea 3088):**
- Mismo patron que Loop 3

**Optimizaciones aplicables (ya probadas en Job 1):**
- OPT-004: Convertir Loop 1 a UPDATE set-based
- OPT-002: Los cursores CUR_DE08_SIB y CUR_DE05_SIB son **identicos** a los del Job 1 — ya optimizados con indices
- OPT-003: Mover COMMITs fuera de los loops

---

### 4. `Actualiza_Preca_Campana_Especiale` (lineas 3120-3332, ~212 lineas) — PRIORIDAD ALTA

**Clon de Actualiza_Preca_Dirigida** con estas diferencias:
- Los UPDATEs de rechazo van a PR_CAMPANA_ESPECIALES
- El parametro SIB es 'VALIDAR_CLASIFICACION_SIB_CAMPANA' (no CARGADIRIGIDA)
- No tiene DELETE PR_REPRESTAMOS WHERE CODIGO_PRECALIFICACION IS NULL

**Mismos 4 loops, mismos riesgos, mismas optimizaciones aplicables.**

---

### 5. `ACTUALIZA_XCORE_DIRIGIDA` (lineas 3509-3577, ~68 lineas) — PRIORIDAD BAJA

**Patron:** Loop anidado (i x CUR_UPDATE_XCORE) que llama a PA_PKG_CONSULTA_DATACREDITO.CONSULTAR_JSON.

**El cuello de botella NO es SQL sino la llamada a DataCredito (servicio externo).**
- COMMIT por fila (linea 3554)
- La unica query: CUR_UPDATE_XCORE filtra por ESTADO='RE' AND XCORE_GLOBAL IS NULL — deberia ser rapida

**No hay queries SQL costosos que optimizar con indices.** El rendimiento depende del servicio externo.

---

### 6. `ACTUALIZA_XCORE_CAMPANA_ESPECIAL` (lineas 3579-3658, ~79 lineas) — PRIORIDAD BAJA

**Clon de ACTUALIZA_XCORE_DIRIGIDA** con diferencia:
- La llamada a DataCredito esta **hardcodeada a xcore := 750** (linea 3628) — esto es un mock/test
- Diferencia en logica de VALIDACION_CLASIFICACION (usa parametro CAMPANA)

**En produccion deberia activarse la llamada real. No hay queries SQL que optimizar.**

---

### 7. `P_Registra_Solicitud_Dirigida` (lineas 7269-7428, ~160 lineas) — PRIORIDAD MEDIA

**Patron:** Procedimiento row-level (llamado desde loop del orquestador).

**Queries:**
| # | Query | Riesgo |
|---|-------|--------|
| 1 | SELECT CODIGO_CLIENTE FROM PR_REPRESTAMOS WHERE ID=:id | Bajo (PK) |
| 2 | SELECT CELULAR FROM PR_CARGA_DIRECCIONADA JOIN PR_REPRESTAMOS | Medio — JOIN sin ROWNUM podria no ser optimo |
| 3 | SELECT ID_REPRESTAMO FROM PR_SOLICITUD_REPRESTAMO | Bajo (PK) |
| 4 | INSERT INTO PR_SOLICITUD_REPRESTAMO | Bajo |
| 5 | F_OBTENER_NUEVO_CREDITO(id) | ✅ Ya optimizado OPT-009 |
| 6 | INSERT INTO PR_CANALES_REPRESTAMO | Bajo |

**Funciones llamadas:** p_datos_primarios, p_datos_secundarios — obtienen datos de CLIENTES_B2000 y PA.PERSONAS_FISICAS
**No hay queries criticos propios.** El OPT-009 ya cubre F_OBTENER_NUEVO_CREDITO.

---

### 8. `P_Registra_Solicitud_Campana` (lineas 7429-7582, ~153 lineas) — PRIORIDAD MEDIA

**Similar a P_Registra_Solicitud_Dirigida** con diferencias:
- Lee celular de PR_CAMPANA_ESPECIALES (no PR_CARGA_DIRECCIONADA)
- Recibe pTipo_Credito como parametro
- Logica adicional: si F_OBTENER_NUEVO_CREDITO retorna 1, anula el represtamo y actualiza PR_CAMPANA_ESPECIALES
- Llama F_Validar_Tipo_Represtamo

**No hay queries SQL criticos nuevos.** OPT-009 ya cubre la funcion mas costosa.

---

### 9. `F_EXISTE_CREDITO` (lineas 9625-9639, ~15 lineas) — PRIORIDAD BAJA

```sql
SELECT COUNT(1) FROM PR_SOLICITUD_REPRESTAMO
WHERE CODIGO_EMPRESA = F_Obt_Empresa_Represtamo
  AND ID_REPRESTAMO = :id
  AND TIPO_CREDITO IS NOT NULL;
```
**Query trivial sobre PK.** No requiere optimizacion.

---

## Ranking de prioridad para Explain Plan en Toad

| Prioridad | Procedimiento | Query critico | Linea | Riesgo estimado |
|-----------|--------------|---------------|-------|-----------------|
| 🔴 1 | Precalifica_Carga_Dirigida | MAX(DIAS_ATRASO) con 3 subqueries anidadas | 2027-2038 | >10,000 cost |
| 🔴 2 | Precalifica_Carga_Dirigida | Capital pagado (JOIN PA_DETALLADO_DE08) | 2049-2058 | >5,000 cost |
| 🔴 3 | Precalifica_Carga_Dirigida | Sola firma (HAVING + EXISTS) | 1972-1986 | >5,000 cost |
| 🔴 4 | Precalifica_Campana_Especiales | Mismos queries (clon) | 2392-2431 | Idem |
| 🔴 5 | Precalifica_Campana_Especiales | REPRESTAMO_CAMPANA_DET con ORDER BY+ROWNUM | 2323-2324 | >3,000 cost |
| 🟡 6 | Actualiza_Preca_Dirigida | UPDATE MTO_CREDITO_ACTUAL con subquery anidada | 2985-2999 | Aplicar OPT-004 |
| 🟡 7 | Actualiza_Preca_Dirigida | CUR_DE08_SIB con OBT_IDENTIFICACION_PERSONA | 2943-2951 | Aplicar OPT-002 |
| 🟡 8 | Actualiza_Preca_Campana_Especiale | Mismos queries (clon) | 3184-3258 | Idem |
| 🟢 9 | FORALL UPDATE DIAS_ATRASO (ambos Precalifica) | Subquery correlada en FORALL | 2215-2227 | Medio |

**Observacion clave:** Las optimizaciones OPT-002, OPT-003 y OPT-004 son **directamente replicables** en los procedimientos Dirigida/Campana porque son clones del flujo original con tablas diferentes.

---

## Pendientes globales (sin cambio)
- **SQL 371 propuesta:** cost 9,748→26 con hardcodeo de estados — pendiente aprobacion del jefe
- **SQL 149/171/188:** cost 129,413 — requieren export del Quest Optimizer (no aparecen en PDF)

---

## Siguiente paso recomendado
1. **Toad Explain Plan** sobre los 5 queries rojos (prioridad 1-5) para confirmar cost real
2. **Replicar OPT-002/003/004** en Actualiza_Preca_Dirigida y Actualiza_Preca_Campana_Especiale (son clones)
3. **Evaluar** si los queries del loop de Precalifica_Carga_Dirigida se pueden convertir a set-based
4. Confirmar definiciones de JOB_PRECALIFICA_REPRESTAMO y XCORE_SOLICITUD_CR_JOB en la BD
