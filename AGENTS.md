# AGENTS.md

Usa `docs/instrucciones_ai/BASE_OPERATIVA.md` como fuente de verdad del proyecto.

## Notas específicas para Codex
- Trabajar siempre en español.
- Si el usuario no indica entorno, preguntar antes de leer cualquier objeto Oracle.
- Para análisis u optimización, leer el objeto completo. Si es package, leer `spec.sql` y `body.sql`.
- En optimización, diagnosticar y proponer primero. No cambiar la lógica de negocio ni la `spec` salvo pedido explícito.
- Citar siempre `archivo + líneas exactas` cuando se expliquen hallazgos o propuestas.
- Si falta una dependencia, pedirla al usuario; puede pegarla por chat o incorporarse en la ruta real del repo.
- Los prompts listos para Codex viven en `docs/prompts_codex/`.
- Las referencias por tipo de objeto viven en `docs/instrucciones_ai/referencias/`.
