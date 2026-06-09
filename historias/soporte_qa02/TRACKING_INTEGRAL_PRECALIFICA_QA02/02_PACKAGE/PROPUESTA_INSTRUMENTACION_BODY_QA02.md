# Propuesta de instrumentacion del body - Tracking integral QA02

Fecha: 2026-06-08 · Estado: **INCREMENTO A IMPLEMENTADO Y PROBADO EN QA02 EL 2026-06-09.**
Revision adversarial multiagente aplicada (14 hallazgos confirmados incorporados): gating de COUNTs por flag,
`FECHA_CORTE` poblada, desglose REAL de precalificacion (RSB/CLS/RCS/borrados), `FLUJO_RE_NETO` reetiquetado,
bloque de cierre concreto, y notas de `ORDEN_FILTRO` y paso 14.

> Este documento sirvio de base para modificar el `body.sql` canonico de
> `PR.PR_PKG_REPRESTAMOS`. El Incremento A ya esta codificado en el repo,
> compilado y probado en la base QA02. Incrementos B/C y la capa
> DIAGNOSTICA permanecen pendientes.
> La `spec.sql` no cambia. Las tablas (`PR_JOB_PRECALIFICA_FILTRO_TRACK`,
> `PR_JOB_PRECALIFICA_CANDIDATO_TRACK`) y los parametros `TRACK_PRECALIFICA_*` ya existen.

## 0. Alcance por incrementos

| Incremento | Que captura | Riesgo | Toca |
|---|---|---|---|
| **A** (este borrador, foco) | Conteos REALES a nivel de orquestacion: arranque, 5 flujos (neto RE), RE consolidado, precalificacion, XCORE, solicitud, cierre. Capa B. | Bajo | Solo el bloque del job en `P_Carga_Precalifica_Cancelado` |
| **B** | Cohorte final + `RESULTADO_ULTIMO` en el cierre (Capa C parcial, sin tocar las 5 procedures). | Bajo | El loop de cierre del mismo bloque |
| **C (diferido)** | Pertenencia por flujo capturada en el `FETCH` de cada procedure (Capa C completa). | Medio | Requiere tocar las 5 procedures -> propuesta separada |
| **DIAGNOSTICA** | Desglose por filtro interno del cursor (X3/X1/X2/mancomunado/edad y filtros combinados). | — | Los 5 scripts externos existentes, asociados al `ID_EJECUCION` |

Este borrador detalla **A** y **B**. **C** y **DIAGNOSTICA** quedan referenciados para fases siguientes.

## 1. Hallazgos del mapeo que condicionan el diseno

El mapeo del codigo real (no solo de la propuesta) revelo desviaciones que el tracking debe respetar:

1. **Arranque no opera sobre `RE`.** `P_Actualizar_Anular_Represtamo` (body 7794) solo llama
   `P_Anular_Represtamos_Inactivos`, que anula **fila por fila** (3 cursores FOR -> `p_generar_bitacora`)
   a estados `AN`/`CC` sobre el universo de los parametros `ESTADOS_ANULAR_*`, **no** sobre `ESTADO='RE'`.
   No hay `SQL%ROWCOUNT` masivo. Por eso `INI_RE_ANTES/DESPUES` se miden como `ESTADO='RE'` (linea base),
   y se espera que sean casi iguales; `INI_ANULADOS` solo es obtenible como delta de COUNTs y es aproximado.
2. **Filtros del cursor combinados.** En `Precalifica_Represtamo` (body 24-129) el lote (`ROWNUM<=LOTE`, l.56)
   y todos los filtros iniciales van en un solo cursor. Los descartes post-cursor (`X3` l.266, `X1` l.291,
   `X2` l.319, mancomunado `DELETE` l.327, edad `DELETE` l.341) terminan con `DELETE ... ESTADO LIKE 'X%'`
   (l.348). **A nivel orquestacion solo es medible el NETO**: `RE` antes/despues de cada procedure. El
   desglose por filtro es **DIAGNOSTICA** (los 5 scripts externos).
3. **XCORE casi inerte en QA02.** `Actualiza_XCORE_CUSTOM` tiene `xcore` hardcodeado a 745 (body 3404;
   consulta real a DataCredito comentada) y `PVALIDA_XCORE`/`MAX_XCORE` comentados (orq. 8283-8286, proc 3472-3476).
   -> `XCORE_CERO_NULO`/`XCORE_ERROR` ~0 por construccion y `XCORE_RECHAZADOS` debe ser **`NO_EJECUTADO`**, nunca 0.
4. **Precalificacion** (body 2587) marca `RSB` (mala clasif. SIB l.2736 y fiador l.2781), pone
   `CODIGO_PRECALIFICACION` (l.2751), **borra** los `RE` sin codigo y los OFAC (l.2800-2829), y registra
   `CLS` (l.2841) y `RCS` (castigo l.2866) via `p_generar_bitacora`. Todo medible por COUNT de estado/columna antes/despues.
5. **Solicitud** (body 7994) recorre los `RE` y por cada uno llama `P_Registrar_Solicitud` + bitacora `RE`.
   `SOL_*`/`CANAL_*` se miden por COUNT en `PR_SOLICITUD_REPRESTAMO`/`PR_CANALES_REPRESTAMO` antes/despues.
6. **Cierre** (orq. 8288-8314) decide `NP`/`CP`/`RXT`/`AN` via `P_Generar_Bitacora`. `FINAL_*` por COUNT de estado tras el loop.

## 2. Principios (propuesta seccion 6)

- Los **conteos se calculan en la transaccion principal** (con `SELECT COUNT`), nunca dentro del helper autonomo.
- El helper recibe **numeros ya calculados** y solo inserta en las tablas de tracking.
- **Transaccion autonoma** con `COMMIT` propio y `EXCEPTION WHEN OTHERS THEN ROLLBACK; NULL;` (el tracking nunca interrumpe ni hace COMMIT sobre la transaccion funcional).
- Activacion por `TRACK_PRECALIFICA_ACTIVO`; si no es `'S'`, el helper retorna sin escribir.
- **Sin cambios en la `spec`.** Todo vive dentro del bloque del job en `P_Carga_Precalifica_Cancelado` (mismo lugar que los `track_*` existentes, body ~8051-8230).

## 3. Helpers e infraestructura (a declarar junto a `track_insert_inicio`, ~body 8067)

### 3.1 Variables locales del bloque del job

Junto a `v_id_ejecucion_track` (body 8067):

```sql
v_track_activo   VARCHAR2(1)  := 'N';
v_track_detalle  VARCHAR2(1)  := 'N';
v_track_lote     NUMBER;
v_track_fcorte   DATE;
v_track_orden    NUMBER       := 0;
-- buffers de conteo reutilizables
v_re_a           NUMBER;   -- RE antes
v_re_b           NUMBER;   -- RE despues
v_aux1           NUMBER;
v_aux2           NUMBER;
v_estado_cierre  VARCHAR2(8);  -- estado asignado en el loop de cierre (Incremento B)
```

### 3.2 Lectura de flags al iniciar el job (tras `track_inicio(0,'TOTAL_JOB')`, body 8234)

```sql
BEGIN
    v_track_activo  := NVL(PR.PR_PKG_REPRESTAMOS.F_Obt_Parametro_Represtamo('TRACK_PRECALIFICA_ACTIVO'),'N');
    v_track_detalle := NVL(PR.PR_PKG_REPRESTAMOS.F_Obt_Parametro_Represtamo('TRACK_PRECALIFICA_DETALLE_CURSOR'),'N');
    v_track_lote    := TO_NUMBER(PR.PR_PKG_REPRESTAMOS.F_Obt_Parametro_Represtamo('LOTE_DE_CARAGA_REPRESTAMO'));
    BEGIN
        SELECT MAX(P.FECHA_CORTE) INTO v_track_fcorte
          FROM PA_DETALLADO_DE08 P WHERE P.FUENTE = 'PR';   -- mismo corte que alimenta el cursor (body 216-219)
    EXCEPTION WHEN OTHERS THEN v_track_fcorte := NULL; END;
EXCEPTION WHEN OTHERS THEN
    v_track_activo := 'N';   -- ante cualquier duda, tracking apagado; el job sigue normal
END;
```

### 3.3 Helper Capa B: `track_filtro` (transaccion autonoma)

```sql
PROCEDURE track_filtro(
    p_flujo         IN VARCHAR2,
    p_fase          IN VARCHAR2,
    p_codigo_filtro IN VARCHAR2,
    p_descripcion   IN VARCHAR2,
    p_tipo_medicion IN VARCHAR2 DEFAULT 'REAL',
    p_antes         IN NUMBER   DEFAULT NULL,
    p_pasan         IN NUMBER   DEFAULT NULL,
    p_descartados   IN NUMBER   DEFAULT NULL,
    p_creditos_desc IN NUMBER   DEFAULT NULL,
    p_clientes_desc IN NUMBER   DEFAULT NULL,
    p_parametros    IN VARCHAR2 DEFAULT NULL
) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    IF NVL(v_track_activo,'N') <> 'S' THEN
        RETURN;
    END IF;
    v_track_orden := v_track_orden + 1;
    INSERT INTO PR.PR_JOB_PRECALIFICA_FILTRO_TRACK
        (ID_EJECUCION, ID_DETALLE, FLUJO, FASE, ORDEN_FILTRO, CODIGO_FILTRO,
         DESCRIPCION, TIPO_MEDICION, CANDIDATOS_ANTES, CANDIDATOS_PASAN,
         CANDIDATOS_DESCARTADOS, CREDITOS_DESCARTADOS, CLIENTES_DESCARTADOS,
         VALOR_LOTE, FECHA_CORTE, PARAMETROS, FECHA_REGISTRO)
    VALUES
        (v_id_ejecucion_track, PR.SEQ_PR_JOB_PRECAL_FILTRO.NEXTVAL, p_flujo, p_fase,
         v_track_orden, p_codigo_filtro, p_descripcion, p_tipo_medicion, p_antes,
         p_pasan, p_descartados, p_creditos_desc, p_clientes_desc,
         v_track_lote, v_track_fcorte, p_parametros, SYSTIMESTAMP);
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;   -- cierra la transaccion autonoma (evita ORA-06519); nunca propaga
        NULL;
END track_filtro;
```

> Mejora sobre el patron actual: el `ROLLBACK` en el handler cierra la transaccion autonoma si el
> `INSERT` falla, evitando `ORA-06519`. `TIPO_MEDICION` siempre se envia ('REAL' o 'DIAGNOSTICA';
> para no-medibles se usa el valor centinela documentado, ver XCORE).
>
> Nota sobre `ORDEN_FILTRO`: `v_track_orden` es un **correlativo global de la corrida** (no 1-based por
> fase). El consumidor debe ordenar por `(FLUJO, FASE, ORDEN_FILTRO)`; el orden relativo dentro de una fase
> es correcto por monotonia. Si se incrementa y el `INSERT` falla puede quedar un hueco (irrelevante: la PK
> es `(ID_EJECUCION, ID_DETALLE)`). Para orden 1-based por fase, pasar `p_orden` explicito en vez del contador.

### 3.4 Helper Capa C: `track_candidato` (transaccion autonoma, MERGE idempotente)

```sql
PROCEDURE track_candidato(
    p_flujo         IN VARCHAR2,
    p_id_represtamo IN NUMBER,
    p_resultado     IN VARCHAR2
) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    IF NVL(v_track_activo,'N') <> 'S' THEN
        RETURN;
    END IF;
    MERGE INTO PR.PR_JOB_PRECALIFICA_CANDIDATO_TRACK t
    USING (SELECT v_id_ejecucion_track AS id_ej, p_flujo AS fl, p_id_represtamo AS idr FROM dual) s
       ON (t.ID_EJECUCION = s.id_ej AND t.FLUJO = s.fl AND t.ID_REPRESTAMO = s.idr)
    WHEN MATCHED THEN
        UPDATE SET t.RESULTADO_ULTIMO = p_resultado, t.FECHA_REGISTRO = SYSTIMESTAMP
    WHEN NOT MATCHED THEN
        INSERT (ID_EJECUCION, FLUJO, ID_REPRESTAMO, RESULTADO_ULTIMO, FECHA_REGISTRO)
        VALUES (s.id_ej, s.fl, s.idr, p_resultado, SYSTIMESTAMP);
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        NULL;
END track_candidato;
```

> El `MERGE` evita el `ORA-00001` por PK `(ID_EJECUCION, FLUJO, ID_REPRESTAMO)` si un candidato se toca dos veces.

## 4. Instrumentacion por fase (Incremento A)

Cada bloque va **dentro de la orquestacion** (body 8232-8322), en la transaccion principal, calculando
COUNTs y llamando `track_filtro`. Las referencias de linea son del `body.sql` actual.

> **Regla de gating (correccion de la revision):** todos los `SELECT COUNT(*)` de esta seccion deben ir
> envueltos en `IF v_track_activo = 'S' THEN ... END IF`. El guard interno de los helpers solo evita el
> `INSERT`; sin envolver los COUNT, la corrida con `TRACK_PRECALIFICA_ACTIVO='N'` igual ejecutaria ~25-30
> COUNT y **no seria** linea base real. Con el gate, OFF = body sin instrumentar. Los snippets de abajo
> omiten el `IF` por brevedad pero **es obligatorio**. (La verdadera base de comparacion sigue siendo el
> body de `04_ROLLBACK/`.)

### 4.1 Arranque (paso 1, body 8236-8238)

```sql
-- antes de 8237 (la llamada a P_Actualizar_Anular_Represtamo):
SELECT COUNT(*) INTO v_re_a FROM PR.PR_REPRESTAMOS WHERE ESTADO = 'RE';
-- ... PR.PR_PKG_REPRESTAMOS.P_Actualizar_Anular_Represtamo(pMensaje);  (linea 8237 existente)
-- despues de 8237, antes de track_fin(1) en 8238:
SELECT COUNT(*) INTO v_re_b FROM PR.PR_REPRESTAMOS WHERE ESTADO = 'RE';
track_filtro('TOTAL','ARRANQUE','INI_RE_ANTES','RE abiertos antes de anular','REAL',p_antes=>v_re_a, p_pasan=>v_re_a);
track_filtro('TOTAL','ARRANQUE','INI_RE_DESPUES','RE tras anular (linea base)','REAL',p_antes=>v_re_a, p_pasan=>v_re_b, p_descartados=>v_re_a - v_re_b);
```

> `INI_ANULADOS` exacto (AN vs CC) no es REAL sin tocar la procedure; se deja para la salida DIAGNOSTICA
> sobre `PR_BITACORA_REPRESTAMO` (`CODIGO_ESTADO IN ('AN','CC')` del dia). `INI_RE_ANTES≈INI_RE_DESPUES` es lo esperado.

### 4.2 Cinco flujos (pasos 2-6, body 8240-8258)

Patron repetido por flujo (ejemplo `Precalifica_Represtamo`, paso 2, l.8240-8242):

```sql
SELECT COUNT(*) INTO v_re_a FROM PR.PR_REPRESTAMOS WHERE ESTADO = 'RE';   -- antes de 8241
-- ... Precalifica_Represtamo();   (linea 8241 existente)
SELECT COUNT(*) INTO v_re_b FROM PR.PR_REPRESTAMOS WHERE ESTADO = 'RE';   -- despues de 8241
track_filtro('Precalifica_Represtamo','LOTE','LOTE_VALOR','Tope ROWNUM del cursor','REAL', p_parametros=>'LOTE='||v_track_lote);
track_filtro('Precalifica_Represtamo','SALIDA','RE_ACUMULADO_TRAS_FLUJO','RE global acumulado tras el flujo (NO es aporte exclusivo del flujo)','REAL', p_antes=>v_re_a, p_pasan=>v_re_b, p_descartados=>CASE WHEN v_re_b<v_re_a THEN v_re_a-v_re_b END, p_parametros=>'NETO='||(v_re_b-v_re_a));
```

Repetir para pasos 3-6 cambiando el nombre de flujo. **Nota (correccion):** `CANDIDATOS_PASAN`=`v_re_b` es el
**RE global acumulado** tras el flujo, no el aporte exclusivo del flujo (arrastra el saldo de flujos previos);
el **neto** del flujo (`v_re_b - v_re_a`, puede ser negativo) viaja en `PARAMETROS`. El bruto insertado y el
desglose `X3/X1/X2/mancomunado/edad` NO son visibles aqui (la procedure ya borro `X%`); van por DIAGNOSTICA.

### 4.3 RE consolidado (paso 7, body 8260-8264)

El job ya calcula `v_conteo` (COUNT RE). Reusarlo:

```sql
-- tras el SELECT COUNT(*) INTO v_conteo de 8262:
track_filtro('TOTAL','POST_CURSOR','RE_CONSOLIDADO','RE tras los 5 flujos','REAL', p_pasan=>v_conteo);
```

### 4.4 Precalificacion (paso 8, body 8266-8268)

```sql
SELECT COUNT(*) INTO v_re_a FROM PR.PR_REPRESTAMOS WHERE ESTADO='RE';   -- PRE_RE_ENTRADA (antes 8267)
-- ... Actualiza_Precalificacion();   (8267 existente)
SELECT COUNT(*) INTO v_re_b FROM PR.PR_REPRESTAMOS WHERE ESTADO='RE';   -- PRE_RE_SALIDA (sobrevivientes; ya todos con codigo)
SELECT COUNT(*) INTO v_aux1 FROM PR.PR_REPRESTAMOS WHERE ESTADO='RSB';            -- rechazo clasificacion/fiador
SELECT COUNT(*) INTO v_aux2 FROM PR.PR_REPRESTAMOS WHERE ESTADO IN ('CLS','RCS'); -- clasificacion SIB / castigo
track_filtro('TOTAL','PRECALIFICACION','PRE_RE_ENTRADA','RE recibidos','REAL', p_antes=>v_re_a, p_pasan=>v_re_a);
track_filtro('TOTAL','PRECALIFICACION','PRE_RSB','Rechazados clasificacion/fiador (RSB)','REAL', p_descartados=>v_aux1);
track_filtro('TOTAL','PRECALIFICACION','PRE_CLS_RCS','Clasificados SIB / castigo (CLS+RCS)','REAL', p_descartados=>v_aux2);
track_filtro('TOTAL','PRECALIFICACION','PRE_BORRADOS','Borrados sin codigo / OFAC (derivado)','REAL', p_descartados=>(v_re_a - v_re_b) - v_aux1 - v_aux2);
track_filtro('TOTAL','PRECALIFICACION','PRE_RE_SALIDA','RE que continuan (== sobrevivientes con codigo)','REAL', p_pasan=>v_re_b);
```

> **Correcciones de la revision (fidelidad):**
> - El delta `entrada - salida` **agrupa** borrados + `RSB` + `CLS` + `RCS` (todas dejan de ser `RE`). Por eso
>   `RSB` y `CLS+RCS` (estados que **sobreviven** como fila) se miden por separado y `PRE_BORRADOS` se **deriva**.
>   Asi `entrada = PRE_BORRADOS + PRE_RSB + PRE_CLS_RCS + PRE_RE_SALIDA` cierra la conciliacion.
> - Se elimino `PRE_CON_CODIGO` como metrica de embudo: `Actualiza_Precalificacion` **borra** los `RE` sin
>   codigo (body 2812-2828), asi que todo `RE` sobreviviente ya tiene codigo -> seria `== PRE_RE_SALIDA` por
>   construccion (tautologico). "Cuantos recibieron codigo" solo es medible por `PR_BITACORA_REPRESTAMO` del dia (DIAGNOSTICA).
> - El `COUNT` por estado actual asume que no hay `RSB/CLS/RCS` residuales de corridas previas; para maxima
>   fidelidad usar `PR_BITACORA_REPRESTAMO` del dia (`CODIGO_ESTADO IN ('RSB','CLS','RCS')`) -> confirmar sus columnas (seccion 7).

### 4.5 XCORE (paso 9, body 8270-8272)

```sql
SELECT COUNT(*) INTO v_aux1 FROM PR.PR_REPRESTAMOS WHERE ESTADO='RE' AND XCORE_GLOBAL IS NULL;  -- XCORE_ENTRADA (antes 8271)
-- ... Actualiza_XCORE_CUSTOM();   (8271 existente)
SELECT COUNT(*) INTO v_aux2 FROM PR.PR_REPRESTAMOS WHERE ESTADO='RE' AND XCORE_GLOBAL IS NULL;  -- pendientes despues
SELECT COUNT(*) INTO v_re_b  FROM PR.PR_REPRESTAMOS WHERE ESTADO='RE';                          -- XCORE_SALIDA
track_filtro('TOTAL','XCORE','XCORE_ENTRADA','RE pendientes de XCORE','REAL', p_antes=>v_aux1, p_pasan=>v_aux1);
track_filtro('TOTAL','XCORE','XCORE_PROCESADOS','RE actualizados con XCORE','REAL', p_pasan=>v_aux1 - v_aux2);
track_filtro('TOTAL','XCORE','XCORE_RECHAZADOS','PVALIDA_XCORE comentado en QA02','DIAGNOSTICA', p_parametros=>'NO_EJECUTADO');
track_filtro('TOTAL','XCORE','XCORE_SALIDA','RE que continuan','REAL', p_pasan=>v_re_b);
```

> Con `xcore=745` fijo, `XCORE_PROCESADOS≈XCORE_ENTRADA` y `XCORE_SALIDA≈RE_consolidado`. `XCORE_RECHAZADOS`
> se registra como `NO_EJECUTADO` (no 0) hasta que se reactiven `PVALIDA_XCORE`/`MAX_XCORE`.

### 4.6 Solicitud y canal (paso 10, body 8274-8276)

```sql
SELECT COUNT(*) INTO v_re_a FROM PR.PR_REPRESTAMOS WHERE ESTADO='RE';                              -- SOL_ENTRADA
SELECT COUNT(*) INTO v_aux1 FROM PR.PR_SOLICITUD_REPRESTAMO s WHERE EXISTS (SELECT 1 FROM PR.PR_REPRESTAMOS r WHERE r.ID_REPRESTAMO=s.ID_REPRESTAMO AND r.ESTADO='RE');  -- solicitudes previas
-- ... P_REGISTRO_SOLICITUD();   (8275 existente)
SELECT COUNT(*) INTO v_aux2 FROM PR.PR_SOLICITUD_REPRESTAMO s WHERE EXISTS (SELECT 1 FROM PR.PR_REPRESTAMOS r WHERE r.ID_REPRESTAMO=s.ID_REPRESTAMO AND r.ESTADO='RE');  -- solicitudes despues
track_filtro('TOTAL','SOLICITUD','SOL_ENTRADA','RE recibidos','REAL', p_antes=>v_re_a, p_pasan=>v_re_a);
track_filtro('TOTAL','SOLICITUD','SOL_CREADA','Solicitudes nuevas en la corrida','REAL', p_pasan=>v_aux2 - v_aux1);
-- CANAL_* analogo sobre PR.PR_CANALES_REPRESTAMO (confirmar nombre de columna de canal valido antes de fijar el predicado)
```

> Pendiente de confirmar contra el DDL real de `PR_SOLICITUD_REPRESTAMO`/`PR_CANALES_REPRESTAMO`
> (columnas y que define "canal valido"). Marcado para el script 00 de la fase de body.

### 4.7 Cierre (paso 13, body 8288-8314) + Capa C (Incremento B)

El loop final ya itera `V_IDS_REPRESTAMO_FINAL` y decide `NP/CP/RXT/AN`. Dos capturas:

```sql
-- (B) Reescribir el IF anidado del cierre (body 8297-8308) a ELSIF capturando el estado en
--     v_estado_cierre VARCHAR2(8) (declarar en 3.1) y reusarlo en bitacora y tracking.
--     id := V_IDS_REPRESTAMO_FINAL(I)
IF F_Existe_Solicitudes(id) AND F_Existe_Canales(id) AND F_EXISTE_CREDITO(id) THEN
    v_estado_cierre := 'NP';
    P_Generar_Bitacora(id, NULL, v_estado_cierre, NULL, 'Notificacion Pendiente', USER);
ELSIF F_EXISTE_CREDITO(id) = FALSE THEN
    v_estado_cierre := 'RXT';
    P_Generar_Bitacora(id, NULL, v_estado_cierre, NULL, 'No cumple con los criterios: Tipo de Credito ', USER);
ELSIF F_Existe_Solicitudes(id) AND F_Existe_Canales(id) = FALSE AND F_EXISTE_CREDITO(id) THEN
    v_estado_cierre := 'CP';
    P_Generar_Bitacora(id, NULL, v_estado_cierre, NULL, 'Solicitud Pendiente de Canal', USER);
ELSE
    v_estado_cierre := 'AN';
    P_Generar_Bitacora(id, NULL, v_estado_cierre, NULL, 'No cumple con los criterios: Solicitudes,Opciones', USER);
END IF;
track_candidato('CIERRE', id, v_estado_cierre);   -- (B) usa el estado ya asignado; no re-deriva el IF

-- (A) tras el loop (antes de track_fin(13) en 8314), conteo por estado final de la cohorte:
SELECT COUNT(*) INTO v_aux1 FROM PR.PR_REPRESTAMOS WHERE ESTADO='NP';
track_filtro('TOTAL','CIERRE','FINAL_NP','Notificacion pendiente','REAL', p_pasan=>v_aux1);
-- idem FINAL_CP / FINAL_RXT / FINAL_AN (COUNT por estado) y FINAL_OTRO para el resto
```

> La conversion del `IF` anidado a `ELSIF` conserva exactamente las mismas condiciones y mensajes; solo
> guarda el estado en `v_estado_cierre` para pasarlo a `P_Generar_Bitacora` y a `track_candidato` sin
> re-derivar la logica (hoy 8300/8303 re-evaluan `F_EXISTE_CREDITO`).

> **Paso 14 (ACTUALIZA_PARAMETRO_EJECUCIONES, body 8316-8320):** NO genera fila en `FILTRO_TRACK`; es
> bookkeeping del job (JSON de corrida en `PA_PARAMETROS_MVP`), no un estado de represtamos. Su duracion ya
> queda en el `track_inicio(14)/track_fin(14)` existente. **Omision deliberada**, no accidental.

## 5. DIAGNOSTICA y Capa C completa (fases siguientes)

- **DIAGNOSTICA:** los 5 scripts de `trackers_precalifica_post_cursor_fast` ya reconstruyen el desglose por
  filtro. Se ejecutan en modo diagnostico **asociados al mismo `ID_EJECUCION`** y se insertan con
  `TIPO_MEDICION='DIAGNOSTICA'`. Requieren las correcciones de la seccion 7 de la propuesta (POST_CLEANUP,
  denominador capital, limpieza por procedure, no-determinismo del lote) antes de ser fuente oficial.
- **Capa C completa (Incremento C, diferido):** atribuir cada `ID_REPRESTAMO` al flujo que lo creo exige
  capturar en el `FETCH`/`FORALL INSERT` de cada una de las 5 procedures (body 232 y equivalentes). Eso
  toca las procedures y se propone por separado, con helper **package-private** (no anidado).

## 6. Compilacion y validacion (propuesta seccion 9)

1. Snapshot del body actual en `02_PACKAGE/` antes de editar (hash vs `00_ANTES/`).
2. Aplicar Incremento A por bloques; `ALTER PACKAGE ... COMPILE BODY` + `SHOW ERRORS` tras cada bloque.
3. Confirmar que la `spec` no cambio (`ddl` de spec identico).
4. Correr el job con `TRACK_PRECALIFICA_ACTIVO='N'` -> debe comportarse y durar igual que la base.
5. Activar `='S'`, correr, conciliar `entrada = descartados + sobrevivientes` por fase; verificar que todos
   los registros comparten `ID_EJECUCION`.
6. Rollback disponible: `04_ROLLBACK/ROLLBACK_PR_PKG_REPRESTAMOS_BODY_QA02.sql` (body baseline).

## 7. Puntos a confirmar antes de codificar el body

- Nombres/columnas reales de `PR_SOLICITUD_REPRESTAMO` y `PR_CANALES_REPRESTAMO` (definir "canal valido").
- Si se separan `PRE_RSB/CLS/RCS` por estado o por `PR_BITACORA_REPRESTAMO` del dia.
- Volumen del cierre para decidir si `track_candidato` por fila (autonomo) es aceptable o conviene bulk.
- Confirmar que `SEQ_PR_JOB_PRECAL_FILTRO.NEXTVAL` dentro de transaccion autonoma es aceptable (lo es;
  las secuencias son independientes de la transaccion).
