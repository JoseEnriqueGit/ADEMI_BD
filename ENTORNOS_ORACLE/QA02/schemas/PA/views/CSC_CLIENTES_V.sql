CREATE OR REPLACE FORCE VIEW PA.CSC_CLIENTES_V
(COD_CLIENTE, CODIGO_EMPRESA, CODIGO_AGENCIA, SUCURSAL, NOMBRES,
NACIONALIDAD, SEGUNDA_NACIONALIDAD, N_SEGUNDA_NACIONALIDAD, PASAPORTES, FECHA_NACIMIENTO,
ESTADO_CIVIL, DESC_ESTADO_CIVIL, SEXO, FEC_INCLUSION, EMAIL_USUARIO,
RANGO_INGRESOS, IND_FUNCIONARIO, OBS_FUNCIONARIO, IND_PARENTFUNCI, OBS_PARENTFUNCI,
IND_FATCA, FATCA_PASAPORTE, FATCA_SS, FATCA_TIN, FATCA_RESIDENTE,
FATCA_GREENCARD, FATCA_DIRECCION, FATCA_TEL, DIRECCION, CEDULA,
LICENCIA_CONDUCIR, TELEFONO_CELULAR, TELEFONO_RESIDENCIA, TELEFONO_OFICINA, FAX_LABORAL,
ACTIVIDAD_ECONOMICA, PRESTAMO, CERTIFICADO, AHORRO, TC,
MONTO_INICIAL, ORIGEN_FONDOS, FORMA_OPERACION, TRANSFERENCIA, CHEQUE,
EFECTIVO, TARJETA_CREDITO, PROPOSITO_OPERACION, MONEDA, TOTAL_ACTIVO,
VENTAS_INGRESO, NOMBRE_REL_PEP, OCUPACION, TIPO_GENERADOR_DIVISA)
BEQUEATH DEFINER
AS
SELECT /*+ NO_CPU_COSTING */
       a.cod_cliente,
       a.codigo_empresa,
       a.codigo_agencia,
       (SELECT z.descripcion
          FROM pa.agencia z
         WHERE Z.COD_EMPRESA = '1'
           AND z.cod_agencia = TO_CHAR(a.codigo_agencia)) sucursal,
       SUBSTR( a.nombres || ' ' || b.primer_apellido || ' ' || b.segundo_apellido, 1, 80) NOMBRES,
       NVL(UPPER(PA.OBT_NACIONALIDAD(a.cod_cliente)), UPPER(b.nacionalidad)) nacionalidad,
       CASE
           WHEN PA.Contar_nacionalidad(a.cod_cliente) = 0 THEN 'NO'
           WHEN PA.Contar_nacionalidad(a.cod_cliente) = 1 THEN 'NO'
           ELSE 'SI'
       END Segunda_Nacionalidad,
       NVL(
           (SELECT I.NACIONALIDAD
              FROM ID_PERSONAS I, PA.personas_fisicas P
             WHERE I.COD_PERSONA = P.COD_PER_FISICA
               AND I.NACIONALIDAD <> P.NACIONALIDAD
               AND I.COD_PERSONA = a.cod_cliente
               AND ROWNUM <= 1),
           'N/A') N_SEGUNDA_NACIONALIDAD,
       NVL(PA.Obt_otros_pasaportes(a.cod_cliente), 'N/A') pasaportes,
       b.fec_nacimiento fecha_nacimiento,
       b.est_civil estado_civil,
       (SELECT UPPER(ETIQUETA)     DESCRIPCION
          FROM PA.CAMPOS_LISTA
         WHERE COD_IDIOMA = 'ESPA'
           AND NOM_FORMA = 'PADATPEF'
           AND COD_SISTEMA = 'PA'
           AND NOM_BLOQUE = 'B_PERFIS'
           AND NOM_CAMPO = 'EST_CIVIL'
           AND VALOR = b.est_civil) desc_estado_civil,
       b.sexo,
       b.fec_inclusion,
       CASE
           WHEN INSTR(email_usuario, '@') = 0 THEN
                email_usuario || CASE
                                      WHEN INSTR(email_servidor, '@') = 0 THEN
                                          '@' || email_servidor
                                      ELSE
                                          email_servidor
                                  END
           ELSE
               email_usuario
       END email_usuario,
       b.rango_ingresos,
      CASE
          WHEN PEP1.COD_PERSONA IS NOT NULL AND NVL(PEP1.CODIGO_PARENTESCO,'') is null THEN 'S'
          ELSE 'N'
          END AS ind_funcionario,
       NVL(PEP1.CARGO_PEP, 'N/A') obs_funcionario,
       CASE WHEN PEP1.NOMBRE_PARENTESCO IS NOT NULL THEN 'S' ELSE 'N' END ind_parentfunci,
       NVL(UPPER(PEP1.nombre_parentesco), 'N/A') obs_parentfunci,
       NVL(R1.ind_fatca, 'N/A') ind_fatca,
       NVL(R1.fatca_pasaporte, 'N/A') fatca_pasaporte,
       NVL(R1.fatca_ss, 'N/A') fatca_ss,
       NVL(R1.fatca_tin, 'N/A') fatca_tin,
       NVL(R1.fatca_residente, 'N/A') fatca_residente,
       NVL(R1.fatca_greencard, 'N/A') fatca_greencard,
       NVL(R1.fatca_direccion, 'N/A') fatca_direccion,
       NVL(R1.FATCA_TEL, 'N/A') FATCA_TEL,
       PA.obt_direccion_actualizada(a.cod_cliente) direccion,
       NVL(pa.OBT_NUM_ID_PERSONA(a.cod_cliente, '1'), pa.OBT_NUM_ID_PERSONA(a.cod_cliente, '5')) Cedula,
       NVL(NVL(pa.obt_identificacion_persona(a.cod_cliente, '7'), pa.obt_identificacion_persona(a.cod_cliente, '5')), NVL(pa.obt_identificacion_persona(a.cod_cliente, '3'), 'N/A')) Licencia_conducir,
       NVL(PA.obt_telefono_persona(a.cod_cliente, 'C'), 'N/A') telefono_celular,
       NVL(NVL(PA.obt_telefono_persona(a.cod_cliente, 'D'), NVL(PA.obt_telefono_persona(a.cod_cliente, 'R'), PA.obt_telefono_persona(a.cod_cliente, 'T'))), 'N/A') telefono_residencia,
       NVL(NVL(PA.obt_telefono_persona(a.cod_cliente, 'O'), PA.obt_telefono_persona(a.cod_cliente, 'X')), 'N/A') telefono_oficina,
       NVL(PA.obt_telefono_persona(a.cod_cliente, 'F'), 'N/A') fax_laboral,
       NVL(h.concepto, NVL(b.actividad, 'N/A')) actividad_economica,
       CASE WHEN o.tipo_producto = 'PRESTAMOS' THEN 'X' ELSE '' END prestamo,
       CASE WHEN o.tipo_producto = 'CERTIFICADOS' THEN 'X' ELSE '' END certificado,
       CASE WHEN o.tipo_producto = 'CUENTA EFECTIVO' THEN 'X' ELSE '' END ahorro,
       CASE WHEN o.tipo_producto = 'TARJETA DE CREDITO' THEN 'X' ELSE '' END tc,
       O.monto_inicial,
       o.origen_fondos,
       o.instrumento_bancario forma_operacion,
       CASE WHEN o.instrumento_bancario = 'TRANSFERENCIA' THEN 'X' ELSE '' END transferencia,
       CASE WHEN o.instrumento_bancario = 'CHEQUE' THEN 'X' ELSE '' END cheque,
       CASE WHEN o.instrumento_bancario = 'EFECTIVO' THEN 'X' ELSE '' END efectivo,
       CASE WHEN o.instrumento_bancario = 'TARJETA_CREDITO' THEN 'X' ELSE '' END tarjeta_credito,
       o.proposito proposito_operacion,
       (SELECT MO.DESCRIPCION FROM PA.MONEDA MO WHERE MO.COD_MONEDA = O.COD_MONEDA) MONEDA,
       NVL(b.CP_TOTAL_ACTIVO, 0) TOTAL_ACTIVO,
       NVL(b.VENTAS_INGRESOS, 0) VENTAS_INGRESO,
       NVL(PEP1.NOMBRE_REL_PEP, 'N/A') NOMBRE_REL_PEP,
       NVL(
           (SELECT t.Desc_Grupos_Primarios     Ocupacion
              FROM T174_Casif_Ocupaciones t
             WHERE t.Grupos_Primarios = B.OCUPACION_CLASIF_NAC
               AND B.cod_per_fisica = A.COD_CLIENTE), 'N/A') OCUPACION,
       NVL(
           (SELECT REGEXP_SUBSTR((s.descripcion), '^[^.]*')
              FROM Pa_Tablas_Sib_Detalle s
             WHERE S.Id_Tabla = '147.0'
               AND s.codigo = B.TIPO_GEN_DIVISAS
               AND B.cod_per_fisica = A.COD_CLIENTE), 'N/A') TIPO_GENERADOR_DIVISA
  FROM personas_fisicas                   b,
       pa.clientes_b2000                  a,
       PA.ACTIVIDADES_ECONOMICAS_BC_CIIU  h,
       (SELECT R2.COD_CLIENTE,
               CASE R2.es_residente WHEN 'S' THEN 'R' WHEN 'N' THEN 'C' ELSE 'N' END ind_fatca,
               NVL(R2.numero_pasaporte, 'N/A') fatca_pasaporte,
               NVL(R2.numero_ss, 'N/A') fatca_ss,
               NVL(R2.numero_tin, 'N/A') fatca_tin,
               NVL(R2.es_residente, 'N') fatca_residente,
               NVL(R2.num_green_card, 'N/A') fatca_greencard,
               NVL(R2.direccion, 'N/A') fatca_direccion,
               NVL(R2.NUM_TELEFONO, 'N/A') FATCA_TEL
          FROM datos_regulacion_fatca R2
         WHERE R2.COD_CLIENTE = R2.COD_CLIENTE||'' AND R2.COD_PAIS <> '0') R1,
       (SELECT /*+ FIRST_ROWS(30) */ ROWID ID,
               S1.cod_persona,
               S1.tipo_producto,
               S1.instrumento_bancario,
               S1.MONTO_INICIAL,
               S1.proposito,
               S1.ORIGEN_FONDOS,
               S1.COD_MONEDA
          FROM PA.INFO_PROD_SOL S1
         WHERE S1.ROWID IN (SELECT S2.ROWID
                              FROM PA.INFO_PROD_SOL S2
                             WHERE S2.COD_MONEDA = 1
                            UNION ALL
                            SELECT S3.ROWID
                              FROM PA.INFO_PROD_SOL S3
                             WHERE S3.COD_MONEDA = 2) ) o,
       (SELECT PEP2.COD_PERSONA,
               PEP2.CARGO CARGO_PEP,
               PEP2.codigo_parentesco,
               par.descripcion NOMBRE_PARENTESCO,
               PEP2.INSTITUCION_POLITICA,
               PEP2.NOMBRE_REL_PEP
          FROM LISTA_PEP PEP2,
               PARENTESCO par
         WHERE PEP2.CONSECUTIVO = PEP2.CONSECUTIVO || ''
           AND PAR.COD_EMPRESA (+) = '1'
           AND PAR.COD_PARENTESCO (+) = NVL(PEP2.CODIGO_PARENTESCO, -1)
         ORDER BY PEP2.CONSECUTIVO) PEP1
WHERE     a.cod_cliente = b.cod_per_fisica
       AND A.CODIGO_EMPRESA = '1'
       AND a.cod_cliente = o.cod_persona(+)
       AND a.cod_cliente = R1.cod_cliente(+)
       AND a.cod_cliente = PEP1.cod_persona(+)
       AND B.COD_ACTIVIDAD = H.segregacion_rd(+)
       AND O.ROWID = f_obt_datos_operacion(A.COD_CLIENTE)
       and o.COD_MONEDA IN (1, 2);

GRANT SELECT ON PA.CSC_CLIENTES_V TO BCC;
GRANT SELECT ON PA.CSC_CLIENTES_V TO BCJ;
GRANT SELECT ON PA.CSC_CLIENTES_V TO BPA;
GRANT SELECT ON PA.CSC_CLIENTES_V TO BPR;
GRANT SELECT ON PA.CSC_CLIENTES_V TO BTC;
