CREATE OR REPLACE PACKAGE PA.PKG_TEL_PERSONAS IS
   TYPE resultado IS RECORD
   (
      codigo        VARCHAR2 (30),
      descripcion   VARCHAR2 (4000)
   );

   PROCEDURE Generar (pCod_Persona              IN     VARCHAR2,
                      pCod_Area                 IN     VARCHAR2,
                      pNum_Telefono             IN     VARCHAR2,
                      pTip_Telefono             IN     VARCHAR2,
                      pTel_Ubicacion            IN     VARCHAR2,
                      pExtension                IN     NUMBER,
                      pNota                     IN     VARCHAR2,
                      pEs_Default               IN     VARCHAR2,
                      pPosicion                 IN     NUMBER,
                      pCod_Direccion            IN     VARCHAR2,
                      pCod_Pais                 IN     VARCHAR2,                      
                      pNotif_Digital            IN     VARCHAR2,
                      pFecha_Notif_Digital      IN     DATE,
                      pUsuaario_Notif_Digital   IN     VARCHAR2,
                      pResultado                IN OUT resultado);

   PROCEDURE Crear (pCod_Persona          IN     VARCHAR2,
                    pCod_Area             IN     VARCHAR2,
                    pNum_Telefono         IN     VARCHAR2,
                    pTip_Telefono         IN     VARCHAR2,
                    pTel_Ubicacion        IN     VARCHAR2,
                    pExtension            IN     NUMBER,
                    pNota                 IN     VARCHAR2,
                    pEs_Default           IN     VARCHAR2,
                    pPosicion             IN     NUMBER,
                    pCod_Direccion        IN     VARCHAR2,
                    pCod_Pais             IN     VARCHAR2,
                    pNotif_Digital            IN     VARCHAR2,
                    pFecha_Notif_Digital      IN     DATE,
                    pUsuaario_Notif_Digital   IN     VARCHAR2,
                    pResultado            IN OUT resultado);

   PROCEDURE Actualizar (pCod_Persona          IN     VARCHAR2,
                         pCod_Area             IN     VARCHAR2,
                         pNum_Telefono         IN     VARCHAR2,
                         pTip_Telefono         IN     VARCHAR2,
                         pTel_Ubicacion        IN     VARCHAR2,
                         pExtension            IN     NUMBER,
                         pNota                 IN     VARCHAR2,
                         pEs_Default           IN     VARCHAR2,
                         pPosicion             IN     NUMBER,
                         pCod_Direccion        IN     VARCHAR2,
                         pCod_Pais             IN     VARCHAR2,
                         pNotif_Digital            IN     VARCHAR2,
                         pFecha_Notif_Digital      IN     DATE,
                         pUsuaario_Notif_Digital   IN     VARCHAR2,
                         pResultado            IN OUT resultado);

   PROCEDURE Borrar (pCod_Persona          IN     VARCHAR2,
                     pCod_Area             IN     VARCHAR2,
                     pNum_Telefono         IN     VARCHAR2,
                     pResultado            IN OUT resultado);

   FUNCTION Consultar (pCod_Persona          IN VARCHAR2,
                       pCod_Area             IN VARCHAR2,
                       pNum_Telefono         IN VARCHAR2,
                       pTip_Telefono         IN VARCHAR2,
                       pTel_Ubicacion        IN VARCHAR2,
                       pExtension            IN NUMBER,
                       pNota                 IN VARCHAR2,
                       pEs_Default           IN VARCHAR2,
                       pPosicion             IN NUMBER,
                       pCod_Direccion        IN VARCHAR2,
                       pCod_Pais             IN VARCHAR2,
                       pModificado_Por       IN VARCHAR2,
                       pFecha_Modificacion   IN DATE,
                       pIncluido_Por         IN VARCHAR2,
                       pFec_Inclusion        IN DATE,
                       pNotif_Digital            IN     VARCHAR2,
                       pFecha_Notif_Digital      IN     DATE,
                       pUsuaario_Notif_Digital   IN     VARCHAR2)
      RETURN PA.TEL_PERSONAS_LIST;

   FUNCTION Existe (pCod_Persona    IN VARCHAR2,
                    pCod_Area       IN VARCHAR2,
                    pNum_Telefono   IN VARCHAR2)
      RETURN BOOLEAN;

   FUNCTION Validar (pCod_Persona          IN     VARCHAR2,
                     pCod_Area             IN     VARCHAR2,
                     pNum_Telefono         IN     VARCHAR2,
                     pTip_Telefono         IN     VARCHAR2,
                     pTel_Ubicacion        IN     VARCHAR2,
                     pExtension            IN     NUMBER,
                     pNota                 IN     VARCHAR2,
                     pEs_Default           IN     VARCHAR2,
                     pPosicion             IN     NUMBER,
                     pCod_Direccion        IN     VARCHAR2,
                     pCod_Pais             IN     VARCHAR2,
                     pNotif_Digital            IN     VARCHAR2,
                     pFecha_Notif_Digital      IN     DATE,
                     pUsuaario_Notif_Digital   IN     VARCHAR2,
                     pOperacion            IN     VARCHAR2,
                     pError                IN OUT VARCHAR2)
      RETURN BOOLEAN;
END PKG_TEL_PERSONAS;
/

