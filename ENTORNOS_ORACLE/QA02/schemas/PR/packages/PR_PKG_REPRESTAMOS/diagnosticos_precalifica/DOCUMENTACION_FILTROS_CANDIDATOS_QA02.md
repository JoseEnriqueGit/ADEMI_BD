# Documentacion filtros de candidatos - QA02

Fecha de referencia: 2026-06-05.
Ambiente: QA02.
Objeto relacionado: `PR.PR_PKG_REPRESTAMOS`.

Esta nota resume los filtros medidos en los trackers de precalificacion. No cambia logica ni propone pase a PROD; solo deja explicado el embudo de candidatos y las conclusiones de los resultados observados.

## Fuentes revisadas

- `01_PRECALIFICA_REPRESTAMO_POST_CURSOR_FAST_QA02.sql`: mide `Precalifica_Represtamo`; el tracker identifica el procedimiento en la linea 1, arma el cruce DE08 en la linea 41, lista los filtros del cursor en lineas 314-331 y los filtros post cursor en lineas 362-367.
- `02_PRECALIFICA_REPRE_CANCELADO_CURSOR_QA02.sql`: mide `Precalifica_Repre_Cancelado`; identifica el procedimiento en la linea 1, arma el filtro de cancelacion reciente en la linea 45, lista filtros del cursor en lineas 292-306 y post cursor en lineas 337-342.
- `03_PRECALIFICA_REPRE_CANCELADO_HI_CURSOR_QA02.sql`: mide `Precalifica_Repre_Cancelado_hi`; identifica el procedimiento en la linea 1, usa `PR_CREDITOS_HI` desde la linea 17 y el filtro de cancelacion reciente desde la linea 40.
- `04_PRECALIFICA_REPRESTAMO_FIADORES_CURSOR_QA02.sql`: mide `Precalifica_Represtamo_fiadores`; identifica el procedimiento en la linea 1, agrega fiador en la linea 169 y exige dos creditos cancelados desde la linea 198.
- `05_PRECALIFICA_REPRESTAMO_FIADORES_HI_CURSOR_QA02.sql`: mide `Precalifica_Represtamo_fiadores_hi`; identifica el procedimiento en la linea 1, usa `PR_CREDITOS_HI` desde la linea 16, agrega fiador historico en la linea 145 y dos cancelados historicos desde la linea 174.
- Diagnosticos DE08: `05_DE08_DESPUES_FILTROS_CURSOR_REPRESTAMO_QA02.sql` usa `FECHA_CORTE` maxima PR desde lineas 2-6; `07_DE08_SIN_FILTRO_FECHA_CORTE_QA02.sql` quita ese filtro y valida `NO_CREDITO`, `FUENTE=PR` y `TIPO_CREDITO` desde lineas 31-47; `10_CONTEO_ESTADOS_DE08_FECHA_CORTE_MAX_QA02.sql` y `11_CONTEO_ESTADOS_DE08_SIN_FECHA_CORTE_QA02.sql` comparan estados con y sin `FECHA_CORTE`.
- Resultados usados: TXT adjuntos en `C:\Users\joogando\Downloads\RESULTADOS DEL FILTRO\` y capturas Toad pegadas en la solicitud.

## Lectura general del embudo

Los trackers separan tres momentos:

1. `SECUENCIAL_CURSOR`: simula los filtros que forman el cursor antes de insertar candidatos.
2. `LIMITE_LOTE`: aplica `ROWNUM <= LOTE_DE_CARAGA_REPRESTAMO`.
3. `SECUENCIAL_POST_CURSOR`: mide los descartes posteriores sobre el lote: `X3` por atraso TC, `X1` por desembolso reciente, `X2` por mora de 6 meses, `DELETE` por mancomunado y `DELETE` por edad invalida. El `POST_CLEANUP` resume la limpieza fisica de registros marcados `X%`, no debe leerse como un filtro adicional nuevo.

## Filtros comunes del cursor

| Orden | Filtro | Que valida |
|---:|---|---|
| 0 | Base | Parte de `PR_CREDITOS` o `PR_CREDITOS_HI`, segun variante. |
| 1 | `TIPO_CREDITO` en `PR_TIPO_CREDITO_REPRESTAMO` | Solo tipos configurados para represtamo. |
| 2 | `PERIODOS_CUOTA` | Periodo permitido o parametro vacio. |
| 3 | Filtro especifico | En represtamo activo cruza DE08; en cancelados valida `F_CANCELACION` en rango y `ESTADO='C'`. |
| 4+ | Reglas de negocio | `CARGA='S'`, empresa, sin desembolso reciente, sin credito estado `E`, persona fisica, nacionalidad/documento, sin reproceso, firma/fiador, garantia, PEP/lista negra. |

En los trackers activos (`Precalifica_Represtamo` y `Precalifica_Represtamo_fiadores`) el filtro 3 cruza `PA.PA_DETALLADO_DE08` por `NO_CREDITO`, `TIPO_CREDITO`, `FUENTE='PR'` y `FECHA_CORTE` maxima. En los trackers de cancelados el filtro 3 no depende de DE08; depende de `F_CANCELACION` dentro de `DIAS_CANCELACION`.

## Detalle filtro DE08

Este es el filtro que mas reduce candidatos en `Precalifica_Represtamo` y tambien afecta al flujo de fiadores no historico. En el cursor real, `P_FECHA_CORTE` entra como parametro del cursor `CREDITOS_PROCESAR(P_FECHA_CORTE DATE)` y representa el corte DE08 seleccionado para la corrida.

Condicion base del cruce:

```sql
JOIN PA.PA_DETALLADO_DE08 b
  ON b.tipo_credito = c.tipo_credito
 AND b.fecha_corte  = P_FECHA_CORTE
 AND b.no_credito   = a.no_credito
 AND b.fuente       = 'PR'
```

Lectura de cada condicion:

| Condicion | Funcion en el filtro |
|---|---|
| `b.fecha_corte = P_FECHA_CORTE` | Obliga a usar solo el corte DE08 de la corrida. Si el credito existe en DE08 historico, pero no en ese corte, no pasa. |
| `b.fuente = 'PR'` | Limita el detalle a creditos de prestamos. Evita mezclar informacion de otras fuentes, por ejemplo TC. |
| `b.no_credito = a.no_credito` | Amarra el registro DE08 al mismo credito candidato que viene de `PR_CREDITOS`. |
| `b.tipo_credito = c.tipo_credito` | Confirma que el DE08 corresponde al tipo de credito configurado en `PR_TIPO_CREDITO_REPRESTAMO`. En el tracker aparece equivalente como `b.tipo_credito = a.tipo_credito`. |

Conclusion de este filtro: el candidato no basta con que exista en `PR_CREDITOS` ni con que tenga algun registro viejo en DE08. Para pasar, debe tener registro DE08 de fuente `PR`, del mismo credito, del mismo tipo de credito y en el `P_FECHA_CORTE` usado por la ejecucion. Por eso, en la medicion QA02, al aplicar DE08 con corte maximo bajaron los candidatos de 652,575 a 96,008.

## Resultados por flujo

| Flujo | Base | Pasa cursor antes de lote | Pasa post cursor | Lectura corta |
|---|---:|---:|---:|---|
| `Precalifica_Represtamo` | 930,807 | 4,798 | 3,386 | El mayor corte ocurre en DE08: de 652,575 a 96,008. Luego pesan `CAPITAL_PAGADO`, sola firma y estados no reproceso. |
| `Precalifica_Repre_Cancelado` | 930,805 | 1,274 | 620 | El filtro dominante es `F_CANCELACION` reciente: de 652,573 a 6,230. Despues pesan desembolso reciente, sola firma y reproceso. |
| `Precalifica_Repre_Cancelado_hi` | 1,043,272 | 0 | 0 | `PR_CREDITOS_HI` no encontro candidatos con `F_CANCELACION` dentro del rango usado en QA02. |
| `Precalifica_Represtamo_fiadores` | 930,807 | 883 | 740 | Comparte el corte DE08 del flujo activo; ademas exige fiador/aval y exactamente dos creditos cancelados. |
| `Precalifica_Represtamo_fiadores_hi` | 1,043,275 | 0 | 0 | Igual que cancelado HI: el rango de cancelacion deja la base en cero antes de evaluar fiadores. |

## Puntos que explican los descartes

- `TIPO_CREDITO` descarta alrededor de 274 mil candidatos en `PR_CREDITOS` y alrededor de 420 mil en `PR_CREDITOS_HI`; este filtro solo deja tipos existentes en `PR_TIPO_CREDITO_REPRESTAMO`.
- `PERIODOS_CUOTA` descarta poco en comparacion: alrededor de 3,900 candidatos.
- En `Precalifica_Represtamo`, DE08 es el mayor filtro: con `FECHA_CORTE` maxima, `FUENTE='PR'` y `TIPO_CREDITO`, pasan 96,008 de 652,575 candidatos.
- En el diagnostico DE08 sin `FECHA_CORTE`, despues de tipo y periodo, la evidencia de Toad mostro 643,151 que si pasan contra 10,215 que no pasan. Esto indica que muchos creditos tienen DE08 historico, pero no necesariamente en el corte maximo usado por el cursor.
- En las capturas de estados `D,V,M,E,J`, la comparacion con y sin `FECHA_CORTE` fue casi igual: con corte maximo se observaron `D=125,221`, `E=1,104`, `J=603`, `M=7,415`, `V=8,886`; sin corte solo cambia `D` a `125,223`. Esa lectura aplica a esos estados puntuales, no a toda la base candidata.
- En `Precalifica_Repre_Cancelado` el filtro critico es cancelacion reciente, no DE08: de 652,573 candidatos despues de tipo/periodo solo pasan 6,230.
- En los dos flujos HI no hay candidatos porque el filtro de cancelacion reciente deja la base en cero; por eso los filtros posteriores no aportan descarte real en QA02.
- Los filtros post cursor que mas pesan son `X2` por mora de ultimos 6 meses y `X3` por atraso TC. `X1` no descarto candidatos en los resultados leidos.

## Conclusiones

1. Para `Precalifica_Represtamo`, la diferencia principal no es ausencia total de DE08, sino el uso de `FECHA_CORTE` maxima junto con `FUENTE='PR'` y `TIPO_CREDITO`.
2. Para `Precalifica_Repre_Cancelado`, el comportamiento esta gobernado por el rango de `F_CANCELACION`; si el rango no captura cancelaciones, el flujo cae rapido.
3. Los flujos con fiadores son subconjuntos mas estrictos: primero pasan el filtro base del flujo activo/cancelado, luego exigen aval distinto al cliente y dos creditos cancelados.
4. Los flujos HI quedaron sin candidatos en esta corrida; si negocio espera candidatos ahi, el primer punto a revisar es `DIAS_CANCELACION` contra `F_CANCELACION` historica.
5. Los numeros son evidencia QA02 de una corrida puntual. Si se reejecutan, pueden variar por nuevos creditos, nuevos cortes DE08 o cambios de parametros.

## Propuesta de tracking integral

La propuesta para convertir este diagnostico en evidencia asociada a una
ejecucion real, y extenderlo hasta precalificacion, XCORE, solicitud, canal y
estado final, se encuentra en
`PROPUESTA_TRACKING_INTEGRAL_PRECALIFICA_QA02.md`.
