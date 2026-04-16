# comparar_entornos

Compara un objeto Oracle entre entornos usando `docs/instrucciones_ai/BASE_OPERATIVA.md` como fuente de verdad.

**Argumento:** `$ARGUMENTS`

## Reglas mínimas
- Comparar el objeto pedido entre `QA` y `DESARROLLO`.
- Leer el objeto completo en ambos entornos.
- Incluir dependencias inmediatas cuando sea relevante para explicar una diferencia.
- Responder en español, de forma técnica y corta.
- Citar siempre `archivo + líneas exactas`.
