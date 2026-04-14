# IRD-519: Botón Reprocesar para documentos en estado "Reservado para Descarga" (H)

## Contexto
- **Ticket**: IRD-519
- **Página APEX**: 63 (Reportes Generados Automáticamente)
- **Tabla fuente**: `PA.PA_REPORTES_AUTOMATICOS`
- **Página destino del link**: 66 (recibe `P66_CODIGO_REPORTE` y `P66_ESTADO_REPORTE`)

## Problema
En la página de "Reportes Generados Automáticamente", el link "Reprocesar" solo se mostraba para los estados `E` (Error), `D` (Descargado) y `S` (Subido). Cuando un documento quedaba en estado `H` (Reservado para Descarga), no había forma de reprocesarlo desde la interfaz.

## Cambio realizado

### Vista/Query de la página 63 — columna REIMPRIMIR

**ANTES** (solo estados E, D, S):
```sql
CASE 
    WHEN R.ESTADO_REPORTE IN ('E', 'D', 'S') THEN
        '<a href="' || APEX_PAGE.GET_URL(
            p_page   => 66, 
            p_items  => 'P66_CODIGO_REPORTE,P66_ESTADO_REPORTE', 
            p_values => R.CODIGO_REPORTE || ',' || 
                        CASE WHEN R.ESTADO_REPORTE = 'S' THEN 'P' ELSE 'R' END
        ) || '">Reprocesar</a>'
    ELSE NULL
END AS REIMPRIMIR
```

**DESPUES** (se agrega estado H con mapeo inteligente):
```sql
CASE 
    -- NUEVO: Estado H con transición según tipo de documento
    WHEN R.ESTADO_REPORTE = 'H' THEN 
         '<a href="' || APEX_PAGE.GET_URL(
                p_page   => 66, 
                p_items  => 'P66_CODIGO_REPORTE,P66_ESTADO_REPORTE', 
                p_values => R.CODIGO_REPORTE || ',' || 
                            CASE 
                                WHEN R.ID_TIPO_DOCUMENTO IN (
                                    '474',  -- FUD
                                    '475',  -- (reservado)
                                    '476',  -- (reservado)
                                    '477',  -- FEC
                                    '478',  -- (reservado)
                                    '479',  -- (reservado)
                                    '452'   -- Conozca Su Cliente / FCSCPF
                                ) THEN 'P'  -- Pendiente
                                ELSE 'R'    -- Pendiente Robotizado
                            END
            ) || '">Reprocesar</a>'
    -- Existente: Estados E, D, S
    WHEN R.ESTADO_REPORTE IN ('E', 'D', 'S') THEN
        '<a href="' || APEX_PAGE.GET_URL(
            p_page   => 66, 
            p_items  => 'P66_CODIGO_REPORTE,P66_ESTADO_REPORTE', 
            p_values => R.CODIGO_REPORTE || ',' || 
                        CASE WHEN R.ESTADO_REPORTE = 'S' THEN 'P' ELSE 'R' END
        ) || '">Reprocesar</a>'
    ELSE NULL
END AS REIMPRIMIR
```

> **Nota**: Este CASE se aplica en **ambos bloques** del UNION ALL (registros CON URL y registros SIN URL).

## Mapeo de transición para estado H

| ID Tipo Documento | Descripción | Estado destino |
|---|---|---|
| 452 | Conozca Su Cliente (FCSCPF) | P (Pendiente) |
| 474 | FUD | P (Pendiente) |
| 477 | FEC | P (Pendiente) |
| 475, 476, 478, 479 | (Reservados/Otros formularios) | P (Pendiente) |
| 193 | Consulta Buró | R (Pendiente Robotizado) |
| 194 | Consulta SIB | R (Pendiente Robotizado) |
| 204 | Póliza Seguro de Vida | R (Pendiente Robotizado) |
| 218 | Póliza Seguro MiPyme | R (Pendiente Robotizado) |
| 451 | Reporte Deponente | R (Pendiente Robotizado) |
| 882 | Póliza Seguro Desempleo | R (Pendiente Robotizado) |
| Cualquier otro | — | R (Pendiente Robotizado) |

## Estados de referencia

| Código | Descripción |
|---|---|
| P | Pendiente |
| R | Pendiente Robotizado |
| S | Subido |
| D | Descargado |
| E | Error |
| H | Reservado para Descarga |
| X | Fallo procesamiento |

## Archivos

```
historias/519_REPROCESAR_ESTADO_H/
├── README.md                              -- Este documento
└── scripts/
    └── query_pagina63_DESPUES.sql          -- Query completo actual
```
