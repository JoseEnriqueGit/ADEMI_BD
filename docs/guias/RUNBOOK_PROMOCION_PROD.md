# Runbook — Promoción de objetos a PRODUCCIÓN

Documento paraguas del flujo anti-regresión. Equipo pequeño, deploy **manual por Toad**, sin CI ni MCP.
Todo el material vive dentro del repo (portable entre la PC de casa y la del trabajo con VS Code + extensión).

## Principios (las 6 causas raíz que esto cierra)
1. **Baseline real de PROD en git.** "Lo vivo en PROD" deja de vivir en un archivo local de Toad: se versiona
   en `ENTORNOS_ORACLE/Produccion/schemas/<SCHEMA>/<tipo>/<OBJETO>.sql`.
2. **Un solo canónico por objeto/entorno.** Variantes (`_OLD`, `copy`, `_ORIGINAL`, `BACKUP`, `_v1`, `_TEST`)
   van a `backups/sombras_consolidadas/`, nunca dentro de `ENTORNOS_ORACLE/*/schemas/`.
3. **No comparar texto, comparar lógica.** Inventario semántico en vez de diff a ojo.
4. **Reconciliar líneas paralelas.** `git log -- <archivo>` obligatorio antes de promover.
5. **Chequeo semántico.** Literales/funciones/columnas que existían no pueden desaparecer sin justificación.
6. **Procedencia.** Cabecera por archivo + entrada en el CHANGELOG del entorno con el sha.

## Flujo
```
DESARROLLO  ->  QA / QA02  ->  PRODUCCION
   (editas)     (pruebas)     (compuerta: checklist + inventario + CHANGELOG)
```
Promover = **copiar el contenido aprobado al archivo espejo del entorno destino y commitear**.
El archivo espejo del destino es, literalmente, el guion que se pega en Toad.

## Paso 0 — Extraer el baseline VIVO (en Toad, antes de sobrescribir)
```sql
SET LONG 200000
-- Vista:
SELECT DBMS_METADATA.GET_DDL('VIEW','<OBJETO>','<SCHEMA>') FROM dual;
-- Package (spec + body):
SELECT DBMS_METADATA.GET_DDL('PACKAGE','<OBJETO>','<SCHEMA>') FROM dual;
SELECT DBMS_METADATA.GET_DDL('PACKAGE_BODY','<OBJETO>','<SCHEMA>') FROM dual;
-- Procedure / Function:
SELECT DBMS_METADATA.GET_DDL('PROCEDURE','<OBJETO>','<SCHEMA>') FROM dual;
SELECT DBMS_METADATA.GET_DDL('FUNCTION','<OBJETO>','<SCHEMA>') FROM dual;
```
Si `DBMS_METADATA` está restringido: click derecho sobre el objeto en Toad/SQL Developer → *Generate DDL / Script*.
Pegar el resultado en el archivo espejo del entorno + cabecera (`docs/instrucciones_ai/PLANTILLA_CABECERA_PROCEDENCIA.sql`).

## Artefactos por promoción (dentro de la historia)
```
historias/<HISTORIA>/promocion/
  01_baseline_<ENTORNO>_<OBJETO>.sql   <- lo VIVO extraído en el paso 0
  02_propuesto_<OBJETO>.sql            <- lo que se va a desplegar
  03_INVENTARIO_SEMANTICO.md           <- plantilla docs/guias/PLANTILLA_INVENTARIO_SEMANTICO.md
  04_SIGNOFF.md                        <- copia de docs/guias/CHECKLIST_DEPLOY_PROD.md, firmada
```

## Compuerta
Un cambio **NO está promovido a PROD** hasta que:
- existe su entrada en `ENTORNOS_ORACLE/Produccion/CHANGELOG.md` con el sha del baseline y del propuesto, y
- `04_SIGNOFF.md` está completo (0 ELIMINADO sin justificar, paso 8 hecho).

## Apoyo opcional
`tools/guardrail/inventario_semantico.ps1` — pre-rellena el inventario comparando dos `.sql`
(literales, funciones `f_*`, columnas `id_*`). **Asesor, no bloqueante.**

## Objetos críticos
Ver `docs/instrucciones_ai/INVENTARIO_OBJETOS_CRITICOS.md` (lista priorizada cuyo baseline de PROD se
versiona primero, objeto por objeto — nunca el espejo completo de golpe).
