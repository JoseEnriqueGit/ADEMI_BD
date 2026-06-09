# Cambios del package

El desarrollo se realizara sobre:

`ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql`

Esta carpeta guardara:

- inventario semantico de cambios;
- snapshots del body despues de hitos aprobados;
- comparacion contra `../00_ANTES/`;
- notas de lineas instrumentadas.

La `spec.sql` no se modifica. El body debe compilar despues de cada fase.

## Estado

- `PROPUESTA_INSTRUMENTACION_BODY_QA02.md` - diseno revisado que sirvio de base
  (seccion 4.8 = Incremento B tal como se implemento).
- `body_QA02_PRE_INCREMENTO_A_20260609.sql` - snapshot exacto previo al cambio.
- `body_QA02_INCREMENTO_A_20260609.sql` - snapshot exacto del body con Incremento A.
- `body_QA02_INCREMENTO_A_PROBADO_20260609.sql` - snapshot del body Incremento A
  **tal como quedo probado en QA02** (hash identico al anterior), tomado antes de
  implementar el Incremento B. Es la base del rollback del B.
- `body_QA02_INCREMENTO_B_PROBADO_20260609.sql` - snapshot del body Incremento B
  **tal como quedo probado en QA02**, tomado antes de implementar el Incremento C.
  Es la base del rollback del C.
- El body canonico contiene **A (probado) + B (probado) + C (pendiente de prueba)**:
  - B: helper `track_candidato` + cohorte individual del cierre (FLUJO='CIERRE').
  - C: estado package-private `g_track_*` + helper `track_candidatos_flujo` + captura
    del bruto insertado en las 5 procedures de flujo (seccion 4.9 de la propuesta).
- La `spec.sql` permanece sin cambios.
- Incremento A probado: `53D427AF4F597DB0E063140311AC14C5`, 31/31 metricas conciliadas.
- Incremento B probado: `53D8BBE0BA0E44D9E063140311AC6BC6`, Capa C 1302/1302 == FINAL_*,
  0 nulos/duplicados, costo del MERGE ~0.2 ms/candidato.
- Incremento C: **NO compilado ni probado aun en QA02**; no requiere DDL nuevo.
- Pendiente: prueba del C y capa DIAGNOSTICA.

## Hashes SHA-256

- Antes: `EFD9F8588E9D23FD0B2D685B7A777320EDC86187724BE87557E7780939C748E3`
- Incremento A probado: `D12032ADE3845CDC1F64C3121665878B0B8679A7988CD1699D1E176796A78397`
  (= `body_QA02_INCREMENTO_A_20260609.sql` = `body_QA02_INCREMENTO_A_PROBADO_20260609.sql`
  = `../04_ROLLBACK/ROLLBACK_INCREMENTO_B_BODY_QA02.sql`)
- Incremento B probado: `0C07E500BB10F564B7495B79AE9B41921B2F21692083988D9D073FD88BA499CD`
  (= `body_QA02_INCREMENTO_B_PROBADO_20260609.sql` = `../04_ROLLBACK/ROLLBACK_INCREMENTO_C_BODY_QA02.sql`)
- Incremento C preparado (sin probar): `2254380E9C4D0CB81D139DD47860F9BD030258C415A0F8A9694FB4759531B7FA`
