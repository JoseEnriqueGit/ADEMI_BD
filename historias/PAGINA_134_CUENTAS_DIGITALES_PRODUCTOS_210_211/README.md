# Pagina 134 APEX - Cuentas digitales productos 210 y 211

## Contexto

- **Ticket**: Pendiente de asignar
- **Pantalla / vista APEX**: Pagina 134
- **Region APEX**: Cards de cuentas digitales y reporte/tabla de cuentas digitales
- **Modulo funcional**: Canal Digital / Cuentas digitales
- **Tabla base principal**: `CC.CUENTA_EFECTIVO`
- **Fecha del cambio**: 2026-05-01

## Historia

Yo como negocio requiero que la vista de cuentas digitales incluya los productos digitales 210 y 211, con el objetivo de asegurar que la pantalla muestre el universo correcto de cuentas digitales y que los indicadores, saldos y registros del reporte representen solamente los productos esperados por negocio.

## Criterios de aceptacion

1. **Filtrar cuentas digitales**
   Debe considerar solamente cuentas cuyo `COD_PRODUCTO` este dentro de la lista `210, 211`.

2. **Aplicar el mismo universo de datos en cards y tabla**
   Las cards informativas y el reporte/tabla deben usar el mismo filtro de productos digitales para que conteos, saldos y detalle sean consistentes.

3. **Mantener filtros existentes**
   La inclusion del producto `211` no debe afectar los filtros actuales por fecha de apertura, fecha de cancelacion, logica de fecha `AND`/`OR` ni filtros aplicados desde las cards.

4. **Evitar errores de logica en el filtro de productos**
   El filtro de productos debe implementarse de forma que ambos productos, `210` y `211`, respeten las mismas condiciones de fecha y filtros de la pantalla.

## Cambio funcional realizado

Se agrego el producto `211` al universo de cuentas digitales de la pagina 134.

Implementacion aplicada:

```sql
ce.COD_PRODUCTO IN ('210', '211')
```

Este criterio reemplaza el filtro previo:

```sql
ce.COD_PRODUCTO = '210'
```

El uso de `IN` evita que un `OR` sin parentesis deje el producto `210` fuera de los filtros de fecha o de las cards por precedencia logica de Oracle.

## Alcance tecnico

### Region: reporte/tabla de cuentas digitales

El filtro de productos se aplica al inicio del `WHERE`, antes de la logica de fecha y antes de `:P134_FILTRO_CARD`.

Se mantienen las reglas existentes de:

- Datos de cliente e identificacion.
- Estado de cuenta.
- Producto, oficina y zona.
- Tipo de cliente empleado o externo.
- Condicion laboral.
- Tipo de vinculacion.
- Filtros por fecha de apertura y fecha de cancelacion.
- Filtros accionados desde las cards.

### Region: cards de cuentas digitales

El filtro de productos se aplica dentro de la CTE `CuentasBase`, por lo que todos los indicadores derivados quedan limitados al mismo universo de datos.

Indicadores impactados:

- Total cuentas activas.
- Total cuentas activas empleados.
- Total cuentas activas cliente.
- Saldo Ctas. Empleados.
- Saldo Ctas. Clientes.
- Total Cuentas Canceladas.

## Evidencia en repositorio

### Respaldo previo

- `backups/apex/page_134/2026-05-01/pagina_134_reporte_tabla_antes_producto_211.sql`
- `backups/apex/page_134/2026-05-01/pagina_134_cards_antes_producto_211.sql`

### Version final

- `backups/apex/page_134/2026-05-01/pagina_134_reporte_tabla_final_productos_210_211.sql`
- `backups/apex/page_134/2026-05-01/pagina_134_cards_final_productos_210_211.sql`

### Revision para release

- `REVISION_RELEASE.md`

### Script auxiliar

- `scripts/01_validar_productos_cuentas_digitales.sql`

## Validacion sugerida en APEX / Toad

1. Ejecutar la consulta final del reporte/tabla y confirmar que solo retorna productos `210` y `211`.
2. Ejecutar la consulta final de cards y validar que todos los calculos nacen de `CuentasBase` con `ce.COD_PRODUCTO IN ('210', '211')`.
3. Comparar el total de la card "Total cuentas activas" contra el conteo del reporte sin filtro de card seleccionado y con cuentas activas.
4. Probar `:P134_LOGICA_FECHA = 'AND'` y `:P134_LOGICA_FECHA = 'OR'`.
5. Probar cada card clickeable y confirmar que el detalle mantiene el filtro de productos digitales.
6. Guardar evidencia visual de la pagina 134 con los filtros aplicados.

## Riesgos y observaciones

- Si negocio modifica la lista de productos digitales de cuentas, debe actualizarse el filtro en ambas regiones.
- La validacion final de datos debe hacerse en el entorno APEX donde se aplico el cambio, porque el repo conserva scripts de referencia pero no confirma la data en base de datos.
- El cambio no altera tablas, packages ni contratos de objetos Oracle; se limita a las consultas SQL de la pagina APEX.

## Estado

Implementado en APEX segun scripts finales preparados para la pagina 134 y respaldado en el repositorio.
