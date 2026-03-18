# Plantilla de README — CD (Certificado Digital)

## Objetivo
- Defina el propósito (ej.: gestión/emisión de certificado digital en Oracle Forms/PLSQL) y KPIs principales.

## Contexto / Alcance
- Flujos cubiertos (cálculo, validaciones, generación, consulta).
- Exclusiones/limitaciones actuales.

## Dependencias de BD
- Tablas clave (listar si aplica).
- Paquetes/procedimientos: `proyectos/CD/PR.pkg_digcert_gestion.sql`, `proyectos/CD/PR.pkg_digcert_gestion SPECS.sql`.
- Simulador (si aplica): `db/packages/DIGCERT_SIMULADOR/*`.
- Señale diferencias por entorno en `env/`.

## Scripts principales
- Entradas y utilitarios relevantes (orden de ejecución recomendado).

## Ejecución
- `sqlplus USER/PASS@DB @proyectos/CD/PR.pkg_digcert_gestion.sql`
- Orden recomendado: tablas → vistas → paquetes → scripts utilitarios.

## Rollback
- Describa revertir cambios (DROP/RENAME, restaurar versión previa, datos).
- Incluya script de rollback si es necesario.

## Pruebas / Evidencias
- Consultas de verificación (SELECT de resultados, conteos, estados).
- Casos de prueba funcionales y de performance.

## Riesgos y consideraciones
- Seguridad de datos sensibles, auditoría, idempotencia y ventanas de mantenimiento.

## Métricas
- Tiempos de respuesta, tasas de éxito/falla, errores por tipo.

## Historial de cambios
- Fecha – resumen – autor – referencia a ticket.
