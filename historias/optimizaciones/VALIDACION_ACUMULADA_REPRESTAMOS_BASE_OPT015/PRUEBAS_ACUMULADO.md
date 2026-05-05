# OPT-015: Guia de pruebas ANTES/DESPUES para QA

> Objetivo: Documentar con evidencia (screenshots) que OPT-015 reduce el tiempo del job
> sin cambiar los resultados funcionales.
> Entorno: DESARROLLO (JOOGANDO@ADMQA1_19C)
> Fecha: 2026-04-15

---

## Prerequisitos

- Toad conectado a JOOGANDO@ADMQA1_19C
- DBMS Output activado (View > DBMS Output)
- Archivos necesarios:
  - `body_ANTES_BASE_OPT015.sql` (body original)
  - `body_DESPUES_ACUMULADO.sql` (body optimizado)
  - `05_MEDIR_JOB_REPRESTAMOS_ACUMULADO.sql` (script de medicion)
- Los indices de soporte del acumulado deben existir (verificar paso 1)

---

## PASO 1: Verificar prerequisitos

```sql
-- 1a. Verificar indices de soporte
SELECT OWNER, INDEX_NAME, STATUS
FROM ALL_INDEXES
WHERE (OWNER = 'PA' AND INDEX_NAME IN (
          'IDX_DE08_SIB_FECHA_DEUDOR',
          'IDX_DE08_NOCRED_CALIF_FECHA',
          'IDX_DE05_SIB_CASTIGO_CEDULA'
      ))
   OR (OWNER = 'PR' AND INDEX_NAME IN (
          'IDX_CREDITOS_HI_NOCREDITO',
          'IDX_GARANTIAS_TIPO_SB',
          'IDX_REPRESTAMOS_EMP_EST_NOCRED'
      ))
ORDER BY OWNER, INDEX_NAME;
-- Esperado: 6 filas, todas con STATUS = VALID
```
**Screenshot 1a**: Resultado del query de indices

```sql
-- 1b. Verificar cuantos RE hay disponibles
SELECT COUNT(*) FROM PR.PR_REPRESTAMOS
WHERE MODIFICADO_POR IS NULL
  AND FECHA_MODIFICACION >= DATE '2026-04-10'
  AND ESTADO IN ('AN','NP','CP','RXT','RXC');
-- Estos son los RE que se pueden restaurar
```
**Screenshot 1b**: Count de RE disponibles

---

## PASO 2: Restaurar RE para prueba ANTES

```sql
UPDATE PR.PR_REPRESTAMOS SET ESTADO='RE'
WHERE MODIFICADO_POR IS NULL
  AND FECHA_MODIFICACION >= DATE '2026-04-10'
  AND ESTADO IN ('AN','NP','CP','RXT','RXC');
COMMIT;
```
**Screenshot 2**: Debe mostrar "~196 rows updated" + "Commit complete"

---

## PASO 3: Compilar body ORIGINAL (ANTES)

1. Abrir `body_ANTES_BASE_OPT015.sql` en Toad
2. Seleccionar todo (Ctrl+A)
3. Compilar (F9)
4. Verificar que no hay errores

```sql
-- Verificar que NO tiene OPT-015
SELECT COUNT(*) FROM ALL_SOURCE
WHERE OWNER = 'PR' AND NAME = 'PR_PKG_REPRESTAMOS' AND TYPE = 'PACKAGE BODY'
AND TEXT LIKE '%OPT-015%';
-- Esperado: 0
```
**Screenshot 3a**: Compilacion exitosa (sin errores)
**Screenshot 3b**: Query de verificacion = 0

---

## PASO 4: Ejecutar medicion ANTES

1. Abrir `05_MEDIR_JOB_REPRESTAMOS_ACUMULADO.sql` en Toad
2. Ejecutar con F5
3. Esperar a que termine (~14-23 min)
4. Copiar el output completo del DBMS Output

**Screenshot 4a**: Inicio de la ejecucion (encabezado con fecha)
**Screenshot 4b**: Resultado final con tiempos de cada paso
**Screenshot 4c**: Linea TOTAL y RE procesados

Anotar:
- Paso 5 (Precalifica_Repre_Cancelado): _____ seg
- Paso 6 (Precalifica_Repre_Cancelado_hi): _____ seg
- TOTAL: _____ seg (_____ min)
- RE procesados: _____

---

## PASO 5: Restaurar RE para prueba DESPUES

```sql
UPDATE PR.PR_REPRESTAMOS SET ESTADO='RE'
WHERE MODIFICADO_POR IS NULL
  AND FECHA_MODIFICACION >= DATE '2026-04-10'
  AND ESTADO IN ('AN','NP','CP','RXT','RXC');
COMMIT;
```
**Screenshot 5**: "~196 rows updated" + "Commit complete"

---

## PASO 6: Compilar body OPTIMIZADO (DESPUES)

1. Abrir `body_DESPUES_ACUMULADO.sql` en Toad
2. Seleccionar todo (Ctrl+A)
3. Compilar (F9)
4. Verificar que no hay errores

```sql
-- Verificar que SI tiene OPT-015
SELECT COUNT(*) FROM ALL_SOURCE
WHERE OWNER = 'PR' AND NAME = 'PR_PKG_REPRESTAMOS' AND TYPE = 'PACKAGE BODY'
AND TEXT LIKE '%OPT-015%';
-- Esperado: 10
```
**Screenshot 6a**: Compilacion exitosa (sin errores)
**Screenshot 6b**: Query de verificacion = 10

---

## PASO 7: Ejecutar medicion DESPUES

1. Abrir `05_MEDIR_JOB_REPRESTAMOS_ACUMULADO.sql` en Toad
2. Ejecutar con F5
3. Esperar a que termine (~10-12 min)
4. Copiar el output completo del DBMS Output

**Screenshot 7a**: Inicio de la ejecucion (encabezado con fecha)
**Screenshot 7b**: Resultado final con tiempos de cada paso
**Screenshot 7c**: Linea TOTAL y RE procesados

Anotar:
- Paso 5 (Precalifica_Repre_Cancelado): _____ seg
- Paso 6 (Precalifica_Repre_Cancelado_hi): _____ seg
- TOTAL: _____ seg (_____ min)
- RE procesados: _____

---

## PASO 8: Validacion funcional (equivalencia)

### 8a. Restaurar RE y ejecutar DESPUES primero

```sql
-- Restaurar RE
UPDATE PR.PR_REPRESTAMOS SET ESTADO='RE'
WHERE MODIFICADO_POR IS NULL
  AND FECHA_MODIFICACION >= DATE '2026-04-10'
  AND ESTADO IN ('AN','NP','CP','RXT','RXC');
COMMIT;

-- Guardar snapshot de RE iniciales
DROP TABLE JOOGANDO.OPTACUM_RE_ANTES;
CREATE TABLE JOOGANDO.OPTACUM_RE_ANTES AS
SELECT ID_REPRESTAMO, CODIGO_CLIENTE, NO_CREDITO, ESTADO,
       DIAS_ATRASO, MTO_CREDITO_ACTUAL, OBSERVACIONES, CODIGO_PRECALIFICACION
FROM PR.PR_REPRESTAMOS WHERE ESTADO = 'RE';

SELECT COUNT(*) FROM JOOGANDO.OPTACUM_RE_ANTES;
-- Anotar: _____ filas RE iniciales
```
**Screenshot 8a**: Count de RE iniciales

### 8b. Ejecutar job con body DESPUES (OPT-015 ya compilado)

Ejecutar `05_MEDIR_JOB_REPRESTAMOS_ACUMULADO.sql` y luego:

```sql
-- Guardar resultado DESPUES
DROP TABLE JOOGANDO.OPTACUM_RESULTADO_DESPUES;
CREATE TABLE JOOGANDO.OPTACUM_RESULTADO_DESPUES AS
SELECT ID_REPRESTAMO, CODIGO_CLIENTE, NO_CREDITO, ESTADO,
       DIAS_ATRASO, MTO_CREDITO_ACTUAL, OBSERVACIONES, CODIGO_PRECALIFICACION
FROM PR.PR_REPRESTAMOS
WHERE ADICIONADO_POR = USER AND FECHA_ADICION >= TRUNC(SYSDATE);
```

### 8c. Restaurar RE y ejecutar ANTES

```sql
-- Restaurar RE
UPDATE PR.PR_REPRESTAMOS SET ESTADO='RE'
WHERE MODIFICADO_POR IS NULL
  AND FECHA_MODIFICACION >= DATE '2026-04-10'
  AND ESTADO IN ('AN','NP','CP','RXT','RXC');
COMMIT;
```

Compilar `body_ANTES_BASE_OPT015.sql` (F9), ejecutar `05_MEDIR_JOB_REPRESTAMOS_ACUMULADO.sql` y luego:

```sql
-- Guardar resultado ANTES
DROP TABLE JOOGANDO.OPTACUM_RESULTADO_ANTES;
CREATE TABLE JOOGANDO.OPTACUM_RESULTADO_ANTES AS
SELECT ID_REPRESTAMO, CODIGO_CLIENTE, NO_CREDITO, ESTADO,
       DIAS_ATRASO, MTO_CREDITO_ACTUAL, OBSERVACIONES, CODIGO_PRECALIFICACION
FROM PR.PR_REPRESTAMOS
WHERE ADICIONADO_POR = USER AND FECHA_ADICION >= TRUNC(SYSDATE);
```

### 8d. Comparar resultados

```sql
-- Query 1: Filas exclusivas (deben ser pocas o cero)
SELECT 'Solo en DESPUES' ORIGEN, D.CODIGO_CLIENTE, D.NO_CREDITO, D.ESTADO
FROM JOOGANDO.OPTACUM_RESULTADO_DESPUES D
WHERE NOT EXISTS (SELECT 1 FROM JOOGANDO.OPTACUM_RESULTADO_ANTES A
                  WHERE A.CODIGO_CLIENTE = D.CODIGO_CLIENTE AND A.NO_CREDITO = D.NO_CREDITO)
UNION ALL
SELECT 'Solo en ANTES', A.CODIGO_CLIENTE, A.NO_CREDITO, A.ESTADO
FROM JOOGANDO.OPTACUM_RESULTADO_ANTES A
WHERE NOT EXISTS (SELECT 1 FROM JOOGANDO.OPTACUM_RESULTADO_DESPUES D
                  WHERE D.CODIGO_CLIENTE = A.CODIGO_CLIENTE AND D.NO_CREDITO = A.NO_CREDITO);
```
**Screenshot 8d-1**: Resultado Query 1

```sql
-- Query 2: Diferencias en campos clave (debe ser 0 filas)
SELECT A.CODIGO_CLIENTE, A.NO_CREDITO,
       A.ESTADO EST_ANTES, D.ESTADO EST_DESPUES,
       A.DIAS_ATRASO DA_ANTES, D.DIAS_ATRASO DA_DESPUES,
       A.MTO_CREDITO_ACTUAL MTO_ANTES, D.MTO_CREDITO_ACTUAL MTO_DESPUES
FROM JOOGANDO.OPTACUM_RESULTADO_ANTES A
JOIN JOOGANDO.OPTACUM_RESULTADO_DESPUES D
  ON A.CODIGO_CLIENTE = D.CODIGO_CLIENTE AND A.NO_CREDITO = D.NO_CREDITO
WHERE A.ESTADO != D.ESTADO
   OR NVL(A.DIAS_ATRASO,-1) != NVL(D.DIAS_ATRASO,-1)
   OR NVL(A.MTO_CREDITO_ACTUAL,-1) != NVL(D.MTO_CREDITO_ACTUAL,-1);
```
**Screenshot 8d-2**: Resultado Query 2 (esperado: "No rows returned")

---

## PASO 9: Dejar body OPTIMIZADO activo

```sql
-- Compilar body_DESPUES_ACUMULADO.sql (F9)

-- Verificar
SELECT COUNT(*) FROM ALL_SOURCE
WHERE OWNER = 'PR' AND NAME = 'PR_PKG_REPRESTAMOS' AND TYPE = 'PACKAGE BODY'
AND TEXT LIKE '%OPT-015%';
-- Esperado: 10
```
**Screenshot 9**: Verificacion final = 10

---

## PASO 10: Restaurar RE (dejar datos limpios)

```sql
UPDATE PR.PR_REPRESTAMOS SET ESTADO='RE'
WHERE MODIFICADO_POR IS NULL
  AND FECHA_MODIFICACION >= DATE '2026-04-10'
  AND ESTADO IN ('AN','NP','CP','RXT','RXC');
COMMIT;
```

---

## Resultados medidos (DESARROLLO - ADMQA1 - 15/04/2026)

| Metrica | ANTES | DESPUES | Mejora |
|---------|-------|---------|--------|
| Paso 5 (seg) | 312.8 | 265.4 | -15% |
| Paso 6 (seg) | 427.3 | 208.2 | -51% |
| Subtotal 5+6 (seg) | 740.1 | 473.6 | -36% |
| Total job (seg) | 917.3 | 625.4 | -32% |
| Total job (min) | 15.3 | 10.4 | -32% |
| RE procesados | 20 | 21 | |

### Medicion anterior (14/04/2026, misma BD)

| Metrica | ANTES | DESPUES | Mejora |
|---------|-------|---------|--------|
| Paso 5 (seg) | 346.8 | 170.2 | -51% |
| Paso 6 (seg) | 509.2 | 207.9 | -59% |
| Total job (seg) | 1,381 | 680 | -51% |
| Total job (min) | 23 | 11.3 | -51% |

### Validacion de equivalencia (14/04/2026)

- Query 2 (campos clave ESTADO, DIAS_ATRASO, MTO_CREDITO_ACTUAL): **0 diferencias**
- Query 1 (filas exclusivas): 3 filas por variabilidad de ROWNUM (ver nota abajo)

## Nota sobre variabilidad

El cursor usa `ROWNUM <= 5` (LOTE) sin ORDER BY. Oracle no garantiza el orden
de filas entre ejecuciones, por lo que la cantidad de RE procesados puede variar
ligeramente y algunas filas pueden aparecer en una ejecucion pero no en otra.
Esto es comportamiento del codigo original, no introducido por OPT-015.
El Query 2 (campos clave) debe retornar siempre 0 filas.

---

## Archivos incluidos en este paquete

| # | Archivo | Descripcion |
|---|---------|-------------|
| 1 | `body_ANTES_BASE_OPT015.sql` | Body original (sin optimizacion) para compilar como ANTES |
| 2 | `body_DESPUES_ACUMULADO.sql` | Body optimizado del acumulado para compilar como DESPUES |
| 3 | `05_MEDIR_JOB_REPRESTAMOS_ACUMULADO.sql` | Script de medicion V$MYSTAT (ejecutar con F5) |
| 4 | `PRUEBAS_ACUMULADO.md` | Esta guia paso a paso |
| 5 | `01_CREAR_INDICES_SOPORTE_ACUMULADO.sql` | Script para crear indices de soporte requeridos (si faltan) |

## Como replicar las pruebas

### Prerequisitos
- Toad conectado al entorno de pruebas
- DBMS Output activado (View > DBMS Output)
- Los 6 indices de soporte deben existir (ejecutar script #5 si falta alguno)

### Pasos resumidos
1. Verificar prerequisitos (indices + RE disponibles)
2. Restaurar RE con el UPDATE del Paso 2
3. Compilar `body_ANTES_BASE_OPT015.sql` (F9), verificar COUNT OPT-015 = 0
4. Ejecutar `05_MEDIR_JOB_REPRESTAMOS_ACUMULADO.sql` (F5), anotar tiempos
5. Restaurar RE de nuevo
6. Compilar `body_DESPUES_ACUMULADO.sql` (F9), verificar COUNT OPT-015 = 10
7. Ejecutar `05_MEDIR_JOB_REPRESTAMOS_ACUMULADO.sql` (F5), anotar tiempos
8. (Opcional) Validacion de equivalencia con snapshots (Paso 8 de esta guia)
9. Dejar `body_DESPUES_ACUMULADO.sql` compilado
10. Restaurar RE

### Notas importantes
- Ejecutar `SET DEFINE OFF;` antes de compilar los body con F5 (evita error de variables &)
- Si aparece ORA-04021 (timeout lock), cerrar otras sesiones de Toad y reintentar
- Los tiempos varian segun carga del servidor, pero la proporcion de mejora debe mantenerse
- El script de medicion requiere permisos de SELECT sobre V$MYSTAT y V$STATNAME
