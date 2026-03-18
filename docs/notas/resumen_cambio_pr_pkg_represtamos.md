## Ajuste en el historial de ejecuciones de campañas de represtamos

- **Qué se hizo:** Se creó una pequeña rutina que ordena y limpia el historial que guardamos cada vez que corren las campañas de represtamos (carga dirigida y campaña especial). También se declaró el nuevo procedimiento en el encabezado del paquete para que forme parte del programa oficial.
- **Por qué era necesario:** El historial se almacenaba en un solo campo de texto y, con el paso del tiempo, ese campo crecía más de lo permitido por la base de datos, generando errores y deteniendo la campaña.  
- **Cómo se resolvió:** Ahora, antes de guardar una nueva ejecución, la rutina elimina automáticamente los registros más viejos y se asegura de no superar el tamaño permitido. Además, se reemplazaron las dos actualizaciones manuales que concatenaban texto (`CARGA_DIRIGIDA_EJECUCIONES` y `CAMPANA_ESPECIAL_EJECUCIONES`) para que llamen a la nueva rutina. La información reciente sigue disponible y el proceso vuelve a completarse sin fallas.  
- **Impacto esperado:** Las campañas de represtamos podrán ejecutarse sin interrupciones por este motivo, manteniendo un registro actualizado de las corridas recientes.
