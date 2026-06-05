# contexto

Reconstruye el contexto del proyecto leyendo la memoria del repo.

Pasos:
1. Lee `docs/memoria/CONTEXTO_ACTUAL.md` (punto de entrada unico).
2. Si la tarea lo pide, abre `historias/INVENTARIO.md` y solo la carpeta del caso concreto.
3. Revisa `git log --oneline -20` y las ultimas entradas de `docs/memoria/BITACORA.md`.
4. Respeta la higiene de contexto (zonas frias) descrita en la skill `memoria-engram`.

Resume el estado actual (vivo en PROD, abierto, pendiente) y, si aplica, atiende:

`$ARGUMENTS`
