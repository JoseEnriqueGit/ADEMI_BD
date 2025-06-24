WITH LatestBitacora AS (
    SELECT B.ID_REPRESTAMO,
           B.CODIGO_ESTADO,
           ROW_NUMBER() OVER (PARTITION BY B.ID_REPRESTAMO
                              ORDER BY B.ID_BITACORA DESC, B.FECHA_ADICION DESC) AS rn
    FROM   PR.PR_BITACORA_REPRESTAMO B
),
HasCryStatus AS (
    SELECT DISTINCT ID_REPRESTAMO
    FROM   PR.PR_BITACORA_REPRESTAMO
    WHERE  CODIGO_ESTADO = 'CRY'
),
BaseData AS (
    SELECT  S.ID_REPRESTAMO,
            R.MTO_PREAPROBADO,
            R.FECHA_PROCESO,
            C.MONTO_DESEMBOLSADO,
            C.F_PRIMER_DESEMBOLSO                    AS FechaDesembolso,
            LB.CODIGO_ESTADO                        AS CodigoEstadoActual,
            CASE
                 WHEN LB.CODIGO_ESTADO = 'CRD' THEN
                      CASE WHEN HCS.ID_REPRESTAMO IS NOT NULL
                           THEN 'Digital (con firma)'
                           ELSE 'Sucursal (tradicional)'
                      END
            END                                     AS CanalDesembolsoDeterminado
    FROM       PA.EMPLEADOS               P
    JOIN       PA.AGENCIA                 A  ON TO_NUMBER(P.COD_EMPRESA)       = A.COD_EMPRESA
                                            AND TO_NUMBER(P.COD_AGENCIA_LABORA)= A.COD_AGENCIA
    JOIN       PR.PR_SOLICITUD_REPRESTAMO S  ON TO_NUMBER(P.COD_EMPRESA)       = S.CODIGO_EMPRESA
                                            AND TO_NUMBER(P.COD_AGENCIA_LABORA)= S.CODIGO_AGENCIA
    JOIN       PR.PR_REPRESTAMOS          R  ON R.ID_REPRESTAMO               = S.ID_REPRESTAMO
                                            AND R.CODIGO_EMPRESA              = S.CODIGO_EMPRESA
    JOIN       LatestBitacora             LB ON LB.ID_REPRESTAMO              = S.ID_REPRESTAMO
                                            AND LB.rn                         = 1
    LEFT JOIN  HasCryStatus               HCS ON HCS.ID_REPRESTAMO            = S.ID_REPRESTAMO
    LEFT JOIN  PR.PR_CREDITOS             C   ON C.NO_CREDITO                 = S.NO_CREDITO
                                            AND C.CODIGO_EMPRESA              = S.CODIGO_EMPRESA
    WHERE  SUBSTR(P.EMAIL1,1,INSTR(P.EMAIL1,'@')-1) = 'MAMATOS'  -- ¿ cambiar a V('APP_USER')
      AND  P.ID_EMPLEADO = A.GERENTE
      AND  P.ESTA_ACTIVO = 'S'
),
EfectividadMes AS (
    SELECT
        (SELECT COUNT(DISTINCT ID_REPRESTAMO)
         FROM   BaseData
         WHERE  CodigoEstadoActual = 'CRD'
           AND  FechaDesembolso   >= TRUNC(SYSDATE,'MM')
           AND  FechaDesembolso   <  ADD_MONTHS(TRUNC(SYSDATE,'MM'),1)
        ) AS DesembolsadosMes,
        (SELECT COUNT(DISTINCT ID_REPRESTAMO)
         FROM   BaseData
         WHERE  FECHA_PROCESO     >= TRUNC(SYSDATE,'MM')
           AND  FECHA_PROCESO     <  ADD_MONTHS(TRUNC(SYSDATE,'MM'),1)
        ) AS PreaprobadosMes
    FROM dual
)
SELECT *
FROM (
    SELECT 'Total Preaprobados'                   CARD_TITLE,
           TO_CHAR(COUNT(DISTINCT ID_REPRESTAMO)) CARD_TEXT,
           'Monto RD$ '||
           TO_CHAR(NVL(SUM(MTO_PREAPROBADO),0),
                   'FM9G999G999G990D00',
                   'NLS_NUMERIC_CHARACTERS=''.,''')        CARD_SUBTEXT,
           'fa-file-invoice-dollar'               CARD_ICON,
           'u-color-1'                            CARD_COLOR,
           1                                       order_col
    FROM   BaseData
    UNION ALL
    SELECT 'Total Desembolsos',
           TO_CHAR(COUNT(DISTINCT ID_REPRESTAMO)),
           'Monto RD$ '||
           TO_CHAR(NVL(SUM(MONTO_DESEMBOLSADO),0),
                   'FM9G999G999G990D00',
                   'NLS_NUMERIC_CHARACTERS=''.,'''),
           'fa-check-circle',
           'u-color-5',
           2
    FROM   BaseData
    WHERE  CodigoEstadoActual = 'CRD'
    UNION ALL
    SELECT 'Efectividad (Mes Actual)',
           CASE
               WHEN PreaprobadosMes = 0
               THEN '0.00%'
               ELSE TO_CHAR(TRUNC((DesembolsadosMes/PreaprobadosMes)*100,2),'FM990.00')||'%'
           END,
           'Des: '||DesembolsadosMes||' / Pre: '||PreaprobadosMes,
           'fa-percent',
           'u-color-10',
           3
    FROM   EfectividadMes
    UNION ALL
    SELECT 'Desembolsos Firma Electrónica',
           TO_CHAR(COUNT(DISTINCT ID_REPRESTAMO)),
           'Monto RD$ '||
           TO_CHAR(NVL(SUM(MONTO_DESEMBOLSADO),0),
                   'FM9G999G999G990D00',
                   'NLS_NUMERIC_CHARACTERS=''.,'''),
           'fa-mobile-alt',
           'u-color-15',
           4
    FROM   BaseData
    WHERE  CodigoEstadoActual = 'CRD'
      AND  CanalDesembolsoDeterminado = 'Digital (con firma)'
    UNION ALL
    SELECT 'Desembolsos Tradicionales',
           TO_CHAR(COUNT(DISTINCT ID_REPRESTAMO)),
           'Monto RD$ '||
           TO_CHAR(NVL(SUM(MONTO_DESEMBOLSADO),0),
                   'FM9G999G999G990D00',
                   'NLS_NUMERIC_CHARACTERS=''.,'''),
           'fa-building',
           'u-color-16',
           5
    FROM   BaseData
    WHERE  CodigoEstadoActual = 'CRD'
      AND  CanalDesembolsoDeterminado = 'Sucursal (tradicional)'
    UNION ALL
    SELECT 'Créditos Cancelados',
           TO_CHAR(COUNT(DISTINCT ID_REPRESTAMO)),
           'Monto RD$ '||
           TO_CHAR(NVL(SUM(MTO_PREAPROBADO),0),
                   'FM9G999G999G990D00',
                   'NLS_NUMERIC_CHARACTERS=''.,'''),
           'fa-times-circle-o',
           'u-color-7',
           6
    FROM   BaseData
    WHERE  CodigoEstadoActual = 'CC'
    UNION ALL
    SELECT 'Link Vencido',
           TO_CHAR(COUNT(DISTINCT ID_REPRESTAMO)),
           'Monto RD$ '||
           TO_CHAR(NVL(SUM(MTO_PREAPROBADO),0),
                   'FM9G999G999G990D00',
                   'NLS_NUMERIC_CHARACTERS=''.,'''),
           'fa-chain-broken',
           'u-color-8',
           7
    FROM   BaseData
    WHERE  CodigoEstadoActual = 'AN'
    UNION ALL
    SELECT 'Créditos Anulados',
           TO_CHAR(COUNT(DISTINCT ID_REPRESTAMO)),
           'Monto RD$ '||
           TO_CHAR(NVL(SUM(MTO_PREAPROBADO),0),
                   'FM9G999G999G990D00',
                   'NLS_NUMERIC_CHARACTERS=''.,'''),
           'fa-ban',
           'u-color-9',
           8
    FROM   BaseData
    WHERE  CodigoEstadoActual = 'CRN'
)
ORDER BY order_col;
