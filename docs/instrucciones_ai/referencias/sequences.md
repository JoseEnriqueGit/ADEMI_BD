# sequences

## Qué leer
- definición de la sequence
- consumidores inmediatos si son relevantes

## Dependencias a buscar
- tablas o procedures que usan `NEXTVAL` o `CURRVAL`

## Qué validar
- propósito
- consistencia con el objeto consumidor
- diferencias entre entornos cuando afecten pruebas

## Plantilla de respuesta
1. Qué genera
2. Quién la usa
3. Riesgos o consideraciones
4. Validación sugerida

## Reglas de optimización
- normalmente no requieren optimización aislada
- evaluar siempre el contexto de consumo

## Tips de Toad
- revisar metadata y consumidores con búsqueda global
