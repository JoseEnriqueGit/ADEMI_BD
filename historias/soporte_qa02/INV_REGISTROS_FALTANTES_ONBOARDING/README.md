# Investigacion: registros faltantes en Reportes Onboarding

## Contexto
- **Caso base**: IRD-519, pagina 136 - Reportes Generados Automaticamente - Onboarding.
- **Aplicacion APEX**: 106 - Canal Digital.
- **Tabla fuente declarada**: `PA.PA_REPORTES_AUTOMATICOS`.
- **Consulta de referencia**: `historias/apex/en_qa/519_REPROCESAR_ESTADO_H/scripts/query_onboarding.sql`.
- **Estado**: investigacion abierta.
- **Entorno**: pendiente de confirmar antes de leer objetos Oracle reales.

## Descripcion tipo historia
Yo como negocio/coordinacion requiero investigar por que la vista **Reportes Generados Automaticamente - Onboarding** no muestra todos los registros esperados, aun despues de retirar el filtro reportado anteriormente, para determinar si la ausencia proviene de los datos fuente, de la SQL de la pagina, de la configuracion del Interactive Report de APEX o del proceso que genera los reportes.

## Problema reportado
El coordinador indica que todavia no aparecen todos los registros esperados en la vista de Onboarding. En el repo, la consulta actual no filtra por un estado especifico para devolver filas, pero si conserva filtros estructurales por origen y por existencia de URL.

## Criterios de aceptacion
1. Identificar el universo total de registros candidatos en `PA.PA_REPORTES_AUTOMATICOS`.
2. Comparar el universo total contra lo que devuelve la query de la pagina 136.
3. Determinar si hay registros excluidos por `ORIGEN_PKM`, valores equivalentes como `Tarjeta`/`TarjetaPC`, espacios, mayusculas/minusculas o nulos.
4. Validar distribucion por estado, tipo de documento, URL, fecha y numero de cuenta.
5. Confirmar si el faltante esta en la SQL fuente o en configuracion APEX: filtros guardados, busqueda activa, paginacion, ordenamiento, columnas ocultas o saved report.
6. Entregar diagnostico con evidencia y propuesta de siguiente paso sin cambiar logica de negocio durante la investigacion.

## Alcance
- Solo investigacion y diagnostico.
- No modificar la query productiva de APEX sin aprobacion.
- No cambiar paquetes, funciones, tablas ni reglas de negocio.
- Si se identifica una dependencia faltante, solicitarla al usuario antes de asumir comportamiento.

## Hipotesis iniciales
1. **Origen exacto**: la pagina solo toma `ORIGEN_PKM = 'Onboarding'`; registros relacionados que vengan como `Tarjeta`, `TarjetaPC`, `ONBOARDING`, `Onboarding ` o `NULL` quedan fuera.
2. **Configuracion APEX**: si la query devuelve los registros pero la pantalla no, el faltante puede estar en filtros guardados, busqueda activa, paginacion, ordenamiento o reporte primario/secundario del Interactive Report.
3. **Orden no deterministico**: la query de referencia no define `ORDER BY`; los registros pueden estar en otra pagina del reporte o mostrarse en un orden no esperado.
4. **Datos fuente incompletos**: si el registro no existe en `PA.PA_REPORTES_AUTOMATICOS`, el problema no esta en la vista sino en el proceso de generacion/insercion del reporte.
5. **Tipos de documento nuevos**: nuevos `ID_TIPO_DOCUMENTO` no deberian excluir filas, pero pueden explicar ausencia del boton `Reprocesar` o transiciones incorrectas si no estan en el mapeo.

## Plan de investigacion
1. Confirmar entorno de analisis: QA02, DESARROLLO o Produccion.
2. Ejecutar `scripts/01_diagnostico_registros_faltantes.sql` en Toad.
3. Comparar el total que devuelve la query contra el total visible en APEX pagina 136.
4. Revisar si existen origenes similares excluidos por el filtro exacto.
5. Levantar evidencia con `CODIGO_REPORTE`, `ORIGEN_PKM`, `ID_TIPO_DOCUMENTO`, `ESTADO_REPORTE`, `URL_REPORTE`, `CODIGO_REFERENCIA`, `NOMBRE_ARCHIVO` y `FECHA_REPORTE`.
6. Concluir causa raiz o solicitar dependencias si el faltante viene del proceso generador.

## Protocolo si el reclamo viene de Produccion
1. Pedir a una persona con acceso a Produccion ejecutar `scripts/02_validacion_apex_vs_bd_prod.sql` en Toad.
2. En APEX Produccion, pagina 136, usar `Actions > Reset` antes de comparar.
3. Exportar el Interactive Report visible a CSV/Excel.
4. Comparar el total exportado de APEX contra `TOTAL_BD_PAGINA_136` del BLOQUE 2.
5. Comparar el CSV/Excel de APEX contra la lista del BLOQUE 3 usando `CODIGO_REPORTE`, `F_NUM_CUENTA`, `NOMBRE_ARCHIVO` y `FECHA_REPORTE`.
6. Si APEX y BLOQUE 3 coinciden, la pagina muestra exactamente lo que consulta; el faltante queda fuera de la SQL actual o fuera de la tabla fuente.
7. Si el faltante aparece en BLOQUE 5, la causa probable es que el registro tiene `ORIGEN_PKM` distinto de `Onboarding`, como `Tarjeta` o `TarjetaPC`.
8. Si el faltante no aparece en ningun bloque, el problema esta antes de la pagina: generacion/insercion del reporte en `PA.PA_REPORTES_AUTOMATICOS`.

## Archivos
```text
historias/soporte_qa02/INV_REGISTROS_FALTANTES_ONBOARDING/
|-- README.md
`-- scripts/
    |-- 01_diagnostico_registros_faltantes.sql
    `-- 02_validacion_apex_vs_bd_prod.sql
```

## Resultado esperado de la investigacion
- Lista de registros faltantes o patron que los excluye.
- Evidencia de si el problema esta en datos fuente, SQL de pagina, configuracion APEX o generacion previa.
- Recomendacion concreta: ajustar filtro, ajustar APEX, pedir dependencia faltante o abrir cambio separado.
