# optimizar_objeto

## Cuándo usarlo
Cuando quieras que Codex diagnostique y proponga optimizaciones sin cambiar la lógica de negocio original.

## Prompt base
```text
Analiza el objeto Oracle [NOMBRE_O_RUTA] en el entorno [ENTORNO] para optimización.

Objetivo: optimizar el proceso sin cambiar la lógica de negocio original.
Primero diagnostica y propone; no apliques cambios todavía.
Lee el objeto completo.
Analiza alcance interno e impacto externo.
Entrega hallazgos priorizados con impacto, riesgo y esfuerzo.
No cambies la spec ni la interfaz pública.
Incluye archivo y líneas exactas.
Deja pasos concretos de validación en Toad.
```

## Ejemplo
```text
Analiza el package PR_PKG_REPRESTAMOS en QA para optimización.

Objetivo: optimizar el proceso sin cambiar la lógica de negocio original.
Primero diagnostica y propone; no apliques cambios todavía.
Lee el spec y el body completos.
Analiza alcance interno e impacto externo.
Entrega hallazgos priorizados con impacto, riesgo y esfuerzo.
No cambies la spec ni la interfaz pública.
Incluye archivo y líneas exactas.
Deja pasos concretos de validación en Toad.
```
