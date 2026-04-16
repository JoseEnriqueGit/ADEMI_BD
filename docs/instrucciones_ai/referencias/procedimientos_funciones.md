# procedimientos_funciones

## Qué leer
- archivo completo del procedure o function
- firma, variables, excepciones y SQL interno

## Dependencias a buscar
- tablas, vistas y packages invocados
- parámetros de entrada y salida
- puntos de transacción

## Qué validar
- propósito exacto
- entradas, salidas y efectos secundarios
- diferencias relevantes entre entornos

## Plantilla de respuesta
1. Qué hace
2. Qué recibe y devuelve
3. Qué lee o escribe
4. Flujo interno
5. Riesgos y validación

## Reglas de optimización
- diagnosticar antes de tocar
- revisar loops, SQL repetitivo, `COUNT(*)`, `NOT IN`, excepciones silenciosas
- preservar contrato y resultado funcional

## Tips de Toad
- ejecutar pruebas controladas desde editor SQL
- revisar profiler y DBMS Output cuando aplique
