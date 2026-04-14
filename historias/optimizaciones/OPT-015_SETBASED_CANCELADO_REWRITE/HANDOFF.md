# OPT-015 — Handoff de sesion (continuar en otra PC)

**Fecha de handoff**: 2026-04-13
**Entorno destino**: DESARROLLO (JOOGANDO@ADMQA1_19C)
**Branch**: `claude/cool-yonath`
**Fase actual**: Fase A (validacion con Explain Plan). NADA se ha tocado en el body.sql todavia.

---

## 1. Contexto corto

Estamos optimizando los pasos 5 y 6 del orquestador `P_Carga_Precalifica_Cancelado`:
- Paso 5: `Precalifica_Repre_Cancelado` (body.sql DESARROLLO, L.382-765)
- Paso 6: `Precalifica_Repre_Cancelado_hi` (body.sql DESARROLLO, L.766-1138)

Estos 2 pasos consumen **624 s de 854 s = 73%** del tiempo total del Job1 segun la medicion real de OPT-014. No se optimizan con mas indices (ya probado y descartado). Requieren rewrite de codigo: replicar OPT-004 (set-based UPDATE) + OPT-010 (inline NOT EXISTS) en ambos procedures.

## 2. Plan completo

Archivo canonico: `C:\Users\ogand\.claude\plans\eager-dreaming-lamport.md`

Estructura:
- **Fase A** — Validar con Explain Plan en Toad (0 riesgo, solo lectura).
- **Fase B** — Aplicar rewrite al body.sql + medir tiempo real + validar semantica con MINUS.

## 3. Decisiones tomadas en esta sesion (con el usuario)

1. **Semantica preservada al 100%** (opcion conservadora). No replicar la simplificacion de OPT-010.
2. **PEP/NEGRA movidos a DELETE post-INSERT** (opcion A). Validado read-only en `PA.P_DATOS_PERSONA` (paquete de 967 lineas, solo SELECTs, sin DML).
3. **Ritmo atomico** — ambos procedures y todos los cambios en una sola sesion.
4. **Flujo 2 fases** — primero Explain Plan (Fase A), luego medicion real (Fase B), no saltar pasos.
5. **Filtros defensivos** — en los 4 UPDATE set-based: `ADICIONADO_POR=USER + FECHA_ADICION >= TRUNC(SYSDATE)` (en body.sql sera `>= v_tstamp_inicio` capturado al inicio).

## 4. Lo completado en esta sesion

- [x] Analisis completo de ambos procedures (cursores + BULK LOOP + FORALL + funciones PL/SQL por fila).
- [x] Identificacion de 4 familias de cambios: C1 (inline F_TIENE_GARANTIA), C2 (BULK LOOP → set-based), C3 (eliminar declaraciones muertas), D1 (PEP/NEGRA al DELETE). Simetricas en `_hi` como H1/H2/H3/H4.
- [x] Plan aprobado por usuario (guardado en `~/.claude/plans/eager-dreaming-lamport.md`).
- [x] Carpeta `historias/optimizaciones/OPT-015_SETBASED_CANCELADO_REWRITE/` creada.
- [x] `scripts_medicion/explain_plan_opt015.sql` creado y corregido con semantica 100%.
- [x] A.0.1 VALIDADO: `PA.P_DATOS_PERSONA.esta_en_lista_pep` y `.esta_en_lista_negra` son read-only (solo SELECT). **PODEMOS aplicar opcion A (PEP/NEGRA al DELETE).**
- [x] Carpeta `ENTORNOS_ORACLE/DESARROLLO/schemas/PA/packages/P_DATOS_PERSONA/` creada (pendiente llenar con `spec.sql` + `body.sql`).
- [x] Mapa completo de la invocacion de `P_Registrar_Solicitud`: solo Job1 la ejecuta automaticamente; los otros 2 call sites (via P_Carga_Precalifica_Represtamo y P_REGISTRO_SOLICITUD) no tienen job agendado en DESARROLLO.

## 5. Lo PENDIENTE (orden estricto de ejecucion)

### Paso 1 — Versionar paquete PA.P_DATOS_PERSONA en el repo

Ruta: `ENTORNOS_ORACLE/DESARROLLO/schemas/PA/packages/P_DATOS_PERSONA/`
Ya tiene un archivo `_PENDIENTE_LLENAR.md` con las instrucciones. Resumen:

1. Abrir Toad conectado a **JOOGANDO@ADMQA1_19C** (DESARROLLO).
2. Schema Browser → schema **PA** → Packages → buscar **P_DATOS_PERSONA**.
3. Copiar el Header (pestana) → guardar como `spec.sql` en esa carpeta.
4. Copiar el Body (pestana) → guardar como `body.sql` en esa carpeta.
5. Borrar el archivo `_PENDIENTE_LLENAR.md`.
6. Commit: `git add ENTORNOS_ORACLE/DESARROLLO/schemas/PA/packages/P_DATOS_PERSONA/ && git commit -m "Versionar PA.P_DATOS_PERSONA en DESARROLLO (referencia para OPT-015)"`.

Alternativa con DBMS_METADATA si Schema Browser no coopera:

```sql
BEGIN
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SQLTERMINATOR', TRUE);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'PRETTY', TRUE);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'STORAGE', FALSE);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'TABLESPACE', FALSE);
END;
/

-- spec.sql
SELECT DBMS_METADATA.GET_DDL('PACKAGE_SPEC', 'P_DATOS_PERSONA', 'PA') FROM DUAL;

-- body.sql
SELECT DBMS_METADATA.GET_DDL('PACKAGE_BODY', 'P_DATOS_PERSONA', 'PA') FROM DUAL;
```

### Paso 2 — Continuar Fase A (los 12 Explain Plans)

Archivo a ejecutar: `historias/optimizaciones/OPT-015_SETBASED_CANCELADO_REWRITE/scripts_medicion/explain_plan_opt015.sql`

Abrir en Toad, ejecutar bloque por bloque con F5:

**Pre-requisitos bloqueantes (si no se completaron):**

- **A.0.1**: ya VALIDADO en esta sesion (read-only confirmado). Saltar.
- **A.0.2**: ejecutar el SELECT sobre `DBA_INDEXES WHERE INDEX_NAME='IDX_GARANTIAS_TIPO_SB'`.
  - Si 0 filas → ejecutar el `CREATE INDEX` comentado en el archivo.
  - Si 1 fila con STATUS=VALID → avanzar.
- **A.0.3**: ejecutar el SELECT que muestra `LOTE_DE_CARAGA_REPRESTAMO` y `f_obt_Empresa_Represtamo`.
  - LOTE debe ser < 5000.
  - COD_EMPRESA debe ser = 1.

**Luego los 12 Explain Plans (Q1-Q12):**

Ejecutar cada bloque `EXPLAIN PLAN ... + SELECT DBMS_XPLAN.DISPLAY` individualmente y **guardar los 12 outputs**.

Criterios de aceptacion al final del archivo SQL. Resumen de lo que buscamos:
- Q1/Q7 (INSERT): HASH SEMI JOIN en los 4 NOT EXISTS, uso de IDX_GARANTIAS_TIPO_SB.
- Q2/Q8 (DELETE PEP/NEGRA): INDEX SCAN + FILTER con functions (aceptable).
- Q3/Q9 (DIAS_ATRASO): uso de IDX_DE08_SIB_FECHA_DEUDOR.
- Q4/Q10 (MTO_CREDITO_ACTUAL): no explosion cuadratica en subquery MAX.
- Q5/Q11 (ESTADO='X3'): HASH SEMI JOIN con PA_DETALLADO_DE08.
- Q6/Q12 (ESTADO='X1'): HASH SEMI JOIN con PR_CREDITOS.

**Alerta si**: FILTER con subquery ejecutada por fila, FULL SCAN sobre PR_GARANTIAS o PA_DETALLADO_DE08.

### Paso 3 — Entregar los 12 plans a Claude para revision

Pegar los outputs en chat. Claude contrasta contra criterios y aprueba (o pide iteracion si alguno falla).

### Paso 4 — Fase B (solo si A.3 aprobo)

Seguir seccion "Fase B" del plan (`~/.claude/plans/eager-dreaming-lamport.md`):

1. Snapshot 190 RE + tabla `JOOGANDO.OPT015_ANTES`.
2. Medir 3x ANTES con `scripts_medicion/05_MEDIR_JOB_CANCELADO_DETALLADO.sql`.
3. Aplicar rewrite atomico al body.sql (C1+C2+C3+D1 en `_Cancelado`; H1+H2+H3+H4 en `_hi`).
4. Compilar; verificar VALID + sin warnings.
5. Medir 3x DESPUES.
6. Validar semantica con MINUS en ambos sentidos = 0 filas.
7. Documentar OPT-015 (README.md, BEFORE.sql, AFTER.sql, rollback.sql).
8. Actualizar README.md maestro, MAPA_JOBS.md, SESION_PENDIENTE.md.
9. Commit unico.

## 6. Archivos criticos para retomar

| Archivo | Proposito |
|---------|-----------|
| `~/.claude/plans/eager-dreaming-lamport.md` | Plan completo de OPT-015 (Fase A + Fase B, riesgos, rollback) |
| `historias/optimizaciones/OPT-015_SETBASED_CANCELADO_REWRITE/scripts_medicion/explain_plan_opt015.sql` | **Este es el archivo que se ejecuta ahora en Toad** |
| `historias/optimizaciones/OPT-015_SETBASED_CANCELADO_REWRITE/HANDOFF.md` | Este mismo archivo |
| `ENTORNOS_ORACLE/DESARROLLO/schemas/PA/packages/P_DATOS_PERSONA/_PENDIENTE_LLENAR.md` | Instrucciones para versionar el paquete PA |
| `ENTORNOS_ORACLE/DESARROLLO/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | Paquete a optimizar (se tocara en Fase B) |
| `historias/optimizaciones/OPT-004_SETBASED_ACTUALIZAR_MTO_CREDITO/` | Plantilla de set-based UPDATE |
| `historias/optimizaciones/OPT-010_INLINE_F_TIENE_GARANTIA/` | Plantilla de inline NOT EXISTS |
| `historias/optimizaciones/OPT-014_INDICES_MEDICION_REAL/README.md` | Medicion real baseline (854 s total, 624 s en pasos 5-6) |
| `historias/optimizaciones/scripts_medicion/05_MEDIR_JOB_CANCELADO_DETALLADO.sql` | Script de medicion ANTES/DESPUES |
| `historias/optimizaciones/SESION_PENDIENTE.md` | Estado global de todas las OPT |
| `historias/optimizaciones/MAPA_JOBS.md` | Arbol de llamadas de cada job |

## 7. Datos utiles para Toad

- **Conexion DESA**: `JOOGANDO@ADMQA1_19C` (segun reference_conexiones_toad.md).
- **Fecha de corte usada en Explain Plans**: `27/09/2024` (valor real observado en DESA).
- **190 RE**: registros en estado RE esperados en DESARROLLO tras ejecutar el UPDATE de restauracion:

```sql
UPDATE PR.PR_REPRESTAMOS SET ESTADO='RE'
 WHERE MODIFICADO_POR IS NULL
   AND FECHA_MODIFICACION >= DATE '2026-04-10'
   AND ESTADO IN ('AN','NP','CP','RXT','RXC');
COMMIT;
```

- **Indices ya creados en DESA (OPT-014)**:
  - `PA.IDX_DE08_SIB_FECHA_DEUDOR` (OPT-002)
  - `PR.IDX_CREDITOS_HI_NOCREDITO` (OPT-009)
  - `PR.IDX_REPRESTAMOS_EMP_EST_NOCRED` (OPT-011)
  - `PA.IDX_DE05_SIB_CASTIGO_CEDULA` (OPT-013)
  - `PR.IDX_GARANTIAS_TIPO_SB` (OPT-010) — **verificar en A.0.2**, puede faltar.

## 8. NO HACER

- NO modificar `body.sql` hasta que Fase A este completamente aprobada (los 12 plans cumplen criterios).
- NO eliminar `PR.IDX_GARANTIAS_TIPO_SB` si ya existe — compartido con OPT-010.
- NO aplicar las optimizaciones a QA ni a PRODUCCION. Estamos trabajando SOLO en DESARROLLO.
- NO alterar la semantica del cursor (respetar estado IN ('D','V','M','E','J') en C1/H1 — decision tomada).
