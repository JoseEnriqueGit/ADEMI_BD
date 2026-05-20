# Plantilla de README — CHAMPION

## Objetivo
- Describa brevemente el propósito del proyecto (ej.: experimento champion/challenger para représtamos, ratio, ventana de medición, KPI).

## Contexto / Alcance
- ¿Qué procesos cubre? (selección, split, notificación, desembolso)
- ¿Qué no cubre? (fuera de alcance)

## Dependencias de BD
- Tablas clave: `PR_REPRESTAMOS`, `PR_SOLICITUD_REPRESTAMO`, `PR_BITACORA_REPRESTAMO`, `PR_CREDITOS`.
- Vistas: `PR.PR_V_ENVIO_REPRESTAMOS` (si aplica).
- Paquetes/procedimientos: `PR.PR_PKG_DESEMBOLSO` (si aplica), `proyectos/CHAMPION/PR_PKG_REPRESTAMOS.sql`.
- Señale versiones/ramas si hay diferencias por entorno (ver `env/`).

## Scripts principales
- Punto de entrada: `proyectos/CHAMPION/PR_PKG_REPRESTAMOS.sql`
- Utilitarios: `proyectos/CHAMPION/BODY SECTION CHAMP.sql`, `HEADER.sql/*` (si aplican)

## Ejecución
- `sqlplus USER/PASS@DB @proyectos/CHAMPION/PR_PKG_REPRESTAMOS.sql`
- Orden recomendado (si aplica): tablas → vistas → paquetes → jobs → scripts.

## Rollback
- Describa cómo revertir: DROP/RENAME objetos, restaurar datos o versiones previas.
- Incluya script de rollback si es necesario.

## Pruebas / Evidencias
- Consultas de verificación (conteos, muestras):
  ```sql
  SELECT COUNT(*) FROM PR_CHAMPION_CHALLENGE_LOG WHERE fecha_proceso >= TRUNC(SYSDATE)-30;
  ```
- Plan de pruebas: casos de éxito, fallas esperadas, rendimiento.

## Riesgos y consideraciones
- Auditoría, idempotencia, impacto en performance, ventanas de ejecución, permisos.

## Métricas
- KPI sugeridos: tasa de conversión, monto desembolsado, tiempo a desembolso.

## Historial de cambios
- Fecha – resumen – autor – referencia a ticket.
