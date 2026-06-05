# Índice — NOTAS_HISTORICO.md

> **Zona fría.** `docs/notas/NOTAS_HISTORICO.md` es un volcado de ~27.162 líneas: una intro de chat
> (líneas 1–8) seguida del **cuerpo completo del package `PR.PR_PKG_REPRESTAMOS`** (un único
> `create or replace PACKAGE BODY` desde la línea 9). **No lo cargues entero.** Usa este índice para
> saltar al subprograma con `Read(offset, limit)` o `grep`.
>
> Nota: la fuente de verdad del package vivo está en
> `ENTORNOS_ORACLE/{ENTORNO}/schemas/PR/packages/PR_PKG_REPRESTAMOS/body.sql`. Este volcado es
> histórico/contexto; ante dudas de qué está desplegado, manda el entorno, no este archivo.

## Cómo usarlo
- Para leer un subprograma: `Read` con `offset` = la línea de inicio (de la tabla) y `limit` hasta
  la línea del siguiente subprograma.
- Para buscar texto puntual: `grep -n "<patron>" docs/notas/NOTAS_HISTORICO.md`.

## Mapa por bloques (línea de inicio)

### Precalificación
| Línea | Subprograma |
|---|---|
| 13 | PROCEDURE Precalifica_Represtamo |
| 773 | PROCEDURE Precalifica_Repre_Cancelado |
| 1543 | PROCEDURE Precalifica_Repre_Cancelado_hi |
| 2289 | PROCEDURE Precalifica_Represtamo_fiadores |
| 2995 | PROCEDURE Precalifica_Represtamo_fiadores_hi |
| 3753 | PROCEDURE Precalifica_Carga_Dirigida |
| 4471 | PROCEDURE Precalifica_Campana_Especiales |

### Actualización de precalificación / XCORE
| Línea | Subprograma |
|---|---|
| 5185 | PROCEDURE Actualiza_Precalificacion |
| 5799 | PROCEDURE Actualiza_Preca_Dirigida |
| 6201 | PROCEDURE Actualiza_Preca_Campana_Especiale |
| 6601 | PROCEDURE Actualiza_XCORE_CUSTOM |
| 6951 | PROCEDURE ACTUALIZA_XCORE_DIRIGIDA |
| 7091 | PROCEDURE ACTUALIZA_XCORE_CAMPANA_ESPECIAL |
| 7233 | PROCEDURE PVALIDA_XCORE |
| 7487 | PROCEDURE PVALIDA_WORLD_COMPLIANCE |
| 7811 | PROCEDURE OBT_WORLD_COMPLIANCE |

### Secuencias y parámetros
| Línea | Subprograma |
|---|---|
| 7951 | FUNCTION F_Genera_Secuencia |
| 8009 | FUNCTION F_Genera_Secuencia_Carga_Dirigida |
| 8063 | FUNCTION F_Genera_Secuencia_Campana_Especiales |
| 8115 | FUNCTION F_Obt_Parametro_Represtamo |
| 8177 | FUNCTION F_Obt_Valor_Parametros |
| 8267 | FUNCTION F_Obt_Parametro_Represtamo_Raw |

### Datos de cliente, teléfono, estado, edad, canal
| Línea | Subprograma |
|---|---|
| 8331 | FUNCTION F_Obt_Descripcion_Estado |
| 8395 | FUNCTION F_Obt_Telefono |
| 8493 | FUNCTION F_Validar_Telefono |
| 8523 | FUNCTION F_Obt_Des_Precalificacion |
| 8611 | FUNCTION F_Obt_Empresa_Represtamo |
| 8621 | FUNCTION F_Validar_Edad |
| 8737 | FUNCTION f_Validar_Canal |

### Montos y opciones de front
| Línea | Subprograma |
|---|---|
| 8769 | PROCEDURE P_Montos_Represtamos |
| 9113 | PROCEDURE P_Montos_Represtamos_Cancelado |
| 9457 | PROCEDURE P_Cargar_Opcion_Represtamo |
| 9755 | PROCEDURE P_Actualizar_Opcion_Front |
| 10213 | FUNCTION F_ES_REPRESTAMO_DIGITAL |
| 10235 | PROCEDURE P_Calcular_Opcion_Front |
| 10611 | PROCEDURE P_Carga_Opcion_Front |
| 10743 | PROCEDURE P_Validar_Idreprestamos |

### PIN, datos primarios/secundarios, bitácora de estados
| Línea | Subprograma |
|---|---|
| 10969 | FUNCTION F_Validar_Pin |
| 11069 | PROCEDURE P_Datos_Primarios |
| 11225 | PROCEDURE P_Datos_Secundarios |
| 11317 | PROCEDURE P_Obtener_Nombres_Cliente |
| 11381 | FUNCTION P_Solicitar_Pin |
| 11701 | PROCEDURE P_Validar_Cambio_Estado |
| 11945 | PROCEDURE P_Generar_Bitacora |
| 12089 | PROCEDURE P_Actualizar_Intentos |
| 12237 | FUNCTION P_Total_Estado_Bitacora |
| 12297 | FUNCTION P_Total_Estado_Bitacora_ID |
| 12359 | FUNCTION P_Total_Estado |
| 12425 | FUNCTION f_Step_Actual |
| 12469 | FUNCTION P_Obt_Estado_Represtamo |

### Bloqueo / desbloqueo / notificaciones
| Línea | Subprograma |
|---|---|
| 12547 | PROCEDURE P_Notificar_Ayuda |
| 12653 | PROCEDURE P_Bloquear_Represtamo |
| 12729 | PROCEDURE P_Desbloquear_Represtamo |
| 13005 | PROCEDURE P_Desbloqueo_FrontEnd |
| 13097 | PROCEDURE P_Desactivar_Activar_FrontEnd |
| 13221 | PROCEDURE P_Notificar_Desbloqueo |
| 13403 | PROCEDURE P_Notificar_Encuesta |
| 13567 | PROCEDURE P_Notificar_Desembolso |
| 13733 | PROCEDURE P_Notificar_Reenvio_Link |
| 13827 | FUNCTION F_Obt_Subject_Email |
| 13911 | FUNCTION F_Obt_Body_Mensaje |

### Registro y actualización de solicitud
| Línea | Subprograma |
|---|---|
| 14027 | PROCEDURE P_Registrar_Solicitud |
| 14345 | PROCEDURE P_Registra_Solicitud_Dirigida |
| 14665 | PROCEDURE P_Registra_Solicitud_Campana |
| 14973 | PROCEDURE P_Actualizar_Datos_Solicitud |
| 15113 | PROCEDURE P_Actualizar_Canal_Represtamo |
| 15359 | PROCEDURE P_Actualizar_Email_Represtamo |
| 15467 | PROCEDURE P_Actualizar_Anular_Represtamo |

### Carga de precalifica (jobs de carga)
| Línea | Subprograma |
|---|---|
| 15681 | PROCEDURE P_Carga_Precalifica_Represtamo |
| 15867 | PROCEDURE P_REGISTRO_SOLICITUD |
| 16035 | PROCEDURE P_Carga_Precalifica_Cancelado |
| 16411 | PROCEDURE P_Carga_Precalifica_Manual |
| 16635 | PROCEDURE P_Carga_Precalifica_Campana_Especial |
| 16873 | PROCEDURE P_Registrar_Rechazo |

### Correo / SMS / reenvíos
| Línea | Subprograma |
|---|---|
| 17033 | PROCEDURE Enviar_Correo_API |
| 17171 | PROCEDURE Enviar_Correo_API_ENCUESTA |
| 17317 | PROCEDURE Enviar_Sms_Api |
| 17485 | PROCEDURE Enviar_SMS_API_DESBLOQUEO |
| 17653 | PROCEDURE Enviar_Sms_Api_ENCUESTA |
| 17811 | PROCEDURE Reenviar_Sms_Api |
| 17985 | PROCEDURE Reenviar_Correo_API |
| 18135 | FUNCTION F_Reenviar_Represtamo |
| 18523 | PROCEDURE P_Anular_Represtamos_Inactivos |
| 18677 | PROCEDURE P_Notificar_Estado |

### Validaciones (F_*)
| Línea | Subprograma |
|---|---|
| 18851 | FUNCTION F_Validar_Existe_IdDeclinar |
| 18871 | FUNCTION F_Validar_Tipo_Represtamo |
| 18897 | FUNCTION F_Validar_Tipo_Represtamo_Carga |
| 18921 | FUNCTION F_Validar_Existe_Estado |
| 18939 | FUNCTION F_Validar_Listas_PEP |
| 18961 | FUNCTION F_Validar_Lista_NEGRA |
| 18981 | FUNCTION F_Existe_Represtamo |
| 19009 | FUNCTION F_Existe_Solicitudes |
| 19037 | FUNCTION F_Existe_Credito |
| 19067 | FUNCTION F_Existe_Canales |
| 19097 | FUNCTION F_Existe_Opciones |
| 19127 | FUNCTION F_Obtener_Total_SMS_Enviados |
| 19211 | FUNCTION F_Obtener_Nuevo_Credito |
| 19375 | FUNCTION F_Obtener_Credito_Cancelado |
| 19613 | FUNCTION F_Obtener_plazo |
| 19839 | FUNCTION F_Existe_Plazo |
| 19869 | FUNCTION F_TIENE_GARANTIA |
| 19913 | FUNCTION F_TIENE_GARANTIA_HISTORICO |
| 19957 | FUNCTION F_Obtiene_Desc_Bitacora |
| 19999 | FUNCTION F_HORARIO_VALIDO_NOTIFICACION |

### Procesamiento de crédito / FUD / documentos
| Línea | Subprograma |
|---|---|
| 20095 | PROCEDURE P_Actualiza_Credito_Solicitud |
| 20187 | PROCEDURE P_Actualiza_Fud |
| 20657 | PROCEDURE P_Procesa_Credito |
| 21581 | PROCEDURE P_Procesa_Credito_Cancelado |
| 23017 | PROCEDURE P_GENERA_DOCUMENTOS |
| 23257 | PROCEDURE p_Procesa_Fec |

### Jobs de creación de crédito / carga DE08-DE05
| Línea | Subprograma |
|---|---|
| 24123 | PROCEDURE setError |
| 24179 | PROCEDURE P_JOB_CREA_CREDITO_S |
| 24219 | PROCEDURE P_JOB_CREA_CREDITO |
| 24281 | PROCEDURE P_JOB_CREA_ACTUALIZA_CORE |
| 24431 | PROCEDURE P_CARGA_DE08 |
| 24467 | PROCEDURE P_CARGA_DE05 |
| 24499 | PROCEDURE P_Generar_reporte_deponente |

### Campañas / FUD / FEC / parámetros
| Línea | Subprograma |
|---|---|
| 24769 | PROCEDURE P_Insertar_Campana |
| 24869 | PROCEDURE P_Actualizar_Campana |
| 25057 | PROCEDURE P_Inactivar_Campana |
| 25101 | PROCEDURE P_CARGAR_DATOS_FUD_ANTERIOR |
| 25951 | PROCEDURE P_CARGAR_DATOS_FUD_NUEVO |
| 26801 | PROCEDURE P_CARGAR_DATOS_FEC_NUEVO |
| 27005 | PROCEDURE P_ACTUALIZA_COMENTARIO_CAMPANA |
| 27031 | PROCEDURE P_Registrar_Ejecucion_Param |
| 27149 | PROCEDURE P_ACTUALIZAR_CAMPO_APPADEMI (fin del body) |
