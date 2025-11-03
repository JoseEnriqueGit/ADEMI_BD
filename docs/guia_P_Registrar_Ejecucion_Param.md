## Cómo funciona `P_Registrar_Ejecucion_Param`

1. **Obtiene el historial actual**  
   Lee el valor de `PA.PA_PARAMETROS_MVP` para el parámetro recibido. Si no existe, trabaja con una cadena vacía.

2. **Construye la nueva entrada**  
   Arma un JSON con la fecha/hora actual, la cantidad de registros (`pTotalRegistros`) y la secuencia que corresponde (conteo de entradas existentes + 1).

3. **Concatena y valida tamaño**  
   Une el historial previo con la nueva entrada. Si la cadena supera los 4 000 bytes permitidos por el campo, elimina iterativamente la entrada más antigua hasta que el texto vuelve a caber.

4. **Último recurso**  
   Si aun recortando todas las entradas antiguas la longitud es mayor al límite, conserva solo la nueva entrada (truncada si es necesario) para garantizar que el campo nunca provoque errores.

5. **Actualiza el parámetro**  
   Escribe el resultado en `PA.PA_PARAMETROS_MVP`, dejando el historial limpio y listo para la siguiente ejecución.
