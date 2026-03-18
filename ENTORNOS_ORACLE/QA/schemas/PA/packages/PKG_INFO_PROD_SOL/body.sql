CREATE OR REPLACE PACKAGE BODY PA.PKG_INFO_PROD_SOL IS
   PROCEDURE Generar (pCod_Persona                 IN     VARCHAR2,
                      pTipo_Producto               IN     VARCHAR2,
                      pCod_Moneda                  IN     VARCHAR2,
                      pProposito                   IN     VARCHAR2,
                      pMonto_Inicial               IN     NUMBER,
                      pInstrumento_Bancario        IN     VARCHAR2,
                      pRango_Monetario_Ini         IN     NUMBER,
                      pRango_Monetario_Fin         IN     NUMBER,
                      pProm_Mes_Depo_Efectivo      IN     NUMBER,
                      pProm_Mes_Depo_Cheques       IN     NUMBER,
                      pProm_Mes_Reti_Efectivo      IN     NUMBER,
                      pProm_Mes_Trans_Enviada      IN     NUMBER,
                      pCod_Pais_Destino            IN     VARCHAR2,
                      pProm_Mes_Trans_Recibida     IN     NUMBER,
                      pCod_Pais_Origen             IN     VARCHAR2,
                      pCompras_Giros_Cheques_Ger   IN     NUMBER,
                      pOrigen_Fondos               IN     VARCHAR2,
                      pResultado                   IN OUT resultado) IS
      pData   PA.INFO_PROD_SOL_OBJ;
   BEGIN
      pData := PA.INFO_PROD_SOL_OBJ ();
      pData.COD_PERSONA := pCOD_PERSONA;
      pData.TIPO_PRODUCTO := pTIPO_PRODUCTO;
      pData.COD_MONEDA := pCOD_MONEDA;
      pData.PROPOSITO := pPROPOSITO;
      pData.MONTO_INICIAL := pMONTO_INICIAL;
      pData.INSTRUMENTO_BANCARIO := pINSTRUMENTO_BANCARIO;
      pData.RANGO_MONETARIO_INI := pRANGO_MONETARIO_INI;
      pData.RANGO_MONETARIO_FIN := pRANGO_MONETARIO_FIN;
      pData.PROM_MES_DEPO_EFECTIVO := pPROM_MES_DEPO_EFECTIVO;
      pData.PROM_MES_DEPO_CHEQUES := pPROM_MES_DEPO_CHEQUES;
      pData.PROM_MES_RETI_EFECTIVO := pPROM_MES_RETI_EFECTIVO;
      pData.PROM_MES_TRANS_ENVIADA := pPROM_MES_TRANS_ENVIADA;
      pData.COD_PAIS_DESTINO := pCOD_PAIS_DESTINO;
      pData.PROM_MES_TRANS_RECIBIDA := pPROM_MES_TRANS_RECIBIDA;
      pData.COD_PAIS_ORIGEN := pCOD_PAIS_ORIGEN;
      pData.COMPRAS_GIROS_CHEQUES_GER := pCOMPRAS_GIROS_CHEQUES_GER;
      pData.ORIGEN_FONDOS := pORIGEN_FONDOS;

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

   PROCEDURE Crear (pCod_Persona                 IN     VARCHAR2,
                    pTipo_Producto               IN     VARCHAR2,
                    pCod_Moneda                  IN     VARCHAR2,
                    pProposito                   IN     VARCHAR2,
                    pMonto_Inicial               IN     NUMBER,
                    pInstrumento_Bancario        IN     VARCHAR2,
                    pRango_Monetario_Ini         IN     NUMBER,
                    pRango_Monetario_Fin         IN     NUMBER,
                    pProm_Mes_Depo_Efectivo      IN     NUMBER,
                    pProm_Mes_Depo_Cheques       IN     NUMBER,
                    pProm_Mes_Reti_Efectivo      IN     NUMBER,
                    pProm_Mes_Trans_Enviada      IN     NUMBER,
                    pCod_Pais_Destino            IN     VARCHAR2,
                    pProm_Mes_Trans_Recibida     IN     NUMBER,
                    pCod_Pais_Origen             IN     VARCHAR2,
                    pCompras_Giros_Cheques_Ger   IN     NUMBER,
                    pOrigen_Fondos               IN     VARCHAR2,
                    pResultado                   IN OUT resultado) IS
      pData   PA.INFO_PROD_SOL_OBJ;
   BEGIN
      pData := PA.INFO_PROD_SOL_OBJ ();
      pData.COD_PERSONA := pCOD_PERSONA;
      pData.TIPO_PRODUCTO := pTIPO_PRODUCTO;
      pData.COD_MONEDA := pCOD_MONEDA;
      pData.PROPOSITO := pPROPOSITO;
      pData.MONTO_INICIAL := pMONTO_INICIAL;
      pData.INSTRUMENTO_BANCARIO := pINSTRUMENTO_BANCARIO;
      pData.RANGO_MONETARIO_INI := pRANGO_MONETARIO_INI;
      pData.RANGO_MONETARIO_FIN := pRANGO_MONETARIO_FIN;
      pData.PROM_MES_DEPO_EFECTIVO := pPROM_MES_DEPO_EFECTIVO;
      pData.PROM_MES_DEPO_CHEQUES := pPROM_MES_DEPO_CHEQUES;
      pData.PROM_MES_RETI_EFECTIVO := pPROM_MES_RETI_EFECTIVO;
      pData.PROM_MES_TRANS_ENVIADA := pPROM_MES_TRANS_ENVIADA;
      pData.COD_PAIS_DESTINO := pCOD_PAIS_DESTINO;
      pData.PROM_MES_TRANS_RECIBIDA := pPROM_MES_TRANS_RECIBIDA;
      pData.COD_PAIS_ORIGEN := pCOD_PAIS_ORIGEN;
      pData.COMPRAS_GIROS_CHEQUES_GER := pCOMPRAS_GIROS_CHEQUES_GER;
      pData.ORIGEN_FONDOS := pORIGEN_FONDOS;

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

   PROCEDURE Actualizar (pCod_Persona                 IN     VARCHAR2,
                         pTipo_Producto               IN     VARCHAR2,
                         pCod_Moneda                  IN     VARCHAR2,
                         pProposito                   IN     VARCHAR2,
                         pMonto_Inicial               IN     NUMBER,
                         pInstrumento_Bancario        IN     VARCHAR2,
                         pRango_Monetario_Ini         IN     NUMBER,
                         pRango_Monetario_Fin         IN     NUMBER,
                         pProm_Mes_Depo_Efectivo      IN     NUMBER,
                         pProm_Mes_Depo_Cheques       IN     NUMBER,
                         pProm_Mes_Reti_Efectivo      IN     NUMBER,
                         pProm_Mes_Trans_Enviada      IN     NUMBER,
                         pCod_Pais_Destino            IN     VARCHAR2,
                         pProm_Mes_Trans_Recibida     IN     NUMBER,
                         pCod_Pais_Origen             IN     VARCHAR2,
                         pCompras_Giros_Cheques_Ger   IN     NUMBER,
                         pOrigen_Fondos               IN     VARCHAR2,
                         pResultado                   IN OUT resultado) IS
      pData   PA.INFO_PROD_SOL_OBJ;
   BEGIN
      pData := PA.INFO_PROD_SOL_OBJ ();
      pData.COD_PERSONA := pCOD_PERSONA;
      pData.TIPO_PRODUCTO := pTIPO_PRODUCTO;
      pData.COD_MONEDA := pCOD_MONEDA;
      pData.PROPOSITO := pPROPOSITO;
      pData.MONTO_INICIAL := pMONTO_INICIAL;
      pData.INSTRUMENTO_BANCARIO := pINSTRUMENTO_BANCARIO;
      pData.RANGO_MONETARIO_INI := pRANGO_MONETARIO_INI;
      pData.RANGO_MONETARIO_FIN := pRANGO_MONETARIO_FIN;
      pData.PROM_MES_DEPO_EFECTIVO := pPROM_MES_DEPO_EFECTIVO;
      pData.PROM_MES_DEPO_CHEQUES := pPROM_MES_DEPO_CHEQUES;
      pData.PROM_MES_RETI_EFECTIVO := pPROM_MES_RETI_EFECTIVO;
      pData.PROM_MES_TRANS_ENVIADA := pPROM_MES_TRANS_ENVIADA;
      pData.COD_PAIS_DESTINO := pCOD_PAIS_DESTINO;
      pData.PROM_MES_TRANS_RECIBIDA := pPROM_MES_TRANS_RECIBIDA;
      pData.COD_PAIS_ORIGEN := pCOD_PAIS_ORIGEN;
      pData.COMPRAS_GIROS_CHEQUES_GER := pCOMPRAS_GIROS_CHEQUES_GER;
      pData.ORIGEN_FONDOS := pORIGEN_FONDOS;

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

   PROCEDURE Borrar (pCod_Persona                 IN     VARCHAR2,
                     pTipo_Producto               IN     VARCHAR2,
                     pProposito                   IN     VARCHAR2,
                     pResultado                   IN OUT resultado) IS
      pData   PA.INFO_PROD_SOL_OBJ;
   BEGIN
      pData := PA.INFO_PROD_SOL_OBJ ();
      pData.COD_PERSONA := pCOD_PERSONA;
      pData.TIPO_PRODUCTO := pTIPO_PRODUCTO;
      pData.PROPOSITO := pPROPOSITO;
      
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

   FUNCTION Consultar (pCod_Persona                 IN VARCHAR2,
                       pTipo_Producto               IN VARCHAR2,
                       pCod_Moneda                  IN VARCHAR2,
                       pProposito                   IN VARCHAR2,
                       pMonto_Inicial               IN NUMBER,
                       pInstrumento_Bancario        IN VARCHAR2,
                       pRango_Monetario_Ini         IN NUMBER,
                       pRango_Monetario_Fin         IN NUMBER,
                       pProm_Mes_Depo_Efectivo      IN NUMBER,
                       pProm_Mes_Depo_Cheques       IN NUMBER,
                       pProm_Mes_Reti_Efectivo      IN NUMBER,
                       pProm_Mes_Trans_Enviada      IN NUMBER,
                       pCod_Pais_Destino            IN VARCHAR2,
                       pProm_Mes_Trans_Recibida     IN NUMBER,
                       pCod_Pais_Origen             IN VARCHAR2,
                       pCompras_Giros_Cheques_Ger   IN NUMBER,
                       pOrigen_Fondos               IN VARCHAR2)
      RETURN PA.INFO_PROD_SOL_LIST IS
      CURSOR cData IS
         SELECT *
           FROM PA.INFO_PROD_SOL t1
          WHERE (t1.COD_PERSONA = pCOD_PERSONA OR pCOD_PERSONA IS NULL)
            AND (t1.TIPO_PRODUCTO = pTIPO_PRODUCTO OR pTIPO_PRODUCTO IS NULL)
            AND (t1.COD_MONEDA = pCOD_MONEDA OR pCOD_MONEDA IS NULL)
            AND (t1.PROPOSITO = pPROPOSITO OR pPROPOSITO IS NULL)
            AND (t1.MONTO_INICIAL = pMONTO_INICIAL OR pMONTO_INICIAL IS NULL)
            AND (t1.INSTRUMENTO_BANCARIO = pINSTRUMENTO_BANCARIO OR pINSTRUMENTO_BANCARIO IS NULL)
            AND (t1.RANGO_MONETARIO_INI = pRANGO_MONETARIO_INI OR pRANGO_MONETARIO_INI IS NULL)
            AND (t1.RANGO_MONETARIO_FIN = pRANGO_MONETARIO_FIN OR pRANGO_MONETARIO_FIN IS NULL)
            AND (t1.PROM_MES_DEPO_EFECTIVO = pPROM_MES_DEPO_EFECTIVO OR pPROM_MES_DEPO_EFECTIVO IS NULL)
            AND (t1.PROM_MES_DEPO_CHEQUES = pPROM_MES_DEPO_CHEQUES OR pPROM_MES_DEPO_CHEQUES IS NULL)
            AND (t1.PROM_MES_RETI_EFECTIVO = pPROM_MES_RETI_EFECTIVO OR pPROM_MES_RETI_EFECTIVO IS NULL)
            AND (t1.PROM_MES_TRANS_ENVIADA = pPROM_MES_TRANS_ENVIADA OR pPROM_MES_TRANS_ENVIADA IS NULL)
            AND (t1.COD_PAIS_DESTINO = pCOD_PAIS_DESTINO OR pCOD_PAIS_DESTINO IS NULL)
            AND (t1.PROM_MES_TRANS_RECIBIDA = pPROM_MES_TRANS_RECIBIDA OR pPROM_MES_TRANS_RECIBIDA IS NULL)
            AND (t1.COD_PAIS_ORIGEN = pCOD_PAIS_ORIGEN OR pCOD_PAIS_ORIGEN IS NULL)
            AND (t1.COMPRAS_GIROS_CHEQUES_GER = pCOMPRAS_GIROS_CHEQUES_GER OR pCOMPRAS_GIROS_CHEQUES_GER IS NULL)
            AND (t1.ORIGEN_FONDOS = pORIGEN_FONDOS OR pORIGEN_FONDOS IS NULL);

      TYPE tData IS TABLE OF cData%ROWTYPE;

      vData       tData := tData();
      vDataList   PA.INFO_PROD_SOL_LIST := PA.INFO_PROD_SOL_LIST ();
      pData       PA.INFO_PROD_SOL_OBJ;
      indice      NUMBER := 0;
   BEGIN      
      
      vDataList.DELETE;

      OPEN cData;

      LOOP
         FETCH cData BULK COLLECT INTO vData LIMIT 5000;

         FOR i IN 1 .. vData.COUNT LOOP
            pData := PA.INFO_PROD_SOL_OBJ ();            
            pData.COD_PERSONA := vData (i).COD_PERSONA;
            pData.TIPO_PRODUCTO := vData (i).TIPO_PRODUCTO;
            pData.COD_MONEDA := vData (i).COD_MONEDA;
            pData.PROPOSITO := vData (i).PROPOSITO;
            pData.MONTO_INICIAL := vData (i).MONTO_INICIAL;
            pData.INSTRUMENTO_BANCARIO := vData (i).INSTRUMENTO_BANCARIO;
            pData.RANGO_MONETARIO_INI := vData (i).RANGO_MONETARIO_INI;
            pData.RANGO_MONETARIO_FIN := vData (i).RANGO_MONETARIO_FIN;
            pData.PROM_MES_DEPO_EFECTIVO := vData (i).PROM_MES_DEPO_EFECTIVO;
            pData.PROM_MES_DEPO_CHEQUES := vData (i).PROM_MES_DEPO_CHEQUES;
            pData.PROM_MES_RETI_EFECTIVO := vData (i).PROM_MES_RETI_EFECTIVO;
            pData.PROM_MES_TRANS_ENVIADA := vData (i).PROM_MES_TRANS_ENVIADA;
            pData.COD_PAIS_DESTINO := vData (i).COD_PAIS_DESTINO;
            pData.PROM_MES_TRANS_RECIBIDA := vData (i).PROM_MES_TRANS_RECIBIDA;
            pData.COD_PAIS_ORIGEN := vData (i).COD_PAIS_ORIGEN;
            pData.COMPRAS_GIROS_CHEQUES_GER := vData (i).COMPRAS_GIROS_CHEQUES_GER;
            pData.ORIGEN_FONDOS := vData (i).ORIGEN_FONDOS;
            indice := indice + 1;
            vDataList.EXTEND;
            vDataList (indice) := pData;
         END LOOP;

         EXIT WHEN cData%NOTFOUND;
      END LOOP;

      CLOSE cData;

      RETURN vDataList;
   END Consultar;

   FUNCTION Existe (pCod_Persona     IN VARCHAR2,
                    pTipo_Producto   IN VARCHAR2,
                    pProposito       IN VARCHAR2)
      RETURN BOOLEAN IS
      pData   PA.INFO_PROD_SOL_OBJ;
   BEGIN
      pData := PA.INFO_PROD_SOL_OBJ ();
      pData.COD_PERSONA := pCOD_PERSONA;
      pData.TIPO_PRODUCTO := pTIPO_PRODUCTO;
      pData.PROPOSITO := pPROPOSITO;
      RETURN pData.Existe ();
   END Existe;

   FUNCTION Validar (pCod_Persona                 IN     VARCHAR2,
                     pTipo_Producto               IN     VARCHAR2,
                     pCod_Moneda                  IN     VARCHAR2,
                     pProposito                   IN     VARCHAR2,
                     pMonto_Inicial               IN     NUMBER,
                     pInstrumento_Bancario        IN     VARCHAR2,
                     pRango_Monetario_Ini         IN     NUMBER,
                     pRango_Monetario_Fin         IN     NUMBER,
                     pProm_Mes_Depo_Efectivo      IN     NUMBER,
                     pProm_Mes_Depo_Cheques       IN     NUMBER,
                     pProm_Mes_Reti_Efectivo      IN     NUMBER,
                     pProm_Mes_Trans_Enviada      IN     NUMBER,
                     pCod_Pais_Destino            IN     VARCHAR2,
                     pProm_Mes_Trans_Recibida     IN     NUMBER,
                     pCod_Pais_Origen             IN     VARCHAR2,
                     pCompras_Giros_Cheques_Ger   IN     NUMBER,
                     pOrigen_Fondos               IN     VARCHAR2,
                     pOperacion                   IN     VARCHAR2,
                     pError                       IN OUT VARCHAR2)
      RETURN BOOLEAN IS
      pData   PA.INFO_PROD_SOL_OBJ;
   BEGIN
      pData := PA.INFO_PROD_SOL_OBJ ();
      pData.COD_PERSONA := pCOD_PERSONA;
      pData.TIPO_PRODUCTO := pTIPO_PRODUCTO;
      pData.COD_MONEDA := pCOD_MONEDA;
      pData.PROPOSITO := pPROPOSITO;
      pData.MONTO_INICIAL := pMONTO_INICIAL;
      pData.INSTRUMENTO_BANCARIO := pINSTRUMENTO_BANCARIO;
      pData.RANGO_MONETARIO_INI := pRANGO_MONETARIO_INI;
      pData.RANGO_MONETARIO_FIN := pRANGO_MONETARIO_FIN;
      pData.PROM_MES_DEPO_EFECTIVO := pPROM_MES_DEPO_EFECTIVO;
      pData.PROM_MES_DEPO_CHEQUES := pPROM_MES_DEPO_CHEQUES;
      pData.PROM_MES_RETI_EFECTIVO := pPROM_MES_RETI_EFECTIVO;
      pData.PROM_MES_TRANS_ENVIADA := pPROM_MES_TRANS_ENVIADA;
      pData.COD_PAIS_DESTINO := pCOD_PAIS_DESTINO;
      pData.PROM_MES_TRANS_RECIBIDA := pPROM_MES_TRANS_RECIBIDA;
      pData.COD_PAIS_ORIGEN := pCOD_PAIS_ORIGEN;
      pData.COMPRAS_GIROS_CHEQUES_GER := pCOMPRAS_GIROS_CHEQUES_GER;
      pData.ORIGEN_FONDOS := pORIGEN_FONDOS;
      RETURN pData.Validar (pOperacion, pError);
   END Validar;
END PKG_INFO_PROD_SOL;
/