# optimizaciones/

Casos de optimizacion de objetos Oracle. Cada caso conserva su `README.md` original; el estado operativo vive en `ESTADO.md` por carpeta y en [historias/INVENTARIO.md](../INVENTARIO.md).

## Estados

- [produccion/](produccion/) — en PROD. Hoy solo: pase de [INDICES_2026-04-23/](produccion/INDICES_2026-04-23/).
- [probados_no_promovidos/](probados_no_promovidos/) — codigo probado en QA/QA02/DESARROLLO, sin pase a PROD.
- [descartados/](descartados/) — no entregaron beneficio o fueron reemplazados. Artefactos preservados.
- [diagnosticos/](diagnosticos/) — mediciones, explain plans, equivalencias. No modifican objetos productivos.
- [propuestas/](propuestas/) — propuestas documentadas, pendientes de aprobacion.
- [soporte/](soporte/) — material reusable: scripts de medicion, mapa de jobs, listas de pendientes, plan de sesion.

## Regla de movimiento

Cuando un caso cambia de estado:
1. `git mv` la carpeta a la nueva categoria.
2. Actualizar `ESTADO.md` (fecha, estado, decision).
3. Actualizar `historias/INVENTARIO.md`.
4. Si paso a PROD, registrar en `ENTORNOS_ORACLE/Produccion/CHANGELOG.md` en el mismo commit.
