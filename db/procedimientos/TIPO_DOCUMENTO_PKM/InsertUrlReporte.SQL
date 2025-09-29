   PROCEDURE InsertUrlReporte(pCodigoReferencia   IN       VARCHAR2,
                              pFechaReporte       IN       DATE,
                              pId_Aplicacion      IN       NUMBER,
                              pIdTipoDocumento    IN       VARCHAR2,
                              pOrigenPkm          IN       VARCHAR2,  
                              pUrlReporte         IN       VARCHAR2, 
                              pFormatoDocumento   IN       VARCHAR2,
                              pNombreArchivo      IN       VARCHAR2,  
                              pEstado             IN       VARCHAR2 DEFAULT 'P',
                              pRespuesta          IN OUT   VARCHAR2,
                              pDocsReutilizar     IN       VARCHAR2 DEFAULT NULL
                              ) IS
        vDirectorio   VARCHAR2(256) := NVL(PA.PARAM.PARAMETRO_X_EMPRESA('1', 'DIR_REPORTES', 'IA'), 'RPT_REGULATORIOS'); --IA.EVERTEC_FCP_v2.getRutaFisica( NVL(PA.PARAM.PARAMETRO_X_EMPRESA('DIR_REPORTES'), 'RPT_REGULATORIOS'));
        vEnviarAPI    VARCHAR2(2);                              
   BEGIN
    
        BEGIN
            SELECT T.ENVIAR_API
              INTO vEnviarAPI
              FROM PA.PA_TIPO_DOCUMENTO_PKM t
             WHERE T.ID_APLICACION = pId_Aplicacion
               AND T.ID_TIPO_DOCUMENTO = pIdTipoDocumento;
        EXCEPTION WHEN NO_DATA_FOUND THEN
            vEnviarAPI := 'S';
        END;
        
        BEGIN
            v_docs_reutilizar_str := REPLACE(REPLACE(pDocsReutilizar, ' ', ''), ',', '*');
            
            INSERT INTO PA.PA_REPORTES_AUTOMATICOS
            ( CODIGO_REFERENCIA, FECHA_REPORTE, ID_APLICACION, ID_TIPO_DOCUMENTO, ORIGEN_PKM, URL_REPORTE, FORMATO_DOCUMENTO, DIRECTORIO_DESTINO, NOMBRE_ARCHIVO, ENVIAR_API, ESTADO_REPORTE, FECHA_PROCESO, ID_DOCS_REUTILIZAR )  
            VALUES ( pCodigoReferencia, pFechaReporte, pId_Aplicacion, pIdTipoDocumento, pOrigenPkm, pUrlReporte, pFormatoDocumento, vDirectorio, pNombreArchivo, NVL(vEnviarAPI,'S'), NVL(pEstado,'P'), SYSDATE, v_docs_reutilizar_str );
        EXCEPTION WHEN OTHERS THEN
            pRespuesta := 'Error: '||SQLERRM;
            RAISE_APPLICATION_ERROR(-20100, pRespuesta);
        END;    
        
   END InsertUrlReporte;   