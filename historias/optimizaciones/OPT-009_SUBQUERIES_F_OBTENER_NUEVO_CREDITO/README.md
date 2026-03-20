# OPT-009 - Subqueries escalares en F_OBTENER_NUEVO_CREDITO y F_Obtener_Credito_Cancelado

- **Paquete**: PR_PKG_REPRESTAMOS
- **Funciones**: F_Obtener_Nuevo_Credito, F_Obtener_Credito_Cancelado
- **Entorno**: QA
- **Fecha**: 2026-03-19
- **SQL Quest**: SQL 385/386/391/392 (cost ~17,235)

## Problema
Tres problemas de rendimiento:

### 1. Scalar subqueries MIN/MAX (IF branch, lineas 9671-9672)
```sql
R.MTO_PREAPROBADO >= (SELECT MIN(MONTO_MIN) FROM PR_PLAZO_CREDITO_REPRESTAMO WHERE TIPO_CREDITO = T.TIPO_CREDITO)
R.MTO_PREAPROBADO <= (SELECT MAX(MONTO_MAX) FROM PR_PLAZO_CREDITO_REPRESTAMO WHERE TIPO_CREDITO = T.TIPO_CREDITO)
```
Dos subqueries ejecutadas por cada fila candidata.

### 2. OR en LEFT JOIN (ELSE branch, linea 9724)
```sql
LEFT JOIN PR_TIPO_CREDITO T ON T.TIPO_CREDITO = C.TIPO_CREDITO OR T.TIPO_CREDITO = H.TIPO_CREDITO
```
El OR impide que Oracle use indices en el JOIN.

### 3. Mismo patron MIN/MAX en F_Obtener_Credito_Cancelado (lineas 9751-9752)

## Cambios realizados

### Cambio 1: MIN/MAX -> JOIN con BETWEEN
```sql
-- ANTES:
FROM PR_TIPO_CREDITO_REPRESTAMO T, PR_REPRESTAMOS R
WHERE R.MTO_PREAPROBADO >= (SELECT MIN(MONTO_MIN) ...)
  AND R.MTO_PREAPROBADO <= (SELECT MAX(MONTO_MAX) ...)

-- DESPUES:
FROM PR_TIPO_CREDITO_REPRESTAMO T
JOIN PR_PLAZO_CREDITO_REPRESTAMO P ON P.TIPO_CREDITO = T.TIPO_CREDITO
JOIN PR_REPRESTAMOS R ON R.ID_REPRESTAMO = pIdReprestamo
WHERE R.MTO_PREAPROBADO BETWEEN P.MONTO_MIN AND P.MONTO_MAX
```

### Cambio 2: OR -> COALESCE
```sql
-- ANTES:
LEFT JOIN PR_TIPO_CREDITO T ON T.TIPO_CREDITO = C.TIPO_CREDITO OR T.TIPO_CREDITO = H.TIPO_CREDITO

-- DESPUES:
LEFT JOIN PR_TIPO_CREDITO T ON T.TIPO_CREDITO = COALESCE(C.TIPO_CREDITO, H.TIPO_CREDITO)
```

## Razonamiento
- JOIN con BETWEEN permite a Oracle evaluar la condicion de rango una sola vez usando el indice
- COALESCE permite INDEX SCAN en lugar de CONCATENATION/UNION forzado por el OR
- Un credito existe en PR_CREDITOS (activo) o PR_CREDITOS_HI (historico), no ambos, asi que COALESCE es semanticamente equivalente

## Como revertir
`git revert <commit>`
