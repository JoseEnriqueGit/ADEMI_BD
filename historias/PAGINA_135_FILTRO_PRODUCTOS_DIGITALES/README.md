# Pagina 135 APEX - Filtro de productos digitales en vista de certificados

## Contexto

- **Ticket**: Pendiente de asignar
- **Pantalla / vista APEX**: Pagina 135
- **Region APEX**: Cards de certificados y reporte/tabla de certificados
- **Modulo funcional**: Certificados digitales
- **Tabla base principal**: `CD.CD_CERTIFICADO`
- **Fecha del cambio**: 2026-05-01

## Historia

Yo como negocio requiero que la vista de certificados de la pagina 135 de APEX muestre unicamente los certificados correspondientes a productos digitales, con el objetivo de evitar que la pantalla mezcle certificados de productos no digitales y asegurar que los indicadores, montos y registros del reporte representen solamente el universo esperado por negocio.

## Criterios de aceptacion

La pantalla debe cumplir con los siguientes criterios:

1. **Filtrar certificados digitales**
   Debe considerar solamente certificados cuyo `COD_PRODUCTO` este dentro de la lista `310, 311, 313, 314, 315, 316, 317, 318`.

2. **Aplicar el mismo universo de datos en cards y tabla**
   Las cards informativas y el reporte/tabla deben usar el mismo filtro de productos digitales para que conteos, montos y detalle sean consistentes.

## Cambio funcional realizado

Se agrego el filtro de productos digitales en las dos consultas principales de la pagina:

- `cards de certificados`: se agrego `AND cd.COD_PRODUCTO IN (310, 311, 313, 314, 315, 316, 317, 318)`.
- `reporte/tabla de certificados`: se agrego el mismo filtro sobre `CD.CD_CERTIFICADO`.

## Alcance tecnico

### Region: cards de certificados

El cambio restringe la CTE base `CertificadosBase`, por lo que todos los indicadores derivados de esa CTE quedan limitados al universo de certificados digitales.

Indicadores impactados:

- Total certificados abiertos
- Certificados vigentes
- Certificados vencidos
- Monto en pesos
- Monto en dolares
- Clientes externos
- Empleados
- Monto cancelados en pesos
- Monto cancelados en dolares

### Region: reporte/tabla de certificados

El cambio restringe el detalle mostrado en la tabla de la pagina 135. El filtro se aplica antes de la logica de seleccion por card, por lo que cualquier card seleccionada filtra solo dentro de los productos digitales.

Columnas y reglas de negocio existentes se mantienen, incluyendo:

- Datos de cliente
- Identificacion / cedula
- Tipo de cliente empleado o externo
- Genero, edad y datos del certificado
- Oficina y zona
- Estado funcional del certificado
- Filtros por vigencia, moneda y tipo de cliente

## Evidencia en repositorio

### Version final

- `backups/apex/page_135/2026-05-01/README.md`
- `backups/apex/page_135/2026-05-01/pagina_135_cards_final_filtro_productos.sql`
- `backups/apex/page_135/2026-05-01/pagina_135_reporte_tabla_final_filtro_productos.sql`

### Respaldo previo

- `backups/apex/page_135/2026-04-30/README.md`
- `backups/apex/page_135/2026-04-30/pagina_135_cards_antes_filtro_productos.sql`
- `backups/apex/page_135/2026-04-30/pagina_135_reporte_tabla_antes_filtro_productos.sql`

### Revision para release

- `REVISION_RELEASE.md`

## Validacion sugerida en APEX / Toad

1. Ejecutar la consulta final de cards y validar que todos los calculos provienen solamente de certificados con `COD_PRODUCTO IN (310, 311, 313, 314, 315, 316, 317, 318)`.
2. Ejecutar la consulta final del reporte/tabla y confirmar que no retorna productos fuera de la lista digital.
3. Comparar el total de la card "Total Certificados Abiertos" contra el conteo del reporte sin filtro de card seleccionado.
4. Validar cada card clickeable y confirmar que el detalle resultante mantiene el filtro de productos digitales.
5. Probar la logica de fecha con `:P135_LOGICA_FECHA = 'AND'` y `:P135_LOGICA_FECHA = 'OR'`.
6. Guardar evidencia visual de la pagina 135 con los filtros aplicados.

Script auxiliar:

- `scripts/01_validar_existencia_productos_digitales.sql`
- `scripts/02_ver_certificados_individuales_productos_digitales.sql`
- `scripts/03_ver_un_certificado_por_producto_digital.sql`

## Riesgos y observaciones

- Si negocio modifica la lista de productos digitales, debe actualizarse el filtro en ambas regiones para mantener consistencia.
- La validacion final de datos debe hacerse en el entorno APEX donde se aplico el cambio, porque el repo conserva los scripts de referencia pero no confirma la data en base de datos.
- El cambio no altera la estructura de la tabla base ni contratos de paquetes; se limita a la consulta SQL de la pagina APEX.

## Estado

Implementado en APEX segun scripts finales informados por el usuario y respaldado en el repositorio.
