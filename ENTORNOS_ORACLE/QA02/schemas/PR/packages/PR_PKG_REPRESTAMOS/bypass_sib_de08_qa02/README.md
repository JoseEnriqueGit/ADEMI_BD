# Bypass SIB DE08 en QA02 — PR.PR_PKG_REPRESTAMOS (body)

> Caso documentado el 2026-06-12. Linaje de versiones del body para pruebas QA02
> con la validación de clasificación SIB (DE08) desactivada.

## Archivos (linaje)

| Archivo | Origen | Contenido |
|---|---|---|
| `01_body_BASELINE_PROD.sql` | Antes `PROD.sql` | **Body vigente en PRODUCCIÓN** (versión más actual de PROD al 2026-06-11). Baseline de comparación. |
| `02_body_QA02_BYPASS_SIB_DE08.sql` | Antes `body copy 2.sql` | PROD + bypass SIB DE08 + stub Xcore + filtro celular relajado. **Sin tracking.** |
| `03_body_QA02_TRACKING_BYPASS_SIB_DE08.sql` | Generado 2026-06-12 (merge 3-vías, 0 conflictos) | `body.sql` canónico (PROD + tracking integral A/B/C + adaptaciones QA02) **+ el bypass del 02**. Es el body a compilar en QA02 para que las pruebas completen sin dependencias externas. |

El `body.sql` canónico del paquete (carpeta padre) **no se tocó**: sigue siendo
PROD + tracking integral, sin bypass.

## Cambios del bypass (02 y 03 respecto a PROD)

Todos en `Precalifica_Repre_Cancelado` / `Precalifica_Repre_Cancelado_hi`
(flujos carga dirigida y campañas especiales):

1. **Bloque de validación DE08_SIB comentado** (2 sitios): se desactivan los
   `IF f_obt_parametro_represtamo('VALIDAR_CLASIFICACION_SIB_*')`, el cálculo de
   clasificación contra `PA.PA_PARAMETROS_MVP` (CLASIFICACION_SIB) y el marcado
   `RSB` / finalización en `PR_CARGA_DIRECCIONADA` / `PR_CAMPANA_ESPECIALES`.
2. **Nuevo cursor `ReprestamosAProcesarCLS`** (`ESTADO = 'RE'`, 2 sitios): en
   reemplazo del bloque anterior, registra bitácora `CLS` para todo candidato con
   comentario "Cliente no encontrado en DE08_SIB, clasificación aprobada por defecto".
3. **Loops `VALIDACION_CLASIFICACION` comentados** (2 sitios): ya no se marca
   `RSB Cliente sin clasificación` ni se finaliza el registro de carga/campaña.
4. **Stub Xcore**: `xcore := 745;` en lugar de la llamada real a
   `PA.PA_PKG_CONSULTA_DATACREDITO.CONSULTAR_JSON` (el 02 stubea 1 sitio; el 03
   queda con 2 sitios stubeados al heredar también el del body canónico).
5. **Filtro de celular relajado**: se comenta `AND C.ESTADO='T'` en el SELECT de
   `CELULAR` sobre `PR_CARGA_DIRECCIONADA` (PROD ya traía el otro sitio comentado).

## Razón

QA02 no tiene corte DE08 de la SIB actualizado ni conectividad a Datacrédito:
sin el bypass, todos los candidatos caen en `RSB Cliente sin clasificación`
(diagnóstico confirmado en
`historias/incidentes/diagnosticos/PROD_REPRESTAMOS_RSB_SIN_CLASIFICACION/`)
y el flujo nunca llega a precalificación/solicitud. El bypass aprueba la
clasificación por defecto (`CLS`) y fija un score que pasa umbrales (745) para
poder probar el resto de la cadena (precalificación, tracking, bitácora,
solicitud, notificaciones).

## Adaptaciones QA02 heredadas del body canónico (solo en 03)

- Fecha de corte DE08: usa el `MAX(FECHA_CORTE)` disponible (QA02 tiene un solo corte).
- `NVL(MAX(DIAS_ATRASO), 0)` en las actualizaciones de `DIAS_ATRASO`.
- `EXISTS` contra `PA.PA_DETALLADO_DE08` antes de marcar `RE`.
- `DELETE PR_REPRESTAMOS WHERE ESTADO LIKE 'X%'` comentado.
- Tracking integral precalifica (Incrementos A/B/C): helper `track_candidatos_flujo`
  + instrumentación en los 5 flujos + capa en `P_Carga_Precalifica_Cancelado`.
  Ver `historias/soporte_qa02/TRACKING_INTEGRAL_PRECALIFICA_QA02/`.

## Reglas

- ⚠️ **NUNCA promover a PROD ninguno de los archivos 02/03**: aprueban a todos los
  clientes sin clasificación SIB y con Xcore fijo 745.
- El baseline 01 es solo lectura (espejo de PROD); si PROD cambia, reemplazarlo y
  regenerar el 03 con `git merge-file` (03 = body.sql canónico + diff 01→02).
