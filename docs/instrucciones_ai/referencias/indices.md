# indices

## Qué leer
- DDL del índice
- tabla asociada
- queries o procesos que pretende acelerar

## Dependencias a buscar
- columnas indexadas
- queries consumidoras
- relación con constraints

## Qué validar
- tipo de índice
- selectividad esperada
- diferencias por entorno si cambian planes o nombres

## Plantilla de respuesta
1. Qué índice es
2. Sobre qué columnas actúa
3. Qué consultas puede beneficiar
4. Riesgos o costo
5. Validación en Toad

## Reglas de optimización
- no proponer índices sin relacionarlos con consultas concretas
- considerar costo de mantenimiento y DML
- separar evidencia del repo de la validación real en base

## Tips de Toad
- usar Explain Plan y estadísticas para validar uso real
