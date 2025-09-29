# proyectos/ — Soluciones de dominio

Aquí viven desarrollos funcionales (experimentos, dashboards, campañas, certificados digitales, etc.). Cada subcarpeta agrupa scripts, documentación y pruebas específicas del dominio.

Estructura típica por proyecto
- `README.md`: objetivo, dependencias de BD, cómo ejecutar, rollback.
- `*.sql`: scripts de lógica de negocio/consultas.
- `TEST/`: validaciones ligeras (evidencias `SELECT`, conteos, casos de prueba).
- Otras carpetas frecuentes: `SCRIPT OFICIAL/`, `PROMPTS/`, `HEADER.sql/`.

Guía de uso
- Coloca en `proyectos/*` la lógica de negocio y evidencias; deja DDL/objetos persistentes en `db/*`.
- Mantén referencias claras a dependencias de BD (tablas/vistas/paquetes).
- Los nombres de archivos permanecen como están (no convertir espacios a guiones bajos).

Ejemplos
- Ejecutar un script de proyecto: `sqlplus USER/PASS@DB @proyectos/CHAMPION/PR_PKG_REPRESTAMOS.sql`
- Consultas de dashboard: `@proyectos/421 Dashboard para Gerentes y Directores de Negocios/CARDS.SQL`

Al crear un proyecto nuevo
1) Crea la carpeta bajo `proyectos/Nombre del Proyecto`.
2) Añade `README.md` con objetivo, dependencias, ejecución y checklist de rollback.
3) Coloca evidencias en `TEST/` y, si aplica, separa scripts “oficiales” de borradores.

