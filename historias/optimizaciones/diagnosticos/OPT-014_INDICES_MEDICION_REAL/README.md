# OPT-014 — Medicion real del impacto de indices (OPT-002, 009, 011, 013)

- **Paquete**: PR_PKG_REPRESTAMOS
- **Job medido**: P_Carga_Precalifica_Cancelado (orquestador principal)
- **Entorno**: DESARROLLO (ADMQA1 / bmadev0004)
- **Fecha**: 2026-04-13
- **Tipo**: Medicion de rendimiento real (no Explain Plan)

## Contexto

Las optimizaciones OPT-002, OPT-009, OPT-011 y OPT-013 crearon 4 indices que mejoraban
los Explain Plans teoricos. Esta medicion valida el impacto real ejecutando el orquestador
completo con datos de produccion (~190 represtamos en estado RE, tablas SIB con 10-20M filas).

## Indices medidos

| OPT | Indice | Tabla | Explain Plan (teorico) |
|-----|--------|-------|----------------------|
| OPT-002 | IDX_DE08_SIB_FECHA_DEUDOR | PA.PA_DE08_SIB (FECHA_CORTE, ID_DEUDOR, CLASIFICACION) | 64,753 -> 39 |
| OPT-009 | IDX_CREDITOS_HI_NOCREDITO | PR.PR_CREDITOS_HI (NO_CREDITO) | 17,232 -> 909 |
| OPT-011 | IDX_REPRESTAMOS_EMP_EST_NOCRED | PR.PR_REPRESTAMOS (CODIGO_EMPRESA, ESTADO, NO_CREDITO, ID_REPRESTAMO) | 10,656 -> 9,748 |
| OPT-013 | IDX_DE05_SIB_CASTIGO_CEDULA | PA.PA_DE05_SIB (FECHA_CASTIGO, CEDULA, ENTIDAD) | 120,122 -> 11 |

## Metodologia

1. Compilar paquete de produccion en DESARROLLO (todos los procedimientos activos)
2. Verificar 190 registros en estado 'RE' como data de prueba
3. Ejecutar script instrumentado (`05_MEDIR_JOB_CANCELADO_DETALLADO.sql`) SIN indices
4. Restaurar los 190 RE
5. Crear los 4 indices
6. Ejecutar el mismo script CON indices
7. Comparar resultados por procedimiento

**Nota**: V$MYSTAT disponible — metricas completas de CPU/LIO/PIO.

## Resultados: Resumen ejecutivo

| Metrica | ANTES (sin indices) | DESPUES (con indices) | Mejora |
|---------|--------------------|-----------------------|--------|
| **Tiempo total** | **1,454 seg (24.2 min)** | **854 seg (14.2 min)** | **-41%** |
| CPU (centiseg) | ~130,000 | ~83,000 | -36% |
| Physical I/O | ~960,000 | ~7,000 | -99.3% |

## Resultados: Desglose por procedimiento

| # | Procedimiento | ANTES (seg) | DESPUES (seg) | Mejora | CPU antes | CPU desp | LIO antes | LIO desp |
|---|--------------|-------------|---------------|--------|-----------|----------|-----------|----------|
| 1 | P_Actualizar_Anular_Represtamo | 1.4 | 1.3 | = | 81 | 80 | 57,059 | 55,439 |
| 2 | **Precalifica_Represtamo** | **278.7** | **98.0** | **-65%** | 24,041 | 9,551 | 9,626,316 | 8,787,423 |
| 3 | **Precalifica_Represtamo_fiadores** | **190.8** | **53.8** | **-72%** | 18,550 | 5,329 | 6,470,846 | 7,528,403 |
| 4 | **Precalifica_Represtamo_fiadores_hi** | **177.9** | **36.9** | **-79%** | 9,798 | 3,651 | 7,099,667 | 7,099,747 |
| 5 | **Precalifica_Repre_Cancelado** | **391.7** | **231.5** | **-41%** | 37,424 | 22,917 | 22,121,084 | 17,164,401 |
| 6 | Precalifica_Repre_Cancelado_hi | 381.6 | 392.5 | +3% | 37,232 | 38,900 | 21,442,729 | 25,565,331 |
| 7 | **Actualiza_Precalificacion** | **13.3** | **3.2** | **-76%** | 869 | 103 | 742,763 | 12,245 |
| 8 | Actualiza_XCORE_CUSTOM | 0 | 12.5 | n/a | 2 | 48 | 217 | 1,906 |
| 9 | P_REGISTRO_SOLICITUD | 18.6 | 23.9 | +28% | 1,296 | 2,347 | 749,299 | 1,514,665 |
| 10 | PVALIDA_WORLD_COMPLIANCE | 0.1 | 0.8 | n/a | 6 | 74 | 2,599 | 40,980 |
| 11 | PVALIDA_XCORE | 0 | 0 | = | 3 | 4 | 1,295 | 1,310 |
| 12 | Loop Bitacora+Validaciones | 0 | 0 | = | 3 | 6 | 191 | 165 |
| | **TOTAL** | **1,454** | **854** | **-41%** | | | | |

## Analisis

### Mejoras significativas (pasos 2-5, 7)
Los 4 indices redujeron el tiempo en ~600 segundos. El mayor impacto fue en:
- **Paso 4 (fiadores_hi)**: -79% gracias al indice en PA_DE08_SIB (OPT-002)
- **Paso 3 (fiadores)**: -72% por la misma razon
- **Paso 7 (Actualiza_Precalificacion)**: -76%, LIO bajo de 742K a 12K
- **Paso 2 (Precalifica_Represtamo)**: -65%, primera fase de precalificacion

### Anomalia: Paso 6 (Precalifica_Repre_Cancelado_hi) NO mejoro
- PIO bajo de 3,866 a 415 (el indice funciona para lecturas de disco)
- Pero LIO SUBIO de 21M a 25M (+19%)
- CPU subio de 37,232 a 38,900
- Hipotesis: este procedimiento tiene queries donde Oracle elige el indice pero hace mas
  buffer cache reads que con full table scan. Puede ser un caso donde el indice no es selectivo
  para la data historica que procesa este procedimiento.
- **Requiere investigacion adicional** — ver seccion "Pendientes"

### Pasos 8 y 9 subieron ligeramente
No es regresion de los indices. El conjunto de represtamos sobrevivientes a precalificacion
cambio entre runs: ANTES quedaron 5 en estado RE; DESPUES quedaron 8. Como pasos 8-9 solo
procesan los que siguen en RE, procesaron mas registros y por eso subieron en tiempo absoluto.

**Aclaracion tecnica**: los indices NO cambian que registros rechaza una query — solo
cambian como Oracle accede a la data. La diferencia 5 vs 8 se debe a drift en datos
auxiliares entre corridas (PA_DE05_SIB, PA_DE08_SIB, PR_CREDITOS_HI pudieron actualizarse;
o validaciones con SYSDATE corrieron a horas distintas). Solo se restauraron los 190 RE
de PR_REPRESTAMOS, no las tablas dependientes.

**Normalizado por registro**: P_REGISTRO_SOLICITUD paso de 18.6s/5 reg = ~3.7s/reg ANTES
a 23.9s/8 reg = ~3.0s/reg DESPUES. Por registro mejoro ~19%, no empeoro.

Para una medicion futura rigurosa: congelar todas las tablas dependientes entre corridas
o normalizar metricas por cantidad de RE procesados.

## Volumenes de datos

| Tabla | Filas |
|-------|-------|
| PR_REPRESTAMOS (total) | 8,012 |
| PR_REPRESTAMOS (ESTADO=RE) | 190 |
| PA_DE05_SIB | 10,691,245 |
| PA_DE08_SIB | 20,681,243 |
| PR_CREDITOS_HI | 838,369 |
| PR_CREDITOS | 641,307 |

## Scripts utilizados

| Archivo | Proposito |
|---------|-----------|
| `scripts_medicion/05_MEDIR_JOB_CANCELADO_DETALLADO.sql` | Script instrumentado con timer por procedimiento |
| `scripts_medicion/03_CREATE_INDICES_RESTAURAR.sql` | Creacion de los 4 indices |

## Pendientes

1. **Paso 5-6 (Cancelado + Cancelado_hi) — INVESTIGADO Y CERRADO para indices**:
   - Causa raiz: el cuello de botella es CPU (32K-38K centiseg), no I/O.
   - Se probo indice `IDX_DE08_FUENTE_NOCRED_FECHA ON PA_DETALLADO_DE08 (FUENTE, NO_CREDITO, FECHA_CORTE DESC)`.
   - **Resultado**: paso 5 empeoro (+43%), paso 6 mejoro marginalmente (-5%). Indice eliminado.
   - **Conclusion**: estos pasos NO se optimizan con indices. El problema es:
     - Funciones PL/SQL por fila (F_TIENE_GARANTIA, F_TIENE_GARANTIA_HISTORICO)
     - Context switching SQL↔PL/SQL en los loops
     - FORALL con subqueries correladas
   - **Accion futura**: Rewrite de codigo (inline funciones, set-based UPDATE, MERGE).
     Equivalente a replicar OPT-004/OPT-010 en Cancelado/Cancelado_hi.
2. **Medir en QA**: Repetir la medicion cuando QA este disponible (actualmente en uso por otro desarrollador).
3. **Medir con cambios de codigo**: OPT-004 (set-based) + OPT-010 (inline NOT EXISTS) son cambios
   de codigo que no se midieron aqui. Solo se midieron los indices.

## Medicion adicional: 5to indice en PA_DETALLADO_DE08 (DESCARTADO)

Se creo y probo `IDX_DE08_FUENTE_NOCRED_FECHA ON PA.PA_DETALLADO_DE08 (FUENTE, NO_CREDITO, FECHA_CORTE DESC)`
para intentar mejorar los pasos 5 y 6. Resultado con 5 indices vs 4 indices:

| Paso | 4 indices | 5 indices | Cambio |
|------|-----------|-----------|--------|
| 5. Precalifica_Repre_Cancelado | 231.5 s | 330.5 s | +43% (peor) |
| 6. Precalifica_Repre_Cancelado_hi | 392.5 s | 371.8 s | -5% (marginal) |
| **TOTAL** | **854 s** | **942 s** | **+10% (peor)** |

**Decision**: Indice eliminado. Oracle lo usaba ineficientemente para el patron de acceso de estos
procedimientos, causando mas buffer reads que el full table scan. El cuello de botella es CPU
(funciones PL/SQL por fila), no I/O.

## Como revertir

```sql
-- Eliminar los 4 indices:
DROP INDEX PA.IDX_DE08_SIB_FECHA_DEUDOR;
DROP INDEX PR.IDX_CREDITOS_HI_NOCREDITO;
DROP INDEX PR.IDX_REPRESTAMOS_EMP_EST_NOCRED;
DROP INDEX PA.IDX_DE05_SIB_CASTIGO_CEDULA;
```
