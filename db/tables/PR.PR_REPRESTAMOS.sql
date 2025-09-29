CREATE TABLE PR.PR_REPRESTAMOS (
    CODIGO_EMPRESA              NUMBER(4) NOT NULL,
    ID_REPRESTAMO               NUMBER(14) NOT NULL,
    CODIGO_CLIENTE              NUMBER(7),
    FECHA_CORTE                 DATE,
    NO_CREDITO                  NUMBER(7),
    ESTADO                      VARCHAR2(3 BYTE),
    CODIGO_PRECALIFICACION      VARCHAR2(2 BYTE),
    DIAS_ATRASO                 NUMBER(10),
    FECHA_PROCESO               DATE,
    PIN                         NUMBER(6),
    INTENTOS_PIN                NUMBER(1),
    INTENTOS_IDENTIFICACION     NUMBER(1),
    IND_SOLICITA_AYUDA          VARCHAR2(1 BYTE) DEFAULT 'N',
    MTO_CREDITO_ACTUAL          NUMBER(18,2),
    MTO_PREAPROBADO             NUMBER(18,2),
    OBSERVACIONES               VARCHAR2(4000 BYTE),
    ADICIONADO_POR              VARCHAR2(30 BYTE) NOT NULL,
    FECHA_ADICION               DATE DEFAULT SYSDATE NOT NULL,
    MODIFICADO_POR              VARCHAR2(30 BYTE),
    FECHA_MODIFICACION          DATE,
    ESTADO_ORIGINAL             VARCHAR2(3 BYTE),
    XCORE_GLOBAL                NUMBER(7,2),
    XCORE_CUSTOM                NUMBER(7,2),
    ID_CARGA_DIRIGIDA           NUMBER,
    ID_REPRE_CAMPANA_ESPECIALES NUMBER,
    ES_FIADOR                   VARCHAR2(30 BYTE) DEFAULT 'N', -- Nota: El tipo es VARCHAR2(30) según la imagen
    -- Constraint de Llave Primaria
    CONSTRAINT PK_REPRESTAMOS PRIMARY KEY (CODIGO_EMPRESA, ID_REPRESTAMO)
);

-- Comentarios Opcionales para Claridad
COMMENT ON TABLE PR.PR_REPRESTAMOS IS 'Tabla principal que almacena los registros de représtamos precalificados y su estado en el proceso.';
COMMENT ON COLUMN PR.PR_REPRESTAMOS.CODIGO_EMPRESA IS 'Código de la empresa.';
COMMENT ON COLUMN PR.PR_REPRESTAMOS.ID_REPRESTAMO IS 'Identificador único del registro de représtamo.';
COMMENT ON COLUMN PR.PR_REPRESTAMOS.CODIGO_CLIENTE IS 'Código del cliente asociado al représtamo.';
COMMENT ON COLUMN PR.PR_REPRESTAMOS.FECHA_CORTE IS 'Fecha de corte de los datos utilizados para la precalificación.';
COMMENT ON COLUMN PR.PR_REPRESTAMOS.NO_CREDITO IS 'Número del crédito original sobre el cual se basa el représtamo.';
COMMENT ON COLUMN PR.PR_REPRESTAMOS.ESTADO IS 'Estado actual del registro de représtamo en el flujo de proceso (RE, SC, BLP, AN, etc.).';
COMMENT ON COLUMN PR.PR_REPRESTAMOS.CODIGO_PRECALIFICACION IS 'Código que indica el nivel o tipo de precalificación obtenido basado en reglas.';
COMMENT ON COLUMN PR.PR_REPRESTAMOS.DIAS_ATRASO IS 'Máximo días de atraso registrados en el período evaluado para el crédito original.';
COMMENT ON COLUMN PR.PR_REPRESTAMOS.FECHA_PROCESO IS 'Fecha en que se procesó o actualizó significativamente el registro.';
COMMENT ON COLUMN PR.PR_REPRESTAMOS.PIN IS 'PIN generado para la validación del cliente (si el flujo lo requiere).';
COMMENT ON COLUMN PR.PR_REPRESTAMOS.INTENTOS_PIN IS 'Número de intentos restantes para validar el PIN.';
COMMENT ON COLUMN PR.PR_REPRESTAMOS.INTENTOS_IDENTIFICACION IS 'Número de intentos restantes para validar la identificación.';
COMMENT ON COLUMN PR.PR_REPRESTAMOS.IND_SOLICITA_AYUDA IS 'Indicador (S/N) de si el cliente solicitó ayuda durante el proceso.';
COMMENT ON COLUMN PR.PR_REPRESTAMOS.MTO_CREDITO_ACTUAL IS 'Monto desembolsado del crédito original.';
COMMENT ON COLUMN PR.PR_REPRESTAMOS.MTO_PREAPROBADO IS 'Monto calculado y preaprobado para ofrecer en el représtamo.';
COMMENT ON COLUMN PR.PR_REPRESTAMOS.OBSERVACIONES IS 'Observaciones o comentarios sobre el estado, validaciones o rechazos.';
COMMENT ON COLUMN PR.PR_REPRESTAMOS.ESTADO_ORIGINAL IS 'Estado que tenía el registro antes de un cambio (ej. antes de ser bloqueado).';
COMMENT ON COLUMN PR.PR_REPRESTAMOS.XCORE_GLOBAL IS 'Puntaje Xcore Global obtenido de DataCrédito (si aplica).';
COMMENT ON COLUMN PR.PR_REPRESTAMOS.XCORE_CUSTOM IS 'Puntaje Xcore Custom obtenido de DataCrédito (si aplica).';
COMMENT ON COLUMN PR.PR_REPRESTAMOS.ID_CARGA_DIRIGIDA IS 'Identificador si el représtamo proviene de una carga dirigida específica.';
COMMENT ON COLUMN PR.PR_REPRESTAMOS.ID_REPRE_CAMPANA_ESPECIALES IS 'Identificador si el représtamo proviene de una campaña especial.';
COMMENT ON COLUMN PR.PR_REPRESTAMOS.ES_FIADOR IS 'Indicador (S/N) de si el cliente original tenía fiador.';
COMMENT ON COLUMN PR.PR_REPRESTAMOS.ADICIONADO_POR IS 'Usuario que creó el registro.';
COMMENT ON COLUMN PR.PR_REPRESTAMOS.FECHA_ADICION IS 'Fecha de creación del registro.';
COMMENT ON COLUMN PR.PR_REPRESTAMOS.MODIFICADO_POR IS 'Usuario que modificó el registro por última vez.';
COMMENT ON COLUMN PR.PR_REPRESTAMOS.FEC_MODIFICACION IS 'Fecha de última modificación del registro.';


-- Índices opcionales (ejemplos)
-- CREATE INDEX IDX_REPRESTAMOS_CLIENTE ON PR.PR_REPRESTAMOS (CODIGO_CLIENTE);
-- CREATE INDEX IDX_REPRESTAMOS_ESTADO ON PR.PR_REPRESTAMOS (ESTADO);
-- CREATE INDEX IDX_REPRESTAMOS_NOCREDITO ON PR.PR_REPRESTAMOS (NO_CREDITO);
-- CREATE INDEX IDX_REPRESTAMOS_FECHA_PROCESO ON PR.PR_REPRESTAMOS (FECHA_PROCESO);