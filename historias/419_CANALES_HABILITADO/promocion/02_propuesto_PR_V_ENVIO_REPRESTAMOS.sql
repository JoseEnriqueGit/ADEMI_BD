-- ============================================================================
-- ENTORNO        : Produccion (PROPUESTO — pendiente de desplegar)
-- OBJETO         : PR.PR_V_ENVIO_REPRESTAMOS
-- TIPO           : VIEW
-- DESPLEGADO     : (pendiente)
-- HISTORIA/TICKET: 419 (recuperacion de canales habilitados) + incidente regresion
-- MOTIVO         : Reimplementar el mapeo de CANAL_DESC para los canales 3 (carga
--                  dirigida) y 4 (campana especial), que en PROD caian al ELSE y
--                  devolvian el codigo crudo. Cambio QUIRURGICO sobre la version VIVA:
--                  SOLO se amplia el CASE de CANAL_DESC (forma parametrizada). El filtro
--                  CANALES_HABILITADOS y el resto del cuerpo quedan identicos a PROD.
-- REQUISITO PROD : deben existir en PA_PARAMETROS_MVP los parametros
--                  CANAL_CARGA_DIRIGIDA y CANAL_CAMPANA_ESPECIAL (ver checks pre-deploy).
-- ============================================================================
CREATE OR REPLACE FORCE VIEW PR.PR_V_ENVIO_REPRESTAMOS
(ID_REPRESTAMO, NUMERO_IDENTIFICACION, CANAL, CANAL_DESC, NOMBRES,
APELLIDOS, MTO_PREAPROBADO, CONTACTO, SUBJECT_EMAIL, TEXTO_MENSAJE,
FECHA_PROCESO, FECHA_VENCIMIENTO, ESTADO)
BEQUEATH DEFINER
AS
SELECT R.ID_REPRESTAMO,
       C.NUMERO_IDENTIFICACION,
       CR.CANAL,
       CASE CR.CANAL
          WHEN PR.PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('CANAL_SMS')              THEN 'CANAL_SMS'
          WHEN PR.PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('CANAL_EMAIL')            THEN 'CANAL_EMAIL'
          WHEN PR.PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('CANAL_CARGA_DIRIGIDA')   THEN 'CANAL_CARGA_DIRIGIDA'
          WHEN PR.PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('CANAL_CAMPANA_ESPECIAL') THEN 'CANAL_CAMPANA_ESPECIAL'
          ELSE CR.CANAL
       END CANAL_DESC,
       C.NOMBRES,
       C.PRIMER_APELLIDO || ' ' || C.SEGUNDO_APELLIDO APELLIDOS,
       R.MTO_PREAPROBADO,
       CR.VALOR CONTACTO,
       CASE CR.CANAL
          WHEN '2' THEN PR.PR_PKG_REPRESTAMOS.f_OBT_subject_email(R.ID_REPRESTAMO)
          ELSE NULL
       END SUBJECT_EMAIL,
       PR.PR_PKG_REPRESTAMOS.F_OBT_BODY_MENSAJE(PF.PRIMER_NOMBRE,
                                                R.FECHA_PROCESO,
                                                CR.CANAL) TEXTO_MENSAJE,
       R.FECHA_PROCESO,
       R.FECHA_PROCESO
       + PR.PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('DIA_CADUCA_LINK') Fecha_Vencimiento,
       R.ESTADO
  FROM PR.PR_REPRESTAMOS R,
       CLIENTES_B2000 C,
       PR.PR_CANALES_REPRESTAMO CR,
       PA.PERSONAS_FISICAS PF
WHERE R.CODIGO_EMPRESA = PR.PR_PKG_REPRESTAMOS.f_obt_Empresa_Represtamo
   AND R.ID_REPRESTAMO = R.ID_REPRESTAMO || ''
   AND R.ESTADO = 'NP'
   AND C.CODIGO_EMPRESA = R.CODIGO_EMPRESA
   AND C.CODIGO_CLIENTE = R.CODIGO_CLIENTE
   AND CR.CODIGO_EMPRESA = R.CODIGO_EMPRESA
   AND CR.ID_REPRESTAMO = R.ID_REPRESTAMO
   AND CR.CANAL = CR.CANAL || ''
   AND PF.COD_PER_FISICA(+) = R.CODIGO_CLIENTE
   AND EXISTS (SELECT 1
                 FROM PR.PR_SOLICITUD_REPRESTAMO O
                WHERE O.CODIGO_EMPRESA = R.CODIGO_EMPRESA
                  AND O.ID_REPRESTAMO = R.ID_REPRESTAMO)
   AND CR.CANAL IN (SELECT PR.PR_PKG_REPRESTAMOS.F_OBT_PARAMETRO_REPRESTAMO(COLUMN_VALUE)
                      FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_OBT_VALOR_PARAMETROS('CANALES_HABILITADOS')));


CREATE OR REPLACE PUBLIC SYNONYM PR_V_ENVIO_REPRESTAMOS FOR PR.PR_V_ENVIO_REPRESTAMOS;
