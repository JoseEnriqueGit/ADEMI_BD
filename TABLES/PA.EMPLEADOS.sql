CREATE TABLE PA.EMPLEADOS (
    COD_EMPRESA              VARCHAR2(10 BYTE) NOT NULL,
    ID_EMPLEADO              VARCHAR2(10 BYTE) NOT NULL,
    COD_PER_FISICA           VARCHAR2(15 BYTE),
    COD_PUESTO               VARCHAR2(5 BYTE),
    COD_AGENCIA              VARCHAR2(5 BYTE), -- Columna de agencia (posiblemente principal)
    COD_AGENCIA_LABORA       VARCHAR2(5 BYTE), -- Columna de agencia donde labora (según imagen)
    ESTA_ACTIVO              VARCHAR2(1 BYTE) DEFAULT 'Y' NOT NULL, -- Asumiendo 'Y' como activo por defecto y que no puede ser nulo
    FEC_INGRESO              DATE,
    EXTENSION                NUMBER(5),
    ATIENDE_QUEJAS           VARCHAR2(1 BYTE) DEFAULT 'Y',
    ATIENDE_PUBLICO          VARCHAR2(1 BYTE) DEFAULT 'Y',
    CROSSELLING              NUMBER(8,4),
    RENTABILIDAD             NUMBER(8,4),
    ES_OFICIAL               VARCHAR2(1 BYTE) DEFAULT 'Y',
    ES_PROMOTOR              VARCHAR2(1 BYTE) DEFAULT 'N',
    ES_EXTERNO               VARCHAR2(1 BYTE) DEFAULT 'N',
    COD_CANAL                VARCHAR2(10 BYTE),
    EMAIL1                   VARCHAR2(50 BYTE),
    EMAIL2                   VARCHAR2(50 BYTE),
    USUARIO                  VARCHAR2(10 BYTE), -- Columna inferida/asumida para el usuario de BD
    SUPERVISOR               VARCHAR2(10 BYTE),
    FIRMA_AUTORIZADA         VARCHAR2(10 BYTE),
    TIPO_FIRMA               VARCHAR2(1 BYTE),
    IMP_CORTE_CTA            VARCHAR2(1 BYTE),
    COD_MOTIVO               VARCHAR2(5 BYTE),
    ES_OFICIAL_CTA           VARCHAR2(1 Byte),
    IND_AUTOSGESP            VARCHAR2(1 Byte),
    NIVEL_APROBACION         NUMBER(1),
    VER_TODOS_REFERIDOS      VARCHAR2(1 Byte) DEFAULT 'Y',
    ID_JEFE                  VARCHAR2(10 Byte),
    CATEG_EMPLEADOS          VARCHAR2(10 Byte) DEFAULT '8',
    AREA_TRABAJA             VARCHAR2(10 Byte),
    RESPONSAB_EMPLE          VARCHAR2(10 Byte) DEFAULT '00',
    IND_NO_CAMBIO_MASIVO     VARCHAR2(1 Byte) DEFAULT 'N',
    INCLUIDO_POR             VARCHAR2(10 Byte) NOT NULL, -- Auditoría: Quién creó
    FEC_INCLUSION            DATE DEFAULT SYSDATE NOT NULL, -- Auditoría: Cuándo se creó
    MODIFICADO_POR           VARCHAR2(10 Byte), -- Auditoría: Quién modificó
    FEC_MODIFICACION         DATE, -- Auditoría: Cuándo se modificó
    TIPO_EMPLEADO            VARCHAR2(20 BYTE),
    FECHA_FIN_CONTRATO       DATE,
    -- Definición de la Llave Primaria Compuesta
    CONSTRAINT PK_EMPLEADOS PRIMARY KEY (COD_EMPRESA, ID_EMPLEADO)
);

-- Comentarios Opcionales para Claridad
COMMENT ON TABLE PA.EMPLEADOS IS 'Tabla que almacena la información de los empleados.';
COMMENT ON COLUMN PA.EMPLEADOS.COD_EMPRESA IS 'Código de la empresa a la que pertenece el empleado.';
COMMENT ON COLUMN PA.EMPLEADOS.ID_EMPLEADO IS 'Identificador único del empleado dentro de la empresa.';
COMMENT ON COLUMN PA.EMPLEADOS.COD_PER_FISICA IS 'Código de persona física asociado al empleado (Enlace a tabla PERSONAS_FISICAS).';
COMMENT ON COLUMN PA.EMPLEADOS.COD_AGENCIA IS 'Código de la agencia principal o de registro del empleado.';
COMMENT ON COLUMN PA.EMPLEADOS.COD_AGENCIA_LABORA IS 'Código de la agencia donde labora físicamente el empleado.';
COMMENT ON COLUMN PA.EMPLEADOS.ESTA_ACTIVO IS 'Indicador de si el empleado está activo (Y/S/1 = Sí, N/0 = No).';
COMMENT ON COLUMN PA.EMPLEADOS.USUARIO IS 'Nombre de usuario de base de datos del empleado (puede usarse para auditoría y joins).';
COMMENT ON COLUMN PA.EMPLEADOS.TIPO_EMPLEADO IS 'Clasificación o tipo de empleado.';
COMMENT ON COLUMN PA.EMPLEADOS.FECHA_FIN_CONTRATO IS 'Fecha de finalización del contrato del empleado (si aplica).';
COMMENT ON COLUMN PA.EMPLEADOS.INCLUIDO_POR IS 'Usuario que creó el registro.';
COMMENT ON COLUMN PA.EMPLEADOS.FEC_INCLUSION IS 'Fecha de creación del registro.';
COMMENT ON COLUMN PA.EMPLEADOS.MODIFICADO_POR IS 'Usuario que modificó el registro por última vez.';
COMMENT ON COLUMN PA.EMPLEADOS.FEC_MODIFICACION IS 'Fecha de última modificación del registro.';

-- Posibles Índices Adicionales (Opcional, basado en uso frecuente)
-- CREATE INDEX IDX_EMPLEADOS_AGENCIA_LABORA ON PA.EMPLEADOS (COD_AGENCIA_LABORA);
-- CREATE INDEX IDX_EMPLEADOS_EMAIL1 ON PA.EMPLEADOS (EMAIL1);
-- CREATE INDEX IDX_EMPLEADOS_USUARIO ON PA.EMPLEADOS (USUARIO); -- Si la columna USUARIO existe y se usa en joins