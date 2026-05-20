# Revision para release - Pagina 135 APEX

## Alcance revisado

- `backups/apex/page_135/2026-05-01/pagina_135_cards_final_filtro_productos.sql`
- `backups/apex/page_135/2026-05-01/pagina_135_reporte_tabla_final_filtro_productos.sql`
- Scripts auxiliares de validacion en `historias/apex/en_qa/PAGINA_135_FILTRO_PRODUCTOS_DIGITALES/scripts/`

## Resultado corto

El cambio principal del release, filtrar la pagina 135 por productos digitales, esta aplicado de forma consistente en las dos regiones revisadas:

- Cards: `cd.COD_PRODUCTO IN (310, 311, 313, 314, 315, 316, 317, 318)`.
- Reporte/tabla: `cd.COD_PRODUCTO IN (310, 311, 313, 314, 315, 316, 317, 318)`.

Para release, el filtro de productos cumple los dos criterios de aceptacion documentados. Antes de liberar, recomiendo validar o corregir dos riesgos de consistencia entre cards y reporte.

## Criterios de aceptacion

1. **Filtrar certificados digitales**
   Cumple. El filtro esta en la consulta de cards y en la consulta del reporte/tabla.

2. **Aplicar el mismo universo de datos en cards y tabla**
   Cumple para el universo base de productos digitales. Requiere validacion adicional en filtros derivados por card.

## Hallazgos para validar antes del release

### 1. Filtro de empleados/clientes externos no usa `COD_EMPRESA` en el reporte

En las cards, la clasificacion empleado/externo valida empleados por persona, empresa y estado activo.

En el reporte, los filtros por card `Clientes Externos` y `Empleados` validan `PA.EMPLEADOS`, pero no incluyen `e.COD_EMPRESA = cd.COD_EMPRESA`.

Riesgo:

- Si una misma persona existe como empleado activo en otra empresa, el reporte puede clasificarla distinto a las cards.
- El conteo de la card y el detalle del reporte podrian no cuadrar al hacer click en esas cards.

Recomendacion:

- Antes de release, validar si `PA.EMPLEADOS.COD_PER_FISICA` es unico globalmente o si debe agregarse `e.COD_EMPRESA = cd.COD_EMPRESA` en ambos filtros del reporte.

### 2. Filtro de certificados vencidos no es identico entre cards y reporte

En las cards, los vencidos/cerrados consideran estados `C`, `P`, `N`, `I` o estados `A`, `R` vencidos por fecha.

En el reporte, la card `Certificados Vencidos` considera estados `C`, `P`, `N`, `I` o cualquier certificado con `FEC_VENCIMIENTO < TRUNC(SYSDATE)` y fecha no nula, sin limitar esa segunda condicion a estados `A`, `R`.

Riesgo:

- Si existen otros estados fuera de `A`, `R`, `C`, `P`, `N`, `I` con fecha vencida, el reporte podria mostrar mas registros que la card.

Recomendacion:

- Antes de release, confirmar si solo existen esos estados en `CD.CD_CERTIFICADO`.
- Si existen otros estados, alinear el filtro del reporte con la logica de la card.

## Validaciones recomendadas

1. Ejecutar `scripts/01_validar_existencia_productos_digitales.sql` para confirmar existencia y conteos por producto.
2. Ejecutar `scripts/02_ver_certificados_individuales_productos_digitales.sql` para revisar registros individuales.
3. Ejecutar `scripts/03_ver_un_certificado_por_producto_digital.sql` para obtener un ejemplo por cada codigo de producto.
4. En APEX, comparar conteo de `Total Certificados Abiertos` contra el total del reporte sin `P135_FILTRO_CARD`.
5. En APEX, probar click de las cards `Certificados Vigentes`, `Certificados Vencidos`, `Clientes Externos` y `Empleados`.
6. Confirmar que cada click mantiene el filtro de productos digitales y que el detalle coincide con el conteo esperado.

## Veredicto

El filtro base de productos digitales esta correcto para el release.

No recomiendo cerrar el release sin validar los dos puntos de consistencia anteriores, especialmente si el release incluye certificar que las cards clickeables cuadran exactamente con el detalle del reporte.
