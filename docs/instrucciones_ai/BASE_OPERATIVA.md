# BASE_OPERATIVA

## Propósito
Esta es la fuente de verdad compartida para trabajar con Claude y Codex en `ADEMI_BD`. Define reglas operativas, límites, flujos y trazabilidad para análisis, explicación, optimización e incorporación manual de objetos Oracle.

## Archivos que dependen de esta base
- `AGENTS.md`
- `CLAUDE.md`
- `.claude/commands/*.md`
- `docs/prompts_codex/*.md`
- `docs/instrucciones_ai/referencias/*.md`

## Memoria operativa (engram)
La memoria del proyecto vive en el repo (texto plano + git), sin herramientas externas, para poder
reconstruirla en cualquier máquina (incluida la PC del trabajo, que no instala software).
- **Al iniciar la sesión**, leer `docs/memoria/CONTEXTO_ACTUAL.md` (estado vivo, casos abiertos,
  pendientes, reglas duras). Es el único punto de entrada obligatorio.
- **Al cerrar trabajo relevante**, agregar una entrada en `docs/memoria/BITACORA.md` (más reciente
  arriba; usar la plantilla `docs/memoria/_plantillas/ENTRADA_BITACORA.md`) y, si cambió el panorama,
  actualizar `CONTEXTO_ACTUAL.md`.
- En Claude Code (web) el hook `SessionStart` (`.claude/hooks/session-start.sh`) recuerda esto
  automáticamente. Detalle en la skill `memoria-engram`.

## Higiene de contexto (qué cargar y qué NO)
Cargar poco y relevante. Capas:
- **Caliente (siempre):** `docs/memoria/CONTEXTO_ACTUAL.md`.
- **Tibio (solo el ítem puntual):** un objeto Oracle concreto, el `README.md`/`ESTADO.md` de UN caso.
- **Frío (NO leer salvo orden explícita):** `backups/`, `_cuarentena/`, `diff/`, `ENTORNOS_ORACLE/**`
  en bloque y `docs/notas/NOTAS_HISTORICO.md` completo (para este último usar
  `docs/notas/INDICE_NOTAS_HISTORICO.md` y saltar a la línea exacta).
No hacer glob de un schema entero ni abrir volcados de cientos de KB "por las dudas": ensucia el
contexto y degrada las respuestas. Localizar por índice/grep y leer lo puntual.

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
  - `historias/_promociones/` guarda un archivo por cada evento de pase entre entornos (auditable, no se mueve aunque la historia cambie de estado).
- `diff/` almacena comparaciones before/after
- `docs/` contiene guías, QA, profiler, notas y documentación complementaria
- `docs/memoria/` guarda la memoria operativa: `CONTEXTO_ACTUAL.md` (snapshot vivo, punto de entrada) y `BITACORA.md` (diario append-only)
- `backups/` almacena material legado o de respaldo
- `_cuarentena/` guarda archivos dudosos o huérfanos pendientes de clasificar (no se borran ni renombran; ver `_cuarentena/INDICE.md`)

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

## Compuerta de promoción a PROD (anti-regresión)
Regla de la fuente de verdad para evitar la pérdida silenciosa de lógica al promover cambios.
Detalle operativo en `docs/guias/RUNBOOK_PROMOCION_PROD.md`.
- `ENTORNOS_ORACLE/<ENTORNO>/schemas/<SCHEMA>/<tipo>/<OBJETO>.sql` es el espejo de **lo que está VIVO** en ese entorno; no borradores ni variantes.
- Un objeto **no puede desplegarse** a un entorno si antes no se extrajo su baseline VIVO a ese archivo espejo (Toad: `DBMS_METADATA.GET_DDL`).
- **Un solo canónico por objeto/entorno.** Variantes (`_OLD`, `copy`, `_ORIGINAL`, `BACKUP`, `_v1`, `_TEST`) van a `backups/sombras_consolidadas/`, nunca dentro de `schemas/`.
- Cada archivo lleva **cabecera de procedencia** (`docs/instrucciones_ai/PLANTILLA_CABECERA_PROCEDENCIA.sql`).
- No se compara texto a ojo: se llena un **inventario semántico** (`docs/guias/PLANTILLA_INVENTARIO_SEMANTICO.md`); no se firma con ítems `ELIMINADO` sin justificación.
- Antes de promover: correr `git log -- <archivo>` y leer **todas** las historias que tocaron el objeto (reconciliar líneas paralelas).
- Un cambio **no está promovido a PROD** hasta tener entrada en `ENTORNOS_ORACLE/Produccion/CHANGELOG.md` con el sha del baseline + el inventario firmado, y haber re-extraído de PROD para confirmar (checklist `docs/guias/CHECKLIST_DEPLOY_PROD.md`).
- Toda historia debe listar en "Objetos afectados" los archivos **reales** que toca (verificable contra `git diff` de la historia).

## Flujos formalizados
- explicar
- optimizar
- comparar entornos
- incorporar objeto
- documentar historia
- preparar validación en Toad
- promover a PROD (runbook + checklist + inventario semántico)

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
- `2026-06-05` - Se añadió la memoria operativa (engram) en `docs/memoria/` (CONTEXTO_ACTUAL + BITACORA), la skill `memoria-engram`, el hook `SessionStart`, el modelo de higiene de contexto (capas caliente/tibio/frío) y la carpeta `_cuarentena/`. Origen: revisión de organización de directorios para agilizar el uso en Claude Code y Codex entre máquinas.
- `2026-04-16` - Se consolidó la base común para Claude y Codex, con entorno obligatorio, optimización orientada a propuesta primero y nueva estructura en `docs/instrucciones_ai/`.
- `2026-05-19` - Reorganización de `historias/` por tipo y estado (produccion / probados_no_promovidos / descartados / diagnosticos / propuestas / soporte). Se agregó `INVENTARIO.md` maestro, plantilla `ESTADO.md` y regla de movimiento por cambio de estado.
- `2026-06-02` - Se añadió la compuerta de promoción a PROD (anti-regresión): baseline VIVO versionado por entorno, un solo canónico por objeto, cabecera de procedencia, inventario semántico, checklist de deploy y runbook. Origen: incidente de regresión en `PR.PR_V_ENVIO_REPRESTAMOS`.
