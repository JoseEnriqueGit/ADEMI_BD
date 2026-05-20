# Historia #442 (IRD-442) - Identificar cuando el cliente marque un seguro voluntario

## Descripcion
Como negocios requiero que se pueda visualizar dentro de la tabla solicitudes el tipo de seguro opcional contratado por el cliente, esto para tener control del aporte en este producto por parte de los clientes de Represtamo Digital.

### Criterios de aceptacion
- Que se pueda visualizar una columna con cada tipo de seguro contratado por el cliente
- Que identifique con SI/NO el que haya contratado INCAPACIDAD/MIPYME
- Que se pueda descargar esa data en excel que descargamos desde el modulo de solicitudes

### Columnas agregadas al query
- **SEGURO_MIPYME**: Si/No basado en `PR_OPCIONES_REPRESTAMO.MTO_SEGURO_MIPYME > 0`
- **SEGURO_INCAPACIDAD**: Si/No basado en `PR_OPCIONES_REPRESTAMO.MTO_SEGURO_DESEMPLEO > 0`

### Optimizacion adicional del query
Aprovechando el cambio funcional, se optimizo el query completo de la region.

## Estado
- **Funcionalidad (seguros)**: Probado en QA
- **Optimizacion query**: Probado en QA - LISTO PARA PROD
- **Indices nuevos**: PENDIENTE para PROD (creados en QA)

## Pase a PROD - Alcance
**SOLO incluye el cambio del query SQL en la region "Solicitudes" de la pagina 21.**
- Script aplicar: `01_query_optimizado_p21_solicitudes.sql` (version v1, segura sin indices)
- Configurar Optimizer Hint: `USE_CONCAT`
- Configurar Page Items to Submit: `P21_ID_REPRESTAMO,P21_ESTADO`

## Pendiente para pase posterior
1. **Crear los 3 indices** en PROD (script `02_crear_indices_PENDIENTE.sql`):
   - `IDX_BITACORA_REPRST_EST` en PR_BITACORA_REPRESTAMO(ID_REPRESTAMO, CODIGO_ESTADO, FECHA_BITACORA)
   - `IDX_SOL_REPRST_EMP_EST` en PR_SOLICITUD_REPRESTAMO(CODIGO_EMPRESA, ESTADO, ID_REPRESTAMO)
   - `IDX_OPC_REPRST_ID_PLAZO` en PR_OPCIONES_REPRESTAMO(ID_REPRESTAMO, PLAZO)

2. **Actualizar el query a la v3** (`03_query_v3_post_indices.sql`) **DESPUES** de crear los indices, para aprovechar el rendimiento maximo (-16% costo adicional).
   - Cambiar Optimizer Hint a: `USE_CONCAT USE_NL(R)`

## Antes y Despues - Comparacion completa

### Problemas del query original
1. **Subquery correlacionado FECHA_BITACORA**: se ejecutaba N veces sin indice adecuado
2. **Dos EXISTS correlacionados** para TIPOS_DESEMBOLSOS: dos scans por fila
3. **F_Obt_Empresa_Represtamo en WHERE**: se evaluaba por cada fila
4. **Full Table Scans** en PR_SOLICITUD_REPRESTAMO (1,392), PR_REPRESTAMOS (910), PR_OPCIONES_REPRESTAMO (177)
5. **Falta de indices** en columnas clave de filtro y JOIN
6. **Patron `OR :param IS NULL`** impide uso de indices

### Versiones evaluadas
| Version | Costo | Estado | Descripcion |
|---|---|---|---|
| Original | 5,566 | Reemplazado | Sin optimizar, multiples Full Table Scans |
| v1 (CTEs) | 5,507 | **Para PROD** | Subqueries -> CTEs con LEFT JOIN GROUP BY (sin indices nuevos) |
| v2 (+ indice OPC) | 5,609 | Descartado | Variacion intermedia |
| v3 (EXISTS + indices) | **4,688** | **En QA / Para PROD post-indices** | EXISTS correlacionados aprovechando indices |

### Cambios SQL aplicados (ambas versiones)
- **CTE `v_empresa`**: F_Obt_Empresa_Represtamo se ejecuta 1 sola vez (en lugar de por fila)
- **WHERE reordenado**: `(:param IS NULL OR columna = :param)` en lugar de `(columna = :param OR :param IS NULL)` para short-circuit
- **Hint `USE_CONCAT`**: habilita OR-expansion del optimizador para parametros opcionales

### Diferencias v1 (PROD) vs v3 (post-indices)
| Aspecto | v1 (PROD) | v3 (post-indices) |
|---|---|---|
| FECHA_BITACORA | LEFT JOIN con GROUP BY (un solo scan de bitacora) | Subquery correlacionado (usa indice IDX_BITACORA_REPRST_EST) |
| TIPOS_DESEMBOLSOS | LEFT JOIN con MAX(CASE) (un solo scan de bitacora) | 2 EXISTS correlacionados (usan indice IDX_BITACORA_REPRST_EST) |
| Hint | `USE_CONCAT` | `USE_CONCAT USE_NL(R)` |
| JOIN PR_REPRESTAMOS | Igual al original | CODIGO_EMPRESA primero para PK |
| Requiere indices nuevos | NO | SI |

### Resultados Explain Plan: ORIGINAL vs v3 (con indices)
| Tabla | ANTES (costo) | DESPUES v3 (costo) | Mejora |
|---|---|---|---|
| PR_SOLICITUD_REPRESTAMO | Full Table Scan (1,392) | INDEX RANGE SCAN IDX_SOL_REPRST_EMP_EST (345) | -75% |
| PR_REPRESTAMOS | Full Table Scan (910) | INDEX UNIQUE SCAN PK_REPRESTAMOS (1) | -99% |
| PR_OPCIONES_REPRESTAMO | Full Table Scan (177) | INDEX RANGE SCAN IDX_OPC_REPRST_ID_PLAZO (1) | -99% |
| BITACORA (fecha) | Subquery sin indice | INDEX RANGE SCAN IDX_BITACORA_REPRST_EST (3) | Usa indice |
| BITACORA (desembolsos) | EXISTS sin indice | INDEX RANGE SCAN IDX_BITACORA_REPRST_EST (3) | Usa indice |
| **Costo total** | **5,566** | **4,688** | **-16%** |

## Configuracion APEX

### Para el pase actual a PROD (v1)
- **Optimizer Hint**: `USE_CONCAT`
- **Page Items to Submit**: `P21_ID_REPRESTAMO,P21_ESTADO`

### Para el pase posterior con indices (v3)
- **Optimizer Hint**: `USE_CONCAT USE_NL(R)`
- **Page Items to Submit**: `P21_ID_REPRESTAMO,P21_ESTADO`

## Archivos
- `scripts/01_query_optimizado_p21_solicitudes.sql` - **Query v1 (PROD - sin indices)**
- `scripts/02_crear_indices_PENDIENTE.sql` - Indices PENDIENTES para PROD
- `scripts/03_query_v3_post_indices.sql` - Query v3 para aplicar DESPUES de los indices

## Orden de implementacion
### Pase actual (PROD)
1. Reemplazar el query en APEX Page 21 region "Solicitudes" con `01_query_optimizado_p21_solicitudes.sql`
2. Configurar Optimizer Hint: `USE_CONCAT`
3. Verificar Page Items to Submit: `P21_ID_REPRESTAMO,P21_ESTADO`
4. Validar que los resultados sean identicos al query original

### Pase posterior (cuando se aprueben los indices)
1. Ejecutar `02_crear_indices_PENDIENTE.sql` en PROD
2. Reemplazar el query en APEX Page 21 con `03_query_v3_post_indices.sql`
3. Cambiar Optimizer Hint a: `USE_CONCAT USE_NL(R)`
4. Validar mejora de rendimiento
