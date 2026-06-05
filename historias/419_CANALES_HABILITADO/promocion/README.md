# Recuperación de canales habilitados — `PR.PR_V_ENVIO_REPRESTAMOS`

Resumen del cambio y su trazabilidad. Estado: **propuesto, pendiente de desplegar en PROD.**

## Incidente
La vista `PR.PR_V_ENVIO_REPRESTAMOS` se sobrescribió en PROD con una versión más vieja (línea de
optimización) que **perdió la diferenciación de canales de campaña**. La versión regresiva nunca pasó
por git, por lo que la comparación manual contra el archivo local de Toad no la detectó (era reescritura
total → el diff a ojo no sirve).

## Causa raíz
- No había baseline de PROD en git (la "versión de PROD" vivía fuera del repo).
- Dos líneas de trabajo nunca reconciliadas: optimización (IRD-502/OPT-015/OPT-020) vs feature (419).
- La trazabilidad de la 419 ni siquiera listaba la vista (apuntaba al package y al job).

## Diagnóstico final (confirmado en código)
El modelo real de canales es **por código** en `PR_CANALES_REPRESTAMO.CANAL`:

| CANAL | Significado | Evidencia |
|---|---|---|
| 1 | SMS | trigger `TRG_PR_CANAL_REPRESTAMOS` / param `CANAL_SMS` |
| 2 | EMAIL | trigger / param `CANAL_EMAIL` |
| 3 | Carga dirigida | `scripts/DIRIGIDA.sql:134` inserta `CANAL=3` |
| 4 | Campaña especial | `scripts/CAMPANA.sql:126` inserta `CANAL=4` |

PROD **conserva** el filtro `CANALES_HABILITADOS`, pero su `CANAL_DESC` solo mapeaba 1/2; los canales
3 y 4 caían al `ELSE` y devolvían el código crudo (`'3'`/`'4'`), rompiendo el enrutamiento downstream.

> ⚠️ La versión de `DESARROLLO` (CTE) **NO** es el target: usa otro modelo (deriva dirigida/campaña de
> `id_carga_dirigida`/`id_repre_campana_especiales` con `canal=SMS`), que no coincide con cómo se cargan
> los datos. Desplegarla dropearía las filas de canal 3/4.

## El fix
`02_propuesto_PR_V_ENVIO_REPRESTAMOS.sql` — parche **quirúrgico** sobre lo VIVO en PROD: solo amplía el
`CASE` de `CANAL_DESC` para mapear los canales 3 y 4 (forma **parametrizada**;
`f_obt_parametro_Represtamo('CANAL_CARGA_DIRIGIDA'/'CANAL_CAMPANA_ESPECIAL')` — parámetros confirmados
existentes en PROD). Resto del cuerpo idéntico. Guardrail PROD→propuesto: 0 pérdidas reales (la única
marca, el literal `'1'`, es el cambio intencional hardcode→parametrizado).

## Artefactos
- `02_propuesto_PR_V_ENVIO_REPRESTAMOS.sql` — DDL a desplegar.
- `03_INVENTARIO_SEMANTICO.md` — inventario del cambio.
- `04_SIGNOFF.md` — checklist de despliegue (pasos de Toad pendientes).
- Baseline vivo: `ENTORNOS_ORACLE/Produccion/schemas/PR/views/PR_V_ENVIO_REPRESTAMOS.sql`.

## Pendiente (en Toad)
1. Verificar contenido de `CANALES_HABILITADOS` (¿incluye dirigida/campaña? si no, actualizar el parámetro).
2. Probar con `PR_V_ENVIO_REPRESTAMOS_TEST` y agrupar por `CANAL, CANAL_DESC`.
3. Desplegar `02_propuesto` en PROD.
4. Verificar post-deploy y sellar: actualizar el espejo de PROD + finalizar la entrada BORRADOR del
   `Produccion/CHANGELOG.md`.

## Commits (rama `anti-regresion-promocion-prod`)
- `7181eaf` — framework anti-regresión + consolidación de sombras.
- `c15a64e` — baseline PROD real + DDL propuesto + sign-off.
