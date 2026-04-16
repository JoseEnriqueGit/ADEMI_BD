# vistas

## Qué leer
- query completa de la vista
- objetos origen usados por la vista

## Dependencias a buscar
- tablas y vistas fuente
- funciones usadas en columnas o filtros
- joins, agrupaciones y subqueries

## Qué validar
- propósito de consolidación
- filtros de negocio
- riesgo de duplicidad o cardinalidad
- diferencias entre entornos

## Plantilla de respuesta
1. Qué consolida la vista
2. De dónde salen los datos
3. Filtros y transformaciones
4. Riesgos de performance o semántica
5. Validación sugerida

## Reglas de optimización
- vigilar funciones en `WHERE`
- revisar joins costosos y subqueries repetidas
- no alterar semántica del resultado al “optimizar”

## Tips de Toad
- abrir el SQL completo y revisar plan de ejecución
- comparar el texto entre entornos cuando la salida difiera
