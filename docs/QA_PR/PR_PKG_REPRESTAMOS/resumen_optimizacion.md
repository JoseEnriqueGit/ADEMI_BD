# Optimización de `PR_PKG_REPRESTAMOS`

Este documento describe los ajustes realizados durante la optimización del paquete `PR_PKG_REPRESTAMOS`, manteniendo intacta la lógica de negocio y los comentarios originales solicitados.

## 1. Procedimiento `Precalifica_Represtamo`

- **Centralización de parámetros**: Se almacenan en variables locales las lecturas de parámetros (`f_obt_parametro_represtamo`, `OBT_PARAMETROS`, etc.).  
  **Motivo**: Evitar múltiples invocaciones a las funciones de parámetros por cada fila procesada, reduciendo llamadas a la base y manteniendo un único punto de lectura.

- **Carga set-based**: El cursor con `BULK COLLECT` + `FORALL` se reemplazó por un único `INSERT ... SELECT`.  
  **Motivo**: Ejecutar el filtrado directamente en SQL elimina la sobrecarga PL/SQL, reduce consumo de PGA y evita iterar sobre colecciones que luego se insertan una a una.

- **Actualizaciones y exclusiones por lote**: Las validaciones posteriores (atrasos, tarjetas de crédito, desembolsos recientes, garantías, edad, etc.) se ejecutan con `UPDATE`/`DELETE` set-based filtrando por la marca de proceso (`fecha_proceso`).  
  **Motivo**: Mantener la misma lógica de exclusión pero aplicándola con operaciones masivas que aprovechan índices existentes, reduciendo round-trips y bloqueos fila-a-fila.

- **Flujo de control conservado**: Se mantiene el chequeo de `v_fecha_proceso` y el `COMMIT` final, así como el bloque `EXCEPTION` original con `setError`, cumpliendo con la operación orquestada previa.

## 2. Procedimientos orquestadores (`P_Carga_Precalifica_Cancelado`, `P_Carga_Precalifica_Manual`, `P_Carga_Precalifica_Campana_Especial`)

- **Cacheo de resultados booleanos**: Dentro de los bucles sobre `CUR_REPRESTAMO` se almacenan en variables locales los resultados de `F_Existe_Solicitudes`, `F_Existe_Canales` y `F_EXISTE_CREDITO`.  
  **Motivo**: En la versión previa, cada condición evaluaba las funciones varias veces por registro, provocando lecturas repetidas sobre las mismas tablas. Guardar los resultados mantiene la lógica de decisión pero con una única consulta por función y registro.

- **Generación de bitácoras sin cambios funcionales**: La estructura de `IF/ELSE` que determina qué estado registrar permanece idéntica, únicamente reutilizando los valores precalculados.  
  **Motivo**: Asegurar que los caminos hacia `'NP'`, `'RXT'`, `'CP'` y `'AN'` se mantengan invariantes, limitando los cambios al ámbito de rendimiento.

## 3. Comentarios y estilo

- Se respetó el contenido textual de los comentarios originales, incluyendo tildes o caracteres presentes en el archivo fuente.  
- No se introdujo formateo adicional en los mensajes de error ni se alteraron los `DBMS_OUTPUT` existentes.

## Impacto esperado

- **Menor consumo de CPU y PGA** en `Precalifica_Represtamo`, al eliminar la carga en memoria de colecciones y ejecutar las reglas directamente en SQL.
- **Menor cantidad de consultas repetidas** durante los bucles de los orquestadores, beneficiando el tiempo total del job `P_CARGA_PRECALIFICA_CANCELADO`.
- **Comportamiento funcional intacto**, ya que no se modificaron los criterios de inclusión/exclusión ni los mensajes de trazabilidad.

Se recomienda recompilar el paquete y ejecutar una corrida de prueba del job para validar los tiempos con los mismos parámetros de entrada, comparando con métricas históricas.
