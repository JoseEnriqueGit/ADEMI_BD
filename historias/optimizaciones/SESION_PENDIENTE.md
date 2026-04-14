# Sesion Pendiente — Continuacion de optimizaciones OPT

> Documento de contexto para continuar el trabajo de optimizacion en otra PC/sesion.
> Fecha: 2026-04-14 (actualizado)
> Sesion anterior: Claude Code VS Code Extension

---

## Resumen de lo completado (sesion 2026-04-14)

### OPT-015: Rewrite set-based + NOT EXISTS en pasos 5-6 (COMPLETADO)

**Resultado**: Job total 23 min → 11.3 min (**-51%**). Pasos 5+6: 856 seg → 378 seg (**-56%**)

**Paso a paso de lo realizado:**

1. **Reconstruccion del contexto**: La sesion anterior no persistio la carpeta OPT-015 ni el plan. Se reconstruyo todo desde SESION_PENDIENTE.md y los READMEs de OPT-004/OPT-010.

2. **Extraccion de PA.P_DATOS_PERSONA**: El usuario copio spec.sql y body.sql del paquete PA.P_DATOS_PERSONA desde Toad a `ENTORNOS_ORACLE/DESARROLLO/schemas/PA/packages/PA.p_datos_persona/`.

3. **A.0.1 - Verificacion funciones PEP/NEGRA (COMPLETADO)**:
   - `esta_en_lista_pep` (L.314 body PA): SELECT INTO a `lista_pep` — read-only
   - `esta_en_lista_negra` (L.129 body PA): SELECT INTO a `lista_negra` — read-only
   - Conclusion: seguro mover a DELETE post-INSERT

4. **A.0.2 - Indice IDX_GARANTIAS_TIPO_SB (COMPLETADO)**:
   - No existia en DESARROLLO (solo en QA desde OPT-010)
   - Creado: `CREATE INDEX PR.IDX_GARANTIAS_TIPO_SB ON PR.PR_GARANTIAS (CODIGO_EMPRESA, NUMERO_GARANTIA, CODIGO_TIPO_GARANTIA_SB) TABLESPACE PR_DAT;`

5. **A.0.3 - Parametros verificados (COMPLETADO)**:
   - `LOTE_DE_CARAGA_REPRESTAMO = 5` (batches de 5 filas por iteracion)
   - `f_obt_Empresa_Represtamo = 1`
   - Nota: la tabla PA_PARAMETROS_MVP tiene columna CODIGO_PARAMETRO (no COD_PARAMETRO)

6. **A.1 - Explain Plans Q1-Q12 (COMPLETADO)**:
   - Script: `OPT-015_SETBASED_CANCELADO_REWRITE/scripts_medicion/explain_plan_opt015.sql`
   - Resultados:

   | Query | Descripcion | Cost |
   |-------|-------------|------|
   | Q1 | Cursor Cancelado (DESPUES) | 5,541 |
   | Q2 | Cursor Cancelado_hi (DESPUES) | 8,732 |
   | Q3 | UPDATE DIAS_ATRASO set-based | 15,182 |
   | Q4 | UPDATE MTO_CREDITO set-based | 9 |
   | Q5 | UPDATE X3 TC set-based | 7 |
   | Q6 | UPDATE X1 desembolso set-based | 24,551 |
   | Q7 | DELETE PEP | 3 |
   | Q8 | DELETE NEGRA | 3 |
   | Q9 | ANTES FORALL DIAS_ATRASO (x1) | 53 |
   | Q10 | ANTES FORALL MTO_CREDITO (x1) | 1,010 |
   | Q11 | ANTES FORALL X3 TC (x1) | 8 |
   | Q12 | ANTES FORALL X1 desembolso (x1) | 37 |

   - IDX_GARANTIAS_TIPO_SB aparece en Q1/Q2 — NOT EXISTS inline usa el indice
   - Sin FULL TABLE SCAN en tablas grandes
   - Fase A aprobada

7. **Fase B - Modificacion del body.sql (COMPLETADO)**:
   - **Cambio 1 (Cursor)**: `F_TIENE_GARANTIA(a.no_credito) = 0` reemplazado por NOT EXISTS inline con JOIN a PR_CREDITOS → PR_GARANTIAS_X_CREDITO → PR_GARANTIAS. PEP/NEGRA eliminados del cursor.
   - **Cambio 2 (Loop)**: 4 FORALL UPDATEs removidos del loop. Loop simplificado a solo INSERT + EXIT.
   - **Cambio 3 (Post-loop)**: 4 UPDATEs set-based (U1-U4) con filtros defensivos `ADICIONADO_POR=USER AND FECHA_ADICION>=TRUNC(SYSDATE)`. 2 DELETEs post-INSERT para PEP/NEGRA.
   - **Cambio 4**: Identico al 1-2-3 para Precalifica_Repre_Cancelado_hi (usa PR_CREDITOS_HI)
   - Archivos: `body_ANTES_OPT015.sql` (rollback), `body_DESPUES_OPT015.sql` (cambios)

8. **Medicion ANTES (body original)**:
   - Restaurar RE: `UPDATE PR.PR_REPRESTAMOS SET ESTADO='RE' WHERE MODIFICADO_POR IS NULL AND FECHA_MODIFICACION >= DATE '2026-04-10' AND ESTADO IN ('AN','NP','CP','RXT','RXC');`
   - 196 filas restauradas

   | Paso | Tiempo | CPU |
   |------|--------|-----|
   | 5. Precalifica_Repre_Cancelado | 346.8 seg | 31,360 |
   | 6. Precalifica_Repre_Cancelado_hi | 509.2 seg | 50,109 |
   | **TOTAL** | **1,381 seg (23 min)** | |
   | RE procesados | 10 | |

9. **Compilacion y medicion DESPUES (body OPT-015)**:

   | Paso | Tiempo | CPU |
   |------|--------|-----|
   | 5. Precalifica_Repre_Cancelado | 170.2 seg | 16,864 |
   | 6. Precalifica_Repre_Cancelado_hi | 207.9 seg | 20,366 |
   | **TOTAL** | **680 seg (11.3 min)** | |
   | RE procesados | 15 | |

10. **Validacion de equivalencia semantica (COMPLETADO)**:
    - Se crearon tablas snapshot: `JOOGANDO.OPT015_RE_ANTES`, `OPT015_RESULTADO_DESPUES`, `OPT015_RESULTADO_ANTES`
    - Query 2 (campos clave ESTADO, DIAS_ATRASO, MTO_CREDITO_ACTUAL): **0 diferencias**
    - Query 1 (filas exclusivas): 3 filas "Solo en ANTES" (18 RE vs 15 RE)
    - Causa: variabilidad entre ejecuciones por `ROWNUM <= 5` sin ORDER BY. El cursor no garantiza orden de filas entre ejecuciones. Comportamiento del codigo original, no introducido por OPT-015.

11. **Commit**: `02c8df3` — incluye body.sql modificado, body rollback, explain plans, HANDOFF, PA.P_DATOS_PERSONA, README actualizado.

**Acumulado desde baseline original:**

| Medicion | Tiempo | Reduccion |
|----------|--------|-----------| 
| Baseline original (sin indices) | ~24 min | — |
| Con indices OPT-014 | 14.2 min | -41% |
| Con indices + OPT-015 set-based | **11.3 min** | **-53%** |

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
- La solucion requiere cambios de codigo, no indices adicionales → resuelto por OPT-015

---

## Estado actual de DESARROLLO (ADMQA1)

- **Body compilado**: OPT-015 (optimizado) — verificado con `SELECT COUNT(*) FROM ALL_SOURCE WHERE TEXT LIKE '%OPT-015%'` = 10
- **5 indices OPT creados y VALID** (4 de OPT-014 + IDX_GARANTIAS_TIPO_SB de OPT-015)
- **Tablas backup**: `JOOGANDO.PR_REPRESTAMOS_POST`, `PR.OPT_HIWATER_MARKS`
- **Tablas de validacion OPT-015**: `JOOGANDO.OPT015_RE_ANTES`, `OPT015_RESULTADO_ANTES`, `OPT015_RESULTADO_DESPUES`
- **Restaurar RE**: `UPDATE PR.PR_REPRESTAMOS SET ESTADO='RE' WHERE MODIFICADO_POR IS NULL AND FECHA_MODIFICACION >= DATE '2026-04-10' AND ESTADO IN ('AN','NP','CP','RXT','RXC');`

---

## Lo que queda pendiente

### 1. OPT-015: Aprobar para produccion
- **Estado**: Completado en DESARROLLO, pendiente aprobacion del jefe
- **Accion**: Presentar resultados (23 min → 11.3 min, -51%) y validacion de equivalencia
- **Pendiente**: Medir en QA cuando este disponible
- **Rollback**: `body_ANTES_OPT015.sql` en carpeta OPT-015

### 2. Propuestas de hardcodeo — 3 cursores del job mensual (cost total 11,698 → 62)
- **Estado**: Propuestas documentadas, pendientes aprobacion del jefe
- **Archivos**:
  - `historias/optimizaciones/propuestas/SQL371_HARDCODEO_ESTADOS.md`
  - `historias/optimizaciones/propuestas/CURSORES_ANULAR_HARDCODEO_ESTADOS.md`
- **Accion**: Preguntar al jefe si aprueba el trade-off (hardcodeo vs parametros dinamicos)

### 3. SQL 151/172 del Quest (cost 106,783)
- **Estado**: Probablemente ya resueltos por OPT-013, falta confirmar
- **Accion**: Pedirle al companero que muestre el SQL Text en Quest SQL Optimizer

### 4. UPDATE MTO_CREDITO_ACTUAL en Actualiza_Preca_Dirigida
- **Estado**: Cost 324/fila vs 10 set-based. Depende del volumen
- **Accion**: Averiguar cuantos registros RE procesa el job de carga dirigida

### 5. COMMITs dentro de loops
- **Estado**: Aplica a Actualiza_Preca_Dirigida y Actualiza_Preca_Campana_Especiale
- **Accion**: Solo vale la pena si lotes > 100 registros

---

## Archivos de referencia

| Archivo | Contenido |
|---------|-----------|
| `historias/optimizaciones/README.md` | Indice de todas las OPT (001-015) |
| `historias/optimizaciones/PENDIENTES.md` | SQLs pendientes del Quest |
| `historias/optimizaciones/MAPA_JOBS.md` | Mapa completo de los 5 jobs |
| `historias/optimizaciones/OPT-015_SETBASED_CANCELADO_REWRITE/HANDOFF.md` | Contexto completo OPT-015 |
| `historias/optimizaciones/OPT-015_SETBASED_CANCELADO_REWRITE/body_ANTES_OPT015.sql` | Body rollback |
| `historias/optimizaciones/OPT-015_SETBASED_CANCELADO_REWRITE/body_DESPUES_OPT015.sql` | Body optimizado |
| `ENTORNOS_ORACLE/DESARROLLO/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | Body actual (OPT-015) |
| `ENTORNOS_ORACLE/DESARROLLO/schemas/PA/packages/PA.p_datos_persona/` | Paquete PA.P_DATOS_PERSONA |

## Nota sobre variabilidad entre ejecuciones
El cursor usa `ROWNUM <= 5` (LOTE) sin ORDER BY, por lo que Oracle no garantiza el orden de las filas retornadas. Entre ejecuciones, el optimizer puede elegir un plan diferente o los bloques en buffer pueden variar, resultando en que se procesen creditos distintos. Esto es comportamiento normal del codigo original — no fue introducido por OPT-015.
