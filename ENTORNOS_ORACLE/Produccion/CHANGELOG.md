# CHANGELOG - PRODUCCION

> Registro cronologico de cambios desplegados en el entorno de Produccion.
> Formato por entrada: Fecha | Historia/Ticket | Objetos afectados
> Campos obligatorios de cada despliegue (compuerta anti-regresion, ver docs/guias/RUNBOOK_PROMOCION_PROD.md):
>   - **commit-baseline**: sha del DDL VIVO de PROD extraido ANTES de sobrescribir
>   - **commit-propuesto**: sha de la version desplegada
>   - **inventario**: ruta al 03_INVENTARIO_SEMANTICO firmado (0 ELIMINADO sin justificar)
>   - **desplego / firmo**: responsables

---

<!-- Agregar nuevas entradas al inicio -->

## (BORRADOR - PENDIENTE DE DESPLIEGUE) | 419 + incidente regresion - PR.PR_V_ENVIO_REPRESTAMOS
> NO desplegado aun. Finalizar esta entrada al pegar en PROD: poner fecha real, sha-propuesto y firmante,
> y quitar el marcador BORRADOR. Ver historias/419_CANALES_HABILITADO/promocion/04_SIGNOFF.md.
- **Modificado**: `PR.PR_V_ENVIO_REPRESTAMOS` (VIEW) - se amplia el CASE de CANAL_DESC para mapear
  canales 3 (CANAL_CARGA_DIRIGIDA) y 4 (CANAL_CAMPANA_ESPECIAL), que estaban cayendo al ELSE.
  Forma parametrizada (f_obt_parametro_Represtamo). Resto del cuerpo identico a lo que estaba vivo.
- **commit-baseline**: `7181eaf` (placeholder) -> DDL real de PROD en el commit de esta entrega
- **commit-propuesto**: `<sha de 02_propuesto>`
- **inventario**: historias/419_CANALES_HABILITADO/promocion/03_INVENTARIO_SEMANTICO.md (0 perdidas reales)
- **Pre-requisito**: parametros CANAL_CARGA_DIRIGIDA/CANAL_CAMPANA_ESPECIAL existen (confirmado).
  Verificar que CANALES_HABILITADOS los incluya, si no, actualizar tambien ese parametro.
- **desplego / firmo**: `____ / ____`

---

## 2026-06-02 | Anti-regresion - Estructura de baseline y consolidacion (solo repo, sin tocar PROD)
- **Estructura**: creado el espejo `Produccion/schemas/PR/views/` (baseline de `PR.PR_V_ENVIO_REPRESTAMOS` PENDIENTE de extraer de PROD).
- **Normalizado**: `Produccion/PKG_TIPO_DOCUMENTO_PKM.sql` (suelto) -> `Produccion/schemas/PA/packages/PKG_TIPO_DOCUMENTO_PKM/body.sql`.
- **Notas**: no hay cambios en la base de datos. Pendiente real de PROD: extraer y versionar el DDL VIVO de `PR.PR_V_ENVIO_REPRESTAMOS` y decidir recuperacion de las ramas CANAL_CARGA_DIRIGIDA/CANAL_CAMPANA_ESPECIAL.

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
