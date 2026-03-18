create or replace PACKAGE    PR_PKG_DESEMBOLSO
AS

/*
     malmanzar:  Req. 27780 flujo desembolso represtamo con firma digital.
        1-Calculo cuota en la aprobación para igualar cuota contrato a cuota desembolso "Excepciones D+6, cambio de mes"
        2-Generar proyección al momento de la aprobación y enviar a FileFlow
        3-Incluir logica d+6 en tabla proyección
       
*/


    V_Fecha_Sist       DATE := Calendar.Fecha_Actual_Calendario ('PR', '1', '50');
    VC                 NUMBER (4) := 0;

    V_Sub_Trans        VARCHAR2 (5);
    Et_Mens23          VARCHAR2 (200);
    Et_Etiq1           VARCHAR2 (200);
    Et_Etiq2           VARCHAR2 (200);
    --
    Vobs1              VARCHAR2 (200);
    Vobs3              VARCHAR2 (200);
    Et_Mens8           VARCHAR2 (200);
    Et_Descripcion3    VARCHAR2 (200);
    Et_Descripcion4    VARCHAR2 (200);
    Et_Descripcion5    VARCHAR2 (200);
    Et_Observaciones   VARCHAR2 (200);
    
    TYPE t_Parametro_Reporte IS RECORD
    (
        Nombre             VARCHAR2(60),
        Valor              VARCHAR2(4000)
    );
    
    TYPE t_Params_Reportes IS TABLE OF t_Parametro_Reporte;

    --- Definicion de Types
    TYPE T_Pr_Creditos IS RECORD
    (
        Oficial_Autorizado                VARCHAR2 (1),
        Numero_Cf                         VARCHAR2 (19),
        Codigo_Empresa                    NUMBER (4),  --Codigo De La Empresa.
        Codigo_Agencia                    NUMBER (5),  --Codigo De La Agencia.
        Estado                            VARCHAR2 (2),  --Estado Del Credito.
        Es_Linea_Credito                  VARCHAR2 (1), --Es Linea De Credito     (S/N).
        Tipo_Linea                        VARCHAR2 (1), --Tipo De Linea De Credito:    (E)Nvolvente. (R)Evolvente.
        Codigo_Cliente                    NUMBER (7),     --Codigo De Cliente.
        Manejo                            NUMBER (1), --Manejo:  (1) Operaciones  (2) Movimientos
        Tipo_Intereses                    VARCHAR2 (1), --Tipo De Intereses:      (A)Nticipados.  (V)Encidos.
        Tipo_Calendario                   NUMBER (1), --Tipo De Calendario:(1)  Natural/Natural.(2)  Natural/Financiero. (3)  Financiero/Financiero. (4)  Financiero/Natural.
        Tipo_Cuota                        VARCHAR2 (1), --Tipo De Cuota:    (N) - Nivelada. (L) - Libre.(M) - Multiperiodica.(P) - Principal Nivelado.(V) - Al Vencimiento. (U) - Un Solo Pago.
        Codigo_Periodo_Cuota              VARCHAR2 (2), --Codigo Del Periodo De Cobro De La Cuota.
        Codigo_Periodo_Intereses          VARCHAR2 (2), --Codigo Del Periodo De Cobro De Los Intereses Si El Tipo De Cuota Es Multiperiodica.
        Periodo_Comision_Normal           VARCHAR2 (2), --Codigo Del Periodo De Cobro De La Comision.
        Comision_Normal                   NUMBER (10, 4), --Porcentaje De Comision A Cobrar.
        Cuota                             NUMBER (16, 2), --Monto De La Cuota.
        Monto_Desembolsado                NUMBER (16, 2), --Monto Total Desembolsado.
        Monto_Pagado_Principal            NUMBER (16, 2), --Monto Pagado En Principal.
        Monto_Pagado_Intereses            NUMBER (16, 2), --Monto Pagado En Intereses.
        Monto_Revalorizacion              NUMBER (16, 2), --Monto De Revalorizacion Del Credito.
        Plazo                             NUMBER (5), --Cantidad De Dias Plazo
        No_Solicitud                      NUMBER (7), --Numero De Credito Del Sistema Anterior
        Tasa_Interes                      NUMBER (10, 4),   --Tasa De Interes.
        Gracia_Principal                  NUMBER (5), --Dias De Gracia En Principal.
        Gracia_Mora                       NUMBER (3), --Dias De Gracia En Moratorios.
        Periodos_Gracia_Principal         NUMBER (2), --Periodos De Gracia En Principal.
        Codigo_Origen                     NUMBER (2), --Codigo Del Origen De Los Fondos.
        Codigo_Nivel_Aprobacion           NUMBER (2), --Codigo Del Nivel De Aprobacion Del Credito.
        F_Ultimo_Pago_Principal           DATE, --Fecha De Ultimo Pago De Principal.
        F_Ultimo_Pago_Intereses           DATE, --Fecha De Ultimo Pago De Intereses.
        F_Primer_Desembolso               DATE, --Fecha Del Primer Desembolso Del Credito.
        F_Ultimo_Desembolso               DATE, --Fecha Del Ultimo Desembolso Del Credito.
        F_Proxima_Comision                DATE, --Fecha De La Proxima Comision Del Credito.
        F_Aprobacion                      DATE, --Fecha De Aprobacion Del Credito.
        F_Ultimo_Pago_Mora                DATE, --Fecha De Ultimo Pago De Moratorios.
        F_Reconocim_Intereses             DATE, --Fecha De Reconocimiento De Intereses.
        F_Principal_Anterior              DATE, --Fecha Del Ultimo Pago De Principal Anterior.
        F_Intereses_Anterior              DATE, --Fecha Del Ultimo Pago De Interes Anterior.
        F_Mora_Anterior                   DATE, --Fecha Del Ultimo Pago De Mora Anterior.
        F_Ultima_Revalorizacion           DATE, --Fecha De Ultima Revalorizacion.
        Cuenta_Abono                      NUMBER (25), --Cuenta Desde Donde Se Efectuaran Los Abonos.
        Tipo_Desembolso                   VARCHAR2 (1), --Tipo De Desembolso: (K) - Cheque. A) - Cuenta Contable.(C) - Cuenta Relacionada.
        Cuenta_Desem                      NUMBER (25), --Cuenta A Donde Se Efectuaran Los Desembolsos.
        Observaciones1                    VARCHAR2 (255),  --Observaciones #1.
        Observaciones2                    VARCHAR2 (255),  --Observaciones #2.
        Modificado_Por                    VARCHAR2 (10),
        Fecha_Modificacion                DATE,
        Codigo_Sub_Aplicacion             NUMBER (3), --Codigo De La Sub Aplicacion.
        Tipo_Comision                     VARCHAR2 (1),    --Tipo De Comision.
        F_Ultimo_Pago_Comision            DATE, --Fecha Del Ultimo Pago De La Comision.
        F_Pago_Comision_Atrasada          DATE, --Fecha De Pago De Comision Atrasada.
        F_Pago_Cobro_Administrativo       DATE, --Fecha De Pago De Cobro Administrativo.
        Dias_Periodo_Interes              NUMBER (4),     --Frecuencia De Pago
        Dias_Periodo_Cuota                NUMBER (4),     --Frecuencia De Pago
        Dias_Periodo_Comision             NUMBER (4),     --Frecuencia De Pago
        Dias_Intereses                    NUMBER (4),
        Dias_Comision                     NUMBER (4),
        F_Intereses_Hasta                 DATE,
        F_Poliza_Desde                    DATE,
        F_Poliza_Hasta                    DATE,
        F_Comision_Hasta                  DATE,
        Numero_Transaccion                NUMBER (25),
        Numero_Autorizacion_Bcc           NUMBER (10),
        Numero_Asiento                    NUMBER (10),
        Primer_Desembolso                 VARCHAR2 (1),
        No_Credito                        NUMBER (7),     --Numero De Credito.
        No_Credito_Origen                 NUMBER (7), --Numero De Credito Origen (Linea De Credito).
        Monto_Credito                     NUMBER (16, 2), --Monto Del Credito.
        F_Apertura                        DATE, --Fecha De Apertura Del Credito.
        F_Vencimiento                     DATE, --Fecha De Vencimiento Del Credito.
        --
        F_Cancelacion                     DATE, --Fecha De Cancelacion Del Credito.
        F_Adjudicacion                    DATE, --Fecha De Adjudicacion Del Credito.
        F_Ultima_Revision                 DATE, --Fecha De Ultima Revision De Tasas De Interes.
        Tipo_Credito                      NUMBER (3),       --Tipo De Credito.
        Codigo_Moneda                     NUMBER (2),      --Codigo De Moneda.
        Dia_Pago                          VARCHAR2 (2), --Dia De Pago Del Credito.
        Saldo_Disponible                  NUMBER (18, 2),
        Saldo_Actual                      NUMBER (18, 2),
        Realiza_Abono                     VARCHAR2 (30),
        Desc_Tipo_Credito                 VARCHAR2 (200),
        Desc_Moneda                       VARCHAR2 (200),
        Desc_Cliente                      VARCHAR2 (200),
        Es_Cuota_Multiple                 VARCHAR2 (30),
        Intereses_Anticipados             NUMBER (16, 2), --Intereses Anticipados.
        Descuenta_Intereses_Desembolso    VARCHAR2 (1), --Indicador Para Prestamos Que Se Descuenta Los Intereses En El Desembolso
        Cantidad_Cuotas_Descontar         NUMBER (5), --Cantidad De Cuotas Descontadas En El Desembolso
        Monto_Cuotas                      NUMBER (18, 2),
        Monto_Poliza                      NUMBER (18, 2),
        No_Poliza_Bco                     VARCHAR2 (25), --Numero De Polizas Para Vehiculo
        Adicionado_Por                    VARCHAR2 (10),
        Codigo_Referente                  NUMBER (3), --Codigo Del Referente Del Credito.
        Grupo_Tipo_Credito                VARCHAR2 (30),
        Ind_Credito_Universitario         VARCHAR2 (1),
        Multiples_Desembolsos             VARCHAR2 (1),
        Es_Reserva                        VARCHAR2 (1),
        Dias_Extra                        NUMBER (4),
        Plazo_Segun_Unidad                NUMBER (4),
        V_Dias_Periodo_Cuota              NUMBER (4),
        V_Dias_Periodo_Interes            NUMBER (4)
    );

    TYPE T_BKDESEM IS RECORD
    (
        Fecha_Desembolso         DATE,
        Codigo_Cliente           NUMBER (7),              --Codigo De Cliente.
        Tipo_Desembolso          VARCHAR2 (1),
        Paga_Impley              VARCHAR2 (1),
        Numero_Cuenta            VARCHAR2 (25),
        Observaciones1           VARCHAR2 (255),
        Observaciones2           VARCHAR2 (255),
        Observaciones3           VARCHAR2 (255),
        Observaciones4           VARCHAR2 (255),
        Monto_Disponible         NUMBER (20, 2),
        Monto_Sobregiro          NUMBER (20, 2),
        Monto_Desembolso         NUMBER (20, 2),
        Monto_Cancelacion        NUMBER (20, 2),
        Cobrar_Cargos            VARCHAR2 (1),
        Cobrar_Comision          VARCHAR2 (1),
        Monto_Cargos             NUMBER (20, 2),
        Monto_Comision           NUMBER (20, 2),
        Cobrar_Cuota             VARCHAR2 (1),
        Cobrar_Poliza            VARCHAR2 (1),
        Monto_Poliza             NUMBER (20, 2),
        Monto_Cuota              NUMBER (20, 2),
        Monto_Cuota_Principal    NUMBER (20, 2),
        Monto_Cuota_Intereses    NUMBER (20, 2),
        Total_Desembolso         NUMBER (22, 2),
        Plan_Libre               VARCHAR2 (25),
        Monto_Iva_Comision       NUMBER (20, 2),
        Monto_Iva_Cargos         NUMBER (20, 2),
        Nuevosaldo               NUMBER (20, 2),
        Monto_Cargos_A           NUMBER (20, 2),
        Monto_Canc_Creditos      NUMBER (20, 2)
    );

    TYPE Trec_Cargos IS RECORD
    (
        Codigo_Empresa             NUMBER (3),
        No_Credito                 NUMBER (7),
        Codigo_Cargo               NUMBER (3),
        Codigo_Tipo_Transaccion    NUMBER (3),
        Descripcion                VARCHAR2 (100),
        Monto_Porcentaje           NUMBER (18, 2),
        Tipo_Cargo                 VARCHAR2 (1),
        Monto_Cargo                NUMBER (16, 2),
        Monto_Minimo               NUMBER (16, 2),
        Monto_Maximo               NUMBER (16, 2),
        Tipo_Cobro                 VARCHAR2 (1),
        Codigo_Periodo             VARCHAR2 (2),
        Adicionado_Por             VARCHAR2 (10),
        Fecha_Adicion              DATE,
        Modificado_Por             VARCHAR2 (10),
        Fecha_Modificacion         DATE,
        F_Ultima_Generacion        DATE
    );

    TYPE Tbcargos IS TABLE OF Trec_Cargos
        INDEX BY BINARY_INTEGER;

    --- Variables basadas en tipos --
    Bkcredit           T_Pr_Creditos;
    Bkdesem            T_Bkdesem;
    Pbkcargo           Tbcargos;

    FUNCTION Get_Mensaje_Err (P_Mensaje IN VARCHAR2, P_Sistema IN VARCHAR2)
        RETURN VARCHAR2;

    PROCEDURE Genera_Desembolso (
        P_Cod_Empresa       IN     NUMBER,
        P_No_Credito        IN     NUMBER,
        P_Codigo_Agencia    IN     NUMBER,                  ---Agencia proceso
        P_Monto_Desemb      IN     NUMBER,
        p_monto_comision    IN     NUMBER,
        pMontoCancelacion   IN     NUMBER,
        P_Tipo_Desemb       IN     VARCHAR2,
        p_cuenta            IN     VARCHAR2,
        P_Mensaje              OUT VARCHAR2,
        P_Nummov_Desemb        OUT VARCHAR2,
        P_Hacer_Commit      IN     VARCHAR2 DEFAULT 'N');

    PROCEDURE Completa_Asiento (P_Empresa         IN     NUMBER,
                                P_Agencia         IN     NUMBER,
                                P_Moneda          IN     VARCHAR2,
                                P_Credito         IN     NUMBER,
                                P_Aplicacion      IN     VARCHAR2,
                                P_Subaplicacion   IN     NUMBER,
                                P_Transaccion     IN     NUMBER,
                                P_Subtransac      IN     NUMBER,
                                P_Numtransac      IN     VARCHAR2,
                                P_Descrip         IN     VARCHAR2,
                                P_Fecha           IN     DATE,
                                P_Numasiento      IN     NUMBER,
                                P_Auxiliarp       IN     NUMBER,
                                P_Usuario         IN     VARCHAR2,
                                P_Principal       IN     NUMBER,
                                P_Interes         IN     NUMBER,
                                P_Mora            IN     NUMBER,
                                P_Mensajeerr         OUT VARCHAR2);



    PROCEDURE Act_poliza_multiple_desem (pCodigo_Empresa       IN NUMBER,
                                         pNo_Credito           IN NUMBER,
                                         pfecha_desembolso     IN DATE,
                                         pMonto_Desembolsado   IN NUMBER);

    FUNCTION Cancelacion_ReCredito (
        pCodigo_Empresa     IN     NUMBER,
        pNo_Credito         IN     NUMBER,
        pFecha_Desembolso   IN     DATE,
        pNumero_Cuenta      IN     VARCHAR2,
        pCodigo_Agencia     IN     NUMBER,
        pNumAsiento         IN OUT VARCHAR2,
        P_Documento         IN     NUMBER DEFAULT 0 -- Excello:JPH:2019-11-13: Se requiere para identificar la operacion de PR
                                                   )
        RETURN VARCHAR2;

    PROCEDURE descongela_monto_recredito (
        pCodigo_Empresa    NUMBER,
        pCodAgencia        NUMBER,                       --:b_cta.cod_agencia,
        pCodSistema        VARCHAR2,
        pnum_cuenta        cc.cuenta_efectivo.num_cuenta%TYPE,
        pMontoMovimiento   cc.movimto_diario.mon_movimiento%TYPE,
        P_Documento        Movimto_Diario.Num_Documento%TYPE --- Excello:JPH:2019-11-13:REQ_83180: Nuevo Parametro
                                                            );

    PROCEDURE Validaciones_Generales (pCodigo_Empresa   IN     NUMBER,
                                      pNo_Credito       IN     NUMBER,
                                      pTipo_Desem       IN     VARCHAR2,
                                      pNum_Cuenta       IN     VARCHAR2,
                                      pError               OUT VARCHAR2);

    FUNCTION es_recredito (pcodigo_empresa NUMBER, pno_credito NUMBER)
        RETURN BOOLEAN;

    FUNCTION f_punto15_Cancelacion (pcodigo_empresa     NUMBER,
                                    pno_credito         NUMBER,
                                    pFecha_Desembolso   DATE)
        RETURN NUMBER;

    PROCEDURE p_desembolso_digital (P_Cod_Empresa     IN     NUMBER,
                                    P_No_Credito      IN     NUMBER,
                                    P_AGENCIA            OUT NUMBER,
                                    P_NUM_CUENTA         OUT NUMBER,
                                    P_Nummov_Desemb      OUT NUMBER,
                                    P_ERROR              OUT VARCHAR2);

    PROCEDURE p_reporte_desembolso (pCodigo_Empresa          NUMBER,
                                    pNo_Credito              NUMBER,
                                    pTipo_Abono              VARCHAR2,
                                    pNo_Recibo               NUMBER,
                                    pCodigo_Agencia        NUMBER,
                                    pError            IN OUT VARCHAR2);

    PROCEDURE P_Descongela_Monto_Digital (
        pCodigo_Empresa   NUMBER,
        pCodAgencia       NUMBER,                        --:b_cta.cod_agencia,
        pCodSistema       VARCHAR2,
        pnum_cuenta       cc.cuenta_efectivo.num_cuenta%TYPE,
        ---pMontoMovimiento   cc.movimto_diario.mon_movimiento%TYPE,
        P_Documento       Movimto_Diario.Num_Documento%TYPE --- Excello:JPH:2019-11-13:REQ_83180: Nuevo Parametro
                                                           );


PROCEDURE p_envia_archivo_FileFlow (p_No_Credito      IN     NUMBER,
                                        P_NombreArchivo   IN     VARCHAR2,
                                        P_IdAplication    IN     VARCHAR2,
                                        P_IdTipoDocumento   IN     VARCHAR2,  
                                        pError               OUT VARCHAR2);


PROCEDURE P_REALIZA_DESEMBOLSO_D(P_Cod_Empresa NUMBER,P_No_Credito NUMBER);

FUNCTION ReadFileToBlob (in_Filename    IN     VARCHAR2,
                             in_Directory   IN     VARCHAR2,
                             out_Error         OUT VARCHAR2)
        RETURN BLOB; 
        
FUNCTION Generar_Reporte(p_NombreReporte        IN VARCHAR2,
                         p_Conexion             IN VARCHAR2,
                         p_Parametros           IN t_Params_Reportes,
                         p_Error                OUT VARCHAR2)
RETURN BLOB;

PROCEDURE Genera_Pagos_Proyectado(pEmpresa      IN  NUMBER, 
                                  pNoCredito    IN  NUMBER,
                                  pSesion       OUT NUMBER);

PROCEDURE Generar_Cargos_2 (P_Cod_Empresa     IN     NUMBER,
                            P_No_Credito      IN     NUMBER,
                            P_Saldo_Credito   IN     NUMBER,
                            P_Msj_Error       IN OUT VARCHAR2);    
                            
FUNCTION Cuotas_Atrasadas (P_Codigo_Empresa         NUMBER,
                           P_No_Credito             NUMBER,
                           P_Fecha_Calendario       DATE,
                           P_Error              OUT VARCHAR2)
        RETURN NUMBER; 
        
FUNCTION F_CARTERA (pcodigo_emprea NUMBER, pNo_credito NUMBER)RETURN VARCHAR2;        
        
FUNCTION f_cargos_desembolso(P_Cod_Empresa NUMBER,P_No_Credito NUMBER)  return NUMBER;        
                                       
 PROCEDURE Simula_Desembolso (
           P_Cod_Empresa      IN     NUMBER,
           P_No_Credito       IN     NUMBER,
           p_cuota            OUT    NUMBER, --23-05-2025
           P_Mensaje             OUT VARCHAR2
        );
                
                              
END PR_PKG_DESEMBOLSO;