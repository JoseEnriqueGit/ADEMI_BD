# ADEMI_BD

Repositorio local de objetos de base de datos Oracle para ADEMI. Contiene paquetes PL/SQL, tablas, vistas, jobs y documentación organizados por entorno y schema, más el historial de trabajo agrupado por tipo y estado.

## Estructura del proyecto

```
ADEMI_BD/
├── ENTORNOS_ORACLE/             Fuente de verdad de objetos DB por entorno
│   ├── DESARROLLO/
│   │   ├── CHANGELOG.md         Registro de cambios en Desarrollo
│   │   └── schemas/             CC, CD, IA, PA, PR, SROBLES
│   ├── QA/
│   │   ├── CHANGELOG.md
│   │   └── schemas/             CC, CD, IA, PA, PR, TC
│   ├── QA02/
│   │   └── schemas/             CC, IA, PA, PR
│   └── Produccion/
│       ├── CHANGELOG.md         Fuente de verdad de qué está en PROD
│       └── schemas/             PA, PR (DDL de los 8 índices del 2026-04-23)
│
├── historias/                   Trazabilidad por tipo y estado
│   ├── INVENTARIO.md            Tabla maestra de estados (empezar aquí)
│   ├── README.md                Convención de carpetas
│   ├── _plantillas/ESTADO.md    Plantilla operativa por caso
│   ├── _promociones/            Eventos cronológicos de pase entre entornos
│   ├── optimizaciones/
│   │   ├── produccion/          OPT con cambio en PROD
│   │   ├── probados_no_promovidos/  OPT probada en QA/QA02/DESA, no en PROD
│   │   ├── descartados/         OPT sin beneficio o reemplazadas
│   │   ├── diagnosticos/        Mediciones, explain plans, equivalencias
│   │   ├── propuestas/          Pendientes de aprobación
│   │   └── soporte/             Scripts de medición, mapas, plantillas
│   ├── incidentes/
│   │   ├── abiertos/, diagnosticos/, cerrados/
│   ├── soporte_qa02/            Fixes QA02 y objetos incorporados
│   └── apex/
│       ├── produccion/, en_qa/, pendientes_confirmacion/, champion/
│
├── diff/                        Comparaciones before/after de procedimientos
├── backups/                     Respaldos y archivos legacy
├── docs/                        Documentación general
│   ├── instrucciones_ai/        BASE_OPERATIVA + referencias por tipo de objeto
│   ├── prompts_codex/           Prompts listos para Codex
│   ├── digcert/, guias/, notas/, profiler/, QA_PR/
└── CLAUDE.md / AGENTS.md        Instrucciones para asistentes
```

## Convenciones

### Estructura por schema
```
schemas/{SCHEMA}/
├── packages/{NOMBRE_PAQUETE}/
│   ├── spec.sql
│   ├── body.sql
│   └── CHANGELOG.md             Solo para objetos de alto tráfico
├── tables/
├── views/
├── procedures/
├── functions/
├── jobs/
├── sequences/
└── triggers/
```

### Nomenclatura
- Carpetas de schema: `MAYÚSCULAS` (PR, PA, CD)
- Carpetas de tipo: `minúsculas` (packages, tables)
- Nombres de paquete: `MAYÚSCULAS` (PR_PKG_REPRESTAMOS)
- Spec/body: siempre `spec.sql` / `body.sql`
- Sin espacios en nombres de archivo o carpeta

### Historias
Cada historia vive en una de las categorías arriba según su estado actual. Estructura por carpeta:
- `README.md` — detalle técnico, decisiones, evidencia.
- `ESTADO.md` — metadato operativo (estado, entorno, fecha, decisión).
- `scripts/`, `evidencia/`, `tests/`, `rollback/` — opcionales según el caso.

Cuando un caso cambia de estado:
1. `git mv` la carpeta a la nueva categoría.
2. Actualizar `ESTADO.md` y `historias/INVENTARIO.md`.
3. Si pasa a PROD, registrar en `ENTORNOS_ORACLE/Produccion/CHANGELOG.md` en el mismo commit.
4. Si es un pase entre entornos, agregar archivo en `historias/_promociones/YYYY-MM-DD_<descripcion>.md`.

### CHANGELOGs
- **A nivel de entorno**: `ENTORNOS_ORACLE/{ENV}/CHANGELOG.md` — fuente de verdad de qué está desplegado.
- **A nivel de objeto**: solo para paquetes de alto tráfico (ej: `PR_PKG_REPRESTAMOS`).

## Fuente de verdad para asistentes

- [docs/instrucciones_ai/BASE_OPERATIVA.md](docs/instrucciones_ai/BASE_OPERATIVA.md) — reglas operativas compartidas.
- Comandos: `/explicar`, `/optimizar`, `/comparar_entornos`, `/incorporar_objeto` (y sus aliases en inglés).
