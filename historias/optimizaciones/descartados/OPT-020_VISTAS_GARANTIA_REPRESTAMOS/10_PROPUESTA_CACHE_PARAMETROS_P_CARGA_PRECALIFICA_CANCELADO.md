# OPT-020 - Propuesta cache parametros P_Carga_Precalifica_Cancelado

Entorno: QA02

Objeto: `PR.PR_PKG_REPRESTAMOS`

Archivo analizado:

- `body_actual_QA02_tracking/body_actual_QA02.sql`
- `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/spec.sql`

## Diagnostico

La `spec` expone `PVALIDA_XCORE`, `F_Obt_Parametro_Represtamo`,
`F_Obt_Valor_Parametros`, `F_Obt_Parametro_Represtamo_Raw`,
`F_Obt_Empresa_Represtamo` y `P_Carga_Precalifica_Cancelado`; no se propone
cambio de `spec`.

`F_Obt_Parametro_Represtamo` consulta `PA_PARAMETROS_MVP` por cada llamada.
`F_Obt_Valor_Parametros` llama esa funcion y separa valores comma-separated en
cada invocacion. `F_Obt_Empresa_Represtamo` solo retorna la constante
`vCodigoEmpresa`.

El orquestador `P_Carga_Precalifica_Cancelado` tiene tracking persistente por
paso, por lo que el orden final debe salir de `Q02` y `Q04` de
`08_CONSULTAR_TRACKING_JOB_PRECALIFICA_RD.sql`. En el repo no hay export de
tiempos de `PR.PR_JOB_PRECALIFICA_TRACK`, asi que esta propuesta prioriza los
pasos instrumentados que contienen consultas repetidas y que pertenecen al
flujo objetivo:

1. Paso 5: `Precalifica_Repre_Cancelado`.
2. Paso 6: `Precalifica_Repre_Cancelado_hi`.
3. Paso 12: `LOOP_FINAL_VALIDACIONES_BITACORA`.
4. Pasos 8, 9 y 11 solo si el tracking los rankea por encima de 5/6/12.

`PVALIDA_XCORE` esta comentado en el orquestador y debe permanecer asi.

## Candidatos priorizados

| Prioridad | Candidato | Evidencia | Impacto | Riesgo | Esfuerzo |
|-----------|-----------|-----------|---------|--------|----------|
| 1 | Scalars de `Precalifica_Repre_Cancelado`: `LOTE_DE_CARAGA_REPRESTAMO`, `MAX_INTENTOS_PIN`, `MAX_INTENTOS_IDENTIFICACION`, `DIAS_CANCELACION`, `MESES_MAX_X_DESEMBOLSO`, `PERSONA_FISICA`, `CLIENTES_A_SOLA_FIRMA`, `PRECAL_DIA_ATRASO_TC`, `PRECAL_DESEMBOLSO_PR`, `PRECAL_MORA_MAYOR_PR` | `body_actual_QA02.sql:395-396`, `body_actual_QA02.sql:415`, `body_actual_QA02.sql:422`, `body_actual_QA02.sql:434`, `body_actual_QA02.sql:446`, `body_actual_QA02.sql:477`, `body_actual_QA02.sql:556`, `body_actual_QA02.sql:685-696`, `body_actual_QA02.sql:713` | Medio/alto si paso 5 domina | Bajo | Medio |
| 2 | Mismos scalars en `Precalifica_Repre_Cancelado_hi` | `body_actual_QA02.sql:778-779`, `body_actual_QA02.sql:797`, `body_actual_QA02.sql:803`, `body_actual_QA02.sql:816`, `body_actual_QA02.sql:828`, `body_actual_QA02.sql:859`, `body_actual_QA02.sql:924`, `body_actual_QA02.sql:1051-1062`, `body_actual_QA02.sql:1080` | Medio si paso 6 trae volumen | Bajo | Medio |
| 3 | Listas de `F_Obt_Valor_Parametros`: `PERIODOS_CUOTA`, `ESTADOS_CREDITOS`, `NACIONALIDAD`, `TIPO_DOCUMENTO`, `ESTADOS_NO_REPROCESO` | `body_actual_QA02.sql:417-418`, `body_actual_QA02.sql:435`, `body_actual_QA02.sql:451-452`, `body_actual_QA02.sql:458`; historico en `body_actual_QA02.sql:799-800`, `body_actual_QA02.sql:817`, `body_actual_QA02.sql:833-834`, `body_actual_QA02.sql:840` | Alto si el optimizador ejecuta la funcion por fila | Medio | Medio/alto |
| 4 | Booleanos del loop final: `F_Existe_Solicitudes`, `F_Existe_Canales`, `F_Existe_Credito` por cada id | Llamadas repetidas en `body_actual_QA02.sql:8237-8256`; funciones hacen `COUNT(1)` en `body_actual_QA02.sql:9599-9602`, `body_actual_QA02.sql:9614-9618`, `body_actual_QA02.sql:9628-9631` | Medio si paso 12 aparece alto | Bajo | Bajo |
| 5 | `F_Obt_Empresa_Represtamo` en SQL masivo | Funcion solo retorna constante en `body_actual_QA02.sql:4312-4315`; aparece en cursores/filtros como `body_actual_QA02.sql:428`, `body_actual_QA02.sql:809` | Bajo/medio | Bajo | Bajo |
| 6 | Parametros de pasos 8, 9 y 11 | Paso 9 usa `LOTE_PROCESO_XCORE` en `body_actual_QA02.sql:3317` y `body_actual_QA02.sql:3374`; paso 11 usa `LOTE_PROCESO_WORLD_COMPLIANCE` y `WORLD_COMPLIANCE` en `body_actual_QA02.sql:3760`, `body_actual_QA02.sql:3828`, `body_actual_QA02.sql:3879`; paso 8 usa `DE08_SIB`, `CASTIGOS_SIB`, `CLASIFICACION_SIB` en `body_actual_QA02.sql:2621`, `body_actual_QA02.sql:2637`, `body_actual_QA02.sql:2739` | Depende del ranking | Bajo/medio | Bajo/medio |

## Snippet A - Scalars para `Precalifica_Repre_Cancelado`

No ejecutar directo. Es guia de reemplazo conservador.

```sql
-- En la declaracion local de Precalifica_Repre_Cancelado, agregar:
v_lote_carga              NUMBER;
v_max_intentos_pin        PR.PR_REPRESTAMOS.INTENTOS_PIN%TYPE;
v_max_intentos_ident      PR.PR_REPRESTAMOS.INTENTOS_IDENTIFICACION%TYPE;
v_dias_cancelacion        NUMBER;
v_meses_max_desembolso    NUMBER;
v_persona_fisica          VARCHAR2(4000);
v_clientes_sola_firma     VARCHAR2(4000);
v_precal_desembolso_pr    NUMBER;
v_obs_desembolso_pr       VARCHAR2(4000);
v_precal_mora_mayor_pr    NUMBER;
```

```sql
-- Cambiar cursor:
CURSOR CREDITOS_PROCESAR (
    P_FECHA_CORTE           DATE,
    P_LOTE_CARGA            NUMBER,
    P_MAX_INTENTOS_PIN      PR.PR_REPRESTAMOS.INTENTOS_PIN%TYPE,
    P_MAX_INTENTOS_IDENT    PR.PR_REPRESTAMOS.INTENTOS_IDENTIFICACION%TYPE,
    P_DIAS_CANCELACION      NUMBER,
    P_MESES_MAX_DESEMBOLSO  NUMBER,
    P_PERSONA_FISICA        VARCHAR2,
    P_CLIENTES_SOLA_FIRMA   VARCHAR2
) IS
```

Reemplazos dentro del cursor:

```sql
P_MAX_INTENTOS_PIN INTENTOS_PIN,
P_MAX_INTENTOS_IDENT INTENTOS_IDENTIFICACION,
...
WHERE ROWNUM <= P_LOTE_CARGA
...
WHERE d.F_CANCELACION >= SYSDATE - P_DIAS_CANCELACION
...
AND C.F_PRIMER_DESEMBOLSO > ADD_MONTHS(SYSDATE, - P_MESES_MAX_DESEMBOLSO)
...
AND ES_FISICA = P_PERSONA_FISICA
...
AND P_CLIENTES_SOLA_FIRMA = 'S'
```

Inicializar una vez antes de `OPEN CREDITOS_PROCESAR`:

```sql
v_lote_carga           := TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('LOTE_DE_CARAGA_REPRESTAMO'));
v_max_intentos_pin     := PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('MAX_INTENTOS_PIN');
v_max_intentos_ident   := PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('MAX_INTENTOS_IDENTIFICACION');
v_dias_cancelacion     := TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('DIAS_CANCELACION'));
v_meses_max_desembolso := TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('MESES_MAX_X_DESEMBOLSO'));
v_persona_fisica       := PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('PERSONA_FISICA');
v_clientes_sola_firma  := PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO('CLIENTES_A_SOLA_FIRMA');
v_precal_desembolso_pr := TO_NUMBER(OBT_PARAMETROS('1', 'PR', 'PRECAL_DESEMBOLSO_PR'));
v_obs_desembolso_pr    := 'EL CLIENTE TIENE OTRO PRESTAMO DESEMBOLSADO EN LOS ULTIMOS ' ||
                          v_precal_desembolso_pr || ' MESES';
v_precal_mora_mayor_pr := TO_NUMBER(OBT_PARAMETROS('1', 'PR', 'PRECAL_MORA_MAYOR_PR'));
```

Abrir el cursor:

```sql
OPEN CREDITOS_PROCESAR(
    v_fecha_corte,
    v_lote_carga,
    v_max_intentos_pin,
    v_max_intentos_ident,
    v_dias_cancelacion,
    v_meses_max_desembolso,
    v_persona_fisica,
    v_clientes_sola_firma
);
```

Reemplazos en updates posteriores:

```sql
Y.OBSERVACIONES = v_obs_desembolso_pr
...
AND C.F_PRIMER_DESEMBOLSO > ADD_MONTHS(SYSDATE, - v_precal_desembolso_pr)
...
WHERE P.DIAS_ATRASO > v_precal_mora_mayor_pr
```

## Snippet B - Repetir patron para `Precalifica_Repre_Cancelado_hi`

Aplicar el mismo patron de Snippet A al cursor historico y a sus updates:

- `PR_CREDITOS_HI` conserva su fuente.
- `F_TIENE_GARANTIA_HISTORICO` no se reactiva ni se cambia aqui; el patch de vistas ya lo maneja por otra via.
- El `DELETE PR_REPRESTAMOS WHERE ESTADO LIKE 'X%'` queda igual.

## Snippet C - Listas de parametros

Propuesta para segundo paso, porque requiere validar compilacion con el tipo SQL
`string_table`.

```sql
v_periodos_cuota       string_table := string_table();
v_estados_creditos     string_table := string_table();
v_nacionalidad         string_table := string_table();
v_tipo_documento       string_table := string_table();
v_estados_no_reproceso string_table := string_table();
```

```sql
SELECT COLUMN_VALUE BULK COLLECT INTO v_periodos_cuota
  FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('PERIODOS_CUOTA'));

SELECT COLUMN_VALUE BULK COLLECT INTO v_estados_creditos
  FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('ESTADOS_CREDITOS'));

SELECT COLUMN_VALUE BULK COLLECT INTO v_nacionalidad
  FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('NACIONALIDAD'));

SELECT COLUMN_VALUE BULK COLLECT INTO v_tipo_documento
  FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('TIPO_DOCUMENTO'));

SELECT COLUMN_VALUE BULK COLLECT INTO v_estados_no_reproceso
  FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('ESTADOS_NO_REPROCESO'));
```

Cambiar las llamadas `TABLE(F_Obt_Valor_Parametros(...))` por
`TABLE(P_LISTA_...)` pasadas como parametros del cursor. Si compila y valida
equivalencia, aplicar tambien al cursor `_hi`.

## Snippet D - Loop final

Declarar en `P_Carga_Precalifica_Cancelado`:

```sql
v_existe_solicitud BOOLEAN;
v_existe_canal     BOOLEAN;
v_existe_credito   BOOLEAN;
```

Dentro del loop final, calcular una vez por `ID_REPRESTAMO`:

```sql
v_existe_solicitud := PR.PR_PKG_REPRESTAMOS.F_Existe_Solicitudes(V_IDS_REPRESTAMO_FINAL(I));
v_existe_canal     := PR.PR_PKG_REPRESTAMOS.F_Existe_Canales(V_IDS_REPRESTAMO_FINAL(I));
v_existe_credito   := PR.PR_PKG_REPRESTAMOS.F_Existe_Credito(V_IDS_REPRESTAMO_FINAL(I));

IF v_existe_solicitud AND v_existe_canal AND v_existe_credito THEN
    PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(V_IDS_REPRESTAMO_FINAL(I), NULL, 'NP', NULL, 'Notificacion Pendiente', USER);
ELSIF NOT v_existe_credito THEN
    PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(V_IDS_REPRESTAMO_FINAL(I), NULL, 'RXT', NULL, 'No cumple con los criterios: Tipo de Credito ', USER);
ELSIF v_existe_solicitud AND NOT v_existe_canal AND v_existe_credito THEN
    PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(V_IDS_REPRESTAMO_FINAL(I), NULL, 'CP', NULL, 'Solicitud Pendiente de Canal', USER);
ELSE
    PR.PR_PKG_REPRESTAMOS.P_Generar_Bitacora(V_IDS_REPRESTAMO_FINAL(I), NULL, 'AN', NULL, 'No cumple con los criterios: Solicitudes,Opciones', USER);
END IF;
```

## Validacion en Toad

1. Ejecutar `08_CONSULTAR_TRACKING_JOB_PRECALIFICA_RD.sql` y guardar Q02/Q04
   antes del patch.
2. Aplicar solo Snippet A y B en una copia del body, manteniendo la `spec`.
3. Compilar package body y revisar `SHOW ERRORS PACKAGE BODY PR.PR_PKG_REPRESTAMOS`.
4. Ejecutar el job normal `PR.JOB_CARGA_PRECALIFICA_RD`.
5. Re-ejecutar `08_CONSULTAR_TRACKING_JOB_PRECALIFICA_RD.sql`.
6. Comparar:
   - `segundos_total`.
   - pasos 5, 6 y 12.
   - `registros_re`.
   - errores por paso.
7. Validar equivalencia funcional con conteos antes/despues de:
   - `PR.PR_REPRESTAMOS` por `ESTADO`.
   - `PR.PR_BITACORA_REPRESTAMO` por `CODIGO_ESTADO`.
   - `PR.PR_SOLICITUD_REPRESTAMO` para ids generados en la corrida.
8. Solo si Snippet A/B pasa, evaluar Snippet C en una copia por el riesgo de
   compilacion del tipo `string_table` como parametro de cursor.

