CREATE TABLE PR_TIPO_CREDITO_REPRESTAMO (
    CODIGO_EMPRESA             NUMBER(4) NOT NULL,
    TIPO_CREDITO               NUMBER(3) NOT NULL,
    ESTADO                     VARCHAR2(1 Byte) NOT NULL,
    ADICIONADO_POR             VARCHAR2(30 Byte) DEFAULT USER NOT NULL,
    FECHA_ADICION              DATE DEFAULT SYSDATE NOT NULL,
    MODIFICADO_POR             VARCHAR2(30 Byte),
    FECHA_MODIFICACION         DATE,
    OBSOLETO                   NUMBER DEFAULT 0,
    CARGA                      CHAR(1 Byte) DEFAULT 'S',
    CREDITO_CAMPANA_ESPECIAL   CHAR(1 Byte) DEFAULT NULL,
    CREDITO_FMO                CHAR(1 Byte),
    CONSTRAINT PK_TIPO_CREDITO_REPRESTAMO PRIMARY KEY (CODIGO_EMPRESA, TIPO_CREDITO)
);

-- Opcional: Añadir comentarios a la tabla y columnas si se desea mayor claridad
-- COMMENT ON TABLE PR_TIPO_CREDITO_REPRESTAMO IS 'Tabla que define los tipos de crédito aplicables a représtamos y sus características.';
-- COMMENT ON COLUMN PR_TIPO_CREDITO_REPRESTAMO.CODIGO_EMPRESA IS 'Código de la empresa.';
-- COMMENT ON COLUMN PR_TIPO_CREDITO_REPRESTAMO.TIPO_CREDITO IS 'Código del tipo de crédito.';
-- COMMENT ON COLUMN PR_TIPO_CREDITO_REPRESTAMO.ESTADO IS 'Estado del tipo de crédito;
-- COMMENT ON COLUMN PR_TIPO_CREDITO_REPRESTAMO.ADICIONADO_POR IS 'Usuario que creó el registro.';
-- COMMENT ON COLUMN PR_TIPO_CREDITO_REPRESTAMO.FECHA_ADICION IS 'Fecha de creación del registro.';
-- COMMENT ON COLUMN PR_TIPO_CREDITO_REPRESTAMO.MODIFICADO_POR IS 'Usuario que realizó la última modificación.';
-- COMMENT ON COLUMN PR_TIPO_CREDITO_REPRESTAMO.FECHA_MODIFICACION IS 'Fecha de la última modificación.';
-- COMMENT ON COLUMN PR_TIPO_CREDITO_REPRESTAMO.OBSOLETO IS 'Indicador de si el tipo de crédito es obsoleto (0=No, 1=Sí).';
-- COMMENT ON COLUMN PR_TIPO_CREDITO_REPRESTAMO.CARGA IS 'Indicador relacionado a procesos de carga (S/N).';
-- COMMENT ON COLUMN PR_TIPO_CREDITO_REPRESTAMO.CREDITO_CAMPANA_ESPECIAL IS 'Indicador de si aplica a campañas especiales (S/N).';
-- COMMENT ON COLUMN PR_TIPO_CREDITO_REPRESTAMO.CREDITO_FMO IS 'Indicador relacionado a FMO (S/N).';