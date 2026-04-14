CREATE OR REPLACE PACKAGE CC.PKG_INTERFAZ_CC AS
   /******************************************************************************
       NAME:       pkg_interfaz_cc
       PURPOSE: crear cuentas de efectivo mediante un servicio o api

       REVISIONS:
       Ver        Date        Author           Description
       ---------  ----------  ---------------  ------------------------------------
       1.0        21/02/2024      fermin rodriguez       1. Package para el manejo de la
                                                      creacion de la cuenta efectivo Onboarding Digital.
    ******************************************************************************/

    --Dogito Verificador
    FUNCTION Digito_Verificador (pNumero   IN NUMBER,
                                 pTamano   IN NUMBER DEFAULT 11111111111111)
        RETURN NUMBER;

                                    

    --Validar la cuenta antes de ser insertada en la tabla
    FUNCTION Validar_Cuenta (pCuenta IN NUMBER)
        RETURN VARCHAR2;

    --Creacion de la cuenta.
    PROCEDURE crear_cuenta_efectivo_api (pSolicitudCuenta   IN CC.SOLICITUD_CUENTA_LIST,                                                                          
                                         pNumero_cuenta     IN OUT    VARCHAR2,
                                         pCodigoCliente     IN OUT    NUMBER,
                                         pErrornum          IN OUT    NUMBER,
                                         pMensaje_Error     IN OUT    VARCHAR2);

    --
    --Creacion de la cuenta.
    PROCEDURE crear_cuenta_efectivo (pCodigo_empresa    IN     VARCHAR2,
                                     pCodigo_cliente    IN     number,
                                     pCodigo_producto   IN     VARCHAR2,
                                     pcodigo_moneda     IN     VARCHAR2,
                                     pcodigo_agencia    IN     VARCHAR2,                                                                          
                                     pNumero_cuenta     IN OUT    VARCHAR2,
                                     pErrornum          IN OUT    NUMBER,
                                     pMensaje_Error     IN OUT    VARCHAR2);
PROCEDURE crear_matriz_riesgos (pCodigo_empresa         IN     VARCHAR2,
                                pCodigo_cliente         IN     number,
                                pMensaje_Error          OUT    VARCHAR2);
END pkg_INTERFAZ_CC;
/

