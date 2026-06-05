# _cuarentena — archivos por clasificar

> **Qué es esto.** Zona de espera para archivos dudosos, huérfanos o mal ubicados que **no se borran
> ni se renombran** hasta decidir su destino final caso por caso. Nada aquí es fuente de verdad.
> Es **zona fría**: no la cargues en contexto salvo que el usuario lo pida.
>
> Movido aquí el 2026-06-05 desde la raíz y `backups/` durante la revisión de organización.
> El historial de cada archivo se preserva (`git mv`); usar `git log --follow` para trazarlo.

## Cómo cerrar un ítem
1. Decidir destino real (una historia/caso, `diff/`, `backups/sombras_consolidadas/`, o eliminar).
2. `git mv` al destino con nombre **sin espacios** y, si aplica, cabecera de procedencia.
3. Quitar su fila de esta tabla y registrar la decisión en `docs/memoria/BITACORA.md`.

## Inventario

### Movidos desde la raíz → `_cuarentena/raiz/`

| Archivo (nombre original) | Tamaño | Origen (commit) | Qué parece ser | Destino propuesto (pendiente confirmar) |
|---|---|---|---|---|
| `QA 02 REPRE.sql` | ~709 KB | `20700ac` OPT-015 | Volcado QA02 de PR_PKG_REPRESTAMOS usado como base de medición | `historias/optimizaciones/soporte/` o eliminar (duplica baseline) |
| `QA 02 REPRE Actual.sql` | ~703 KB | `20700ac` OPT-015 | Estado "actual" QA02 para benchmark | idem |
| `QA 02 REPRE TEL BENCH.sql` | ~711 KB | `20700ac` OPT-015 | Benchmark de medición de teléfonos | `historias/.../diagnosticos/` (medición telefonos) |
| `QA 02 REPRE BEFORE MEDICION TELEFONOS.sql` | ~704 KB | `20700ac` OPT-015 | "Antes" de la medición de teléfonos | idem |
| `Before PKM.sql` | 4.4 KB | `8a72e87` OPT-020 | Snippet "antes" (PKM) de validaciones QA02 | dentro de `optimizaciones/descartados/OPT-020_*/` |
| `After PKM.sql` | 4.3 KB | `8a72e87` OPT-020 | Snippet "después" (PKM) | idem |
| `Before Tel.sql` | 2.1 KB | `8a72e87` OPT-020 | Snippet "antes" (teléfono) | idem |
| `After Tel.sql` | 2.0 KB | `8a72e87` OPT-020 | Snippet "después" (teléfono) | idem |

### Movidos desde `backups/` → `_cuarentena/backups/`

| Archivo (nombre original) | Tamaño | Origen (commit) | Qué parece ser | Destino propuesto (pendiente confirmar) |
|---|---|---|---|---|
| `ok.sql` | ~742 KB | `20700ac` OPT-015 | Nombre genérico sin metadato; volcado de PR_PKG_REPRESTAMOS | Identificar versión y eliminar o consolidar en `backups/sombras_consolidadas/` |
| `PR_REPRESTAMOS_DUBLICADO CH.sql` | ~738 KB | `20700ac` OPT-015 | Copia "duplicada" (typo "DUBLICADO"), con espacio | `backups/sombras_consolidadas/` con nombre normalizado o eliminar |

### Documentados pero NO movidos (revisar in situ)

| Archivo | Tamaño | Observación |
|---|---|---|
| `backups/PACKAGE_REPRESTAMOS_DESARROLLO.sql` | ~728 KB | Posible variante canónica de DESARROLLO de PR_PKG_REPRESTAMOS. Confirmar si corresponde a `ENTORNOS_ORACLE/DESARROLLO/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql`; si es redundante, consolidar; si es histórico, mover a `sombras_consolidadas/`. Se deja en sitio hasta confirmar. |
