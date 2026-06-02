# tools/guardrail

Apoyo **asesor** (no bloqueante) para el inventario semántico de promoción.
Cero dependencias externas: solo PowerShell (Windows 11) + git. No usa MCP ni toca la base de datos.

## `inventario_semantico.ps1`
Compara dos archivos `.sql` y reporta los **tokens de negocio** que estaban en el baseline y
faltan en el propuesto: literales entre comillas (`'CANAL_CAMPANA_ESPECIAL'`…), llamadas a función
(`f_obt_*`, `paquete.funcion`) e identificadores sensibles (`id_*`, `*_especiales`, `canal*`).

Ignora orden y estilo, así que **sí detecta** una rama que desaparece aunque el objeto se haya
reescrito entero (que es donde el diff a ojo falla).

### Uso
```powershell
powershell -File tools\guardrail\inventario_semantico.ps1 `
  -Origen  ENTORNOS_ORACLE\Produccion\schemas\PR\views\PR_V_ENVIO_REPRESTAMOS.sql `
  -Destino historias\419_CANALES_HABILITADO\promocion\02_propuesto_PR_V_ENVIO_REPRESTAMOS.sql
```

Salida: lista en rojo lo que **posiblemente se perdió**, en amarillo lo agregado.
**Siempre sale con código 0** — su trabajo es pre-rellenar `03_INVENTARIO_SEMANTICO.md`, no decidir.

### Por qué NO es bloqueante
Un regex sobre SQL produce falsos positivos (un alias renombrado legítimamente) y falsos negativos
(un `AND ... IS NULL` que cambia a `IS NOT NULL` dentro de una rama conservada). Un gate bloqueante
en un equipo de 2 entrena a usar `--no-verify` por costumbre y mata el control. El juicio lo pone
el humano en el inventario firmado; el script solo le ahorra trabajo.

### Prueba de calibración
Comparar el canónico actual contra la sombra archivada del incidente reproduce el ruido conocido
(la versión vieja usa `r.id_represtamo = r.id_represtamo || ''`):
```powershell
powershell -File tools\guardrail\inventario_semantico.ps1 `
  -Origen  backups\sombras_consolidadas\DESARROLLO\PR_V_ENVIO_REPRESTAMOS\PR_V_ENVIO_REPRESTAMOS_OLD.sql `
  -Destino ENTORNOS_ORACLE\DESARROLLO\schemas\PR\views\PR_V_ENVIO_REPRESTAMOS.sql
```
