# Inventario de objetos críticos

Lista corta y priorizada de objetos cuyo **baseline de PROD se versiona primero** y que pasan
**siempre** por el runbook de promoción (`docs/guias/RUNBOOK_PROMOCION_PROD.md`).

> No se busca un espejo completo de PROD de un solo golpe (eso no se termina en un equipo de 2).
> Se versiona **objeto por objeto**, la primera vez que cada uno pasa por un despliegue.

Estado del baseline de PROD: `pendiente` = no extraído aún · `versionado` = DDL real de PROD en git.

| # | Objeto | Schema | Tipo | Por qué es crítico | Baseline PROD |
|---|---|---|---|---|---|
| 1 | `PR_V_ENVIO_REPRESTAMOS` | PR | VIEW | Origen del incidente; alimenta el envío de représtamos (SMS/email/campañas). Reescrita varias veces. | **versionado** (DDL real de PROD; fix pendiente de desplegar) |
| 2 | `PR_PKG_REPRESTAMOS` | PR | PACKAGE | Paquete de más tráfico; tiene CHANGELOG propio y múltiples optimizaciones (OPT-0xx). Atomicidad spec+body. | placeholder creado (spec+body) |
| 3 | `JOB_CAMPANA_ESPECIALES` | PR | JOB | Puebla `id_repre_campana_especiales`; si falla, la vista #1 deja de diferenciar campañas (mismo síntoma sin tocar la vista). | pendiente |
| 4 | `PR_PKG_PRECALIFICADOS` | PR | PACKAGE | Precalificación de représtamos; entrada del flujo. | pendiente |
| 5 | `PR_PKG_DESEMBOLSO` | PR | PACKAGE | Desembolso; alto impacto financiero. | pendiente |
| 6 | `PKG_CLIENTE` / `PKG_PERFILCLIENTE` | PA | PACKAGE | Datos de contacto del cliente (tel/email) usados por los envíos. | pendiente |

> Ampliar esta tabla cuando se identifique otro objeto de alto tráfico o alto riesgo de regresión.
> Mantener corta: si crece a 30 objetos, deja de ser una lista de "críticos".

## Cómo crear el baseline de un objeto (gradual, objeto por objeto)
Cuando un objeto pase por el runbook por primera vez, generar su placeholder y pegarle el DDL vivo de PROD:
```powershell
# Package (crea subcarpeta con spec.sql + body.sql):
powershell -File tools\guardrail\nuevo_baseline.ps1 -Entorno Produccion -Schema PR -Tipo packages -Objeto PR_PKG_REPRESTAMOS -Paquete
# Otros (vista, procedure, function, job...):
powershell -File tools\guardrail\nuevo_baseline.ps1 -Entorno Produccion -Schema PR -Tipo jobs -Objeto JOB_CAMPANA_ESPECIALES
```
El script crea un placeholder NO ejecutable con el `DBMS_METADATA.GET_DDL` listo; no sobreescribe si ya existe.
Luego se pega el DDL real extraído de Toad. **No poblar todo PROD de golpe** — solo el objeto que toca.

## Riesgos transversales anotados (del análisis del incidente)
- **Atomicidad spec+body (objeto #2):** desplegar `body` sin su `spec` compatible es otra clase de
  regresión silenciosa. Al promover un package, promover y verificar AMBOS archivos juntos.
- **Trazabilidad objeto↔historia (causa raíz #4):** una historia debe listar en "Objetos afectados"
  los archivos **reales** que toca. Verificar cruzando contra `git diff` de la historia.
  (Caso real: `historias/419_CANALES_HABILITADO` no listaba la vista, aunque la lógica vive en ella.)
