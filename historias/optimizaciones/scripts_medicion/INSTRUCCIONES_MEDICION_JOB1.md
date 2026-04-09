# Instrucciones: Medicion ANTES/DESPUES de OPT-004 y OPT-010 en Job 1

> Fecha: 2026-04-08
> Job: JOB_CARGA_PRECALIFICA_RD (diario, cada 5 min)
> Procedimiento: PR.PR_PKG_REPRESTAMOS.P_CARGA_PRECALIFICA_CANCELADO
> Entorno: QA (JOOGANDO@QAORACEL)
> Optimizaciones a medir: OPT-004 (set-based UPDATE) + OPT-010 (NOT EXISTS inline)

---

## Contexto

El Job 1 tiene 2 optimizaciones de **codigo** que estan en el repositorio pero
nunca se compilaron en la BD de QA:

| OPT | Cambio | Impacto |
|-----|--------|---------|
| OPT-004 | Loop row-by-row → 2 UPDATEs set-based en Actualiza_Precalificacion | Elimina N context switches |
| OPT-010 | F_TIENE_GARANTIA() → NOT EXISTS inline en 3 cursores CREDITOS_PROCESAR | Elimina context switch por fila |

## Archivos necesarios

| Archivo | Contenido |
|---------|-----------|
| `body copy.sql` | Paquete actual de la BD (SIN optimizaciones) — para medir ANTES |
| `body_copy_OPT004_010.sql` | Paquete con OPT-004 y OPT-010 aplicadas — para medir DESPUES |
| `04_MEDIR_JOB_CANCELADO.sql` | Script de medicion |

Ambos archivos estan en `historias/optimizaciones/scripts_medicion/`

---

## IMPORTANTE: Ejecutar DESPUES de la medicion de indices

Estas instrucciones asumen que ya completaste la medicion de indices
(INSTRUCCIONES_MEDICION.md) y los 4 indices estan restaurados.

---

## Paso a paso

### Paso 1 — Verificar estado actual
El paquete en la BD debe ser el original (body copy.sql sin cambios).
Verificar:
```sql
SELECT LINE, TEXT FROM ALL_SOURCE
WHERE OWNER = 'PR' AND NAME = 'PR_PKG_REPRESTAMOS' AND TYPE = 'PACKAGE BODY'
AND TEXT LIKE '%OPT-004%';
```
Debe retornar **0 filas**. Si retorna filas, compilar `body copy.sql` primero.

### Paso 2 — Medir ANTES (codigo original)
Abrir: `scripts_medicion/04_MEDIR_JOB_CANCELADO.sql`

1. Activar DBMS Output en Toad
2. Ejecutar con boton Play (no F5)
3. **Ejecutar 3 veces**
4. Descartar la 1ra ejecucion (cold cache)
5. Anotar la 2da y 3ra como **ANTES**

```
ANTES Ejecucion 1 (descartar): elapsed=___ms cpu=___ lio=___
ANTES Ejecucion 2:             elapsed=___ms cpu=___ lio=___
ANTES Ejecucion 3:             elapsed=___ms cpu=___ lio=___
```

### Paso 3 — Compilar paquete con OPT-004 + OPT-010
1. Abrir `scripts_medicion/body_copy_OPT004_010.sql` en Toad
2. Compilar con F9
3. Verificar que compile sin errores
4. Confirmar con:
```sql
SELECT LINE, TEXT FROM ALL_SOURCE
WHERE OWNER = 'PR' AND NAME = 'PR_PKG_REPRESTAMOS' AND TYPE = 'PACKAGE BODY'
AND TEXT LIKE '%OPT-004%';
```
Debe retornar filas con comentarios OPT-004.

### Paso 4 — Medir DESPUES (con OPT-004 + OPT-010)
Abrir: `scripts_medicion/04_MEDIR_JOB_CANCELADO.sql`

1. Ejecutar con boton Play
2. **Ejecutar 3 veces**
3. Descartar la 1ra ejecucion (cold cache)
4. Anotar la 2da y 3ra como **DESPUES**

```
DESPUES Ejecucion 1 (descartar): elapsed=___ms cpu=___ lio=___
DESPUES Ejecucion 2:             elapsed=___ms cpu=___ lio=___
DESPUES Ejecucion 3:             elapsed=___ms cpu=___ lio=___
```

### Paso 5 — Comparar y documentar
Llenar esta tabla con la mediana de ejecuciones 2 y 3:

```
| Metrica        | ANTES (original)   | DESPUES (OPT-004+010) | Mejora |
|----------------|--------------------|-----------------------|--------|
| Elapsed (ms)   |                    |                       |        |
| CPU (centiseg)  |                    |                       |        |
| Logical I/O    |                    |                       |        |
| Physical I/O   |                    |                       |        |
| Redo (bytes)   |                    |                       |        |
```

### Paso 6 — Decidir si mantener o revertir
- **Si mejora**: Dejar el paquete con OPT-004+010 compilado en QA
- **Si no mejora**: Compilar `body copy.sql` para restaurar el original

---

## Si algo sale mal

### Si el paquete no compila:
- Revisar errores en la pestana Messages de Toad
- Si dice "identifier not declared", puede ser una referencia rota
- Compilar `body copy.sql` para restaurar el original

### Si el procedimiento da error:
- Si dice "ORA-04068: existing state of packages has been discarded": es normal despues de recompilar — ejecutar de nuevo
- Si dice otro error: anotar y compilar `body copy.sql` para restaurar
