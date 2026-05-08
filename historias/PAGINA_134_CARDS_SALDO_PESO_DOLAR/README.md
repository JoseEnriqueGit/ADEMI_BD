# Pagina 134 APEX - Cards de Saldo en Pesos y Dolares

## Contexto

- **Ticket**: Pendiente de asignar
- **Pantalla / vista APEX**: Pagina 134 (Panel de Cuentas Digitales)
- **Region APEX**: Cards de cuentas digitales
- **Modulo funcional**: Canal Digital / Cuentas digitales
- **Tabla base principal**: `CC.CUENTA_EFECTIVO`
- **Fecha del cambio**: 2026-05-07

## Historia

Yo como negocio requiero ver el saldo total de cuentas digitales separado por moneda (pesos dominicanos y dolares estadounidenses), con el objetivo de tener visibilidad financiera correcta del universo de cuentas digitales y evitar lecturas erroneas que mezclan DOP + USD en un solo monto.

## Mapeo de moneda confirmado por negocio

- Producto `210` -> cuentas en pesos dominicanos (DOP).
- Producto `211` -> cuentas en dolares estadounidenses (USD).

La tabla `CC.CUENTA_EFECTIVO` no tiene columna `COD_MONEDA`, por lo que la separacion se hace por `COD_PRODUCTO`.

## Criterios de aceptacion

1. **Card "Saldo Total en Pesos"**
   Suma `SAL_TOTAL_CTA` de cuentas activas (`FEC_CANCELAC IS NULL`) con `COD_PRODUCTO = '210'`. Formato `RD$ 9,999,999.99`.

2. **Card "Saldo Total en Dolares"**
   Suma `SAL_TOTAL_CTA` de cuentas activas (`FEC_CANCELAC IS NULL`) con `COD_PRODUCTO = '211'`. Formato `US$ 9,999,999.99`.

3. **Respeta filtros existentes**
   Las dos cards nuevas deben respetar los filtros de fecha de apertura, fecha de cancelacion y la logica `AND`/`OR` (`P134_LOGICA_FECHA`).

4. **Click en card filtra el reporte**
   Las cards nuevas son clickeables y aplican `P134_FILTRO_CARD = 'Saldo Total en Pesos'` o `'Saldo Total en Dolares'` para filtrar la tabla.

5. **No alteran cards existentes**
   Las cards `Saldo Ctas. Empleados`, `Saldo Ctas. Clientes` y todas las de conteo siguen igual.

## Cambio funcional realizado

Se agregan dos cards nuevas a la region de cards de la pagina 134, ordenadas entre `Saldo Ctas. Clientes` (orden 5) y `Total Cuentas Canceladas` (orden 8):

- Orden 6: `Saldo Total en Pesos`
- Orden 7: `Saldo Total en Dolares`

La card `Total Cuentas Canceladas` se reordena de orden 6 a orden 8.

### Diferencia clave con las cards existentes

Las cards `Saldo Ctas. Empleados` y `Saldo Ctas. Clientes` actuales suman saldos sin distinguir moneda (mezclan DOP + USD en un solo numero). Negocio decidio mantenerlas como estaban y agregar las dos cards nuevas separadas por moneda, que si son matematicamente correctas porque cada una agrega una sola moneda.

### Cambios SQL aplicados

1. La CTE `CuentasBase` agrega la columna `ce.COD_PRODUCTO` para que las nuevas cards puedan filtrar por moneda.
2. La CTE `CuentasFiltradas` agrega dos ramas a `:P134_FILTRO_CARD` para soportar los nuevos filtros click.
3. Se agregan dos `UNION ALL` con los `SELECT` de las nuevas cards.

## Alcance tecnico

### Region: cards de cuentas digitales

Cambio aplicado en la consulta SQL de la region. No se modifican packages, tablas ni objetos Oracle.

### Region: reporte/tabla de cuentas digitales

No requiere cambios para mostrar los totales por moneda. Si negocio quiere que el click en las cards nuevas filtre la tabla por moneda, hay que extender el bloque `:P134_FILTRO_CARD` del reporte (pendiente de confirmar con negocio).

## Evidencia en repositorio

### Respaldo previo

- `backups/apex/page_134/2026-05-07/pagina_134_cards_antes_saldo_peso_dolar.sql`

### Version final

- `backups/apex/page_134/2026-05-07/pagina_134_cards_final_saldo_peso_dolar.sql`

### Script de validacion

- `scripts/01_validar_saldos_peso_dolar.sql`

## Validacion sugerida en APEX / Toad

1. Ejecutar `scripts/01_validar_saldos_peso_dolar.sql` en el entorno destino y comparar el resultado contra las cards.
2. En APEX, validar que `Saldo Total en Pesos` cuadra con la suma de cuentas activas producto 210.
3. En APEX, validar que `Saldo Total en Dolares` cuadra con la suma de cuentas activas producto 211.
4. Probar con `:P134_LOGICA_FECHA = 'AND'` y `:P134_LOGICA_FECHA = 'OR'`.
5. Si negocio requiere click filtro en tabla: probar click en cards nuevas y confirmar que el reporte filtra por moneda.
6. Confirmar que las cards de conteo y las de saldo existentes siguen retornando los mismos numeros que antes del cambio.

## Riesgos y observaciones

- Si negocio cambia el mapeo de productos digitales (por ejemplo agrega un producto 212 en otra moneda), debe revisarse la condicion `COD_PRODUCTO IN ('210', '211')` y los filtros por moneda de las nuevas cards.
- Las cards existentes `Saldo Ctas. Empleados` y `Saldo Ctas. Clientes` quedan iguales a proposito por decision del negocio. Si en el futuro se decide separarlas por moneda, hay que duplicarlas (Empleados DOP, Empleados USD, Clientes DOP, Clientes USD).
- El cambio es solo SQL APEX. No altera tablas, packages ni objetos Oracle.

## Estado

Implementacion preparada y respaldada. Pendiente confirmar entorno APEX donde se aplicara y, opcionalmente, decidir si se extiende el reporte/tabla para soportar el filtro click de las cards nuevas.

## Fix posterior - 2026-05-08: refresh intermitente al cambiar `Logica Fecha`

### Sintoma

Al cambiar el radio `P134_LOGICA_FECHA` ("Cumplir ambos filtros" / "Cumplir uno de los dos filtros"), la tabla del reporte a veces refrescaba con los datos correctos y a veces se quedaba mostrando datos del valor anterior. Las cards si refrescaban consistentemente.

### Causa

La sub-region del Interactive Report (TABLA detalle) **no incluia `P134_LOGICA_FECHA` en su propiedad `Source > Page Items to Submit`**, aunque la region de cards si lo tenia. APEX no auto-completa `Page Items to Submit` con los bind variables que aparecen en el SQL: hay que listarlos explicitamente.

Como consecuencia, al refrescar el IR via Dynamic Action:

- El AJAX request enviaba todos los items declarados (fechas, filtro card) **menos** `P134_LOGICA_FECHA`.
- El SQL del IR se ejecutaba con el valor de `P134_LOGICA_FECHA` que hubiera en session state, no con el valor recien seleccionado.
- Solo cuando otra accion (ej. cambio de fecha) habia submiteado antes el item, casualmente coincidia y "parecia" que refrescaba bien -> sensacion de intermitencia.

### Fix aplicado en APEX

En la sub-region del IR (Interactive Report con la tabla detalle):

1. Page Designer -> click en la sub-region del IR.
2. Panel derecho -> seccion `Source` -> propiedad `Page Items to Submit`.
3. Agregar `P134_LOGICA_FECHA` a la lista, dejando todos los demas filtros que ya estaban.
4. Save.

Tras el cambio el refresh es consistente en todos los cambios de radio.

### Diagnostico realizado

Se confirmo el bug via DevTools del navegador (F12 -> Network -> filtro XHR), comparando el `p_json > pageItems > itemsToSubmit` de los dos requests AJAX que dispara el cambio de radio:

- Request del CARD region: incluia `P134_LOGICA_FECHA` con el valor nuevo. ✓
- Request del IR (`p_widget_name: worksheet`, `p_widget_mod: PULL`): **no incluia** `P134_LOGICA_FECHA`. ✗

El mismo bug fue detectado y corregido el mismo dia en la pagina 135 sobre `P135_LOGICA_FECHA` (referencia: `historias/PAGINA_135_CARDS_VIGENCIA_POR_ESTADO/`).

### Recordatorio para cambios futuros

Cada vez que se agregue un nuevo item de filtro a esta pagina (cualquier `:P134_*` referenciado en el SQL), hay que asegurarse de agregarlo en el `Page Items to Submit` de **todas** las regions data-driven que dependen de el (region de cards y sub-region del IR), no solo de una.
