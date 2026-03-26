CREATE OR REPLACE PROCEDURE PR.Generar_Reportes_Prestamo(
    pCodigoEmpresa     IN     VARCHAR2,
    pCreditoNuevo      IN     VARCHAR2,
    pCreditoAnterior   IN     VARCHAR2,
    pValidaReprestamo  IN     BOOLEAN,
    pError             IN OUT VARCHAR2) IS
    vURL                VARCHAR2(4000);
    vIdAplication       PLS_INTEGER := 2;                         -- Prestamos
    vIdTipoDocumento    PLS_INTEGER;
    vCodigoReferencia   VARCHAR2(100) := pCreditoNuevo || ':' || NVL(pCreditoAnterior, ' ');
    vCodigoCliente      PR.PR_CREDITOS.CODIGO_CLIENTE%TYPE;
    vDocumento          VARCHAR2(30);
    vNombreArchivo      VARCHAR2(60);
    vOrigenPkm          VARCHAR2(30) := 'Normal';
    vIdtempFud          PR.TEMPFUD.ID_TEMPFUD%TYPE;
    vIdtempFec          PR.TEMPFEC.ID_TEMPFEC%TYPE;
    vNomArchivo         PR.TEMPFUD.NOMARCHIVO%TYPE;
    vIdReprestamo       PR.PR_REPRESTAMOS.ID_REPRESTAMO%TYPE;
    vIdentificacion     PA.ID_PERSONAS.NUM_ID%TYPE;
    vNombres            VARCHAR2(200);
    vApellidos          VARCHAR2(200);
    --v_datacredito       XMLTYPE;
    vContinuar          BOOLEAN := FALSE;
    v_datacredito_json clob;
    CURSOR c_Poliza(p_NoCredito IN NUMBER) IS
    SELECT PC.TIPO_POLIZA
    FROM PR.PR_POLIZAS_X_CREDITO PC
    JOIN PR.PR_TIPOS_POLIZAS T ON T.TIPO_POLIZA = PC.TIPO_POLIZA
    where PC.NO_CREDITO = p_NoCredito
     and T.TIPO_POLIZA in ('17','18','24') ;
    vMiPyme             VARCHAR2(2) := 'N';
    vDesempleo          VARCHAR2(2) := 'N';
    FUNCTION IncluirTipoDoc(pIdTipoDoc  IN NUMBER) RETURN BOOLEAN IS
        CURSOR c_TipoDoc IS
        with rws as (select PA.OBT_PARAMETROS('1', 'PR', 'TIPODOC_CLI_HELADO') str from dual)
          select regexp_substr ( str, '[^;]+', 1, level ) value
          from   rws
          connect by level <= length( str ) - length( replace ( str, ';' ) ) + 1;
        TYPE tTipoDoc IS TABLE OF c_TipoDoc%ROWTYPE;
        vTipoDoc    tTipoDoc;
        vExiste     BOOLEAN := FALSE;
    begin
        vExiste := FALSE;
        OPEN c_TipoDoc;
        LOOP
            FETCH c_TipoDoc BULK COLLECT INTO vTipoDoc LIMIT 500;
            FOR i IN 1 .. vTipoDoc.COUNT LOOP
                IF vTipoDoc(i).VALUE = pIdTipoDoc THEN
                    vExiste := TRUE;
                END IF;
            END LOOP;
            EXIT WHEN c_TipoDoc%NOTFOUND;
        END LOOP;
        CLOSE c_TipoDoc;
        RETURN vExiste;
    end;
BEGIN
    -- Determinar si es de represtamos o no
    BEGIN
        SELECT 'Represtamo', R.ID_REPRESTAMO
          INTO vOrigenPkm, vIdReprestamo
          FROM PR.PR_REPRESTAMOS R, PR.PR_SOLICITUD_REPRESTAMO S
         WHERE S.CODIGO_EMPRESA = pCodigoEmpresa
           AND R.CODIGO_EMPRESA = S.CODIGO_EMPRESA
           AND R.ID_REPRESTAMO = S.ID_REPRESTAMO
           AND R.NO_CREDITO = pCreditoAnterior
           AND S.NO_CREDITO = pCreditoNuevo;
           IF pValidaReprestamo THEN
               vContinuar := TRUE;
           ELSE
               vContinuar := FALSE;
           END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            vOrigenPkm := 'Normal';
            IF pValidaReprestamo THEN
               vContinuar := FALSE;
            ELSE
               vContinuar := TRUE;
            END IF;
    END;
    IF vContinuar THEN
        vIdentificacion := ' ';
        BEGIN
            SELECT C.CODIGO_CLIENTE, PA.OBT_IDENTIFICACION_PERSONA(c.CODIGO_CLIENTE, '1')
              INTO vCodigoCliente, vIdentificacion
              FROM PR.PR_CREDITOS C
             WHERE C.NO_CREDITO = pCreditoNuevo;
        EXCEPTION WHEN NO_DATA_FOUND THEN
            pError := 'Error obteniendo los datos del préstamo ' || SQLERRM;
            RAISE_APPLICATION_ERROR(-20104, pError);
        END;
        BEGIN
            --v_datacredito := PA.PA_PKG_CONSULTA_DATACREDITO.CONSULTAR_SERVICIO_ORIGINAL(replace(vIdentificacion,'-'));
            v_datacredito_json := pa_pkg_consulta_datacredito.consultar_json(vIdentificacion,
                                                                             'C',
                                                                             'AUTOINDEXADO',
                                                                             null,
                                                                             null,
                                                                             nvl(v('APP_USER'), user),
                                                                             null,
                                                                             0);
        EXCEPTION WHEN OTHERS THEN
            NULL;
        END;
        -- Determina la FUD
        BEGIN
            SELECT f.ID_TEMPFUD, f.NOMARCHIVO
              INTO vIdtempFud, vNomArchivo
              FROM PR.TEMPFUD f
             WHERE f.NOCREDITO = pCreditoNuevo
               AND f.NUMDOCUMENTOIDENTIDAD = replace(vIdentificacion,'-')
               AND f.ID_TEMPFUD = (select max(id_tempfud) FROM PR.TEMPFUD X WHERE x.NOCREDITO = pCreditoNuevo AND x.NUMDOCUMENTOIDENTIDAD = replace(vIdentificacion,'-'));
        EXCEPTION WHEN NO_DATA_FOUND THEN
            pError := 'Error obteniendo la FUD ' || SQLERRM;
            vIdtempFud := NULL;
            DBMS_OUTPUT.PUT_LINE(pError);
        END;
        DBMS_OUTPUT.PUT_LINE ( 'vIdtempFud = '|| vIdtempFud||' vNomArchivo = ' || vNomArchivo );
        -- Determina la FEC
        BEGIN
            SELECT f.ID_TEMPFEC
              INTO vIdtempFec
              FROM PR.TEMPFEC f
             WHERE f.NOMARCHIVO = vNomArchivo
               AND f.DOCUMENTOIDENTIDAD = REPLACE(vIdentificacion, '-','')
               AND f.ID_TEMPFEC = (SELECT MAX(X.ID_TEMPFEC) FROM PR.TEMPFEC x WHERE x.NOMARCHIVO = vNomArchivo AND x.DOCUMENTOIDENTIDAD = REPLACE(vIdentificacion, '-','') );
        EXCEPTION WHEN NO_DATA_FOUND THEN
            pError := 'Error obteniendo la FEC ' || SQLERRM;
            vIdtempFec := NULL;
            DBMS_OUTPUT.PUT_LINE(pError);
        END;
        DBMS_OUTPUT.PUT_LINE ( 'vIdtempFec = ' || vIdtempFec );
        vIdTipoDocumento := '193';             -- CONSULTA BURO DE CREDITO PRIVADO
        vDocumento := 'BURO';
        vCodigoReferencia := '1:' || REPLACE(vIdentificacion,'-','') || ':' || pCreditoNuevo || ': :' || vDocumento || ':' || vIdtempFud;
        vNombreArchivo := vDocumento || '_' || pCreditoNuevo || '_' || pCreditoAnterior;
        PA.PKG_TIPO_DOCUMENTO_PKM.InsertUrlReporte(
            pCodigoReferencia   => vCodigoReferencia,
            pFechaReporte       => SYSDATE,
            pId_Aplicacion      => vIdAplication,
            pIdTipoDocumento    => vIdTipoDocumento,
            pOrigenPkm          => vOrigenPkm,
            pUrlReporte         => NULL,
            pFormatoDocumento   => 'PDF',
            pNombreArchivo      => vNombreArchivo || '.pdf',
            pEstado             => 'R',
            pRespuesta          => pError);
        vIdTipoDocumento := '194';                  -- CONSULTA BUSCADOR DE GOOGLE
        vDocumento := 'SIB';
        vCodigoReferencia := '1:' || REPLACE(vIdentificacion,'-','') || ':' || pCreditoNuevo || ': :' || vDocumento;
        vNombreArchivo := vDocumento || '_' || pCreditoNuevo || '_' || pCreditoAnterior;
        PA.PKG_TIPO_DOCUMENTO_PKM.InsertUrlReporte(
            pCodigoReferencia   => vCodigoReferencia,
            pFechaReporte       => SYSDATE,
            pId_Aplicacion      => vIdAplication,
            pIdTipoDocumento    => vIdTipoDocumento,
            pOrigenPkm          => vOrigenPkm,
            pUrlReporte         => NULL,
            pFormatoDocumento   => 'PDF',
            pNombreArchivo      => vNombreArchivo || '.pdf',
            pEstado             => 'R',
            pRespuesta          => pError);
       BEGIN
            SELECT PRIMER_NOMBRE||' '||SEGUNDO_NOMBRE Nombres,
                   PRIMER_APELLIDO||' '||SEGUNDO_APELLIDO
              INTO vNombres, vApellidos
              FROM PA.PERSONAS_FISICAS pf
             WHERE pf.COD_PER_FISICA = vCodigoCliente;
        EXCEPTION WHEN NO_DATA_FOUND THEN
            vNombres := NULL;
            vApellidos := NULL;
        END;
        vIdTipoDocumento := '450';             -- CONSULTA LEXIS NEXIS PRIVADO
        vDocumento := 'LEXISNEXIS';
        vCodigoReferencia := '1:' || REPLACE(vIdentificacion,'-','') || ':' || pCreditoNuevo || ': :' || vDocumento || ':' || vIdtempFud;
        vNombreArchivo := vDocumento || '_' || pCreditoNuevo || '_' || pCreditoAnterior;
        vUrl := null; --PA.PKG_TIPO_DOCUMENTO_PKM.UrlLexisNexis(vNombres, vApellidos, REPLACE(vIdentificacion,'-',''));
        PA.PKG_TIPO_DOCUMENTO_PKM.InsertUrlReporte(
            pCodigoReferencia   => vCodigoReferencia,
            pFechaReporte       => SYSDATE,
            pId_Aplicacion      => vIdAplication,
            pIdTipoDocumento    => vIdTipoDocumento,
            pOrigenPkm          => vOrigenPkm,
            pUrlReporte         => NULL,
            pFormatoDocumento   => 'PDF',
            pNombreArchivo      => vNombreArchivo || '.pdf',
            pEstado             => 'R',
            pRespuesta          => pError);
        -- Generar FEC para File Flow
        IF vOrigenPkm = 'Represtamo' THEN
            vIdTipoDocumento := '477';                                   -- FEC DEUDOR
            vDocumento := 'FEC';
            --vCodigoReferencia := '1:' || REPLACE(vIdentificacion,'-','') || ':' || pCreditoNuevo || ': :' || vDocumento || ':' || vIdtempFud;
            vCodigoReferencia := pCreditoNuevo || ': ';
            vNombreArchivo := vDocumento || '_' || pCreditoNuevo || '_' || pCreditoAnterior || '.pdf';
            vUrl := PA.PKG_TIPO_DOCUMENTO_PKM.UrlFecReprestamos(vIdReprestamo);
            PA.PKG_TIPO_DOCUMENTO_PKM.InsertUrlReporte(
                pCodigoReferencia   => vCodigoReferencia,
                pFechaReporte       => SYSDATE,
                pId_Aplicacion      => vIdAplication,
                pIdTipoDocumento    => vIdTipoDocumento,
                pOrigenPkm          => vOrigenPkm,
                pUrlReporte         => vUrl,
                pFormatoDocumento   => 'PDF',
                pNombreArchivo      => vNombreArchivo,
                pEstado             => 'P',
                pRespuesta          => pError);
        ELSE
            IF vIdtempFec IS NOT NULL THEN
                vIdTipoDocumento := '477';                                   -- FEC DEUDOR
                vDocumento := 'FEC';
                vCodigoReferencia := '1:' || REPLACE(vIdentificacion,'-','') || ':' || pCreditoNuevo || ': :' || vDocumento || ':' || vIdtempFud;
                --vCodigoReferencia := pCreditoNuevo || ': ';
                vNombreArchivo := vDocumento || '_' || pCreditoNuevo || '_' || pCreditoAnterior || '_'||to_char(sysdate, 'ddmmyyyy')||'.pdf';
                vUrl := PA.PKG_TIPO_DOCUMENTO_PKM.UrlFec(pId_tempfec   => vIdtempFec,
                                                         p_nomarchivo  => vNomArchivo) ; -- falta funcion para obtener url del rporte FEC vIdtempFec;
                PA.PKG_TIPO_DOCUMENTO_PKM.InsertUrlReporte(
                    pCodigoReferencia   => vCodigoReferencia,
                    pFechaReporte       => SYSDATE,
                    pId_Aplicacion      => vIdAplication,
                    pIdTipoDocumento    => vIdTipoDocumento,
                    pOrigenPkm          => vOrigenPkm,
                    pUrlReporte         => vUrl,
                    pFormatoDocumento   => 'PDF',
                    pNombreArchivo      => vNombreArchivo,
                    pEstado             => 'P',
                    pRespuesta          => pError);
            END IF;
        END IF;
        IF vIdtempFud IS NOT NULL THEN
            vIdTipoDocumento := '474';                                          -- FUD
            vDocumento := 'FUD';
            vCodigoReferencia := '1:' || REPLACE(vIdentificacion,'-','') || ':' || pCreditoNuevo || ': :' || vDocumento || ':' || vIdtempFud;
            --vCodigoReferencia := pCreditoNuevo || ': ';
            vUrl := PA.PKG_TIPO_DOCUMENTO_PKM.UrlFudReprestamos(vIdtempFud, vNomArchivo);
            vNombreArchivo := vDocumento || '_' || pCreditoNuevo || '_' || pCreditoAnterior || '_'||to_char(sysdate, 'ddmmyyyy')|| '.pdf';
            PA.PKG_TIPO_DOCUMENTO_PKM.InsertUrlReporte(
                pCodigoReferencia   => vCodigoReferencia,
                pFechaReporte       => SYSDATE,
                pId_Aplicacion      => vIdAplication,
                pIdTipoDocumento    => vIdTipoDocumento,
                pOrigenPkm          => vOrigenPkm,
                pUrlReporte         => vUrl,
                pFormatoDocumento   => 'PDF',
                pNombreArchivo      => vNombreArchivo,
                pEstado             => 'P',
                pRespuesta          => pError);
        END IF;
        vIdTipoDocumento := '452';                        -- Formulario de Conozca
        vDocumento := 'FCSCPF';
        vCodigoReferencia := '1:' || REPLACE(vIdentificacion,'-','') || ':' || pCreditoNuevo || ': :' || vDocumento || ':' || vIdtempFud;
        --vCodigoReferencia := pCreditoNuevo || ': ';
        vNombreArchivo := vDocumento || '_' || pCreditoNuevo || '_' || pCreditoAnterior|| '_'||to_char(sysdate, 'ddmmyyyy')|| '.pdf';
        -- Generar Conozca Su Cliente para File Flow
        vUrl := PA.PKG_TIPO_DOCUMENTO_PKM.UrlConozcaSuCliente(vCodigoCliente, pCodigoEmpresa);
        PA.PKG_TIPO_DOCUMENTO_PKM.InsertUrlReporte(
            pCodigoReferencia   => vCodigoReferencia,
            pFechaReporte       => SYSDATE,
            pId_Aplicacion      => vIdAplication,
            pIdTipoDocumento    => vIdTipoDocumento,
            pOrigenPkm          => vOrigenPkm,
            pUrlReporte         => vUrl,
            pFormatoDocumento   => 'PDF',
            pNombreArchivo      => vNombreArchivo,
            pEstado             => 'P',
            pRespuesta          => pError);
        IF IncluirTipoDoc(851) THEN
            vIdTipoDocumento := '851';                        -- Poliza
            vDocumento := 'APOLIZA';
            vCodigoReferencia := '1:' || REPLACE(vIdentificacion,'-','') || ':' || pCreditoNuevo || ': :' || vDocumento || ':' || vIdtempFud;
            vNombreArchivo := vDocumento || '_'|| pCreditoNuevo || '_' || pCreditoAnterior|| '_'||to_char(sysdate, 'ddmmyyyy')|| '.pdf';
            PA.PKG_TIPO_DOCUMENTO_PKM.InsertUrlReporte(
                pCodigoReferencia   => vCodigoReferencia,
                pFechaReporte       => SYSDATE,
                pId_Aplicacion      => vIdAplication,
                pIdTipoDocumento    => vIdTipoDocumento,
                pOrigenPkm          => vOrigenPkm,
                pUrlReporte         => NULL,
                pFormatoDocumento   => 'PDF',
                pNombreArchivo      => vNombreArchivo,
                pEstado             => 'R',
                pRespuesta          => pError);
        END IF;
        IF IncluirTipoDoc(204) THEN
            vIdTipoDocumento := '204';                        -- Poliza
            vDocumento := 'SVIDA';
            vCodigoReferencia := '1:' || REPLACE(vIdentificacion,'-','') || ':' || pCreditoNuevo || ': :' || vDocumento || ':' || vIdtempFud;
            vNombreArchivo := vDocumento || '_'|| pCreditoNuevo || '_' || pCreditoAnterior|| '_'||to_char(sysdate, 'ddmmyyyy')|| '.pdf';
            PA.PKG_TIPO_DOCUMENTO_PKM.InsertUrlReporte(
                pCodigoReferencia   => vCodigoReferencia,
                pFechaReporte       => SYSDATE,
                pId_Aplicacion      => vIdAplication,
                pIdTipoDocumento    => vIdTipoDocumento,
                pOrigenPkm          => vOrigenPkm,
                pUrlReporte         => NULL,
                pFormatoDocumento   => 'PDF',
                pNombreArchivo      => vNombreArchivo,
                pEstado             => 'R',
                pRespuesta          => pError);
        END IF;
        IF IncluirTipoDoc(451) THEN
            vIdTipoDocumento := '451';                        -- Deponente
            vDocumento := 'DEPONENTE';
            vCodigoReferencia := '1:' || REPLACE(vIdentificacion,'-','') || ':' || pCreditoNuevo || ': :' || vDocumento || ':' || vIdtempFud;
            vNombreArchivo := vDocumento || '_'|| pCreditoNuevo || '_' || pCreditoAnterior|| '_'||to_char(sysdate, 'ddmmyyyy')|| '.jpg';
            PA.PKG_TIPO_DOCUMENTO_PKM.InsertUrlReporte(
                pCodigoReferencia   => vCodigoReferencia,
                pFechaReporte       => SYSDATE,
                pId_Aplicacion      => vIdAplication,
                pIdTipoDocumento    => vIdTipoDocumento,
                pOrigenPkm          => vOrigenPkm,
                pUrlReporte         => NULL,
                pFormatoDocumento   => 'JPG',
                pNombreArchivo      => vNombreArchivo,
                pEstado             => 'R',
                pRespuesta          => pError);
        END IF;
        -- Verifica los Tipos de Pólizas del crédito
        vMiPyme := 'N';
        vDesempleo := 'N';
        FOR  reg IN c_Poliza(pCreditoNuevo) LOOP
            IF REG.tipo_poliza = 17 THEN
                vMiPyme := 'S';
            END IF;
            IF REG.tipo_poliza IN (18,24) THEN
                vDesempleo := 'S';
            END IF;
        END LOOP;
        -- Si tiene póliza de Desempleo
        IF vDesempleo = 'S' AND IncluirTipoDoc(882) THEN
            vIdTipoDocumento := '882';                        -- Poliza Desempleo
            vDocumento := 'SDESEMPLEO';
            vCodigoReferencia := '1:' || REPLACE(vIdentificacion,'-','') || ':' || pCreditoNuevo || ': :' || vDocumento || ':' || vIdtempFud;
            vNombreArchivo := vDocumento || '_'|| pCreditoNuevo || '_' || pCreditoAnterior|| '_'||to_char(sysdate, 'ddmmyyyy')|| '.pdf';
            PA.PKG_TIPO_DOCUMENTO_PKM.InsertUrlReporte(
                pCodigoReferencia   => vCodigoReferencia,
                pFechaReporte       => SYSDATE,
                pId_Aplicacion      => vIdAplication,
                pIdTipoDocumento    => vIdTipoDocumento,
                pOrigenPkm          => vOrigenPkm,
                pUrlReporte         => NULL,
                pFormatoDocumento   => 'PDF',
                pNombreArchivo      => vNombreArchivo,
                pEstado             => 'R',
                pRespuesta          => pError);
        END IF;
        -- Si tiene póliza de MiPyme
        IF vMiPyme = 'S' AND IncluirTipoDoc(218) THEN
            vIdTipoDocumento := '218';                        -- Seguros MiPyme
            vDocumento := 'SMIPYME';
            vCodigoReferencia := '1:' || REPLACE(vIdentificacion,'-','') || ':' || pCreditoNuevo || ': :' || vDocumento || ':' || vIdtempFud;
            vNombreArchivo := vDocumento || '_'|| pCreditoNuevo || '_' || pCreditoAnterior|| '_'||to_char(sysdate, 'ddmmyyyy')|| '.pdf';
            PA.PKG_TIPO_DOCUMENTO_PKM.InsertUrlReporte(
                pCodigoReferencia   => vCodigoReferencia,
                pFechaReporte       => SYSDATE,
                pId_Aplicacion      => vIdAplication,
                pIdTipoDocumento    => vIdTipoDocumento,
                pOrigenPkm          => vOrigenPkm,
                pUrlReporte         => NULL,
                pFormatoDocumento   => 'PDF',
                pNombreArchivo      => vNombreArchivo,
                pEstado             => 'R',
                pRespuesta          => pError);
        END IF;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        pError := pError || ' ' || DBMS_UTILITY.format_error_backtrace;
        RAISE_APPLICATION_ERROR(-20105, pError);
END;
/
