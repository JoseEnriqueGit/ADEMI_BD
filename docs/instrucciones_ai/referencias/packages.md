# packages

## Qué leer
- `spec.sql` completo
- `body.sql` completo
- `CHANGELOG.md` del package si existe

## Dependencias a buscar
- tablas leídas y escritas
- vistas consumidas
- packages y procedures invocados
- sequences, DB links y SQL dinámico
- `COMMIT`, `ROLLBACK`, `AUTONOMOUS_TRANSACTION`

## Qué validar
- firma pública del `spec`
- procedures y funciones relevantes
- cursores, loops y bloques de excepciones
- diferencias relevantes entre entornos

## Plantilla de respuesta
1. Resumen ejecutivo
2. Qué expone el `spec`
3. Qué implementa el `body`
4. Dependencias y flujo
5. Lógica de negocio
6. Riesgos y validación

## Reglas de optimización
- no tocar `spec` salvo pedido explícito
- analizar alcance interno y externo
- priorizar problemas de loops, cursores, commits, DML repetitivo y SQL costoso
- no cambiar reglas de negocio bajo pretexto de performance

## Tips de Toad
- Schema Browser para abrir package spec y body
- Describe o Dependencies para ver relaciones
- DBMS Profiler y Explain Plan para validar impacto
