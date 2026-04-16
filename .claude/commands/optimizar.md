# optimizar

Optimiza un objeto Oracle usando `docs/instrucciones_ai/BASE_OPERATIVA.md` como fuente de verdad y la referencia por tipo de objeto aplicable.

**Argumento:** `$ARGUMENTS`

## Reglas mínimas
- Si no se especifica entorno, preguntarlo antes de leer el objeto.
- Leer el objeto completo antes de responder.
- Diagnosticar y proponer primero; no aplicar cambios todavía.
- Analizar alcance interno e impacto externo.
- No cambiar lógica de negocio ni `spec` salvo pedido explícito.
- Entregar hallazgos priorizados con `impacto`, `riesgo` y `esfuerzo`.
- Citar siempre `archivo + líneas exactas`.
- Dejar pasos concretos de validación en Toad.
