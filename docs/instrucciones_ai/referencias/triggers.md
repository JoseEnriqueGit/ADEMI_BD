# triggers

## Qué leer
- código completo del trigger
- tabla o evento asociado

## Dependencias a buscar
- tablas afectadas
- packages o funciones invocadas
- uso de variables `:NEW` y `:OLD`

## Qué validar
- evento disparador
- efectos secundarios
- riesgo transaccional y de recursión
- diferencias entre entornos

## Plantilla de respuesta
1. Cuándo dispara
2. Qué hace
3. Qué toca
4. Riesgos
5. Validación en Toad

## Reglas de optimización
- priorizar claridad sobre “micro-optimizaciones”
- revisar operaciones pesadas dentro del trigger
- no cambiar comportamiento de auditoría o integridad sin consulta

## Tips de Toad
- probar DML controlado sobre la tabla
- revisar efectos secundarios y errores de compilación
