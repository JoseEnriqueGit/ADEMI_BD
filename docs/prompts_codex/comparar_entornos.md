# comparar_entornos

## Cuándo usarlo
Cuando quieras contrastar un objeto entre `QA` y `DESARROLLO`.

## Prompt base
```text
Compara el objeto Oracle [NOMBRE_O_RUTA] entre QA y DESARROLLO.

Lee el objeto completo en ambos entornos.
Incluye diferencias relevantes con archivo y líneas exactas.
Si es útil, compara también las dependencias inmediatas.
Quiero un resumen técnico y corto.
Destaca cualquier diferencia que pueda impactar lógica, performance o validación.
```

## Ejemplo
```text
Compara el package PR_PKG_REPRESTAMOS entre QA y DESARROLLO.

Lee el spec y el body completos en ambos entornos.
Incluye diferencias relevantes con archivo y líneas exactas.
Si es útil, compara también las dependencias inmediatas.
Quiero un resumen técnico y corto.
Destaca cualquier diferencia que pueda impactar lógica, performance o validación.
```
