# incorporar_objeto

Incorpora un objeto Oracle faltante al repo usando `docs/instrucciones_ai/BASE_OPERATIVA.md` como fuente de verdad.

**Argumento:** `$ARGUMENTS`

## Reglas mínimas
- Confirmar entorno, schema y tipo de objeto antes de ubicar el archivo si faltan datos.
- Crear o actualizar el objeto en su ruta real dentro de `ENTORNOS_ORACLE/`.
- Normalizar el contenido de forma completa, sin cambiar la lógica.
- Incluir cabecera con entorno, schema, fecha, origen, motivo/caso y observación breve.
- Si hace falta documentación adicional en historias, consultarlo aparte; este comando no la crea automáticamente.
