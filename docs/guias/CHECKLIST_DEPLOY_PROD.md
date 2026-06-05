# Checklist de despliegue a PRODUCCIÓN (1 página)

> Copiar esta lista dentro de `historias/<HISTORIA>/promocion/04_SIGNOFF.md` y marcar casilla por casilla.
> Pensada para equipo pequeño con deploy manual por Toad. Sin servidor CI, sin MCP, todo dentro del repo.
> El orden importa: el paso 0 y el paso 8 son los que habrían evitado el incidente de `PR_V_ENVIO_REPRESTAMOS`.

**Objeto:** `SCHEMA.OBJETO`  ·  **Historia/Ticket:** `____`  ·  **Entorno destino:** `PRODUCCION`

- [ ] **0. Baseline vivo extraído.** Extraje de PROD el DDL VIVO actual (Toad: `DBMS_METADATA.GET_DDL`)
      y lo commiteé en `ENTORNOS_ORACLE/Produccion/schemas/.../OBJETO.sql` con cabecera de procedencia.
      Commit baseline: `____`
- [ ] **1. Propuesto guardado.** La versión a desplegar está en `historias/<HISTORIA>/promocion/02_propuesto_OBJETO.sql`.
- [ ] **2. Inventario semántico completo.** `03_INVENTARIO_SEMANTICO.md` lleno: **0 ítems en ELIMINADO sin justificación**.
- [ ] **3. Reconciliación de líneas paralelas (anti-incidente).** Corrí
      `git log -- ENTORNOS_ORACLE/.../OBJETO.sql` y leí **todas** las historias/tickets que tocaron el objeto.
      Confirmo que el propuesto incluye TODA feature ya entregada en otras historias.
      Historias revisadas: `____`
- [ ] **4. Probado.** Compilado/probado en QA o QA02. Entorno de prueba: `____`
- [ ] **5. Sign-off de segundo par.** Otra persona revisó el inventario (o self-review diferido documentado).
      Firma: `____` — fecha `____`
- [ ] **6. Pegado en PROD.** Por: `____` — fecha/hora `____`
- [ ] **7. CHANGELOG sellado.** Entrada en `ENTORNOS_ORACLE/Produccion/CHANGELOG.md` con sha del baseline + propuesto.
- [ ] **8. Verificación post-deploy (anti-incidente).** Re-extraje el objeto de PROD DESPUÉS de pegar
      y confirmé que coincide con `02_propuesto`. Actualicé el archivo espejo de PROD con el DDL re-extraído.

> **Por qué el paso 8 es no negociable:** sin re-extraer, el repo solo refleja *intención*, no *realidad*.
> El incidente fue exactamente eso: lo que terminó vivo en PROD nunca se confirmó contra el repo.
