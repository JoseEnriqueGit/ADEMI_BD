# OPT-015: Guia rigurosa de equivalencia funcional en DESARROLLO

> Objetivo: validar que OPT-015 mantiene resultados equivalentes para la cadena de
> cancelados y su flujo local posterior, con menos variabilidad que la guia anterior.
>
> Entorno objetivo: `DESARROLLO`
>
> Alcance cubierto por esta guia:
> - `Precalifica_Repre_Cancelado`
> - `Precalifica_Repre_Cancelado_hi`
> - `Actualiza_Precalificacion`
> - `P_Registrar_Solicitud` / `P_Generar_Bitacora`
> - Loop final de bitacora y cambios de estado (`NP`, `CP`, `RXT`, `AN`)
>
> Alcance excluido como criterio de equivalencia:
> - `PVALIDA_WORLD_COMPLIANCE`
> - `PVALIDA_XCORE`
>
> Motivo: esos pasos dependen de validaciones externas o ruido adicional y no deben
> usarse como gate de equivalencia de OPT-015.

---

## Archivos del paquete

| # | Archivo | Uso |
|---|---------|-----|
| 1 | `01_CREAR_INDICE_IDX_GARANTIAS_TIPO_SB.sql` | Crear indice si no existe |
| 2 | `02_SETUP_EQUIVALENCIA_OPT015.sql` | Crea tablas auxiliares y sube temporalmente el lote |
| 3 | `03_EJECUTAR_CADENA_CANCELADOS_OPT015.sql` | Ejecuta la cadena deterministica para un run (`ANTES` o `DESPUES`) |
| 4 | `04_LIMPIAR_RUN_EQUIVALENCIA_OPT015.sql` | Elimina los datos funcionales creados por un run |
| 5 | `05_MEDIR_JOB_CANCELADO_DETALLADO.sql` | Medicion de rendimiento del job |
| 6 | `06_COMPARAR_EQUIVALENCIA_CANCELADOS_OPT015.sql` | Compara snapshots ANTES vs DESPUES |
| 7 | `07_RESTAURAR_PARAMETRO_LOTE_OPT015.sql` | Restaura `LOTE_DE_CARAGA_REPRESTAMO` |
| 8 | `body_ANTES_OPT015.sql` | Body original |
| 9 | `body_DESPUES_OPT015.sql` | Body optimizado |

---

## Prerequisitos

- Trabajar en `DESARROLLO`.
- Poder compilar `PR.PR_PKG_REPRESTAMOS`.
- Poder ejecutar `UPDATE` sobre `PA.PA_PARAMETROS_MVP`.
- Poder crear tablas auxiliares en tu usuario actual.
- El indice `PR.IDX_GARANTIAS_TIPO_SB` debe existir.

Si alguno de esos puntos falla en `DESARROLLO`, detente y pasame exactamente el error.

---

## Criterio de aprobacion

Se considera aprobada la equivalencia funcional de OPT-015 si:

1. `06_COMPARAR_EQUIVALENCIA_CANCELADOS_OPT015.sql` devuelve:
   - 0 filas en exclusivas de `PR_REPRESTAMOS`
   - 0 filas en diferencias de `PR_REPRESTAMOS`
   - 0 filas en diferencias de `PR_SOLICITUD_REPRESTAMO`
   - 0 filas en diferencias de `PR_CANALES_REPRESTAMO`
   - 0 filas en diferencias de `PR_OPCIONES_REPRESTAMO`
   - 0 filas en diferencias de `PR_BITACORA_REPRESTAMO`
2. `05_MEDIR_JOB_CANCELADO_DETALLADO.sql` muestra mejora de tiempo en `Paso 5`, `Paso 6` y total.

---

## Paso a paso

### Paso 1. Verificar o crear el indice

Ejecuta `01_CREAR_INDICE_IDX_GARANTIAS_TIPO_SB.sql` solo si el indice no existe.

Verificacion:

```sql
SELECT INDEX_NAME, STATUS
FROM ALL_INDEXES
WHERE OWNER = 'PR'
  AND INDEX_NAME = 'IDX_GARANTIAS_TIPO_SB';
```

Esperado: `1` fila y `STATUS = VALID`.

### Paso 2. Preparar el entorno de prueba

Ejecuta `02_SETUP_EQUIVALENCIA_OPT015.sql`.

Ese script hace lo siguiente:

- crea tablas auxiliares en tu usuario
- respalda `LOTE_DE_CARAGA_REPRESTAMO`
- sube temporalmente el lote a `500` para quitar la variabilidad por `ROWNUM`
- muestra parametros relevantes
- te avisa si ya hay filas creadas hoy por tu usuario

Si `RE_HOY_USUARIO > 0`, limpia o usa otro usuario antes de continuar.

### Paso 3. Compilar el body ANTES

1. Abre `body_ANTES_OPT015.sql`
2. Compila completo
3. Verifica que no haya errores

Chequeo recomendado:

```sql
SELECT COUNT(*)
FROM ALL_SOURCE
WHERE OWNER = 'PR'
  AND NAME = 'PR_PKG_REPRESTAMOS'
  AND TYPE = 'PACKAGE BODY'
  AND TEXT LIKE '%OPT-015%';
```

Esperado: `0`.

### Paso 4. Ejecutar el run ANTES

Abre `03_EJECUTAR_CADENA_CANCELADOS_OPT015.sql` y cambia:

```sql
DEFINE RUN_LABEL = ANTES
```

Ejecutalo completo.

Ese script:

- corre solo la cadena relevante para cancelados
- captura los `ID_REPRESTAMO` generados por ese run
- ejecuta la parte local posterior de solicitud y bitacora
- guarda snapshots de:
  - `PR_REPRESTAMOS`
  - `PR_SOLICITUD_REPRESTAMO`
  - `PR_CANALES_REPRESTAMO`
  - `PR_OPCIONES_REPRESTAMO`
  - `PR_BITACORA_REPRESTAMO`

Guarda evidencia del resumen final del run.

### Paso 5. Medir rendimiento ANTES

Con el body ANTES aun compilado, ejecuta `05_MEDIR_JOB_CANCELADO_DETALLADO.sql`.

Anota:

- Paso 5
- Paso 6
- Total

### Paso 6. Limpiar solo los datos funcionales del run ANTES

Abre `04_LIMPIAR_RUN_EQUIVALENCIA_OPT015.sql` y deja:

```sql
DEFINE RUN_LABEL = ANTES
```

Ejecutalo completo.

Importante:

- este script borra solo las filas funcionales creadas por ese run
- no borra los snapshots auxiliares, porque se necesitan para comparar luego

### Paso 7. Compilar el body DESPUES

1. Abre `body_DESPUES_OPT015.sql`
2. Compila completo
3. Verifica que no haya errores

Chequeo recomendado:

```sql
SELECT COUNT(*)
FROM ALL_SOURCE
WHERE OWNER = 'PR'
  AND NAME = 'PR_PKG_REPRESTAMOS'
  AND TYPE = 'PACKAGE BODY'
  AND TEXT LIKE '%OPT-015%';
```

Esperado: mayor que `0`.

### Paso 8. Ejecutar el run DESPUES

Abre `03_EJECUTAR_CADENA_CANCELADOS_OPT015.sql` y cambia:

```sql
DEFINE RUN_LABEL = DESPUES
```

Ejecutalo completo y guarda el resumen final.

### Paso 9. Medir rendimiento DESPUES

Con el body DESPUES compilado, ejecuta `05_MEDIR_JOB_CANCELADO_DETALLADO.sql`.

Anota:

- Paso 5
- Paso 6
- Total

### Paso 10. Comparar equivalencia funcional

Abre `06_COMPARAR_EQUIVALENCIA_CANCELADOS_OPT015.sql` y verifica:

```sql
DEFINE RUN_LABEL_BASE = ANTES
DEFINE RUN_LABEL_TEST = DESPUES
```

Ejecutalo completo.

Interpretacion:

- si todas las secciones devuelven `0` filas, la equivalencia queda aprobada
- si alguna seccion devuelve filas, revisa exactamente en cual tabla aparece la diferencia

### Paso 11. Restaurar el parametro de lote

Ejecuta `07_RESTAURAR_PARAMETRO_LOTE_OPT015.sql`.

### Paso 12. Limpieza final opcional del run DESPUES

Si no quieres dejar datos funcionales del run en `PR`, ejecuta:

```sql
DEFINE RUN_LABEL = DESPUES
```

en `04_LIMPIAR_RUN_EQUIVALENCIA_OPT015.sql`.

---

## Recomendaciones

- Ejecuta ANTES y DESPUES lo mas pegado posible en tiempo.
- No uses esta prueba como gate de `WORLD_COMPLIANCE` o `XCORE`.
- Si el run inserta `0` filas, revisa:
  - `PRECAL_DIAS_PROCESAR`
  - estado de los datos fuente
  - si hay residuos de una corrida previa
- Si la comparacion falla solo en bitacora, revisa si la diferencia viene de `observaciones` o de conteo del mismo estado.

---

## Resultado que deberias poder afirmar si pasa todo

> En DESARROLLO, con el lote controlado y comparacion por llave de negocio,
> OPT-015 mantiene equivalencia funcional para la cadena local de cancelados
> (`PR_REPRESTAMOS`, `PR_OPCIONES_REPRESTAMO`, `PR_SOLICITUD_REPRESTAMO`,
> `PR_CANALES_REPRESTAMO` y `PR_BITACORA_REPRESTAMO`) y al mismo tiempo mejora
> el rendimiento de `Precalifica_Repre_Cancelado` y `Precalifica_Repre_Cancelado_hi`.
