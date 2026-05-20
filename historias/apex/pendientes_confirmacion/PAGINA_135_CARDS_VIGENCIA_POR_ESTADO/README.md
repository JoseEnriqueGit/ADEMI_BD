# Pagina 135 APEX - Vigencia de certificados solo por ESTADO

## Contexto

- **Ticket**: Pendiente de asignar
- **Pantalla / vista APEX**: Pagina 135 (Panel de Certificado Digital)
- **Region APEX**: Cards de certificados y reporte/tabla de certificados
- **Modulo funcional**: Certificados digitales
- **Tabla base principal**: `CD.CD_CERTIFICADO`
- **Fecha del cambio**: 2026-05-08
- **Cambio anterior relacionado**: `historias/apex/en_qa/PAGINA_135_FILTRO_PRODUCTOS_DIGITALES/README.md` (filtro por productos digitales, 2026-05-01).

## Historia

Yo como negocio requiero que la vigencia de un certificado se evalue unicamente por el campo `ESTADO` y no por la `FEC_VENCIMIENTO`, con el objetivo de que las cards y la tabla del Panel de Certificado Digital muestren los mismos resultados que el campo `ESTATUS` del reporte. Antes del cambio, certificados con `ESTADO = 'A'` (mostrados como `VIGENTE` en la tabla) pero con fecha de vencimiento ya pasada se contabilizaban como vencidos en las cards, lo que producia montos vigentes en `RD$ 0.00` / `US$ 0.00` aun cuando la tabla listaba certificados activos.

Ademas, la card "Total Certificados Abiertos" no era clickeable: tenia `VALOR_FILTRO = NULL` y la columna `CSS_CURSOR` la marcaba como `default`. Negocio requiere que al hacer click se filtre la tabla mostrando todo el universo de certificados (equivalente a "Limpiar Filtros" pero conservando el filtro implicito por click).

Por ultimo, las cards de monto (`Monto en Pesos`, `Monto en Dólares`, `Monto Cancelados (Pesos)`, `Monto Cancelados (Dólares)`) sumaban siempre sobre todo el universo, sin reaccionar al filtro por card. Negocio requiere que al hacer click en `Certificados Vigentes`, `Certificados Vencidos`, `Clientes Externos` o `Empleados`, las 4 cards de monto recalculen sus sumas sobre el subconjunto seleccionado.

## Decision de negocio

La vigencia se rige solo por el campo `ESTADO`:

- `ESTADO IN ('A', 'R')` -> Vigente.
- `ESTADO IN ('C', 'P', 'N', 'I')` -> Vencido / Cancelado.

La columna `FEC_VENCIMIENTO` deja de participar en la clasificacion de vigencia. Se mantiene en la tabla y en los filtros de fecha generales (rangos `:P135_FROM_CANC` / `:P135_TO_CANC`).

## Criterios de aceptacion

1. **Card "Total Certificados Abiertos"** es clickeable y filtra la tabla mostrando todos los certificados del universo base (sin restriccion adicional por estado o moneda).
2. **Card "Certificados Vigentes"** cuenta solo `ESTADO IN ('A', 'R')`.
3. **Card "Certificados Vencidos"** cuenta solo `ESTADO IN ('C', 'P', 'N', 'I')`.
4. **Card "Monto en Pesos"** suma `MONTO` con `COD_MONEDA = '1'` y `ESTADO IN ('A', 'R')` sobre el subconjunto definido por `:P135_FILTRO_CARD`.
5. **Card "Monto en Dólares"** suma `MONTO` con `COD_MONEDA = '2'` y `ESTADO IN ('A', 'R')` sobre el subconjunto definido por `:P135_FILTRO_CARD`.
6. **Card "Monto Cancelados (Pesos)"** suma `MONTO` con `COD_MONEDA = '1'` y `ESTADO IN ('C', 'P', 'N', 'I')` sobre el subconjunto definido por `:P135_FILTRO_CARD`.
7. **Card "Monto Cancelados (Dólares)"** suma `MONTO` con `COD_MONEDA = '2'` y `ESTADO IN ('C', 'P', 'N', 'I')` sobre el subconjunto definido por `:P135_FILTRO_CARD`.
8. **Reactividad de cards de monto**: al hacer click en `Certificados Vigentes`, `Certificados Vencidos`, `Clientes Externos` o `Empleados`, las 4 cards de monto recalculan sus sumas sobre el subconjunto seleccionado.
9. **Cards de conteo independientes**: `Total Certificados Abiertos`, `Vigentes`, `Vencidos`, `Clientes Externos` y `Empleados` siempre representan totales del universo base; no se afectan entre si por el filtro de card.
10. **Coherencia card -> tabla**: hacer click en cualquier card retorna en la tabla el mismo universo de certificados que la card cuenta.
11. **Filtros existentes intactos**: el filtro de productos digitales (310, 311, 313-318), los rangos de fecha (`AND`/`OR`) y los filtros por tipo de cliente se mantienen.

## Cambio funcional realizado

### Region cards (`pagina_135_cards_final_solo_estado.sql`)

| Bloque | Card                          | Antes (2026-05-01)                                                                            | Despues (2026-05-08)                  |
|--------|-------------------------------|-----------------------------------------------------------------------------------------------|---------------------------------------|
| 1      | Total Certificados Abiertos   | `VALOR_FILTRO = NULL` (no clickeable, cursor `default`)                                       | `VALOR_FILTRO = 'TOTAL'` (clickeable, cursor `pointer`) |
| 2      | Certificados Vigentes         | `ESTADO IN ('A','R') AND (FEC_VENCIMIENTO >= TRUNC(SYSDATE) OR FEC_VENCIMIENTO IS NULL)`     | `ESTADO IN ('A','R')`                 |
| 3      | Certificados Vencidos         | `ESTADO IN ('C','P','N','I') OR (ESTADO IN ('A','R') AND FEC_VENCIMIENTO < TRUNC(SYSDATE))`  | `ESTADO IN ('C','P','N','I')`         |
| 4      | Monto en Pesos                | Lee de `CertificadosBase` con condicion de fecha                                              | Lee de `CertificadosFiltrados` con `COD_MONEDA='1' AND ESTADO IN ('A','R')` |
| 5      | Monto en Dólares              | Lee de `CertificadosBase` con condicion de fecha                                              | Lee de `CertificadosFiltrados` con `COD_MONEDA='2' AND ESTADO IN ('A','R')` |
| 8      | Monto Cancelados (Pesos)      | Lee de `CertificadosBase` con rama por fecha                                                  | Lee de `CertificadosFiltrados` con `COD_MONEDA='1' AND ESTADO IN ('C','P','N','I')` |
| 9      | Monto Cancelados (Dólares)    | Lee de `CertificadosBase` con rama por fecha                                                  | Lee de `CertificadosFiltrados` con `COD_MONEDA='2' AND ESTADO IN ('C','P','N','I')` |

Los bloques 6 y 7 (Clientes Externos, Empleados) no cambian.

### CTE nueva: `CertificadosFiltrados`

```sql
CertificadosFiltrados AS (
    SELECT *
    FROM CertificadosBase
    WHERE (
        :P135_FILTRO_CARD IS NULL
        OR :P135_FILTRO_CARD = 'Total Certificados Abiertos'
        OR (:P135_FILTRO_CARD = 'Certificados Vigentes' AND ESTADO IN ('A','R'))
        OR (:P135_FILTRO_CARD = 'Certificados Vencidos' AND ESTADO IN ('C','P','N','I'))
        OR (:P135_FILTRO_CARD = 'Clientes Externos' AND TIPO_CLIENTE = 'Externo')
        OR (:P135_FILTRO_CARD = 'Empleados' AND TIPO_CLIENTE = 'Empleado')
        OR :P135_FILTRO_CARD IN ('Monto en Pesos','Monto en Dólares','Monto Cancelados (Pesos)','Monto Cancelados (Dólares)')
    )
)
```

- Las cards de **conteo** (Bloques 1, 2, 3, 6, 7) siguen leyendo de `CertificadosBase` -> totales del universo, no se afectan entre si.
- Las cards de **monto** (Bloques 4, 5, 8, 9) leen de `CertificadosFiltrados` -> reaccionan al click en Vigentes / Vencidos / Externos / Empleados.
- Click en Total Certificados Abiertos o en una card de monto -> `CertificadosFiltrados = CertificadosBase` (sin restriccion adicional).

### Region reporte/tabla (`pagina_135_reporte_tabla_final_solo_estado.sql`)

Las ramas del bloque `:P135_FILTRO_CARD` se simplifican para que el detalle mostrado coincida con el conteo de la card seleccionada:

- `'Total Certificados Abiertos'` -> rama nueva sin restriccion adicional (deja pasar todo el universo del WHERE base).
- `'Certificados Vigentes'` -> `cd.ESTADO IN ('A','R')`.
- `'Certificados Vencidos'` -> `cd.ESTADO IN ('C','P','N','I')`.
- `'Monto en Pesos'` -> `cd.COD_MONEDA = '1' AND cd.ESTADO IN ('A','R')`.
- `'Monto en Dólares'` -> `cd.COD_MONEDA = '2' AND cd.ESTADO IN ('A','R')`.

Las ramas `'Clientes Externos'` y `'Empleados'` no cambian.

### Nota APEX

El click en la card debe estar conectado a una Dynamic Action que asigne `CARD_TITLE` (`'Total Certificados Abiertos'`) a `:P135_FILTRO_CARD` y refresque la region de la tabla. Si la DA actual depende de un mapeo hardcoded por titulo, hay que agregar la nueva entrada para que el click funcione end-to-end.

## Alcance tecnico

- Cambio aplicado solo a las consultas SQL de las regiones APEX. No se modifican packages, tablas ni objetos Oracle.
- La columna `cd.FEC_VENCIMIENTO` sigue mostrandose en la tabla (`Fecha Vencimiento`) y participa en los filtros de rango de fecha (`P135_FROM_CANC` / `P135_TO_CANC`).

## Evidencia en repositorio

### Version final

- `backups/apex/page_135/2026-05-08/README.md`
- `backups/apex/page_135/2026-05-08/pagina_135_cards_final_solo_estado.sql`
- `backups/apex/page_135/2026-05-08/pagina_135_reporte_tabla_final_solo_estado.sql`

### Respaldo previo

- `backups/apex/page_135/2026-05-08/pagina_135_cards_antes_solo_estado.sql`
- `backups/apex/page_135/2026-05-08/pagina_135_reporte_tabla_antes_solo_estado.sql`

(Equivalentes a la version final de `backups/apex/page_135/2026-05-01/`.)

### Scripts de validacion

- `scripts/01_validar_conteos_solo_estado.sql`
- `scripts/02_validar_montos_solo_estado.sql`

## Validacion sugerida en APEX / Toad

1. Ejecutar `scripts/01_validar_conteos_solo_estado.sql` y comparar contra las cards `Certificados Vigentes` y `Certificados Vencidos`.
2. Ejecutar `scripts/02_validar_montos_solo_estado.sql` y comparar contra las cards `Monto en Pesos`, `Monto en Dólares`, `Monto Cancelados (Pesos)` y `Monto Cancelados (Dólares)`.
3. En APEX, hacer click en cada card filtrable y confirmar que el conteo de la tabla coincide con el numero de la card.
4. Probar con `:P135_LOGICA_FECHA = 'AND'` y `:P135_LOGICA_FECHA = 'OR'`.
5. Validar un caso conocido con `ESTADO = 'A'` y `FEC_VENCIMIENTO < SYSDATE`: debe contarse en `Certificados Vigentes` y su monto debe sumar en `Monto en Pesos` o `Monto en Dólares`.
6. Validar que `Total Certificados Abiertos = Vigentes + Vencidos` (la suma debe cuadrar porque ahora los buckets son particion exacta del campo `ESTADO`).

## Riesgos y observaciones

- Si negocio quiere reincorporar la regla "vencido por fecha" como una card adicional sin tocar la clasificacion principal, hay que agregar una card nueva (por ejemplo `Vencidos por fecha`) en lugar de re-introducir la condicion en las cards actuales.
- El cambio no altera la estructura de la tabla base ni contratos de paquetes; se limita a la consulta SQL de la pagina APEX.
- La validacion final de datos debe hacerse en el entorno APEX donde se aplico el cambio.

## Estado

Implementacion preparada y respaldada en repositorio. Pendiente confirmar entorno APEX donde se aplicara y validacion con negocio.
