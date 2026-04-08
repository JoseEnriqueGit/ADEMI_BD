# Propuestas de Optimizacion

> Optimizaciones identificadas y analizadas que requieren aprobacion antes de implementarse.
> Cada propuesta incluye el analisis completo, scripts de prueba y el trade-off involucrado.

---

| ID | SQL Quest | Descripcion | Cost Antes -> Despues | Trade-off | Estado |
|----|-----------|-------------|----------------------|-----------|--------|
| SQL371 | SQL 371 | Hardcodeo de estados en CUR_Anular_creditos_cancelados | 9,748 -> 26 | Parametros hardcodeados | Pendiente aprobacion |
| ANULAR | CUR_Anular + CUR_Anular_campana_especiales | Hardcodeo de estados en 2 cursores adicionales | 953+997 -> 18+18 | Mismo trade-off que SQL371 | Pendiente aprobacion |
