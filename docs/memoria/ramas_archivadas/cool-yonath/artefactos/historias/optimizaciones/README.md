# Indice de Optimizaciones

> Registro de todas las optimizaciones de rendimiento realizadas a objetos Oracle.
> Cada optimizacion tiene su propia carpeta con documentacion, diff y rollback.
> Ver `MAPA_JOBS.md` para el arbol de llamadas completo por orquestador.

---

## Leyenda de columnas

- **Orquestador**: Job en el que participa la optimizacion (ver `MAPA_JOBS.md`).
  - Job1 = `P_Carga_Precalifica_Cancelado` (orquestador principal — medido en OPT-014)
  - Job2 = `P_Carga_Precalifica_Represtamo`
  - Job3 = `P_Carga_Precalifica_Manual`
  - Job4 = `P_Carga_Precalifica_Campana_Especial`
  - Job5 = `P_REGISTRO_SOLICITUD` (job independiente)
  - JobAnular = `JOB_ACTUALIZAR_ANULAR_RD` (mensual)
- **Tipo**: Indice | Codigo | Estructural (COMMITs/redo log) | Combinado
- **Medido real**: ✅ validado en tiempo real (OPT-014) | ❌ solo Explain Plan | N/A

---

## Tabla maestra

| ID      | Objeto                 | Procedure/SQL              | Cost Antes | Cost Despues | Orquestador                     | Tipo       | Medido real                              | Entorno | Fecha      |
|---------|------------------------|----------------------------|------------|--------------|---------------------------------|------------|------------------------------------------|---------|------------|
| OPT-001 | PR_PKG_REPRESTAMOS     | PVALIDA_WORLD_COMPLIANCE   | 18,293     | 15           | Job1 paso 10                    | Codigo + Estructural | ❌                               | QA      | 2026-03-18 |
| OPT-002 | PR_PKG_REPRESTAMOS     | CUR_DE08_SIB, CUR_DE05_SIB | ~16,963    | <100         | Job1 paso 7 (+ impacto paso 4), Job3, Job4 | Indice + Codigo | ✅ indice (paso 4: -79%) / ❌ codigo | QA | 2026-03-19 |
| OPT-003 | PR_PKG_REPRESTAMOS     | Actualiza_Precalificacion  | N/A (redo) | -99% flushes | Job1 paso 7                     | Estructural | ❌                                      | QA      | 2026-03-19 |
| OPT-004 | PR_PKG_REPRESTAMOS     | Actualiza_Precalificacion  | N iters    | 2 UPDATEs    | Job1 paso 7                     | Codigo + Indice | ❌                                  | QA      | 2026-03-24 |
| OPT-005 | PR_PKG_REPRESTAMOS     | Actualiza_XCORE_CUSTOM     | N*M iters  | 1 UPDATE     | Job1 paso 8                     | Codigo     | ❌                                      | QA      | 2026-03-19 |
| OPT-006 | PR_PKG_REPRESTAMOS     | P_REGISTRO_SOLICITUD       | N/A (redo) | -99% flushes | Job1 paso 9, Job3               | Estructural | ❌                                      | QA      | 2026-04-06 |
| OPT-007 | PR_PKG_REPRESTAMOS     | PVALIDA_XCORE              | N/A (redo) | -99% flushes | Job1 paso 11, Job3, Job4        | Estructural | ❌                                      | QA      | 2026-03-19 |
| OPT-008 | PR_PKG_REPRESTAMOS     | P_Carga_Precalifica_Cancel | 3-9 SELECTs| 3 SELECTs    | Job1 paso 12, Job3, Job4        | Codigo     | ❌                                      | QA      | 2026-03-19 |
| OPT-009 | PR_PKG_REPRESTAMOS     | F_Obtener_Nuevo_Credito    | 17,232     | 909          | Job1 pasos 2/3/5, Job3, Job4    | Indice + Codigo | ✅ indice (paso 2: -65%, paso 3: -72%) / ❌ codigo | QA | 2026-04-06 |
| OPT-010 | PR_PKG_REPRESTAMOS     | CREDITOS_PROCESAR (x3)     | N ctx sw   | ANTI JOIN    | Job1 pasos 2/3/5                | Codigo + Indice | ✅ indice / ❌ codigo                | QA      | 2026-03-19 |
| OPT-011 | PR_PKG_REPRESTAMOS     | CUR_Anular_creditos_cancel | 10,656     | 9,748        | Job1 paso 1, JobAnular          | Indice     | ✅ (paso 1: 1.4→1.3s, paso rapido)       | QA      | 2026-04-07 |
| OPT-012 | PR_PKG_REPRESTAMOS     | UPDATE PROMOCION_PERSONA   | 8,332      | NO OPTIMIZABLE | Job1 paso 9                   | N/A        | N/A                                      | QA      | 2026-04-07 |
| OPT-013 | PA.PA_DE05_SIB         | CUR_DE05_SIB (Dirigida+Campana) | 120,122 | 11       | Job1 paso 7, Job3, Job4         | Indice     | ✅ (paso 7: 13.3→3.2s, -76%)             | QA      | 2026-04-07 |
| OPT-014 | PR_PKG_REPRESTAMOS     | Medicion real indices (002,009,011,013) | 24.2 min | 14.2 min (-41%) | Job1 (orquestador completo)   | Medicion  | ✅ prueba real                           | DESA    | 2026-04-13 |

---

## Resumen por Job1 = P_Carga_Precalifica_Cancelado (medido en OPT-014)

Orden real de ejecucion segun OPT-014 (190 represtamos en estado RE en DESA, 2026-04-13):

| Paso | Procedimiento | OPTs | Tiempo ANTES | Tiempo DESPUES | Δ |
|------|---------------|------|--------------|----------------|---|
| 1 | P_Actualizar_Anular_Represtamo | OPT-011 | 1.4 s | 1.3 s | = |
| 2 | Precalifica_Represtamo | OPT-009, OPT-010 | 278.7 s | 98.0 s | **-65%** |
| 3 | Precalifica_Represtamo_fiadores | OPT-010, OPT-002 (indirecto) | 190.8 s | 53.8 s | **-72%** |
| 4 | Precalifica_Represtamo_fiadores_hi | OPT-002 | 177.9 s | 36.9 s | **-79%** |
| 5 | Precalifica_Repre_Cancelado | OPT-010, OPT-009 (indirecto) | 391.7 s | 231.5 s | **-41%** |
| 6 | Precalifica_Repre_Cancelado_hi | ⚠️ ninguna efectiva — requiere rewrite | 381.6 s | 392.5 s | +3% |
| 7 | Actualiza_Precalificacion | OPT-002, OPT-003, OPT-004, OPT-013 | 13.3 s | 3.2 s | **-76%** |
| 8 | Actualiza_XCORE_CUSTOM | OPT-005 | 0 | 12.5 s | n/a |
| 9 | P_REGISTRO_SOLICITUD | OPT-006, OPT-012 | 18.6 s | 23.9 s | +28% |
| 10 | PVALIDA_WORLD_COMPLIANCE | OPT-001 | 0.1 s | 0.8 s | n/a |
| 11 | PVALIDA_XCORE | OPT-007 | 0 | 0 | = |
| 12 | Loop Bitacora+Validaciones | OPT-008 | 0 | 0 | = |
| | **TOTAL** | | **1,454 s (24.2 min)** | **854 s (14.2 min)** | **-41%** |

**Nota clave**: OPT-014 midio solo el impacto de los 4 indices (OPT-002, OPT-009, OPT-011, OPT-013).
Los cambios de codigo (OPT-003, OPT-004, OPT-005, OPT-006, OPT-007, OPT-008, OPT-010) NO se aplicaron en DESARROLLO para esa prueba — su impacto real aun no esta validado en tiempo real.

**Proximo paso**: replicar OPT-004 + OPT-010 en `Precalifica_Repre_Cancelado` y `Precalifica_Repre_Cancelado_hi` (pasos 5-6, 53% del tiempo total). Ver `SESION_PENDIENTE.md`.
