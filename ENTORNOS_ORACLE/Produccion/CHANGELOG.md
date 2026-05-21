# CHANGELOG - PRODUCCION

> Registro cronologico de cambios desplegados en el entorno de Produccion.
> Formato: Fecha | Historia/Ticket | Objetos afectados

---

<!-- Agregar nuevas entradas al inicio -->

## 2026-05-21 | PR_PKG_REPRESTAMOS / PR_V_ENVIO_REPRESTAMOS - Pase package, vista e indice MVP

- **Agregado/actualizado**: `PR.PR_PKG_REPRESTAMOS` spec y body finales para pase.
- **Agregado/actualizado**: `PR.PR_V_ENVIO_REPRESTAMOS` y sinonimo publico `PR_V_ENVIO_REPRESTAMOS`.
- **Agregado**: indice `PA.IDX_PARAM_MVP_EMP_MVP_PARAM` sobre `PA.PA_PARAMETROS_MVP`
  (`CODIGO_EMPRESA, CODIGO_MVP, CODIGO_PARAMETRO`) en tablespace `PA_IDX`.
- **Archivos de referencia**:
  - `ENTORNOS_ORACLE/Produccion/schemas/PR/packages/PR_PKG_REPRESTAMOS/spec.sql`
  - `ENTORNOS_ORACLE/Produccion/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql`
  - `ENTORNOS_ORACLE/Produccion/schemas/PR/views/PR_V_ENVIO_REPRESTAMOS.sql`
  - `ENTORNOS_ORACLE/Produccion/schemas/PA/tables/PA_PARAMETROS_MVP/indexes.sql`
- **Promocion**: `historias/_promociones/2026-05-21_REPRESTAMOS_PACKAGE_VIEW_INDEX.md`
- **Rollback**: `historias/_promociones/2026-05-21_REPRESTAMOS_PACKAGE_VIEW_INDEX_ROLLBACK.sql`
- **Package rollback incluido**:
  - `historias/_promociones/2026-05-21_REPRESTAMOS_PACKAGE_VIEW_INDEX_ROLLBACK/PR_PKG_REPRESTAMOS_spec_anterior.sql`
  - `historias/_promociones/2026-05-21_REPRESTAMOS_PACKAGE_VIEW_INDEX_ROLLBACK/PR_PKG_REPRESTAMOS_body_anterior.sql`
- **Pendientes de verificar en PROD**:
  1. `PR.PR_PKG_REPRESTAMOS` spec/body compilan `VALID`.
  2. `PR.PR_V_ENVIO_REPRESTAMOS` compila `VALID` y devuelve registros esperados.
  3. El sinonimo publico apunta a `PR.PR_V_ENVIO_REPRESTAMOS`.
  4. El indice `PA.IDX_PARAM_MVP_EMP_MVP_PARAM` existe en `PA_IDX` con `STATUS=VALID`.
  5. Monitorear la primera corrida de `PR.JOB_CARGA_PRECALIFICA_RD`.

## 2026-04-23 | OPT-002/004/009/010/011/013/015/016 - Pase de 8 indices de apoyo

- **Agregado**: 8 indices para apoyar optimizaciones del paquete PR_PKG_REPRESTAMOS.
- **Tablas afectadas**:
  - `PA.PA_DE08_SIB` -> `IDX_DE08_SIB_FECHA_DEUDOR` (FECHA_CORTE, ID_DEUDOR, CLASIFICACION)
  - `PA.PA_DETALLADO_DE08` -> `IDX_DE08_NOCRED_CALIF_FECHA` (NO_CREDITO, FECHA_CORTE, CALIFICA_CLIENTE)
  - `PA.PA_DE05_SIB` -> `IDX_DE05_SIB_CASTIGO_CEDULA` (FECHA_CASTIGO, CEDULA, ENTIDAD)
  - `PR.PR_CREDITOS_HI` -> `IDX_CREDITOS_HI_NOCREDITO` (NO_CREDITO)
  - `PR.PR_GARANTIAS` -> `IDX_GARANTIAS_TIPO_SB` (CODIGO_EMPRESA, NUMERO_GARANTIA, CODIGO_TIPO_GARANTIA_SB)
  - `PR.PR_REPRESTAMOS` -> `IDX_REPRESTAMOS_EMP_EST_NOCRED` (CODIGO_EMPRESA, ESTADO, NO_CREDITO, ID_REPRESTAMO)
  - `PR.PR_REPRESTAMOS` -> `IDX_REPRESTAMOS_ESTADO_COV` (ESTADO, ID_REPRESTAMO, XCORE_GLOBAL)
  - `PR.PR_SOLICITUD_REPRESTAMO` -> `IDX_SOLREPRE_IDREPRE_TIPCRED` (ID_REPRESTAMO, TIPO_CREDITO)
- **Tablespaces**: PA_IDX / PR_IDX (correccion aplicada por observacion de Directora TI
  sobre el uso incorrecto de tablespaces DATA para indices).
- **Evidencia de respaldo**:
  - 4 indices con medicion real del job completo en DESARROLLO (OPT-014, reduccion -41% tiempo total, -99% PIO):
    `IDX_DE08_SIB_FECHA_DEUDOR`, `IDX_CREDITOS_HI_NOCREDITO`,
    `IDX_REPRESTAMOS_EMP_EST_NOCRED`, `IDX_DE05_SIB_CASTIGO_CEDULA`.
  - 4 indices con evidencia aislada (Explain Plan o medicion por query individual):
    `IDX_DE08_NOCRED_CALIF_FECHA`, `IDX_GARANTIAS_TIPO_SB`,
    `IDX_REPRESTAMOS_ESTADO_COV`, `IDX_SOLREPRE_IDREPRE_TIPCRED`.
- **Pendientes de verificar en PROD**:
  1. Que los indices esten con STATUS=VALID en `ALL_INDEXES`.
  2. Que esten efectivamente en PA_IDX/PR_IDX (no en DATA). Si DBA los creo en otro
     tablespace, actualizar los archivos de este entorno para reflejar realidad.
  3. Que se hayan refrescado estadisticas de las tablas afectadas
     (`DBMS_STATS.GATHER_TABLE_STATS(..., cascade=>TRUE)`) tras la creacion.
  4. Monitorear durante 1-2 semanas regresiones en queries OLTP no previstas,
     especialmente sobre `PR_REPRESTAMOS` (ESTADO como columna lider baja cardinalidad).
- **Nota**: 4 de los 8 indices dependen de cambios de codigo aun no desplegados
  (OPT-004, OPT-010, OPT-015, OPT-016). Hasta que esos cambios esten en PROD,
  esos indices penalizan DML sin entregar el beneficio pleno para el que fueron disenados.
