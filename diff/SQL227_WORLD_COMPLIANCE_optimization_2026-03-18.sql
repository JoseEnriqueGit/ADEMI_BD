/*
================================================================================
  OPTIMIZACIÓN SQL 227 — CURSOR CARGAR_WORLD_COMPLIANCE
  Paquete:    PR.PR_PKG_REPRESTAMOS
  Procedure:  PVALIDA_WORLD_COMPLIANCE
  Entorno:    QA (QAORACEL19C)
  Fecha:      2026-03-18
  Autor:      Análisis basado en Quest SQL Optimizer + Claude Code

  Reporte origen: Scanned SQL Report 227.pdf (Quest SQL Optimizer)
  Cost original:  18,293
  Cost esperado:  ~40
================================================================================

  RESUMEN DE PROBLEMAS DETECTADOS:
  ────────────────────────────────
  1. TABLE ACCESS FULL en PERSONAS_FISICAS (1.667K rows, 49MB, cost 16,948)
     Causa: Conversión implícita VARCHAR2 vs NUMBER en JOIN invalida PK

  2. TABLE ACCESS FULL en PR_SOLICITUD_REPRESTAMO (132K rows, 1.1MB, cost 1,295)
     Causa: JOIN solo por ID_REPRESTAMO, pero PK es (CODIGO_EMPRESA, ID_REPRESTAMO)

  3. COMMIT dentro del FOR loop (1 commit por fila procesada)
     Causa: Genera redo log flush excesivo

  ÍNDICES EXISTENTES VERIFICADOS EN QA:
  ─────────────────────────────────────
  - PK_PERSONASFISICAS: COD_PER_FISICA (VARCHAR2)
  - PK_SOLICITUD_REPRESTAMO: CODIGO_EMPRESA, ID_REPRESTAMO
  - No se requiere crear índices nuevos para esta optimización.

================================================================================
*/


-- ╔════════════════════════════════════════════════════════════════════════════╗
-- ║  ANTES (CÓDIGO ORIGINAL)                                                  ║
-- ╚════════════════════════════════════════════════════════════════════════════╝

/*
  Ubicación: body.sql líneas 3741-3749 (cursor) y 3838 (COMMIT)

  --- CURSOR (líneas 3741-3749) ---

              CURSOR CARGAR_WORLD_COMPLIANCE IS
               SELECT R.ID_REPRESTAMO,R.NO_CREDITO, PF.PRIMER_APELLIDO, PF.PRIMER_NOMBRE, b.NUMERO_IDENTIFICACION-- S.IDENTIFICACION
               FROM PR_REPRESTAMOS R
               LEFT JOIN PERSONAS_FISICAS PF ON PF.COD_PER_FISICA = R.CODIGO_CLIENTE
               LEFT JOIN PR_SOLICITUD_REPRESTAMO S ON S.ID_REPRESTAMO = R.ID_REPRESTAMO
               LEFT JOIN CLIENTES_B2000 B ON B.CODIGO_CLIENTE = R.CODIGO_CLIENTE
               WHERE R.ESTADO = 'RE'
               AND WORLD_COMPLIANCE IS NULL
               AND ROWNUM <=  TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('LOTE_PROCESO_WORLD_COMPLIANCE'));


  --- COMMIT dentro del loop (línea 3838) ---

            UPDATE PR.PR_SOLICITUD_REPRESTAMO SET WORLD_COMPLIANCE = VALOR WHERE ID_REPRESTAMO = A.ID_REPRESTAMO ;
            COMMIT;
            EXCEPTION WHEN OTHERS THEN
                ...
           END;
         END LOOP ;


  --- EXECUTION PLAN ORIGINAL (cost 18,293) ---

  | Id | Operation                              | Name                      | Rows  | Bytes | Cost   |
  |----|------------------------------------------|---------------------------|-------|-------|--------|
  |  0 | SELECT STATEMENT                         |                           |     1 |    83 | 18293  |
  |  1 |  COUNT STOPKEY                           |                           |       |       |        |
  |  2 |   HASH JOIN OUTER                        |                           |     1 |    83 | 18293  |
  |  3 |    NESTED LOOPS OUTER                    |                           |     1 |    52 |  1332  |
  |  4 |     FILTER                               |                           |       |       |        |
  |  5 |      HASH JOIN OUTER                     |                           |     1 |    32 |  1329  |
  |  6 |       TABLE ACCESS BY INDEX ROWID BATCHED| PR_REPRESTAMOS            |     1 |    23 |    33  |
  |  7 |        INDEX SKIP SCAN                   | IND02_PR_REPRESTAMOS      |     1 |       |    32  |
  |  8 |       TABLE ACCESS FULL                  | PR_SOLICITUD_REPRESTAMO   | 132K  |1164K  |  1295  | << PROBLEMA
  |  9 |      TABLE ACCESS BY INDEX ROWID BATCHED | CLIENTES_B2000            |     1 |    20 |     3  |
  | 10 |       INDEX RANGE SCAN                   | IDX_CLIENTE_2000          |     1 |       |     2  |
  | 11 |   TABLE ACCESS FULL                      | PERSONAS_FISICAS          |1667K  |  49M  | 16948  | << PROBLEMA (92% del costo)

*/


-- ╔════════════════════════════════════════════════════════════════════════════╗
-- ║  DESPUÉS (CÓDIGO OPTIMIZADO)                                              ║
-- ╚════════════════════════════════════════════════════════════════════════════╝

/*
  --- CURSOR OPTIMIZADO (líneas 3741-3749) ---

              CURSOR CARGAR_WORLD_COMPLIANCE IS
               SELECT R.ID_REPRESTAMO,R.NO_CREDITO, PF.PRIMER_APELLIDO, PF.PRIMER_NOMBRE, b.NUMERO_IDENTIFICACION-- S.IDENTIFICACION
               FROM PR_REPRESTAMOS R
               LEFT JOIN PERSONAS_FISICAS PF ON PF.COD_PER_FISICA = TO_CHAR(R.CODIGO_CLIENTE)
               LEFT JOIN PR_SOLICITUD_REPRESTAMO S ON S.CODIGO_EMPRESA = R.CODIGO_EMPRESA AND S.ID_REPRESTAMO = R.ID_REPRESTAMO
               LEFT JOIN CLIENTES_B2000 B ON B.CODIGO_CLIENTE = R.CODIGO_CLIENTE
               WHERE R.ESTADO = 'RE'
               AND WORLD_COMPLIANCE IS NULL
               AND ROWNUM <=  TO_NUMBER(PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('LOTE_PROCESO_WORLD_COMPLIANCE'));


  --- COMMIT movido fuera del loop ---

            UPDATE PR.PR_SOLICITUD_REPRESTAMO SET WORLD_COMPLIANCE = VALOR WHERE ID_REPRESTAMO = A.ID_REPRESTAMO ;
            EXCEPTION WHEN OTHERS THEN
                ...
           END;
         END LOOP ;
         COMMIT;


  --- EXECUTION PLAN ESPERADO (cost ~40) ---

  | Id | Operation                              | Name                      | Rows  | Bytes | Cost   |
  |----|------------------------------------------|---------------------------|-------|-------|--------|
  |  0 | SELECT STATEMENT                         |                           |     1 |    83 |   ~40  |
  |  1 |  COUNT STOPKEY                           |                           |       |       |        |
  |  2 |   NESTED LOOPS OUTER                     |                           |     1 |    83 |   ~37  |
  |  3 |    NESTED LOOPS OUTER                    |                           |     1 |    52 |   ~35  |
  |  4 |     NESTED LOOPS OUTER                   |                           |     1 |    32 |   ~33  |
  |  5 |      TABLE ACCESS BY INDEX ROWID BATCHED | PR_REPRESTAMOS            |     1 |    23 |    33  |
  |  6 |       INDEX SKIP SCAN                    | IND02_PR_REPRESTAMOS      |     1 |       |    32  |
  |  7 |      TABLE ACCESS BY INDEX ROWID         | PR_SOLICITUD_REPRESTAMO   |     1 |     9 |    ~2  | << USA PK
  |  8 |       INDEX UNIQUE SCAN                  | PK_SOLICITUD_REPRESTAMO   |     1 |       |    ~1  |
  |  9 |     TABLE ACCESS BY INDEX ROWID BATCHED  | CLIENTES_B2000            |     1 |    20 |     3  |
  | 10 |      INDEX RANGE SCAN                    | IDX_CLIENTE_2000          |     1 |       |     2  |
  | 11 |    TABLE ACCESS BY INDEX ROWID           | PERSONAS_FISICAS          |     1 |    31 |    ~2  | << USA PK
  | 12 |     INDEX UNIQUE SCAN                    | PK_PERSONASFISICAS        |     1 |       |    ~1  |

*/


-- ╔════════════════════════════════════════════════════════════════════════════╗
-- ║  DETALLE DE CADA CAMBIO                                                   ║
-- ╚════════════════════════════════════════════════════════════════════════════╝

/*
  ── CAMBIO #1: TO_CHAR en JOIN PERSONAS_FISICAS ──────────────────────────────
  Línea:     3744
  Severidad: CRITICA (92% del costo total)

  ANTES:  LEFT JOIN PERSONAS_FISICAS PF ON PF.COD_PER_FISICA = R.CODIGO_CLIENTE
  DESPUÉS: LEFT JOIN PERSONAS_FISICAS PF ON PF.COD_PER_FISICA = TO_CHAR(R.CODIGO_CLIENTE)

  POR QUÉ: COD_PER_FISICA es VARCHAR2(15), CODIGO_CLIENTE es NUMBER(22).
  Oracle aplica TO_NUMBER(COD_PER_FISICA) para comparar, invalidando el índice
  PK_PERSONASFISICAS. Con TO_CHAR() convertimos el valor NUMBER (no la columna
  indexada), permitiendo usar el PK.

  Cost: 16,948 --> ~2

  RIESGO: BAJO. TO_CHAR de un NUMBER siempre produce un resultado comparable
  con el VARCHAR2 original. Los CODIGO_CLIENTE son numéricos puros.


  ── CAMBIO #2: CODIGO_EMPRESA en JOIN PR_SOLICITUD_REPRESTAMO ────────────────
  Línea:     3745
  Severidad: ALTA (7% del costo total)

  ANTES:  LEFT JOIN PR_SOLICITUD_REPRESTAMO S ON S.ID_REPRESTAMO = R.ID_REPRESTAMO
  DESPUÉS: LEFT JOIN PR_SOLICITUD_REPRESTAMO S ON S.CODIGO_EMPRESA = R.CODIGO_EMPRESA AND S.ID_REPRESTAMO = R.ID_REPRESTAMO

  POR QUÉ: El PK es (CODIGO_EMPRESA, ID_REPRESTAMO). Sin CODIGO_EMPRESA como
  primera columna del acceso, Oracle no puede usar el PK y hace full table scan
  de 132K filas. Agregando CODIGO_EMPRESA, Oracle usa INDEX UNIQUE SCAN.

  Cost: 1,295 --> ~2

  RIESGO: BAJO. PR_REPRESTAMOS ya tiene CODIGO_EMPRESA; es la misma empresa.
  No cambia el resultado funcional.


  ── CAMBIO #3: COMMIT fuera del FOR loop ─────────────────────────────────────
  Línea:     3838 (eliminado) --> 3858 (nuevo, después del END LOOP)
  Severidad: CRITICA (rendimiento de redo log)

  ANTES:  COMMIT dentro del loop (1 commit por cada fila del lote)
  DESPUÉS: COMMIT después del END LOOP (1 commit por lote completo)

  POR QUÉ: Cada COMMIT genera un flush del redo log buffer al disco. Con un
  lote de 500 registros, son 500 synchronous writes al redo log. Moviendo el
  COMMIT fuera, es 1 solo flush.

  RIESGO: MEDIO. Si el proceso falla a mitad del lote, se hace rollback de
  todo el lote en vez de perder solo la fila actual. Dado que el procedure
  tiene EXCEPTION con logging, el riesgo es aceptable. Los registros fallidos
  se pueden reprocesar.

*/


-- ╔════════════════════════════════════════════════════════════════════════════╗
-- ║  RESUMEN COMPARATIVO                                                      ║
-- ╚════════════════════════════════════════════════════════════════════════════╝

/*
  ╔═══════════════════════════════════╦═══════════════╦════════════════╗
  ║ Métrica                           ║  ANTES        ║  DESPUÉS       ║
  ╠═══════════════════════════════════╬═══════════════╬════════════════╣
  ║ Cost total del cursor             ║ 18,293        ║ ~40            ║
  ║ Full Table Scans                  ║ 2             ║ 0              ║
  ║ Bytes leídos (PERSONAS_FISICAS)   ║ 49 MB         ║ ~31 bytes      ║
  ║ Bytes leídos (PR_SOLICITUD_REP)   ║ 1,164 KB      ║ ~9 bytes       ║
  ║ COMMITs por lote (500 filas)      ║ 500           ║ 1              ║
  ║ Índices creados                   ║ N/A           ║ 0 (ninguno)    ║
  ║ Cambio de interfaz (spec)         ║ N/A           ║ NO             ║
  ╚═══════════════════════════════════╩═══════════════╩════════════════╝
*/
