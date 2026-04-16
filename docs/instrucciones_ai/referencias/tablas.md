# tablas

## Qué leer
- DDL completo de la tabla
- constraints, índices y claves relacionadas
- documentación o historia asociada si existe

## Dependencias a buscar
- foreign keys
- índices relevantes
- vistas, procedures o packages que la consumen

## Qué validar
- columnas clave para negocio
- nulos, defaults y restricciones
- diferencias relevantes entre entornos

## Plantilla de respuesta
1. Resumen de la tabla
2. Columnas clave
3. Restricciones e índices
4. Quién la usa
5. Riesgos de negocio o integridad
6. Validación en Toad

## Reglas de optimización
- revisar índices y patrones de acceso antes de proponer cambios
- no sugerir cambios estructurales sin medir impacto funcional
- distinguir entre problema de tabla, query o package consumidor

## Tips de Toad
- Describe para revisar metadata
- View Dependencies para consumidores
- Explain Plan sobre queries que la usan
