CREATE OR REPLACE PACKAGE IA.PKG_API_PKM IS
    vUrlBase    VARCHAR2(200) := PA.PARAM.PARAMETRO_X_EMPRESA('1', 'URL_API_PKM', 'PA');
    
     TYPE tFile IS RECORD(
        ARCHIVO                VARCHAR2(256),
        EXTENSION              VARCHAR2(10),
        DIRECTORIO             VARCHAR2(256)
    );
    
    TYPE tListFiles IS TABLE OF tFile INDEX BY BINARY_INTEGER;

    FUNCTION Obtener_Token(p_Username    IN VARCHAR2,
                           p_Password    IN VARCHAR2) 
      RETURN VARCHAR2;
                                  
    FUNCTION Obtener_Aplicaciones(p_Token        IN VARCHAR2) 
      RETURN IA.PKM_APLICACION_LIST;
      
    FUNCTION Obtener_Campos(p_Token          IN VARCHAR2,
                            p_Id_Aplicacion  IN NUMBER)
      RETURN IA.PKM_CAMPO_LIST;
    
    procedure enviar_pkm(pToken             IN VARCHAR2,
                         pNoCredito         IN VARCHAR2,
                         pNoCreditoAnt      IN VARCHAR2,
                         pIdAplicacionPKM   IN NUMBER,
                         pTipoDocpKM        IN VARCHAR2,
                         pArchivos          IN IA.PKG_API_PKM.tListFiles,
                         pRespuesta         OUT VARCHAR2,
                         pError             OUT VARCHAR2
                         );
  
    FUNCTION ObtieneParteReferencia(pCodigoReferencia IN VARCHAR2, 
                                    pDelimitador      IN VARCHAR2, 
                                    pNumeroParte      IN NUMBER)
      RETURN VARCHAR2;
        
    FUNCTION ReadFileToBlob (in_Filename    IN     VARCHAR2,
                             in_Directory   IN     VARCHAR2,
                             out_Error         OUT VARCHAR2)
        RETURN BLOB;
  
END PKG_API_PKM;
/

