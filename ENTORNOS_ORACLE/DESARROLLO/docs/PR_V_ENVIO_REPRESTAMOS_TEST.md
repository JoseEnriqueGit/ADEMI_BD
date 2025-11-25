# Requisitos para que la vista devuelva filas

- PR_REPRESTAMOS: fila con `codigo_empresa = pr.pr_pkg_represtamos.f_obt_empresa_represtamo`, `estado = 'NP'` y campos NOT NULL completos.
- PR_SOLICITUD_REPRESTAMO: fila hija con el mismo `codigo_empresa / id_represtamo` (lo exige el EXISTS).
- PR_CANALES_REPRESTAMO: al menos un canal para ese `id_represtamo` con `canal` igual a los parametros de paquete (`CANAL_EMAIL` o `CANAL_SMS`) y un valor de contacto.
- Parametria: la lista `CANALES_HABILITADOS` debe contener la etiqueta resultante (`CANAL_EMAIL`, `CANAL_SMS`, `CANAL_CARGA_DIRIGIDA`, `CANAL_CAMPANA_ESPECIAL`).
- Condicion por canal:
  - Email: `canal = CANAL_EMAIL` y `id_carga_dirigida` e `id_repre_campana_especiales` en NULL.
  - SMS estandar: `canal = CANAL_SMS` y ambos NULL.
  - SMS carga dirigida: `canal = CANAL_SMS` e `id_carga_dirigida` NOT NULL.
  - SMS campana especial: `canal = CANAL_SMS` e `id_repre_campana_especiales` NOT NULL.

## Checks rapidos en SQL Developer (solo lectura)

```sql
SELECT pr.pr_pkg_represtamos.f_obt_empresa_represtamo FROM dual;
SELECT pr.pr_pkg_represtamos.f_obt_parametro_represtamo('CANAL_EMAIL') AS canal_email,
       pr.pr_pkg_represtamos.f_obt_parametro_represtamo('CANAL_SMS')   AS canal_sms
FROM dual;

SELECT *
FROM TABLE(pr.pr_pkg_represtamos.f_obt_valor_parametros('CANALES_HABILITADOS'));
```

## Guia minima para poblar datos de prueba

1. Inserta en PR_REPRESTAMOS con `estado = 'NP'`; respeta NOT NULL con datos dummy coherentes.
2. Inserta la fila correspondiente en PR_SOLICITUD_REPRESTAMO con el mismo `codigo_empresa/id_represtamo`; al menos `estado` y los NOT NULL.
3. Inserta en PR_CANALES_REPRESTAMO el canal que quieras probar:

```sql
-- Ejemplo SMS estandar
INSERT INTO pr.pr_canales_represtamo(codigo_empresa,id_represtamo,canal,valor,adicionado_por)
VALUES (:empresa, :id_rep, pr.pr_pkg_represtamos.f_obt_parametro_represtamo('CANAL_SMS'),
        '8095550000', USER);

-- Ejemplo Email
INSERT INTO pr.pr_canales_represtamo(codigo_empresa,id_represtamo,canal,valor,adicionado_por)
VALUES (:empresa, :id_rep, pr.pr_pkg_represtamos.f_obt_parametro_represtamo('CANAL_EMAIL'),
        'cliente@correo.com', USER);
```

4. Para “carga dirigida”, llena `id_carga_dirigida` en PR_REPRESTAMOS; para “campana especial”, llena `id_repre_campana_especiales`.
5. `COMMIT;` y luego:

```sql
SELECT * FROM pr.pr_v_envio_represtamos WHERE id_represtamo = :id_rep;
```

Con estos requisitos la vista debe devolver filas al instante en SQL Developer.

# Script de pruebas para poner todos los représtamos en NP

```sql
-- 1) Foto inicial
COLUMN estado FORMAT A5
SELECT estado, COUNT(*) AS cnt
FROM   pr.pr_represtamos
GROUP  BY estado
ORDER  BY estado;

-- 2) Actualizar solo los que no estan ya en NP
UPDATE pr.pr_represtamos r
SET    r.estado = 'NP'
WHERE  r.estado <> 'NP';

-- 3) Ver cuantas filas se tocaron
SELECT SQL%ROWCOUNT AS filas_actualizadas FROM dual;

-- 4) Foto final
SELECT estado, COUNT(*) AS cnt
FROM   pr.pr_represtamos
GROUP  BY estado
ORDER  BY estado;

COMMIT;
```

Notas:
- El trigger `TRG_BUI_PR_REPRESTAMOS` propagara el nuevo estado a `PR_SOLICITUD_REPRESTAMO`, asi que no hace falta actualizarla manualmente.
- Si quieres limitar a una empresa especifica, agrega `AND r.codigo_empresa = <empresa>` en el `WHERE`.
