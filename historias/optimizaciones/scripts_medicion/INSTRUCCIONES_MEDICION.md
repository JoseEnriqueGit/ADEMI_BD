# Instrucciones: Medicion ANTES/DESPUES de indices en JOB_PRECALIFICA_REPRESTAMO

> Fecha: 2026-04-08
> Job: JOB_PRECALIFICA_REPRESTAMO (mensual, dia 1 a las 7am)
> Procedimiento: PR.PR_PKG_REPRESTAMOS.P_CARGA_PRECALIFICA_REPRESTAMO
> Entorno: QA (JOOGANDO@QAORACEL)
> Optimizaciones a medir: 4 indices (OPT-002, 009, 011, 013)

---

## Contexto

Este job reutiliza procedimientos del Job 1 (P_Carga_Precalifica_Cancelado) que se
benefician de 4 indices creados en optimizaciones anteriores. Los indices ya estan
en la BD de QA. Queremos medir cuanto impactan eliminandolos y restaurandolos.

**No hay cambios de codigo** — solo indices.

## Indices involucrados

| OPT | Indice | Tabla | Mejora en Explain Plan |
|-----|--------|-------|----------------------|
| OPT-002 | IDX_DE08_SIB_FECHA_DEUDOR | PA.PA_DE08_SIB | 64,753 -> 39 |
| OPT-009 | IDX_CREDITOS_HI_NOCREDITO | PR.PR_CREDITOS_HI | 17,232 -> 909 |
| OPT-011 | IDX_REPRESTAMOS_EMP_EST_NOCRED | PR.PR_REPRESTAMOS | 10,656 -> 9,748 |
| OPT-013 | IDX_DE05_SIB_CASTIGO_CEDULA | PA.PA_DE05_SIB | 120,122 -> 11 |

---

## Paso a paso

### Paso 1 — Verificar que los indices existen
Ejecutar en Toad:
```sql
SELECT INDEX_NAME, TABLE_NAME, TABLE_OWNER, STATUS
FROM ALL_INDEXES
WHERE INDEX_NAME IN (
    'IDX_DE08_SIB_FECHA_DEUDOR',
    'IDX_CREDITOS_HI_NOCREDITO',
    'IDX_REPRESTAMOS_EMP_EST_NOCRED',
    'IDX_DE05_SIB_CASTIGO_CEDULA'
);
```
Debe retornar 4 filas. Si falta alguno, no se puede medir esa OPT.
**Anotar los resultados.**

### Paso 2 — Eliminar los 4 indices
Abrir y ejecutar: `scripts_medicion/01_DROP_INDICES_ROLLBACK.sql`

Verificar que el SELECT final retorna 0 filas (indices eliminados).

### Paso 3 — Medir ANTES (sin indices)
Abrir: `scripts_medicion/02_MEDIR_JOB_PRECALIFICA.sql`

1. Activar DBMS Output en Toad
2. Ejecutar con boton Play (no F5)
3. **Ejecutar 3 veces**
4. Descartar la 1ra ejecucion (cold cache)
5. Anotar la 2da y 3ra como **ANTES**
6. Copiar las lineas "RESULTADO|..." del output

Formato para anotar:
```
ANTES Ejecucion 1 (descartar): elapsed=___ms cpu=___ lio=___
ANTES Ejecucion 2:             elapsed=___ms cpu=___ lio=___
ANTES Ejecucion 3:             elapsed=___ms cpu=___ lio=___
```

### Paso 4 — Restaurar los 4 indices
Abrir y ejecutar: `scripts_medicion/03_CREATE_INDICES_RESTAURAR.sql`

Verificar que el SELECT final retorna 4 filas con STATUS = VALID.

**NOTA**: La creacion de indices puede tardar unos minutos dependiendo del tamano
de las tablas. Esperar a que termine antes de continuar.

### Paso 5 — Medir DESPUES (con indices)
Abrir: `scripts_medicion/02_MEDIR_JOB_PRECALIFICA.sql`

1. Ejecutar con boton Play
2. **Ejecutar 3 veces**
3. Descartar la 1ra ejecucion (cold cache)
4. Anotar la 2da y 3ra como **DESPUES**

Formato para anotar:
```
DESPUES Ejecucion 1 (descartar): elapsed=___ms cpu=___ lio=___
DESPUES Ejecucion 2:             elapsed=___ms cpu=___ lio=___
DESPUES Ejecucion 3:             elapsed=___ms cpu=___ lio=___
```

### Paso 6 — Comparar y documentar
Llenar esta tabla con los resultados (mediana de ejecuciones 2 y 3):

```
| Metrica        | ANTES (sin indices) | DESPUES (con indices) | Mejora |
|----------------|--------------------|-----------------------|--------|
| Elapsed (ms)   |                    |                       |        |
| CPU (centiseg)  |                    |                       |        |
| Logical I/O    |                    |                       |        |
| Physical I/O   |                    |                       |        |
| Redo (bytes)   |                    |                       |        |
```

---

## Si algo sale mal

### Si un DROP INDEX falla (indice no existe):
Ignorar el error y continuar con los demas.

### Si un CREATE INDEX falla:
- Verificar que el schema tiene permisos con: `SELECT * FROM SESSION_PRIVS;`
- Si el error es "insufficient privileges", pedir a un DBA que lo cree
- Si el error es "name already in use", el indice ya existe — continuar

### Si el procedimiento da error al ejecutarse:
- Anotar el error
- Verificar que el paquete esta VALID: 
```sql
SELECT STATUS FROM ALL_OBJECTS WHERE OBJECT_NAME = 'PR_PKG_REPRESTAMOS' AND OBJECT_TYPE = 'PACKAGE BODY';
```
- Si esta INVALID, recompilar: `ALTER PACKAGE PR.PR_PKG_REPRESTAMOS COMPILE BODY;`

### Si hay resultados inesperados:
- El ANTES deberia ser mas lento que el DESPUES
- Si el ANTES es igual o mas rapido, puede ser por cache — ejecutar mas veces
- Los Logical I/O deberian bajar significativamente con los indices

---

## Archivos en esta carpeta

| Archivo | Que hace |
|---------|----------|
| 01_DROP_INDICES_ROLLBACK.sql | Elimina los 4 indices para medir baseline |
| 02_MEDIR_JOB_PRECALIFICA.sql | Script de medicion con V$MYSTAT |
| 03_CREATE_INDICES_RESTAURAR.sql | Restaura los 4 indices |
| MEDIR_JOB_ANULAR.sql | Script de medicion para el otro job (JOB_ACTUALIZAR_ANULAR_RD) |
| README.md | Explicacion de metricas |
| INSTRUCCIONES_MEDICION.md | Este archivo |
