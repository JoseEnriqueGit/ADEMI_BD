# Sesion Pendiente — Continuacion de mediciones OPT

> Documento de contexto para continuar el trabajo de optimizacion en otra PC/sesion.
> Fecha: 2026-04-07
> Sesion anterior: Claude Code Desktop

---

## Resumen de lo completado

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

### 1. SQL 371 — Hardcodeo de estados (cost 9,748 → 26)
- **Estado**: Propuesta documentada, pendiente aprobacion del jefe
- **Archivo**: `historias/optimizaciones/propuestas/SQL371_HARDCODEO_ESTADOS.md`
- **Accion**: Preguntar al jefe si aprueba el trade-off (hardcodeo vs parametros dinamicos)
- **Si se aprueba**: Aplicar el cambio al cursor CUR_Anular_creditos_cancelados en body.sql, documentar como OPT-014

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
| `historias/optimizaciones/propuestas/SQL371_HARDCODEO_ESTADOS.md` | Propuesta SQL 371 |
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

1. Leer este documento (`SESION_PENDIENTE.md`) al inicio
2. Trabajar los 4 items pendientes en orden de prioridad
3. Para cada item que se complete, documentar en su carpeta OPT correspondiente
4. Al finalizar, actualizar este documento con los resultados o crear uno nuevo para la sesion siguiente
5. Si se obtienen resultados de Explain Plan, guardar screenshots o anotar los costs aqui
