# contexto

## Cuándo usarlo
Al iniciar una sesión en ADEMI_BD, para reconstruir el contexto del proyecto desde la memoria del repo.

## Prompt base
```text
Reconstruye el contexto del proyecto.

1. Lee docs/memoria/CONTEXTO_ACTUAL.md (punto de entrada único).
2. Si la tarea lo pide, abre historias/INVENTARIO.md y solo la carpeta del caso concreto.
3. Revisa git log --oneline -20 y las últimas entradas de docs/memoria/BITACORA.md.
4. Respeta la higiene de contexto: no abras backups/, _cuarentena/, diff/ ni volcados grandes
   (docs/notas/NOTAS_HISTORICO.md completo) salvo que te lo pida explícitamente.

Resume el estado actual: qué está vivo en PROD, qué está abierto y qué sigue pendiente.
```
