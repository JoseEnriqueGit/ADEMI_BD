# CLAUDE.md - Instrucciones para Claude Code

## Contexto del proyecto
Este es un repositorio local de objetos de base de datos Oracle para ADEMI (institución financiera). Contiene PL/SQL packages, tablas, vistas, jobs organizados por entorno (DESARROLLO, QA) y schema (PR, PA, CD, CC, IA, TC).

## Estructura principal
- `ENTORNOS_ORACLE/` - Estructura: `{ENTORNO}/schemas/{SCHEMA}/{tipo_objeto}/`
- `historias/` - Historial de trabajo por ticket. Cada historia tiene README.md, scripts/, y opcionalmente paquetes/, tests/, evidencia/
- `diff/` - Comparaciones before/after de procedimientos
- `docs/` - Documentación (digcert, guías, notas, profiler, QA)
- `backups/` - Respaldos y archivos legacy migrados desde db/ y env/

## Schemas principales
- **PR** (Préstamos): PR_PKG_REPRESTAMOS, PR_PKG_DESEMBOLSO, PR_PKG_PRECALIFICADOS, PKG_RECREDITO, pkg_solicitud_credito, PR_CREDITO
- **PA** (Personas/Admin): PKG_CLIENTE, tablas de agencias/empleados/personas
- **CD** (Certificados): PKG_CD_DEVENG_INTERESES, CD_INTERFAZ_CONSULTA, CD_PKG_REVERSIONES, PKG_CD_INTER, CDUTIL
- **CC** (Cuentas): PKG_INTERFAZ_CC, CC_UTILS (solo QA)
- **IA** (APIs): IA_PKG_APIS, IA_PKG_REGISTRO_SOLICITUD_API
- **TC** (Tarjetas): TC_SOLICITUD (solo QA)

## Convenciones de archivos
- Packages: cada uno en su carpeta con `spec.sql` (header) y `body.sql` (implementation)
- Sin espacios en nombres de archivo/carpeta
- Sin prefijo de schema en nombres de archivo (la carpeta padre ya lo indica)

## Al hacer cambios
1. Modificar el código en `ENTORNOS_ORACLE/{entorno}/schemas/...`
2. Agregar entrada al `CHANGELOG.md` del entorno
3. Si el objeto es crítico (ej: PR_PKG_REPRESTAMOS), agregar entrada a su CHANGELOG.md propio
4. Si es parte de una historia, documentar en `historias/{numero_historia}/`

## Regla de entornos (OBLIGATORIA para todas las skills)
- **SIEMPRE preguntar al usuario** a cuál entorno consultar (DESARROLLO o QA) antes de leer cualquier objeto Oracle (spec.sql, body.sql, tablas, vistas, etc.)
- **Ningún entorno es "fuente de verdad" por defecto.** Ambos pueden diferir y el usuario decide cuál es relevante para la tarea.
- Si un objeto referenciado (tabla, índice, paquete de otro schema) **no existe en el repositorio local**, solicitar al usuario que lo consulte directamente en la base de datos y lo comparta.
- Esta regla aplica a TODAS las skills: oracle-optimize, oracle-explain, y cualquier tarea que involucre leer/modificar objetos de BD.

## Lenguaje
- Responder siempre en español
- Código y objetos Oracle mantienen sus nombres originales
