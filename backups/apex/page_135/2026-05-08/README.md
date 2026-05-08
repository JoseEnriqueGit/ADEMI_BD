# Backup pagina 135 - 2026-05-08

Cambios incluidos en este release:

1. Vigencia de certificados evaluada **solo por `ESTADO`** (sin la condicion `FEC_VENCIMIENTO < SYSDATE`).
2. Card **"Total Certificados Abiertos"** ahora es clickeable y filtra la tabla mostrando todos los certificados del universo base.
3. **Cards de monto reactivas al filtro por card**: las cards `Monto en Pesos`, `Monto en Dólares`, `Monto Cancelados (Pesos)` y `Monto Cancelados (Dólares)` recalculan sus sumas cuando se hace click en `Certificados Vigentes`, `Certificados Vencidos`, `Clientes Externos` o `Empleados`.
4. **Columna `NOMBRE_PRODUCTO` agregada** en el reporte/tabla, equivalente al campo que tiene la pagina 134. JOIN a `PA.PRODUCTOS` por `COD_PRODUCTO` y `COD_EMPRESA`. Se aplica `REGEXP_REPLACE` para remover el prefijo redundante `"Certificados financieros Digital "` del valor mostrado, y dejar solo la parte distintiva (ejemplo: `Capitalizable Pesos` en vez de `Certificados financieros Digital Capitalizable Pesos`).

## Motivo

### 1. Vigencia solo por ESTADO

Antes del cambio, las cards `Certificados Vigentes`, `Monto en Pesos` y `Monto en Dólares` requerian que `ESTADO IN ('A','R')` **y** `FEC_VENCIMIENTO >= SYSDATE`. Esto provocaba que certificados con `ESTADO = 'A'` (que la tabla mostraba como `VIGENTE`) pero con fecha de vencimiento ya pasada se contabilizaran como vencidos en las cards y, por tanto, los montos vigentes aparecieran en `RD$ 0.00` / `US$ 0.00`. Negocio decidio que la vigencia se rige por el campo `ESTADO`, no por la fecha de vencimiento.

### 2. Card "Total Certificados Abiertos" clickeable

Antes del cambio, el Bloque 1 tenia `VALOR_FILTRO = NULL`, lo que hacia que la columna `CSS_CURSOR` la marcara como `default` y la card no respondiera al click. Negocio requirio que al hacer click se mostrara el universo completo de certificados en la tabla (equivalente a "Limpiar Filtros" pero conservando el filtro implicito por click). Se ajusto a `VALOR_FILTRO = 'TOTAL'` y se agrego una rama en la tabla para `:P135_FILTRO_CARD = 'Total Certificados Abiertos'` que no aplica restriccion adicional.

### 3. Cards de monto reactivas al filtro por card

Antes, las cards de monto siempre sumaban sobre todo el universo (`CertificadosBase`). Negocio requirio que la suma reflejara el subconjunto seleccionado al hacer click en una card de conteo (Vigentes, Vencidos, Externos, Empleados). Se introdujo la CTE `CertificadosFiltrados` que aplica el filtro de `:P135_FILTRO_CARD` y las cards de monto pasan a leer de esa CTE. Las cards de conteo siguen leyendo de `CertificadosBase` para que sus numeros representen siempre el universo total.

### 4. Columna `NOMBRE_PRODUCTO` en el reporte/tabla

Negocio requiere ver el nombre legible del producto en la tabla de la pagina 135, igual que la pagina 134. Se agrego la columna `NOMBRE_PRODUCTO` al SELECT del reporte, posicionada despues de `Número Certificado`, y un `LEFT JOIN PA.PRODUCTOS` por `COD_PRODUCTO` y `COD_EMPRESA`. Si el producto no existe en `PA.PRODUCTOS`, se muestra `'PRODUCTO ' || cd.COD_PRODUCTO` como fallback.

Refinamiento posterior: como todas las descripciones en `PA.PRODUCTOS` para los productos digitales empiezan con el prefijo `"Certificados financieros Digital "`, ese prefijo ocupa la mitad del ancho de la columna y dificulta diferenciar productos en el filtro del reporte (queda truncado igual para todas las opciones). Se envuelve la descripcion en `REGEXP_REPLACE` con anclaje `^` y flag `'i'` (case-insensitive) para remover ese prefijo solo cuando aparece al inicio. Si en el futuro algun producto no respeta esa convencion, `REGEXP_REPLACE` lo deja intacto y no rompe nada.

Las cards no requieren este cambio.

Detalle: ver `historias/PAGINA_135_AGREGAR_NOMBRE_PRODUCTO/README.md`.

## Archivos

- `pagina_135_cards_antes_solo_estado.sql` - Snapshot previo (igual al final de 2026-05-01).
- `pagina_135_cards_final_solo_estado.sql` - Version final de las cards.
- `pagina_135_reporte_tabla_antes_solo_estado.sql` - Snapshot previo (igual al final de 2026-05-01).
- `pagina_135_reporte_tabla_final_solo_estado.sql` - Version final del reporte/tabla.

## Region afectada

- Cards de certificados (region principal).
- Reporte/tabla de certificados (filtros por `:P135_FILTRO_CARD`).

## Bloques modificados en cards

| Bloque | Card                          | Cambio                                                                                              |
|--------|-------------------------------|-----------------------------------------------------------------------------------------------------|
| 1      | Total Certificados Abiertos   | `VALOR_FILTRO` pasa de `NULL` a `'TOTAL'` -> activa el cursor pointer.                              |
| 2      | Certificados Vigentes         | Se elimina `FEC_VENCIMIENTO >= SYSDATE OR FEC_VENCIMIENTO IS NULL`.                                 |
| 3      | Certificados Vencidos         | Se elimina la rama `OR (ESTADO A/R AND FEC_VENCIMIENTO < SYSDATE)`.                                 |
| 4      | Monto en Pesos                | Se elimina la condicion de fecha; queda `ESTADO IN ('A','R')`. Pasa a leer de `CertificadosFiltrados`. |
| 5      | Monto en Dólares              | Idem bloque 4. Pasa a leer de `CertificadosFiltrados`.                                              |
| 8      | Monto Cancelados (Pesos)      | Se elimina la rama por fecha; queda `ESTADO IN ('C','P','N','I')`. Pasa a leer de `CertificadosFiltrados`. |
| 9      | Monto Cancelados (Dólares)    | Idem bloque 8. Pasa a leer de `CertificadosFiltrados`.                                              |

## Comportamiento esperado al hacer click en una card

| Click en                         | `CertificadosFiltrados` aplica            | Efecto sobre cards de monto                                                  |
|----------------------------------|-------------------------------------------|------------------------------------------------------------------------------|
| Total Certificados Abiertos      | Sin restriccion adicional                 | Igual que sin filtro (universo completo).                                    |
| Certificados Vigentes            | `ESTADO IN ('A','R')`                     | Monto Pesos / Dolares igual; Cancelados muestran 0 (interseccion vacia).     |
| Certificados Vencidos            | `ESTADO IN ('C','P','N','I')`             | Cancelados Pesos / Dolares igual; Vigentes muestran 0 (interseccion vacia).  |
| Clientes Externos                | `TIPO_CLIENTE = 'Externo'`                | Las 4 cards de monto suman solo externos.                                    |
| Empleados                        | `TIPO_CLIENTE = 'Empleado'`               | Las 4 cards de monto suman solo empleados.                                   |
| Monto en Pesos / Dolares / Canc. | Sin restriccion adicional                 | Las cards de monto no se afectan entre si; solo filtran la tabla.            |

## Bloques modificados en tabla

- Las ramas de `:P135_FILTRO_CARD` para `'Certificados Vigentes'`, `'Certificados Vencidos'`, `'Monto en Pesos'` y `'Monto en Dólares'` quedan regidas solo por `ESTADO` para mantener coherencia con las cards.
- Se agrega la rama `:P135_FILTRO_CARD = 'Total Certificados Abiertos'` sin restriccion adicional, para soportar el click en la card del Bloque 1.

## Nota APEX

El click en la card debe estar conectado a una Dynamic Action que asigne el valor de `CARD_TITLE` (`'Total Certificados Abiertos'`) a `:P135_FILTRO_CARD` y refresque la region de la tabla. Si la DA actual depende de un mapeo hardcoded por titulo, hay que agregar la nueva entrada para que el click funcione end-to-end.

## Historia relacionada

`historias/PAGINA_135_CARDS_VIGENCIA_POR_ESTADO/README.md`
