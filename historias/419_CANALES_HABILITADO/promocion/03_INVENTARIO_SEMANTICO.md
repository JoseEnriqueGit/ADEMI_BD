# Inventario semántico — `PR.PR_V_ENVIO_REPRESTAMOS` (caso del incidente, lleno como ejemplo)

> Este inventario está lleno con el caso REAL del incidente para mostrar el antídoto en acción.
> Si este documento hubiera existido y se hubiera firmado, el deploy regresivo **no** habría pasado:
> tres ítems quedan en `ELIMINADO` **sin justificación** → bandera roja automática.

- **Versión correcta (la que debió quedar):** `ENTORNOS_ORACLE/DESARROLLO/schemas/PR/views/PR_V_ENVIO_REPRESTAMOS.sql`
  (CTE con ramas de campaña — líneas 32-42 y filtro `CANALES_HABILITADOS` líneas 12-14, 78-82)
- **Versión que se desplegó a PROD (regresiva):** comma-joins, `CASE CR.CANAL WHEN '1'.. WHEN '2'..`,
  sin ramas de campaña. **Nunca entró a git** → por eso el diff manual no la atrapó.
- **Historias que tocaron el objeto** (`git log -- ...PR_V_ENVIO_REPRESTAMOS.sql`):
  `IRD-502` (optimización), `OPT-020` (ajustes), y la reorg — **NO aparece la 419**, aunque la
  lógica de campaña vive en la vista. Esa desconexión es la causa raíz #4.

### Ramas / valores de negocio (literales, CASE)
| Ítem | Estado | Justificación (obligatoria si ELIMINADO) |
|---|---|---|
| `'CANAL_EMAIL'` | conservado | |
| `'CANAL_SMS'` | conservado | |
| `'CANAL_CARGA_DIRIGIDA'` | **ELIMINADO** | ⚠️ **SIN JUSTIFICACIÓN — regresión.** Se perdió la diferenciación de cargas dirigidas. |
| `'CANAL_CAMPANA_ESPECIAL'` | **ELIMINADO** | ⚠️ **SIN JUSTIFICACIÓN — regresión.** Se perdió la diferenciación de campañas especiales. |
| `'CANALES_HABILITADOS'` (filtro por `canal_desc`) | **ELIMINADO** | ⚠️ La versión regresiva filtra por `canal` crudo, no por `canal_desc`: cambia la semántica del filtro. |

### Llamadas a funciones / packages
| Función | Estado | Justificación si ELIMINADO |
|---|---|---|
| `pr.pr_pkg_represtamos.f_obt_parametro_represtamo` | conservado | |
| `pr.pr_pkg_represtamos.f_obt_valor_parametros` | conservado | |
| `pr.pr_pkg_represtamos.f_obt_subject_email` | conservado | |
| `pr.pr_pkg_represtamos.f_obt_body_mensaje` | conservado | (cambia la firma de parámetros — revisar compatibilidad) |
| `pr.pr_pkg_represtamos.f_obt_empresa_represtamo` | conservado | |

### Columnas de salida y de filtro clave
| Columna | Estado | Justificación si ELIMINADO |
|---|---|---|
| `id_carga_dirigida` | **ELIMINADO** | ⚠️ Sin esta columna no hay forma de marcar `CANAL_CARGA_DIRIGIDA`. |
| `id_repre_campana_especiales` | **ELIMINADO** | ⚠️ Sin esta columna no hay forma de marcar `CANAL_CAMPANA_ESPECIAL`. |
| `fecha_vencimiento` | conservado (semántica distinta) | regresiva: `fecha + DIA_CADUCA_LINK`; correcta: `TRUNC(LAST_DAY(fecha))`. Revisar cuál es la de negocio. |

### Resultado
- [x] **HAY 5 ítems en ELIMINADO sin justificación válida → NO se debe desplegar.** ❌
- [ ] (No se cumple) Confirmé contra `git log` que la propuesta incluye toda la lógica previa.
- **Conclusión:** la versión correcta es la de `DESARROLLO`. Acción de recuperación: ver
  `docs/guias/RUNBOOK_PROMOCION_PROD.md` (extraer baseline vivo de PROD → confirmar target con el
  usuario → re-desplegar la versión con ramas de campaña → sellar en CHANGELOG).
