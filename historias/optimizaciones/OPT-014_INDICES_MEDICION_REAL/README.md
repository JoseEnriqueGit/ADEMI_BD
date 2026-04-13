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
No es regresion de los indices. Se procesaron mas RE (v_conteo=8 vs 5) porque con indices
la precalificacion rechaza menos registros, dejando mas trabajo para XCORE y REGISTRO_SOLICITUD.

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

1. **Paso 6 (Precalifica_Repre_Cancelado_hi) — INVESTIGADO**:
   - Causa raiz: los indices creados NO cubren los queries de este procedimiento.
   - Usa `PR_CREDITOS_HI` (no `PR_CREDITOS`) y `PA.PA_DETALLADO_DE08` (no `PA_DE08_SIB`).
   - El FORALL UPDATE hace `SELECT MAX(DIAS_ATRASO) FROM PA_DETALLADO_DE08` sin indice adecuado.
   - LIO subio porque Oracle eligio indice IDX_REPRESTAMOS_EMP_EST_NOCRED con mas buffer reads
     que el full table scan para el patron de acceso historico.
   - **Accion futura**: Crear indice en PA_DETALLADO_DE08 (FUENTE, NO_CREDITO, FECHA_CORTE DESC),
     revisar F_TIENE_GARANTIA_HISTORICO, evaluar rewrite del FORALL a MERGE/set-based.
2. **Medir en QA**: Repetir la medicion cuando QA este disponible (actualmente en uso por otro desarrollador).
3. **Medir con cambios de codigo**: OPT-004 (set-based) + OPT-010 (inline NOT EXISTS) son cambios
   de codigo que no se midieron aqui. Solo se midieron los indices.

## Como revertir

```sql
-- Eliminar los 4 indices:
DROP INDEX PA.IDX_DE08_SIB_FECHA_DEUDOR;
DROP INDEX PR.IDX_CREDITOS_HI_NOCREDITO;
DROP INDEX PR.IDX_REPRESTAMOS_EMP_EST_NOCRED;
DROP INDEX PA.IDX_DE05_SIB_CASTIGO_CEDULA;
```
