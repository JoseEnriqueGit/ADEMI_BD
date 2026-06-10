# CONTEXTO ACTUAL — ADEMI_BD

> **Punto de entrada único del proyecto.** Si abres el repo en cualquier máquina (Claude Code en
> web, Codex, editor local), **lee este archivo primero**. Es la "memoria de trabajo": un snapshot
> vivo que se sobrescribe. El detalle cronológico vive en `docs/memoria/BITACORA.md`.
>
> Última actualización: 2026-06-09 · Mantener al día con cada cambio de estado relevante.

---

## Estado del proyecto en 5 líneas

Repositorio de objetos Oracle de ADEMI versionados por entorno/schema, más la trazabilidad de
optimizaciones (OPT), incidentes y releases APEX en `historias/`. El foco de trabajo reciente es el
paquete de alto tráfico **`PR.PR_PKG_REPRESTAMOS`** y su cadena de precalificación/represtamos.
Existe una **compuerta anti-regresión** para promover a PROD (baseline VIVO + inventario semántico).
El trabajo se hace desde dos máquinas; la PC del trabajo no puede instalar software, así que **toda
la memoria vive en el repo (git)** y se reconstruye clonando.

## Vivo en PROD (fuente de verdad: `ENTORNOS_ORACLE/Produccion/CHANGELOG.md`)

- **2026-04-23** — 8 índices de apoyo a `PR_PKG_REPRESTAMOS` (OPT-002/004/009/010/011/013/016).
- **2026-05-21** — Pase de `PR.PR_PKG_REPRESTAMOS` (spec+body), `PR.PR_V_ENVIO_REPRESTAMOS` (+ sinónimo)
  e índice `PA.IDX_PARAM_MVP_EMP_MVP_PARAM`.
- ⚠️ **Discrepancia a reconciliar:** `historias/INVENTARIO.md` aún marca como confirmado en PROD
  *solo* los 8 índices; el `CHANGELOG` de Produccion ya registra el pase del 2026-05-21. Confirmar
  contra PROD y alinear ambos.

## Abierto ahora

- 🟡 **Tracking integral precalifica QA02:** Incrementos A, B y C aplicados y PROBADOS
  (2026-06-09) en `PR.PR_PKG_REPRESTAMOS`. A: `53D427AF...` 31/31 métricas. B: `53D8BBE0...`
  cohorte del cierre 1302/1302, costo MERGE ~0.2 ms/candidato. C: `53DAC282...` pertenencia
  por flujo (1834 filas, 0 huérfanos, 317 descartados intra-flujo visibles), variante
  procedures con helper package-private `track_candidatos_flujo`.
  📌 **Decisión: `LOTE_DE_CARAGA_REPRESTAMO` queda en `1300` en QA02** (corridas de prueba
  cortas; subir a 130000 solo para corridas representativas/comparables con PROD).
  **Pendiente solo la capa DIAGNOSTICA** (propuesta separada). No promover a PROD desde
  esta historia. Ruta: `historias/soporte_qa02/TRACKING_INTEGRAL_PRECALIFICA_QA02/`.
- **Diagnostico PROD RSB/SIB:** clientes aparecen directamente en bitacora `RSB`
  con `Cliente sin clasificacion`. El body versionado muestra que las rutinas XCORE de
  carga dirigida/campana convierten todo `RE` sin bitacora `CLS` a `RSB` antes de escribir
  la bitacora `RE`, y sus cursores no filtran por origen. Hipotesis pendiente de validar:
  ausencia de los clientes en `PA.PA_DE08_SIB` al corte 2026-06-01. Script solo lectura en
  `historias/incidentes/diagnosticos/PROD_REPRESTAMOS_RSB_SIN_CLASIFICACION/`.
- 🔴 **Incidente abierto:** `INC_SNAPSHOT_TOO_OLD_JOB_PRECALIFICA` (ORA-01555, reportado 2026-05-01).
  Ruta: `historias/incidentes/abiertos/INC_SNAPSHOT_TOO_OLD_JOB_PRECALIFICA/`. Mitigación propuesta:
  OPT-017/018 (bulk collect) en DESARROLLO, pendiente de compilar en QA y monitorear en PROD.
- 🟡 **Borrador de despliegue pendiente:** `419_CANALES_HABILITADO` + regresión `PR.PR_V_ENVIO_REPRESTAMOS`
  (CASE de CANAL_DESC para canales 3 y 4). Entrada BORRADOR en `Produccion/CHANGELOG.md`, sign-off en
  `historias/419_CANALES_HABILITADO/promocion/04_SIGNOFF.md`. **No desplegado.**
- 🟡 **Baseline VIVO pendiente:** falta extraer de PROD el DDL real de `PR.PR_V_ENVIO_REPRESTAMOS`
  (espejo creado pero pendiente, ver CHANGELOG 2026-06-02).

## Pendiente de decisión (resumen — detalle en `historias/INVENTARIO.md`)

- **OPT `PROBADO_NO_PROMOVIDO`:** OPT-001 a OPT-018 (varias) — probadas en QA/QA02/DESARROLLO, sin pasar
  a PROD. OPT-020 está `DESCARTADO` (no remarcar sin aprobación explícita).
- **OPT `PROPUESTA`:** hardcodeo SQL371 + CURSORES_ANULAR.
- **APEX `PENDIENTE_CONFIRMAR`:** 375, 419, 421, 441/453/454, IRD-525, IRD-546, varias páginas 134/135, menú productos digitales.

## Reglas duras (no negociables)

1. **Idioma:** responder siempre en español; no cambiar nombres Oracle.
2. **Entorno obligatorio:** si el usuario no indica entorno, **preguntar** antes de leer objetos Oracle.
3. **Anti-regresión PROD:** ningún objeto se promueve sin baseline VIVO extraído + inventario semántico
   firmado + entrada en `Produccion/CHANGELOG.md`. Ver `docs/guias/RUNBOOK_PROMOCION_PROD.md`.
4. **Optimizar = proponer primero:** diagnosticar y proponer; no aplicar cambios de lógica sin aprobación.
5. **Git:** `git status --short` antes de tocar; no `git add .`; un commit por cambio lógico.

## Higiene de contexto — qué cargar y qué NO

| Capa | Qué es | Regla |
|---|---|---|
| 🔥 Caliente | `docs/memoria/CONTEXTO_ACTUAL.md` (este archivo) | Cargar siempre al iniciar. |
| 🌤 Tibio | `historias/INVENTARIO.md`, el objeto Oracle puntual, el `README.md`/`ESTADO.md` de UN caso | Cargar solo el ítem que pide la tarea. |
| 🧊 Frío | `backups/`, `_cuarentena/`, `diff/`, `ENTORNOS_ORACLE/**` en bloque, `docs/notas/NOTAS_HISTORICO.md` completo | **No leer salvo orden explícita.** Para `NOTAS_HISTORICO.md` usar `docs/notas/INDICE_NOTAS_HISTORICO.md` y saltar a la línea. |

> No hagas glob de un schema entero ni abras volcados de cientos de KB "por las dudas": ensucia el
> contexto y degrada las respuestas. Localiza por índice y lee lo puntual.

## Cómo retomar contexto en 3 pasos

1. Lee este archivo y, si la tarea lo pide, abre `historias/INVENTARIO.md`.
2. Abre **solo** la carpeta del caso concreto (`historias/.../<CASO>/README.md` + `ESTADO.md`).
3. Revisa `git log --oneline -20` y las últimas entradas de `docs/memoria/BITACORA.md` para ver qué
   se hizo en sesiones previas. Al cerrar trabajo relevante, **agrega una entrada en la bitácora**.

## Punteros clave

- Fuente de verdad operativa: `docs/instrucciones_ai/BASE_OPERATIVA.md`
- Tabla maestra de estados: `historias/INVENTARIO.md`
- Qué hay en PROD: `ENTORNOS_ORACLE/Produccion/CHANGELOG.md`
- Runbook de promoción: `docs/guias/RUNBOOK_PROMOCION_PROD.md`
- Objetos críticos: `docs/instrucciones_ai/INVENTARIO_OBJETOS_CRITICOS.md`
- Diario de sesiones: `docs/memoria/BITACORA.md`
