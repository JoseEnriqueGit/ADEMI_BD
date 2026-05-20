# Objetos Incorporados

## QA02

### PA

| Objeto | Tipo | Ruta | Motivo |
|---|---|---|---|
| `PA.PKG_MANT_TBL_HELADO` | Package spec/body | `ENTORNOS_ORACLE/QA02/schemas/PA/packages/PA.PKG_MANT_TBL_HELADO/` | Referencia para identificar migracion/archivo de reportes automaticos y bitacora. |
| `PA.BITACORA_REPORTES_AUTOMATICOS` | Procedure | `ENTORNOS_ORACLE/QA02/schemas/PA/Procedures/Bitacora_Reportes_Automaticos.sql` | Referencia del procedimiento invocado por triggers de reportes automaticos. |
| `PA.CAMBIAR_MULTIESTADO_REP_AUTO` | Procedure | `ENTORNOS_ORACLE/QA02/schemas/PA/Procedures/CAMBIAR_MULTIESTADO_REP_AUTO.sql` | Referencia de cambio masivo de estados usando bitacora. |
| `PA.MARK_ERROR_STATUS_AUTOMATICO` | Procedure | `ENTORNOS_ORACLE/QA02/schemas/PA/Procedures/MARK_ERROR_STATUS_AUTOMATICO.sql` | Referencia de ajuste de estados usando bitacora. |

### IA

| Objeto | Tipo | Ruta | Motivo |
|---|---|---|---|
| `IA.CHECK_ESTADO_REPORTE` | Procedure | `ENTORNOS_ORACLE/QA02/schemas/IA/Procedures/check_estado_reporte.sql` | Referencia de validacion de estados contra bitacora. |
| `IA.CHECK_ESTADO_REPORTE_TEST` | Procedure | `ENTORNOS_ORACLE/QA02/schemas/IA/Procedures/CHECK_ESTADO_REPORTE_TEST.sql` | Referencia de version test de validacion de estados contra bitacora. |
| `IA.CHECK_ESTADO_REPORTE_V1` | Procedure | `ENTORNOS_ORACLE/QA02/schemas/IA/Procedures/check_estado_reporte_v1.sql` | Referencia de version previa de validacion de estados contra bitacora. |

## Observaciones

- Incorporados el 2026-04-30 desde Toad / `ALL_SOURCE` en `QADEMI02_19C`.
- Los objetos se guardaron solo como referencia de investigacion; no se altero su logica.
- `CHECK_ESTADO_REPORTE_TESTs.sql` fue renombrado a `CHECK_ESTADO_REPORTE_TEST.sql` para coincidir con el nombre real del procedimiento.
