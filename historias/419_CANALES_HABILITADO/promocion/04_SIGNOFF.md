# Sign-off de despliegue — `PR.PR_V_ENVIO_REPRESTAMOS`

**Objeto:** `PR.PR_V_ENVIO_REPRESTAMOS`  ·  **Historia/Ticket:** 419 + incidente de regresión  ·  **Entorno destino:** `PRODUCCION`

> Recuperación de la lógica de canales habilitados (mapeo de `CANAL_DESC` para canales 3=dirigida / 4=campaña).
> Cambio quirúrgico sobre la versión VIVA en PROD; solo amplía el `CASE` de `CANAL_DESC` (forma parametrizada).

- [x] **0. Baseline vivo extraído.** DDL VIVO de PROD confirmado por el usuario y versionado en
      `ENTORNOS_ORACLE/Produccion/schemas/PR/views/PR_V_ENVIO_REPRESTAMOS.sql`.
      Commit baseline: `7181eaf` (placeholder) → actualizado con DDL real en este commit.
- [x] **1. Propuesto guardado.** `historias/419_CANALES_HABILITADO/promocion/02_propuesto_PR_V_ENVIO_REPRESTAMOS.sql`.
- [x] **2. Inventario semántico completo.** `03_INVENTARIO_SEMANTICO.md`. Guardrail PROD→propuesto:
      agrega `canal_carga_dirigida`/`canal_campana_especial`; única "pérdida" = literal `'1'` (cambio
      intencional hardcode→`f_obt_parametro_Represtamo('CANAL_SMS')`). **0 pérdidas reales.**
- [x] **3. Reconciliación de líneas paralelas.** `git log` de la vista: IRD-502 + OPT-020 + reorg (no aparece 419).
      Confirmado que el mecanismo real es **por código de canal** (3/4), no el de columnas `id_*` de DESARROLLO.
      La versión de DESARROLLO **descartada** como target (dropearía filas de canal 3/4).
- [ ] **PRE. Verificar `CANALES_HABILITADOS` en PROD.** Correr:
      ```sql
      SELECT codigo_empresa, codigo_mvp, codigo_parametro, valor
      FROM   PA_PARAMETROS_MVP
      WHERE  codigo_parametro IN ('CANAL_SMS','CANAL_EMAIL','CANAL_CARGA_DIRIGIDA',
                                  'CANAL_CAMPANA_ESPECIAL','CANALES_HABILITADOS');
      ```
      Parámetros `CANAL_CARGA_DIRIGIDA`/`CANAL_CAMPANA_ESPECIAL`: **confirmados existentes** por el usuario.
      ¿`CANALES_HABILITADOS` incluye dirigida/campaña? → `____` (si NO, actualizar también ese parámetro).
- [ ] **4. Probado.** Compilado/probado en QA o QA02. Entorno: `____`
- [ ] **5. Sign-off de segundo par.** Firma: `____` — fecha `____`
- [ ] **6. Pegado en PROD.** Por: `____` — fecha/hora `____`
- [ ] **7. CHANGELOG sellado.** Entrada en `ENTORNOS_ORACLE/Produccion/CHANGELOG.md` con sha baseline + propuesto.
- [ ] **8. Verificación post-deploy.** Re-extraje la vista de PROD; un représtamo de dirigida muestra
      `CANAL_DESC='CANAL_CARGA_DIRIGIDA'` y uno de campaña `='CANAL_CAMPANA_ESPECIAL'`. Actualicé el espejo de PROD.

**Decisión pendiente opcional:** ¿parametrizar también `SUBJECT_EMAIL` (`WHEN CR.CANAL = f_obt_parametro_Represtamo('CANAL_EMAIL')`)
en vez del `WHEN '2'` actual? Hoy se dejó como en PROD para minimizar el diff.
