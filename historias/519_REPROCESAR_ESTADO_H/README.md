# IRD-519: Botón Reprocesar para documentos en estado "Reservado para Descarga" (H)

## Contexto
- **Ticket**: IRD-519
- **Página APEX**: 63 (Reportes Generados Automáticamente - Represtamos)
- **Página APEX nueva**: 136 (Reportes Generados Automáticamente - Onboarding)
- **Tabla fuente**: `PA.PA_REPORTES_AUTOMATICOS`
- **Página destino del link**: 66 (recibe `P66_CODIGO_REPORTE` y `P66_ESTADO_REPORTE`)
- **Aplicación APEX**: 106 (Canal Digital)

## Problema
1. En la página 63, el link "Reprocesar" solo se mostraba para los estados `E`, `D` y `S`. Documentos en estado `H` (Reservado para Descarga) no podían reprocesarse.
2. No existía una página equivalente para documentos de **Onboarding** (`ORIGEN_PKM = 'Onboarding'`).

---

## Parte 1: Botón Reprocesar para estado H (Página 63 - Represtamos)

### Cambio en la columna REIMPRIMIR

**ANTES** (solo estados E, D, S):
```sql
CASE 
    WHEN R.ESTADO_REPORTE IN ('E', 'D', 'S') THEN
        '<a href="' || APEX_PAGE.GET_URL(...) || '">Reprocesar</a>'
    ELSE NULL
END AS REIMPRIMIR
```

**DESPUES** (se agrega estado H con mapeo según tipo de documento):
```sql
CASE 
    WHEN R.ESTADO_REPORTE = 'H' THEN 
         '<a href="' || APEX_PAGE.GET_URL(
                p_page   => 66, 
                p_items  => 'P66_CODIGO_REPORTE,P66_ESTADO_REPORTE', 
                p_values => R.CODIGO_REPORTE || ',' || 
                            CASE 
                                WHEN R.ID_TIPO_DOCUMENTO IN ('474','475','476','477','478','479','452') THEN 'P'
                                ELSE 'R' 
                            END
            ) || '">Reprocesar</a>'
    WHEN R.ESTADO_REPORTE IN ('E', 'D', 'S') THEN
        '<a href="' || APEX_PAGE.GET_URL(...) || '">Reprocesar</a>'
    ELSE NULL
END AS REIMPRIMIR
```

### Mapeo de transición Represtamos (estado H)

| Servicio | ID Tipo Documento | Estado destino | Fuente |
|---|---|---|---|
| FUD | 474, 475, 476 | P | JSON DocumentService Represtamo |
| FEC | 477, 478, 479 | P | JSON DocumentService Represtamo |
| Conozca Su Cliente | 452 | P | JSON DocumentService Represtamo |
| SIB | 194 | R | JSON DocumentService Represtamo |
| LexisNexis | 450 | R | JSON DocumentService Represtamo |
| Buró | 193 | R | JSON DocumentService Represtamo |
| Seguro Vida | 204 | R | JSON DocumentService Represtamo |
| Seguro MiPyme | 218 | R | JSON DocumentService Represtamo |
| Deponente | 451 | R | JSON DocumentService Represtamo |
| Seguro Desempleo | 882 | R | JSON DocumentService Represtamo |

---

## Parte 2: Nueva página 136 - Reportes Onboarding

### Diferencias vs Represtamos (página 63)

| Aspecto | Página 63 (Represtamo) | Página 136 (Onboarding) |
|---|---|---|
| ORIGEN_PKM | `'Represtamo'` | `'Onboarding'` |
| JOIN principal | `PR.PR_SOLICITUD_REPRESTAMO` | Ninguno (sin tabla equivalente) |
| Datos del cliente | `SR.NOMBRES`, `SR.APELLIDOS`, `SR.IDENTIFICACION` | Extraídos del NOMBRE_ARCHIVO (3er segmento = codigo_cliente) |
| Identificación | Del JOIN | Subquery a `PA.CLIENTES_B2000` |
| Nombre cliente | Del JOIN | `PA.OBT_NOMBRE_PERSONA(codigo_cliente)` |
| Columna Représtamo | `SR.ID_REPRESTAMO` | Se elimina (no aplica) |
| Columna No. Crédito | `F_NUM_PRESTAMO` | `F_NUM_CUENTA` (número de cuenta) |

### Mapeo de transición Onboarding (todos los estados E, D, S, H)

Según los criterios de aceptación de la IRD-519, la transición al reprocesar se determina
**siempre por tipo de documento**, sin importar el estado actual. Esto difiere de la página 63
(Represtamos) donde E/D/S usan lógica basada en estado.

| Servicio | ID Tipo Documento | Estado destino | Fuente |
|---|---|---|---|
| Conozca Su Cliente | 618, 429 | P | JSON DocumentService Onboarding |
| Solicitud Tarjeta | 424 | P | JSON DocumentService Onboarding |
| Matriz Riesgo | 809 | P | JSON DocumentService Onboarding |
| SIB | 810, 527 | R | JSON DocumentService Onboarding |
| LexisNexis | 621, 511 | R | JSON DocumentService Onboarding |
| Buró | 762, 428 | R | JSON DocumentService Onboarding |

### Obtención de datos del cliente

El código de cliente se extrae del nombre del archivo:
```
NOMBRE_ARCHIVO: FCSCPF_21055516645617_5516645.pdf
                 ^TIPO   ^NUM_CUENTA     ^COD_CLIENTE
```
- `REGEXP_SUBSTR(REPLACE(R.NOMBRE_ARCHIVO, '.pdf', ''), '[^_]+', 1, 3)` → codigo_cliente
- `PA.OBT_NOMBRE_PERSONA(codigo_cliente)` → nombre del cliente
- `CLIENTES_B2000.NUMERO_IDENTIFICACION` → cédula

### Pruebas realizadas (DESARROLLO - 2026-04-15)

| Prueba | Tipo Doc | Estado antes | Estado después | Resultado |
|---|---|---|---|---|
| Reprocesar FCSCPF | 618 | S | P (Pendiente) | OK |
| Reprocesar MRAVPF | 809 | S | P (Pendiente) | OK |
| Diálogo página 66 | — | — | Muestra "PENDIENTE" | OK |
| Datos cliente con codigo_cliente válido | 618 | — | Muestra nombre e identificación | OK |
| Datos cliente sin codigo_cliente válido | 618 | — | Campos vacíos (esperado en datos de prueba) | OK |

### Nota sobre datos vacíos
Algunos registros no muestran Identificación ni Cliente porque el código de cliente extraído del nombre del archivo no existe en `CLIENTES_B2000` del entorno de DESARROLLO. En producción con datos reales, la mayoría debería mostrar los datos completos.

---

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
    ├── query_pagina63_DESPUES.sql          -- Query página 63 (Represtamos) con estado H
    └── query_onboarding.sql               -- Query página 136 (Onboarding)
```

## Investigación realizada

### Paquetes que generan documentos de Onboarding
- `CC.PKG_INTERFAZ_CC` — Apertura de cuenta efectivo (principal)
- `CD.PKG_CD_DIGITAL` — Certificados digitales
- `PA.PKG_CLIENTE` — Referencia de onboarding
- `PA.PKG_TIPO_DOCUMENTO_PKM` — Genera FCSCPF_OnBoarding

### Consultas de validación ejecutadas
- Confirmación de `ORIGEN_PKM = 'Onboarding'` en QA02 y DESARROLLO
- Validación empírica de estados por tipo de documento (DESARROLLO)
- Confirmación de mapeo con JSON DocumentService de Onboarding
- Verificación de extracción de codigo_cliente desde NOMBRE_ARCHIVO
