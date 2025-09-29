CREATE TABLE PA_PARAMETROS_MVP (
    CODIGO_EMPRESA        NUMBER(4) NOT NULL,
    CODIGO_MVP            VARCHAR2(30 Byte) NOT NULL,
    CODIGO_PARAMETRO      VARCHAR2(50 Byte) NOT NULL,
    DES_PARAMETRO         VARCHAR2(500 Byte) NOT NULL,
    VALOR                 VARCHAR2(4000 Byte),
    ADICIONADO_POR        VARCHAR2(30 Byte) NOT NULL,
    FECHA_ADICION         DATE NOT NULL,
    MODIFICADO_POR        VARCHAR2(30 Byte),
    FECHA_MODIFICACION    DATE,
    VALOR_RAW             RAW(2000)
);

-- Opcional: Añadir comentarios a la tabla y columnas si se desea mayor claridad
-- COMMENT ON TABLE PA_PARAMETROS_MVP IS 'Tabla que almacena parámetros de configuración específicos de MVP.';
-- COMMENT ON COLUMN PA_PARAMETROS_MVP.CODIGO_EMPRESA IS 'Código de la empresa.';
-- COMMENT ON COLUMN PA_PARAMETROS_MVP.CODIGO_MVP IS 'Identificador del módulo o contexto MVP al que pertenece el parámetro.';
-- COMMENT ON COLUMN PA_PARAMETROS_MVP.CODIGO_PARAMETRO IS 'Código único del parámetro dentro del contexto MVP.';
-- COMMENT ON COLUMN PA_PARAMETROS_MVP.DES_PARAMETRO IS 'Descripción del propósito del parámetro.';
-- COMMENT ON COLUMN PA_PARAMETROS_MVP.VALOR IS 'Valor del parámetro como texto (hasta 4000 bytes).';
-- COMMENT ON COLUMN PA_PARAMETROS_MVP.ADICIONADO_POR IS 'Usuario que creó el registro del parámetro.';
-- COMMENT ON COLUMN PA_PARAMETROS_MVP.FECHA_ADICION IS 'Fecha de creación del registro del parámetro.';
-- COMMENT ON COLUMN PA_PARAMETROS_MVP.MODIFICADO_POR IS 'Usuario que realizó la última modificación.';
-- COMMENT ON COLUMN PA_PARAMETROS_MVP.FECHA_MODIFICACION IS 'Fecha de la última modificación.';
-- COMMENT ON COLUMN PA_PARAMETROS_MVP.VALOR_RAW IS 'Valor del parámetro en formato RAW (hasta 2000 bytes), para datos binarios o no textuales.';