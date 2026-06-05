# Paquete PA.P_DATOS_PERSONA — pendiente de versionar

**Estado**: carpeta creada, archivos pendientes de llenar.
**Referenciado por**: OPT-015 (rewrite pasos 5-6 de P_Carga_Precalifica_Cancelado).
**Razon**: `F_Validar_Listas_PEP` y `F_Validar_Lista_NEGRA` del paquete `PR.PR_PKG_REPRESTAMOS` son wrappers que llaman a este paquete. Se versiona para referencia futura.

## Que archivos crear

En esta misma carpeta:

- `spec.sql` — Header del paquete (firmas publicas de las funciones).
- `body.sql` — Implementacion completa (las ~967 lineas del codigo fuente).

## Como extraer desde Toad (entorno DESARROLLO = JOOGANDO@ADMQA1_19C)

### Opcion A — Schema Browser (mas rapido)

1. Abrir **Schema Browser** en Toad.
2. Conectar a **JOOGANDO@ADMQA1_19C** (DESARROLLO).
3. Cambiar al schema **PA** (dropdown arriba).
4. Pestana **Packages**.
5. Buscar **P_DATOS_PERSONA**.
6. En el panel derecho hay pestanas **Header** y **Body** (o "Spec" y "Body" segun version).
7. Para cada una:
   - Copiar todo el contenido (Ctrl+A, Ctrl+C).
   - Pegar en un editor de texto.
   - Guardar como `spec.sql` (para Header) y `body.sql` (para Body) en esta carpeta.

### Opcion B — Query DBMS_METADATA (genera DDL limpio)

Ejecutar primero una sola vez:

```sql
BEGIN
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SQLTERMINATOR', TRUE);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'PRETTY', TRUE);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'STORAGE', FALSE);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'TABLESPACE', FALSE);
END;
/
```

Luego cada uno:

```sql
-- Para spec.sql (Header):
SELECT DBMS_METADATA.GET_DDL('PACKAGE_SPEC', 'P_DATOS_PERSONA', 'PA') AS SPEC_DDL FROM DUAL;

-- Para body.sql (Implementation):
SELECT DBMS_METADATA.GET_DDL('PACKAGE_BODY', 'P_DATOS_PERSONA', 'PA') AS BODY_DDL FROM DUAL;
```

Hacer doble click en el valor del CLOB en Data Grid para ver el texto completo, copiar y guardar.

### Opcion C — Si Toad guarda .pks / .pkb en disco automaticamente

Si ves pestanas tipo `P_DATOS_PERSONA.pks` y `P_DATOS_PERSONA.pkb` en Toad, esas son precisamente el spec y el body. Copiarlas a esta carpeta como `spec.sql` y `body.sql`.

## Formato esperado

Ambos archivos deben empezar con `CREATE OR REPLACE ...`:

```sql
-- spec.sql
CREATE OR REPLACE PACKAGE PA.P_DATOS_PERSONA IS
  FUNCTION obt_scoring_persona(...)
    RETURN Number;
  FUNCTION esta_en_lista_pep(...)
    RETURN Boolean;
  -- etc.
END P_DATOS_PERSONA;
/
```

```sql
-- body.sql
CREATE OR REPLACE PACKAGE BODY PA.P_DATOS_PERSONA IS
  FUNCTION obt_scoring_persona(...) RETURN Number IS
    -- ...
  BEGIN
    -- ...
  END;
  -- ... 967 lineas aprox ...
END P_DATOS_PERSONA;
/
```

## Despues de llenar los archivos

1. Eliminar este archivo `_PENDIENTE_LLENAR.md`.
2. Commit: `git add ENTORNOS_ORACLE/DESARROLLO/schemas/PA/packages/P_DATOS_PERSONA/ && git commit -m "Versionar PA.P_DATOS_PERSONA en DESARROLLO"`.
3. Push a la rama.
