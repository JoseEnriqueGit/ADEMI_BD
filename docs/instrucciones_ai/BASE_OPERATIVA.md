# BASE_OPERATIVA

## Propósito
Esta es la fuente de verdad compartida para trabajar con Claude y Codex en `ADEMI_BD`. Define reglas operativas, límites, flujos y trazabilidad para análisis, explicación, optimización e incorporación manual de objetos Oracle.

## Archivos que dependen de esta base
- `AGENTS.md`
- `CLAUDE.md`
- `.claude/commands/*.md`
- `docs/prompts_codex/*.md`
- `docs/instrucciones_ai/referencias/*.md`

## Idioma y estilo
- Responder siempre en español.
- Mantener nombres originales de objetos Oracle, schemas, columnas y packages.
- El estilo por defecto de explicación es técnico y corto.
- No inventar comportamiento, dependencias, tablas ni efectos.
- Cuando se presenten hallazgos o propuestas, citar siempre `archivo + líneas exactas`.

## Contexto del repositorio
- `ENTORNOS_ORACLE/` sigue la estructura `ENTORNOS_ORACLE/{ENTORNO}/schemas/{SCHEMA}/{tipo_objeto}/`
- `historias/` guarda trazabilidad por ticket, iniciativa o caso de trabajo. Organizada por tipo y estado:
  - `historias/optimizaciones/{produccion|probados_no_promovidos|descartados|diagnosticos|propuestas|soporte}/`
  - `historias/incidentes/{abiertos|diagnosticos|cerrados}/`
  - `historias/soporte_qa02/`
  - `historias/apex/{produccion|en_qa|pendientes_confirmacion|champion}/`
  - `historias/INVENTARIO.md` mantiene la tabla maestra de estados; `historias/_plantillas/ESTADO.md` es la plantilla de metadato operativo.
- `diff/` almacena comparaciones before/after
- `docs/` contiene guías, QA, profiler, notas y documentación complementaria
- `backups/` almacena material legado o de respaldo

## Regla de trazabilidad por estado
- Cada carpeta de historia tiene `README.md` (detalle técnico) y `ESTADO.md` (metadato operativo: estado, entorno, decisión).
- Al cambiar el estado de un caso, mover la carpeta a la nueva categoría con `git mv` y actualizar `ESTADO.md` y `historias/INVENTARIO.md` en el mismo commit.
- Si un caso se promueve a PROD, registrar la fila en `ENTORNOS_ORACLE/Produccion/CHANGELOG.md` en ese mismo commit.
- Los CHANGELOG por entorno (`ENTORNOS_ORACLE/{ENTORNO}/CHANGELOG.md`) son la fuente de verdad de qué está desplegado.

## Schemas más frecuentes
- `PR` - préstamos y represtamos
- `PA` - personas y administración
- `CD` - certificados
- `CC` - cuentas
- `IA` - APIs
- `TC` - tarjetas

## Regla de entornos
- Nunca asumir un entorno por defecto.
- Si el usuario no especifica entorno, preguntar antes de leer cualquier objeto Oracle.
- Si el usuario da una ruta completa o menciona explícitamente el entorno, usar ese entorno sin volver a preguntar.
- Si se detectan diferencias relevantes entre `QA` y `DESARROLLO`, avisarlo aunque no se haga una comparación completa.
- La comparación detallada entre entornos se hace cuando el flujo o la tarea lo requieran.

## Regla de lectura
- Leer siempre el objeto completo antes de explicar u optimizar.
- Si es package, leer `spec.sql` y `body.sql`.
- Si el archivo es grande, la respuesta puede resumirse, pero la lectura no se recorta.

## Dependencias faltantes
- Si falta una tabla, vista, índice, package u otra dependencia relevante, detenerse y pedirla al usuario.
- El usuario puede:
  - pegar el objeto por chat
  - pedir que se cree el archivo en el repo para pegarlo ahí
- No se debe asumir el contenido faltante.

## Incorporación manual de objetos
- Si un objeto faltante se incorpora al repo, debe ir en su ruta real según `entorno/schema/tipo_objeto`.
- No usar carpetas temporales genéricas si el destino real ya se conoce.
- El objeto debe quedar normalizado de forma completa, sin alterar su lógica.
- El archivo incorporado debe llevar una cabecera con:
  - entorno
  - schema
  - fecha
  - origen
  - motivo o caso
  - observación breve
- Si el trabajo ya tiene historia o caso, el control puede registrarse dentro de ese caso en `OBJETOS_INCORPORADOS.md` con secciones por schema.
- Si no existe historia o caso y hace falta decidir trazabilidad adicional, preguntar al usuario en ese momento.

## Explicación de objetos Oracle
### Objetivo
Explicar objetos Oracle concretos sin relleno, con enfoque técnico y corto.

### Proceso mínimo
1. Ubicar el objeto.
2. Confirmar entorno si falta.
3. Leer el objeto completo.
4. Identificar dependencias y consumidores relevantes.
5. Avisar diferencias relevantes entre entornos si las hay.
6. Responder con precisión y líneas exactas.

### Estructura sugerida
1. Resumen ejecutivo breve
2. Contexto en el sistema
3. Anatomía del objeto
4. Flujo de datos y dependencias
5. Lógica de negocio
6. Riesgos, gotchas y verificación en Toad

## Optimización de objetos Oracle
### Objetivo
Optimizar el proceso sin cambiar la lógica de negocio original.

### Reglas obligatorias
- Diagnosticar y proponer primero.
- Analizar el alcance interno y el impacto externo.
- No modificar la `spec` ni la interfaz pública salvo pedido explícito.
- No desarrollar cambios de lógica de negocio sin consultar antes al usuario.
- Solo aceptar menor legibilidad cuando haya justificación fuerte y beneficio claro.
- Priorizar propuestas con `impacto`, `riesgo` y `esfuerzo`.

### Alcance del análisis
- Código interno del objeto
- Quién llama el objeto
- Qué dependencias toca
- Qué comportamiento podría verse afectado

### Qué debe incluir una propuesta
- diagnóstico actual
- hallazgos priorizados
- alcance esperado
- impacto, riesgo y esfuerzo
- riesgos residuales
- pasos de validación en Toad

### Qué no debe hacer el asistente
- No rediseñar el negocio bajo el nombre de “optimización”.
- No tocar transacciones, semántica de errores o contratos públicos sin exponer el riesgo.
- No aplicar cambios por iniciativa propia si todavía se está en fase de diagnóstico o propuesta.

## Evidencia y documentación
- En análisis u optimizaciones relevantes, actualizar trazabilidad en `historias/` casi siempre.
- Actualizar `CHANGELOG.md` cuando aplique.
- En optimizaciones importantes, generar `ANTES`, `DESPUES` y `ROLLBACK`.
- Guardar comparaciones útiles en `diff/` cuando aporten contexto.

## Validación
- Si no se puede validar directamente en Oracle desde este entorno, dejar siempre pasos concretos de verificación en Toad.
- Separar claramente lo observado en el repo de lo que solo puede confirmarse en base de datos.

## Flujos formalizados
- explicar
- optimizar
- comparar entornos
- incorporar objeto
- documentar historia
- preparar validación en Toad

## Referencias por tipo de objeto
Usar los anexos en `docs/instrucciones_ai/referencias/`:
- `packages.md`
- `tablas.md`
- `vistas.md`
- `procedimientos_funciones.md`
- `jobs.md`
- `triggers.md`
- `sequences.md`
- `indices.md`
- `sinonimos.md`

## Historial
- `2026-04-16` - Se consolidó la base común para Claude y Codex, con entorno obligatorio, optimización orientada a propuesta primero y nueva estructura en `docs/instrucciones_ai/`.
- `2026-05-19` - Reorganización de `historias/` por tipo y estado (produccion / probados_no_promovidos / descartados / diagnosticos / propuestas / soporte). Se agregó `INVENTARIO.md` maestro, plantilla `ESTADO.md` y regla de movimiento por cambio de estado.
