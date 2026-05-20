# Historia #530 (IRD-530) - Card Informativa Backoffice de Représtamo Digital

## Descripcion

Yo, como **Negocio**, requiero que en el dashboard ya existente en el BackOffice de Représtamo Digital se ajusten las cards informativas **para** reflejar correctamente los estados del flujo y facilitar el análisis de resultados de las solicitudes.

### Criterios de Aceptación

- **Card "Total Preaprobados":** Actualizar la lista de estados para incluir todos los estados del flujo (`AP, AYR, BLI, BLP, CP, CRN, RZ, MS, EP, LA, NR, NP, CRA, CRD, CRV, CRS, SC`)
- **Card "Canal Pendiente"** → renombrar a **"Disponible"** y ampliar el filtro de solo `CP` a `CP, MS, NR`

## Cambios funcionales

### 1. Card "Total Preaprobados" - Lista de estados ampliada

Se actualizó la lista de estados para incluir todos los estados del flujo del représtamo.

**ANTES (8 estados):**
```
'RE', 'VR', 'NP', 'CP', 'LA', 'EP', 'A', 'SC'
```

**DESPUES (17 estados):**
```
'AP','AYR','BLI','BLP','CP','CRN','RZ','MS','EP','LA','NR','NP','CRA','CRD','CRV','CRS','SC'
```

- **Removidos:** `RE`, `VR`, `A`
- **Agregados:** `AP`, `AYR`, `BLI`, `BLP`, `CRN`, `RZ`, `MS`, `NR`, `CRA`, `CRD`, `CRV`, `CRS`
- El `card_link` JavaScript también se actualizó con la misma lista para mantener coherencia entre el conteo y el filtro al hacer click.

### 2. Card "Canal Pendiente" -> Renombrada a "Disponible"

**ANTES:**
- Título: `'CANAL PENDIENTE (ACTUALIZAR TELEFONO)'`
- Filtro: solo estado `'CP'`

**DESPUES:**
- Título: `'Disponible'`
- Filtro: tres estados `'CP', 'MS', 'NR'`
- `card_link` actualizado para filtrar por `'CP,MS,NR'`

## Validacion realizada

### Validacion visual (Dashboard QA - Zona Metropolitana Este, 01/04/2025 - 09/04/2026)

| # | Id Représtamo | Monto Preaprobado | Estado |
|---|---------------|-------------------|--------|
| 1 | 2603881386 | 10,000 | PRESTAMO SOLICITADO |
| 2 | 2503303053 | 50,000 | PRESTAMO SOLICITADO |

- **Conteo card:** 2 -> Coincide con la tabla
- **Monto card:** RD$ 60,000.00 (10,000 + 50,000) -> Coincide

### Validacion en BD

Se ejecutaron los queries en `validacion/` para confirmar que:
1. Los IDs de représtamos mostrados en la tabla efectivamente existen en `pr.pr_represtamos`
2. El estado actual de cada représtamo está incluido en la nueva lista de la card "Total Preaprobados"
3. El historial de la bitácora (`pr.pr_bitacora_represtamo`) muestra el recorrido de estados por los que pasó cada représtamo

**Resultado:** Validacion exitosa. Los conteos y montos de las cards coinciden con la data en las tablas.

## Archivos

- `scripts/before.sql` - Query original del dashboard (antes del cambio)
- `scripts/after.sql` - Query nuevo del dashboard (después del cambio)
- `validacion/01_validar_estado_actual.sql` - Valida estado actual de représtamos específicos en `pr_represtamos`
- `validacion/02_validar_historial_bitacora.sql` - Muestra historial de estados de un représtamo en la bitácora

## Estado

Implementado y validado en QA

## Notas

- La columna `USUARIO_ADICION` no existe en `pr.pr_bitacora_represtamo`. Las columnas disponibles son: `id_represtamo`, `id_bitacora`, `codigo_estado`, `fecha_bitacora`, `fecha_adicion`.
