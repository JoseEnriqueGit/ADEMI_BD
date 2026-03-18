CREATE OR REPLACE PACKAGE CD.PKG_CD_DIGITAL IS
vtiptransac         VARCHAR2(3):='57'; 
vsubtiptransac      VARCHAR2(3):='6';
vdiapagocd          VARCHAR2(2):='26';

--var credito a cuenta por cancelacion CC
ntiptracan_cc     VARCHAR2(3):='58';
nsubtiptracan_cc  VARCHAR2(3):='5';

--var cancelacion a vencimiento CD
ntiptra_canc_venc     VARCHAR2(3):='4';
nsubtiptra_canc_venc  VARCHAR2(3):='1';

--var cancelacion anticipada CD
ntiptra_canc_anti      VARCHAR2(3):='4';
nsubtiptra_canc_anti   VARCHAR2(3):='2';

TYPE siiresult_set IS REF CURSOR; 

TYPE RECORD_DATOS_APERTURA_CD IS RECORD
        (   cod_empresa         VARCHAR2(5),
            cod_persona         VARCHAR2(25),
            num_id              VARCHAR2(25),
            cod_tipo_id         VARCHAR2(5),
            num_cuenta          VARCHAR2(15),
            num_certificado     VARCHAR2(15),
            cod_producto        VARCHAR2(5),
            cod_moneda          VARCHAR2(2),
            monto_apertura      NUMBER,
            cod_tasa_cd         VARCHAR2(5),
            plazo               NUMBER,
            Tasabruta           NUMBER,
            tipo_interes        VARCHAR2(1),
            fecha_apertura      DATE,
            fecha_expiracion    DATE
        );
PROCEDURE getOpenInformationCD_api(pbody                  IN BLOB,
                                   pv_productCode         OUT VARCHAR2,
                                   pv_rateCode            OUT VARCHAR2,
                                   Pn_openRate            OUT NUMBER,
                                   pn_taxePercent         OUT NUMBER,
                                   pn_interestTotal       OUT NUMBER,
                                   pn_taxeAmount          OUT NUMBER,
                                   pv_fechaapertura       OUT VARCHAR2,
                                   pv_fechavence          OUT VARCHAR2,
                                   pn_errornumber         OUT NUMBER,
                                   pv_errorMessage        OUT VARCHAR2);
                                
PROCEDURE getCancellationInfocd_api(pbody                    IN BLOB,
                                    pv_cancellationType       OUT VARCHAR2,
                                    pn_cancellationAmount     OUT NUMBER,
                                    pn_accountNumber          OUT NUMBER,
                                    pn_penalAmount            OUT NUMBER,
                                    pn_errornumber            OUT NUMBER,
                                    pv_errorMessage           OUT VARCHAR2);
                                   
PROCEDURE Cancellationcd_api(pbody                    IN BLOB,
                             pv_cancellationType       OUT VARCHAR2,
                             pn_cancellationAmount     OUT NUMBER,
                             pn_openAmount             OUT NUMBER,
                             pn_accruedInterest        OUT NUMBER,
                             pn_currentInterest        OUT NUMBER,
                             pn_taxesRate              OUT NUMBER,
                             pn_taxesAmount            OUT NUMBER,
                             pn_acountNumber           OUT NUMBER,
                             pn_penalRate              OUT NUMBER,
                             pn_penalAmount            OUT NUMBER,
                             pn_autorizationNumber     OUT NUMBER,
                             pn_CreditAmount           OUT NUMBER,
                             pv_cancellationDate       OUT VARCHAR2,
                             pn_errornumber            OUT NUMBER,
                             pv_errorMessage           OUT VARCHAR2);
                                   
 PROCEDURE OpenCertificadoCD_api(pbody                  IN BLOB,
                                 Pv_numcertificado      OUT VARCHAR2,
                                 pv_beneficiary         OUT VARCHAR2,
                                 pn_openingAmount       OUT NUMBER,
                                 pv_productCode         OUT VARCHAR2,
                                 pv_rateCode            OUT VARCHAR2,
                                 Pn_openRate            OUT NUMBER,
                                 pn_transaccionid       OUT NUMBER,
                                 pv_certificateType     OUT VARCHAR2,
                                 pv_currencyIso         OUT VARCHAR2,
                                 pv_openingAmountLetTer OUT VARCHAR2,
                                 pn_interestTotal       OUT NUMBER,
                                 pn_taxeAmount          OUT NUMBER,
                                 pv_methodPayment       OUT VARCHAR2,
                                 pn_termInDay           OUT NUMBER,
                                 pv_location            OUT VARCHAR2,
                                 pv_issuingEntity       OUT VARCHAR2,
                                 pv_verificationCode    OUT VARCHAR2,
                                 pv_fechaapertura       OUT VARCHAR2,
                                 pv_fechavence          OUT VARCHAR2,
                                 pv_securityCode        OUT VARCHAR2,
                                 pv_QRCode              OUT VARCHAR2,
                                 pv_errornumber         OUT NUMBER,
                                 pv_errorMessage        OUT VARCHAR2);

                                 
PROCEDURE   OpenCertificateCD  (pv_companyId            IN VARCHAR2,
                                 pn_customerId          IN VARCHAR2,
                                 pv_identicationNumber  IN VARCHAR2,
                                 pv_identificationType  IN VARCHAR2,
                                 pv_accountNumber       IN NUMBER,
                                 pv_currencyCode        IN VARCHAR2,
                                 pv_productCode         IN VARCHAR2,
                                 pn_openingAmount       IN NUMBER,
                                 pn_termInDay           IN NUMBER,
                                 pv_rateCode            IN VARCHAR2,
                                 pn_openingRate         IN NUMBER,
                                 pv_certificateNumber   OUT VARCHAR2,
                                 pv_verificationCode    OUT VARCHAR2, 
                                 pd_openingDate         OUT VARCHAR2,
                                 pd_expirationDate      OUT VARCHAR2,
                                 pn_idmovimiento        OUT NUMBER,
                                 pv_errornumber         OUT VARCHAR2,
                                 pv_errorMessage        OUT VARCHAR2);
PROCEDURE aplica_contabilidad(pcodempresa    IN     VARCHAR2,
                              pcodagencia    IN     VARCHAR2,
                              pnummovim      IN     NUMBER,
                              ptiptrans      IN     NUMBER,
                              pgencaratula   IN     VARCHAR2,
                              pnumasiento    IN OUT NUMBER,
                              perrorNun      IN OUT VARCHAR2, 
                              pmensaje       IN OUT VARCHAR2,
                              descrip        IN     VARCHAR2,
                              preferencia    IN     VARCHAR2 DEFAULT '');
FUNCTION aplica_contable(ptiptransaccion in number)
        RETURN BOOLEAN;


        
FUNCTION OpenRateValidate(Pn_Empresa        IN  NUMBER,
                              pv_codproducto    IN VARCHAR2,
                              pn_plazo          IN NUMBER,
                              pn_monto          IN NUMBER,
                              pv_rateCode       IN VARCHAR2,
                              pn_spread         OUT NUMBER,
                              pn_tasa           IN NUMBER) RETURN BOOLEAN;
PROCEDURE getInfoCancellationcd(pv_companyId              IN NUMBER ,
                               pn_customerId             IN NUMBER,
                               pv_identificationNumber   IN VARCHAR2,
                               pv_identificationType     IN VARCHAR2,
                               pv_certificateNumber      IN VARCHAR2,
                               pv_currencyCode           IN VARCHAR2,
                               pn_accountNumber           IN NUMBER,
                               pv_cancellationType       OUT VARCHAR2,
                               pn_cancellationAmount     OUT NUMBER,
                               pn_penalAmount            OUT NUMBER,
                               pn_creditAccount           OUT NUMBER,
                               pn_errornumber            OUT NUMBER,
                               pv_errorMessage           OUT VARCHAR2);   
PROCEDURE  CancellationCertificate(pv_companyId             IN NUMBER ,
                                   pn_customerId            IN NUMBER,
                                   pv_identificationNumber  IN VARCHAR2,
                                   pv_identificationType    IN VARCHAR2,
                                   pv_certificateNumber     IN VARCHAR2,
                                   pv_currencyCode          IN VARCHAR2,
                                   pn_accountNumber         IN NUMBER,
                                   pv_cancellationType      OUT VARCHAR2,
                                   pn_openAmount            OUT NUMBER,
                                   pn_accruedInterest       OUT NUMBER,
                                   pn_currentInterest       OUT NUMBER,
                                   pn_taxesRate             OUT NUMBER,
                                   pn_taxesAmount           OUT NUMBER,
                                   pn_cancellationAmount    OUT NUMBER,
                                   pn_penalAmount           OUT NUMBER,
                                   pn_creditAccount         OUT NUMBER,
                                   pd_cancellationDate      OUT DATE,
                                   pn_errornumber           OUT NUMBER,
                                   pv_errorMessage          OUT VARCHAR2);                                
FUNCTION getAmortizationCd(pn_openingAmount       IN NUMBER,
                           pn_baseCalendar        IN NUMBER,
                           pn_percentTaxe         IN NUMBER,
                           pn_termInDay           IN NUMBER,
                           pv_interestType        IN VARCHAR2,
                           pn_openingRate         IN NUMBER,
                           pd_openingDate         IN DATE,
                           pd_expirationDate      IN DATE
                           ) RETURN CD.tAMORTIZACIONCD_DIGITAL;
FUNCTION getCertificateNumber(P_Empresa IN VARCHAR2, 
                             P_Agencia IN VARCHAR2,
                             P_Moneda  IN NUMBER,
                             P_Error   IN OUT VARCHAR2, 
                             P_SqlCode IN OUT VARCHAR2) RETURN VARCHAR2;
FUNCTION calcula_penalidad (p_empresa        IN NUMBER, 
                            p_certificado    IN VARCHAR2, 
                            pcod_producto    IN VARCHAR2,
                            p_monto          IN NUMBER,
                            pfecha_cal       IN DATE,
                            p_fecha_emision  IN DATE,
                            p_fecha_ult_cap  IN DATE,
                            p_fecha_ult_ren  IN DATE,
                            p_fecha_vence    IN DATE,
                            p_dias_pendiente IN NUMBER)
 RETURN NUMBER;
FUNCTION get_codigo_hast( i_num_certificado       IN  VARCHAR2,
                          i_cedula                IN  VARCHAR2,
                          i_nombre_cliente        IN  VARCHAR2,
                          o_cod_error             OUT VARCHAR2,
                          o_mensaje               OUT VARCHAR2) RETURN VARCHAR2; 
END;
/

