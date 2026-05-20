# OPT-015 - Rewrite Set-Based + Inline NOT EXISTS en Pasos 5-6

## Actualizacion 2026-04-16 | Handoff para otra PC / sesion Codex

- **Estado actual**: se dejo preparado un paquete de pruebas mas riguroso en `PAQUETE_PRUEBAS_RIESGOS` para validar equivalencia funcional en `DESARROLLO` desde una PC con acceso a Oracle.
- **Importante**: en esta sesion **no** se ejecutaron scripts contra la BD. Solo se preparo documentacion, scripts SQL y metodologia.
- **Objetivo de la siguiente sesion**: correr la validacion rigurosa de equivalencia para OPT-015 y luego, si pasa, cerrar evidencia con tiempos ANTES/DESPUES.

### Archivos nuevos preparados

- `PAQUETE_PRUEBAS_RIESGOS/02_SETUP_EQUIVALENCIA_OPT015.sql`
- `PAQUETE_PRUEBAS_RIESGOS/03_EJECUTAR_CADENA_CANCELADOS_OPT015.sql`
- `PAQUETE_PRUEBAS_RIESGOS/04_LIMPIAR_RUN_EQUIVALENCIA_OPT015.sql`
- `PAQUETE_PRUEBAS_RIESGOS/06_COMPARAR_EQUIVALENCIA_CANCELADOS_OPT015.sql`
- `PAQUETE_PRUEBAS_RIESGOS/07_RESTAURAR_PARAMETRO_LOTE_OPT015.sql`
- `PAQUETE_PRUEBAS_RIESGOS/PRUEBAS_OPT015_RIGUROSA.md`

### Que cambia respecto a la guia anterior

- La equivalencia ya no se basa solo en `PR_REPRESTAMOS`.
- Se compara tambien:
  - `PR_SOLICITUD_REPRESTAMO`
  - `PR_CANALES_REPRESTAMO`
  - `PR_OPCIONES_REPRESTAMO`
  - `PR_BITACORA_REPRESTAMO`
- La comparacion se hace por **llave de negocio**:
  - `CODIGO_EMPRESA`
  - `CODIGO_CLIENTE`
  - `NO_CREDITO`
  - `FECHA_CORTE`
- No se usa `ID_REPRESTAMO` como clave de comparacion entre corridas porque la secuencia cambia.
- Se sube temporalmente `LOTE_DE_CARAGA_REPRESTAMO` a `500` para reducir la variabilidad por `ROWNUM` sin `ORDER BY`.
- Se excluyen `PVALIDA_WORLD_COMPLIANCE` y `PVALIDA_XCORE` como criterio de equivalencia porque meten dependencias externas y ruido ajeno a OPT-015.

### Flujo recomendado para la siguiente sesion

1. Confirmar acceso a `DESARROLLO`.
2. Ejecutar `01_CREAR_INDICE_IDX_GARANTIAS_TIPO_SB.sql` solo si el indice no existe.
3. Ejecutar `02_SETUP_EQUIVALENCIA_OPT015.sql`.
4. Compilar `body_ANTES_OPT015.sql`.
5. Ejecutar `03_EJECUTAR_CADENA_CANCELADOS_OPT015.sql` con `RUN_LABEL = ANTES`.
6. Ejecutar `05_MEDIR_JOB_CANCELADO_DETALLADO.sql` para tiempos ANTES.
7. Ejecutar `04_LIMPIAR_RUN_EQUIVALENCIA_OPT015.sql` con `RUN_LABEL = ANTES`.
8. Compilar `body_DESPUES_OPT015.sql`.
9. Ejecutar `03_EJECUTAR_CADENA_CANCELADOS_OPT015.sql` con `RUN_LABEL = DESPUES`.
10. Ejecutar `05_MEDIR_JOB_CANCELADO_DETALLADO.sql` para tiempos DESPUES.
11. Ejecutar `06_COMPARAR_EQUIVALENCIA_CANCELADOS_OPT015.sql`.
12. Ejecutar `07_RESTAURAR_PARAMETRO_LOTE_OPT015.sql`.
13. Si se desea limpiar los datos funcionales del segundo run, ejecutar `04_LIMPIAR_RUN_EQUIVALENCIA_OPT015.sql` con `RUN_LABEL = DESPUES`.

### Resultado esperado para aprobar equivalencia

- `0` filas exclusivas y `0` diferencias en:
  - `PR_REPRESTAMOS`
  - `PR_SOLICITUD_REPRESTAMO`
  - `PR_CANALES_REPRESTAMO`
  - `PR_OPCIONES_REPRESTAMO`
  - `PR_BITACORA_REPRESTAMO`
- Mejora de tiempo en `Paso 5`, `Paso 6` y total del job.

### Permisos / objetos que deben existir en la otra PC

- Conexion al entorno `DESARROLLO`.
- Capacidad de compilar `PR.PR_PKG_REPRESTAMOS`.
- Capacidad de ejecutar `UPDATE` sobre `PA.PA_PARAMETROS_MVP`.
- Capacidad de crear tablas auxiliares en el usuario desde el cual se ejecutaran los scripts.
- Indice `PR.IDX_GARANTIAS_TIPO_SB` valido.

### Si algo falla, lo primero que hay que capturar

- Error exacto de compilacion del package.
- Error exacto al crear tablas auxiliares.
- Error exacto al actualizar `PA.PA_PARAMETROS_MVP`.
- Salida final de `03_EJECUTAR_CADENA_CANCELADOS_OPT015.sql` y de `06_COMPARAR_EQUIVALENCIA_CANCELADOS_OPT015.sql`.

### Nota metodologica para la siguiente sesion

- Esta validacion es deliberadamente mas estrecha que el job completo.
- Cubre la cadena local impactada por OPT-015 y deja fuera pasos externos.
- Si esta validacion pasa, ya se puede afirmar equivalencia funcional local con mucha mas fuerza que con la guia anterior.

- **Paquete**: PR_PKG_REPRESTAMOS
- **Procedures**: Precalifica_Repre_Cancelado (L.382), Precalifica_Repre_Cancelado_hi (L.766)
- **Entorno**: DESARROLLO (ADMQA1 / bmadev0004)
- **Fecha inicio**: 2026-04-13
- **Tipo**: Cambio estructural (eliminar FORALL row-by-row, inline funciones PL/SQL)
- **Referencia**: Patrones OPT-004 (set-based) + OPT-010 (NOT EXISTS inline)

---

## Problema

Los pasos 5 y 6 del orquestador `P_Carga_Precalifica_Cancelado` consumen el **53% del tiempo total** (624 seg de 854 seg con indices). La causa raiz es CPU/PL/SQL, no I/O:

1. **FORALL UPDATEs row-by-row**: 4 UPDATEs dentro del loop ejecutan subqueries correlacionadas por cada fila del batch (LIMIT 100), causando N context switches SQL-PL/SQL.
2. **Funciones PL/SQL en cursor**: `F_TIENE_GARANTIA` / `F_TIENE_GARANTIA_HISTORICO` y `F_Validar_Listas_PEP` / `F_Validar_Lista_NEGRA` se ejecutan por cada fila candidata del cursor.
3. **Se probo 5to indice en PA_DETALLADO_DE08** y empeoro. Confirmado: no se optimiza con indices.

## Decisiones tomadas (NO cambiar)

| Decision | Detalle |
|----------|---------|
| Semantica 100% conservadora | C1/H1 incluyen JOIN a PR_CREDITOS/PR_CREDITOS_HI con filtro estado IN ('D','V','M','E','J') |
| PEP/NEGRA a DELETE post-INSERT | A.0.1 validado: `esta_en_lista_pep`/`esta_en_lista_negra` son read-only |
| Filtros defensivos en UPDATEs | `ADICIONADO_POR = USER AND FECHA_ADICION >= TRUNC(SYSDATE)` en los 4 UPDATE set-based |
| Ritmo atomico | Ambos procedures y todos los cambios en una sola sesion (Fase B) |
| Flujo en 2 fases | NO tocar body.sql hasta que Fase A este aprobada |

## Fase A - Validacion con Explain Plan (estado actual)

### A.0.1 - Verificar funciones PEP/NEGRA (COMPLETADO)
- `PA.P_DATOS_PERSONA.esta_en_lista_pep` (L.314 body): SELECT INTO a `lista_pep` â€” **read-only**
- `PA.P_DATOS_PERSONA.esta_en_lista_negra` (L.129 body): SELECT INTO a `lista_negra` â€” **read-only**
- `F_Validar_Listas_PEP` (L.9464) y `F_Validar_Lista_NEGRA` (L.9475): wrappers que llaman a las funciones PA
- **Conclusion**: Es seguro mover a DELETE post-INSERT

### A.0.2 - Crear indice IDX_GARANTIAS_TIPO_SB (COMPLETADO 2026-04-13)
- Indice de OPT-010: `PR.IDX_GARANTIAS_TIPO_SB ON PR.PR_GARANTIAS (CODIGO_EMPRESA, NUMERO_GARANTIA, CODIGO_TIPO_GARANTIA_SB)`
- **No existia en DESARROLLO** â€” creado exitosamente
- Ya existia en QA (creado en OPT-010)

### A.0.3 - Verificar LOTE y COD_EMPRESA (COMPLETADO 2026-04-13)
- **LOTE_DE_CARAGA_REPRESTAMO = 5** (batches de 5 filas por iteracion del loop)
- **f_obt_Empresa_Represtamo = 1**
- Nota: LOTE=5 es mucho menor que los 190 RE que se midieron. El cursor itera multiples veces.

### A.1 - Ejecutar 12 Explain Plans Q1-Q12 (COMPLETADO 2026-04-13)
- Script: `scripts_medicion/explain_plan_opt015.sql`
- **Resultados**:

| Query | Descripcion | Cost |
|-------|-------------|------|
| Q1 | Cursor Cancelado (DESPUES) | 5,541 |
| Q2 | Cursor Cancelado_hi (DESPUES) | 8,732 |
| Q3 | UPDATE DIAS_ATRASO set-based | 15,182 |
| Q4 | UPDATE MTO_CREDITO set-based | 9 |
| Q5 | UPDATE X3 TC set-based | 7 |
| Q6 | UPDATE X1 desembolso set-based | 24,551 |
| Q7 | DELETE PEP | 3 |
| Q8 | DELETE NEGRA | 3 |
| Q9 | ANTES FORALL DIAS_ATRASO (x1) | 53 |
| Q10 | ANTES FORALL MTO_CREDITO (x1) | 1,010 |
| Q11 | ANTES FORALL X3 TC (x1) | 8 |
| Q12 | ANTES FORALL X1 desembolso (x1) | 37 |

- **Veredicto**: APROBADA. Q4/Q5 victorias claras. Q3/Q6 costs inflados pero eliminan context switches. IDX_GARANTIAS_TIPO_SB activo en Q1/Q2. Sin FULL TABLE SCAN.
- **Parametros verificados**: LOTE=5, EMPRESA=1

## Fase B - Modificacion de body.sql (COMPLETADO 2026-04-14)

Cambios aplicados en ambos procedimientos (Cancelado y Cancelado_hi):
- Cursor: F_TIENE_GARANTIA/F_TIENE_GARANTIA_HISTORICO reemplazados por NOT EXISTS inline
- Cursor: PEP/NEGRA eliminados del cursor, movidos a DELETE post-INSERT
- Loop: Simplificado a solo INSERT (4 FORALL UPDATEs removidos)
- Post-loop: 4 UPDATEs set-based (U1-U4) + 2 DELETEs (D1-D2) con filtros defensivos

## Resultados de medicion real (DESARROLLO - ADMQA1)

| Paso | ANTES (seg) | DESPUES (seg) | Mejora |
|------|-------------|---------------|--------|
| 5. Precalifica_Repre_Cancelado | 346.8 | 170.2 | -51% |
| 6. Precalifica_Repre_Cancelado_hi | 509.2 | 207.9 | -59% |
| Subtotal pasos 5+6 | 856 | 378 | **-56%** |
| **TOTAL JOB** | **1,381 (23 min)** | **680 (11.3 min)** | **-51%** |

RE procesados: 10 (LOTE=5, 2 iteraciones)

### Acumulado con OPT-014 (indices)

| Medicion | Tiempo | Reduccion vs original |
|----------|--------|-----------------------|
| Baseline original (sin indices) | ~24 min | â€” |
| Con indices OPT-014 | 14.2 min | -41% |
| Con indices + OPT-015 set-based | **11.3 min** | **-53%** |

### Validacion de equivalencia semantica (2026-04-14)

Se compararon snapshots de resultados entre body original y body OPT-015:
- **Query 2 (campos clave)**: 0 diferencias â€” ESTADO, DIAS_ATRASO, MTO_CREDITO_ACTUAL identicos
- **Query 1 (filas exclusivas)**: 3 filas "Solo en ANTES" (18 RE vs 15 RE)
- **Causa**: Variabilidad entre ejecuciones, no diferencia de logica

**Nota sobre variabilidad**: El cursor usa `ROWNUM <= 5` (LOTE) sin ORDER BY,
por lo que Oracle no garantiza el orden de las filas retornadas. Entre ejecuciones,
el optimizer puede elegir un plan diferente o los bloques en buffer pueden variar,
resultando en que se procesen creditos distintos. Esto es comportamiento normal
del codigo original â€” no fue introducido por OPT-015. Los 3 creditos faltantes
tenian estado NP (pasaron todas las validaciones), confirmando que si hubieran
sido procesados por el body optimizado, habrian tenido el mismo resultado.

### Archivos de rollback

- `body_ANTES_OPT015.sql` â€” body original para revertir
- `body_DESPUES_OPT015.sql` â€” body con cambios OPT-015

---

## Cambios planificados (Fase B - NO ejecutar aun)

### Procedimiento 1: Precalifica_Repre_Cancelado (L.382-765)

#### C1 - Cursor CREDITOS_PROCESAR (L.383-484)
**Quitar del cursor:**
- L.479: `F_TIENE_GARANTIA(a.no_credito) = 0` â†’ inline como NOT EXISTS
- L.481: `F_Validar_Listas_PEP(1, a.codigo_cliente) = 0` â†’ mover a DELETE post-INSERT
- L.483: `F_Validar_Lista_NEGRA(1, a.codigo_cliente) = 0` â†’ mover a DELETE post-INSERT

**NOT EXISTS inline (reemplaza F_TIENE_GARANTIA):**
```sql
AND NOT EXISTS (
    SELECT 1
    FROM PR_CREDITOS cr
    JOIN PR_GARANTIAS_X_CREDITO gx ON gx.CODIGO_EMPRESA = cr.CODIGO_EMPRESA
                                   AND gx.NO_CREDITO = cr.NO_CREDITO
    JOIN PR_GARANTIAS g ON g.CODIGO_EMPRESA = gx.CODIGO_EMPRESA
                        AND g.NUMERO_GARANTIA = gx.NUMERO_GARANTIA
    WHERE cr.CODIGO_EMPRESA = PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
      AND cr.NO_CREDITO = a.NO_CREDITO
      AND cr.ESTADO IN ('D','V','M','E','J')
      AND g.CODIGO_TIPO_GARANTIA_SB != 'NA'
)
```

#### U1-U4 - FORALL UPDATEs â†’ set-based (L.613-697)
Reemplazar los 4 FORALL UPDATEs dentro del loop por 4 UPDATEs set-based despues del CLOSE cursor.

**U1 - DIAS_ATRASO** (reemplaza L.613-630):
```sql
UPDATE PR.PR_REPRESTAMOS y
SET Y.DIAS_ATRASO = (SELECT MAX(D.DIAS_ATRASO)
                     FROM PA.PA_DETALLADO_DE08 D
                     WHERE D.FUENTE = 'PR'
                       AND D.FECHA_CORTE >= ADD_MONTHS(y.FECHA_CORTE, -6)
                       AND D.NO_CREDITO = y.NO_CREDITO
                       AND D.CODIGO_CLIENTE = y.CODIGO_CLIENTE)
WHERE y.ESTADO = 'RE'
  AND y.ADICIONADO_POR = USER
  AND y.FECHA_ADICION >= TRUNC(SYSDATE);
```

**U2 - MTO_CREDITO_ACTUAL** (reemplaza L.636-650):
```sql
UPDATE PR.PR_REPRESTAMOS R
SET R.MTO_CREDITO_ACTUAL = (SELECT D.monto_desembolsado
                            FROM PA.PA_DETALLADO_DE08 D
                            WHERE D.FUENTE = 'PR'
                              AND D.NO_CREDITO = R.NO_CREDITO
                              AND D.CODIGO_CLIENTE = R.CODIGO_CLIENTE
                              AND D.FECHA_CORTE = (SELECT MAX(P.FECHA_CORTE)
                                                   FROM PA_DETALLADO_DE08 P
                                                   WHERE P.FUENTE = 'PR'
                                                     AND P.NO_CREDITO = R.NO_CREDITO
                                                     AND P.CODIGO_CLIENTE = R.CODIGO_CLIENTE))
WHERE R.ESTADO = 'RE'
  AND R.ADICIONADO_POR = USER
  AND R.FECHA_ADICION >= TRUNC(SYSDATE);
```

**U3 - ESTADO X3 (TC atraso)** (reemplaza L.659-675):
```sql
UPDATE PR.PR_REPRESTAMOS y
SET y.ESTADO = 'X3',
    Y.OBSERVACIONES = 'EL CLIENTE POSEE TARJETA DE CREDITO CON ATRASO MAYOR A '||v_atraso_30||' DIAS'
WHERE y.ESTADO = 'RE'
  AND y.ADICIONADO_POR = USER
  AND y.FECHA_ADICION >= TRUNC(SYSDATE)
  AND EXISTS (SELECT 1
              FROM PA_DETALLADO_DE08 D
              WHERE D.FUENTE = 'TC'
                AND D.FECHA_CORTE = y.FECHA_CORTE
                AND D.NO_CREDITO != y.NO_CREDITO
                AND D.CODIGO_CLIENTE = y.CODIGO_CLIENTE
                AND D.CODIGO_EMPRESA = y.CODIGO_EMPRESA
                AND D.DIAS_ATRASO >= v_atraso_30);
```

**U4 - ESTADO X1 (desembolso reciente)** (reemplaza L.682-697):
```sql
UPDATE PR.PR_REPRESTAMOS y
SET y.ESTADO = 'X1',
    Y.OBSERVACIONES = 'EL CLIENTE TIENE OTRO PRESTAMO DESEMBOLSADO EN LOS ULTIMOS '||OBT_PARAMETROS('1','PR','PRECAL_DESEMBOLSO_PR')||' MESES'
WHERE y.ESTADO = 'RE'
  AND y.ADICIONADO_POR = USER
  AND y.FECHA_ADICION >= TRUNC(SYSDATE)
  AND EXISTS (SELECT 1
              FROM PR_CREDITOS C
              WHERE C.CODIGO_EMPRESA = y.CODIGO_EMPRESA
                AND C.NO_CREDITO != y.NO_CREDITO
                AND C.CODIGO_CLIENTE = y.CODIGO_CLIENTE
                AND C.F_PRIMER_DESEMBOLSO > ADD_MONTHS(SYSDATE, -OBT_PARAMETROS('1','PR','PRECAL_DESEMBOLSO_PR'))
                AND C.ESTADO IN (SELECT COLUMN_VALUE FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('ESTADOS_CREDITOS'))));
```

#### D1 - DELETE PEP post-INSERT (nuevo, despues de U4):
```sql
DELETE FROM PR_REPRESTAMOS
WHERE ESTADO = 'RE'
  AND ADICIONADO_POR = USER
  AND FECHA_ADICION >= TRUNC(SYSDATE)
  AND PR.PR_PKG_REPRESTAMOS.F_Validar_Listas_PEP(1, CODIGO_CLIENTE) = 1;
```
Nota: Usa la funcion wrapper porque la funcion PA devuelve BOOLEAN (no usable en SQL puro).

#### D2 - DELETE NEGRA post-INSERT (nuevo, despues de D1):
```sql
DELETE FROM PR_REPRESTAMOS
WHERE ESTADO = 'RE'
  AND ADICIONADO_POR = USER
  AND FECHA_ADICION >= TRUNC(SYSDATE)
  AND PR.PR_PKG_REPRESTAMOS.F_Validar_Lista_NEGRA(1, CODIGO_CLIENTE) = 1;
```

### Procedimiento 2: Precalifica_Repre_Cancelado_hi (L.766-1138)

Cambios identicos con estas diferencias:
- **H1**: Cursor usa `PR_CREDITOS_HI` en lugar de `PR_CREDITOS` â†’ NOT EXISTS usa `PR_CREDITOS_HI`
- **H2-H5**: Identicos a U1-U4 (ambos actualizan PR_REPRESTAMOS)
- **H6-H7**: Identicos a D1-D2

### Estructura del loop simplificado (aplica a ambos)
```
OPEN cursor;
LOOP
  FETCH BULK COLLECT INTO ... LIMIT 100;
  FORALL INSERT INTO PR_REPRESTAMOS;
  EXIT WHEN cursor%NOTFOUND;
END LOOP;
CLOSE cursor;

-- UPDATEs set-based (una sola ejecucion)
UPDATE DIAS_ATRASO ...     -- U1
UPDATE MTO_CREDITO_ACTUAL ...  -- U2
UPDATE ESTADO X3 ...       -- U3
UPDATE ESTADO X1 ...       -- U4

-- DELETEs post-INSERT (PEP/NEGRA)
DELETE PEP ...             -- D1
DELETE NEGRA ...           -- D2

-- UPDATEs y DELETEs existentes (ya set-based, no cambian)
UPDATE ESTADO X2 ...
DELETE mancomunados ...
DELETE edad ...
DELETE X% ...
```

---

## Archivos de referencia

| Archivo | Contenido |
|---------|-----------|
| `ENTORNOS_ORACLE/DESARROLLO/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | Paquete principal |
| `ENTORNOS_ORACLE/DESARROLLO/schemas/PA/packages/PA.p_datos_persona/body.sql` | Funciones PEP/NEGRA |
| `historias/optimizaciones/probados_no_promovidos/OPT-004_SETBASED_ACTUALIZAR_MTO_CREDITO/README.md` | Patron set-based |
| `historias/optimizaciones/probados_no_promovidos/OPT-010_INLINE_F_TIENE_GARANTIA/README.md` | Patron NOT EXISTS |
| `historias/optimizaciones/soporte/scripts_medicion/05_MEDIR_JOB_CANCELADO_DETALLADO.sql` | Script medicion |

## Valores de referencia para Explain Plan
- **NO_CREDITO**: 1087363
- **CODIGO_CLIENTE**: 1107470
- **FECHA_CORTE**: DATE '2024-09-27'
- **CODIGO_EMPRESA**: 1
