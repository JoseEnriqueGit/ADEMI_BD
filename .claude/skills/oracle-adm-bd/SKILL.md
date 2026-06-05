---
name: oracle-adm-bd
description: Usar para analizar, explicar, optimizar o modificar objetos Oracle del repo ADEMI_BD, especialmente packages, vistas, indices, procedimientos, funciones, jobs y scripts QA/produccion.
---

# Oracle ADEMI_BD

## Fuente de verdad
Usar `docs/instrucciones_ai/BASE_OPERATIVA.md` antes de actuar. Esta skill no reemplaza la base: la aterriza para objetos Oracle.

## Reglas obligatorias
- Trabajar siempre en espanol.
- Si el usuario no indica entorno, preguntar antes de leer objetos Oracle.
- Si la ruta ya indica entorno o el usuario lo menciono, usar ese entorno.
- Para analisis u optimizacion, leer el objeto completo.
- Si es package, leer `spec.sql` y `body.sql`.
- Citar siempre `archivo + lineas exactas` al explicar hallazgos o propuestas.
- No cambiar la logica de negocio sin propuesta y aprobacion.
- No tocar `spec` salvo pedido explicito.
- Si falta una dependencia, pedirla al usuario.
- Separar diagnostico, propuesta, implementacion, validacion y rollback.

## Higiene de contexto (que leer / que NO cargar)
- Leer el archivo del objeto puntual (y `spec.sql`+`body.sql` si es package); NO hacer glob del
  schema entero ni cargar `ENTORNOS_ORACLE/**` en bloque.
- Tratar como zona fria (no abrir salvo orden explicita): `backups/`, `_cuarentena/`, `diff/` y
  `docs/notas/NOTAS_HISTORICO.md` completo (para este ultimo, usar `docs/notas/INDICE_NOTAS_HISTORICO.md`).
- Empezar la sesion leyendo `docs/memoria/CONTEXTO_ACTUAL.md` (ver skill `memoria-engram`).

## Flujo minimo
1. Confirmar entorno y objeto.
2. Ubicar archivos reales en `ENTORNOS_ORACLE/`, `historias/`, `diff/` o ruta dada.
3. Leer objeto completo y dependencias relevantes.
4. Diagnosticar con hallazgos priorizados.
5. Proponer cambios con impacto, riesgo y esfuerzo.
6. Implementar solo con aprobacion cuando el flujo lo exija.
7. Preparar validacion en Toad si no se puede ejecutar Oracle localmente.
8. Documentar rollback o estrategia de reversa.

## Ejemplos
- Package: leer spec y body antes de proponer.
- Vista: comparar `CREATE OR REPLACE VIEW`, dependencias e impacto.
- Indice: validar plan, existencia, rollback `DROP INDEX` y ambiente.
- Parametro: identificar tabla fuente, valor actual, cambio propuesto y reversa.
