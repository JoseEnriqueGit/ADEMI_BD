# Explicacion del problema y solucion - INC SNAPSHOT TOO OLD

> Documento actualizado al 2026-05-05. Reemplaza el plan anterior que proponia
> reproducir el error en QA/DEV. Esa reproduccion queda descartada por decision
> del equipo.

---

## 1. Resumen en 30 segundos

El job mensual `PR.JOB_PRECALIFICA_REPRESTAMO` corre el dia 1 de cada mes a las
07:00 y ejecuta `PR.PR_PKG_REPRESTAMOS.P_CARGA_PRECALIFICA_CANCELADO`.

En la corrida del 2026-05-01 el scheduler termino como `SUCCEEDED`, pero el trace
de produccion reporto internamente:

```sql
SELECT ID_REPRESTAMO, ESTADO, XCORE_GLOBAL
FROM PR_REPRESTAMOS
WHERE ESTADO = 'RE'
```

con `ORA-01555: snapshot too old`, duracion aproximada de 3,632 segundos
(~60 min) y `UNDO_RETENTION` observado en el trace de ~1,500 segundos (~25 min).

La causa principal sospechosa, ya aceptada por el equipo backend, es el patron en
`P_REGISTRO_SOLICITUD`: cursor abierto sobre `PR_REPRESTAMOS`, llamadas por fila
con commits, y transacciones autonomas que actualizan la misma tabla que el cursor
esta leyendo.

La propuesta tecnica es OPT-017: cargar primero los IDs con `BULK COLLECT`, cerrar
el cursor, y luego iterar la coleccion.

---

## 2. Por que el job aparece SUCCEEDED

El estado `SUCCEEDED` del scheduler no contradice el error. El procedimiento
`P_REGISTRO_SOLICITUD` tiene un `EXCEPTION WHEN OTHERS` que registra el error y no
lo relanza hacia el scheduler.

Referencia:

| Punto | Archivo | Lineas |
|-------|---------|--------|
| Handler de `P_REGISTRO_SOLICITUD` captura errores | `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | 8024-8044 |

Esto explica por que el job puede terminar "bien" para Oracle Scheduler mientras
deja parte del lote sin procesar correctamente.

---

## 3. Causa raiz tecnica

El problema no es solamente que el query tarde. El problema es la combinacion:

1. Cursor abierto mucho tiempo sobre `PR_REPRESTAMOS`.
2. `COMMIT` dentro del procesamiento por fila.
3. `P_Generar_Bitacora` y `P_Validar_Cambio_Estado` como transacciones autonomas.
4. `P_Validar_Cambio_Estado` actualizando `PR_REPRESTAMOS`, la misma tabla del
   cursor padre.
5. UNDO disponible por menos tiempo que la duracion del cursor.

Ese patron es una variante del anti-patron `FETCH across COMMIT`. Oracle necesita
mantener una lectura consistente del cursor desde el momento en que se abrio. Si
esa lectura dura ~60 min y el UNDO disponible ronda ~25 min, el cursor puede
necesitar informacion vieja que ya fue reciclada. Ahi aparece `ORA-01555`.

---

## 4. Evidencia verificada en codigo

La lectura se hizo sobre QA02:

`ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql`

| Evidencia | Lineas |
|-----------|--------|
| `P_REGISTRO_SOLICITUD` declara cursor sobre `PR_REPRESTAMOS WHERE ESTADO='RE'` | 7968-7971 |
| El loop llama `P_Registrar_Solicitud`, luego `P_GENERAR_BITACORA`, luego `COMMIT` | 8014-8020 |
| `P_Generar_Bitacora` declara `PRAGMA AUTONOMOUS_TRANSACTION` | 6001-6009 |
| `P_Generar_Bitacora` llama `P_Validar_Cambio_Estado` | 6023-6026 |
| `P_Validar_Cambio_Estado` declara `PRAGMA AUTONOMOUS_TRANSACTION` | 5879-5882 |
| `P_Validar_Cambio_Estado` actualiza `PR_REPRESTAMOS` | 5902-5912 |
| `P_Validar_Cambio_Estado` hace `COMMIT` despues del update | 5914 |
| `P_Carga_Precalifica_Cancelado` llama `P_REGISTRO_SOLICITUD` | 8126 |
| Luego el orquestador clasifica estados `NP`, `RXT`, `CP`, `AN` | 8171-8186 |
| `F_Existe_Credito` exige solicitud con `TIPO_CREDITO IS NOT NULL` | 9547-9557 |

---

## 5. Por que OPT-004/010/015/016 no son la solucion directa

El analisis inicial apuntaba a optimizaciones pendientes del job. Ese plan queda
corregido:

| Optimizacion | Que afecta | Resuelve directamente este cursor? |
|--------------|------------|------------------------------------|
| OPT-004 | `Actualiza_Precalificacion` | No |
| OPT-010 | `Precalifica_Represtamo` y fiadores | No |
| OPT-015 | `Precalifica_Repre_Cancelado` y `_hi` | No |
| OPT-016 | Indices que pueden ayudar al SELECT | Parcial/marginal |

Estas optimizaciones pueden reducir el tiempo total del job, pero no eliminan el
cursor abierto de `P_REGISTRO_SOLICITUD` mientras se hacen commits y updates
autonomos sobre la misma tabla.

---

## 6. Relacion probable con los RXT

El orquestador llama `P_REGISTRO_SOLICITUD` y despues sigue con validaciones que
clasifican estados. En esa clasificacion, si `F_Existe_Credito` devuelve `FALSE`,
se genera estado `RXT` con observacion de tipo de credito.

Referencia:

| Punto | Archivo | Lineas |
|-------|---------|--------|
| `P_Carga_Precalifica_Cancelado` llama `P_REGISTRO_SOLICITUD` | `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | 8126 |
| Clasificacion a `RXT` si `F_EXISTE_CREDITO = FALSE` | `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | 8180-8181 |
| `F_Existe_Credito` busca `PR_SOLICITUD_REPRESTAMO.TIPO_CREDITO IS NOT NULL` | `ENTORNOS_ORACLE/QA02/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql` | 9547-9557 |

Conexion probable:

1. `P_REGISTRO_SOLICITUD` debia crear solicitudes para los `RE`.
2. Si falla por `ORA-01555`, parte del lote puede quedar sin solicitud completa.
3. El error se captura y el job puede continuar.
4. En la validacion final, esos registros pueden no tener `TIPO_CREDITO`.
5. Entonces `F_Existe_Credito` devuelve `FALSE` y caen en `RXT`.

Esto no demuestra que todos los `RXT` vengan de este incidente, pero si hace que
el error de produccion sea coherente con el sintoma de represtamos rechazados por
tipo de credito.

---

## 7. Solucion propuesta: OPT-017

La idea es cambiar el patron de iteracion en `P_REGISTRO_SOLICITUD`.

Patron actual:

```sql
FOR A IN CUR_REPRESTAMO LOOP
   P_Registrar_Solicitud(A.ID_REPRESTAMO, ...);
   P_GENERAR_BITACORA(A.ID_REPRESTAMO, ...);
   COMMIT;
END LOOP;
```

Patron propuesto:

```sql
TYPE t_ids IS TABLE OF PR_REPRESTAMOS.ID_REPRESTAMO%TYPE;
v_ids t_ids;

SELECT ID_REPRESTAMO
BULK COLLECT INTO v_ids
FROM PR_REPRESTAMOS
WHERE ESTADO = 'RE';

FOR i IN 1 .. v_ids.COUNT LOOP
   P_Registrar_Solicitud(v_ids(i), ...);
   P_GENERAR_BITACORA(v_ids(i), ...);
   COMMIT;
END LOOP;
```

Con esto, el cursor sobre `PR_REPRESTAMOS` se cierra antes de comenzar las
llamadas que hacen commits y transacciones autonomas. Ese es el cambio importante.

---

## 8. Columnas `ESTADO` y `XCORE_GLOBAL`

El cursor original selecciona:

```sql
SELECT ID_REPRESTAMO, ESTADO, XCORE_GLOBAL
```

Pero dentro del loop solo se usa `A.ID_REPRESTAMO`. Por eso la version minima de
OPT-017 puede cargar solo `ID_REPRESTAMO`.

Si se quiere un cambio mas conservador para revision, tambien se puede preservar
la forma de las tres columnas usando un record. Funcionalmente ambas opciones son
validas; la version minima es mas limpia, la version conservadora reduce la
discusion en revision.

---

## 9. Comprobacion en QA/DEV descartada

El equipo consulto la posibilidad de replicar el error en desarrollo o QA y la
respuesta fue que no es viable. Por tanto:

- no se crearan scripts de reproduccion;
- no se bajara `UNDO_RETENTION` en QA;
- no se crearan tablas clon;
- no se crearan procedimientos clon;
- no se generara presion concurrente artificial;
- no se documentara un "antes/despues" basado en reproduccion local.

La validacion se hara con:

1. evidencia del trace de PROD;
2. lectura de codigo;
3. validaciones no destructivas con DBA;
4. compilacion/regresion basica en QA cuando exista OPT-017;
5. monitoreo de la corrida productiva posterior al pase.

---

## 10. Confianza y riesgos residuales

Sin reproduccion en QA/DEV, la confianza queda asi:

| Escenario | Probabilidad estimada |
|-----------|----------------------|
| OPT-017 resuelve el `ORA-01555` de este cursor | ~90% |
| OPT-017 resuelve este cursor, pero queda otro foco de riesgo en el job | ~7% |
| El diagnostico esta incompleto o hay otra causa dominante | ~3% |

Riesgos residuales:

- que exista otro cursor largo con patron similar en otro paso;
- que el UNDO de PROD este subdimensionado para otros queries largos;
- que parte de los `RXT` tenga otra causa independiente;
- que el flag de estado no este configurado como asumimos y haya que ajustar la
  explicacion del update a `PR_REPRESTAMOS`.

---

## 11. Validaciones pendientes

Estas validaciones no requieren reproducir el error:

1. Confirmar `UNDO_RETENTION` real en PROD.
2. Revisar tamano y presion del tablespace UNDO en PROD.
3. Confirmar volumen real de `PR_REPRESTAMOS WHERE ESTADO='RE'` en la corrida
   del 2026-05-01.
4. Confirmar actividad concurrente sobre `PR_REPRESTAMOS` durante la ventana del
   job.
5. Confirmar `PR_ESTADOS_REPRESTAMO.IND_CAMBIA_ESTADO_REPRE='S'` para
   `CODIGO_ESTADO='RE'`.

---

## 12. Plan actualizado

### Fase 0 - Documentacion
- Dejar el diagnostico y la decision de no reproducir documentados.
- Crear handoff para una sesion nueva.

### Fase 1 - Validaciones no destructivas
- Pedir al DBA los datos de UNDO y volumen.
- Confirmar el flag de estado `RE`.

### Fase 2 - Preparar OPT-017
- Crear carpeta separada:
  `historias/optimizaciones/OPT-017_BULKCOLLECT_P_REGISTRO_SOLICITUD/`.
- Preparar README, BEFORE, AFTER y ROLLBACK.
- No tocar `spec.sql`.
- Cambiar solo `P_REGISTRO_SOLICITUD`, salvo hallazgo nuevo.

### Fase 3 - QA
- Compilar el package.
- Ejecutar regresion funcional basica si el entorno lo permite.
- No declarar que QA reproduce el `ORA-01555`.

### Fase 4 - PROD
- Coordinar ventana.
- Tener rollback listo.
- Considerar mitigacion temporal de UNDO si el pase no llega antes de la
  siguiente corrida.

### Fase 5 - Monitoreo
- Monitorear la corrida del 2026-06-01.
- Confirmar ausencia de `ORA-01555`.
- Comparar conteos de `RE`, solicitudes creadas y `RXT`.

---

## 13. Decisiones cerradas

1. El principal sospechoso es `P_REGISTRO_SOLICITUD`.
2. La solucion conceptual aceptada es OPT-017 con `BULK COLLECT`.
3. No se prepararan scripts de reproduccion en QA/DEV.
4. OPT-004/010/015/016 quedan fuera de la correccion directa de este incidente.
5. No se ha implementado ningun cambio de package en esta carpeta.

## 14. Pendientes antes de implementar

1. Elegir version minima o conservadora para las columnas del bulk collect.
2. Confirmar si se pedira mitigacion temporal al DBA sobre UNDO.
3. Confirmar ventana y restricciones de pase a PROD.
4. Aprobar explicitamente la creacion de la carpeta OPT-017.
