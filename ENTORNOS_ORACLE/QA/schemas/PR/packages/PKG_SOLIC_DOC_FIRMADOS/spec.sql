create or replace PACKAGE    PKG_SOLIC_DOC_FIRMADOS IS
    TYPE ListaArchivos IS TABLE OF VARCHAR2 (256);

    PROCEDURE Generar (pCodigo_Empresa   IN     NUMBER,
                       pNo_Credito       IN     NUMBER,
                       pEstado           IN     VARCHAR2,
                       pResultado        IN OUT VARCHAR2);

    PROCEDURE Crear (pCodigo_Empresa   IN     NUMBER,
                     pNo_Credito       IN     NUMBER,
                     pEstado           IN     VARCHAR2,
                     pResultado        IN OUT VARCHAR2);

    PROCEDURE Actualizar (pCodigo_Empresa   IN     NUMBER,
                          pNo_Credito       IN     NUMBER,
                          pEstado           IN     VARCHAR2,
                          pResultado        IN OUT VARCHAR2);

    PROCEDURE ProcesarSolicitud (
        pCodigo_Empresa   IN     NUMBER,
        pNo_Credito       IN     NUMBER,
        pArchivos         IN     PA.PKG_API_PKM.tDescargaList,
        pResultado        IN OUT VARCHAR2);

    /*PROCEDURE CopiarArchivo (pOrigen      IN     VARCHAR2,
                             pDestino     IN     VARCHAR2,
                             pResultado   IN OUT VARCHAR2);*/
    
    PROCEDURE DescargarDocumentosSeguro(
        pCodigo_Empresa   IN     NUMBER,
        pNo_Credito       IN     NUMBER,
        pArchivos         IN OUT PA.PKG_API_PKM.tDescargaList,
        pResultado        IN OUT VARCHAR2);

    PROCEDURE Email_Docs_Firmados (
        pDestino     IN     VARCHAR2,
        pArchivos    IN     PA.PKG_API_PKM.tDescargaList,
        pResultado   IN OUT VARCHAR2);
    
    /*FUNCTION LeerArchivo2Blob (P_Filename    IN     VARCHAR2,
                               p_Directory   IN     VARCHAR2)
        RETURN BLOB;*/

    PROCEDURE Borrar (pCodigo_Empresa   IN     NUMBER,
                      pNo_Credito       IN     NUMBER,
                      pResultado        IN OUT VARCHAR2);

    FUNCTION Consultar (pCodigo_Empresa       IN     NUMBER,
                        pNo_Credito           IN     NUMBER,
                        pFecha_Solicitud      IN     DATE,
                        pAdicionado_Por       IN     VARCHAR2,
                        pFecha_Adicion        IN     DATE,
                        pModificado_Por       IN     VARCHAR2,
                        pFecha_Modificacion   IN     DATE,
                        pEstado               IN     VARCHAR2,
                        pResultado            IN OUT VARCHAR2)
        RETURN PR.PR_SOLIC_DOC_FIRMADOS_LIST;

    FUNCTION Comparar (pData1       IN OUT PR.PR_SOLIC_DOC_FIRMADOS_OBJ,
                       pData2       IN OUT PR.PR_SOLIC_DOC_FIRMADOS_OBJ,
                       pModo        IN     VARCHAR2,
                       pResultado   IN OUT VARCHAR2)
        -- O = (Compare between Objects pData1 and pData2),
        -- T = (Compare pData1 and Table data "Must used pData2 like search parameter in table)
        RETURN BOOLEAN;

    FUNCTION Existe (pCodigo_Empresa   IN     NUMBER,
                     pNo_Credito       IN     NUMBER,
                     pResultado        IN OUT VARCHAR2)
        RETURN BOOLEAN;

    FUNCTION Validar (pCodigo_Empresa    IN     NUMBER,
                      pNo_Credito        IN     NUMBER,
                      pFecha_Solicitud   IN     DATE,
                      pEstado            IN     VARCHAR2,
                      pOperacion         IN     VARCHAR2, -- G=Generar, C=Crear, U=Actualizar, D=Borrar
                      pError             IN OUT VARCHAR2)
        RETURN BOOLEAN;

    PROCEDURE LogError (pData                IN OUT PR.PR_SOLIC_DOC_FIRMADOS_OBJ,
                        inProgramUnit        IN     IA.LOG_ERROR.PROGRAMUNIT%TYPE,
                        inErrorDescription   IN     VARCHAR2,
                        inErrorTrace         IN     CLOB,
                        outIdError              OUT NUMBER);
END PKG_SOLIC_DOC_FIRMADOS;