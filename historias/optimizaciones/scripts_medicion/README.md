# Scripts de Medicion de Rendimiento

> Scripts para medir tiempos de ejecucion ANTES y DESPUES de aplicar optimizaciones.
> Ejecutar en Toad con DBMS Output activado.

## Proceso de medicion

### Paso 1: Medir ANTES (sin cambios)
1. Abrir Toad, conectar a QA (JOOGANDO@QAORACEL)
2. Activar DBMS Output (View > DBMS Output o F6)
3. Ejecutar `MEDIR_JOB_ANULAR.sql` — anotar resultados
4. **Ejecutar 3 veces** y quedarse con la mediana (la 2da o 3ra ejecucion)
5. La 1ra ejecucion puede ser lenta por cold cache — descartarla

### Paso 2: Aplicar cambios
1. Modificar body.sql con los cursores hardcodeados
2. Compilar el paquete en Toad (sin errores)

### Paso 3: Medir DESPUES
1. Ejecutar `MEDIR_JOB_ANULAR.sql` — anotar resultados
2. **Ejecutar 3 veces** y quedarse con la mediana
3. Comparar con los resultados del Paso 1

### Que mide cada metrica
| Metrica | Que significa | Que indica |
|---------|--------------|------------|
| Elapsed (ms) | Tiempo real transcurrido | Tiempo total percibido por el usuario |
| CPU (centiseg) | Tiempo de CPU consumido | Cuanto trabajo real hizo la CPU |
| Logical I/O | Lecturas de buffer cache | Cantidad de bloques leidos (memoria) |
| Physical I/O | Lecturas de disco | Cantidad de bloques leidos desde disco |
| Redo generado | Bytes de redo log | Cantidad de cambios escritos (COMMITs) |

### Interpretar resultados
- **Elapsed y CPU bajan**: La optimizacion funciona
- **Logical I/O baja**: El query accede a menos datos (indices)
- **Physical I/O baja**: Menos lecturas de disco
- **Redo baja**: Menos COMMITs innecesarios (OPT-003)
- Si solo **Elapsed** baja pero CPU no: la mejora fue en esperas I/O, no en logica

### Nota sobre V$MYSTAT
Si el usuario no tiene permisos a V$MYSTAT, las metricas de CPU/LIO/PIO/Redo
mostraran -1. En ese caso solo se tiene el elapsed time.
Para dar permisos:
```sql
-- Ejecutar como DBA:
GRANT SELECT ON V_$MYSTAT TO JOOGANDO;
GRANT SELECT ON V_$STATNAME TO JOOGANDO;
```

## Scripts disponibles

| Script | Job que mide | Procedimiento |
|--------|-------------|---------------|
| MEDIR_JOB_ANULAR.sql | JOB_ACTUALIZAR_ANULAR_RD | P_ACTUALIZAR_ANULAR_REPRESTAMO |
