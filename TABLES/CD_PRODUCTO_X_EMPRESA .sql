/* ==========================================================
   CREACIÓN DE TABLA: CD_PRODUCTO_X_EMPRESA
   ========================================================== */

-- Si la tabla existe y quieres recrearla, primero elimínala.
-- DROP TABLE CD_PRODUCTO_X_EMPRESA CASCADE CONSTRAINTS;

CREATE TABLE CD_PRODUCTO_X_EMPRESA (
    /* Clave primaria compuesta */
    COD_EMPRESA               VARCHAR2(5)    NOT NULL,
    COD_PRODUCTO              VARCHAR2(4)    NOT NULL,

    /* Reglas y parámetros del producto */
    MONTO_MINIMO              NUMBER(17,2)   NOT NULL,
    A_LA_VISTA                VARCHAR2(1)    NOT NULL,
    FORMA_CALCULO_INTERES     VARCHAR2(3),
    FREC_REVISION             VARCHAR2(1),
    PLAZO_REVISION            NUMBER(5),
    FREC_INTERES              VARCHAR2(1),
    PLAZO_INTERES             NUMBER(5),
    FREC_CAPITALIZA           VARCHAR2(1),
    PLAZO_CAPITALIZA          NUMBER(5),
    PAGA_RENTA                VARCHAR2(1),
    PORCENTAJE_RENTA          NUMBER(8,4),
    BASE_CALCULO              NUMBER(3)      NOT NULL,
    BASE_PLAZO                NUMBER(3)      NOT NULL,
    PLAZO_MINIMO              NUMBER(5)      NOT NULL,

    /* Auditoría */
    ADICIONADO_POR            VARCHAR2(10)   NOT NULL,
    FECHA_ADICION             DATE           NOT NULL,
    MODIFICADO_POR            VARCHAR2(10)   NOT NULL,
    FECHA_MODIFICACION        DATE,

    /* Parámetros adicionales */
    NUM_DIAS                  NUMBER(4),
    TIENE_DOC_FISICO          VARCHAR2(1),
    MODIFICA_PLA_CAP          VARCHAR2(1),
    DIA_EX_CAP_FRE_MES        NUMBER(2),
    DIA_PAGO_INT              NUMBER(2),
    COD_CARTERA               VARCHAR2(10),
    DIAS_EFECTIVO             NUMBER(3),
    DIAS_CHEQUE               NUMBER(3),
    MON_COM_EMSION_CHK        NUMBER(17,2),
    CODIGO_TIPO_INSTRUMENTO   VARCHAR2(3),
    IND_CALCULA_PENALIDAD     VARCHAR2(1),
    IND_PENALIDAD_RENOV       VARCHAR2(1),
    IND_REDENCION_ANT         VARCHAR2(1)    DEFAULT 'S',
    IND_BONOS                 VARCHAR2(1)    DEFAULT 'N',
    IND_RENOVACION_AUTO       VARCHAR2(1)    DEFAULT 'N',
    IND_PRD_EMP               VARCHAR2(1),

    /* Clave primaria */
    CONSTRAINT PK_CD_PRODUCTO_X_EMPRESA
        PRIMARY KEY (COD_EMPRESA, COD_PRODUCTO)
);

/* ==========================================================
   ÍNDICES ADICIONALES (si los necesitas, añádelos aquí)
   Ejemplo:
   -- CREATE INDEX IDX_CD_PROD_EMP_CARTERA
   --     ON CD_PRODUCTO_X_EMPRESA (COD_CARTERA);
   ========================================================== */
