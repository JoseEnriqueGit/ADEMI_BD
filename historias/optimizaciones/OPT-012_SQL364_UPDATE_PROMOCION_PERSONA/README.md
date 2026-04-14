# OPT-012 - SQL 364: UPDATE PROMOCION_PERSONA (NO OPTIMIZABLE)

- **Paquete**: PR_PKG_REPRESTAMOS
- **Procedure**: P_Registrar_Rechazo (linea ~8585)
- **Entorno**: QA
- **Fecha analisis**: 2026-04-07
- **SQL Quest**: SQL 364 (cost original 8,332)
- **Conclusion**: No optimizable sin cambiar estructura de tabla
- **Orquestador(es)**: Job1=P_Carga_Precalifica_Cancelado (paso 9 via P_Registrar_Rechazo llamado desde P_Registrar_Solicitud)
- **Tipo**: N/A (no optimizable — PK existente ya cubre el WHERE)
- **Medido real**: N/A

## Query analizado

```sql
UPDATE PA.PROMOCION_PERSONA p
   SET P.AUTORIZADO = 'N', P.COD_ORIGEN = 'RD'
 WHERE P.COD_PERSONA = (SELECT CODIGO_CLIENTE
                           FROM PR.PR_REPRESTAMOS r
                          WHERE R.CODIGO_EMPRESA = 1
                            AND r.ID_REPRESTAMO = pIdReprestamo)
   AND P.COD_CANAL = vCanalCore;
```

## Analisis

El cost de 4,149 viene del INDEX RANGE SCAN en `PK_PROMOCION_PERSONA` (cost 4,133).

### PK actual de PROMOCION_PERSONA:
```
PK_PROMOCION_PERSONA (COD_CANAL, COD_PERSONA, FECHA_AUTORIZACION)
```

### Por que no se puede optimizar:

1. **El PK ya cubre las columnas del WHERE** (COD_CANAL y COD_PERSONA)
2. Oracle prefiere el PK (UNIQUE) sobre cualquier indice nuevo
3. Se creo `IDX_PROMO_PERSONA_CANAL(COD_PERSONA, COD_CANAL)` pero Oracle lo ignora porque el PK ya es valido
4. El cost alto (4,133) viene de la cantidad de filas por COD_CANAL, no de falta de indice
5. Cambiar el orden del PK requeriria alterar la estructura de la tabla, impactando otras aplicaciones

### Se intento:
- Crear indice `PA.IDX_PROMO_PERSONA_CANAL(COD_PERSONA, COD_CANAL)` — Oracle no lo uso
- Oracle siempre elige PK_PROMOCION_PERSONA por ser UNIQUE

## Resultados

| Metrica | Original (PDF) | Actual (QA) |
|---------|---------------|-------------|
| Cost total | 8,332 | 4,149 |
| Mejora | | -50.2% (por estadisticas actualizadas, no por cambio nuestro) |

## Indice creado (puede eliminarse)

```sql
-- Este indice no tuvo efecto, puede eliminarse si se desea
DROP INDEX PA.IDX_PROMO_PERSONA_CANAL;
```

## Scripts para Explain Plan

```sql
UPDATE /* OPT-364 */ PA.PROMOCION_PERSONA p
   SET P.AUTORIZADO = 'N', P.COD_ORIGEN = 'RD'
 WHERE P.COD_PERSONA = (SELECT CODIGO_CLIENTE
                           FROM PR.PR_REPRESTAMOS r
                          WHERE R.CODIGO_EMPRESA = 1
                            AND r.ID_REPRESTAMO = 1)
   AND P.COD_CANAL = 'CORE';
```
