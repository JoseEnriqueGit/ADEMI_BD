# Ramas archivadas

Memoria de ramas que se **dejaron de lado / reemplazaron** y se borrarán del remoto. Antes de
borrarlas se documenta aquí su objetivo y se preservan sus artefactos únicos, para no perder
conocimiento ni código. **Zona fría:** consultar solo si se va a retomar ese trabajo.

| Rama | Estado | Objetivo en una línea | Carpeta |
|---|---|---|---|
| `feature/api-bitacora-logs` | Descartada (no promovida) | Componente institucional de bitácora/logs para APIs ORDS (Oracle, transacciones autónomas, saneo de payload) | `feature-api-bitacora-logs/` |
| `claude/cool-yonath` | Reemplazada por `master` reorganizado | Línea de desarrollo original (OPT-001..015, mediciones, fixes QA02, documentación) | `cool-yonath/` |

Cada subcarpeta tiene un `README.md` (objetivo, razones, diseño, recuperación) y `artefactos/` con
los archivos preservados (copia histórica, **no** baseline vivo).

## Convención
- Para archivar una rama antes de borrarla: comparar su contenido contra `master` **por hash de
  blob** (no por nombre), preservar solo lo único, documentar objetivo/razón y dejar el tip (sha)
  para recuperación.
- Tras archivar, la rama remota puede borrarse desde GitHub sin pérdida.
