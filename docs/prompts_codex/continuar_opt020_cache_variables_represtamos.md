# Prompt para continuar OPT-020 cache de variables

Trabaja en espanol y usa `docs/instrucciones_ai/BASE_OPERATIVA.md` como fuente
de verdad. Entorno confirmado: `QA02`.

Contexto:

- Historia: `historias/optimizaciones/OPT-020_VISTAS_GARANTIA_REPRESTAMOS/`
- Handoff: `historias/optimizaciones/OPT-020_VISTAS_GARANTIA_REPRESTAMOS/HANDOFF_TRACKING_QA02.md`
- Body de trabajo con tracking:
  `historias/optimizaciones/OPT-020_VISTAS_GARANTIA_REPRESTAMOS/body_actual_QA02_tracking/body_actual_QA02.sql`
- Backup antes del tracking:
  `historias/optimizaciones/OPT-020_VISTAS_GARANTIA_REPRESTAMOS/body_actual_QA02_tracking/body_actual_QA02_BEFORE_TRACKING.sql`
- Tabla de tracking:
  `PR.PR_JOB_PRECALIFICA_TRACK`
- Query de resultados:
  `historias/optimizaciones/OPT-020_VISTAS_GARANTIA_REPRESTAMOS/08_CONSULTAR_TRACKING_JOB_PRECALIFICA_RD.sql`

Situacion actual:

- Ya se creo/valido la tabla de tracking con
  `06_CREATE_TRACKING_TABLE_JOB_PRECALIFICA_RD.sql`.
- El body de trabajo ya tiene tracking persistente en
  `P_Carga_Precalifica_Cancelado`.
- No se cambio la `spec`.
- `PVALIDA_XCORE` estaba comentado en el body actual y debe permanecer asi salvo
  pedido explicito.

Tarea de la nueva sesion:

Analizar el body completo y proponer una optimizacion conservadora para colocar
en variables/cache aquellos valores que se consultan una sola vez por corrida,
son repetitivos y no cambian durante el proceso, con el objetivo de acelerar un
poco mas el job.

Reglas:

- Leer el body completo antes de proponer.
- No cambiar la `spec`.
- Diagnosticar y proponer primero antes de editar.
- No cambiar reglas de negocio.
- Citar siempre archivo + lineas exactas.
- Priorizar `P_Carga_Precalifica_Cancelado` y los procesos mas costosos segun
  `PR.PR_JOB_PRECALIFICA_TRACK`.

Buscar candidatos:

- Llamadas repetidas a `F_OBT_PARAMETRO_REPRESTAMO`.
- Llamadas repetidas a `F_Obt_Empresa_Represtamo`.
- Llamadas repetidas a `F_Obt_Valor_Parametros`.
- Consultas repetidas a `PA.PA_PARAMETROS_MVP`.
- Valores constantes por corrida usados dentro de loops masivos.

Entrega esperada:

1. Diagnostico con hallazgos priorizados.
2. Candidatos a variable/cache con impacto, riesgo y esfuerzo.
3. Propuesta de patch por snippets o archivo de trabajo, sin tocar `spec`.
4. Pasos de validacion en Toad.
