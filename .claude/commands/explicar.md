# explicar

Explica un objeto Oracle usando `docs/instrucciones_ai/BASE_OPERATIVA.md` como fuente de verdad y la referencia por tipo de objeto que corresponda en `docs/instrucciones_ai/referencias/`.

**Argumento:** `$ARGUMENTS`

## Reglas mínimas
- Si no se especifica entorno, preguntarlo antes de leer el objeto.
- Leer el objeto completo. Si es package, leer `spec.sql` y `body.sql`.
- Responder en español, de forma técnica y corta.
- Citar siempre `archivo + líneas exactas`.
- Si hay diferencias relevantes con otro entorno, avisarlo.
- Si falta una dependencia, detenerse y pedirla.
