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
- [x] **La versión viva en PROD perdió la diferenciación de canales 3/4 → hay que corregir.** ❌
- **Diagnóstico afinado (tras leer los scripts de la 419 y `PR_CANALES_REPRESTAMO`):**
  - PROD **sí conserva** el filtro `CANALES_HABILITADOS`. Lo que perdió es el **mapeo de `CANAL_DESC`**:
    los canales **3** (carga dirigida) y **4** (campaña) caen al `ELSE` y devuelven el código crudo.
  - El mecanismo real es **por código de canal** (1=SMS, 2=EMAIL, 3=dirigida, 4=campaña), confirmado por
    `DIRIGIDA.sql:134` (CANAL=3), `CAMPANA.sql:126` (CANAL=4) y la PK `(empresa,id_represtamo,CANAL)`.
  - ⚠️ **La versión de `DESARROLLO` NO es el target correcto:** usa un modelo distinto
    (deriva dirigida/campaña de `id_carga_dirigida`/`id_repre_campana_especiales` con `canal=SMS`),
    que no coincide con cómo se cargan los datos (canal 3/4). Desplegarla dropearía esas filas.
- **Target de recuperación:** `02_propuesto_PR_V_ENVIO_REPRESTAMOS.sql` — parche quirúrgico sobre lo VIVO,
  solo amplía `CANAL_DESC` (forma parametrizada, parámetros confirmados existentes en PROD).
- Guardrail PROD→propuesto: agrega `canal_carga_dirigida`/`canal_campana_especial`, 0 pérdidas reales
  (la única marca, el literal `'1'`, es el cambio intencional hardcode→parametrizado).
