# apex/

Historias funcionales sobre la aplicacion APEX 106 (Canal Digital) y reportes asociados.

## Estados

- [produccion/](produccion/) — releases confirmados en PROD.
- [en_qa/](en_qa/) — releases probados en QA o DESARROLLO, sin pase a PROD.
- [pendientes_confirmacion/](pendientes_confirmacion/) — historias sin estado documentado en su README. Necesitan revision manual antes de reclasificar.
- [champion/](champion/) — paquetes y plantillas de referencia.

## Regla

Antes de mover una historia desde `pendientes_confirmacion/`, confirmar:
- Si la pagina/region se libero en PROD -> `produccion/`.
- Si solo esta en QA o DESARROLLO -> `en_qa/`.
- Si fue descartada o reemplazada por otra version, agregar nota en `ESTADO.md` y mover a la categoria correspondiente.
