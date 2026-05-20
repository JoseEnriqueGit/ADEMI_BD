# OPT-020 - Resultados QA

## 2026-05-18 - Creacion de vistas

El usuario ejecuto los scripts unitarios de creacion de vistas en QA.

### Diagnostico previo

`00_DIAGNOSTICO_EJECUCION.sql` retorno:

| Validacion | Resultado |
|------------|-----------|
| Ejecucion completa | Marca de inicio y marca de fin correctas |
| Privilegios | `CREATE ANY VIEW` y `CREATE VIEW` disponibles |
| Columnas requeridas | 12 columnas encontradas |
| Vistas existentes antes del DDL | 0 filas |

### Creacion de vistas

| Script | Resultado |
|--------|-----------|
| `01A_CREATE_VIEW_CREDITOS_GAR.sql` | `PR.V_REPRE_CREDITOS_GAR` creada y `VALID` |
| `01B_CREATE_VIEW_CREDITOS_HI_GAR.sql` | `PR.V_REPRE_CREDITOS_HI_GAR` creada y `VALID` |

### Equivalencia funcional

`02_VALIDAR_EQUIVALENCIA.sql` retorno:

| Consulta | Resultado |
|----------|-----------|
| Q00 - Vistas requeridas | 2 vistas con `STATUS = VALID` |
| Q00B - Acceso directo a vistas | `V_REPRE_CREDITOS_GAR` = 11,968; `V_REPRE_CREDITOS_HI_GAR` = 0 |
| Q01 - `F_TIENE_GARANTIA` vs `V_REPRE_CREDITOS_GAR` | 0 diferencias |
| Q02 - `F_TIENE_GARANTIA_HISTORICO` vs `V_REPRE_CREDITOS_HI_GAR` | 0 diferencias |
| Q03 - funcion actual `> 0` vs vista actual `EXISTS` | 11,968 vs 11,968 |
| Q04 - funcion historica `> 0` vs vista historica `EXISTS` | 0 vs 0 |

### Accion posterior

Con la equivalencia validada en QA, se puede aplicar el cambio del paquete en una
copia controlada del body, compilar y ejecutar regresion de
`P_Carga_Precalifica_Cancelado`.
