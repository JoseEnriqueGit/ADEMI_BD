# Plantilla — Inventario semántico de promoción

> **Para qué sirve.** Es el antídoto al fallo cognitivo *"todo cambió, es esperado porque optimizamos"*.
> Cuando un objeto se reescribe entero (CTE vs comma-joins, etc.) el diff línea-a-línea es inútil:
> el ojo no detecta que **desapareció una rama de negocio completa**. Aquí NO comparas texto:
> listas explícitamente cada pieza de lógica del baseline y marcas si sigue viva.
>
> **Regla dura:** no se firma si algún ítem quedó en `ELIMINADO` **sin** justificación escrita.

## Cómo llenarlo
1. Toma el **baseline** (lo VIVO en el entorno destino — ver `RUNBOOK_PROMOCION_PROD.md`).
2. Toma la versión **propuesta** (la que vas a desplegar).
3. (Opcional) Corre `tools/guardrail/inventario_semantico.ps1 -Origen <baseline> -Destino <propuesta>`
   para **pre-rellenar** candidatos (literales, funciones, columnas). El script es **asesor, no decide**.
4. Para cada ítem marca el estado. Cualquier `ELIMINADO` exige una razón de negocio.

---

## Objeto: `SCHEMA.OBJETO`
- **Baseline (vivo en):** `<entorno>` — archivo: `ENTORNOS_ORACLE/<ENTORNO>/.../OBJETO.sql` (commit: `____`)
- **Propuesto:** `historias/<HISTORIA>/promocion/02_propuesto_OBJETO.sql`
- **Historias que han tocado este objeto** (correr `git log -- <archivo>` y listarlas TODAS): `____`

### Ramas / valores de negocio (literales, CASE, banderas)
| Ítem | Estado | Justificación (obligatoria si ELIMINADO) |
|---|---|---|
| `'EJEMPLO_RAMA'` | conservado / **eliminado** / agregado | |

### Llamadas a funciones / packages
| Función | Estado | Justificación si ELIMINADO |
|---|---|---|
| `pkg.funcion(...)` | conservado / eliminado / agregado | |

### Columnas de salida y de filtro clave
| Columna | Estado | Justificación si ELIMINADO |
|---|---|---|
| `columna` | conservado / eliminado / agregado | |

### Resultado
- [ ] **0 ítems en ELIMINADO sin justificación.**
- [ ] Confirmé contra `git log` que la propuesta incluye TODA la lógica de historias previas del objeto.
- Revisor / sign-off: `____` — fecha `____`
