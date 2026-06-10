# Diagnóstico: represtamos que quedan en estado AN (PROD)

## Pregunta
¿Por qué en producción hay candidatos a represtamo que terminan/quedan en estado `AN`?

## Contexto
Es el complemento del tracking de filtros de QA02 (`TRACKING_INTEGRAL_PRECALIFICA_QA02`),
pero del lado del **cierre y post-precalificación en PROD**: ya no mide qué descartan los
cursores, sino qué condiciones del package marcan `AN`.

## Rutas que marcan AN en `PR.PR_PKG_REPRESTAMOS` (body PROD)

| Ruta | Origen | Motivo en bitácora | Condición |
|---|---|---|---|
| R1 | Cierre del job (`P_Carga_Precalifica_*`, loop sobre `ESTADO='RE'`) | `No cumple con los criterios: Solicitudes,Opciones` | Tras `P_Registrar_Solicitud` NO existe fila en `PR_SOLICITUD_REPRESTAMO`. Con solicitud y sin canal va a `CP`; con ambos va a `NP`. |
| R2 | `P_Anular_Represtamos_Inactivos` (previo a recarga diaria) | `Represtamo anulado (Link Vencido) por no concluir proceso.` | Estado actual ∈ parámetro `ESTADOS_ANULAR_REPRESTAMOS_POR_NO_CONCLUIR_PROCESO` y `LAST_DAY(FECHA_PROCESO) <= hoy` (campañas especiales: `FECHA_PROCESO + DIA_CADUCA_LINK_CANCELADOS <= hoy`). |
| R3 | `P_Registra_Solicitud_Campana_Tipo_Credito` | `Represtamo anulado por salto de Tipo Credito` | `F_OBTENER_NUEVO_CREDITO = 1` (no hay tipo de crédito destino válido para el monto). |
| R4 | Solicitud de nuevo link | `Anulado por Solicitud nuevo Link` | El represtamo anterior se anula al generar uno nuevo. |

En R1 la solicitud no se crea cuando `PR_REPRESTAMOS.CODIGO_CLIENTE` es NULL o cuando
`P_Registrar_Solicitud` falla antes del INSERT (datos primarios/secundarios del cliente,
`F_OBTENER_NUEVO_CREDITO`, error de inserción); en ese caso el error solo queda en el log
de `IA.LOGGER`/`setError`.

## Script
`01_DIAGNOSTICO_REPRESTAMOS_AN_PROD.sql` — solo lectura, ejecutar por query con F9 en PROD.

| Query | Qué responde |
|---|---|
| 1 | Parámetros vigentes que gobiernan la anulación. |
| 2 | Volumen de AN por mes y motivo (¿qué ruta domina?). |
| 3 | Desde qué estado caen a AN (estado previo en bitácora). |
| 4 | AN del cierre (R1): causa raíz clasificada (sin código cliente / falló registrar solicitud / anomalías). |
| 5 | Muestra individual de R1 con solicitud, canal y validación del celular contra `EXPREG_TELEFONO`. |
| 6 | AN por link vencido (R2): verificación de la regla contra el parámetro y `FECHA_PROCESO`. |
| 7 | Foto actual: represtamos hoy en `AN` con su último motivo. |

## Estado
- 2026-06-10: script creado a partir del body vivo de PROD (`ENTORNOS_ORACLE/Produccion/.../PR_PKG_REPRESTAMOS/body.sql`). Pendiente de ejecutar en PROD y registrar resultados.
