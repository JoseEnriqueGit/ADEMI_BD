-- Script alternativo para ediciones que no soportan particionamiento (XE/SE).
-- Crea la tabla IA_API_LOGS sin PARTITION BY ni cláusulas de almacenamiento avanzadas.

CREATE TABLE "IA"."IA_API_LOGS"
(
    "ID_LOG"               NUMBER GENERATED ALWAYS AS IDENTITY,
    "FECHA_HORA"           TIMESTAMP(6) DEFAULT SYSTIMESTAMP NOT NULL,
    "ENDPOINT"             VARCHAR2(200 BYTE) NOT NULL,
    "METODO"               VARCHAR2(10 BYTE) NOT NULL,
    "USUARIO"              VARCHAR2(100 BYTE),
    "IP_ORIGEN"            VARCHAR2(50 BYTE),
    "SERVICE_NAME"         VARCHAR2(200 BYTE),
    "LOG_LEVEL"            VARCHAR2(10 BYTE) DEFAULT 'INFO' NOT NULL,
    "IS_SENSITIVE"         CHAR(1 BYTE) DEFAULT 'N' NOT NULL,
    "PARAMETROS"           CLOB,
    "REQUEST_BODY_SUMMARY" VARCHAR2(1000 BYTE),
    "STATUS_CODE"          NUMBER,
    "STATUS_CATEGORY"      VARCHAR2(20 BYTE) DEFAULT 'UNKNOWN',
    "TIEMPO_MS"            NUMBER,
    "ERROR_MSG"            VARCHAR2(4000 BYTE),
    "RESPONSE_MSG"         CLOB,
    "RESPONSE_SUMMARY"     VARCHAR2(1000 BYTE),
    CONSTRAINT "PK_IA_API_LOGS" PRIMARY KEY ("ID_LOG")
        USING INDEX TABLESPACE "IA_IDX" ENABLE,
    CONSTRAINT "CHK_IA_API_LOGS_LEVEL" CHECK (LOG_LEVEL IN ('DEBUG','INFO','WARN','ERROR','FATAL')) ENABLE,
    CONSTRAINT "CHK_IA_API_LOGS_SENS" CHECK (IS_SENSITIVE IN ('Y','N')) ENABLE
)
SEGMENT CREATION IMMEDIATE
TABLESPACE "IA_DAT"
LOB ("PARAMETROS") STORE AS BASICFILE (TABLESPACE "IA_DAT")
LOB ("RESPONSE_MSG") STORE AS BASICFILE (TABLESPACE "IA_DAT");

-- Índices de apoyo
CREATE INDEX "IA"."IDX_API_LOGS_FECHA" ON "IA"."IA_API_LOGS" ("FECHA_HORA") TABLESPACE "IA_IDX";
CREATE INDEX "IA"."IDX_API_LOGS_ENDPOINT" ON "IA"."IA_API_LOGS" ("ENDPOINT", "METODO", "STATUS_CODE") TABLESPACE "IA_IDX";

-- Comentarios descriptivos (opcionales)
COMMENT ON TABLE  "IA"."IA_API_LOGS" IS 'Bitácora centralizada de invocaciones a API''s expuestas mediante ORDS con metadatos de seguridad y métricas.';
COMMENT ON COLUMN "IA"."IA_API_LOGS"."ID_LOG" IS 'Identificador único del registro de log.';
COMMENT ON COLUMN "IA"."IA_API_LOGS"."FECHA_HORA" IS 'Fecha y hora exacta de la invocación.';
COMMENT ON COLUMN "IA"."IA_API_LOGS"."ENDPOINT" IS 'Nombre del endpoint ORDS o ruta del servicio.';
COMMENT ON COLUMN "IA"."IA_API_LOGS"."METODO" IS 'Método HTTP invocado (GET, POST, etc.).';
COMMENT ON COLUMN "IA"."IA_API_LOGS"."USUARIO" IS 'Usuario autenticado o sistema consumidor de la API.';
COMMENT ON COLUMN "IA"."IA_API_LOGS"."IP_ORIGEN" IS 'Dirección IP de origen reportada por ORDS.';
COMMENT ON COLUMN "IA"."IA_API_LOGS"."SERVICE_NAME" IS 'Nombre del procedimiento ORDS / paquete que atiende la solicitud.';
COMMENT ON COLUMN "IA"."IA_API_LOGS"."LOG_LEVEL" IS 'Nivel de severidad asociado al evento (DEBUG, INFO, WARN, ERROR, FATAL).';
COMMENT ON COLUMN "IA"."IA_API_LOGS"."IS_SENSITIVE" IS 'Marca si la solicitud contiene datos sensibles que deben ofuscarse.';
COMMENT ON COLUMN "IA"."IA_API_LOGS"."PARAMETROS" IS 'Payload de la invocación después de aplicar sanitización.';
COMMENT ON COLUMN "IA"."IA_API_LOGS"."REQUEST_BODY_SUMMARY" IS 'Primeros caracteres del payload para facilitar búsquedas rápidas.';
COMMENT ON COLUMN "IA"."IA_API_LOGS"."STATUS_CODE" IS 'Código de estado HTTP o interno devuelto al consumidor.';
COMMENT ON COLUMN "IA"."IA_API_LOGS"."STATUS_CATEGORY" IS 'Categoría semántica del código HTTP (SUCCESS, CLIENT_ERROR, etc.).';
COMMENT ON COLUMN "IA"."IA_API_LOGS"."TIEMPO_MS" IS 'Tiempo total de ejecución medido en milisegundos.';
COMMENT ON COLUMN "IA"."IA_API_LOGS"."ERROR_MSG" IS 'Mensaje resumido asociado a la ejecución (éxito o error).';
COMMENT ON COLUMN "IA"."IA_API_LOGS"."RESPONSE_MSG" IS 'Payload de respuesta después de sanitización.';
COMMENT ON COLUMN "IA"."IA_API_LOGS"."RESPONSE_SUMMARY" IS 'Primeros caracteres de la respuesta para búsqueda textual.';