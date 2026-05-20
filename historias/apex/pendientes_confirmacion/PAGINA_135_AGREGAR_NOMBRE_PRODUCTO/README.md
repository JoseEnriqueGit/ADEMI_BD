# Pagina 135 APEX - Agregar columna `NOMBRE_PRODUCTO` al reporte

## Contexto

- **Ticket**: Pendiente de asignar
- **Pantalla / vista APEX**: Pagina 135 (Panel de Certificado Digital)
- **Region APEX**: Reporte/tabla de certificados
- **Modulo funcional**: Certificados digitales
- **Tabla base principal**: `CD.CD_CERTIFICADO`
- **Tabla referencial agregada**: `PA.PRODUCTOS`
- **Fecha del cambio**: 2026-05-08

## Historia

Yo como negocio requiero que la tabla de la pagina 135 muestre el nombre del producto al lado del `Número Certificado`, equivalente a la columna `NOMBRE_PRODUCTO` que ya existe en la pagina 134, con el objetivo de que las dos vistas tengan informacion comparable y que el detalle del certificado sea legible sin tener que recordar la equivalencia entre `COD_PRODUCTO` y su descripcion.

## Criterios de aceptacion

1. **Columna `NOMBRE_PRODUCTO`** agregada al reporte/tabla, posicionada inmediatamente despues de `Número Certificado` y antes de `MODALIDAD_PAGO`.
2. **Fuente del nombre**: `PA.PRODUCTOS.DESCRIPCION` joinada por `COD_PRODUCTO` y `COD_EMPRESA` desde `CD.CD_CERTIFICADO`.
3. **Prefijo redundante removido**: como todas las descripciones de productos digitales empiezan con `"Certificados financieros Digital "`, se aplica `REGEXP_REPLACE` para mostrar solo la parte distintiva (ejemplo: `Capitalizable Pesos`, `Pagadero Dólares (P.Fisica)`).
4. **Fallback**: si el producto no existe en `PA.PRODUCTOS` o el JOIN no retorna fila, mostrar `'PRODUCTO ' || cd.COD_PRODUCTO` para que la celda nunca aparezca en blanco.
5. **No alterar** filtros, otras columnas, ni cards. Solo agrega un campo y un JOIN al reporte.
6. **Cardinalidad preservada**: el JOIN es `LEFT JOIN`, por lo que ningun certificado debe perderse aunque su producto no exista en `PA.PRODUCTOS`.

## Cambio funcional realizado

### Region: reporte/tabla

Dos cambios puntuales en el SQL:

#### 1. Columna agregada en el SELECT

```sql
NVL(
    REGEXP_REPLACE(prod.DESCRIPCION, '^Certificados financieros Digital\s*', '', 1, 1, 'i'),
    'PRODUCTO ' || cd.COD_PRODUCTO
) AS NOMBRE_PRODUCTO,
```

Posicion: justo despues de `cd.NUM_CERTIFICADO AS "Número Certificado"`.

**Nota sobre el `REGEXP_REPLACE`**: las descripciones de los productos digitales en `PA.PRODUCTOS` siguen el patron `"Certificados financieros Digital <variante>"` (ejemplo: `Certificados financieros Digital Capitalizable Pesos`). Como ese prefijo aparece en TODAS las filas, ocupa ancho de columna sin diferenciar nada y trunca el filtro del reporte para todas las opciones por igual. El regex tiene:

- `^` -> ancla al inicio: solo strip si aparece como prefijo, no en medio.
- `\s*` -> consume el espacio que sigue al prefijo.
- Flags `1, 1, 'i'` -> primera ocurrencia, primera coincidencia, case-insensitive (por si en algun momento el catalogo tiene variantes de mayusculas/minusculas).
- Si la descripcion **no** empieza con el prefijo, `REGEXP_REPLACE` la deja intacta. No rompe nada.

#### 2. JOIN agregado al FROM

```sql
LEFT JOIN PA.PRODUCTOS prod
    ON cd.COD_PRODUCTO = prod.COD_PRODUCTO
   AND cd.COD_EMPRESA = prod.COD_EMPRESA
```

Posicion: despues de `LEFT JOIN PA.AREAS_MERCADO zn`.

### Region: cards

No requiere cambios. El nombre del producto no participa en cards de conteo ni de monto.

## Alcance tecnico

- Cambio aplicado solo en la consulta SQL de la region del reporte. No se modifican packages, tablas, indices ni objetos Oracle.
- Se asume que `PA.PRODUCTOS` ya tiene entradas para todos los productos digitales (310, 311, 313, 314, 315, 316, 317, 318). El fallback `'PRODUCTO ' || COD_PRODUCTO` cubre cualquier producto que falte.

## Evidencia en repositorio

### Version final

- `backups/apex/page_135/2026-05-08/pagina_135_reporte_tabla_final_solo_estado.sql` (incluye este cambio mas los cambios previos del release 2026-05-08).

### Respaldo previo

- `backups/apex/page_135/2026-05-08/pagina_135_reporte_tabla_antes_solo_estado.sql` (estado antes de agregar la columna).

### Script de validacion

- `scripts/01_validar_nombre_producto.sql`

## Validacion sugerida en APEX / Toad

1. Ejecutar `scripts/01_validar_nombre_producto.sql` y confirmar que cada `COD_PRODUCTO` digital (310, 311, 313-318) tiene `DESCRIPCION` no nula en `PA.PRODUCTOS`. Si alguno aparece sin descripcion, coordinar con el dueno de `PA.PRODUCTOS` para completar el catalogo o aceptar el fallback.
2. En APEX, abrir la pagina 135 y verificar que la nueva columna `NOMBRE_PRODUCTO` aparece despues de `Número Certificado` y muestra el nombre legible.
3. Comparar conteo de filas antes y despues del cambio (con los mismos filtros) para asegurar que el JOIN no recorta certificados.
4. Probar con un certificado cuyo `COD_PRODUCTO` no este en `PA.PRODUCTOS` (si existe alguno) y verificar que la celda muestra `'PRODUCTO <codigo>'` en lugar de quedar vacia.

## Riesgos y observaciones

- Si negocio modifica `PA.PRODUCTOS` y cambia la `DESCRIPCION` de un producto digital, la tabla reflejara el nuevo nombre automaticamente (no hay duplicacion de catalogo).
- Si en el futuro se agrega un producto digital nuevo (por ejemplo `319`), el filtro `COD_PRODUCTO IN (310, 311, 313-318)` debe actualizarse en ambas regiones (cards y tabla) y `PA.PRODUCTOS` debe tener la entrada correspondiente.
- El cambio no afecta las cards ni el comportamiento del filtro por card.

## Estado

Implementado en el SQL del backup. Pendiente aplicar en APEX y validar con el script de validacion.
