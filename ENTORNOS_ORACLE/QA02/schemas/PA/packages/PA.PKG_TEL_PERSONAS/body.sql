CREATE OR REPLACE PACKAGE BODY PA.PKG_TEL_PERSONAS IS
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
                      pResultado            IN OUT resultado) IS
      pData   PA.TEL_PERSONAS_OBJ;
   BEGIN
   
      pData := PA.TEL_PERSONAS_OBJ ();
      pData.COD_PERSONA := pCOD_PERSONA;
      pData.COD_AREA := pCOD_AREA;
      pData.NUM_TELEFONO := pNUM_TELEFONO;
      pData.TIP_TELEFONO := pTIP_TELEFONO;
      pData.TEL_UBICACION := pTEL_UBICACION;
      pData.EXTENSION := pEXTENSION;
      pData.NOTA := pNOTA;
      pData.ES_DEFAULT := pES_DEFAULT;
      pData.POSICION := pPOSICION;
      pData.COD_DIRECCION := pCOD_DIRECCION;
      pData.COD_PAIS := pCOD_PAIS;
      pData.NOTIF_DIGITAL := pNotif_Digital;
      pData.FECHA_NOTIF_DIGITAL := pFecha_Notif_Digital;
      pData.USUAARIO_NOTIF_DIGITAL := pUsuaario_Notif_Digital;

      IF pData.Validar ('G', pResultado.descripcion) THEN
         -- Existe
         IF pData.Existe () = FALSE THEN
            -- Insertar
            pData.crear ();
         ELSE
            -- Modificar
            pData.Actualizar ();
         END IF;
      END IF;
   EXCEPTION
      WHEN OTHERS THEN
         pResultado.codigo := SQLCODE;
         pResultado.descripcion := SQLERRM;
         RAISE_APPLICATION_ERROR (-20100, 'Error ' || SQLERRM);
   END Generar;

   PROCEDURE Crear (pCod_Persona              IN     VARCHAR2,
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
                    pResultado            IN OUT resultado) IS
      pData   PA.TEL_PERSONAS_OBJ;
   BEGIN
      pData := PA.TEL_PERSONAS_OBJ ();
      pData.COD_PERSONA := pCOD_PERSONA;
      pData.COD_AREA := pCOD_AREA;
      pData.NUM_TELEFONO := pNUM_TELEFONO;
      pData.TIP_TELEFONO := pTIP_TELEFONO;
      pData.TEL_UBICACION := pTEL_UBICACION;
      pData.EXTENSION := pEXTENSION;
      pData.NOTA := pNOTA;
      pData.ES_DEFAULT := pES_DEFAULT;
      pData.POSICION := pPOSICION;
      pData.COD_DIRECCION := pCOD_DIRECCION;
      pData.COD_PAIS := pCOD_PAIS;
      pData.NOTIF_DIGITAL := pNotif_Digital;
      pData.FECHA_NOTIF_DIGITAL := pFecha_Notif_Digital;
      pData.USUAARIO_NOTIF_DIGITAL := pUsuaario_Notif_Digital;

      IF pData.Validar ('C', pResultado.descripcion) THEN
         -- Existe
         IF pData.Existe () = FALSE THEN
            pData.Crear ();
         END IF;
      END IF;
   EXCEPTION
      WHEN OTHERS THEN
         pResultado.codigo := SQLCODE;
         pResultado.descripcion := SQLERRM;
         RAISE_APPLICATION_ERROR (-20100, 'Error ' || SQLERRM);
   END Crear;

   PROCEDURE Actualizar (pCod_Persona              IN     VARCHAR2,
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
                         pResultado            IN OUT resultado) IS
      pData   PA.TEL_PERSONAS_OBJ;
   BEGIN
      pData := PA.TEL_PERSONAS_OBJ ();
      pData.COD_PERSONA := pCOD_PERSONA;
      pData.COD_AREA := pCOD_AREA;
      pData.NUM_TELEFONO := pNUM_TELEFONO;
      pData.TIP_TELEFONO := pTIP_TELEFONO;
      pData.TEL_UBICACION := pTEL_UBICACION;
      pData.EXTENSION := pEXTENSION;
      pData.NOTA := pNOTA;
      pData.ES_DEFAULT := pES_DEFAULT;
      pData.POSICION := pPOSICION;
      pData.COD_DIRECCION := pCOD_DIRECCION;
      pData.COD_PAIS := pCOD_PAIS;
      pData.NOTIF_DIGITAL := pNotif_Digital;
      pData.FECHA_NOTIF_DIGITAL := pFecha_Notif_Digital;
      pData.USUAARIO_NOTIF_DIGITAL := pUsuaario_Notif_Digital;

      IF pData.Validar ('U', pResultado.descripcion) THEN
         -- Existe
         IF pData.Existe () = TRUE THEN
            pData.Actualizar ();
         END IF;
      END IF;
   EXCEPTION
      WHEN OTHERS THEN
         pResultado.codigo := SQLCODE;
         pResultado.descripcion := SQLERRM;
         RAISE_APPLICATION_ERROR (-20100, 'Error ' || SQLERRM);
   END Actualizar;

   PROCEDURE Borrar (pCod_Persona          IN     VARCHAR2,
                     pCod_Area             IN     VARCHAR2,
                     pNum_Telefono         IN     VARCHAR2,                     
                     pResultado            IN OUT resultado) IS
      pData   PA.TEL_PERSONAS_OBJ;
   BEGIN
      pData := PA.TEL_PERSONAS_OBJ ();
      pData.COD_PERSONA := pCOD_PERSONA;
      pData.COD_AREA := pCOD_AREA;
      pData.NUM_TELEFONO := pNUM_TELEFONO;      

      IF pData.Validar ('D', pResultado.descripcion) THEN
         -- Existe
         IF pData.Existe () = TRUE THEN
            pData.Borrar ();
         END IF;
      END IF;
   EXCEPTION
      WHEN OTHERS THEN
         pResultado.codigo := SQLCODE;
         pResultado.descripcion := SQLERRM;
         RAISE_APPLICATION_ERROR (-20100, 'Error ' || SQLERRM);
   END Borrar;

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
      RETURN PA.TEL_PERSONAS_LIST IS
      CURSOR cData  IS
         SELECT *
           FROM PA.TEL_PERSONAS t1
          WHERE (t1.COD_PERSONA = t1.COD_PERSONA||'')
            AND (t1.COD_AREA = t1.COD_AREA||'')
            AND (t1.NUM_TELEFONO = t1.NUM_TELEFONO||'')
            AND (t1.COD_PERSONA = pCOD_PERSONA OR pCOD_PERSONA IS NULL)
            AND (t1.COD_AREA = pCOD_AREA OR pCOD_AREA IS NULL)
            AND (t1.NUM_TELEFONO = pNUM_TELEFONO OR pNUM_TELEFONO IS NULL)
            AND (t1.TIP_TELEFONO = pTIP_TELEFONO OR pTIP_TELEFONO IS NULL)
            AND (t1.TEL_UBICACION = pTEL_UBICACION OR pTEL_UBICACION IS NULL)
            AND (t1.EXTENSION = pEXTENSION OR pEXTENSION IS NULL)
            AND (t1.NOTA = pNOTA OR pNOTA IS NULL)
            AND (t1.ES_DEFAULT = pES_DEFAULT OR pES_DEFAULT IS NULL)
            AND (t1.POSICION = pPOSICION OR pPOSICION IS NULL)
            AND (t1.COD_DIRECCION = pCOD_DIRECCION OR pCOD_DIRECCION IS NULL)
            AND (t1.COD_PAIS = pCOD_PAIS OR pCOD_PAIS IS NULL)
            AND (t1.MODIFICADO_POR = pMODIFICADO_POR OR pMODIFICADO_POR IS NULL)
            AND (t1.FECHA_MODIFICACION = pFECHA_MODIFICACION OR pFECHA_MODIFICACION IS NULL)
            AND (t1.INCLUIDO_POR = pINCLUIDO_POR OR pINCLUIDO_POR IS NULL)
            AND (t1.FEC_INCLUSION = pFEC_INCLUSION OR pFEC_INCLUSION IS NULL)
            AND (t1.NOTIF_DIGITAL = pNotif_Digital OR pNotif_Digital IS NULL);

      TYPE tData IS TABLE OF cData%ROWTYPE;

      vData       tData := tData();
      vDataList   PA.TEL_PERSONAS_LIST := PA.TEL_PERSONAS_LIST ();
      pData       PA.TEL_PERSONAS_OBJ;
      indice      NUMBER := 0;
   BEGIN
      
      vDataList.DELETE;
      OPEN cData ;

      LOOP
         FETCH cData BULK COLLECT INTO vData LIMIT 5000;

         FOR i IN 1 .. vData.COUNT LOOP
            pData := PA.TEL_PERSONAS_OBJ ();
            pData.COD_PERSONA   := vData(i).COD_PERSONA;
            pData.COD_AREA      := vData(i).COD_AREA;
            pData.NUM_TELEFONO  := vData(i).NUM_TELEFONO;
            pData.TIP_TELEFONO  := vData(i).TIP_TELEFONO;
            pData.TEL_UBICACION := vData(i).TEL_UBICACION;
            pData.EXTENSION     := vData(i).EXTENSION;
            pData.NOTA          := vData(i).NOTA;
            pData.ES_DEFAULT    := vData(i).ES_DEFAULT;
            pData.POSICION      := vData(i).POSICION;
            pData.COD_DIRECCION := vData(i).COD_DIRECCION;
            pData.COD_PAIS      := vData(i).COD_PAIS;
            pData.NOTIF_DIGITAL := vData(i).NOTIF_DIGITAL;
            pData.FECHA_NOTIF_DIGITAL   := vData(i).FECHA_NOTIF_DIGITAL;
            pData.USUAARIO_NOTIF_DIGITAL:= vData(i).USUAARIO_NOTIF_DIGITAL;
            indice := indice + 1;
            vDataList.EXTEND;
            vDataList (indice)  := pData;
         END LOOP;

         EXIT WHEN cData%NOTFOUND;
      END LOOP;

      CLOSE cData;

      RETURN vDataList;
   END Consultar;

   FUNCTION Existe (pCod_Persona    IN VARCHAR2,
                    pCod_Area       IN VARCHAR2,
                    pNum_Telefono   IN VARCHAR2)
      RETURN BOOLEAN IS
      pData   PA.TEL_PERSONAS_OBJ;
   BEGIN
      pData := PA.TEL_PERSONAS_OBJ ();
      pData.COD_PERSONA := pCOD_PERSONA;
      pData.COD_AREA := pCOD_AREA;
      pData.NUM_TELEFONO := pNUM_TELEFONO;
      RETURN pData.Existe ();
   END Existe;

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
                     pNotif_Digital          IN     VARCHAR2,
                     pFecha_Notif_Digital    IN     DATE,
                     pUsuaario_Notif_Digital IN     VARCHAR2,
                     pOperacion              IN     VARCHAR2,
                     pError                  IN OUT VARCHAR2)
      RETURN BOOLEAN IS
      pData   PA.TEL_PERSONAS_OBJ;
   BEGIN
      
      pData := PA.TEL_PERSONAS_OBJ ();
      pData.COD_PERSONA := pCOD_PERSONA;
      pData.COD_AREA := pCOD_AREA;
      pData.NUM_TELEFONO := pNUM_TELEFONO;
      pData.TIP_TELEFONO := pTIP_TELEFONO;
      pData.TEL_UBICACION := pTEL_UBICACION;
      pData.EXTENSION := pEXTENSION;
      pData.NOTA := pNOTA;
      pData.ES_DEFAULT := pES_DEFAULT;
      pData.POSICION := pPOSICION;
      pData.COD_DIRECCION := pCOD_DIRECCION;
      pData.COD_PAIS := pCOD_PAIS;
      pData.NOTIF_DIGITAL := pNotif_Digital;
      pData.FECHA_NOTIF_DIGITAL := pFecha_Notif_Digital;
      pData.USUAARIO_NOTIF_DIGITAL := pUsuaario_Notif_Digital;
       
      RETURN pData.Validar (pOperacion, pError);
   END Validar;
END PKG_TEL_PERSONAS;
/

