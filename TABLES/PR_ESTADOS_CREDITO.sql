CREATE TABLE PR_ESTADOS_CREDITO (
    CODIGO_ESTADO          VARCHAR2(2 BYTE)   NOT NULL,  -- Clave primaria del estado
    ABREV_ESTADO           VARCHAR2(15 BYTE)  NOT NULL,  -- Abreviación para mostrar en listados
    DESCRIPCION_ESTADO     VARCHAR2(60 BYTE)  NOT NULL,  -- Descripción legible del estado
    ADICIONADO_POR         VARCHAR2(10 BYTE),            -- Usuario que creó el registro
    FECHA_ADICION          DATE,                         -- Fecha de creación
    MODIFICADO_POR         VARCHAR2(10 BYTE),            -- Usuario que realizó la última modificación
    FECHA_MODIFICACION     DATE,                         -- Fecha de modificación
    DIAS_TRASLADO_ESTADO   NUMBER,                       -- Cantidad de días límite para cambiar de estado
    CONSTRAINT PK_PR_ESTADOS_CREDITO PRIMARY KEY (CODIGO_ESTADO)
);

--Estos son los estado registrado en la tabla

| CODIGO_ESTADO | ABREV_ESTADO   | DESCRIPCION_ESTADO                     |
|---------------|----------------|---------------------------------------|
| E             | REESTRUCTURADO | CREDITO REESTRUCTURADO                |
| T             | CASTIGADO      | CREDITO CASTIGADO                     |
| R             | REGISTRADO     | CREDITO REGISTRADO                    |
| A             | APROBADO       | CREDITO APROBADO                      |
| D             | DESEMBOLSADO   | CREDITO DESEMBOLSADO                  |
| C             | CANCELADO      | CREDITO CANCELADO                     |
| J             | EN LEGAL       | CREDITO EN ESTADO LEGAL               |
| N             | ANULADO        | CREDITO ANULADO                       |
| X             | RECHAZADO      | CREDITO RECHAZADO                     |
| V             | VENCIDO        | CREDITO VENCIDO                       |
| M             | MORA           | CREDITO EN MORA                       |
| S             | SOLICITADO     | CREDITO SOLICITADO                    |
| O             | ADJUDICADO     | CREDITO ADJUDICADO/DACION EN PAGO     |
