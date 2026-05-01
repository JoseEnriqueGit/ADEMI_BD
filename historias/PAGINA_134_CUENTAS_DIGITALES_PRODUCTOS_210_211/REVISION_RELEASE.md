# Revision para release - Pagina 134 APEX

## Alcance revisado

- `backups/apex/page_134/2026-05-01/pagina_134_reporte_tabla_final_productos_210_211.sql`
- `backups/apex/page_134/2026-05-01/pagina_134_cards_final_productos_210_211.sql`
- `historias/PAGINA_134_CUENTAS_DIGITALES_PRODUCTOS_210_211/scripts/01_validar_productos_cuentas_digitales.sql`

## Resultado corto

El cambio principal del release, incluir el producto `211` junto al `210` en la pagina 134, esta aplicado de forma consistente en las dos regiones revisadas:

- Cards: `ce.COD_PRODUCTO IN ('210', '211')`.
- Reporte/tabla: `ce.COD_PRODUCTO IN ('210', '211')`.

Para release, el filtro de productos cumple los criterios de aceptacion documentados.

## Criterios de aceptacion

1. **Filtrar cuentas digitales**
   Cumple. El filtro esta en la consulta de cards y en la consulta del reporte/tabla.

2. **Aplicar el mismo universo de datos en cards y tabla**
   Cumple. Ambas regiones usan `ce.COD_PRODUCTO IN ('210', '211')`.

3. **Mantener filtros existentes**
   Cumple. La logica de fechas, filtros por cards y reglas de clasificacion existentes se conservaron.

4. **Evitar errores de logica en el filtro de productos**
   Cumple. Se uso `IN ('210', '211')` para evitar problemas de precedencia con `AND` y `OR`.

## Validaciones recomendadas

1. Ejecutar `scripts/01_validar_productos_cuentas_digitales.sql` para confirmar conteos y saldos por producto.
2. En APEX, comparar la card "Total cuentas activas" contra el detalle de la tabla sin `P134_FILTRO_CARD`.
3. En APEX, probar clicks de las cards de activas, empleados, clientes y canceladas.
4. Confirmar que los filtros de fechas con `AND` y `OR` no retornan productos fuera de `210` y `211`.

## Veredicto

El filtro base de productos digitales esta correcto para el release. La validacion final debe ejecutarse en el entorno APEX/base de datos donde se haya aplicado el SQL.
