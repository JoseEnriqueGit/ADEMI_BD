CREATE OR REPLACE PACKAGE BODY PA.PKG_TIPO_DOCUMENTO_PKM IS
   PROCEDURE Generar(pId_Aplicacion           IN     NUMBER,
                     pId_Tipo_Documento       IN     VARCHAR2,
                     pDescripcion             IN     VARCHAR2,
                     pNombre_Reporte          IN     VARCHAR2,
                     pReutilizable            IN     VARCHAR2,
                     pAutomatico              IN     VARCHAR2,
                     pAdicionado_Por          IN     VARCHAR2,
                     pFecha_Adicion           IN     DATE,
                     pModificado_Por          IN     VARCHAR2,
                     pFecha_Modificacion      IN     DATE,
                     pEstado_Tipo_Documento   IN     VARCHAR2,
                     pEnviar_Api              IN     VARCHAR2,
                     pResultado               IN OUT VARCHAR2) IS
      pData      PA.TIPO_DOCUMENTO_PKM_OBJ;
      vIdError   NUMBER := 0;
   BEGIN
      pData := PA.TIPO_DOCUMENTO_PKM_OBJ();
      pData.ID_APLICACION           := pId_Aplicacion;
      pData.ID_TIPO_DOCUMENTO       := pId_Tipo_Documento;
      pData.DESCRIPCION             := pDescripcion;
      pData.NOMBRE_REPORTE          := pNombre_Reporte;
      pData.REUTILIZABLE            := pReutilizable;
      pData.AUTOMATICO              := pAutomatico;
      pData.ADICIONADO_POR          := pAdicionado_Por;
      pData.FECHA_ADICION           := pFecha_Adicion;
      pData.MODIFICADO_POR          := pModificado_Por;
      pData.FECHA_MODIFICACION      := pFecha_Modificacion;
      pData.ESTADO_TIPO_DOCUMENTO   := pEstado_Tipo_Documento;
      pData.ENVIAR_API              := pEnviar_Api;

      IF pData.Validar('G', pResultado) THEN
         -- Existe
         IF pData.Existe() = FALSE THEN
            -- Insertar
            pData.crear();
         ELSE
            -- Modificar
            pData.Actualizar();
         END IF;

         pResultado := 'Exitoso.';
      END IF;
   EXCEPTION
      WHEN OTHERS THEN
         pResultado := SQLCODE || ': ' || SQLERRM;
         PA.PKG_TIPO_DOCUMENTO_PKM.LogError(
            pData                => pData,
            inProgramUnit        => 'Generar',
            inErrorDescription   => pResultado,
            inErrorTrace         => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,
            outIdError           => vIdError);
         RAISE_APPLICATION_ERROR(-20100, 'Error ' || SQLERRM);
   END Generar;


   PROCEDURE Crear(pId_Aplicacion           IN     NUMBER,
                   pId_Tipo_Documento       IN     VARCHAR2,
                   pDescripcion             IN     VARCHAR2,
                   pNombre_Reporte          IN     VARCHAR2,
                   pReutilizable            IN     VARCHAR2,
                   pAutomatico              IN     VARCHAR2,
                   pAdicionado_Por          IN     VARCHAR2,
                   pFecha_Adicion           IN     DATE,
                   pModificado_Por          IN     VARCHAR2,
                   pFecha_Modificacion      IN     DATE,
                   pEstado_Tipo_Documento   IN     VARCHAR2,
                   pEnviar_Api              IN     VARCHAR2,
                   pResultado               IN OUT VARCHAR2) IS
      pData      PA.TIPO_DOCUMENTO_PKM_OBJ;
      vIdError   NUMBER := 0;
   BEGIN
      pData := PA.TIPO_DOCUMENTO_PKM_OBJ();
      pData.ID_APLICACION           := pId_Aplicacion;
      pData.ID_TIPO_DOCUMENTO       := pId_Tipo_Documento;
      pData.DESCRIPCION             := pDescripcion;
      pData.NOMBRE_REPORTE          := pNombre_Reporte;
      pData.REUTILIZABLE            := pReutilizable;
      pData.AUTOMATICO              := pAutomatico;
      pData.ADICIONADO_POR          := pAdicionado_Por;
      pData.FECHA_ADICION           := pFecha_Adicion;
      pData.MODIFICADO_POR          := pModificado_Por;
      pData.FECHA_MODIFICACION      := pFecha_Modificacion;
      pData.ESTADO_TIPO_DOCUMENTO   := pEstado_Tipo_Documento;
      pData.ENVIAR_API              := pEnviar_Api;

      IF pData.Validar('C', pResultado) THEN
         -- Existe
         IF pData.Existe() = FALSE THEN
            pData.Crear();
            pResultado := 'Exitoso.';
         END IF;
      END IF;
   EXCEPTION
      WHEN OTHERS THEN
         pResultado := SQLCODE || ': ' || SQLERRM;
         PA.PKG_TIPO_DOCUMENTO_PKM.LogError(
            pData                => pData,
            inProgramUnit        => 'Crear',
            inErrorDescription   => pResultado,
            inErrorTrace         => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,
            outIdError           => vIdError);
         RAISE_APPLICATION_ERROR(-20100, 'Error ' || SQLERRM);
   END Crear;


   PROCEDURE Actualizar(pId_Aplicacion           IN     NUMBER,
                        pId_Tipo_Documento       IN     VARCHAR2,
                        pDescripcion             IN     VARCHAR2,
                        pNombre_Reporte          IN     VARCHAR2,
                        pReutilizable            IN     VARCHAR2,
                        pAutomatico              IN     VARCHAR2,
                        pAdicionado_Por          IN     VARCHAR2,
                        pFecha_Adicion           IN     DATE,
                        pModificado_Por          IN     VARCHAR2,
                        pFecha_Modificacion      IN     DATE,
                        pEstado_Tipo_Documento   IN     VARCHAR2,
                        pEnviar_Api              IN     VARCHAR2,
                        pResultado               IN OUT VARCHAR2) IS
      pData      PA.TIPO_DOCUMENTO_PKM_OBJ;
      vIdError   NUMBER := 0;
   BEGIN
      pData := PA.TIPO_DOCUMENTO_PKM_OBJ();
      pData.ID_APLICACION           := pId_Aplicacion;
      pData.ID_TIPO_DOCUMENTO       := pId_Tipo_Documento;
      pData.DESCRIPCION             := pDescripcion;
      pData.NOMBRE_REPORTE          := pNombre_Reporte;
      pData.REUTILIZABLE            := pReutilizable;
      pData.AUTOMATICO              := pAutomatico;
      pData.ADICIONADO_POR          := pAdicionado_Por;
      pData.FECHA_ADICION           := pFecha_Adicion;
      pData.MODIFICADO_POR          := pModificado_Por;
      pData.FECHA_MODIFICACION      := pFecha_Modificacion;
      pData.ESTADO_TIPO_DOCUMENTO   := pEstado_Tipo_Documento;
      pData.ENVIAR_API              := pEnviar_Api;

      IF pData.Validar('U', pResultado) THEN
         -- Existe
         IF pData.Existe() = TRUE THEN
            pData.Actualizar();
            pResultado := 'Exitoso.';
         END IF;
      END IF;
   EXCEPTION
      WHEN OTHERS THEN
         pResultado := SQLCODE || ': ' || SQLERRM;
         PA.PKG_TIPO_DOCUMENTO_PKM.LogError(
            pData                => pData,
            inProgramUnit        => 'Actualizar',
            inErrorDescription   => pResultado,
            inErrorTrace         => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,
            outIdError           => vIdError);
         RAISE_APPLICATION_ERROR(-20100, 'Error ' || SQLERRM);
   END Actualizar;

   PROCEDURE Borrar(pId_Aplicacion       IN     NUMBER,
                    pId_Tipo_Documento   IN     VARCHAR2,
                    pResultado           IN OUT VARCHAR2) IS
      pData      PA.TIPO_DOCUMENTO_PKM_OBJ;
      vIdError   NUMBER := 0;
   BEGIN
      pData := PA.TIPO_DOCUMENTO_PKM_OBJ();
      pData.ID_APLICACION       := pId_Aplicacion;
      pData.ID_TIPO_DOCUMENTO   := pId_Tipo_Documento;

      IF pData.Validar('D', pResultado) THEN
         -- Existe
         IF pData.Existe() = TRUE THEN
            pData.Borrar();
            pResultado := 'Exitoso.';
         END IF;
      END IF;
   EXCEPTION
      WHEN OTHERS THEN
         pResultado := SQLCODE || ': ' || SQLERRM;
         PA.PKG_TIPO_DOCUMENTO_PKM.LogError(
            pData                => pData,
            inProgramUnit        => 'Borrar',
            inErrorDescription   => pResultado,
            inErrorTrace         => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,
            outIdError           => vIdError);
         RAISE_APPLICATION_ERROR(-20100, 'Error ' || SQLERRM);
   END Borrar;


   FUNCTION Consultar(pId_Aplicacion           IN     NUMBER,
                      pId_Tipo_Documento       IN     VARCHAR2,
                      pDescripcion             IN     VARCHAR2,
                      pNombre_Reporte          IN     VARCHAR2,
                      pReutilizable            IN     VARCHAR2,
                      pAutomatico              IN     VARCHAR2,
                      pAdicionado_Por          IN     VARCHAR2,
                      pFecha_Adicion           IN     DATE,
                      pModificado_Por          IN     VARCHAR2,
                      pFecha_Modificacion      IN     DATE,
                      pEstado_Tipo_Documento   IN     VARCHAR2,
                      pEnviar_Api              IN     VARCHAR2,
                      pResultado               IN OUT VARCHAR2)
      RETURN PA.TIPO_DOCUMENTO_PKM_LIST IS
      CURSOR cData IS
         SELECT *
           FROM PA.PA_TIPO_DOCUMENTO_PKM t1
          WHERE (t1.ID_APLICACION = pId_Aplicacion OR pId_Aplicacion IS NULL)
            AND (t1.ID_TIPO_DOCUMENTO = pId_Tipo_Documento OR pId_Tipo_Documento IS NULL)
            AND (t1.DESCRIPCION = pDescripcion OR pDescripcion IS NULL)
            AND (t1.NOMBRE_REPORTE = pNombre_Reporte OR pNombre_Reporte IS NULL)
            AND (t1.REUTILIZABLE = pReutilizable OR pReutilizable IS NULL)
            AND (t1.AUTOMATICO = pAutomatico OR pAutomatico IS NULL)
            AND (t1.ADICIONADO_POR = pAdicionado_Por OR pAdicionado_Por IS NULL)
            AND (t1.FECHA_ADICION = pFecha_Adicion OR pFecha_Adicion IS NULL)
            AND (t1.MODIFICADO_POR = pModificado_Por OR pModificado_Por IS NULL)
            AND (t1.FECHA_MODIFICACION = pFecha_Modificacion OR pFecha_Modificacion IS NULL)
            AND (t1.ESTADO_TIPO_DOCUMENTO = pEstado_Tipo_Documento OR pEstado_Tipo_Documento IS NULL)
            AND (t1.ENVIAR_API = pEnviar_Api OR pEnviar_Api IS NULL);

      TYPE tData IS TABLE OF cData%ROWTYPE;

      vData       tData;
      vDataList   PA.TIPO_DOCUMENTO_PKM_LIST := PA.TIPO_DOCUMENTO_PKM_LIST();
      pData       PA.TIPO_DOCUMENTO_PKM_OBJ;
      indice      NUMBER := 0;
      vIdError    NUMBER := 0;
   BEGIN
      vDataList.DELETE;

      OPEN cData;

      LOOP
         FETCH cData BULK COLLECT INTO vData LIMIT 5000;

         FOR i IN 1 .. vData.COUNT LOOP
            pData := PA.TIPO_DOCUMENTO_PKM_OBJ();
            pData.ID_APLICACION         := vData(i).ID_APLICACION;
            pData.ID_TIPO_DOCUMENTO     := vData(i).ID_TIPO_DOCUMENTO;
            pData.DESCRIPCION           := vData(i).DESCRIPCION;
            pData.NOMBRE_REPORTE        := vData(i).NOMBRE_REPORTE;
            pData.REUTILIZABLE          := vData(i).REUTILIZABLE;
            pData.AUTOMATICO            := vData(i).AUTOMATICO;
            pData.ADICIONADO_POR        := vData(i).ADICIONADO_POR;
            pData.FECHA_ADICION         := vData(i).FECHA_ADICION;
            pData.MODIFICADO_POR        := vData(i).MODIFICADO_POR;
            pData.FECHA_MODIFICACION    := vData(i).FECHA_MODIFICACION;
            pData.ESTADO_TIPO_DOCUMENTO := vData(i).ESTADO_TIPO_DOCUMENTO;
            pData.ENVIAR_API            := vData(i).ENVIAR_API;
            indice := indice + i;
            vDataList.EXTEND;
            vDataList(indice) := pData;
         END LOOP;

         EXIT WHEN cData%NOTFOUND;
      END LOOP;

      CLOSE cData;

      pResultado := 'Exitoso.';
      RETURN vDataList;
   EXCEPTION
      WHEN OTHERS THEN
         pResultado := SQLCODE || ': ' || SQLERRM;
         PA.PKG_TIPO_DOCUMENTO_PKM.LogError(
            pData                => pData,
            inProgramUnit        => 'Consultar',
            inErrorDescription   => pResultado,
            inErrorTrace         => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,
            outIdError           => vIdError);
         RAISE_APPLICATION_ERROR(-20404, 'Error ' || SQLERRM);
   END Consultar;

   FUNCTION Comparar(pData1       IN OUT PA.TIPO_DOCUMENTO_PKM_OBJ,
                     pData2       IN OUT PA.TIPO_DOCUMENTO_PKM_OBJ,
                     pModo        IN     VARCHAR2,
                     pResultado   IN OUT VARCHAR2)
      -- O = (Compare between Objects pData1 and pData2),
      -- T = (Compare pData1 and Table data "Must used pData2 like search parameter in table)
      RETURN BOOLEAN IS
      vIgual      BOOLEAN := FALSE;
      vDataList   PA.TIPO_DOCUMENTO_PKM_LIST := PA.TIPO_DOCUMENTO_PKM_LIST();
      vData       PA.TIPO_DOCUMENTO_PKM_OBJ := PA.TIPO_DOCUMENTO_PKM_OBJ();
      vIdError    NUMBER := 0;
   BEGIN
      IF pModo = 'O' THEN
         IF pData1 IS NOT NULL AND pData2 IS NOT NULL THEN
            vIgual := pData1.Compare(pData2);
         ELSE
            vIgual := TRUE;
         END IF;
      ELSIF pModo = 'T' THEN
         vDataList :=
            Consultar(
               pId_Aplicacion          => pData2.ID_APLICACION,
               pId_Tipo_Documento      => pData2.ID_TIPO_DOCUMENTO,
               pDescripcion            => pData2.DESCRIPCION,
               pNombre_Reporte         => pData2.NOMBRE_REPORTE,
               pReutilizable           => pData2.REUTILIZABLE,
               pAutomatico             => pData2.AUTOMATICO,
               pAdicionado_Por         => pData2.ADICIONADO_POR,
               pFecha_Adicion          => pData2.FECHA_ADICION,
               pModificado_Por         => pData2.MODIFICADO_POR,
               pFecha_Modificacion     => pData2.FECHA_MODIFICACION,
               pEstado_Tipo_Documento  => pData2.ESTADO_TIPO_DOCUMENTO,
               pEnviar_Api             => pData2.ENVIAR_API,
               pResultado              => pResultado);

         IF vDataList.COUNT > 0 THEN
            vData := vDataList(1);
            vIgual := pData1.Compare(vData);
         ELSE
            vIgual := FALSE;
         END IF;
      END IF;

      pResultado := 'Exitoso.';
      RETURN vIgual;
   END Comparar;

   FUNCTION Existe(pId_Aplicacion       IN     NUMBER,
                   pId_Tipo_Documento   IN     VARCHAR2,
                   pResultado           IN OUT VARCHAR2)
      RETURN BOOLEAN IS
      pData      PA.TIPO_DOCUMENTO_PKM_OBJ;
      vIdError   NUMBER := 0;
   BEGIN
      pData := PA.TIPO_DOCUMENTO_PKM_OBJ();
      pData.ID_APLICACION       := pId_Aplicacion;
      pData.ID_TIPO_DOCUMENTO   := pId_Tipo_Documento;
      pResultado                := 'Exitoso.';
      RETURN pData.Existe();
   EXCEPTION
      WHEN OTHERS THEN
         pResultado := SQLCODE || ': ' || SQLERRM;
         PA.PKG_TIPO_DOCUMENTO_PKM.LogError(
            pData                => pData,
            inProgramUnit        => 'Existe',
            inErrorDescription   => pResultado,
            inErrorTrace         => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,
            outIdError           => vIdError);
         RAISE_APPLICATION_ERROR(-20404, 'Error ' || SQLERRM);
   END Existe;

   FUNCTION Validar(pId_Aplicacion           IN     NUMBER,
                    pId_Tipo_Documento       IN     VARCHAR2,
                    pDescripcion             IN     VARCHAR2,
                    pNombre_Reporte          IN     VARCHAR2,
                    pReutilizable            IN     VARCHAR2,
                    pAutomatico              IN     VARCHAR2,
                    pAdicionado_Por          IN     VARCHAR2,
                    pFecha_Adicion           IN     DATE,
                    pModificado_Por          IN     VARCHAR2,
                    pFecha_Modificacion      IN     DATE,
                    pEstado_Tipo_Documento   IN     VARCHAR2,
                    pEnviar_Api              IN     VARCHAR2,
                    pOperacion               IN     VARCHAR2, -- G=Generar, C=Crear, U=Actualizar, D=Borrar
                    pError                   IN OUT VARCHAR2)
      RETURN BOOLEAN IS
      pData      PA.TIPO_DOCUMENTO_PKM_OBJ;
      vValidar   BOOLEAN := FALSE;
      vIdError   NUMBER := 0;
   BEGIN
      pData := PA.TIPO_DOCUMENTO_PKM_OBJ();
      pData.ID_APLICACION         := pId_Aplicacion;
      pData.ID_TIPO_DOCUMENTO     := pId_Tipo_Documento;
      pData.DESCRIPCION           := pDescripcion;
      pData.NOMBRE_REPORTE        := pNombre_Reporte;
      pData.REUTILIZABLE          := pReutilizable;
      pData.AUTOMATICO            := pAutomatico;
      pData.ADICIONADO_POR        := pAdicionado_Por;
      pData.FECHA_ADICION         := pFecha_Adicion;
      pData.MODIFICADO_POR        := pModificado_Por;
      pData.FECHA_MODIFICACION    := pFecha_Modificacion;
      pData.ESTADO_TIPO_DOCUMENTO := pEstado_Tipo_Documento;
      pData.ENVIAR_API            := pEnviar_Api;
      vValidar                    := pData.Validar(pOperacion, pError);
      
      PA.PKG_TIPO_DOCUMENTO_PKM.LogError(
         pData                => pData,
         inProgramUnit        => 'Validar',
         inErrorDescription   => pError,
         inErrorTrace         => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,
         outIdError           => vIdError);
         
      RETURN vValidar;
   END Validar;
   
   FUNCTION UrlConozcaSuCliente(pCodCliente   IN VARCHAR2, pEmpresa IN VARCHAR2) 
      RETURN VARCHAR2 IS
        vURL            varchar2(2000);
        vParametros     varchar2(2000) := null;
        vFormato_salida varchar2(20) := 'PDF';
    BEGIN        
        vParametros := 'CustomerId='|| pCodCliente || CHR(38) || 'CompanyId='||pEmpresa;
        vURL := ia.f_reporte_ssrs ('LV', 'FCSCPF', vFormato_salida, vParametros );  
        RETURN vURL;
    END UrlConozcaSuCliente;

   FUNCTION UrlConozcaSuCliente2(pCodCliente   IN VARCHAR2, pEmpresa IN VARCHAR2) 
      RETURN VARCHAR2 IS
        vURL            varchar2(2000);
        vParametros     varchar2(2000) := null;
        vFormato_salida varchar2(20) := 'PDF';
    BEGIN        
        vParametros := 'CustomerId='|| pCodCliente || CHR(38) || 'CompanyId='||pEmpresa;
        vURL := ia.f_reporte_ssrs ('LV', 'FCSCPF_OnBoarding', vFormato_salida, vParametros );  
        RETURN vURL;
    END UrlConozcaSuCliente2;
    
    FUNCTION UrlMatrizRiesgo(pCodCliente   IN VARCHAR2) 
      RETURN VARCHAR2 IS
        vURL            varchar2(2000);
        vParametros     varchar2(2000) := null;
        vFormato_salida varchar2(20) := 'PDF';
    BEGIN        
        vParametros := 'pCodPersona='|| pCodCliente;
        vURL := ia.f_reporte_ssrs ('LV', 'MRAVPF', vFormato_salida, vParametros );  
        RETURN vURL;
    END UrlMatrizRiesgo;
    
    FUNCTION UrlSolicitudTarjeta(pNoSolicitud   IN NUMBER) 
      RETURN VARCHAR2 IS
        vURL            varchar2(2000);
        vParametros     varchar2(2000) := null;
        vFormato_salida varchar2(20) := 'PDF';
    BEGIN
        vParametros     := 'p_NoSolicitud='||pNoSolicitud;
        vURL := ia.f_reporte_ssrs ('TC', 'SolicitudTarjeta', vFormato_salida, vParametros);
        RETURN vURL;
    END UrlSolicitudTarjeta;    
    
    FUNCTION UrlFec(pId_tempfec   IN NUMBER,
                               p_nomarchivo  IN VARCHAR2) 
      RETURN VARCHAR2 IS
        vURL            varchar2(2000);
        vParametros     varchar2(2000) := null;
        vFormato_salida varchar2(20) := 'PDF';
    BEGIN
        vParametros     := 'P_IDTEMPFEC='||pId_tempfec || CHR(38) || 'P_NOMARCHIVO='||p_nomarchivo;
        vURL := ia.f_reporte_ssrs ('PR', 'FEC_CLIENTE', vFormato_salida, vParametros);
        RETURN vURL;
    END UrlFec;
    
    FUNCTION UrlFecFiador(pId_tempfec   IN NUMBER,
                               p_nomarchivo  IN VARCHAR2) 
      RETURN VARCHAR2 IS
        vURL            varchar2(2000);
        vParametros     varchar2(2000) := null;
        vFormato_salida varchar2(20) := 'PDF';
    BEGIN
        vParametros     := 'P_IDTEMPFEC='||pId_tempfec || CHR(38) || 'P_NOMARCHIVO='||p_nomarchivo;
        vURL := ia.f_reporte_ssrs ('PR', 'FEC_FI', vFormato_salida, vParametros);
        RETURN vURL;
    END UrlFecFiador;
    
    FUNCTION UrlFudReprestamos(pId_tempfud   IN NUMBER,
                               p_nomarchivo  IN VARCHAR2) 
      RETURN VARCHAR2 IS
        vURL            varchar2(2000);
        vParametros     varchar2(2000) := null;
        vFormato_salida varchar2(20) := 'PDF';
    BEGIN
        vParametros     := 'p_IDTEMPFUD='||pId_tempfud || CHR(38) || 'p_NOMARCHIVO='||p_nomarchivo;
        vURL := ia.f_reporte_ssrs ('PR', 'FUD', vFormato_salida, vParametros);
        RETURN vURL;
    END UrlFudReprestamos;
    
    FUNCTION UrlFecReprestamos(pIdReprestamo   IN NUMBER) 
      RETURN VARCHAR2 IS
        vURL            varchar2(2000);
        vParametros     varchar2(2000) := null;
        vFormato_salida varchar2(20) := 'PDF';
    BEGIN
        vParametros     := 'p_ID_REPRESTAMO='||pIdReprestamo;
        vURL := ia.f_reporte_ssrs ('PR', 'rptFEC_Represtamos', vFormato_salida, vParametros);
        RETURN vURL;
    END UrlFecReprestamos;
    
    FUNCTION UrlLexisNexis(pNombres  IN VARCHAR2, pApellidos IN VARCHAR2, pIdentificacion  IN VARCHAR2)
     RETURN VARCHAR2 IS
        vURL            varchar2(2000);
        vParametros     varchar2(2000) := null;
        vFormato_salida varchar2(20) := 'PDF';
    BEGIN
        vParametros     := 'NATIONALID='||pIdentificacion|| CHR(38) || 'FIRSTNAME='||pNombres||CHR(38) || 'LASTNAME='||pApellidos;
        vURL := ia.f_reporte_ssrs ('PR', 'rptLexisNexis', vFormato_salida, vParametros);
        RETURN vURL;
    END;
    
  procedure inserturlreporte(pcodigoreferencia in  varchar2,
                               pfechareporte  in     date,
                               pid_aplicacion in     number,
                               pidtipodocumento in   varchar2,
                               porigenpkm     in     varchar2,
                               purlreporte    in     varchar2,
                               pformatodocumento in  varchar2,
                               pnombrearchivo in     varchar2,
                               pestado        in     varchar2 default 'P',
                               prespuesta     in out varchar2) IS
        vDirectorio   VARCHAR2(256) := NVL(PA.PARAM.PARAMETRO_X_EMPRESA('1', 'DIR_REPORTES', 'IA'), 'RPT_REGULATORIOS'); --IA.EVERTEC_FCP_v2.getRutaFisica( NVL(PA.PARAM.PARAMETRO_X_EMPRESA('DIR_REPORTES'), 'RPT_REGULATORIOS'));
        vEnviarAPI    VARCHAR2(2);
        v_codigo_reporte  NUMBER; 
        v_tipo_identificacion VARCHAR2(5);
        v_identificacion  VARCHAR2(30);
        v_num_prestamo  VARCHAR2(40); 
        v_prest_anterior VARCHAR2(40);
        v_Id_tempfud    VARCHAR2(30); 
        v_tipo_archivo VARCHAR2(40); 
        v_nombre_archivo VARCHAR2(60); 
        v_codigo_agencia	 VARCHAR2(60); 
        v_nombre_agencia	 VARCHAR2(60); 
        v_primer_nombre	     VARCHAR2(60); 
        v_segundo_nombre	 VARCHAR2(60); 
        v_primer_apellido	 VARCHAR2(60); 
        v_segundo_apellido	 VARCHAR2(60); 
        v_nacionalidad       VARCHAR2(60);   
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
            INSERT INTO PA.PA_REPORTES_AUTOMATICOS
            ( CODIGO_REFERENCIA, FECHA_REPORTE, ID_APLICACION, ID_TIPO_DOCUMENTO, ORIGEN_PKM, URL_REPORTE, FORMATO_DOCUMENTO, DIRECTORIO_DESTINO, NOMBRE_ARCHIVO, ENVIAR_API, ESTADO_REPORTE, FECHA_PROCESO )  
            VALUES ( pCodigoReferencia, pFechaReporte, pId_Aplicacion, pIdTipoDocumento, pOrigenPkm, pUrlReporte, pFormatoDocumento, vDirectorio, pNombreArchivo, NVL(vEnviarAPI,'S'), NVL(pEstado,'P'), SYSDATE );
        EXCEPTION WHEN OTHERS THEN
            pRespuesta := 'Error: '||SQLERRM;
            RAISE_APPLICATION_ERROR(-20100, pRespuesta);
        END;  
        
       SELECT  r.codigo_reporte,
               r.tipo_identificacion,
               r.identificacion,
               r.f_num_prestamo,
               r.f_prest_anterior,
               r.tipo_archivo,
               r.id_tempfud,
               r.nombre_archivo,
               r.codigo_agencia,
               (select a.descripcion from pa.agencia a where a.cod_empresa = '1' and a.cod_agencia = r.codigo_agencia) as nombre_agencia,
               (select pf.primer_nombre
                   from pa.personas_fisicas pf, pa.id_personas i
                  where pf.cod_per_fisica = i.cod_persona
                    and i.cod_tipo_id = r.tipo_identificacion 
                    and i.num_id = r.identificacion) as primer_nombre,
               (select pf.segundo_nombre
                   from pa.personas_fisicas pf, pa.id_personas i
                  where pf.cod_per_fisica = i.cod_persona
                    and i.cod_tipo_id = r.tipo_identificacion 
                    and i.num_id = r.identificacion) as segundo_nombre,
                (select pf.primer_apellido
                   from pa.personas_fisicas pf, pa.id_personas i
                  where pf.cod_per_fisica = i.cod_persona
                    and i.cod_tipo_id = r.tipo_identificacion 
                    and i.num_id = r.identificacion) as primer_apellido,
                (select pf.segundo_apellido
                   from pa.personas_fisicas pf, pa.id_personas i
                  where pf.cod_per_fisica = i.cod_persona
                    and i.cod_tipo_id = r.tipo_identificacion 
                    and i.num_id = r.identificacion) as segundo_apellido,
               (select nvl(i.nacionalidad, pf.nacionalidad)
                  from pa.personas_fisicas pf, pa.id_personas i
                 where pf.cod_per_fisica = i.cod_persona
                   and i.cod_tipo_id = r.tipo_identificacion
                   and i.num_id =  r.identificacion) as nacionalidad 
       INTO v_codigo_reporte	 ,
            v_tipo_identificacion,	
            v_identificacion	 ,
            v_num_prestamo	     ,
            v_prest_anterior	 ,
            v_tipo_archivo	     ,
            v_id_tempfud	     ,
            v_nombre_archivo	 ,
            v_codigo_agencia	 ,
            v_nombre_agencia	 ,
            v_primer_nombre	     ,
            v_segundo_nombre	 ,
            v_primer_apellido	 ,
            v_segundo_apellido	 ,
            v_nacionalidad
        from (
                SELECT r.CODIGO_REPORTE, 
                       r.CODIGO_REFERENCIA, 
                       r.ORIGEN_PKM,
                           case when r.ORIGEN_PKM in ('Normal','Represtamo') then 
                                nvl(ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1), '1')
                                WHEN R.ORIGEN_PKM IN ('Onboarding', 'TarjetaPC', 'Tarjeta') THEN
                                  CASE WHEN r.URL_REPORTE is not null THEN
                                    (SELECT st.COD_TIPO_ID
                                       FROM TC.TC_SOLICITUD_TARJETA st 
                                      WHERE st.no_solicitud =  ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1)
                                    )
                                    ELSE
                                        nvl(ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1), '1')
                                  END 
                           end as tipo_identificacion,            
                           case when r.ORIGEN_PKM in ('Normal','Represtamo') then 
                                    pa.formatear_identificacion(ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 2), 
                                                                (select mascara from tipos_id where cod_tipo_id = ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1)), 
                                                                'ESPA') 
                                WHEN R.ORIGEN_PKM IN ('Onboarding', 'TarjetaPC', 'Tarjeta') THEN 
                                    case when r.url_reporte is not null then
                                        (select st.num_id
                                           from tc.tc_solicitud_tarjeta st 
                                          WHERE st.no_solicitud =  ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1)
                                        )
                                    ELSE
                                        pa.formatear_identificacion(ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 2),
                                                                    (select mascara from tipos_id where cod_tipo_id = ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 1)), 
                                                                    'ESPA') 
                                    END
                           end as identificacion,
                           case when r.ORIGEN_PKM in ('Normal','Represtamo') then 
                                    ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 3)
                                WHEN R.ORIGEN_PKM IN ('Onboarding', 'TarjetaPC', 'Tarjeta') THEN                      
                                    ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', CASE WHEN r.url_reporte is not null THEN 1 ELSE 3 END)                
                           end as f_num_prestamo,
                           ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 4) as f_prest_anterior,
                           substr(replace(r.nombre_archivo, ':', '_'), 1, instr(replace(r.nombre_archivo, ':', '_'), '_') - 1) as tipo_archivo,
                           ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', 6) as id_tempfud,
                           replace(r.nombre_archivo, ':', '_') as nombre_archivo,
                           case when r.origen_pkm in ('Normal','Represtamo') then
                                    (select cr.codigo_agencia 
                                       from pr.pr_creditos cr 
                                      where cr.codigo_empresa = '1' 
                                        and cr.no_credito = ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', case when r.url_reporte is null then 3 else 1 end)
                                    )
                                WHEN R.ORIGEN_PKM IN ('Onboarding', 'TarjetaPC', 'Tarjeta') THEN 
                                    (SELECT to_number(st.oficina) 
                                       FROM TC.TC_SOLICITUD_TARJETA st 
                                      WHERE st.no_solicitud =  ia.pkg_api_pkm.obtienepartereferencia(r.codigo_referencia, ':', CASE WHEN r.url_reporte is not null THEN 1 ELSE 3 END)                                                               
                                    )
                           END  as codigo_agencia                               
                        from PA.PA_REPORTES_AUTOMATICOS r) r
        WHERE R.CODIGO_REPORTE = (SELECT MAX(x.codigo_reporte) FROM PA.PA_REPORTES_AUTOMATICOS X);
        
        InsertAutoIndexado
        (
          v_codigo_reporte,
          pId_Aplicacion,
          pIdTipoDocumento,
          v_tipo_identificacion,	
          v_identificacion	 ,
          v_num_prestamo       ,
          v_prest_anterior     ,
          v_tipo_archivo         ,
          v_Id_tempfud           ,
          pOrigenPkm             ,
          pUrlReporte          ,
          v_nombre_archivo       ,
          pCodigoReferencia    ,
          NVL(vEnviarAPI,'S')     ,
          v_codigo_agencia       ,
          v_nombre_agencia       ,
          NVL(pEstado,'P')       ,
          v_primer_nombre        ,
          v_segundo_nombre       ,
          v_primer_apellido      ,
          v_segundo_apellido     ,
          v_nacionalidad         ,
          NULL ,
          pRespuesta 
        );  
        
   END InsertUrlReporte;   
   
   PROCEDURE InsertAutoIndexado
(
  p_CODIGO_REPORTE       NUMBER,
  p_APPLICATIONID        NUMBER,
  p_F_DOCUMENT_TYPE      VARCHAR2,
  p_TIPO_IDENTIFICACION  VARCHAR2,
  p_IDENTIFICACION       VARCHAR2,
  p_F_NUM_PRESTAMO       VARCHAR2,
  p_F_PREST_ANTERIOR     VARCHAR2,
  p_TIPO_ARCHIVO         VARCHAR2,
  p_ID_TEMPFUD           VARCHAR2,
  p_F_ORIGEN             VARCHAR2,
  p_URL_REPORTE          VARCHAR2,
  p_NOMBRE_ARCHIVO       VARCHAR2,
  p_CODIGO_REFERENCIA    VARCHAR2,
  p_ENVIAR_API           VARCHAR2,
  p_CODIGO_AGENCIA       NUMBER,
  p_NOMBRE_AGENCIA       VARCHAR2,
  p_ESTADO_REPORTE       VARCHAR2,
  p_PRIMER_NOMBRE        VARCHAR2,
  p_SEGUNDO_NOMBRE       VARCHAR2,
  p_PRIMER_APELLIDO      VARCHAR2,
  p_SEGUNDO_APELLIDO     VARCHAR2,
  p_NACIONALIDAD         VARCHAR2,
  p_IDPROCESO            VARCHAR2,
  pRespuesta             IN OUT VARCHAR2
) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    vExiste         NUMBER := 0;
BEGIN
    select count(1) INTO vExiste from PA.PA_AUTO_INDEXADO a where a.CODIGO_REPORTE = P_CODIGO_REPORTE;

    IF NVL(vExiste,0) = 0 THEN
    
        INSERT INTO PA.PA_AUTO_INDEXADO
        (
          CODIGO_REPORTE       ,
          APPLICATIONID        ,
          F_DOCUMENT_TYPE      ,
          TIPO_IDENTIFICACION  ,
          IDENTIFICACION       ,
          F_NUM_PRESTAMO       ,
          F_PREST_ANTERIOR     ,
          TIPO_ARCHIVO         ,
          ID_TEMPFUD           ,
          F_ORIGEN             ,
          URL_REPORTE          ,
          NOMBRE_ARCHIVO       ,
          CODIGO_REFERENCIA    , 
          ENVIAR_API           ,
          CODIGO_AGENCIA       ,
          NOMBRE_AGENCIA       ,
          ESTADO_REPORTE       ,
          PRIMER_NOMBRE        ,
          SEGUNDO_NOMBRE       ,
          PRIMER_APELLIDO      ,
          SEGUNDO_APELLIDO     ,
          NACIONALIDAD         ,
          IDPROCESO            
        ) VALUES
        (
          P_CODIGO_REPORTE       ,
          P_APPLICATIONID        ,
          P_F_DOCUMENT_TYPE      ,
          P_TIPO_IDENTIFICACION  ,
          P_IDENTIFICACION       ,
          P_F_NUM_PRESTAMO       ,
          P_F_PREST_ANTERIOR     ,
          P_TIPO_ARCHIVO         ,
          P_ID_TEMPFUD           ,
          P_F_ORIGEN             ,
          P_URL_REPORTE          ,
          P_NOMBRE_ARCHIVO       ,
          P_CODIGO_REFERENCIA    , 
          P_ENVIAR_API           ,
          P_CODIGO_AGENCIA       ,
          P_NOMBRE_AGENCIA       ,
          P_ESTADO_REPORTE       ,
          P_PRIMER_NOMBRE        ,
          P_SEGUNDO_NOMBRE       ,
          P_PRIMER_APELLIDO      ,
          P_SEGUNDO_APELLIDO     ,
          P_NACIONALIDAD         ,
          P_IDPROCESO            
        );
    end if;
    COMMIT;
    
EXCEPTION WHEN OTHERS THEN
    ROLLBACK;
    pRespuesta := 'Error: '||SQLERRM;
    RAISE_APPLICATION_ERROR(-20100, pRespuesta);
END;

   PROCEDURE LogError(pData                IN OUT PA.TIPO_DOCUMENTO_PKM_OBJ,
                      inProgramUnit        IN     IA.LOG_ERROR.PROGRAMUNIT%TYPE,
                      inErrorDescription   IN     VARCHAR2,
                      inErrorTrace         IN     CLOB,
                      outIdError              OUT NUMBER) IS
      pPackageName   CONSTANT IA.LOG_ERROR.PACKAGENAME%TYPE := 'PA.PKG_TIPO_DOCUMENTO_PKM' ;
   BEGIN
      IA.LOGGER.ADDPARAMVALUEV('pId_Aplicacion', pData.Id_Aplicacion);
      IA.LOGGER.ADDPARAMVALUEV('pId_Tipo_Documento', pData.Id_Tipo_Documento);
      IA.LOGGER.ADDPARAMVALUEV('pDescripcion', pData.Descripcion);
      IA.LOGGER.ADDPARAMVALUEV('pNombre_Reporte', pData.Nombre_Reporte);
      IA.LOGGER.ADDPARAMVALUEV('pReutilizable', pData.Reutilizable);
      IA.LOGGER.ADDPARAMVALUEV('pAutomatico', pData.Automatico);
      IA.LOGGER.ADDPARAMVALUEV('pAdicionado_Por', pData.Adicionado_Por);
      IA.LOGGER.ADDPARAMVALUEV('pFecha_Adicion', pData.Fecha_Adicion);
      IA.LOGGER.ADDPARAMVALUEV('pModificado_Por', pData.Modificado_Por);
      IA.LOGGER.ADDPARAMVALUEV('pFecha_Modificacion', pData.Fecha_Modificacion);
      IA.LOGGER.ADDPARAMVALUEV('pEstado_Tipo_Documento', pData.Estado_Tipo_Documento);
      IA.LOGGER.ADDPARAMVALUEV('pEnviar_Api', pData.Enviar_Api);
      IA.LOGGER.LOG(inOWNER               => SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA'),
                    inPACKAGENAME         => pPackageName,
                    inPROGRAMUNIT         => inProgramUnit,
                    inPIECECODENAME       => NULL,
                    inERRORDESCRIPTION    => inErrorDescription,
                    inERRORTRACE          => inErrorTrace,
                    inEMAILNOTIFICATION   => NULL,
                    inPARAMLIST           => IA.LOGGER.vPARAMLIST,
                    inOUTPUTLOGGER        => FALSE,
                    inEXECUTIONTIME       => NULL,
                    outIdError            => outIdError);


      IF IA.LOGGER.VPARAMLIST.COUNT > 0 THEN
         IA.LOGGER.VPARAMLIST.DELETE;
      END IF;
   END LogError;
END PKG_TIPO_DOCUMENTO_PKM;
/

