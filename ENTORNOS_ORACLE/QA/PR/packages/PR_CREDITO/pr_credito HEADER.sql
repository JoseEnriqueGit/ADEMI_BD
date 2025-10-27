create or replace PACKAGE    PR_CREDITO AS
   --
   -- Autor AValverde  Fecha Creacion 30/06/2015
   -- Descripcion: Contiene procedimientos para la creacion de creditos.

   -- VARIABLES. --
   ----------------
   --
   -- Varible tipo registro que contiene
   Type T_rec_pr_creditos Is Record (
      CODIGO_EMPRESA                  NUMBER(4),   --Codigo de la Empresa.
      NO_CREDITO                      NUMBER(7),   --Numero de Credito.
      CODIGO_AGENCIA                  NUMBER(5),   --Codigo de la Agencia.
      CODIGO_MONEDA                   NUMBER(2),   --Codigo de Moneda.
      CODIGO_CLIENTE                  NUMBER(7),   --Codigo de Cliente.
      CODIGO_DIRECCION                NUMBER(8),   --Codigo de Direccion del Cliente.
      TIPO_CREDITO                    NUMBER(3),   --Tipo de Credito.
      ESTADO                          VARCHAR2(2), --Estado del Credito.
      MONTO_CREDITO                   NUMBER(16,2),--Monto del Credito.
      ES_LINEA_CREDITO                VARCHAR2(1), --Es Linea de Credito     (S/N).
      TIPO_LINEA                      VARCHAR2(1), --Tipo de Linea de Credito:    (E)nvolvente. (R)evolvente.
      MANEJO                          NUMBER(1),   --Manejo:  (1) Operaciones  (2) Movimientos
      MODALIDAD_COBRO                 VARCHAR2(1), --Tipo de Modalidad de Cobro:  (H)orizontal.  (V)ertical.
      TIPO_INTERESES                  VARCHAR2(1), --Tipo de Intereses:      (A)nticipados.  (V)encidos.
      TIPO_CALENDARIO                 NUMBER(1),   --Tipo de Calendario:(1)  Natural/Natural.(2)  Natural/Financiero. (3)  Financiero/Financiero. (4)  Financiero/Natural.
      TIPO_CUOTA                      VARCHAR2(1), --Tipo de Cuota:    (N) - Nivelada. (L) - Libre.(M) - Multiperiodica.(P) - Principal Nivelado.(V) - Al Vencimiento. (U) - Un Solo Pago.
      CODIGO_PERIODO_CUOTA            VARCHAR2(2), --Codigo del Periodo de Cobro de la Cuota.
      CODIGO_PERIODO_INTERESES        VARCHAR2(2), --Codigo del Periodo de Cobro de los Intereses si el tipo de cuota es Multiperiodica.
      PERIODO_COMISION_NORMAL         VARCHAR2(2), --Codigo del Periodo de Cobro de la Comision.
      COMISION_NORMAL                 NUMBER(10,4),--Porcentaje de Comision a Cobrar.
      CUOTA                           NUMBER(16,2),--Monto de la Cuota.
      MONTO_DESEMBOLSADO              NUMBER(16,2),--Monto Total Desembolsado.
      MONTO_PAGADO_PRINCIPAL          NUMBER(16,2),--Monto Pagado en Principal.
      MONTO_PAGADO_INTERESES          NUMBER(16,2),--Monto Pagado en Intereses.
      INTERESES_ACUMULADOS            NUMBER(16,2),--Total en Intereses Acumulados.
      MONTO_REVALORIZACION            NUMBER(16,2),--Monto de Revalorizacion del Credito.
      INTERESES_EN_SUSPENSO           NUMBER(16,2),--Total en Intereses en Suspenso.
      CUOTA_ANTERIOR                  NUMBER(16,2),--Monto de la Cuota Anterior.
      PLAZO                           NUMBER(5),   --Cantidad de Dias Plazo
      PLAZO_SEGUN_UNIDAD              NUMBER(5),  --plazo en meses --malmanzar 10-05-2018             
      ID_SISTEMA_EXTERNO              VARCHAR2(15),--Numero de Credito del Sistema Anterior
      NO_SOLICITUD                    NUMBER(7),   --Numero de Credito del Sistema Anterior
      NO_CREDITO_ORIGEN               NUMBER(7),   --Numero de Credito Origen (Linea de Credito).
      TIPO_TASA                       VARCHAR2(1), --Tipo de Tasa de Interes: (F)ija.(V)ariable.
      CODIGO_TIPO_DE_TASA             NUMBER(2),   --Codigo del Tipo de Tasa de Interes.
      VARIACION_BASE                  NUMBER(10,4),--Variacion de la Tasa de Interes.
      TASA_INTERES                    NUMBER(10,4),--Tasa de Interes.
      TASA_ORIGINAL                   NUMBER(10,4),--Tasa Original de Interes.
      CODIGO_TASA_MORATORIOS          NUMBER(2),   --Codigo del Tipo de Tasa de Moratorios.
      VARIACION_MORA                  NUMBER(10,4),--Variacion  de la Tasa de Moratorios.
      TASA_MORATORIOS                 NUMBER(10,4),--Tasa de Moratorios.
      PERIODO_REVISION_TASA           VARCHAR2(2), --Periodo de Revision de la Tasa de Interes.
      VARIACION_MAX_REVISION          NUMBER(10,4),--Variacion Maxima en la Revision de Tasas de Interes.
      VARIACION_MAX_TOTAL             NUMBER(10,4),--Variacion Minima en la Revision de Tasas de Interes.
      GRACIA_PRINCIPAL                NUMBER(5),   --Dias de Gracia en Principal.
      GRACIA_MORA                     NUMBER(3),   --Dias de Gracia en Moratorios.
      CODIGO_ORIGEN                   NUMBER(2),   --Codigo del Origen de los Fondos.
      NO_PROGRAMA_ASOCIADO            VARCHAR2(20),--Numero de Programa Asociado.
      CODIGO_EJECUTIVO                VARCHAR2(10),--Codigo del Ejecutivo de Credito.
      COBRADOR                        NUMBER(2),   --CCodigo del Cobrador.
      CODIGO_REFERENTE                NUMBER(3),   --Codigo del Referente del Credito.
      CODIGO_ANALISTA                 NUMBER(5),   --Codigo del Analista de Credito.
      CODIGO_NIVEL_APROBACION         NUMBER(2),   --Codigo del Nivel de Aprobacion del Credito.
      F_APERTURA                      DATE,        --Fecha de Apertura del Credito.
      F_VENCIMIENTO                   DATE,        --Fecha de Vencimiento del Credito.
      F_CANCELACION                   DATE,        --Fecha de Cancelacion del Credito.
      F_ADJUDICACION                  DATE,        --Fecha de Adjudicacion del Credito.
      F_ULTIMA_REVISION               DATE,        --Fecha de Ultima Revision de Tasas de Interes.
      F_ULTIMO_PAGO_PRINCIPAL         DATE,        --Fecha de Ultimo Pago de Principal.
      F_ULTIMO_PAGO_INTERESES         DATE,        --Fecha de Ultimo Pago de Intereses.
      F_PRIMER_DESEMBOLSO             DATE,        --Fecha del Primer Desembolso del Credito.
      F_ULTIMO_DESEMBOLSO             DATE,        --Fecha del Ultimo Desembolso del Credito.
      F_PROXIMA_COMISION              DATE,        --Fecha de la Proxima Comision del Credito.
      F_APROBACION                    DATE,        --Fecha de Aprobacion del Credito.
      F_ULTIMO_PAGO_MORA              DATE,        --Fecha de Ultimo Pago de Moratorios.
      F_RECONOCIM_INTERESES           DATE,        --Fecha de Reconocimiento de Intereses.
      F_PRINCIPAL_ANTERIOR            DATE,        --Fecha del Ultimo Pago de Principal Anterior.
      F_INTERESES_ANTERIOR            DATE,        --Fecha del Ultimo Pago de Interes Anterior.
      F_MORA_ANTERIOR                 DATE,        --Fecha del Ultimo Pago de Mora Anterior.
      F_ULTIMA_REVALORIZACION         DATE,        --Fecha de Ultima Revalorizacion.
      TIPO_ABONO                      VARCHAR2(1), --Tipo de Abono: (I) - Ingreso desde Cajas.(A) - Cuenta Contable. (C) - Cuenta Relacionada.
      CUENTA_ABONO                    NUMBER(25),  --Cuenta desde donde se Efectuaran los Abonos.
      TIPO_DESEMBOLSO                 VARCHAR2(1), --Tipo de Desembolso: (K) - Cheque. A) - Cuenta Contable.(C) - Cuenta Relacionada.
      CUENTA_DESEM                    NUMBER(25),  --Cuenta a donde se Efectuaran los Desembolsos.
      CONTINUA_COBRO_INTERESES        VARCHAR2(1), --Continua el Cobro de Intereses  (S/N).
      DIA_PAGO                        VARCHAR2(2), --Dia de Pago del Credito.
      MARCA_REV_TASA                  VARCHAR2(1), --Marca al Credito para Revision de Tasas de Interes.
      REVALORIZA                      VARCHAR2(1),  --Revaloriza  (S/N).
      OBSERVACIONES1                  VARCHAR2(255),--Observaciones #1.
      OBSERVACIONES2                  VARCHAR2(255),--Observaciones #2.
      CODIGO_SUB_APLICACION           NUMBER(3),    --Codigo de la Sub Aplicacion.
      MONTO_VARIACION                 NUMBER(16,2), --Monto de Variaciones al Principal.
      CODIGO_ACTIVIDAD                NUMBER(5),    --Codigo de Actividad Economica.
      CODIGO_SUBACTIVIDAD             NUMBER(5),    --Codigo de SubActividad Economica.
      CODIGO_CALIFICACION_SISTEMA      VARCHAR2(5),  --Codigo de Calificacion dada por el Sistema.
      CODIGO_CALIFICACION_MANUAL       VARCHAR2(5),  --Codigo de Calificacion dada Manualmente.
      OBSERVACIONES_CALIFICACION       VARCHAR2(255),--Observaciones Referentes a la Calificacion.
      ATRASO_PROMEDIO                  NUMBER(5),    --Atraso Promedio.
      TIPO_COMISION                    VARCHAR2(1),  --Tipo de Comision.
      PLAN_INVERSION                   NUMBER(3),    --Codigo del Plan de Inversion.
      PAIS_DESTINO                     NUMBER(6),    --Codigo del Pais Destino.
      DEPARTAMENTO_DESTINO             NUMBER(6),    --Codigo del Departamento Destino.
      MUNICIPIO_DESTINO                NUMBER(6),    --Codigo del Municipio Destino.
      DISTRITO_DESTINO                 NUMBER(6),    --Codigo del Distrito Destino.
      CODIGO_SUB_CLASE                 NUMBER(6),    --Codigo de la SubClase (SubSubActividad).
      TIPO_MORA                        VARCHAR2(1),  --Tipo de Mora.
      PORCENTAJE_TASA_MORA             NUMBER(7,4),  --Porcentaje de Tasa de Mora.
      APROBADO_POR                     VARCHAR2(10), --Codigo del Usuario que Aprueba el Credito.
      CODIGO_PLAZO                     NUMBER(2),    --Codigo del Tipo de Plazo.
      TASA_ORIGINAL_MORA               NUMBER(10,4), --Tasa Original de Mora.
      MONTO_X_DESEMBOLSAR              NUMBER(16,2), --Monto por Desembolsar.
      CALIFICADO_POR                   VARCHAR2(10), --Codigo del Usuario que Califico al Credito.
      F_ULTIMA_CALIFICACION            DATE,         --Fecha de la Ultima Calificacion Efectuada.
      PLAZO_OPERACIONES                NUMBER(5),    --Plazo de las Operaciones Hijas.
      PERMITE_SOBREGIRO                VARCHAR2(1),  --Permite Sobregiro  (S/N).
      PORCENTAJE_SOBREGIRO             NUMBER(10,4), --Porcentaje de Sobregiro.
      F_PRORROGA                       DATE,         --Fecha de la Prorroga al Vencimiento.
      F_ULTIMO_PAGO_COMISION           DATE,         --Fecha del Ultimo Pago de la Comision.
      F_PROXIMA_REVISION               DATE,         --Fecha de la Proxima Revision de Tasas.
      F_ULTIMA_REV_MORA                DATE,         --Fecha de Ultima Revision de Moratorios.
      OBSERVACIONES3                   VARCHAR2(255),--Observaciones #3.
      OBSERVACIONES4                   VARCHAR2(255),--Observaciones #4.
      BLOQUEO_DESEMBOLSO               VARCHAR2(1),  --Bloqueo sobre el Desembolso.
      DESC_CARGOS                      VARCHAR2(1),  --Descuenta los Cargos en el Desembolso (S/N).
      DESC_POLIZA                      VARCHAR2(1),  --Descuenta la Poliza en el Desembolso (S/N).
      DESC_CUOTA                       VARCHAR2(1),  --Descuenta la Cuota en el Desembolso (S/N).
      DESC_COMISION                    VARCHAR2(1),  --Descuenta la Comision en el Desembolso (S/N).
      ACUMULA_INTERESES                VARCHAR2(1),  --Acumula Intereses  (S/N).
      VARIACION_MINIMA                 NUMBER(10,4), --Variacion Minima.
      VARIACION_MAXIMA                 NUMBER(10,4), --Variacion Maxima.
      TIPO_REVISION                    VARCHAR2(1),  --Tipo de Revision: (A)utomatica. (M)anual.
      PERIODOS_GRACIA_PRINCIPAL        NUMBER(2),    --Periodos de Gracia en Principal.
      F_PAGO_COMISION_ATRASADA         DATE,         --Fecha de Pago de Comision Atrasada.
      TIPO_REGRESO_COBRO               VARCHAR2(2 ), --Tipo de Regreso de Cobro.
      F_PAGO_COBRO_ADMINISTRATIVO      DATE,         --Fecha de Pago de Cobro Administrativo.
      BASE_CALCULO_MORATORIOS          NUMBER(3),    --Base de Calculo de Moratorios  (360 o 365)
      INTERESES_ANTICIPADOS            NUMBER(16,2), --Intereses Anticipados.
      INTERESES_ANTES_COBRO_JUDICIAL   NUMBER(16,2), --Intereses Acumulados antes de Envio a Cobro Judicial.
      MARCA_COBRO_ADMINISTRATIVO       VARCHAR2(1),  --Cobro Administrativo sin importar atraso (S/N)
      PORC_SALDO_NO_UTILIZADO          NUMBER(10,4), --Porcentaje a cobrarse sobre Desembolsos Parciales de Lineas de Credito.
      F_ULTIMO_PAGO_INTERESES_VENC     DATE,         --Fecha de ultimo pago de intereses despues del vencimiento del credito
      F_PROXIMA_MORA_FLAT              DATE,         --Fecha de proxima generacion de mora flat
      RENOVACION                       NUMBER(2),
      COD_NOTARIO                      VARCHAR2(15), --Codigo del abogado notario
      CLIENTE_PROSPECTO                VARCHAR2(1),
      NUMERO_CF                                   VARCHAR2(19),
      DESCUENTA_INTERESES_DESEMBOLSO   VARCHAR2(1),  --Indicador para prestamos que se descuenta los intereses en el desembolso
      CANTIDAD_CUOTAS_DESCONTAR        NUMBER(5),    --Cantidad de cuotas descontadas en el desembolso
      NO_POLIZA_BCO                             NUMBER(16),   --Numero de polizas para vehiculo
      IND_PR_VEHICULO                          VARCHAR2(1),  --Indica si el prestamo fue emitido para financiar la compra de vehiculo
      CANTIDAD_COBRO_CARGO              NUMBER(5),
      DESTINO_DE_FONDOS                     VARCHAR2(200 ),
      COD_PROMOTOR                            VARCHAR2(10), --Codigo de promotor de venta
      F_RESTRUCTURACION                     DATE,         --Fecha en que se el credito paso de Restructurado a Vigente.
      F_RESTRUC_A_VIGENTE                   DATE,         --Fecha en que el prestamo para se restructurado a vigente
      RES_APR_INMED                              VARCHAR2(5),  --Codigo del resultado de la aprobacion inmediata. Hace referencia a la tabla PA.PA_RESULT_APR_INMED.
      DIR_SUCURSAL                                VARCHAR2(200),--Direccion de la Sucursal de la Tienda.
      MTO_INICIAL_COTIZACION               NUMBER(18,2), --Monto con que se inicio la cotizacion.
      MTO_FINANCIADO                            NUMBER(18,2), --Monto financiado por el BSC.
      VENDEDOR                                       VARCHAR2(120),--Nombre del Vendedor.
      PORCIENTO_RETENCION                   NUMBER(18,4), --Porcentaje de Retencion establecido.
      NETO_PAGAR                                   NUMBER(18,2), --Monto Neto a Pagar.
      NO_COTIZACION                              VARCHAR2(120),--Numero de la Cotizacion.
      GASTOS_CIERRE                             NUMBER(18,2), --Monto de gastos para el cierre.
      COMISIONPTO15                             NUMBER(18,2), --Monto de la comision del 0.15%.
      INT_COMPLETIVO_ACUM                  NUMBER(18,2), --Acumulado de intereses completivos
      DIAS_PERIODO_CUOTA                    NUMBER(4),     --Frecuencia de pago
      DESC_VALOR_TASA_CORRIENTES    NUMBER(10,4),
      DESC_TASA_INTERES_BASE            VARCHAR2(200),
      VARIACION_MIN_INTERES                NUMBER(10),
      VARIACION_MAX_INTERES               NUMBER(10),
      DESC_TASA_MORA_BASE                 VARCHAR2(200),
      DESC_VALOR_TASA_MORATORIOS   NUMBER(10,4),
      NUM_GRUPO_MICROCREDITO           NUMBER(15),
      SEGREGACION_RD                           Varchar2(6),
      --
      CODIGO_CLIENTECO                  NUMBER(7),   --Codigo de Cliente.
      CODIGO_RELACIONCO             VARCHAR2(1),
      --
      ESINCENDIO_PYME VARCHAR2(1)  --- Excello:JPH/ADEMI:Manuel Rodriguez:2017-08-01: REQ_59191_Seguro_Insendio_Pimes 
      
   );
   --
   -- Variables locales
   v_fec_apertura DATE;
--+--------------------------------------------------------------------------------------+
   --| SISTEMA : Banca                                                                      |
   --| MODULO  : PR                                                                         |
   --| AUTOR   : AVavlerde                                                                  |
   --| CREACION: (Ver:1.0.0) 30/06/2015                                                     |
   --| DESCRIP.: Procedimiento que crea un credito con base a los parametros ingresados.    |
   --| PARAMTROS:  p_codigo_empresa: Codigo de empresa en la que se desea generar el credito|
   --|             p_codigo_agencia: Codigo de la agencia en la que se desea generar el     |
   --|                               credito.                                               |
   --|             p_no_credito: Se retorna el numero de credito generado                   |
   --|             p_credito:    Variable tipo registro que permite el ingreso de los datos |
   --|                            de la tabla PR_CREDITOS.                                  |   
   --|             p_mensaje: Retorna el codigo de error, de no presentarse se devuelve nulo|
   --|           poder realizar una investigacion, extraccion de datos o reporte            |
   --|           relacionando ambos movimientos como una sola operacion.                    |
   --+--------------------------------------------------------------------------------------+  
  PROCEDURE Inserta_Credito(
     p_codigo_empresa     Number,
     p_codigo_agencia     Number,
     p_no_credito         IN OUT Number, 
     p_credito            IN OUT T_rec_pr_creditos,
     pMensajeError        In Out Varchar2);
  --
  --

--+--------------------------------------------------------------------------------------+
   --| SISTEMA : Banca                                                                      |
   --| MODULO  : PR                                                                         |
   --| AUTOR   : AVavlerde                                                                  |
   --| CREACION: (Ver:1.0.0) 30/06/2015                                                     |
   --| DESCRIP.: Procedimiento que crea un microcredito.                                    |
   --| PARAMTROS:  p_codigo_empresa: Codigo de empresa en la que se desea generar el credito|
   --|             p_codigo_agencia: Codigo de la agencia en la que se desea generar el     |
   --|                               credito.                                               |
   --|             p_tipo_credito Se retorna el numero de credito generado                   |
   --|             p_num_grupo:    Variable tipo registro que permite el ingreso de los datos |
   --|                            de la tabla PR_CREDITOS.                                  |
   --|             p_no_credito: Se retorna el numero de credito generado                   |      
   --|             p_mensaje: Retorna el codigo de error, de no presentarse se devuelve nulo|
   --|           poder realizar una investigacion, extraccion de datos o reporte            |
   --|           relacionando ambos movimientos como una sola operacion.                    |
   --+--------------------------------------------------------------------------------------+  
  PROCEDURE Inserta_MicroCredito(
     p_codigo_empresa     Number,
     p_codigo_agencia     Number,
     p_tipo_credito       Number,
     p_num_grupo          Number,
     p_codIdioma          Varchar2,
     p_no_credito         IN OUT Number, 
     pMensajeError        In Out Varchar2);    
     -- 
--+--------------------------------------------------------------------------------------+
   --| SISTEMA : Banca                                                                      |
   --| MODULO  : PR                                                                         |
   --| AUTOR   : AVavlerde                                                                  |
   --| CREACION: (Ver:1.0.0) 01/07/2015                                                     |
   --| DESCRIP.: Procedimiento genera un nuevo consecutivo para el numero de credito.       |
   --| PARAMTROS:  p_codigo_empresa: Codigo de empresa en la que se desea generar el credito|
   --|             p_codigo_agencia: Codigo de la agencia en la que se desea generar el     |
   --|                               credito.                                               |
   --|             p_consecutivo  Se retorna el numero de credito generado                   |      
   --|             p_mensaje: Retorna el codigo de error, de no presentarse se devuelve nulo|
   --|           poder realizar una investigacion, extraccion de datos o reporte            |
   --|           relacionando ambos movimientos como una sola operacion.                    |
   --+--------------------------------------------------------------------------------------+       
    Procedure Consecutivo_Credito(P_Codigo_Empresa  In Varchar2,
                                     P_Codigo_Agencia  In Varchar2,
                                     P_CONSECUTIVO     IN OUT NUMBER,
                                     P_MENSAJE         IN OUT VARCHAR2 );
    --
    --
    Procedure Calcula_Tasa_Interes (
       p_codigo_empresa     Number,
       p_codigo_agencia     Number,
       p_credito            IN OUT T_rec_pr_creditos,
       pMensajeError        In Out Varchar2);
   --
    procedure CALCULA_CUOTA(
           -- del credito
           p_codigo_empresa in number,
           p_no_credito in number,
           p_f_primer_desem in date,
           p_f_vencimiento in date,
           p_gracia_principal in number, -- en dias
           p_saldo_real in number,
           p_tipo_cuota in varchar2,
           p_periodicidad in number,     -- cantidad dias periodic. de interes
           p_tasa in number,             -- porcentaje (23, 27.5, etc)
           p_tipo_interes in varchar2,   -- (V)encido o (A)nticipado
           p_tipo_calendario in number,  -- tipos de cal: 1, 2, 3 o 4
           p_plazo_total in number,      -- en dias
           -- especificos
           p_f_calculo in date,
           p_con_saldo_teorico in boolean,
           p_con_gracia_principal in boolean,
           -- salida
           p_cuota in out number,
           p_msj_error in out varchar2
        ) ;
    --
    --
    procedure Agregar_Dias(p_f_base          in date,
                           p_dias            in number,
                           p_tipo_calendario in number,
                           p_f_resultado     in out date,
                           p_msj_error       in out varchar2);    
     --
     --    
     Procedure Busca_Extras_Cliente(P_Codigo_Empresa    In Varchar2,
                                    P_Codigo_Actividad  In Out	Number,
                                    p_codigo_cliente    In Number,
                                    P_Codigo_Ejecutivo  In Out Varchar2,
                                    P_Desc_Ejecutivo    In Out Varchar2,                               
                                    P_Desc_Actividad    In Out Varchar2,
                                    P_Agencia_Labora    In Out Varchar2, --FAMH --- 22-04-2005 PROBLEMA CON LA AGENCIA
                                    P_Credito           In Out T_rec_pr_creditos,
                                    P_CodIdioma         In Varchar2
                                    );
      --
      --
      Procedure Obtiene_PlanInversion(P_Codigo_Empresa       In Varchar2,
                                    P_Cod_Idioma           In Varchar2,
                                    P_Plan_Inversion       In Out Number,
                                    P_Desc_Plan_Inversion  In Out Varchar2) ;
--
-- IGH, Req RCC002. Procedimiento para inseertar un cr'dito x un sobregiro NO autorizado
   --|             p_mensaje: Retorna el codigo de error, de no presentarse se devuelve nulo|
   --|           poder realizar una investigacion, extraccion de datos o reporte            |
   --|           relacionando ambos movimientos como una sola operacion.                    |
   --+--------------------------------------------------------------------------------------+  
  PROCEDURE Inserta_Sobregiro(
     p_codigo_empresa     Number,
     p_codigo_agencia     Number,
     p_tipo_credito       Number,
     p_num_grupo          Number,
     p_codIdioma          Varchar2,
     pCodCliente          varchar2, 
     pMonto               number,   
     pCuentaAbono         varchar2,
     pMensajeError        In Out Varchar2) 
     ;
     --
     --
    Procedure crea_credito_pda (
            p_codempresa Number,
            p_codagencia Number,
            p_PLAZO                           NUMBER,
            p_tasa                            NUMBER        DEFAULT 0,
            p_frecuencia                  VARCHAR2,
            p_CUOTA                           NUMBER        DEFAULT 0,
            p_TIPOCREDITO               VARCHAR2,
            reg1                    in out pr_credito.t_rec_pr_creditos,
            p_nrocredito          in out    Varchar2,
            p_mensajeerror     in out     Varchar2
           ) ;
END PR_CREDITO;