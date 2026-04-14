# OPT-008: Cache de funciones F_Existe_* en P_Carga_Precalifica_Cancelado

## Objeto
- **Paquete:** PR.PR_PKG_REPRESTAMOS
- **Procedimiento:** P_Carga_Precalifica_Cancelado
- **Seccion:** Loop final `FOR A IN CUR_REPRESTAMO` (~linea 8216)
- **Entorno:** QA
- **Git commit:** 821d2f1
- **Orquestador(es):** Job1=P_Carga_Precalifica_Cancelado (paso 12 Loop Bitacora+Validaciones), Job3=P_Carga_Precalifica_Manual, Job4=P_Carga_Precalifica_Campana_Especial
- **Tipo:** Codigo (cachear resultados de funciones F_Existe_* en variables booleanas)
- **Medido real:** No (OPT-014 midio solo impacto de indices; cache no aplicado en DESA para la prueba real)

## Problema
En el loop final de `P_Carga_Precalifica_Cancelado`, las funciones `F_Existe_Solicitudes`, `F_Existe_Canales` y `F_EXISTE_CREDITO` se invocaban directamente dentro de las condiciones IF/ELSIF. Dado que la logica de ramificacion las evalua multiples veces:

- `F_Existe_Solicitudes(A.ID_REPRESTAMO)` -- llamada 2 veces (lineas 8220 y 8228)
- `F_Existe_Canales(A.ID_REPRESTAMO)` -- llamada 2 veces (lineas 8220 y 8228)
- `F_EXISTE_CREDITO(A.ID_REPRESTAMO)` -- llamada 3 veces (lineas 8220, 8225, 8228)

Cada una de estas funciones ejecuta un SELECT contra la base de datos. En el peor caso (rama ELSE), una sola iteracion del loop ejecuta **hasta 7 queries** en lugar de las 3 necesarias.

Para N registros en el cursor, esto resulta en hasta **7*N** SELECTs en lugar de **3*N**.

## Solucion
Declarar 3 variables booleanas al inicio del loop y evaluar cada funcion una sola vez por iteracion:

```plsql
v_tiene_solicitud := PR.PR_PKG_REPRESTAMOS.F_Existe_Solicitudes(A.ID_REPRESTAMO);
v_tiene_canales   := PR.PR_PKG_REPRESTAMOS.F_Existe_Canales(A.ID_REPRESTAMO);
v_tiene_credito   := PR.PR_PKG_REPRESTAMOS.F_EXISTE_CREDITO(A.ID_REPRESTAMO);
```

Luego usar las variables en todas las condiciones IF/ELSIF.

## Impacto
- **Antes:** 3 a 7 SELECTs por iteracion (dependiendo de la rama)
- **Despues:** Exactamente 3 SELECTs por iteracion (siempre)
- **Reduccion:** Hasta ~57% menos queries por iteracion en el peor caso
- **Beneficio adicional:** Codigo mas legible y mantenible

## Riesgo
- Ninguno. Las funciones son deterministas para un mismo ID_REPRESTAMO dentro de la misma iteracion. No hay efectos secundarios.

## Archivos
- `BEFORE.sql` - Loop original con llamadas directas repetidas
- `AFTER.sql` - Loop optimizado con variables cacheadas
- `rollback.sql` - Instrucciones para revertir al codigo original
