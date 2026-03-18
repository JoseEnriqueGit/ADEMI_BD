# Sysde - Componentes reutilizables para APIs de certificados digitales

Este documento enumera los procesos, procedimientos y funciones existentes en el proyecto sysde (Forms) que pueden servir como base para exponer un nuevo producto de certificados digitales via API en Oracle APEX. Se incluyen notas sobre responsabilidades, entradas/salidas, dependencias y ajustes recomendados antes de integrarlos en servicios REST o PL/SQL APIs. Los elementos marcados como **experimentales** provienen de desarrollos de laboratorio y aun no pertenecen al flujo del certificado tradicional.

## 1. Parametrizacion de productos
### `productos_x_agencia` (Forms) -> potencial paquete `CD_API_PARAM`
- **Definicion:** `cdfemice/Unidades de programa`
- **Rol:** cargar configuraciones de producto desde `CD_PRODUCTO_X_AGENCIA` o `CD_PRODUCTO_X_EMPRESA`.
- **Datos clave:** montos y plazos minimos, base de calculo, base de plazo, flags de renovacion, dias de capitalizacion, porcentaje de renta, moneda.
- **Reutilizacion:** extraer el SQL en un paquete utilitario `CD_API_PARAM.get_producto` que retorne un record/JSON con la configuracion; ideal para endpoints como `GET /productos/{codigo}`.
- **Consideraciones:** maneje mensajes de error (`000189`, `000190`, `000191`, `000192`, `000171`); asegure compatibilidad multicompania.

## 2. Calculos de plazo y fechas
- **Agregar_Dias** (`cdfemice/Biblioteca PL_SQL/CDUTIL:1`), **cd_calcula_dias** (`cdfemice/Biblioteca PL_SQL/CDUTIL:140`), **CD_FECHA_EXACTA** (`cdfemice/Biblioteca PL_SQL/CDUTIL:346`), **CD_FECHA_FINANCIERA** (`cdfemice/Biblioteca PL_SQL/CDUTIL:397`).
- **Aplicacion en APIs:** encapsular en un paquete `CD_API_FECHAS` para consumir desde APEX cuando se generen simulaciones o cotizaciones (calculo de vencimientos, proxima capitalizacion).
- **Recomendaciones:** refactorizar para eliminar dependencias de `Name_In`/`utilitarios.mensaje`, devolver excepciones controladas. Conserve la logica de calendario financiero 360 vs 365.

## 3. Calculo de tasas
### `determine_tasa` (Forms) -> adaptacion a servicio
- **Definicion:** `cdfemice/Unidades de programa`
- **Funciones clave:** llamadas a `CD.pkg_cd_inter.Obtiene_CDTasActual`, `CD_TASINTERES_BASE`, `cd_calcula_tasa_neta`.
- **Entradas necesarias:** cod_empresa, cod_producto, monto, plazo (dias), cliente (opcional para tasas preferenciales), fecha.
- **Reutilizacion:** cree un wrapper PL/SQL `CD_API_TASAS.calcular` que reciba parametros limpios y devuelva:
  - codigo de tasa vigente
  - spread, operacion
  - tasa bruta base, tasa bruta ajustada, tasa neta
- **Dependencias adicionales:** `CD_VIS_CLI_TASA_MONTO` para tasas por cliente y `CD_CERTIFICADO` (acumulado) si el producto permite renovacion automatica.
- **Preparacion:** separar la lectura del acumulado de certificados en un procedimiento dedicado (`CD_API_TASAS.get_acumulado_cliente`), parametrizando moneda y estados admitidos.

## 4. Generacion de cupones
### `generacion_cupones` / `generacion_cupones_dia_pago`
- **Definiciones:** `cdfemice/Unidades de programa`, `cdfemice/Unidades de programa`
- **Uso potencial:** calcular calendario de cupones para presentar en la UI o enviar al cliente.
- **Entradas minimas:** monto, tasa bruta/neto, fecha de emision, fecha de vencimiento, configuracion de capitalizacion (`fre_capitaliza`, `pla_capitaliza`, `tip_plazo`, `pla_dias`, `dia_pago_int`).
- **Salida deseada:** lista JSON con `numero_cupon`, `fecha_vencimiento`, `dias_periodo`, `monto_bruto`, `monto_neto`.
- **Accion sugerida:** mover la logica a un paquete `CD_API_CUPONES` que no haga `INSERT` directo; en API se generaria el arreglo en memoria. Mantenga `CD_CAL_INTERES` y `cd_calcula_dias` como auxiliares.

## 5. Codigo de verificacion
### `archivo_codigo_verificacion`
- **Definicion:** `cdfemice/Unidades de programa`
- **Rol:** generar el hash SHA-1 combinando nombre, cedula y numero de certificado.
- **Reutilizacion:** convertirlo en funcion pura `CD_API_UTIL.get_codigo_verificacion(nombre, cedula, certificado)` que devuelva el hash. Util al emitir certificados digitales o enviar PDF/QR.
- **Seguridad:** confirmar que `PA.SHA1` soporte longitud esperada; considere migrar a SHA-256 si la superintendencia lo permite.

## 6. Manejo de formas de pago y cajas
### `conexion_con_cajas` y `tiene_forma_pago`
- **Definiciones:** `cdfemice/Unidades de programa`, `cdfemice/Unidades de programa`
- **Componentes reutilizables:**
  - Validacion de existencia de forma de pago (`tiene_forma_pago`).
  - Integracion con cajas (`genera_solicitud_cajas`, `CD_DET_ING_CAJA`) y registro de movimientos (`cd_inserta_movimiento_cap`).
- **Para APIs:** exponga servicios que permitan registrar formas de pago y generar solicitudes:
  - `POST /certificados/{id}/formas-pago`
  - `POST /certificados/{id}/cajas/solicitudes`
- **Recomendaciones:** separar transacciones (obtener consecutivo, insertar solicitud, insertar detalle) en procedimientos unitarios y devolver IDs generados; evitar dependencia del estado de la forma en memoria (`:pblock`, `:variables`).

## 7. Interes simple y renta
### `CD_CALCULA_INTERES`, `CD_CAL_INTERES`, `CD_CAL_TASA_NETA`
- **Definiciones:** `cdfemice/Biblioteca PL_SQL/CDUTIL:206`, `cdfemice/Biblioteca PL_SQL/CDUTIL:233`, `cdfemice/Biblioteca PL_SQL/CDUTIL:252`
- **Uso:** mantener funciones puras para calculos financieros; su estructura es apta para exponer via API sin cambios mayores.
- **Wrapper sugerido:** `CD_API_INTERES.calcular(monto, tasa, base_calculo, base_plazo, fecha_inicio, fecha_fin)` que integre `cd_calcula_dias` y `CD_CAL_INTERES`.
- **Control de errores:** implemente manejo de multiplos y retornos `NULL` explicitos para evitar raises no controlados.

Con estas piezas reutilizadas y refactorizadas, la capa APEX puede montar endpoints RESTful que entreguen simulaciones, configuraciones y calendarios de certificados digitales sin depender de la UI legacy, facilitando la evolucion hacia un producto 100% digital.
