# ADEMI_BD

Repositorio local de objetos de base de datos Oracle para ADEMI. Contiene paquetes PL/SQL, tablas, vistas, jobs y documentación organizados por entorno y schema.

## Estructura del proyecto

```
ADEMI_BD/
├── ENTORNOS_ORACLE/          Fuente de verdad de objetos DB por entorno
│   ├── DESARROLLO/
│   │   ├── CHANGELOG.md      Registro de cambios en Desarrollo
│   │   └── schemas/
│   │       ├── CC/            Cuentas Corrientes
│   │       ├── CD/            Certificados de Depósito
│   │       ├── IA/            Integración / APIs
│   │       ├── PA/            Personas / Administración
│   │       ├── PR/            Préstamos / Représtamos
│   │       └── SROBLES/       Profiler
│   └── QA/
│       ├── CHANGELOG.md
│       └── schemas/
│           ├── CC/, CD/, IA/, PA/, PR/, TC/
│
├── historias/                 Historial de trabajo por ticket/historia
│   ├── 375_CASOS/
│   ├── 419_CANALES_HABILITADO/
│   ├── 421_DASHBOARD_GERENTES/
│   ├── 441_453_454/
│   └── CHAMPION/
│
├── diff/                      Comparaciones before/after de procedimientos
├── backups/                   Respaldos y archivos legacy
├── docs/                      Documentación general
│   ├── digcert/               Certificado digital
│   ├── guias/                 Guías de desarrollo
│   ├── notas/                 Notas históricas
│   ├── profiler/              Análisis de rendimiento
│   └── QA_PR/                 Documentación QA
└── CLAUDE.md                  Instrucciones para Claude Code
```

## Convenciones

### Estructura por schema
```
schemas/{SCHEMA}/
├── packages/{NOMBRE_PAQUETE}/
│   ├── spec.sql               Especificación (CREATE OR REPLACE PACKAGE)
│   ├── body.sql               Cuerpo (CREATE OR REPLACE PACKAGE BODY)
│   └── CHANGELOG.md           Solo para objetos de alto tráfico
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
Cada historia en `historias/` tiene:
- `README.md` con descripción, estado y entorno desplegado
- `scripts/` con los SQL del cambio
- `paquetes/` con snapshots de paquetes entregados (opcional)
- `tests/` con queries de validación (opcional)
- `evidencia/` con capturas y referencia (opcional)

### CHANGELOGs
- **A nivel de entorno**: `ENTORNOS_ORACLE/{ENV}/CHANGELOG.md`
- **A nivel de objeto**: Solo para paquetes de alto tráfico (ej: PR_PKG_REPRESTAMOS)
