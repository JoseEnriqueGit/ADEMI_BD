# Sysde - Certificado digital (Forms) - Flujos y calculos

Este documento describe el funcionamiento de los artefactos oficiales del proyecto **sysde** ubicados en `Certificado digital ORACLE FORMS`, omitiendo los paquetes experimentales `PR.pkg_digcert_gestion`/`PR.pkg_digcert_proceso` (reservados para un producto digital futuro). Incluye el flujo operativo completo del certificado tradicional, el detalle de los procedimientos involucrados y las tablas que intervienen.

## Componentes analizados
- `cdfemice/Biblioteca PL_SQL/CDUTIL`
- `cdfemice/Unidades de programa`

## Flujo operativo del certificado (Forms)
1. **Inicializacion de la forma**
   - Los triggers de `WHEN-NEW-FORM-INSTANCE` establecen valores en `:GLOBAL` y `:variables` (usuario, empresa, agencia, idioma, sistema, fecha de trabajo).
   - Se limpian bloques de trabajo (`PBLOCK`, `PBLOCK1`, `PBLOCK2`) y se posiciona la forma segun el tipo de certificado.

2. **Seleccion de producto**
   - Al elegir `:emision.cod_producto`, la funcion `productos_x_agencia` busca primero en `CD_PRODUCTO_X_AGENCIA` y, si no encuentra registro, en `CD_PRODUCTO_X_EMPRESA`.
   - Se cargan parametros clave en el bloque `:bkproducto`: bases de calculo/plazo, montos y plazos minimos, configuracion de capitalizacion, porcentaje de renta, indicadores de renovacion y moneda (`PA.PRODUCTOS`).
   - Estos datos alimentan controles de la UI (`:emision.forma_calculo`, `:emision.porcentaje_renta`, etc.).

3. **Captura de cliente y forma de pago**
   - Los bloques de Forms ligados a `CLIENTE`, `CD_DETALLE_FORMA_PAGO` y tablas auxiliares validan datos de titular, cuenta, oficiales firmantes y referencias (incluye consultas a `PA.PERSONAS`, `PA.ID_PERSONAS`, `PA.EMPLEADOS` segun la configuracion del formulario).
   - La funcion `tiene_forma_pago` verifica en `CD_DETALLE_FORMA_PAGO` si existen lineas aprobadas para la transaccion; su resultado impacta las validaciones posteriores (por ejemplo, estado inicial de cupones).

4. **Determinacion de tasas**
   - El procedimiento `determine_tasa` recibe el bloque activo (`CU`, `CA`, `VI`) y calcula:
     1. Plazo en dias mediante `cd_calcula_dias` (usa las bases de `:bkproducto`).
     2. Monto a evaluar, sumando certificados activos del cliente en `CD_CERTIFICADO` cuando el producto permite renovacion automatica.
     3. Busca configuraciones prioritarias en `CD_VIS_CLI_TASA_MONTO` (tasas preferenciales por cliente); si no aplica, delega en `CD.pkg_cd_inter.Obtiene_CDTasActual`, equivalente moderno de `CD_PRD_TASA_PLAZO_MONTO`.
     4. Con el codigo de tasa hallado, consulta la tasa bruta vigente (`CD.pkg_cd_inter.CD_TASINTERES_BASE`) y aplica spread/impuesto (`CD.pkg_cd_inter.cd_calcula_tasa_neta`).
   - Las tasas resultantes se almacenan en los bloques de Forms y en `:variables.tasa_bruta` / `:variables.tasa_neta`.

5. **Calculo de plazos y capitalizaciones**
   - `Calcule_FEC_PROX_CAP` usa `CD_FECHA_EXACTA` y `CD_FECHA_FINANCIERA` (CDUTIL) para determinar la proxima fecha de capitalizacion respetando dia objetivo, frecuencia (`D` dias o `M` meses) y calendario (360/365).
   - Estas fechas alimentan `:pblock.fec_vencimiento`, `:pblock.plazo`, `:pblock.fre_capitaliza` y variables similares en los otros bloques.

6. **Generacion de cupones**
   - `generacion_cupones` y `generacion_cupones_dia_pago` calculan cuantos cupones corresponden, su duracion (`vdias_normales`, `vdiassobran`) y montos bruto/neto con `CD_CAL_INTERES`.
   - Cada cupon se inserta en `CD_CUPON` con estado `A` (activo) o `I` (inactivo) segun exista forma de pago. Se asignan fechas de vencimiento y, si aplica, dias expresados en calendario financiero.

7. **Codigo de verificacion**
   - `archivo_codigo_verificacion` arma la cadena `<Nombre><Cedula><Certificado>`, la firma con `PA.SHA1` y devuelve el hash para grabarlo en `CD_CERTIFICADO.codigo_verificacion` y mostrarlo en el certificado impreso/digital.

8. **Registro de formas de pago e interfaces**
   - Dependiendo de `:detalle_forma_pago.forma_pago`:
     - `EE` (caja): `conexion_con_cajas` crea una solicitud en `BCJ_SOLICITUD`, inserta lineas en `CD_DET_ING_CAJA`, registra movimientos via `cd_inserta_movimiento_cap` y actualiza `CD_CERTIFICADO.numero_asiento_contable`/`numero_solicitud_cajas`.
     - `CO` (contabilidad) o `CH`/`DB` (otros medios): se invocan rutinas externas (`interfaz_cg`, `Solicitud_Debito_Cta`, `pa.inserta_solicitud_procesos`) segun el tipo, dejando trazas en tablas de procesos y monitoreo.

9. **Actualizacion y commit**
   - Tras validar montos, tasas, cupones y medios de pago, el bloqueo principal (`PBLOCK`) almacena el encabezado del certificado en `CD_CERTIFICADO`. Las rutinas anteriores completan campos auxiliares (por ejemplo, `numero_asiento_contable`, `codigo_verificacion`).
   - El commit final dispara triggers que interactuan con `CD_MOVIMIENTO`, bitacoras y solicitudes pendientes.

## Procedimientos principales (Forms)
### `archivo_codigo_verificacion`
- **Definicion:** `cdfemice/Unidades de programa`
- **Entradas:** numero de certificado, cedula (sin guiones), nombre del cliente.
- **Proceso:** concatena los datos, aplica `PA.SHA1` y retorna el hash; cualquier fallo genera mensaje `100084` y levanta `FORM_TRIGGER_FAILURE`.
- **Uso tipico:** llenar `CD_CERTIFICADO.codigo_verificacion` antes de imprimir o publicar el certificado digital.

### `Calcule_FEC_PROX_CAP`
- **Definicion:** `cdfemice/Unidades de programa`
- **Entradas:** fecha de emision, dia objetivo de capitalizacion, plazo, frecuencia (`D` o `M`).
- **Proceso:** delega en `CD_FECHA_EXACTA` para sumar dias/meses segun `:bkproducto.base_plazo`; si hay un dia especifico se ajusta con `CD_FECHA_FINANCIERA` para respetar fines de mes y febrero.
- **Salidas:** fecha de la siguiente capitalizacion (`fec_cap`) y dias acumulados (`v_plazo_dias`).

### `productos_x_agencia`
- **Definicion:** `cdfemice/Unidades de programa`
- **Objetivo:** cargar la configuracion del producto seleccionado.
- **Tablas:** `CD_PRODUCTO_X_AGENCIA`, `CD_PRODUCTO_X_EMPRESA`, `PA.PRODUCTOS`.
- **Resultados:** valores en `:bkproducto` (montos, plazos, base de calculo, indicadores de renta, dia de pago, dias de cheque/efectivo) y propagacion a `:emision`.

### `determine_tasa`
- **Definicion:** `cdfemice/Unidades de programa`
- **Flujo detallado:**
  1. Identifica el bloque y toma datos de empresa, producto, monto, cliente, fechas.
  2. Calcula el plazo exacto con `cd_calcula_dias`.
  3. Suma el saldo de certificados activos (`CD_CERTIFICADO`) cuando el producto acepta renovacion automatica.
  4. Busca tasas preferenciales en `CD_VIS_CLI_TASA_MONTO`; si no hay, llama a `CD.pkg_cd_inter.Obtiene_CDTasActual` (equivale a `CD_PRD_TASA_PLAZO_MONTO`).
  5. Obtiene tasa bruta (`CD_TASINTERES_BASE`) y calcula tasa neta (`cd_calcula_tasa_neta`) aplicando spread y porcentaje de renta.
  6. Actualiza los campos `tas_bruta`, `tas_neta`, `cod_tasa` en los bloques y en `:variables`.
- **Errores manejados:** configuracion inexistente (`000162`), falta de tasas (`000163`, `000571`), errores del paquete `CD.pkg_cd_inter`.

### `generacion_cupones`
- **Definicion:** `cdfemice/Unidades de programa`
- **Objetivo:** armar el plan de cupones cuando la capitalizacion se define por frecuencia/plazo fijo.
- **Logica:** calcula cantidad y tamano de cupones (normales/ajustados), determina dias por cupon y los inserta en `CD_CUPON` con montos calculados por `CD_CAL_INTERES`.
- **Variables claves:** `tiene_forma_pago` decide estado inicial (`A` vs `I`), `:pblock.fre_capitaliza` define periodicidad.

### `generacion_cupones_dia_pago`
- **Definicion:** `cdfemice/Unidades de programa`
- **Escenario:** productos que pagan intereses en un dia de mes especifico.
- **Pasos:** usa `verifica_dia_pago` (rutina del formulario) para cada ciclo, calcula monto con `CD_CAL_INTERES` y registra cupones en `CD_CUPON`.

### `conexion_con_cajas`
- **Definicion:** `cdfemice/Unidades de programa`
- **Objetivo:** conectar la emision con el modulo de cajas cuando la forma de pago es en efectivo.
- **Pasos principales:**
  1. Determina cantidad de certificados y monto total segun el bloque (`PBLOCK`, `PBLOCK1`, `PBLOCK2`).
  2. Solicita numero consecutivo (`consecutivo_ingresos`) y lo guarda en `:variables.solicitud`.
  3. Obtiene `CLIENTE.num_cliente` para el titular.
  4. Invoca `genera_solicitud_cajas` para insertar en `BCJ_SOLICITUD`.
  5. Recorre los certificados y crea lineas en `CD_DET_ING_CAJA`.
  6. Registra movimientos con `cd_inserta_movimiento_cap` (tabla `CD_MOVIMIENTO_CAP`/`CD_MOVIMIENTO`).
  7. Actualiza `CD_CERTIFICADO.numero_asiento_contable` y `numero_solicitud_cajas`.
- **Manejo de errores:** cada operacion valida `SQL%NOTFOUND` y genera mensajes `100084` con rollback en caso de falla.

### `call_cd_inserta_movimiento`
- **Definicion:** `cdfemice/Unidades de programa`
- **Rol:** envoltorio que fija parametros comunes y delega en `cd_inserta_movimiento_cap` para registrar movimientos contables/operativos de certificados.
- **Parametros resaltados:** empresa, certificado, sistema, subtransaccion, fecha, monto, producto, agencia, tipo de certificado y comentarios.

### `tiene_forma_pago`
- **Definicion:** `cdfemice/Unidades de programa`
- **Funcion:** consulta `CD_DETALLE_FORMA_PAGO` usando `:variables.consec_forma_pago`; devuelve `S` si existen lineas, `N` en caso contrario. El resultado activa o congela procesos dependientes (cupones, solicitudes de cajas).

## Utilidades destacadas (CDUTIL)
- **`Agregar_Dias`** (`cdfemice/Biblioteca PL_SQL/CDUTIL:1`): suma dias naturales o financieros a una fecha, corrigiendo fin de mes y febrero.
- **`cd_calcula_dias`** (`cdfemice/Biblioteca PL_SQL/CDUTIL:140`): calcula dias entre dos fechas para bases 360/365, ajustando meses de 31 dias y febrero.
- **`CD_FECHA_EXACTA`** (`cdfemice/Biblioteca PL_SQL/CDUTIL:346`) y **`CD_FECHA_FINANCIERA`** (`cdfemice/Biblioteca PL_SQL/CDUTIL:397`): obtencion de fechas y dias exactos segun frecuencia y calendario; pilar para plazos, capitalizaciones y vencimientos.
- **`CD_CALCULA_INTERES`** (`cdfemice/Biblioteca PL_SQL/CDUTIL:206`) y **`CD_CAL_INTERES`** (`cdfemice/Biblioteca PL_SQL/CDUTIL:233`): calculo de intereses simples con base de calculo configurable; usados en cupones y simulaciones.
- **`CD_CAL_TASA_NETA`** (`cdfemice/Biblioteca PL_SQL/CDUTIL:252`): aplica spread e impuesto a una tasa bruta, devolviendo tasa neta y codigos de error.


## Tablas y paquetes externos relevantes
- **CD_PRODUCTO_X_AGENCIA / CD_PRODUCTO_X_EMPRESA**: parametrizacion de productos (bases de calculo, montos, renovacion, capitalizacion); consultadas en `productos_x_agencia`. (`cdfemice/Unidades de programa`)
- **PA.PRODUCTOS**: moneda y metadatos generales del producto; se lee desde `productos_x_agencia`. (`cdfemice/Unidades de programa`)
- **CD_CERTIFICADO**: encabezado principal del certificado (plazos, tasas, montos, numero de asiento, codigo de verificacion); usado en acumulados y actualizaciones. (`cdfemice/Unidades de programa`, `cdfemice/Unidades de programa`)
- **CD_CUPON**: detalle de cupones generados por certificado (monto bruto/neto, fechas, estado); insertado en `generacion_cupones` y `generacion_cupones_dia_pago`. (`cdfemice/Unidades de programa`, `cdfemice/Unidades de programa`)
- **CD_DETALLE_FORMA_PAGO**: registro de medios de pago asociados a la emision; verificacion en `tiene_forma_pago`. (`cdfemice/Unidades de programa`)
- **CD_DET_ING_CAJA** y **BCJ_SOLICITUD**: integracion con cajas para recibir/entregar fondos; gestionadas en `conexion_con_cajas`. (`cdfemice/Unidades de programa`)
- **CD_VIS_CLI_TASA_MONTO / CD_PRD_TASA_PLAZO_MONTO**: configuracion de tasas por cliente o por rango generico; consultadas en `determine_tasa`. (`cdfemice/Unidades de programa`)
- **CD.pkg_cd_inter**: paquete central para tasas (obtencion, base, neta); invocado en `determine_tasa` y otras rutinas. (`cdfemice/Unidades de programa`)
- **CLIENTE**, **PA.PERSONAS**, **PA.ID_PERSONAS**, **PA.EMPLEADOS**: datos del titular y validaciones asociadas; consultas en `conexion_con_cajas` y bloques relacionados. (`cdfemice/Unidades de programa`, `cdfemice/Unidades de programa`)
- **cd_inserta_movimiento_cap**, **interfaz_cg**, **Solicitud_Debito_Cta**, **pa.inserta_solicitud_procesos**: procedimientos externos que registran movimientos contables o solicitudes operativas; invocados en `conexion_con_cajas` y procesos de formas de pago. (`cdfemice/Unidades de programa`, `cdfemice/Unidades de programa`)

## Nota sobre desarrollos futuros
Los paquetes `PR.pkg_digcert_gestion` y `PR.pkg_digcert_proceso` presentes en el mismo directorio corresponden a un esfuerzo de laboratorio para un certificado digital movil (app ADEMI). No forman parte del flujo oficial descrito aqui; mantenga esta diferencia al versionar o migrar cambios.
