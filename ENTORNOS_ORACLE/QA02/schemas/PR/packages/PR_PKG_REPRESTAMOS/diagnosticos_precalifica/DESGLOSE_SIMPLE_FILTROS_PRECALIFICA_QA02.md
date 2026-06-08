# Desglose simple de filtros de precalificacion - QA02

## Como leerlo

- **Pasa:** el credito sigue al proximo filtro.
- **No pasa:** el credito se descarta de ese flujo.
- **Lista inicial:** primeros filtros que arman el grupo de candidatos de cada flujo.
- **Revision adicional del lote:** filtros que se aplican despues de armar la lista inicial de candidatos.
- **Candidato `RE`:** registro que sigue vivo para validaciones, score y solicitud.

## Vista cronologica de la campaña

| Paso | Momento | Que ocurre |
|---:|---|---|
| 1 | Arranque | Se limpian o actualizan represtamos viejos/vencidos antes de cargar nuevos candidatos. |
| 2 | Flujo activos | Se buscan creditos activos que califican por DE08 y reglas de cartera. |
| 3 | Flujo fiadores | Se buscan creditos activos parecidos al flujo anterior, pero exigiendo fiador y dos cancelados. |
| 4 | Flujo fiadores historico | Se revisan creditos historicos con fiador y reglas de cancelacion. |
| 5 | Flujo cancelados | Se buscan creditos cancelados recientes en cartera actual. |
| 6 | Flujo cancelados historico | Se buscan creditos cancelados recientes desde historico. |
| 7 | Revision adicional del lote | Sobre cada lote se revisan atrasos, prestamos recientes, mora, mancomunados y edad. |
| 8 | Candidatos vivos | Los que sobreviven quedan en `PR_REPRESTAMOS` como `RE`. |
| 9 | Precalificacion | Se calcula monto, codigo de precalificacion y monto preaprobado. Tambien se revisan SIB/castigos. |
| 10 | Score / XCORE | Se obtiene o calcula el XCORE y se guarda para validaciones posteriores. |
| 11 | Solicitud | Se crea la solicitud en `PR_SOLICITUD_REPRESTAMO` si no existe. |
| 12 | Canal | Si el telefono celular es valido, se crea canal en `PR_CANALES_REPRESTAMO`. |
| 13 | Cierre | Se define el estado final: listo, pendiente o rechazado. |

## Etapa 1. Arranque del job

Antes de evaluar candidatos nuevos, el proceso prepara la campaña. En esta parte se actualizan o anulan registros anteriores que ya no deben seguir abiertos, para que la nueva corrida trabaje sobre una base limpia.

Lectura corta: esta etapa no busca candidatos nuevos; limpia el terreno para que la campaña no mezcle registros vencidos con los nuevos.

## Etapa 2. Carga de candidatos por flujo

Aqui nacen los candidatos. Cada procedimiento revisa un tipo de caso distinto y, si el credito pasa sus filtros, puede entrar al lote de represtamos.

### 2.1 Precalifica_Represtamo

Flujo para creditos activos que se evaluan contra DE08.

| Orden | Filtro | Explicacion simple |
|---:|---|---|
| 0 | Base `PR_CREDITOS` | Toma los creditos de la cartera actual. |
| 1 | Tipo de credito permitido | El tipo de credito debe estar configurado para represtamo. |
| 2 | Periodo de cuota permitido | El periodo de pago debe estar dentro de los valores permitidos; si el parametro esta vacio, no bloquea. |
| 3 | DE08 del corte actual | El credito debe aparecer en DE08 con `FUENTE='PR'`, mismo numero de credito, mismo tipo y el corte usado por la corrida. |
| 4 | `CARGA = S` | El tipo de credito debe estar marcado como cargable. |
| 5 | Dias de atraso actual | El atraso actual debe estar dentro del maximo permitido. |
| 6 | Clasificacion SIB | La clasificacion del cliente debe estar dentro de las permitidas. |
| 7 | Capital pagado | El cliente debe haber pagado suficiente capital segun el parametro. |
| 8 | Empresa correcta | El credito debe pertenecer a la empresa configurada para represtamos. |
| 9 | Sin prestamo reciente | El cliente no debe tener otro prestamo desembolsado recientemente. |
| 10 | Sin otro credito en estado `E` | El cliente no debe tener otro credito en estado `E`. |
| 11 | Persona fisica | El cliente debe ser persona fisica. |
| 12 | Nacionalidad/documento validos | La nacionalidad y el tipo de documento deben estar permitidos. |
| 13 | Sin represtamo en proceso | No debe existir un represtamo del mismo credito en estados que impiden reproceso. |
| 14 | Sola firma | Si aplica la regla, el credito no debe tener aval distinto al cliente. |
| 15 | Sin garantia | El credito no debe tener garantia. |
| 16 | No PEP | El cliente no debe estar en listas PEP. |
| 17 | No lista negra | El cliente no debe estar en lista negra. |
| 99 | Limite de lote | Se toma hasta el maximo definido por `LOTE_DE_CARAGA_REPRESTAMO`. |

Lectura corta: el filtro mas fuerte es DE08 con corte actual. Despues pesan capital pagado, sola firma y represtamos ya en proceso.

### 2.2 Precalifica_Represtamo_fiadores

Flujo para creditos activos que, ademas de pasar reglas parecidas a `Precalifica_Represtamo`, deben tener fiador.

| Orden | Filtro | Explicacion simple |
|---:|---|---|
| 0 | Base `PR_CREDITOS` | Toma los creditos de la cartera actual. |
| 1 | Tipo de credito permitido | El tipo de credito debe estar configurado para represtamo. |
| 2 | Periodo de cuota permitido | El periodo de pago debe estar permitido o el parametro debe estar vacio. |
| 3 | DE08 del corte actual | El credito debe aparecer en DE08 con `FUENTE='PR'`, mismo credito, mismo tipo y corte actual. |
| 4 | `CARGA = S` | El tipo de credito debe estar marcado como cargable. |
| 5 | Dias de atraso actual | El atraso actual debe estar dentro del maximo permitido. |
| 6 | Clasificacion SIB | La clasificacion del cliente debe estar dentro de las permitidas. |
| 7 | Capital pagado | El cliente debe haber pagado suficiente capital. |
| 8 | Empresa correcta | El credito debe pertenecer a la empresa configurada para represtamos. |
| 9 | Sin prestamo reciente | El cliente no debe tener otro prestamo desembolsado recientemente. |
| 10 | Sin otro credito en estado `E` | El cliente no debe tener otro credito en estado `E`. |
| 11 | Persona fisica | El cliente debe ser persona fisica. |
| 12 | Nacionalidad/documento validos | La nacionalidad y el tipo de documento deben estar permitidos. |
| 13 | Sin represtamo en proceso | No debe existir un represtamo del mismo credito en estados que impiden reproceso. |
| 14 | Tiene fiador | Debe existir un aval/fiador diferente al cliente. |
| 15 | Sin garantia | El credito no debe tener garantia. |
| 16 | No PEP | El cliente no debe estar en listas PEP. |
| 17 | No lista negra | El cliente no debe estar en lista negra. |
| 18 | Dos creditos cancelados | El cliente debe tener exactamente dos creditos cancelados. |
| 99 | Limite de lote | Se toma hasta el maximo definido por `LOTE_DE_CARAGA_REPRESTAMO`. |

Lectura corta: es un subconjunto mas estricto del flujo activo. No basta con pasar DE08; tambien debe tener fiador y dos creditos cancelados.

### 2.3 Precalifica_Represtamo_fiadores_hi

Flujo historico para candidatos con fiadores.

| Orden | Filtro | Explicacion simple |
|---:|---|---|
| 0 | Base `PR_CREDITOS_HI` | Toma creditos desde la tabla historica. |
| 1 | Tipo de credito permitido | El tipo de credito debe estar configurado para represtamo. |
| 2 | Periodo de cuota permitido | El periodo de pago debe estar permitido o el parametro debe estar vacio. |
| 3 | Cancelacion reciente historica | El credito historico debe estar cancelado dentro del rango permitido. |
| 4 | `CARGA = S` | El tipo de credito debe estar marcado como cargable. |
| 5 | Empresa correcta | El credito debe pertenecer a la empresa configurada para represtamos. |
| 6 | Sin prestamo reciente | El cliente no debe tener otro prestamo reciente en cartera actual. |
| 7 | Sin otro credito en estado `E` | El cliente no debe tener otro credito en estado `E`. |
| 8 | Persona fisica | El cliente debe ser persona fisica. |
| 9 | Nacionalidad/documento validos | La nacionalidad y el tipo de documento deben estar permitidos. |
| 10 | Sin represtamo en proceso | No debe existir un represtamo del mismo credito en estados que impiden reproceso. |
| 11 | Tiene fiador historico | Debe existir un aval/fiador diferente al cliente en el historico. |
| 12 | Sin garantia historica | El credito no debe tener garantia historica. |
| 13 | No PEP | El cliente no debe estar en listas PEP. |
| 14 | No lista negra | El cliente no debe estar en lista negra. |
| 15 | Dos creditos cancelados historicos | El cliente debe tener exactamente dos creditos cancelados en historico. |
| 99 | Limite de lote | Se toma hasta el maximo definido por `LOTE_DE_CARAGA_REPRESTAMO`. |

Lectura corta: este flujo quedo en cero en la corrida revisada porque no paso el filtro de cancelacion reciente historica; por eso los filtros de fiador no llegaron a aportar candidatos.

### 2.4 Precalifica_Repre_Cancelado

Flujo para creditos cancelados recientes en la cartera actual.

| Orden | Filtro | Explicacion simple |
|---:|---|---|
| 0 | Base `PR_CREDITOS` | Toma los creditos de la cartera actual. |
| 1 | Tipo de credito permitido | El tipo de credito debe estar configurado para represtamo. |
| 2 | Periodo de cuota permitido | El periodo de pago debe estar permitido o el parametro debe estar vacio. |
| 3 | Cancelacion reciente | El credito debe estar cancelado y su fecha de cancelacion debe caer dentro del rango permitido. |
| 4 | `CARGA = S` | El tipo de credito debe estar marcado como cargable. |
| 5 | Empresa correcta | El credito debe pertenecer a la empresa configurada para represtamos. |
| 6 | Sin prestamo reciente | El cliente no debe tener otro prestamo desembolsado recientemente. |
| 7 | Sin otro credito en estado `E` | El cliente no debe tener otro credito en estado `E`. |
| 8 | Persona fisica | El cliente debe ser persona fisica. |
| 9 | Nacionalidad/documento validos | La nacionalidad y el tipo de documento deben estar permitidos. |
| 10 | Sin represtamo en proceso | No debe existir un represtamo del mismo credito en estados que impiden reproceso. |
| 11 | Sola firma | Si aplica la regla, el credito no debe tener aval distinto al cliente. |
| 12 | Sin garantia | El credito no debe tener garantia. |
| 13 | No PEP | El cliente no debe estar en listas PEP. |
| 14 | No lista negra | El cliente no debe estar en lista negra. |
| 99 | Limite de lote | Se toma hasta el maximo definido por `LOTE_DE_CARAGA_REPRESTAMO`. |

Lectura corta: aqui no manda DE08. El filtro principal es que la cancelacion sea reciente y este dentro de `DIAS_CANCELACION`.

### 2.5 Precalifica_Repre_Cancelado_hi

Flujo historico para creditos cancelados usando `PR_CREDITOS_HI`.

| Orden | Filtro | Explicacion simple |
|---:|---|---|
| 0 | Base `PR_CREDITOS_HI` | Toma creditos desde la tabla historica. |
| 1 | Tipo de credito permitido | El tipo de credito debe estar configurado para represtamo. |
| 2 | Periodo de cuota permitido | El periodo de pago debe estar permitido o el parametro debe estar vacio. |
| 3 | Cancelacion reciente historica | El credito historico debe estar cancelado dentro del rango permitido. |
| 4 | `CARGA = S` | El tipo de credito debe estar marcado como cargable. |
| 5 | Empresa correcta | El credito debe pertenecer a la empresa configurada para represtamos. |
| 6 | Sin prestamo reciente | El cliente no debe tener otro prestamo reciente en cartera actual. |
| 7 | Sin otro credito en estado `E` | El cliente no debe tener otro credito en estado `E`. |
| 8 | Persona fisica | El cliente debe ser persona fisica. |
| 9 | Nacionalidad/documento validos | La nacionalidad y el tipo de documento deben estar permitidos. |
| 10 | Sin represtamo en proceso | No debe existir un represtamo del mismo credito en estados que impiden reproceso. |
| 11 | Sola firma historica | Si aplica la regla, el credito historico no debe tener aval distinto al cliente. |
| 12 | Sin garantia historica | El credito no debe tener garantia historica. |
| 13 | No PEP | El cliente no debe estar en listas PEP. |
| 14 | No lista negra | El cliente no debe estar en lista negra. |
| 99 | Limite de lote | Se toma hasta el maximo definido por `LOTE_DE_CARAGA_REPRESTAMO`. |

Lectura corta: en la corrida revisada este flujo quedo en cero porque no paso el filtro de cancelacion reciente historica.

## Etapa 3. Revision adicional del lote

Cuando un flujo ya armo su lote de candidatos, se aplican validaciones adicionales. Estos filtros protegen la campaña de casos que entraron a la lista inicial, pero que todavia tienen riesgos o condiciones que impiden seguir.

| Filtro | Explicacion simple |
|---|---|
| Base del lote | Son los candidatos que pasaron todos los filtros iniciales y entraron al lote. |
| `X3`: TC con atraso | Descarta clientes que tienen tarjeta u otro producto TC con atraso mayor o igual al parametro. |
| `X1`: otro prestamo desembolsado reciente | Descarta si el cliente recibio otro prestamo recientemente. |
| `X2`: mora ultimos 6 meses | Descarta si el credito tuvo mora alta en los ultimos 6 meses. |
| Mancomunado | Elimina creditos marcados como mancomunados. |
| Edad invalida | Elimina clientes que no cumplen la regla de edad para carga. |
| Limpieza final de rechazados `X` | Limpia fisicamente los registros marcados con estados de rechazo `X`. |

Lectura corta: aqui se depuran candidatos que se veian bien en la lista inicial, pero fallan por comportamiento reciente, mora, edad o condiciones especiales.

## Etapa 4. Candidatos vivos en estado RE

Los candidatos que sobreviven quedan en `PR_REPRESTAMOS` con estado `RE`. Ese estado significa que todavia no estan listos para notificacion: solo pasaron la primera parte y ahora entran al proceso comun.

En este punto el job cuenta cuantos `RE` quedaron. Si no hay candidatos vivos, las etapas siguientes no tienen nada nuevo que procesar.

## Etapa 5. Precalificacion y validaciones adicionales

Estas validaciones ya no son de la lista inicial, pero si forman parte del camino antes de que el cliente quede listo para solicitud/notificacion.

| Validacion | Que hace en lenguaje simple |
|---|---|
| Clasificacion SIB del DE08 | Si el cliente no tiene una clasificacion permitida en SIB, se marca rechazo `RSB`. |
| Codigo de precalificacion | Asigna el codigo de represtamo segun los dias de atraso y calcula el monto preaprobado. |
| Sin codigo de precalificacion | Si no se logra asignar codigo de precalificacion, el registro se elimina de `PR_REPRESTAMOS`. |
| OFAC | En el bloque de registros sin precalificacion se consulta OFAC; si aplica, el registro queda eliminado. |
| Fiador + dos cancelados | Si el cliente tiene fiador y exactamente dos creditos cancelados, pero no cumple el codigo requerido, se marca rechazo `RSB`. |
| DE08 SIB | Registra clasificacion SIB en bitacora con estado `CLS`. |
| DE05 SIB / castigos | Si aparece castigado en SIB, se marca rechazo `RCS`. |

Lectura corta: aqui se convierte el candidato en una opcion real de represtamo, con monto y codigo. Si falla por clasificacion, castigo o reglas internas, se descarta antes de crear la solicitud.

## Etapa 6. Score / XCORE

El score de riesgo real del proceso es `XCORE`. En los scripts de diagnostico hay un bloque que agrupa validaciones adicionales del lote (`X3`, `X1`, `X2`, mancomunado y edad), pero ese bloque no representa el score de riesgo.

En el proceso real:

- `Actualiza_XCORE_CUSTOM` corre dentro del job y llena `XCORE_GLOBAL` / `XCORE_CUSTOM`.
- En produccion, el XCORE se obtiene desde la consulta externa correspondiente; por eso no se documenta como un numero fijo.
- La validacion que rechaza por XCORE (`PVALIDA_XCORE`) existe. En el job QA02 revisado esta comentada, pero en produccion puede formar parte del cierre de riesgo segun la version vigente.

Lectura corta: XCORE no es un filtro de entrada. Es una validacion posterior que se usa cuando el candidato ya llego vivo al proceso comun.

## Etapa 7. Solicitud y canal

Cuando el candidato sigue en `RE`, el proceso intenta crearle su solicitud.

| Paso | Que ocurre |
|---|---|
| Solicitud existente | Si ya existe solicitud para el `ID_REPRESTAMO`, no la duplica. |
| Solicitud nueva | Si no existe, crea la fila en `PR_SOLICITUD_REPRESTAMO` con datos personales, direccion, telefonos, correo y tipo de credito. |
| Canal valido | Si el telefono celular es valido, crea canal para contacto en `PR_CANALES_REPRESTAMO`. |

Lectura corta: pasar filtros no significa que ya tenga solicitud. La solicitud se crea despues, cuando el candidato sigue vivo y el proceso comun lo registra formalmente.

## Etapa 8. Cierre de estado

Al final se revisa si el candidato tiene las piezas necesarias: credito, solicitud y canal. Con eso se define como queda para la siguiente etapa operativa.

| Estado | Explicacion simple |
|---|---|
| `NP` | Tiene credito, solicitud y canal; queda listo como notificacion pendiente. |
| `CP` | Tiene solicitud, pero falta canal; queda pendiente por canal. |
| `RXT` | No existe credito valido para el candidato; se rechaza por tipo de credito. |
| `AN` | Faltan solicitud/opciones; queda anulado por no cumplir criterios. |

Lectura corta: este es el cierre de la campaña. El candidato queda listo para notificacion o marcado con la causa por la que no pudo avanzar.

## Referencias exactas en el body

- Orden del job: ejecuta los cinco precalificadores en `body.sql` lineas 8240-8258.
- Despues ejecuta `Actualiza_Precalificacion`, `Actualiza_XCORE_CUSTOM` y `P_REGISTRO_SOLICITUD` en `body.sql` lineas 8266-8276.
- `PVALIDA_WORLD_COMPLIANCE` y `PVALIDA_XCORE` existen, pero estan comentados en el job QA02 revisado: `body.sql` lineas 8278-8286.
- Validacion final de solicitud/canal/credito y estados `NP`, `RXT`, `CP`, `AN`: `body.sql` lineas 8293-8307.
- `Actualiza_Precalificacion` aplica clasificacion, codigo, fiador, OFAC, DE08 SIB y DE05 SIB en `body.sql` lineas 2736-2867.
- `Actualiza_XCORE_CUSTOM` asigna XCORE en `body.sql` lineas 3307-3479.
- Referencia de produccion para XCORE: `ENTORNOS_ORACLE/Produccion/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` lineas 3299-3432.
- `P_Registrar_Solicitud` crea solicitud y canal en `body.sql` lineas 7074-7200.
- `P_REGISTRO_SOLICITUD` recorre los candidatos `RE` y llama `P_Registrar_Solicitud` en `body.sql` lineas 7994-8020.

## Resumen muy corto

1. La campaña limpia registros anteriores.
2. Carga candidatos desde cinco caminos: activos, fiadores, fiadores historico, cancelados y cancelados historico.
3. Cada camino aplica sus filtros de entrada.
4. Luego se aplican validaciones adicionales sobre el lote.
5. Los sobrevivientes quedan en `RE`.
6. El proceso comun calcula precalificacion, revisa SIB/castigos y obtiene XCORE.
7. Si sigue vivo, crea solicitud y canal.
8. Al final queda como `NP`, `CP`, `RXT` o `AN`.
