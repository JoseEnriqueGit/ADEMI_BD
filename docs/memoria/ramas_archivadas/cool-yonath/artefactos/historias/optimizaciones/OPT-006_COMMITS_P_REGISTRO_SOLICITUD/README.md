# OPT-006 - Mover COMMIT fuera del FOR loop en P_REGISTRO_SOLICITUD y P_Carga_Precalifica_Manual

- **Paquete**: PR_PKG_REPRESTAMOS
- **Procedures**: P_REGISTRO_SOLICITUD, P_Carga_Precalifica_Manual
- **Entorno**: QA
- **Fecha**: 2026-04-06
- **Git commit original**: 73849ac
- **Orquestador(es)**: Job1=P_Carga_Precalifica_Cancelado (paso 9 P_REGISTRO_SOLICITUD), Job3=P_Carga_Precalifica_Manual (via P_Carga_Precalifica_Manual)
- **Tipo**: Estructural (COMMIT fuera de loops)
- **Medido real**: No (OPT-014 midio solo impacto de indices)

## Problema
Ambos procedures tenian COMMIT dentro del FOR loop, lo que causaba:
1. Un COMMIT por cada iteracion (por cada represtamo en estado 'RE')
2. Overhead de log switch en redo logs por cada COMMIT
3. Mayor tiempo total de ejecucion por el overhead transaccional

### P_REGISTRO_SOLICITUD (~linea 8007)
```
FOR A IN CUR_REPRESTAMO LOOP
    PR.PR_PKG_REPRESTAMOS.P_Registrar_Solicitud(A.ID_REPRESTAMO,...,VMSG);
    PR.PR_PKG_REPRESTAMOS.P_GENERAR_BITACORA(A.ID_REPRESTAMO,...);
    COMMIT;  -- <-- COMMIT por cada fila
END LOOP;
```

### P_Carga_Precalifica_Manual (~linea 8279)
```
FOR A IN CUR_REPRESTAMO LOOP
    PR.PR_PKG_REPRESTAMOS.P_Registra_Solicitud_Dirigida(A.ID_REPRESTAMO,...,VMSG);
    COMMIT;  -- <-- COMMIT por cada fila
END LOOP;
```

## Cambio realizado
Mover el COMMIT fuera del END LOOP para que se haga un solo COMMIT al final de todo el procesamiento.

## Razonamiento
- Un solo COMMIT al final reduce drasticamente el overhead de redo log writes
- Si ocurre un error a mitad del loop, el ROLLBACK automatico deshace todo (comportamiento mas limpio)
- El volumen de datos (represtamos en estado 'RE') es manejable en una sola transaccion

## Como revertir
Compilar rollback.sql en Toad o: `git revert 73849ac`
