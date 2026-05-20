# ESTADO — <ID o Nombre del caso>

| Campo | Valor |
|---|---|
| Estado actual | PRODUCCION / QA02 / QA / DESARROLLO / PROBADO_NO_PROMOVIDO / DESCARTADO / DIAGNOSTICO / PROPUESTA / PENDIENTE_CONFIRMAR / INCIDENTE_ABIERTO / SOPORTE |
| Entorno donde se probo | QA / QA02 / DESARROLLO / PROD / ninguno |
| Fecha del ultimo cambio de estado | YYYY-MM-DD |
| Fecha de pase a PROD | YYYY-MM-DD o N/A |
| Objetos tocados | SCHEMA.OBJETO (tipo) — uno por linea |
| Tipo de cambio | Indice / Codigo / Vista / DDL / APEX / Diagnostico / Documentacion |
| Scripts aplicados | rutas relativas |
| Scripts rollback | rutas relativas (o N/A) |
| Resultado de validacion | 1-2 lineas + ruta a evidencia |
| Decision final | promover / no promover / descartar / pendiente — con razon |
| Tracking / historia Jira | IRD-NNN o N/A |
| Cambios relacionados | links a otros ESTADO.md |
| Ultima actualizacion | YYYY-MM-DD, autor |
