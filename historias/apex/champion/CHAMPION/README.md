# Documentación breve (pero detallada) — Champion/Challenger en Représtamo Digital

## 1) Objetivo

Implementar un **experimento controlado** por campañas mensuales para comparar dos rutas operativas:

* **Champion (NP)**: flujo **digital** con notificación por **SMS**.
* **Challenger (LCC)**: flujo **tradicional/oficina** (se usa estado `LCC` en vez de `CC` por colisión con un estado existente).

La asignación a cada grupo es **aleatoria y controlada por ratio** 60/40. Se **miden resultados** en una ventana de **30 días** por campaña.

---

## 2) Alcance actual

* **Selección y división aleatoria** de candidatos (en estado **NP**) por campaña.
* **Registro auditable** de la asignación (log por lote/campaña).
* **Clasificación del desembolso** alcanzado (digital, oficina) con evidencia en bitácora y core.
* **Medición de resultados** (crédito nuevo, monto, fechas) dentro de 30 días posteriores a la inclusión en campaña.

---

## 3) Artefactos principales

### Procedimientos

1. **`P_EJECUTAR_CAMPANA_CHALLENGE(p_error OUT)`**

   * Crea **lote** (`PR_LOTE_ID_SEC.NEXTVAL`), arma nombre “Campaña YYYY-MM”, invoca el split con ratio (hoy 0.40), hace `COMMIT`.
   * Punto de entrada para correr la campaña (p. ej., job mensual).

2. **`P_SPLIT_CHAMPION_CHALLENGER(p_id_lote IN, p_nombre_campana IN, p_challenger_ratio IN DEFAULT 0.40, p_error OUT)`**

   * Trae **candidatos NP**, **baraja** (shuffle con `DBMS_RANDOM`) y asigna exactamente **K = TRUNC(N \* ratio)** a **Challenger (LCC)**; el resto queda **Champion (NP)**.
   * **LCC** genera bitácora con `P_Generar_Bitacora(...)`.
   * Inserta **log** por cada caso: campaña, lote, cliente, crédito, **XCORE**, **monto preaprobado**, **tipo de crédito**, **grupo asignado**, **canal**, **veces\_procesado**, **oficina/zona/oficial**.

3. **`ACTUALIZAR_CHAMPION_CHALLENGE`**

   * Toma el **último lote** del log.
   * Busca en **core** (PR\_CREDITOS) si hay **crédito desembolsado** del mismo cliente **en ≤30 días** desde `fecha_proceso` (distinto del crédito original), y guarda:

     * `no_credito_nuevo_core`, `fecha_desembolso_core`, `monto_desembolsado`.
   * Lee el **último estado digital** del caso en `PR_BITACORA_REPRESTAMO` y lo guarda en `estado_final_digital`.
   * **Clasifica tipo de desembolso** según señales (ver §5).
   * `COMMIT` al cierre del procesamiento.

### Tablas y fuentes

* **`PR_REPRESTAMOS`** / **`PR_SOLICITUD_REPRESTAMO`**: base de candidatos y metadatos (estado NP, id\_represtamo, no\_credito, etc.).
* **`PR_BITACORA_REPRESTAMO`**: señales de flujo digital **CRY** (hito firma/validación digital) y **CRD** (desembolso).
* **`PR_CREDITOS`**: verificación de **desembolso real** (estado `D`, fechas, monto, no\_credito distinto).
* **`PR_CHAMPION_CHALLENGE_LOG`**: **log maestro** del experimento (ver §4).
* **`PA`** (personas/agencias/zona/oficial): nombres y descripciones de apoyo.
* **Secuencia**: `PR_LOTE_ID_SEC`.

---

## 4) Datos registrados en el Log

**Columnas ya usadas/derivadas** (nombres representativos según el código):

* Identificación de muestra: `id_lote`, `nombre_campana`, `fecha_proceso`.
* Clave de caso: `id_represtamo`, `cod_cliente`, `no_credito`, `identificacion`, `nombre_cliente`.
* Métricas de entrada: `xcore_al_preaprobar`, `monto_preaprobado`, `tipo_credito`.
* Asignación: `grupo_asignado` (`CHAMPION` o `CHALLENGER`), `canal_notificacion` (p. ej. `SMS` para Champion), `veces_procesado`.
* Segmentos: `oficina`, `zona`, `oficial`.
* **Resultados** (llenados en `ACTUALIZAR_…`):

  * `tipo_desembolso` (`DESEMBOLSO POR FIRMA DIGITAL` | `DESEMBOLSO POR OFICINA`).
  * `no_credito_nuevo_core`, `fecha_desembolso_core`, `monto_desembolsado`.
  * `estado_final_digital` (último estado en bitácora digital del caso).

> Nota: si un caso **no desembolsa** en la ventana, `tipo_desembolso` queda **nulo**.

---

## 5) Reglas de clasificación del desembolso

**Interpretación operativa de señales (bitácora y core):**

* **Firma Digital (Champion)**: existe **CRY** y **CRD** en la bitácora del représtamo
  → `tipo_desembolso = 'DESEMBOLSO POR FIRMA DIGITAL'`.

* **Oficina (Champion que “saltó” a tradicional)**: existe **CRD** y **no** existe **CRY**
  → `tipo_desembolso = 'DESEMBOLSO POR OFICINA'`.

* **Oficina (Challenger “nativo”)**: `grupo_asignado = 'CHALLENGER'` y se detecta **crédito nuevo** en core (estado `D`) en ≤30 días
  → `tipo_desembolso = 'DESEMBOLSO POR OFICINA'`.

---

## 6) Método de aleatorización actual

* Estrategia **“shuffle + primeros K”** en PL/SQL:

  1. Se cuentan **N** candidatos en NP.
  2. Se calcula **K = TRUNC(N \* ratio)** (ej. 40%).
  3. Se **baraja** la colección con `DBMS_RANDOM` (intercambios i↔j).
  4. Los **primeros K** pasan a **Challenger (LCC)**; el resto permanecen **Champion (NP)**.
* Ventaja: el **porcentaje es exacto** por campaña.
* Consideración: la muestra depende de la mezcla interna; para auditorías se recomienda **registrar `id_lote` y el SQL de selección** (ya se hace), y correr el split **una sola vez por lote**.

---

## 7) Flujo operativo

1. **Inicio de campaña (mensual)**

   * Ejecutar `P_EJECUTAR_CAMPANA_CHALLENGE`.
   * Se crea el **lote**, se corre el **split** con ratio, se **loggea** cada caso y (si aplica) se **marca LCC** en bitácora para los Challenger.

2. **Ejecución de la campaña (≤30 días)**

   * Champion recibe **SMS** y entra al **embudo digital**.
   * Challenger queda **disponible en oficina** (negocios tradicional).

3. **Cierre/medición**

   * Ejecutar `ACTUALIZAR_CHAMPION_CHALLENGE` (revisa **último lote**):

     * Detecta **desembolsos** en core y **señales CRY/CRD**,
     * **Clasifica** el canal final, guarda **monto/fecha/no\_crédito** y **estado final digital**.
