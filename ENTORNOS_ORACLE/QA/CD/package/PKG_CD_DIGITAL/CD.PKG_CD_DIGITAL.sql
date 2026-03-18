CREATE OR REPLACE PACKAGE BODY CD.PKG_CD_DIGITAL
IS                            
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
                                   pv_errorMessage        OUT VARCHAR2)
                                   
                                    IS
       v_datos_apertura RECORD_DATOS_APERTURA_CD;

        ciclo               NUMBER;
        nMontototal         NUMBER:=0;
        nMontoIntciclob     NUMBER:=0;
        nMontoIntciclon     NUMBER:=0;
        nMontocdciclo       NUMBER;
        nMontoIntAcum       NUMBER:=0;
        dFechaliq           DATE;
        dFechaciclo         DATE;
        dFechant            DATE;
        nDias               NUMBER;
        nMontoRetencion     NUMBER;
        nMontoNeto          NUMBER;
        nInteresTotal       NUMBER;

       nSaldoDisponible     NUMBER;
       vcod_productacta     pa.productos.cod_producto%TYPE;
       vcodAgencia          pa.agencia.cod_agencia%TYPE;

       dfechacalcd          DATE;
       dfechacalcc          DATE;
       ntasaminima          NUMBER:=0;
       ntasamaxima          NUMBER:=0;
       vexc_impuesto        PA.PERSONAS.COBR_NODGII_132011%TYPE;
       vexiste              VARCHAR2(1):='';
       vesEmpleado          VARCHAR2(1):='';

       pd_openingDate       DATE;
       pd_expirationDate    DATE;
       ncalendario          NUMBER;
       ntasaRetencion       NUMBER;
       NSEQUENCELOG         NUMBER;
      BEGIN
        BEGIN
            ia.ia_pkg_apis.LOG_API_CALL(p_endpoint    =>'productParameters',
                                        p_metodo      =>'POST',
                                        p_usuario     =>USER,
                                        p_ip_origen   =>NULL,
                                        p_parametros  =>TO_CLOB(pbody),
                                        p_status_code =>NULL,
                                        p_tiempo_ms   =>NULL,
                                        p_error_msg   =>NULL,
                                        po_secuencia  =>NSEQUENCELOG);
          END;
        v_datos_apertura.cod_empresa         := JSON_VALUE(pbody, '$.openCertificateInfo.companyId');
        v_datos_apertura.cod_persona         := JSON_VALUE(pbody, '$.openCertificateInfo.customerId');
        v_datos_apertura.num_id              := JSON_VALUE(pbody, '$.openCertificateInfo.identificationNumber');
        v_datos_apertura.cod_tipo_id         := JSON_VALUE(pbody, '$.openCertificateInfo.identificationType');
        --v_datos_apertura.cod_producto      := JSON_VALUE(pbody, '$.openCertificateInfo.productCode');
        --v_datos_apertura.cod_tasa_cd       := JSON_VALUE(pbody, '$.openCertificateInfo.rateCode');
        v_datos_apertura.num_cuenta          := JSON_VALUE(pbody, '$.openCertificateInfo.accountNumber');
        v_datos_apertura.cod_moneda          := JSON_VALUE(pbody, '$.openCertificateInfo.currencyCode');
        v_datos_apertura.monto_apertura      := JSON_VALUE(pbody, '$.openCertificateInfo.openingAmount');
        v_datos_apertura.plazo               := JSON_VALUE(pbody, '$.openCertificateInfo.termInDay');
        --v_datos_apertura.Tasabruta         := JSON_VALUE(pbody, '$.openCertificateInfo.openingRate');
        v_datos_apertura.tipo_interes        := JSON_VALUE(pbody, '$.openCertificateInfo.interestType');


        IF v_datos_apertura.cod_empresa IS NULL  THEN
                    pn_errornumber    :=400;
                    pv_errorMessage :='Bad request 401 -Debe ingresar un codigo de empresa para buscar el producto';
        RETURN;
        END IF;

        IF v_datos_apertura.num_id IS NULL  THEN
                    pn_errornumber    :=400;
                    pv_errorMessage :='Bad request 402 -Debe ingresar un n mero de identificaci n del cliente';
        RETURN;
        END IF;

        IF v_datos_apertura.cod_tipo_id IS NULL  THEN
                    pn_errornumber    :=400;
                    pv_errorMessage :='Bad request 403 -Debe ingresar un tipo de identificaci n del cliente';
        RETURN;
        END IF;


        IF v_datos_apertura.num_cuenta IS NULL THEN
                    pn_errornumber:=400;
                    pv_errorMessage:='Bad request -405 No ha ingresado un numero de cuenta para los fondo del certificado digital';
        RETURN;
        END IF;

        IF v_datos_apertura.cod_moneda IS NULL THEN
                    pn_errornumber:=400;
                    pv_errorMessage:='Bad request 406 -La moneda de apertura del producto es obligatorio para la solicitud de certificado digital';
        RETURN;
        END IF;

        IF v_datos_apertura.monto_apertura IS NULL OR v_datos_apertura.monto_apertura<=0 THEN
                    pn_errornumber    :=400;
                    pv_errorMessage :='Bad request 407 -El monto de apertura no puede ser igual o menor que (0)';
        RETURN;
        END IF;


        IF v_datos_apertura.plazo IS NULL OR v_datos_apertura.plazo<=0 THEN
                    pn_errornumber    :=400;
                    pv_errorMessage :='Bad request 408 -El plazo para la apertura no puede ser igual o menor que (0)';
        RETURN;
        END IF;

        IF v_datos_apertura.num_cuenta IS NULL  THEN
                    pn_errornumber    :=400;
                    pv_errorMessage :='Bad request - 410 Debe ingresar un numero de cuenta para confirmar fondos de la apertura del producto';
        RETURN;
        END IF;

        Ciclo:= v_datos_apertura.plazo/30;
        BEGIN
            SELECT 'S'
            INTO vexiste
            FROM pa.id_personas per
            WHERE REPLACE(num_id,'-')=v_datos_apertura.num_id
              AND cod_tipo_id=v_datos_apertura.cod_tipo_id;
              EXCEPTION
              WHEN NO_DATA_FOUND THEN
                   vexiste:='N';
                   pn_errornumber :=401;
                   pv_errorMessage:='Error de validacion 409 -No existe una persona registrada con este numero de Documento '||v_datos_apertura.num_id;
                   RETURN;
        END;


       BEGIN
         SELECT fecha_hoy
           INTO dfechacalcc
           FROM pa.calendario_b2000
          WHERE codigo_empresa = v_datos_apertura.cod_empresa AND 
                codigo_aplicacion = 'BCC';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            dfechacalcc := NULL;
            pn_errornumber :=415;
            pv_errorMessage:='Calendario de CC no definido';
            RETURN; 
      END;

     BEGIN
         SELECT fecha_hoy
           INTO dfechacalcd
           FROM pa.calendario_b2000
          WHERE codigo_empresa = v_datos_apertura.cod_empresa AND 
                codigo_aplicacion = 'BCD';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            dfechacalcd := NULL;
            pn_errornumber :=416;
            pv_errorMessage:='Calendario de CD no definido';
            RETURN; 
     END;
      pd_expirationDate:=dfechacalcd+v_datos_apertura.plazo;

     BEGIN
     SELECT 'S'
      INTO vesEmpleado
      FROM pa.Empleados emp
      WHERE emp.cod_empresa     =   v_datos_apertura.cod_empresa    AND
            emp.cod_per_fisica  =   v_datos_apertura.cod_persona  AND 
            NVL(emp.Esta_activo,'N')='S';
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
           vesEmpleado:='N';
     END;

     BEGIN
      SELECT NVL(cobr_nodgii_132011,'S'),10
      INTO vexc_impuesto,ntasaRetencion
      FROM pa.personas per
      WHERE cod_persona=v_datos_apertura.cod_persona;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
           vexc_impuesto:=NULL;
           pn_errornumber :=401;
           pv_errorMessage:='Bad request 421 - No existe una persona registrada con este numero de ID '||v_datos_apertura.cod_persona;
           RETURN;
      END;

      BEGIN
      SELECT cef.sal_total_cta-ppr.sal_min_cta_alt,cef.cod_producto,cef.cod_agencia
      INTO nSaldoDisponible,vcod_productacta,vcodAgencia
      FROM cc.cuenta_efectivo cef, cc.cara_x_producto ppr
      WHERE cef.cod_empresa     =   v_datos_apertura.cod_empresa        AND 
            cef.num_cuenta      =   v_datos_apertura.num_cuenta         AND 
            cef.cod_cliente     =   v_datos_apertura.cod_persona        AND
            ppr.cod_empresa     =   cef.cod_empresa                     AND
            ppr.cod_producto    =   cef.cod_producto;
            EXCEPTION
      WHEN NO_DATA_FOUND
         THEN
            nSaldoDisponible:= 0;
            vcodAgencia:=NULL;
            vcod_productacta:=NULL;
            pn_errornumber :=409;
            pv_errorMessage:='Error de validaci n - La cuenta de efectivo no existe o no pertence al solicitante';
            RETURN; 
      END;
      /*IF nSaldoDisponible<v_datos_apertura.monto_apertura THEN
        pn_errornumber :=410;
        pv_errorMessage:='Error de validaci¿n - La cuenta de efectivo refleja un saldo insuficiente para realizar esta operaci n';
        RETURN;
      END IF;*/
     BEGIN
    SELECT car.cod_producto
    INTO v_datos_apertura.cod_producto
    FROM cd.cd_producto_x_empresa car, pa.productos pro
    WHERE car.cod_empresa           = v_datos_apertura.cod_empresa AND
    car.forma_calculo_interes   = DECODE(v_datos_apertura.tipo_interes,'N','CU','C','CV',car.forma_calculo_interes) AND
    NVL(car.ind_prd_emp,'N')    = vesEmpleado
    AND car.cod_producto IN (SELECT REGEXP_SUBSTR((SELECT PA.PARAM.PARAMETRO_X_EMPRESA('1', 'CD_CERT_DIGITAL', 'CD') FROM DUAL), '[^,]+', 1, LEVEL) AS DATA
                             FROM DUAL
                             CONNECT BY REGEXP_SUBSTR((SELECT PA.PARAM.PARAMETRO_X_EMPRESA('1', 'CD_CERT_DIGITAL', 'CD') FROM DUAL), '[^,]+', 1, LEVEL) IS NOT NULL)
    AND pro.cod_empresa     =   car.cod_empresa
    AND pro.cod_producto    =   car.cod_producto
    AND pro.cod_moneda      =   v_datos_apertura.cod_moneda
    AND car.monto_minimo<=v_datos_apertura.monto_apertura;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
           v_datos_apertura.cod_producto:='';
           ncalendario:=0;
           ntasaRetencion:=10;
           pn_errornumber :=431;
           pv_errorMessage:='Error de validaci¿n,  No existe un producto de certificado Digital con el monto minimo de apertura de '||v_datos_apertura.monto_apertura;
           RETURN;
    END;

    BEGIN
    SELECT car.cod_producto,car.base_calculo,car.porcentaje_renta
    INTO v_datos_apertura.cod_producto,ncalendario,ntasaRetencion
    FROM cd.cd_producto_x_empresa car, pa.productos pro
    WHERE car.cod_empresa           = v_datos_apertura.cod_empresa AND
    car.forma_calculo_interes   = DECODE(v_datos_apertura.tipo_interes,'N','CU','C','CV',car.forma_calculo_interes) AND
    NVL(car.ind_prd_emp,'N')    = vesEmpleado
    AND car.cod_producto IN (SELECT REGEXP_SUBSTR((SELECT PA.PARAM.PARAMETRO_X_EMPRESA('1', 'CD_CERT_DIGITAL', 'CD') FROM DUAL), '[^,]+', 1, LEVEL) AS DATA
                             FROM DUAL
                             CONNECT BY REGEXP_SUBSTR((SELECT PA.PARAM.PARAMETRO_X_EMPRESA('1', 'CD_CERT_DIGITAL', 'CD') FROM DUAL), '[^,]+', 1, LEVEL) IS NOT NULL)
    AND pro.cod_empresa     =   car.cod_empresa
    AND pro.cod_producto    =   car.cod_producto
    AND pro.cod_moneda      =   v_datos_apertura.cod_moneda;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
           v_datos_apertura.cod_producto:='';
           ncalendario:=0;
           ntasaRetencion:=10;
           pn_errornumber :=432;
           pv_errorMessage:='Error de validaci¿n DE- No existe un producto de certificado Digital con estas caracteristicas especificas';
           RETURN;
    WHEN TOO_MANY_ROWS THEN
           v_datos_apertura.cod_producto:='';
           ncalendario:=0;
           ntasaRetencion:=10;
           pn_errornumber :=432;
           pv_errorMessage:='Error de Validaci¿n DE- Existe mas de un producto de certificado Digital con estas caracter¿sticas espec¿ficas';
           RETURN;
    END;
    pv_productCode:=v_datos_apertura.cod_producto;
    BEGIN
    SELECT pla.cod_tasa,
    CASE WHEN operacion='+' THEN  pla.tasa_minima ELSE  pla.tasa_minima END minimunrate,
    CASE WHEN operacion='+' THEN tasa_maxima ELSE tasa_maxima END maximunrate
    INTO  pv_rateCode, ntasaminima, ntasamaxima
    FROM cd.cd_prd_tasa_plazo_monto pla, cd.cd_producto_x_empresa pro
    WHERE pla.cod_empresa       =   pro.cod_empresa                    AND
          pla.cod_producto      =   v_datos_apertura.cod_producto      AND
          v_datos_apertura.plazo  BETWEEN pla.plazo_minimo             AND   PLA.PLAZO_MAXIMO    AND
          v_datos_apertura.monto_apertura BETWEEN  pla.monto_minimo    AND   pla.monto_maximo    AND
          pla.cod_producto      =   pro.cod_producto    AND 
          --pla.cod_tasa          =   pv_rateCode         AND
          pla.estado            =  'A'                  AND
          pla.cod_producto      =   v_datos_apertura.cod_producto      AND
          pla.fecha_vigencia IN (SELECT MAX(fecha_vigencia) 
                                                         FROM  cd.cd_prd_tasa_plazo_monto 
                                                            WHERE cod_producto =   pla.cod_producto    AND 
                                                                  cod_tasa     =   pla.cod_tasa        AND 
                                                                  plazo_minimo =   pla.plazo_minimo    AND 
                                                                  monto_minimo =   pla.monto_minimo    AND
                                                                  cod_tasa     =   pla.cod_tasa        AND 
                                                                  estado       =   pla.estado);
                                                                  EXCEPTION
                                                                  WHEN NO_DATA_FOUND THEN
                                                                  ntasaminima:=0;
                                                                  ntasamaxima:=0;
                                                                  pn_errornumber      := 451;
                                                                  pv_errorMessage     := 'Error de validaci¿n - No existe un producto parametrizado con estas caracteristicas';
                                                                  RETURN;

 END;
    pn_openRate:= NVL(ntasamaxima,0);
     IF pn_openRate<=0 THEN
         pn_errornumber      := 452;
         pv_errorMessage     := 'Error de validaci¿n - No existe una tasa parametrizada con estas caracteristicas';
         RETURN;
     END IF;

 BEGIN
 SELECT SUM(interes_neto),SUM(retencion_itbis)--SUM(MONTO_INTERES)
 INTO pn_interestTotal,  pn_taxeAmount
 FROM TABLE(SELECT getAmortizationCd(pn_openingAmount      => v_datos_apertura.monto_apertura,
                                     pn_baseCalendar       => ncalendario,
                                     pn_percentTaxe        => NVL(ntasaRetencion,0),
                                     pn_termInDay          => v_datos_apertura.plazo,
                                     pv_interestType       => v_datos_apertura.tipo_interes,
                                     pn_openingRate        => ntasamaxima,
                                     pd_openingDate        => dfechacalcd,
                                     pd_expirationDate     => pd_expirationDate
                            ) FROM dual);
                            EXCEPTION
                            WHEN NO_DATA_FOUND THEN
                            pn_errornumber      := 453;
                            pv_errorMessage     := 'Eror en c¿lculo de rendimiento, verificar parametros del producto'||pv_productCode;
                            WHEN OTHERS THEN
                            pn_errornumber      := 454;
                            pv_errorMessage     := 'Eror en c¿lculo de rendimiento, verificar parametros del producto'||pv_productCode;
                            RETURN;
 END;
                BEGIN
                pn_openRate         := NVL(ntasamaxima,0);
                pn_taxePercent      := NVL(ntasaRetencion,0);
                pv_fechaapertura    := TO_CHAR(dfechacalcd,'dd/mm/yyyy');    
                pv_fechavence       := TO_CHAR(pd_expirationDate,'dd/mm/yyyy');
                pn_errornumber      := 200;
                pv_errorMessage     := 'Ok';
                BEGIN
                UPDATE IA.IA_API_LOGS SET
                status_code  = pn_errornumber,
                error_msg    = pv_errorMessage
                WHERE ID_LOG = NSEQUENCELOG;
                COMMIT;
                END;
                COMMIT;
               END;
END;
PROCEDURE getCancellationInfocd_api(pbody                    IN BLOB,
                                   pv_cancellationType       OUT VARCHAR2,
                                   pn_cancellationAmount     OUT NUMBER,
                                   pn_acountNumber           OUT NUMBER,
                                   pn_penalAmount            OUT NUMBER,
                                   pn_errornumber            OUT NUMBER,
                                   pv_errorMessage           OUT VARCHAR2)
                                   IS

       v_datos_apertura RECORD_DATOS_APERTURA_CD;

       ciclo               NUMBER;
       nMontototal         NUMBER:=0;
       nMontoIntciclob     NUMBER:=0;
       nMontoIntciclon     NUMBER:=0;
       nMontocdciclo       NUMBER;
       nMontoIntAcum       NUMBER:=0;
       dFechaliq           DATE;
       dFechaciclo         DATE;
       dFechant            DATE;
       nDias               NUMBER;
       nMontoRetencion     NUMBER;
       nMontoNeto          NUMBER;
       nInteresTotal       NUMBER;

       nSaldoDisponible     NUMBER;
       vcod_productacta     pa.productos.cod_producto%TYPE;
       vcodAgencia          pa.agencia.cod_agencia%TYPE;

       dfechacalcd          DATE;
       dfechacalcc          DATE;
       ntasaminima          NUMBER:=0;
       ntasamaxima          NUMBER:=0;
       vexc_impuesto        PA.PERSONAS.COBR_NODGII_132011%TYPE;
       vexiste              VARCHAR2(1):='';
       vesEmpleado          VARCHAR2(1):='';

       pd_openingDate       DATE;
       pd_expirationDate    DATE;

       ncalendario          NUMBER;
       ntasaRetencion       NUMBER;

      BEGIN

        v_datos_apertura.cod_empresa         := JSON_VALUE(pbody, '$.cancellationInfo.companyId');
        v_datos_apertura.cod_persona         := JSON_VALUE(pbody, '$.cancellationInfo.customerId');
        v_datos_apertura.num_id              := JSON_VALUE(pbody, '$.cancellationInfo.identificationNumber');
        v_datos_apertura.cod_tipo_id         := JSON_VALUE(pbody, '$.cancellationInfo.identificationType');
        v_datos_apertura.num_certificado     := JSON_VALUE(pbody, '$.cancellationInfo.certificateNumber');
        v_datos_apertura.num_cuenta          := JSON_VALUE(pbody, '$.cancellationInfo.acountNumber');
        v_datos_apertura.cod_moneda          := JSON_VALUE(pbody, '$.cancellationInfo.currencyCode');

        IF v_datos_apertura.cod_empresa IS NULL  THEN
                    pn_errornumber  :=501;
                    pv_errorMessage :='Debe ingresar un codigo de empresa para buscar el producto';
                    RETURN;
        END IF;

        IF v_datos_apertura.num_id IS NULL  THEN
                    pn_errornumber  :=502;
                    pv_errorMessage :='Debe ingresar un codigo de empresa para buscar el producto';
                    RETURN;
        END IF;

        IF v_datos_apertura.cod_tipo_id IS NULL  THEN
                    pn_errornumber  :=503;
                    pv_errorMessage :='Debe ingresar un codigo de empresa para buscar el producto';
                    RETURN;
        END IF;

        IF v_datos_apertura.cod_persona IS NULL THEN
                    pn_errornumber:=505;
                    pv_errorMessage:='El codigo de cliente es necesario para la solicitud de cancelaci n de certificado digital';
                    RETURN;
        END IF;   

        IF v_datos_apertura.num_cuenta IS NULL THEN
                    pn_errornumber:=506;
                    pv_errorMessage:='No ha ingresado un numero de cuenta para los fondo del certificado digital';
                    RETURN;
        END IF;

        IF v_datos_apertura.cod_moneda IS NULL THEN
                    pn_errornumber:=507;
                    pv_errorMessage:='La moneda del producto es obligatorio para la solicitud de cancelacion';
                    RETURN;
        END IF;
         IF v_datos_apertura.num_certificado IS NULL THEN
                    pn_errornumber:=508;
                    pv_errorMessage:='Es necesirio indicar el certificado a cancelar';
                    RETURN;
        END IF;

            BEGIN
                getInfoCancellationcd(pv_companyId             => v_datos_apertura.cod_empresa,
                                       pn_customerId           => v_datos_apertura.cod_persona,
                                       pv_identificationNumber => v_datos_apertura.num_id,
                                       pv_identificationType   => v_datos_apertura.cod_tipo_id,
                                       pv_certificateNumber    => v_datos_apertura.num_certificado,
                                       pv_currencyCode         => v_datos_apertura.cod_moneda,
                                       pn_acountNumber         => v_datos_apertura.num_cuenta,
                                       pv_cancellationType     => pv_cancellationType,
                                       pn_cancellationAmount   => pn_cancellationAmount,
                                       pn_penalAmount          => pn_penalAmount,
                                       pn_creditAcount         => pn_acountNumber,
                                       pn_errornumber          => pn_errornumber,
                                       pv_errorMessage         => pv_errorMessage);
           END;

           dbms_output.put_line('cuenta'||pn_acountNumber);
       END;      

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
                                 pv_openingAmountLetter OUT VARCHAR2,
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
                                 pv_errorMessage        OUT VARCHAR2)
 IS

 v_datos_apertura RECORD_DATOS_APERTURA_CD;
        vCanal                   VARCHAR2(5):='';
        vSECUENCIA               NUMBER;
        vCICLO                   VARCHAR2(6);
        dFECHA                   DATE;
        nCANTIDAD_DIAS           NUMBER;
        nMONTO                   NUMBER;
        nINTERES_REINVERTIDO     NUMBER;
        nINTERES_CICLO           NUMBER;
        nRETENCION_ITBIS         NUMBER;
        nTOTAL                   NUMBER;
        vamortizacion            VARCHAR2(4000):='';
        verror                   VARCHAR2(4000);
        vcodproducto             VARCHAR2(5):='';
        nTasabruta               NUMBER;
        dfechaapertura           VARCHAR2(10);
        dfechaexpiration         VARCHAR2(10);
        NSEQUENCELOG             NUMBER;
        ncalendario              CD.CD_PRODUCTO_X_EMPRESA.BASE_CALCULO%TYPE;
        ntasaRetencion           CD.CD_PRODUCTO_X_EMPRESA.PORCENTAJE_RENTA%TYPE;

        --variables pkm
         vurl               VARCHAR2(4000);
         vidaplication      PLS_INTEGER := 38; -- CUENTASDEAHORROS
         vidtipodocumento   PLS_INTEGER := '618'; -- Formulario de Conozca
         vcodigoreferencia  VARCHAR2(100) := ''; 
         vdocumento         VARCHAR2(30) := 'FCSCPF';
         vorigenpkm         VARCHAR2(100) := 'Onboarding';
         --idtipodocumento    VARCHAR2(5):='';

    BEGIN
     BEGIN
            ia.ia_pkg_apis.LOG_API_CALL(p_endpoint    =>'opendigitalcertificate',
                                        p_metodo      =>'POST',
                                        p_usuario     =>USER,
                                        p_ip_origen   =>NULL,
                                        p_parametros  =>TO_CLOB(pbody),
                                        p_status_code =>NULL,
                                        p_tiempo_ms   =>NULL,
                                        p_error_msg   =>NULL,
                                        po_secuencia  =>NSEQUENCELOG);
          END;
        v_datos_apertura.cod_empresa         := JSON_VALUE(pbody, '$.openCertificateInfo.companyId');
        v_datos_apertura.cod_persona         := JSON_VALUE(pbody, '$.openCertificateInfo.customerId');
        v_datos_apertura.num_id              := JSON_VALUE(pbody, '$.openCertificateInfo.identificationNumber');
        v_datos_apertura.cod_tipo_id         := JSON_VALUE(pbody, '$.openCertificateInfo.identificationType');
        v_datos_apertura.cod_producto        := JSON_VALUE(pbody, '$.openCertificateInfo.productCode');
        v_datos_apertura.cod_tasa_cd         := JSON_VALUE(pbody, '$.openCertificateInfo.rateCode');
        v_datos_apertura.num_cuenta          := JSON_VALUE(pbody, '$.openCertificateInfo.accountNumber');
        v_datos_apertura.cod_moneda          := JSON_VALUE(pbody, '$.openCertificateInfo.currencyCode');
        v_datos_apertura.monto_apertura      := JSON_VALUE(pbody, '$.openCertificateInfo.openingAmount');
        v_datos_apertura.plazo               := JSON_VALUE(pbody, '$.openCertificateInfo.termInDay');
        v_datos_apertura.Tasabruta           := JSON_VALUE(pbody, '$.openCertificateInfo.openingRate');
        v_datos_apertura.tipo_interes        := JSON_VALUE(pbody, '$.openCertificateInfo.interestType');
        v_datos_apertura.fecha_apertura      := TO_DATE(JSON_VALUE(pbody, '$.openCertificateInfo.openingDate'),'dd/mm/yyyy');
        v_datos_apertura.fecha_expiracion    := TO_DATE(JSON_VALUE(pbody, '$.openCertificateInfo.expirationDate'),'dd/mm/yyyy');
        vCanal                               := JSON_VALUE(pbody, '$.canal.idCanal');

        IF v_datos_apertura.cod_empresa IS NULL  THEN
                    pv_errornumber    :=400;
                    pv_errorMessage :='Bad request - Debe ingresar un codigo de empresa para buscar el producto';
        RETURN;
        END IF;

        IF v_datos_apertura.num_id IS NULL  THEN
                    pv_errornumber    :=400;
                    pv_errorMessage :='Bab requeest- Debe ingresar el n mero de identificacion del cliente';
        RETURN;
        END IF;

        IF v_datos_apertura.cod_tipo_id IS NULL  THEN
                    pv_errornumber    :=400;
                    pv_errorMessage :='Bad request debe ingresar el codigo del tipo de identificacion';
        RETURN;
        END IF;

        IF vCanal IS NULL THEN
                pv_errornumber:=400;
                pv_errorMessage:='Bad request- El c¿digo de canal es obligatorio';
                 RETURN;
        END IF;

         IF v_datos_apertura.cod_persona IS NULL THEN
                    pv_errornumber:=400;
                    pv_errorMessage:='Bad request- El c¿digo de persona no pertence a un cliente del Banco';
        RETURN;

        ELSE

        BEGIN
        SELECT UPPER(TRIM(NOMBRE)) 
        INTO pv_beneficiary
        FROM PA.PERSONAS
        WHERE COD_PERSONA=v_datos_apertura.cod_persona;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
        pv_beneficiary:='';
        END;
        BEGIN
        SELECT T1.descripcion, t2.descripcion
        INTO pv_location, pv_issuingEntity
        FROM pa.agencia T1, pa.cantones T2
        WHERE T1.COD_CANTON=T2.COD_CANTON AND
        T2.COD_PAIS='1'             AND
        T1.Cod_Agencia IN (SELECT Codigo_Agencia 
                            From Clientes 
                            WHERE Codigo_Cliente=TO_NUMBER(V_Datos_Apertura.Cod_Persona));
                    EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                    pv_location:='';
                    pv_issuingEntity:='';
                    pv_errornumber:=400;
                    pv_errorMessage:='Bad request- El c¿digo de persona no una agencia activa asignada';
        END;
        END IF;

        IF v_datos_apertura.cod_producto IS NULL THEN
                    pv_errornumber:=400;
                    pv_errorMessage:='Bad request- El c¿digo de producto es obligatorio para la solicitud de certificado digital';
        RETURN;
        END IF;

        IF v_datos_apertura.cod_moneda IS NULL THEN
                    pv_errornumber:=400;
                    pv_errorMessage:='Bad request - La moneda de apertura del producto es obligatorio para la solicitud de certificado digital';
        RETURN;
        ELSE
        BEGIN
            SELECT sigla_sb 
            INTO pv_currencyIso  
            FROM PA.MONEDA 
            WHERE cod_moneda=v_datos_apertura.cod_moneda;
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
            pv_currencyIso:='';
            pv_errornumber:=400;
            pv_errorMessage:='Bad request - La moneda no existe en nuestro sistema CORE, este dato es obligatorio para la solicitud de certificado digital';
            RETURN;
        END;
        END IF;

        IF v_datos_apertura.monto_apertura IS NULL OR v_datos_apertura.monto_apertura<=0 THEN
                    pv_errornumber    :=400;
                    pv_errorMessage :='Bad request - El monto de apertura no puede ser igual o menor que (0)';
        RETURN;
        ELSE
        pn_openingAmount:=v_datos_apertura.monto_apertura;
        END IF;


        IF v_datos_apertura.plazo IS NULL OR v_datos_apertura.plazo<=0 THEN
                    pv_errornumber    :=400;
                    pv_errorMessage :='Bad request - El plazo para la apertura no puede ser igual o menor que (0)';
        RETURN;
        ELSE
        pn_termInDay:=v_datos_apertura.plazo;
        END IF;

        IF  v_datos_apertura.Tasabruta IS NULL OR  v_datos_apertura.Tasabruta<=0 THEN
                    pv_errornumber    :=400;
                    pv_errorMessage :='Bad request - La tasa de inter¿s para la apertura no puede ser igual o menor que (0)';
        RETURN;
        ELSE
        Pn_openRate:=v_datos_apertura.Tasabruta;
        END IF;


         IF  v_datos_apertura.fecha_apertura IS NULL THEN
                 BEGIN
                 SELECT fecha_hoy
                   INTO v_datos_apertura.fecha_apertura 
                   FROM pa.calendario_b2000
                  WHERE codigo_empresa = v_datos_apertura.cod_empresa AND 
                        codigo_aplicacion = 'BCC';
              EXCEPTION
                 WHEN NO_DATA_FOUND
                 THEN
                     pv_errornumber :=415;
                    pv_errorMessage:='Calendario de CC no definido';
                    RETURN; 
              END;
        END IF;
        IF v_datos_apertura.tipo_interes IS NOT NULL THEN
            IF v_datos_apertura.tipo_interes='C' THEN
                pv_methodPayment:='CAPITALIZABLE';
            ELSIF v_datos_apertura.tipo_interes='N' THEN
                pv_methodPayment:='ACOUNT_CREDIT';
            ELSE
             pv_errornumber :=455;
             pv_errorMessage:='Bad request, Metodo de pago no existe';
             RETURN; 
            END IF;
        END IF;
         IF  v_datos_apertura.fecha_expiracion IS NULL THEN
                     v_datos_apertura.fecha_expiracion:=v_datos_apertura.fecha_apertura+v_datos_apertura.plazo;
        END IF;
        BEGIN
            SELECT base_calculo,porcentaje_renta
            INTO ncalendario,ntasaRetencion
            FROM CD.CD_PRODUCTO_X_EMPRESA
            WHERE cod_empresa='1' AND
            cod_producto=v_datos_apertura.cod_producto;
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
                ntasaRetencion:=10;
                ncalendario:=0;
        END;

       BEGIN
             SELECT SUM(interes_neto),SUM(retencion_itbis)--SUM(MONTO_INTERES)
             INTO pn_interestTotal,pn_taxeAmount
             FROM TABLE(SELECT getAmortizationCd(pn_openingAmount      => v_datos_apertura.monto_apertura,
                                                 pn_baseCalendar       => ncalendario,
                                                 pn_percentTaxe        => NVL(ntasaRetencion,0),
                                                 pn_termInDay          => v_datos_apertura.plazo,
                                                 pv_interestType       => v_datos_apertura.tipo_interes,
                                                 pn_openingRate        => v_datos_apertura.tasabruta,
                                                 pd_openingDate        => v_datos_apertura.fecha_apertura,
                                                 pd_expirationDate     => v_datos_apertura.fecha_expiracion
                                        ) FROM dual);
                                        EXCEPTION
                                        WHEN NO_DATA_FOUND THEN
                                        pv_errornumber      := 453;
                                        pv_errorMessage     := 'Eror en calculo de rendimiento, verificar parametros del producto'||pv_productCode;
                                        WHEN OTHERS THEN
                                        pv_errornumber      := 454;
                                        pv_errorMessage     := 'Eror en calculo de rendimiento, verificar parametros del producto'||pv_productCode;
                                        RETURN;
             END;

             BEGIN
            cd.pkg_cd_digital.OpenCertificateCD(pv_companyId           => v_datos_apertura.cod_empresa,
                                                pn_customerId          => v_datos_apertura.cod_persona,
                                                pv_identicationNumber  => v_datos_apertura.num_id,
                                                pv_identificationType  => v_datos_apertura.cod_tipo_id,
                                                pv_accountNumber        => v_datos_apertura.num_cuenta,
                                                pv_currencyCode        => v_datos_apertura.cod_moneda,
                                                pv_productCode         => v_datos_apertura.cod_producto,
                                                pn_openingAmount       => v_datos_apertura.monto_apertura,
                                                pn_termInDay           => v_datos_apertura.plazo,
                                                pv_rateCode            => v_datos_apertura.cod_tasa_cd,--'CDPF',
                                                pn_openingRate         => v_datos_apertura.tasabruta,
                                                pv_certificateNumber   => pv_numcertificado,
                                                pv_verificationCode    => pv_verificationCode, 
                                                pd_openingDate         => pv_fechaapertura,
                                                pd_expirationDate      => pv_fechavence,
                                                pn_idmovimiento        => pn_transaccionid,
                                                pv_errornumber         => pv_errornumber,
                                                pv_errorMessage        => pv_errorMessage);
            END;
            IF pv_numcertificado IS NOT NULL AND pv_errornumber='200' THEN
             -- Detarmina el Origen PKM para el BGP
                    BEGIN
                         SELECT X.ORIGEN_PKM
                           INTO vOrigenPkm
                           FROM PA.CANAL_APLICACION X
                          WHERE X.COD_SISTEMA = 'CC'
                            AND X.COD_CANAL = vCanal;
                    EXCEPTION WHEN NO_DATA_FOUND THEN
                       vOrigenPkm := 'Onboarding';
                    END;
            BEGIN
                  vdocumento := 'FCSCPF';
                  vidtipodocumento := '618';
                    vurl := pa.pkg_tipo_documento_pkm.urlconozcasucliente2(pcodcliente => v_datos_apertura.cod_persona, pempresa => v_datos_apertura.cod_empresa);
                    pa.pkg_tipo_documento_pkm.inserturlreporte(pcodigoreferencia => pv_numcertificado,
                                                               pfechareporte => SYSDATE,
                                                               pid_aplicacion => vidaplication,
                                                               pidtipodocumento => vidtipodocumento,
                                                               porigenpkm => vorigenpkm,
                                                               purlreporte => vurl,
                                                               pformatodocumento => 'PDF',
                                                               pnombrearchivo => vdocumento || '_' || pv_numcertificado || '_' || v_datos_apertura.cod_persona || '.pdf',
                                                               prespuesta => verror);
                    dbms_output.put_line('FCSCPF vError = ' || verror);

                    -- Generar LEXISNEXIS para File Flow
                    vidtipodocumento := '621';
                    vdocumento := 'LEXISNEXIS';
                    vcodigoreferencia := v_datos_apertura.cod_tipo_id || ':' || v_datos_apertura.num_id || ':' || pv_numcertificado || ': :' || vdocumento;
                    pa.pkg_tipo_documento_pkm.inserturlreporte(pcodigoreferencia => vcodigoreferencia,
                                                               pfechareporte => SYSDATE,
                                                               pid_aplicacion => vidaplication,
                                                               pidtipodocumento => vidtipodocumento,
                                                               porigenpkm => vorigenpkm,
                                                               purlreporte => NULL,
                                                               pformatodocumento => 'PDF',
                                                               pnombrearchivo => vdocumento || '_' || pv_numcertificado || '_' || v_datos_apertura.cod_persona || '.pdf',
                                                               pestado => 'R',
                                                               prespuesta => verror);
                    dbms_output.put_line('LEXISNEXIS vError = ' || verror);

                END;

            END IF;

            pv_openingAmountLetter:=PA.OBTIENE_NUMERO_LETRA(v_datos_apertura.monto_apertura,'ESPA');
            pv_certificateType:='DIGITAL_MONEYMARKET';
            BEGIN
                UPDATE IA.IA_API_LOGS SET
                status_code  = pv_errornumber,
                error_msg    = pv_errorMessage||verror
                WHERE ID_LOG = NSEQUENCELOG;
                COMMIT;
                END;

END;   

 PROCEDURE OpenCertificateCD (pv_companyId           IN VARCHAR2,
                              pn_customerId          IN VARCHAR2,
                              pv_identicationNumber  IN varchar2,
                              pv_identificationType  IN varchar2,
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
                              pv_errorMessage        OUT VARCHAR2)
   IS
      dfechacalcd           DATE := TRUNC (SYSDATE);
      dfechacalcc           DATE := TRUNC (SYSDATE);
      dfechacalcg           DATE := TRUNC (SYSDATE);
      dfechaproxcap         DATE := TRUNC (SYSDATE);
      vcod_productacta      cc.cuenta_efectivo.cod_producto%TYPE;
      vcartera              CD.CD_CARTERA.COD_CARTERA%TYPE;
      vcuentacontable       CD.CD_CARTERA.CUENTA_CONTABLE%TYPE;
      vcodsec_contable      PA.SECTORES_CONTABLES.COD_SEC_CONTABLE%TYPE;
      nSaldoDisponible      CC.CUENTA_EFECTIVO.SAL_TOTAL_CTA%TYPE;
      vnummovtod            CC.MOVIMTO_DIARIO.NUM_MOVTO_D%TYPE;
      vrefautorizacion      VARCHAR2(25):='';
      vnumautorizacion      VARCHAR2(25):='';
      vummovimientofuente   CC.MOVIMTO_DIARIO.NUM_MOV_FUENTE%TYPE;
      vNumAsiento           CG.CG_MOVIMIENTO_RESUMEN.numero_asiento%TYPE;
      vcodAgencia           cc.cuenta_efectivo.cod_agencia%TYPE;
      vtipocambio1          NUMBER;
      vconsecutivo          NUMBER;
      vtipocambio2          NUMBER;
      nMontoDiferencia      NUMBER;
      bvalidar              BOOLEAN:=FALSE;
      nspread_tasa          CD.CD_PRD_TASA_PLAZO_MONTO.SPREAD%TYPE;
      vtitular              pa.personas.nombre%TYPE;
      vcodhast              CD.CD_CERTIFICADO.CODIGO_VERIFICACION%TYPE;
      vcodigotasa           CD.CD_PRD_TASA_PLAZO_MONTO.COD_TASA%TYPE;

      --caracteristicas del producto
         vind_reno_auto      cd.cd_producto_x_empresa.ind_renovacion_auto%TYPE; 
         vfre_revision       cd.cd_producto_x_empresa.fre_revision%TYPE;
         vpla_revision       cd.cd_producto_x_empresa.plazo_revision%TYPE;
         vfre_interes        cd.cd_producto_x_empresa.fre_interes%TYPE;
         vpla_interes        cd.cd_producto_x_empresa.plazo_interes%TYPE;
         vfre_capitaliza     cd.cd_producto_x_empresa.fre_capitaliza%TYPE;
         vforma_calc_interes cd.cd_producto_x_empresa.forma_calculo_interes%TYPE;
         vpla_capitaliza     cd.cd_producto_x_empresa.plazo_capitaliza%TYPE;
         vtip_certificado    cd.cd_producto_x_empresa.forma_calculo_interes%TYPE;
         vtiene_doc_fisico   cd.cd_producto_x_empresa.tiene_doc_fisico%TYPE;
         vporcentaje_renta   cd.cd_producto_x_empresa.porcentaje_renta%TYPE;
         vbase_calculo       cd.cd_producto_x_empresa.base_calculo%TYPE;
         vbase_plazo         cd.cd_producto_x_empresa.base_plazo%TYPE;
         vdia_pago_int       cd.cd_producto_x_empresa.dia_pago_int%TYPE;
         vcod_ejecutivo      pa.empleados.id_empleado%TYPE;
         --Impuesto
         vexc_impuesto      PA.PERSONAS.COBR_NODGII_132011%TYPE;
         nsequence          NUMBER;
         vInd_Digital       VARCHAR2(1):='9';
         vexiste            VARCHAR2(1):='N';
         ntasaBruta         NUMBER; 

  BEGIN        
  BEGIN
   BEGIN
         SELECT fecha_hoy
           INTO dfechacalcc
           FROM pa.calendario_b2000
          WHERE codigo_empresa = pv_companyId AND 
                codigo_aplicacion = 'BCC';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            dfechacalcc := NULL;
            pv_errornumber :='405';
            pv_errorMessage:='Calendario de CC no definido';
            RETURN; 
      END;

      BEGIN
         SELECT fecha_hoy
           INTO dfechacalcd
           FROM pa.calendario_b2000
          WHERE codigo_empresa = pv_companyId AND 
                codigo_aplicacion = 'BCD';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            dfechacalcd := NULL;
            pv_errornumber :='406';
            pv_errorMessage:='Calendario de CD no definido';
            RETURN; 
      END;

      pd_openingDate:=TO_CHAR(dfechacalcd,'dd/mm/yyyy');   
      pd_expirationDate:=TO_CHAR((dfechacalcd+pn_termInDay),'dd/mm/yyyy');
      dfechaproxcap:=TO_DATE(vdiapagocd||'/'||TO_CHAR(dfechacalcd,'mm/yyyy'),'dd/mm/yyyy');
      IF dfechaproxcap<dfechacalcd THEN
      dfechaproxcap:=ADD_MONTHS(dfechaproxcap,1);
      END IF;
       BEGIN
         SELECT fecha_hoy
           INTO dfechacalcg
           FROM pa.calendario_b2000
          WHERE codigo_empresa = pv_companyId AND 
                codigo_aplicacion = 'BCG';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            dfechacalcg := NULL;
            pv_errornumber :='407';
            pv_errorMessage:='Calendario de CD no definido';
            RETURN; 
      END;

     /* IF dfechacalcd<>dfechacalcc THEN
      pv_errornumber :='408';
      pv_errorMessage:='Calendario de CD y CC difieren, no se puede procesar la operacion';
      RETURN; 
      END IF;*/
      /*
      IF dfechacalcd<>dfechacalcg THEN
      pv_errornumber :='408';
      pv_errorMessage:='Calendario de CD y CG difieren, no se puede procesar la operacion';
      RETURN; 
      END IF;
        */
      BEGIN
      SELECT cobr_nodgii_132011, NVL(cli.cod_promotor,cli.cod_oficial)
      INTO vexc_impuesto, vcod_ejecutivo
      FROM pa.personas per, pa.cliente cli
       WHERE per.cod_persona    =   pn_customerId
       AND cli.cod_empresa      =   pv_companyId 
       AND cli.cod_cliente      =   per.cod_persona;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
           vexc_impuesto:=NULL;
           vcod_ejecutivo:=NULL;
           pv_errornumber :='409';
           pv_errorMessage:='No existe una persona registrada con este numero de ID '||pn_customerId;
           RETURN;
      END;


       IF NOT openRateValidate(pv_companyId,
                                   pv_productCode,
                                   pn_termInDay,
                                   pn_openingAmount,
                                   pv_rateCode,
                                   nspread_tasa,
                                   pn_openingRate) 
                                     THEN
                                        pv_errornumber :='409';
                                        pv_errorMessage:='La tasa enviada no concuerda con los parametros del producto';
                                        return;
                                     END IF;

      BEGIN
          SELECT
          ind_renovacion_auto, fre_revision, plazo_revision, 
          fre_interes, plazo_interes,fre_capitaliza, 
          plazo_capitaliza, forma_calculo_interes, NVL(tiene_doc_fisico,'N'), 
          porcentaje_renta, base_calculo,base_plazo, dia_pago_int    
          INTO
          vind_reno_auto, vfre_revision, vpla_revision, vfre_interes,
          vpla_interes, vfre_capitaliza, vpla_capitaliza,
          vtip_certificado, vtiene_doc_fisico, 
          vporcentaje_renta, vbase_calculo, vbase_plazo, vdia_pago_int    
          FROM    cd.cd_producto_x_empresa
          WHERE cod_empresa =   pv_companyId
          AND cod_producto  =   pv_productcode;
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
          vind_reno_auto   :=NULL; 
          vfre_revision    :=NULL;
          vpla_revision    :=NULL;
          vfre_interes     :=NULL;
          vpla_interes     :=NULL;
          vfre_capitaliza  :=NULL;
          vpla_capitaliza  :=NULL;
          vtip_certificado :=NULL;
          vtiene_doc_fisico:=NULL;
          vporcentaje_renta:=NULL;
          vbase_calculo    :=NULL;
          vbase_plazo      :=NULL;
          vdia_pago_int    :=NULL;
          pv_errornumber :='429';
          pv_errorMessage:='El Producto no ha sido creado en el core';
          RETURN;
          END;
       ntasaBruta:=pn_openingRate-(pn_openingRate*(vporcentaje_renta/100));
      BEGIN
      SELECT cef.sal_total_cta-ppr.sal_min_cta_alt,cef.cod_producto,cef.cod_agencia
      INTO nSaldoDisponible,vcod_productacta,vcodAgencia
      FROM cc.cuenta_efectivo cef, cc.cara_x_producto ppr
      WHERE cef.cod_empresa     =   pv_companyId        AND 
            cef.num_cuenta      =   pv_accountNumber    AND 
            cef.cod_cliente     =   pn_customerId       AND
            ppr.cod_empresa     =   cef.cod_empresa     AND
            ppr.cod_producto    =  cef.cod_producto;
            EXCEPTION
      WHEN NO_DATA_FOUND
         THEN
            nSaldoDisponible:= 0;
            vcodAgencia:=NULL;
            vcod_productacta:=NULL;
            pv_errornumber :='409';
            pv_errorMessage:='La cuenta de efectivo no existe o no pertence al solicitante';
            RETURN; 
      END;
      IF nSaldoDisponible<=pn_openingAmount THEN
        pv_errornumber :='410';
        pv_errorMessage:='La cuenta de efectivo refleja un saldo insuficiente para realizar esta operacion';
        RETURN;
      END IF;

      BEGIN
          SELECT cod_sec_contable,nombre
          INTO vcodsec_contable,vtitular
          FROM pa.personas
          WHERE cod_persona=pn_customerId;
          EXCEPTION
          WHEN no_data_found THEN
          vcodsec_contable:='';
          vtitular:='';
          pv_errornumber :='411';
          pv_errorMessage:='El codigo de cliente enviado no tiene asignado un sector contable';
          RETURN;
      END;


      BEGIN
          SELECT pro.cod_cartera,car.cuenta_contable
          INTO vcartera,vcuentacontable
          FROM cd.cd_cartera car, cd.cd_producto_x_empresa pro
          WHERE codigo_empresa          =   pv_companyId             AND
          (pn_termInDay BETWEEN plazo_inicio AND plazo_fin       )   AND
          clasificacion                 =   'N'                      AND
          vencido                       =   'N'                      AND
          cod_sec_contable              =   vcodsec_contable         AND
          forma_pago_int                =   DECODE(pro.forma_calculo_interes,'CU','N','CV','C','C') AND
          pro.cod_empresa               =   car.codigo_empresa       AND
          pro.cod_producto              =   pv_productCode           AND
          car.cod_cartera               =   pro.cod_cartera;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
       pv_errornumber :='412';
       pv_errorMessage:='No existe la cartera, ni los parametros contable para este producto con los terminos solitados';
       RETURN; 
      END; 
      cc.ccmov.agrega_movimiento (pv_companyId,
                                  vcodAgencia,
                                 'CC',
                                  pv_accountNumber,
                                  vcod_productacta,
                                  vtiptransac,
                                  vsubtiptransac,
                                  USER,
                                  dfechacalcc,
                                  vummovimientofuente,
                                  pn_openingAmount,
                                  'APERTURA DE CERTIFICADO DIGITAL',
                                  'CD',
                                  NULL,
                                  'N',
                                  vnummovtod,
                                  vrefautorizacion,
                                  vnumautorizacion);
    IF NVL(vnummovtod,0)= 0 THEN
         pv_errornumber :='413';
        pv_errorMessage:='El monto de apertura no pudo ser debitado de la cuenta de efectivo especificada';
       RETURN; 
    END IF;
      dbms_output.put_line('mov. cuenta'||vnummovtod);
      BEGIN
      aplica_contabilidad(pv_companyId,
                          vcodAgencia,
                          vnummovtod,
                          vtiptransac,
                          'S',
                          vnumasiento,
                          pv_errornumber, 
                          pv_errorMessage,
                          'APERTURA DE CERTIFICADO DIGITAL',
                          vrefautorizacion);
      END;
      IF pv_errornumber IS NOT NULL OR pv_errorMessage IS NOT NULL THEN
            ROLLBACK;
      END IF;


      IF NVL(vnummovtod,0)= 0 THEN
         pv_errornumber :='414';
         pv_errorMessage:='Falla en el proceso de aplicacion del movimiento y generacion del asiento contable';
       RETURN; 
    END IF;
    BEGIN
    cg_utl.lineas_del_asiento(pv_companyId,
                              vcodAgencia,
                              'BCD',
                              pv_productCode,
                              vtiptransac,
                              vsubtiptransac,
                              vnummovtod,
                              'Apertura de Certificado Digital',
                              dfechacalcc,
                              dfechacalcc,
                              dfechacalcc,
                              vnumasiento, --nNumAsiento,
                              vcuentacontable,
                              vcodAgencia,
                              pn_openingAmount,
                              'N', --'S',
                              'C',
                              'S',
                              vtipocambio1,
                              vtipocambio2,
                              USER,
                              pv_errorMessage,
                              vrefautorizacion);
    END;
                dbms_output.put_line($$plsql_line || ' MENSAJE: ' || pv_errorMessage);

            IF (pv_errorMessage IS NOT NULL) THEN
                ROLLBACK;
                RETURN;
            END IF;
        IF NVL(vnumasiento,0) > 0 THEN
            ---Actualizar el movimiento contable en 'P'
            cg_utl.Cuadre_Asiento(pv_companyId,
                                  dfechacalcc,
                                  vnumasiento,
                                  nMontoDiferencia,
                                  pv_errorMessage);
        END IF;

        IF nMontoDiferencia=0 THEN
                BEGIN
                UPDATE cc.movimto_diario
                SET estado_movimto  =   'C', 
                    num_asiento     =   vnumasiento
                WHERE cod_empresa   =   pv_companyId    AND
                      num_movto_d    =   vnummovtod     AND
                      estado_movimto  =   'N';
                END;
                BEGIN
                UPDATE cc.cuenta_efectivo
                SET sal_total_cta   =   sal_total_Cta-nvl(pn_openingAmount,0)
                WHERE cod_empresa   =   pv_companyId  AND
                      num_cuenta    =   pv_accountNumber;
                END;
                nsequence:=getCertificateNumber(pv_companyId, 
                                                vcodAgencia,
                                                pv_currencyCode,
                                                pv_errornumber, 
                                                pv_errorMessage);
                 IF nsequence IS  NULL THEN
                 ROLLBACK;
                 RETURN;
                 END IF;

                pv_certificateNumber:=RPAD (LPAD (vcodagencia, 2, '0'), 5, '0') || pv_currencyCode || LPAD (nsequence, 9, '0');
                BEGIN
                SELECT 'S'
                    INTO vexiste
                    FROM CD.CD_CERTIFICADO
                    WHERE COD_EMPRESA=pv_companyId AND
                    NUM_CERTIFICADO=pv_certificateNumber;
                    EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                    vexiste:='N';
                END;

              IF vexiste='S' THEN
              LOOP  
                nsequence:=getCertificateNumber(pv_companyId, 
                                                vcodAgencia,
                                                pv_currencyCode,
                                                pv_errornumber, 
                                                pv_errorMessage);
                 IF nsequence IS  NULL THEN
                    ROLLBACK;
                    RETURN;
                    ELSE
                    pv_certificateNumber:=RPAD (LPAD (vcodagencia, 2, '0'), 5, '0') || pv_currencyCode || LPAD (nsequence, 9, '0');
                 END IF;
                 BEGIN
                SELECT 'S'
                    INTO vexiste
                    FROM CD.CD_CERTIFICADO
                    WHERE COD_EMPRESA=pv_companyId AND
                    NUM_CERTIFICADO=pv_certificateNumber;
                    EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                    vexiste:='N';
                END;
                EXIT WHEN vexiste='S';
              END LOOP;
              END IF;

              IF pv_certificateNumber IS NULL THEN
                pv_errornumber:='425'; 
                pv_errorMessage:='No se pudo generar un numero de certificado, con estos parametros';
                ROLLBACK;
                RETURN;
              END IF;
              BEGIN
              pv_verificationCode:=get_codigo_hast( pv_certificateNumber,
                                                    pv_identicationNumber,
                                                    vtitular,
                                                    pv_errornumber,
                                                    pv_errorMessage);

              END;
              IF pv_errornumber IS NOT NULL THEN
              pv_errornumber:=455;
              pv_errorMessage:='Error, No se pudo generar el codigo HASH';
              END IF;
      BEGIN
          INSERT INTO cd.cd_certificado
          (cod_empresa,num_certificado,cod_agencia,cod_cartera,--4
          cod_producto,cliente,cod_serie,consecutivo,cuenta_contable,cod_tasa,adicionado_por,--7
          clasificacion,clasificado,con_impresion,cre_interes,cre_mes,deb_interes,dia_congelamiento,--7
          estado,exc_impuesto,fec_adicion,fec_emision,ind_beneficiario_cd,ind_beneficiario_cu,--6       
          lug_captacion,monto,pla_dias,pla_meses,spread_cd,tas_bruta,tas_neta,tip_plazo,--8
          titular,utilizado,ind_reno_auto,num_macrotitulo,fec_entrega,fec_modificacion,--6
          fec_calc_interes,fec_pago,fec_pag_antici,fec_ult_calculo,fec_ult_revision,--5
          fec_prox_cap,fec_prox_revi,fec_vencimiento,modificado_por,comentario,--5
          mon_interes_pagado,num_serie,fre_revision,pla_revision,fre_interes,pla_interes,--6
          fre_capitaliza,pla_capitaliza,cod_empresa_op,cod_agencia_op,cod_producto_op,--5
          mon_int_x_pagar,mon_int_x_pagar_bruto,mon_acum_int_cap,mon_acum_int_cal,--4
          mon_int_reconocidos,tip_certificado,cod_moneda,fec_ult_cap,--4               
          mon_acum_int_cap_bruto,mon_acum_int_cal_bruto,mon_retenido,--3
          monto_original,mon_int_proyectado,mon_int_proyectado_bruto,--3  
          tiene_doc_fisico,numero_asiento_contable,numero_solicitud_cajas, --3   
          forma_pago_intereses,mon_int_ganado,mon_int_reconocidos_bruto, --3
          num_cuenta,porcentaje_renta,base_calculo,base_plazo,--4
          operacion,nuevo_certificado,dia_pago_int,fec_ult_renov,num_veces_renovado,   --5     
          unificar_cd,monto_cheques,dias_efectivo,dias_cheques,dias_ajuste,--5
          mon_efectivo,cod_ejecutivo,codigo_verificacion,firma_aut1,firma_aut2, --5               
          no_doc_origen,int_cap_no_saldo,autoriza_anu1,      --3       
          autoriza_anu2,procesar,numero_asiento,num_preimpreso,fec_prox_pag,codigo_promotor--6           
          )
          VALUES (pv_companyId,pv_certificateNumber,vcodAgencia,vcartera,--4
                  pv_productCode,pn_customerId,NULL,NULL,vcuentacontable,pv_rateCode,USER,--7
                  'N','N',1,0,0,0,0--7
                  ,'A',vexc_impuesto,SYSDATE,dfechacalcd,'P','P',--6
                  'BE',pn_openingAmount,pn_termInDay,0,nspread_tasa,pn_openingRate,ntasaBruta,'D',--8
                  vtitular,'N',vind_reno_auto,NULL,NULL,NULL,--6
                  dfechacalcd,NULL,NULL,NULL,NULL,--5
                  dfechaproxcap,NULL,(dfechacalcd+pn_termInDay),NULL,'APERTURA DE CERTIFICADO DIGITAL POR CANAL ELECTRONICO',--5
                  0,NULL,vfre_revision,vpla_revision,vfre_interes,nvl(vpla_interes,30),--6
                  nvl(vfre_capitaliza,'D'),nvl(vpla_capitaliza,'30'),pv_companyId,vcodAgencia,pv_productCode,--5
                  0,0,0,0,--4
                  0,vtip_certificado,pv_currencyCode,NULL,--4
                  0,0,0,--3
                  pn_openingAmount,0,0,--3
                  vtiene_doc_fisico,vnumasiento,NULL,--3
                  DECODE(vtip_certificado,'CU','CE',NULL),0,0,--3
                  pv_accountNumber,vporcentaje_renta,vbase_calculo,vbase_plazo,--4
                  NULL,NULL,vdiapagocd,NULL,0,--5
                  'N',0,0,0,0,--5
                  0,vcod_ejecutivo,pv_verificationCode,NULL,NULL,--5
                  NULL,0,NULL,--3
                  NULL,NULL,vnumasiento,NULL,dfechaproxcap,vcod_ejecutivo);--6;*/

           EXCEPTION WHEN OTHERS THEN
           dbms_output.put_line('Error'||SQLERRM);
           pv_certificateNumber :=NULL;
           pv_verificationCode  :=NULL;
           pd_openingDate       :=NULL;
           pd_expirationDate    :=NULL;
           pv_errornumber       :=426;
           pv_errorMessage:='No se puede registar el certificado digital con estas condiciones - '||SQLERRM;
           ROLLBACK;
           RETURN; 
           END;
           IF pv_certificateNumber IS NOT NULL THEN
           INSERT INTO PA.CUENTA_CLIENTE_RELACION
           ( NUM_CUENTA     ,
             CODIGO_CLIENTE ,
             TIPO_RELACION , 
             PRINCIPAL     , 
             COD_SISTEMA  ,  
             ESTADO       ,  
             NUMERO_LINEA  )
           VALUES(pv_certificateNumber,pn_customerId,'','S','CD','A',1);
           END IF;
      BEGIN
       SELECT seq_movimientos.NEXTVAL INTO vconsecutivo FROM dual;
       INSERT INTO cd.cd_movimiento (cod_empresa,
                                  num_certificado,
                                  consecutivo,
                                  cod_sistema,
                                  tip_transaccion,
                                  subtip_transac,
                                  numero_cupon,
                                  descripcion,
                                  detalle_actual,
                                  fecha_movimiento,
                                  detalle_anterior,
                                  adicionado_por,
                                  fecha_adicion,
                                  numero_asiento_pago,
                                  valor_mvto,
                                  cod_producto,
                                  cod_agencia,
                                  tip_certificado,
                                  cod_moneda,
                                  estado,
                                  monto,
                                  cre_interes,
                                  cre_mes,
                                  tas_bruta,
                                  tas_neta,
                                  mon_int_x_pagar,
                                  mon_acum_int_cap,
                                  mon_interes_pagado,
                                  mon_int_ganado,
                                  porcentaje_renta,
                                  base_calculo,
                                  mon_descuento,
                                  cod_tasa,
                                  base_plazo,
                                  comentario
                                  )
            VALUES (pv_companyId,
                    pv_certificateNumber,
                    vconsecutivo,
                    'CD',
                    '1',
                    '1',
                    1,
                    'Apertura de Certificado Digital',
                    TO_CHAR(pn_openingAmount,'9,999,999,999.99'),
                    dfechacalcd,
                    TO_CHAR(pn_openingAmount,'9,999,999,999.99'),
                    USER,
                    -- p_cierre.dfechacal);
                    SYSDATE,
                    vnumasiento,
                    pn_openingAmount,
                    pv_productCode,
                    vcodagencia,
                    vtip_certificado,
                    pv_currencyCode,
                    'A',
                    pn_openingAmount,
                    0,
                    0,
                    pn_openingRate,
                    ntasaBruta,
                    0,
                    0,
                    0,
                    0,
                    vporcentaje_renta,
                    '360',
                    0,
                    pv_rateCode,
                    NULL,
                    'Api apertura Certificado Digital'
                    );      
        EXCEPTION
         WHEN OTHERS
         THEN
                    p_cierre.ERROR ('CFDIGITAL_8-5-' || pv_certificateNumber);
                     pv_errorMessage:= '000450- CD'|| SQLCODE;
        END;     
           COMMIT;
           pv_errornumber :=200;
           pv_errorMessage:='Ok';
           pn_idmovimiento:=vnummovtod;

    END IF;
  END;

   END;
PROCEDURE aplica_contabilidad(pcodempresa    IN     VARCHAR2,
                              pcodagencia    IN     VARCHAR2,
                              pnummovim      IN     NUMBER,
                              ptiptrans      IN     NUMBER,
                              pgencaratula   IN     VARCHAR2,
                              pnumasiento    IN OUT NUMBER,
                              perrorNun      IN OUT VARCHAR2, 
                              pmensaje       IN OUT VARCHAR2,
                              descrip        IN     VARCHAR2,
                              preferencia    IN     VARCHAR2 DEFAULT '') IS
        --nNumAsiento     NUMBER;
        mensajeerror        VARCHAR2(250);
        vtipocambio1        NUMBER(12, 4) := NULL;
        vtipocambio2        NUMBER(12, 4) := NULL;
        vctaprincipal       VARCHAR2(25);
        corigen             VARCHAR2(1);
        dfechacalcg         DATe;
        vexiste             VARCHAR2(1):='';
    BEGIN
    dbms_output.put_line('mov en aplica conta '||pnummovim);
        BEGIN
         SELECT 'S'
         INTO vexiste 
         FROM movimto_diario a
            WHERE a.cod_empresa     = pcodempresa
            AND   a.num_movto_d     = pnummovim
            AND   a.estado_movimto  = 'N';
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
            vexiste:='N';
            perrorNun:='412';
            pmensaje:='No se ha creado un movimiento a la cuenta seleccionada';
            RETURN;
        END;
        IF vexiste='N' THEN
        dbms_output.put_line('movimiento no existe en cc.movimto_diario');
        ELSE
        dbms_output.put_line('movimiento  existe en cc.movimto_diario');
        END IF;
     BEGIN
         SELECT fecha_hoy
           INTO dfechacalcg
           FROM pa.calendario_b2000
          WHERE codigo_empresa = pcodempresa AND 
                codigo_aplicacion = 'BCC';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            dfechacalcg := NULL;
            perrorNun:='413';
            pmensaje:='Calendario de CC no definido';
            RETURN; 
      END;

        BEGIN
            SELECT tip_movimiento
            INTO corigen
            FROM cat_tip_transac
            WHERE cod_sistema = 'CC'
            AND   tip_transaccion = ptiptrans;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                corigen := NULL;
                perrorNun:='414';
                pmensaje:='El tipo de transacci n no tiene un origen parametrizado';
                RETURN;
        END;

        IF aplica_contable(ptiptrans)
           OR corigen IS NOT NULL THEN
            dbms_output.put_line('valor de aplica_contable es true');
            --open cur_movimto;
            FOR c1 IN (
            SELECT a.cod_empresa,
                   a.mon_movimiento,
                   a.tip_transaccion,
                   a.subtip_transacc,
                   a.descripcion,
                   a.estado_movimto,
                   a.cod_producto,
                   a.num_movto_d,
                   a.fec_movimiento,
                   a.cod_usuario,
                   a.num_cuenta,
                   a.cod_agencia cod_agencia_pro,
                   b.cod_cliente
                   FROM movimto_diario a, cc.cuenta_efectivo b
            WHERE a.cod_empresa     =   pcodempresa
            AND   a.num_movto_d     =   pnummovim
            AND   a.estado_movimto  =   'N'
            AND   b.num_cuenta      =   a.num_cuenta)

            LOOP

                IF NVL(pgencaratula, 'N') = 'S' THEN
                    cg_utl.caratula_del_asiento(c1.cod_empresa,
                            c1.cod_agencia_pro,
                            'BCC',
                            c1.cod_producto,
                            c1.tip_transaccion,
                            c1.subtip_transacc,  
                            c1.num_movto_d,
                            c1.descripcion,
                            c1.fec_movimiento,
                            c1.fec_movimiento,
                            pnumasiento, -- nNumAsiento,
                            USER,
                            mensajeerror);
dbms_output.put_line('asiento'||pnumasiento||' ,error caratura'||mensajeerror);
                    IF (mensajeerror IS NOT NULL) THEN
                        perrorNun:='415';
                        pmensaje := mensajeerror;
                        RETURN;
                    END IF;
                END IF;


                cg_utl.cuenta_contable_sector(empresa => pcodempresa,
                                              aplicacion => 'BCC',
                                              subaplicacion => c1.cod_producto,
                                              nconcepto => 'PRINCIPAL',
                                              cliente => c1.cod_cliente,
                                              ctactable => vctaprincipal,
                                              mensajeerr => mensajeerror);


                IF (mensajeerror IS NOT NULL) THEN
                    perrorNun:='416';
                    pmensaje := mensajeerror;
                    RETURN;
                END IF;


                cg_utl.lineas_del_asiento(TO_NUMBER(pcodempresa),
                                          TO_NUMBER(c1.cod_agencia_pro),
                                          'BCC',
                                          TO_NUMBER(c1.cod_producto),
                                          c1.tip_transaccion,
                                          TO_NUMBER(c1.subtip_transacc),
                                          pnummovim, -- '0',
                                          descrip,
                                          dfechacalcg,
                                          dfechacalcg,
                                          c1.fec_movimiento,
                                          pnumasiento, --nNumAsiento,
                                          vctaprincipal,
                                          TO_NUMBER(c1.cod_agencia_pro),
                                          c1.mon_movimiento,
                                          'N', --'S',
                                          corigen,
                                          'S',
                                          vtipocambio1,
                                          vtipocambio2,
                                          USER,
                                          mensajeerror,
                                          preferencia);

                dbms_output.put_line($$plsql_line || ' MENSAJE: ' || mensajeerror);

                IF (mensajeerror IS NOT NULL) THEN
                    perrorNun:='417';
                    pmensaje := mensajeerror;
                    RETURN;
                END IF;
            END LOOP;
            --close cur_movimto;
            dbms_output.put_line('valor de  NUMERO ASIENTO para Acredita ' || pnumasiento);
        END IF;
    END APLICA_CONTABILIDAD;
 FUNCTION aplica_contable(ptiptransaccion in number)
        RETURN BOOLEAN IS
        vtemp varchar2(1);
    BEGIN
        SELECT aplica_conta
        INTO vtemp
        FROM tip_transacciones
        WHERE (cod_empresa = p_cierre.ccodempresa)
        AND   (cod_sistema = 'CC')
        AND   (tip_transaccion = ptiptransaccion);

        IF (vtemp = 'S') THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END APLICA_CONTABLE;

 FUNCTION openRateValidate(Pn_Empresa        IN  NUMBER,
                           pv_codproducto    IN  VARCHAR2,
                           pn_plazo          IN  NUMBER,
                           pn_monto          IN  NUMBER,
                           pv_rateCode       IN  VARCHAR2,
                           pn_spread         OUT NUMBER,
                           pn_tasa           IN  NUMBER) RETURN BOOLEAN
                              IS 
ntasaMinima     NUMBER;
ntasaMaxima     NUMBER;       

BEGIN
 BEGIN
   SELECT
    CASE WHEN operacion='+' THEN  pla.tasa_minima ELSE  pla.tasa_minima END minimunrate,
    CASE WHEN operacion='+' THEN tasa_maxima ELSE tasa_maxima END maximunrate,PLA.SPREAD
    INTO  ntasaminima, ntasamaxima,pn_spread
    FROM cd.cd_prd_tasa_plazo_monto pla, cd.cd_producto_x_empresa pro
    WHERE pla.cod_empresa       =   pn_empresa          AND
          pla.cod_producto      =   pv_codproducto      AND
          pn_plazo BETWEEN pla.plazo_minimo             AND   PLA.PLAZO_MAXIMO    AND
          pn_monto BETWEEN  pla.monto_minimo            AND   pla.monto_maximo    AND
          pla.cod_producto      =   pro.cod_producto    AND 
          pla.cod_tasa          =   pv_rateCode         AND
          pla.estado            =  'A'                  AND
          pla.cod_producto IN (SELECT REGEXP_SUBSTR((SELECT PA.PARAM.PARAMETRO_X_EMPRESA('1', 'CD_CERT_DIGITAL', 'CD') FROM DUAL), '[^,]+', 1, LEVEL) AS DATA
                             FROM DUAL
                             CONNECT BY REGEXP_SUBSTR((SELECT PA.PARAM.PARAMETRO_X_EMPRESA('1', 'CD_CERT_DIGITAL', 'CD') FROM DUAL), '[^,]+', 1, LEVEL) IS NOT NULL)
                             AND pla.fecha_vigencia IN (SELECT MAX(fecha_vigencia) 
                                                         FROM  cd.cd_prd_tasa_plazo_monto 
                                                            WHERE cod_producto =   pla.cod_producto    AND 
                                                                  cod_tasa     =   pla.cod_tasa        AND 
                                                                  plazo_minimo =   pla.plazo_minimo    AND 
                                                                  monto_minimo =   pla.monto_minimo    AND
                                                                  cod_tasa     =   pla.cod_tasa        AND 
                                                                  estado       =   pla.estado);
                                                                  EXCEPTION
                                                                  WHEN NO_DATA_FOUND THEN
                                                                  ntasaminima:=0;
                                                                  ntasamaxima:=0;
                                                                  pn_spread:=0;
 END;
     IF pn_tasa>= ntasaminima and pn_tasa<= ntasamaxima then
        RETURN TRUE;
     ELSE 
        RETURN FALSE;
     END IF;
 END;

PROCEDURE getInfoCancellationcd(pv_companyId             IN NUMBER,
                               pn_customerId             IN NUMBER,
                               pv_identificationNumber   IN VARCHAR2,
                               pv_identificationType     IN VARCHAR2,
                               pv_certificateNumber      IN VARCHAR2,
                               pv_currencyCode           IN VARCHAR2,
                               pn_acountNumber           IN NUMBER,
                               pv_cancellationType       OUT VARCHAR2,
                               pn_cancellationAmount     OUT NUMBER,
                               pn_penalAmount            OUT NUMBER,
                               pn_creditAcount           OUT NUMBER,
                               pn_errornumber            OUT NUMBER,
                               pv_errorMessage           OUT VARCHAR2)                

                            IS
ves_penable         VARCHAR2(1):='';
vpenalidad_renov    VARCHAR2(1):='';
vcalcula_penalidad  VARCHAR2(1):='';
nbase_calculo       NUMBER;
vtip_certificado    VARCHAR2(3):='';
ninteresmes         NUMBER;
ninteresAcum        NUMBER;
ninteresGanado      NUMBER;
nporcentajeRenta    NUMBER;
ninteresnetoGanado  NUMBER;
ntasaBruta          NUMBER;
ntasaNeta           NUMBER;
dfechaEmision       DATE;
dfechacalcd         DATE;
dfechaUltcap        DATE;
dfechaUltRenov      DATE;
dfechaVence         DATE;
ndiasGracias        NUMBER:=PARAM.PARAMETRO_X_EMPRESA(pv_companyId,'DIAS_GRACIAS_DIGITAL','CD');
vcodagencia         pa.agencia.cod_agencia%TYPE;
nmonto_pagar        NUMBER;
vcodproducto        VARCHAR2(3):='';
nmonto_apertura     NUMBER;
ndiasaVencer        NUMBER;
nmonto_penalidad    NUMBER;
nmonto_total        NUMBER;

BEGIN
pv_cancellationType     :='N';
pn_cancellationAmount   :=0;
pn_penalAmount          :=0;
pn_creditAcount         :=NULL;
 BEGIN
         SELECT fecha_hoy
           INTO dfechacalcd
           FROM pa.calendario_b2000
          WHERE codigo_empresa = pv_companyId AND 
                codigo_aplicacion = 'BCD';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            dfechacalcd := NULL;
            pn_errornumber :=405;
            pv_errorMessage:='Calendario de CC no definido';
            RETURN; 
      END;
    BEGIN
    SELECT DECODE(t2.ind_redencion_ant,'S','N','S'),
                NVL(t2.ind_penalidad_renov,'N'),
                NVL(t2.ind_calcula_penalidad,'N'),
                t1.base_calculo, forma_calculo_interes,
                t1.cre_mes, t1.mon_acum_int_cap,
                t1.porcentaje_renta, t1.fec_emision,
                NVL(t1.fec_ult_renov,t1.fec_vencimiento),t1.cod_producto,
                t1.monto,t1.fec_ult_cap,DECODE(T1.TIP_CERTIFICADO,'CU',t1.num_cuenta,pn_acountNumber)
    INTO ves_penable, vpenalidad_renov, vcalcula_penalidad, nbase_calculo,vtip_certificado, 
     ninteresmes, nInteresAcum,nporcentajeRenta, dfechaEmision,dfechaUltRenov, vcodproducto, 
     nmonto_apertura,dfechaUltcap, pn_creditAcount
    FROM cd.cd_certificado t1 , cd.cd_producto_x_empresa t2
    WHERE t1.cod_empresa    =   pv_companyid
    AND t1.num_certificado  =   pv_certificateNumber
    AND T1.ESTADO       =   'A'
    AND t2.cod_empresa  =   t1.cod_empresa AND
        t2.cod_producto =   t1.cod_producto
    AND t1.cod_producto IN (SELECT REGEXP_SUBSTR((SELECT PA.PARAM.PARAMETRO_X_EMPRESA('1', 'CD_CERT_DIGITAL', 'CD') FROM DUAL), '[^,]+', 1, LEVEL) AS DATA
                             FROM DUAL
                             CONNECT BY REGEXP_SUBSTR((SELECT PA.PARAM.PARAMETRO_X_EMPRESA('1', 'CD_CERT_DIGITAL', 'CD') FROM DUAL), '[^,]+', 1, LEVEL) IS NOT NULL);
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
    ves_penable:='N';
    dfechaUltRenov:=NULL;
    nbase_calculo:=0;
    dfechaUltcap:=NULL;
    nmonto_apertura:=0;
    nporcentajeRenta:=0;
    vcodproducto:=NULL;
    ninteresmes:=0; 
    nInteresAcum:=0;
    pn_errorNumber:=415; 
    pv_errorMessage:='No existe un n mero de certificado digital registrado con numero de certificado '||pv_certificateNumber;
    RETURN;
    END;

    IF (ves_penable = 'S') Then
        BEGIN
              IF (vtip_certificado = 'CU') Then -- Si es pagadero (Con Cupones)

                    ninteresGanado := ROUND (NVL (ninteresAcum, 0.00) + NVL(ninteresmes, 0.00), 2);
                    ninteresNetoGanado := ROUND (NVL (ninteresmes, 0.00), 2) -(ROUND (ROUND(NVL (ninteresmes, 0.00), 2) * (nporcentajeRenta/100), 2));
                     nmonto_total:=nvl(nmonto_apertura,0)+ nvl(ninteresNetoGanado,0);
                         BEGIN
                            pv_cancellationType     :='A';
                            pn_cancellationAmount   :=nmonto_total;
                            pn_penalAmount          :=0;
                            pn_creditAcount         :=pn_acountNumber;
                         END;    
              ELSIF (vtip_certificado IN ('CV', 'CF')) THEN    --si es capitalizable -- Capitalizable Tasa Variable / Tasa Fija

                 ninteresGanado := ROUND (NVL (ninteresAcum, 0.00) + nvl (ninteresMes, 0.00), 2);   
                 ninteresnetoGanado := (ROUND (NVL (ninteresMes, 0.00), 2)
                                  - ROUND (ROUND (NVL (ninteresMes, 0.00), 2) * nporcentajeRenta, 2));
                nmonto_total:=nvl(nmonto_apertura,0) + nvl (ninteresAcum, 0.00) + nvl(ninteresnetoGanado,0);
                NULL;
              END IF; 
      --
           IF ((dfechacalcd - dfechaUltRenov) < 7)
                 AND (dfechacalcd > dfechaUltRenov)  THEN 
                 IF (pa.calendar.dias_habiles_entre_fechas (pv_companyId,
                                                            vcodagencia,
                                                            dfechaUltRenov,
                                                            dfechacalcd) <= ndiasGracias)
             THEN

            pv_cancellationType:='V';
            ELSE
            pv_cancellationType:='A';
             END IF;
           END IF;

           IF (pv_cancellationType = 'A')
           THEN

              -- EBlanco: 09-06-2014: Se movio para que al momento de llamar la funcion ya tena calculado los dias por vencer.
              ndiasavencer:=dfechavence-dfechacalcd;
              nmonto_penalidad:=calcula_penalidad(p_empresa        =>    pv_companyId, 
                                                     p_certificado    =>    pv_certificateNumber, 
                                                     pcod_producto    =>    vcodproducto,
                                                     p_monto          =>    nmonto_total,
                                                     pfecha_cal       =>    dfechacalcd,
                                                     p_fecha_emision  =>    dfechaEmision,
                                                     p_fecha_ult_cap  =>    dfechaUltcap,
                                                     p_fecha_ult_ren  =>    dfechaUltRenov,
                                                     p_fecha_vence    =>    dfechaVence,
                                                     p_dias_pendiente =>    ndiasaVencer);
                 pn_penalAmount:= nmonto_penalidad;

              END IF;
              pn_penalAmount:=nmonto_penalidad;
              pn_cancellationAmount := ROUND (NVL (nmonto_total, 0.00), 2)-NVL(nmonto_penalidad,0);  
        END;
       ELSE

        pn_penalAmount:=nmonto_penalidad;
        pn_cancellationAmount := ROUND (NVL (nmonto_total, 0.00), 2);
   END IF;
    pn_errorNumber:=200; 
    pv_errorMessage:='Ok';
END;
PROCEDURE  CancellationCertificate(pv_companyId             IN  NUMBER,
                                   pn_customerId            IN  NUMBER,
                                   pv_identificationNumber  IN  VARCHAR2,
                                   pv_identificationType    IN  VARCHAR2,
                                   pv_certificateNumber     IN  VARCHAR2,
                                   pv_currencyCode          IN  VARCHAR2,
                                   pn_acountNumber          IN  NUMBER,
                                   pv_cancellationType      OUT VARCHAR2,
                                   pn_cancellationAmount    OUT NUMBER,
                                   pn_penalAmount           OUT NUMBER,
                                   pn_creditAcount          OUT NUMBER,
                                   pn_errornumber           OUT NUMBER,
                                   pv_errorMessage          OUT VARCHAR2)                

                            IS
ves_penable         VARCHAR2(1):='';
vpenalidad_renov    VARCHAR2(1):='';
vcalcula_penalidad  VARCHAR2(1):='';
nbase_calculo       NUMBER;
vtip_certificado    VARCHAR2(3):='';
ninteresmes         NUMBER;
ninteresAcum        NUMBER;
ninteresGanado      NUMBER;
nporcentajeRenta    NUMBER;
ninteresnetoGanado  NUMBER;
ntasaBruta          NUMBER;
ntasaNeta           NUMBER;
dfechaEmision       DATE;
dfechacalcd         DATE;
dfechaUltcap        DATE;
dfechaUltRenov      DATE;
dfechaVence         DATE;
ndiasGracias        NUMBER:=PARAM.PARAMETRO_X_EMPRESA(pv_companyId,'DIAS_GRACIAS_DIGITAL','CD');
vcodagencia         pa.agencia.cod_agencia%TYPE;
nmonto_pagar        NUMBER;
vcodproducto        VARCHAR2(3):='';
nmonto_apertura     NUMBER;
ndiasaVencer        NUMBER;
nmonto_penalidad    NUMBER;
nmonto_total        NUMBER;

BEGIN
pv_cancellationType     :='N';
pn_cancellationAmount   :=0;
pn_penalAmount          :=0;
pn_creditAcount         :=NULL;
 BEGIN
         SELECT fecha_hoy
           INTO dfechacalcd
           FROM pa.calendario_b2000
          WHERE codigo_empresa = pv_companyId AND 
                codigo_aplicacion = 'BCD';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            dfechacalcd := NULL;
            pn_errornumber :=405;
            pv_errorMessage:='Calendario de CC no definido';
            RETURN; 
      END;
    BEGIN
    SELECT DECODE(t2.ind_redencion_ant,'S','N','S'),
                NVL(t2.ind_penalidad_renov,'N'),
                NVL(t2.ind_calcula_penalidad,'N'),
                t1.base_calculo, forma_calculo_interes,
                t1.cre_mes, t1.mon_acum_int_cap,
                t1.porcentaje_renta, t1.fec_emision,
                t1.fec_ult_renov,t1.cod_producto,
                t1.monto,t1.fec_ult_cap,DECODE(T1.TIP_CERTIFICADO,'CU',t1.num_cuenta,pn_acountNumber)
    INTO ves_penable, vpenalidad_renov, vcalcula_penalidad, nbase_calculo,vtip_certificado, 
     ninteresmes, nInteresAcum,nporcentajeRenta, dfechaEmision,dfechaUltRenov, vcodproducto, 
     nmonto_apertura,dfechaUltcap, pn_creditAcount
    FROM cd.cd_certificado t1 , cd.cd_producto_x_empresa t2
    WHERE t1.cod_empresa    =   pv_companyid
    AND t1.num_certificado  =   pv_certificateNumber
    AND T1.ESTADO       =   'A'
    AND t2.cod_empresa  =   t1.cod_empresa AND
        t2.cod_producto =   t1.cod_producto
    AND t1.cod_producto IN (SELECT REGEXP_SUBSTR((SELECT PA.PARAM.PARAMETRO_X_EMPRESA('1', 'CD_CERT_DIGITAL', 'CD') FROM DUAL), '[^,]+', 1, LEVEL) AS DATA
                             FROM DUAL
                             CONNECT BY REGEXP_SUBSTR((SELECT PA.PARAM.PARAMETRO_X_EMPRESA('1', 'CD_CERT_DIGITAL', 'CD') FROM DUAL), '[^,]+', 1, LEVEL) IS NOT NULL);
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
    ves_penable:='N';
    dfechaUltRenov:=NULL;
    nbase_calculo:=0;
    dfechaUltcap:=NULL;
    nmonto_apertura:=0;
    nporcentajeRenta:=0;
    vcodproducto:=NULL;
    ninteresmes:=0; 
    nInteresAcum:=0;
    pn_errorNumber:=415; 
    pv_errorMessage:='No existe un n mero de certificado digital registrado con numero de certificado '||pv_certificateNumber;
    RETURN;
    END;

    IF (ves_penable = 'S') Then
        BEGIN
              IF (vtip_certificado = 'CU') Then -- Si es pagadero (Con Cupones)

                    ninteresGanado := ROUND (NVL (ninteresAcum, 0.00) + NVL(ninteresmes, 0.00), 2);
                    ninteresNetoGanado := ROUND (NVL (ninteresmes, 0.00), 2) -(ROUND (ROUND(NVL (ninteresmes, 0.00), 2) * (nporcentajeRenta/100), 2));
                     nmonto_total:=nvl(nmonto_apertura,0)+ nvl(ninteresNetoGanado,0);
                         BEGIN
                            pv_cancellationType     :='A';
                            pn_cancellationAmount   :=nmonto_total;
                            pn_penalAmount          :=0;
                            pn_creditAcount         :=pn_acountNumber;
                         END;    
              ELSIF (vtip_certificado IN ('CV', 'CF')) THEN    --si es capitalizable -- Capitalizable Tasa Variable / Tasa Fija

                 ninteresGanado := ROUND (NVL (ninteresAcum, 0.00) + nvl (ninteresMes, 0.00), 2);   
                 ninteresnetoGanado := (ROUND (NVL (ninteresMes, 0.00), 2)
                                  - ROUND (ROUND (NVL (ninteresMes, 0.00), 2) * nporcentajeRenta, 2));
                nmonto_total:=nvl(nmonto_apertura,0) + nvl (ninteresAcum, 0.00) + nvl(ninteresnetoGanado,0);
                NULL;
              END IF; 
      --
           IF ((dfechacalcd - dfechaUltRenov) < 7)
                 AND (dfechacalcd > dfechaUltRenov)  THEN 
                 IF (pa.calendar.dias_habiles_entre_fechas (pv_companyId,
                                                            vcodagencia,
                                                            dfechaUltRenov,
                                                            dfechacalcd) <= ndiasGracias)
             THEN

            pv_cancellationType:='V';
            ELSE
            pv_cancellationType:='A';
             END IF;
           END IF;

           IF (pv_cancellationType = 'A')
           THEN

              -- EBlanco: 09-06-2014: Se movio para que al momento de llamar la funcion ya tena calculado los dias por vencer.
              ndiasavencer:=dfechavence-dfechacalcd;
              nmonto_penalidad:=calcula_penalidad(p_empresa        =>    pv_companyId, 
                                                  p_certificado    =>    pv_certificateNumber, 
                                                  pcod_producto    =>    vcodproducto,
                                                  p_monto          =>    nmonto_total,
                                                  pfecha_cal       =>    dfechacalcd,
                                                  p_fecha_emision  =>    dfechaEmision,
                                                  p_fecha_ult_cap  =>    dfechaUltcap,
                                                  p_fecha_ult_ren  =>    dfechaUltRenov,
                                                  p_fecha_vence    =>    dfechaVence,
                                                  p_dias_pendiente =>    ndiasaVencer);
                 pn_penalAmount:= nmonto_penalidad;

              END IF;
              pn_penalAmount:=nmonto_penalidad;
              pn_cancellationAmount := ROUND (NVL (nmonto_total, 0.00), 2)-nvl(nmonto_penalidad,0);  
        END;
       ELSE

        pn_penalAmount:=nmonto_penalidad;
        pn_cancellationAmount := ROUND (NVL (nmonto_total, 0.00), 2);
   END IF;
    pn_errorNumber:=200; 
    pv_errorMessage:='Ok';
END;
 FUNCTION getAmortizationCd(pn_openingAmount      IN NUMBER,
                            pn_baseCalendar       IN NUMBER,
                            pn_percentTaxe        IN NUMBER,
                            pn_termInDay          IN NUMBER,
                            pv_interestType       IN VARCHAR2,
                            pn_openingRate        IN NUMBER,
                            pd_openingDate        IN DATE,
                            pd_expirationDate     IN DATE
                            ) RETURN   CD.tAMORTIZACIONCD_DIGITAL

                           IS
            dataLoad            VARCHAR2(4000):='';
            vcodmensaje         VARCHAR2(10):='';
            vmensaje            VARCHAR2(200):='';
            nsecuencia          NUMBER:=0;
            ciclo               NUMBER:=1;--pn_termInDay/30;
            tAmortization       CD.tAMORTIZACIONCD_DIGITAL;
            nMontototal         NUMBER:=0;
            nMontoIntciclob     NUMBER:=0;
            nMontoIntciclon     NUMBER:=0;
            nMontocdciclo       NUMBER;
            nMontoIntAcum       NUMBER:=0;
            dFechaliq           DATE;
            dFechaciclo         DATE;

            dFechaControl       DATE;
            dFechant            DATE;
            nDias               NUMBER;
            nMontoRetencion     NUMBER;
            nMontoNeto          NUMBER;
            nInteresTotal       NUMBER;

            bSigCiclo         BOOLEAN:=TRUE;

         BEGIN
            BEGIN
                IF TO_DATE((vdiapagocd||'/'||TO_CHAR(pd_openingDate,'MM/YYYY')),'DD/MM/YYYY') >=pd_openingDate THEN
                dfechaliq:=TO_DATE((vdiapagocd||'/'||TO_CHAR(pd_openingDate,'MM/YYYY')),'DD/MM/YYYY');
                ELSE
                dfechaliq:=TO_DATE((vdiapagocd||'/'||TO_CHAR((add_months(pd_openingDate,1)),'MM/YYYY')),'DD/MM/YYYY');
                END IF;
                  dfechant:=pd_openingDate;
             dfechacontrol:=dfechaliq;
            WHILE bSigCiclo=TRUE LOOP
                ciclo:=ciclo+1;
                dfechacontrol:=ADD_MONTHS(dfechacontrol,1);

                IF dfechacontrol>=pd_expirationDate THEN
                bSigCiclo:=FALSE;
                END IF;
                END LOOP;    
            tAmortization:=CD.tAMORTIZACIONCD_DIGITAL();

           FOR r IN 1..ciclo
           LOOP
           IF dfechaliq > pd_expirationDate THEN
            dfechaliq:=pd_expirationDate;
           END IF;
           ndias:=(dfechaliq-dfechant)+1;
           nsecuencia:=nsecuencia+1;
           nMontocdciclo:=pn_openingAmount+NVL(nmontoIntAcum,0);
           nMontoIntCiclob:=ROUND((((((pn_openingRate/100)/pn_baseCalendar))*nMontocdciclo)*ndias),2);
           nMontoRetencion:=ROUND((nMontoIntCiclob*(pn_percentTaxe/100)),2);
           nMontoIntCiclon:=nMontoIntCiclob-NVL(nMontoRetencion,0);
           nInteresTotal:=NVL(nInteresTotal,0)+nMontoIntCiclob;

           IF pv_interestType='N' THEN
                nMontototal:=pn_openingAmount;
             ELSE
                nMontototal:=nMontocdciclo;
          END IF;

          IF pv_interestType!='N' THEN
                nMontoIntAcum:=NVL(nMontoIntAcum,0)+nMontoIntCiclon;
          END IF;

          tAmortization.EXTEND;
                tAmortization(tAmortization.LAST) := 
                     CD.rAMORTIZACIONCD_DIGITAL (nsecuencia        ,
                                                 nsecuencia        ,
                                                 dfechant          ,
                                                 dfechaliq         ,
                                                 ndias             ,
                                                 nMontocdciclo     ,
                                                 nMontoIntAcum     ,
                                                 nMontoIntCiclob   ,
                                                 nMontoRetencion   ,
                                                 nMontoIntCiclon   ,
                                                 nMontototal     );
          dfechant:=dfechaliq+1;
          dfechaliq:=ADD_MONTHS(dfechaliq,1);  
          END LOOP;
        END; 
          --pn_interestTotal:=nInteresTotal;
          RETURN tAmortization;
        END;
FUNCTION getCertificateNumber(P_Empresa IN VARCHAR2, 
                             P_Agencia IN VARCHAR2,
                             P_Moneda  IN NUMBER,
                             P_Error   IN OUT VARCHAR2, 
                             P_SqlCode IN OUT VARCHAR2) RETURN VARCHAR2 IS 


   v_numero  number(9);
   v_maximo  number(9);
BEGIN
   v_numero := NULL ;


   BEGIN
     SELECT NVL(val_siguiente,0), val_maximo
       INTO v_numero, v_maximo
       FROM cd_consec_x_agencia
      WHERE cod_empresa = P_Empresa
        AND cod_agencia = P_Agencia
        AND cod_moneda  = P_Moneda
        AND activa      = 'S' 
        FOR UPDATE OF val_siguiente ;
      IF v_numero >= v_maximo THEN
          p_error := '652' ;
          RETURN NULL;
      END IF;
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
        p_error := '354' ;
        p_sqlcode := SQLCODE ;
     WHEN TOO_MANY_ROWS THEN
        p_error := '355' ;
        p_sqlcode := SQLCODE ;
     WHEN OTHERS THEN
        p_error := '101' ;
        p_sqlcode := SQLCODE ;
   END ;
   IF v_numero IS NOT NULL THEN
     -- Actualiza el ultimo numero de certificado asignado 
     BEGIN
       UPDATE cd_consec_x_agencia
          SET val_siguiente = NVL(val_siguiente,0) + 1
        WHERE cod_empresa = P_Empresa
          AND cod_agencia = P_Agencia
          AND cod_moneda  = P_Moneda
          AND activa      = 'S';
          COMMIT;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
          p_error := '354' ;
          p_sqlcode := SQLCODE ;
          RETURN NULL;
       WHEN TOO_MANY_ROWS THEN
          p_error := '355' ;
          p_sqlcode := SQLCODE ;
          RETURN NULL;
       WHEN OTHERS THEN
          p_error := '101' ;
          p_sqlcode := SQLCODE ;
          RETURN NULL;
    END ;
  END IF ;

  RETURN (v_numero) ;
END;
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
 RETURN NUMBER
IS
   vtiempo              NUMBER;
   vpenalidad           NUMBER;
   vexoneracion         NUMBER;
   vtransaccion         NUMBER;
   vsubtipotrans        NUMBER;
   vint_cal             NUMBER;
   vmonto_r             NUMBER;
   ncomision_calculada  NUMBER;
BEGIN
   vtransaccion := PA.param.parametro_x_empresa (p_empresa, 'TRANS_PENALIDAD', 'CD');
   vsubtipotrans := PA.param.parametro_x_empresa (p_empresa, 'SUBTRANS_PENALIDAD', 'CD');
   --
   BEGIN                                                   -- Verifico si este cd no esta exonerado del pago de la penalidad
      SELECT COUNT (*)
        INTO vexoneracion
        FROM cd_movimiento
       WHERE cod_empresa = p_empresa
         AND num_certificado = p_certificado
         AND tip_transaccion = vtransaccion
         AND subtip_transac = vsubtipotrans;
   EXCEPTION
      WHEN OTHERS
      THEN
         vexoneracion:=0;
   END;


      BEGIN
         SELECT NVL (tasa_penalidad, 0) / 100
           INTO vpenalidad
           FROM cd_penalidad_cancelacion
          WHERE cod_producto = pcod_producto
            AND p_dias_pendiente BETWEEN limite_inferior AND limite_superior;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            vpenalidad := 0;                                                                  -- No le corresponde penalidad
      END;


   vmonto_r := 0;
   -- Para buscar saldo del Certificado a la ultima fecha de renovacion. LDAMIAN
   BEGIN                                                                                                -- LDAMIAN 24/06/2009
      SELECT monto_cd
        INTO vmonto_r
        FROM cd_interes r
       WHERE r.cod_empresa = p_empresa
         AND r.num_certificado = p_certificado
         AND r.fecha_calculo = NVL (p_fecha_ult_cap, NVL (p_fecha_ult_ren, p_fecha_emision));
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         vmonto_r := p_monto;
      WHEN OTHERS
      THEN
         vmonto_r := p_monto;
   END;                                                                      

   ncomision_calculada := ((vmonto_r * vpenalidad) / 360) * p_dias_pendiente;
   --
  IF NVL (ncomision_calculada, 0) <> 0
  THEN
  RETURN (ncomision_calculada);
  ELSE

  RETURN (0);
  END IF;

  -- :bktotal.total_pagar := nvl (:bktotal.total_principal, 0.00) + nvl (:bktotal.total_intxpag_neto, 0.00) - nvl (:bktotal.total_comision, 0.00);
END;
FUNCTION get_codigo_hast( i_num_certificado       IN  VARCHAR2,
                          i_cedula                IN  VARCHAR2,
                          i_nombre_cliente        IN  VARCHAR2,
                          o_cod_error             OUT VARCHAR2,
                          o_mensaje               OUT VARCHAR2) RETURN VARCHAR2
IS
   -- Variables de manejo de archivo
   vlinebuff   varchar2 (500);
   codigohast  varchar2(200):='';
BEGIN
BEGIN
   vlinebuff := RTRIM (i_nombre_cliente) || REPLACE (i_cedula, '-', '') || i_num_certificado;
   codigohast := pa.sha1 (vlinebuff);
EXCEPTION
   WHEN OTHERS  THEN
       o_cod_error:='407';
       o_mensaje :='No se pudo geenrar el codigo HAST para esta solicitud.';
END;
RETURN (codigohast);
END;

END;

/

