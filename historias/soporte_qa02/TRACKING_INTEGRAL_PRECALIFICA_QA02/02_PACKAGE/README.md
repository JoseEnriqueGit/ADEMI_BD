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

- `PROPUESTA_INSTRUMENTACION_BODY_QA02.md` - diseno revisado que sirvio de base.
- `body_QA02_PRE_INCREMENTO_A_20260609.sql` - snapshot exacto previo al cambio.
- `body_QA02_INCREMENTO_A_20260609.sql` - snapshot exacto del body instrumentado.
- El body canonico contiene el **Incremento A** desde 2026-06-09.
- La `spec.sql` permanece sin cambios.
- Compilado y probado en Toad/QA02 el 2026-06-09.
- Ejecucion validada: `53D427AF4F597DB0E063140311AC14C5`,
  31/31 metricas y conciliaciones correctas.
- Pendiente: Incrementos B/C y capa DIAGNOSTICA.

## Hashes SHA-256

- Antes: `EFD9F8588E9D23FD0B2D685B7A777320EDC86187724BE87557E7780939C748E3`
- Incremento A probado: `D12032ADE3845CDC1F64C3121665878B0B8679A7988CD1699D1E176796A78397`
