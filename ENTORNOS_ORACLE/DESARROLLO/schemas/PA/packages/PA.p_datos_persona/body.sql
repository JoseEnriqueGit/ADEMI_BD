CREATE OR REPLACE PACKAGE BODY PA.p_datos_persona Is
   Function obt_scoring_persona(
      p_codpersona                        Varchar2,
      p_tipscoring                        Varchar2 )
      Return Number Is
      /*
         OBJETIVO
          Retorna el scoring de la persona. En caso de error retorna -1. En caso de que no este
          definido el scoring retorna 0.
         REQUIERE
          p_codpersona    -- Codigo de la persona
          p_tipScoring    -- Tipo del scoring que se desea accesar
         HISTORIA
          Erick Villalobos 06-11-1997
      */
      Cursor scoring_personas Is
         Select puntaje_scoring
           From scoring_x_persona
          Where cod_persona = p_codpersona
            And tipo_scoring = p_tipscoring;
      v_scoring                     scoring_x_persona.puntaje_scoring%Type;
   Begin
      Open scoring_personas;
      Fetch scoring_personas
       Into v_scoring;
      Close scoring_personas;
      Return Nvl( v_scoring, 0 );
   Exception
      When Others Then
         Return -1;
   End;
   Function hay_mensajes_pendientes(
      p_codempresa                        Varchar2,
      p_codpersona                        Varchar2 )
      Return Boolean Is
      /*
         OBJETIVO
          Devuelve true si hay mensajes pendientes para
          la persona.
        REQUIERE
          P_CODPERSONA -- Codigo de la persona
        HISTORIA
          EVIL 12-01-1997 CREACION
      */
      v_result                      Varchar2( 1 );
   Begin
      Select 'M'
        Into v_result
        From mensajes_x_persona
       Where cod_empresa = p_codempresa
         And cod_persona = p_codpersona
         And ind_entregado = 'N'
         And Trunc( fec_desplegar ) <= Trunc( Sysdate )
         And Rownum = 1;
      Return True;
   Exception
      When Others Then
         Return False;
   End;
   Function hay_alertas_pendientes(
      p_codempresa                        Varchar2,
      p_codpersona                        Varchar2 )
      Return Boolean Is
      /*
         OBJETIVO
          Devuelve true si hay alertas pendientes para
          la persona.
        REQUIERE
          P_CODPERSONA -- Codigo de la persona
        HISTORIA
          EVIL 12-01-1997 CREACION
      */
      v_result                      Varchar2( 1 );
   Begin
      Select 'N'
        Into v_result
        From notas_x_persona
       Where cod_empresa = p_codempresa
         And cod_persona = p_codpersona
         And tip_nota = 'A'
         And Rownum = 1;
      Return True;
   Exception
      When Others Then
         Return False;
   End;
   Function hay_actividades_pendientes(
      p_codempresa                        Varchar2,
      p_codpersona                        Varchar2,
      p_codusuario                        Varchar2 )
      Return Boolean Is
      /*
         OBJETIVO
          Devuelve true si hay actividades pendientes para
          la persona.
        REQUIERE
          P_CODPERSONA -- Codigo de la persona
        HISTORIA
          EVIL 12-01-1997 CREACION
      */
      v_result                      Varchar2( 1 );
   Begin
      Select 'A'
        Into v_result
        From agenda_actividades
       Where cod_empresa = p_codempresa
         And cod_persona = p_codpersona
         And encarg_actividad = p_codusuario
         And estado_actividad = 'P'
         And Rownum = 1;
      Return True;
   Exception
      When Others Then
         Return False;
   End;
   Function esta_en_lista_oficialia(
      p_codempresa                        Varchar2,
      p_codpersona                        Varchar2 )
      Return Boolean Is
      v_result                      Varchar2( 1 );
   Begin
      Return False;
   Exception
      When Too_many_rows Then
         Return True;
      When Others Then
         Return False;
   End;
   Function esta_en_lista_negra(
      p_codempresa                        Varchar2,
      p_codpersona                        Varchar2 )
      Return Boolean Is
      /*
         OBJETIVO
          Devuelve true si la persona se encuenta en la lista
          negra.
        REQUIERE
          P_CODPERSONA -- Codigo de la persona
        HISTORIA
          EVIL 12-01-1997 CREACION
          API 06062014 -- Agregar el uso del campo "incluido", el cual es utilizado para activar o desactivar
                                  las personas en la lista negra
      */
      v_result                      Varchar2( 1 );
   Begin
      Select 'L'
        Into v_result
        From lista_negra
       Where cod_persona = p_codpersona
         And Trunc( fec_vencimiento ) > Trunc( Sysdate )
         And Nvl( incluido, 'N' ) = 'S'
           -- API 06062014 Para considerarse en lista negra debe tener el campo INCLUIDO marcado
             FETCH FIRST 1 ROWS ONLY;
      Return True;
   Exception
      When Others Then
         Return False;
   End;
   Function esta_en_lista_negra_no_cliente(
      p_numid                             Varchar2,
      tipo                                Varchar2 )
      Return Boolean Is
      --EFECTUA: Devuelve true si la persona se encuenta en la lista Negra de No Clientes.
      --REQUIERE :
      --HISTORIA : EnFrancisco : 14/7/2011
      --                API 06062014 : Agregar el uso del campo "incluido", el cual es utilizado para activar o desactivar
      --                                        las personas en la lista negra de no clientes
      v_result                      Varchar2( 1 );
   Begin
      Select 'L'
        Into v_result
        From lista_negra_no_cliente
       Where num_id = p_numid
         And tipo_id = tipo
         And Trunc( fec_vencimiento ) > Trunc( Sysdate )
         And Nvl( incluido, 'N' ) = 'S'
         And   -- API 06062014 Para considerarse en lista negra de no clientes debe tener el campo INCLUIDO marcado
             Rownum = 1;
      Return True;
   Exception
      When Others Then
         Return False;
   End;
   
    FUNCTION en_lista_negra_no_cliente_nomb(pc_primer_nombre    IN VARCHAR2,    --
                                            pc_segundo_nombre   IN VARCHAR2,    -- IVAN BERGES 13/08/2025
                                            pc_primer_apellido  IN VARCHAR2,    --
                                            pc_segundo_apellido IN VARCHAR2)    --
    RETURN BOOLEAN
    IS
        v_result VARCHAR2(1);
    BEGIN
        SELECT 'L'
        INTO    v_result
        FROM    LISTA_NEGRA_NO_CLIENTE
        WHERE   REPLACE(UPPER(NOMBRE_PERSONA||APELLIDO_PERSONA), CHR(32)) = REPLACE(UPPER(pc_primer_nombre  ||
                                                                                          pc_segundo_nombre ||
                                                                                          pc_primer_apellido||
                                                                                          pc_segundo_apellido), CHR(32))
        AND     TRUNC(fec_vencimiento) > TRUNC(SYSDATE)
        AND     NVL(incluido, 'N') = 'S'
        FETCH FIRST 1 ROWS ONLY;
        
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END en_lista_negra_no_cliente_nomb;  
   
   Function esta_en_lista_ofac(
      p_codempresa                        Varchar2,
      p_codpersona                        Varchar2 )
      Return Boolean Is
      --OBJETIVO :    Devuelve true si el nombre la persona se encuenta en la Lista ofac.
      --REQUIERE :  p_codempresa- codigo de la empresa; p_codPersona -- Codigo de la persona
      --HISTORIA :    Dfatule 27/09/2007 CREACION
      v_result                      Varchar2( 1 );
      vnombre                       Varchar2( 30 ) := Null;
      vapellido                     Varchar2( 30 ) := Null;
      vcomercial                    Varchar2( 65 ) := Null;
      vtipper                       Varchar2( 1 ) := Null;
   Begin
      Begin
         Select es_fisica
           Into vtipper
           From personas
          Where cod_persona = p_codpersona
          FETCH FIRST 1 ROWS ONLY;
      Exception
         When Others Then
            Return False;
      End;
      If vtipper Is Not Null Then
         If vtipper = 'S' Then
            Begin
               Select Trim( primer_nombre || ' ' || segundo_nombre ),
                      Trim( primer_apellido || ' ' || segundo_apellido )
                 Into vnombre, vapellido
                 From personas_fisicas
                Where cod_per_fisica = p_codpersona;
            Exception
               When Others Then
                  Null;
            End;
            --
            Begin
               Select 'X'
                 Into v_result
                 From ofac_datos_generales
                Where tipo_persona = 'Individual'   --Fisicas
                  And Trim( Decode( Nvl( Substr( nombre, 1, Instr( nombre, ',' ) - 1 ),
                                         '0' ),
                                    '0', Substr( nombre, Instr( nombre, ' ' ) + 1,
                                                 Length( nombre )),
                                    Substr( nombre, Instr( nombre, ',' ) + 1,
                                            Length( nombre )))) Like vnombre
                  And Trim( Decode( Nvl( Substr( nombre, 1, Instr( nombre, ',' ) - 1 ),
                                         '0' ),
                                    '0', Substr( nombre, 1, Instr( nombre, ' ' ) - 1 ),
                                    Substr( nombre, 1, Instr( nombre, ',' ) - 1 ))) Like
                                                                                 vapellido
                  And Rownum = 1;
               Return True;
            Exception
               When Others Then
                  Return False;
            End;
         Elsif vtipper = 'N' Then
            Begin
               Select nom_comercial
                 Into vcomercial
                 From personas_juridicas
                Where cod_per_juridica = p_codpersona;
            Exception
               When Others Then
                  Null;
            End;
            --
            Begin
               Select 'X'
                 Into v_result
                 From ofac_datos_generales
                Where Upper( tipo_persona ) Is Null   --Juridicas
                  And Substr( nombre, 1, 65 ) Like vcomercial
                  And Rownum = 1;
               Return True;
            Exception
               When Others Then
                  Return False;
            End;
         End If;
      End If;
   End;
   Function esta_en_lista_ong(
      p_codempresa                        Varchar2,
      p_codpersona                        Varchar2 )
      Return Boolean Is
      --  OBJETIVO :    Devuelve true si la persona se encuenta en la Lista ONG.
      --  REQUIERE :  P_CODPERSONA -- Codigo de la persona
      --  HISTORIA :    Dfatule 27/09/2007 CREACION
      v_result                      Varchar2( 1 );
   Begin
      Select 'X'
        Into v_result
        From lista_ong
       Where cod_per_juridica = p_codpersona
         And Trunc( fec_vencimiento ) > Trunc( Sysdate )
         And Rownum = 1;
      Return True;
   Exception
      When Others Then
         Return False;
   End;
   Function esta_en_lista_pep(
      p_codempresa                        Varchar2,
      p_codpersona                        Varchar2 )
      Return Boolean Is
      --  OBJETIVO :    Devuelve true si la persona se encuenta en la Lista PEP.
      --  REQUIERE :  P_CODPERSONA -- Codigo de la persona
      --  HISTORIA :    Dfatule 27/09/2007 CREACION
      v_result                      Varchar2( 1 );
   Begin
      Select 'X'
        Into v_result
        From lista_pep
       Where cod_persona = p_codpersona
         And Trunc( fec_vencimiento ) > Trunc( Sysdate )
         And Rownum = 1;
      Return True;
   Exception
      When Others Then
         Return False;
   End;
   --
   --WLAPAZ - EXCELLO REQ. 11727
   Function fes_pep(
      p_codpersona       Varchar2,
      p_es               Varchar2)
      Return varchar2 IS
      vfun  varchar2(5);
      vrel  varchar2(5);
   BEGIN
      select es_funcionario,es_peps
      into vfun, vrel
      from personas_fisicas
      where cod_per_fisica = p_codpersona;
      --
      if p_es = 'F' then
        return nvl(vfun,'N');
      elsif p_es = 'P' then
        return nvl(vrel,'N');  
      end if;
      --   
   EXCEPTION
      when others then
         return null;         
   END;   
   --
   Function esta_en_lista_se(
      p_codempresa                        Varchar2,
      p_codpersona                        Varchar2 )
      Return Boolean Is
      --  OBJETIVO :    Devuelve true si la persona se encuenta en la Lista SE.
      --  REQUIERE :  P_CODPERSONA -- Codigo de la persona
      --  HISTORIA :    Dfatule 27/09/2007 CREACION
      v_result                      Varchar2( 1 );
   Begin
      Select 'X'
        Into v_result
        From lista_seguimiento_especial
       Where cod_persona = p_codpersona
         And Trunc( fec_vencimiento ) > Trunc( Sysdate )
         And Rownum = 1;
      Return True;
   Exception
      When Others Then
         Return False;
   End;
   Function ofrecer_paquete_productos(
      p_codempresa                        Varchar2,
      p_codpersona                        Varchar2 )
      Return Boolean Is
      /*
         OBJETIVO
          Retorna TRUE si la persona es acta para ofrecerle productos.
          En caso de que no se le pueda ofrecer productos entonces retorna FALSE.
          Si la persona no es cliente no es apta para ofrecerle productos.
         REQUIERE
          p_codpersona    -- Codigo de la persona
          p_codEmpresa    -- codigo de la empresa
         HISTORIA
          Erick Villalobos 06-11-1997
              Rafael Sibaja    02-12-1997
      */
      Cursor cur_clientes Is
         Select cross_calculado, rentabilidad
           From cliente
          Where cod_empresa = p_codempresa
            And cod_cliente = p_codpersona;
      Cursor cur_paquetes Is
         Select crosselling, rentabilidad, scoring, cod_tip_scoring
           From paquetes_productos
          Where cod_empresa = p_codempresa;
      v_cliente                     cur_clientes%Rowtype;
      v_scoring                     scoring_x_persona.puntaje_scoring%Type;
      v_crosselling                 cliente.cross_calculado%Type;
      v_rentabilidad                cliente.rentabilidad%Type;
      v_simbcrosselling             Varchar2( 2 );
      v_simbscoring                 Varchar2( 2 );
      v_simbrentabilidad            Varchar2( 2 );
      v_result                      Boolean := False;
   Begin
      -- Obtener los parametros para los simbolos de comparacion
      v_simbcrosselling          := param.parametro_general( 'SIMB_CROSSELL', 'MK' );
      v_simbrentabilidad         := param.parametro_general( 'SIMB_RENTABILIDAD', 'MK' );
      v_simbscoring              := param.parametro_general( 'SIMB_SCORING', 'MK' );
      -- Obtener la rentabilidad y el crosselling del cliente
      Open cur_clientes;
      Fetch cur_clientes
       Into v_cliente;
      v_rentabilidad             := v_cliente.rentabilidad;
      v_crosselling              := v_cliente.cross_calculado;
      Close cur_clientes;
      -- Evaluar si hay algun paquete que llene las condiciones
      For paquete In cur_paquetes Loop
         v_scoring                  :=
                             obt_scoring_persona( p_codpersona, paquete.cod_tip_scoring );
         --v_cliente.cross_calculado
         --v_cliente.rentabilidad
         If     evaluar_condicion( Nvl( v_crosselling, 0 ), v_simbcrosselling,
                                   Nvl( paquete.crosselling, 0 ))
            And evaluar_condicion( Nvl( v_rentabilidad, 0 ), v_simbrentabilidad,
                                   Nvl( paquete.rentabilidad, 0 ))
            And evaluar_condicion( v_scoring, v_simbscoring, Nvl( paquete.scoring, 0 )) Then
            v_result                   := True;
            Exit;
         End If;
      End Loop;
      Return v_result;
   Exception
      When Others Then
         Return False;
   End;
   Function oportunidad_venta_productos(
      p_codempresa                        Varchar2,
      p_codpersona                        Varchar2 )
      Return Boolean Is
      /*
         OBJETIVO
          Retorna TRUE si se tiene oportunidad de venta de un producto con la persona
          En caso contrario retorna FALSE.
         REQUIERE
          p_codpersona    -- Codigo de la persona
          p_codEmpresa    -- codigo de la empresa
         HISTORIA
          Rafael Sibaja 24-11-1997
          Erick Villalobos 12-01-1998 Se elimino el count para que fuera mas rapido.
                          Ademas se metio al paquete de base de datos
                          P_DATOS_PERSONA.
      */
      v_result                      Varchar2( 1 );
   Begin
      Select 'x'
        Into v_result
        From oportunidades_venta
       Where cod_persona = p_codpersona
         And cod_empresa = p_codempresa
         And estatus = 'P'
         And Rownum = 1;
      Return True;
   Exception
      When Others Then
         Return False;
   End;
   Function pictures(
      p_codempresa                        Varchar2,
      p_codagencia                        Varchar2,
      p_codpersona                        Varchar2,
      p_codusuario                        Varchar2 )
      Return Varchar2 Is
      /*
        OBJETIVO
          Devuelve un string el cual determina si el cliente tiene
              mensajes, alertas, actividades, si es anticliente,
              si tiene oportunidades de venta pendientes y
              si se le debe ofrecer productos.
          En caso de que no tenga nada se devuelve un guion en la posicion
          correspondiente.
          Las posiciones del string son
          1: M  -- Mensaje
          2: N  -- Alerta
          3: A  -- Actividad pendiente
          4: L  -- Si la persona es un anticliente
              5: P  -- Se debe ofrecer productos al cliente
          6: O  -- El cliente tiene oportunidades de venta pendientes
          Ejemplo
          Un string como 'M-AL--' debe interpretarse como que el cliente es tiene
          mensajes, no tiene alertas, tiene actividades pendientes y es anticliente.
          Ademas no se le debe ofrecer productos y no tiene oportunidades pendientes.
        REQUIERE
          P_CODPERSONA -- Codigo de la persona
        HISTORIA
          EVIL 12-01-1997 Se modifico y se incluyo al procedimiento.
      */
      v_string                      Varchar2( 10 );
   Begin
      -- Mensajes
      If hay_mensajes_pendientes( p_codempresa, p_codpersona ) Then
         v_string                   := v_string || 'M';
      Else
         v_string                   := v_string || '-';
      End If;
      -- Alertas
      If hay_alertas_pendientes( p_codempresa, p_codpersona ) Then
         v_string                   := v_string || 'N';
      Else
         v_string                   := v_string || '-';
      End If;
      -- Actividades
      If hay_actividades_pendientes( p_codempresa, p_codpersona, p_codusuario ) Then
         v_string                   := v_string || 'A';
      Else
         v_string                   := v_string || '-';
      End If;
      -- Anticliente
      If esta_en_lista_negra( p_codempresa, p_codpersona ) Then
         v_string                   := v_string || 'L';
      Else
         v_string                   := v_string || '-';
      End If;
      If sistema_instalado( p_codempresa, p_codagencia, 'MK' ) Then
         If ofrecer_paquete_productos( p_codempresa, p_codpersona ) Then
            v_string                   := v_string || 'P';
         Else
            v_string                   := v_string || '-';
         End If;
         If oportunidad_venta_productos( p_codempresa, p_codpersona ) Then
            v_string                   := v_string || 'O';
         Else
            v_string                   := v_string || '-';
         End If;
      End If;
      Return v_string;
   End;
   Function relacion_persona_banco(
      p_codempresa                        Varchar2,
      p_codpersona                        Varchar2 )
      Return Varchar2 Is
      v_relacion                    Varchar2( 1 );
   /*
     FUNCION
            Esta funcion devuelve la relacion de la persona con el banco.
        P - Prospecto
        C - Cliente
        O - Otro
     REQUIERE
          p_codEmpresa -- Codigo de la empresa
          p_codPersona -- Codigo de la persona
     FECHA 09-01-1998
     ANALISTA
            Erick Villalobos
   */
   Begin
      Begin
         Select 'C'
           Into v_relacion
           From cliente
          Where cod_cliente = p_codpersona
            And cod_empresa = p_codempresa;
         Return v_relacion;
      Exception
         When Others Then
            Null;
      End;
      Begin
         Select 'P'
           Into v_relacion
           From prospectos
          Where cod_prospecto = p_codpersona
            And cod_empresa = p_codempresa;
         Return v_relacion;
      Exception
         When Others Then
            Null;
      End;
      Return( 'O' );
   End;
   Procedure obt_datos_persona(
      p_codempresa                        Varchar2,
      p_codagencia                        Varchar2,
      p_codpersona                        Varchar2,
      p_codusuario                        Varchar2,
      p_pictures                 In Out   Varchar2,
      p_relacionbanco            In Out   Varchar2,
      p_nomoficial               In Out   Varchar2,
      p_nompromotor              In Out   Varchar2,
      p_categoria_clte           In Out   Varchar2 ) Is
      v_codcategoria                cat_clientes.cod_cat_clte%Type;
   Begin
      -- Buscar existencia de mensajes y otros aspectos que tienen que
      -- desplegarse
      p_pictures                 :=
                       pictures( p_codempresa, p_codagencia, p_codpersona, p_codusuario );
      -- Determinar la relacion con el banco
      p_relacionbanco            := relacion_persona_banco( p_codempresa, p_codpersona );
      -- Averiguar el nombre del promotor y el oficial
      If p_relacionbanco = 'C' Then
         -- Oficial (extrae de una vez la categoria del cliente para
         --         hacer solo un acceso a la tabla cliente.)
         Begin
            Select c.nombre, a.cod_cat_clte
              Into p_nomoficial, v_codcategoria
              From cliente a, empleados b, personas c
             Where a.cod_cliente = p_codpersona
               And a.cod_empresa = p_codempresa
               And a.cod_oficial Is Not Null
               And a.cod_oficial = b.id_empleado
               And b.cod_per_fisica = c.cod_persona;
         Exception
            When Others Then
               Null;
         End;
         -- Promotor
         Begin
            Select c.nombre
              Into p_nompromotor
              From cliente a, empleados b, personas c
             Where a.cod_cliente = p_codpersona
               And a.cod_empresa = p_codempresa
               And a.cod_promotor Is Not Null
               And a.cod_promotor = b.id_empleado
               And b.cod_per_fisica = c.cod_persona;
         Exception
            When Others Then
               Null;
         End;
         -- Obtener la descripcion de la categoria
         Begin
            Select descripcion
              Into p_categoria_clte
              From cat_clientes
             Where cod_cat_clte = v_codcategoria;
         Exception
            When Others Then
               Null;
         End;
      Elsif p_relacionbanco = 'P' Then
         -- Oficial
         Begin
            Select c.nombre
              Into p_nomoficial
              From cliente a, empleados b, personas c
             Where a.cod_cliente = p_codpersona
               And a.cod_empresa = p_codempresa
               And a.cod_oficial Is Not Null
               And a.cod_oficial = b.id_empleado
               And b.cod_per_fisica = c.cod_persona;
         Exception
            When Others Then
               Null;
         End;
         -- Promotor
         Begin
            Select c.nombre
              Into p_nompromotor
              From cliente a, empleados b, personas c
             Where a.cod_cliente = p_codpersona
               And a.cod_empresa = p_codempresa
               And a.cod_promotor Is Not Null
               And a.cod_promotor = b.id_empleado
               And b.cod_per_fisica = c.cod_persona;
         Exception
            When Others Then
               Null;
         End;
      End If;
   End;
   Function obt_sect_economico(
      p_persona                           Varchar2,
      p_esfisica                          Varchar2 )
      Return Varchar2 Is
      Cursor fis_sector Is
         Select cod_sector
           From personas_fisicas
          Where cod_per_fisica = p_persona;
      Cursor jur_sector Is
         Select cod_sector
           From personas_juridicas
          Where cod_per_juridica = p_persona;
      v_sector                      Varchar2( 5 );
   Begin
      If p_esfisica = 'S' Then
         Open fis_sector;
         Fetch fis_sector
          Into v_sector;
         Close fis_sector;
      Elsif p_esfisica = 'N' Then
         Open jur_sector;
         Fetch jur_sector
          Into v_sector;
         Close jur_sector;
      Else
         v_sector                   := Null;
      End If;
   End;
   /*
       EFECTUA : Busca un nombre en la lista OFAC y devuelve true o false de acuerdo
                 al porcentaje de parecido especificado. Si no se especifica un porcentaje
                 se utiliza el porcentaje por defecto definido en el parametro PORC_PAREC_OFAC
       HISTORIA: JDELACRUZ (JAC) 21-jun-2011
   */
   Function es_parecido_ofac(
      pnombre                    In       Varchar2 )
      Return Number Is
      vexiste                       Number := 0;
   Begin
      Begin
         vexiste                    := parecidos_ofac( pnombre, 0 ).Last;
      Exception
         When No_data_found Then
            Return 0;
      End;
      Return vexiste;
   End es_parecido_ofac;
   /*
       EFECTUA : Busca un nombre en la lista OFAC y devuelve los registros parecidos de acuerdo
                 al porcentaje de parecido especificado. Si no se especifica un porcentaje
                 se utiliza el porcentaje por defecto definido en el parametro PORC_PAREC_OFAC.
                 Se busca dentro de toda la tabla OFAC_DATOS_GENERALES
       HISTORIA: JDELACRUZ (JAC) 21-jun-2011
                 JDELACRUZ (JAC) 13-jul-2011
   */
   Function parecidos_ofac(
      pnombre                    In       Varchar2,
      pporcentaje                In       Number := 0 )
      Return tofac Is
      vporcentaje                   Number := pporcentaje;
      vidx                          Binary_integer;
      vret                          tofac;
      --JAC 22-07-2014 incluyo OFAC_APODOS
      vporcentajeapodo              Number := pporcentaje;
      --Fin JAC
      Cursor parecidosofac Is
         Select cod_ofac, Upper( Trim( nombre )) nombre
           From ofac_datos_generales o
          Where Instr( ( Upper( Trim( nombre ))),
                       Upper( Trim( Substr( pnombre, 1, Instr( pnombre, ' ' ))))) > 0
            And ( ( pct_parecidos( Upper( Trim( nombre )), Upper( pnombre )) >=
                                                                               vporcentaje ))
         --JAC 22-07-2014 incluyo OFAC_APODOS
         Union
         Select cod_ofac, Upper( Trim( apodo )) nombre
           From ofac_apodos
          Where Instr( ( Upper( Trim( apodo ))),
                       Upper( Trim( Substr( pnombre, 1, Instr( pnombre, ' ' ))))) > 0
            And ( ( pct_parecidos( Upper( Trim( apodo )), Upper( pnombre )) >=
                                                                          vporcentajeapodo ));
   --Fin JAC
   Begin
      If vporcentaje = 0 Then
         vporcentaje                :=
                                param.parametro_x_empresa( '1', 'PORC_PAREC_OFAC', 'PA' );
         --JAC 22-07-2014 incluyo OFAC_APODOS
         vporcentajeapodo           :=
                           param.parametro_x_empresa( '1', 'PORC_PAREC_OFAC_APOD', 'PA' );
      --Fin JAC
      End If;
      Begin
         For c In parecidosofac Loop
            vidx                       := Nvl( vret.Last, 0 ) + 1;
            If vidx <= 400 Then
               vret( vidx ).codofac       := c.cod_ofac;
               vret( vidx ).nomofac       := c.nombre;
            Else
               Exit;
            End If;
         End Loop;
      Exception
         When Others Then
            Null;
      End;
      Return vret;
   End parecidos_ofac;
   /*
       EFECTUA : Busca el procentaje de parecido de nombre con respecto a otro comparando palabra por palabra.
       HISTORIA: JDELACRUZ (JAC) 04-jul-2011


    El algoritmo utilizado realiza lo siguiente: Se separan los nombres en palabras, se compara cada palabra
    de un nombre con las palabras del otro utilizando porcentaje de similitud y se calcula
    el promedio de similitud para el nombre suministrado.

    El porcentaje de similitud se realiza utilizando la funcion UTL_MATCH.EDIT_DISTANCE_SIMILARITY
    basada en el algoritmo "Edit Distance" tambien conocido como "Levenshtein Distance"
    (http://download.oracle.com/docs/cd/E14072_01/appdev.112/e10577/u_match.htm)
   */
  Function pct_parecidos(
      pnombre2                   In       Varchar2,
      pnombre1                   In       Varchar2 )
      Return Number Is
      vnombre1                      Varchar2( 255 ) := Upper( pnombre1 );
      vnombre2                      Varchar2( 255 ) := Upper( pnombre2 );
      vanombre1                     strarray := strarray( );
      vanombre2                     strarray := strarray( );
      vporcentaje                   Number( 3 ) := 0;
      vacumulado                    Number( 4 ) := 0;
      vporctotal                    Number( 3 ) := 0;
      vcantidad                     Number( 3 ) := 0;
      
      /*
       EFECTUA : Remueve palabras y letras que provocan falsos positivos.
       HISTORIA: JDELACRUZ (JAC) 13-jul-2011
      */
     Function preparatexto(
         ptexto                     In       Varchar2 )
         Return Varchar2 Is
         vtexto                        Varchar2( 32567 );
      Begin
         vtexto                     := Replace( Upper( ptexto ), ',' );
         vtexto                     := Replace( vtexto, ' DE ', ' ' );
         vtexto                     := Replace( vtexto, ' LA ', ' ' );
         vtexto                     := Replace( vtexto, ' C.A. ', ' ' );
         vtexto                     := Replace( vtexto, ' S.A. ', ' ' );
         vtexto                     := Replace( vtexto, ' R.L. ', ' ' );
         vtexto                     := Replace( vtexto, ' DEL ', ' ' );
         vtexto                     := Replace( vtexto, ' CON ', ' ' );
         vtexto                     := Replace( vtexto, ' Y ', ' ' );
         vtexto                     := Replace( vtexto, ' S. ', ' ' );
         vtexto                     := Replace( vtexto, ' C.V. ', ' ' );
         Return Trim( vtexto );
      End preparatexto;
   Begin
      vnombre1                   := preparatexto( vnombre1 );
      vnombre2                   := preparatexto( vnombre2 );
            arreglo_palabras( vnombre1, vanombre1 );
            arreglo_palabras( vnombre2, vanombre2 );
      vcantidad                  := vanombre1.Count;
      vporcentaje                := 0;
      vacumulado                 := 0;
      vporctotal                 := 0;
      For n1 In 1 .. vanombre1.Count Loop
         If Length( Trim( vanombre1( n1 ))) > 1 Then
            For n2 In 1 .. vanombre2.Count Loop
               vporcentaje                :=
                  utl_match.edit_distance_similarity( ( vanombre1( n1 )),
                                                      ( vanombre2( n2 )));
               If vporcentaje >= 80 Then
                  vacumulado                 := vacumulado + vporcentaje;
                  vporctotal                 :=( vacumulado / vcantidad );
               End If;
            End Loop;
         End If;
      End Loop;
      If vporctotal > 100 Then   --Es un falso verdadero y se descarta
         vporctotal                 := 0;
      End If;
      Return vporctotal;
   End pct_parecidos;
   Function cta_aplica_norma253(
      p_num_cuenta                        Number )
      Return Varchar2 Is
      vesfisica                     Varchar2( 1 );
   Begin
      Begin
         Select es_fisica
           Into vesfisica
           From personas p, cuenta_efectivo c
          Where p.cod_persona = c.cod_cliente
            And c.num_cuenta = p_num_cuenta;
      Exception
         When Others Then
            vesfisica                  := 'N';
      End;
      Return vesfisica;
   End;
   --
   Function clte_aplica_norma253(
      pcodcliente                         Number )
      Return Varchar2 Is
      -- Efectua:
      --           Valida si es una persona fisica para aplicar el 10% de la Ley 253
      -- Requiere:
      --       N/A
      --
      -- Historia:
      --        Flarsen 22/11/2012  Creacion
      --
      vesfisica                     Varchar2( 1 );
   Begin
      Begin
         Select es_fisica
           Into vesfisica
           From personas p
          Where p.cod_persona = pcodcliente;
      Exception
         When Others Then
            vesfisica                  := 'N';
      End;
      Return vesfisica;
   End;
   Function clte_aplica_normadgii132011(
      pcodcliente                         Number )
      Return Varchar2 Is
      -- Efectua:
      --           Valida si es una persona juridica para aplicar el 1% de la Norma DGII 13-2011.
      -- Requiere:
      --       N/A
      --
      -- Historia:
      --        Enfrancisco 02/04/2014  Creacion
      --
      vperjurrnc                    Varchar2( 1 ) := '';
   Begin
      Begin
         Select 'S'
           Into vperjurrnc
           From personas p
          Where p.cobr_nodgii_132011 = 'S'
            And p.cod_per_juridica = pcodcliente
            And p.es_fisica = 'N';
      Exception
         When No_data_found Then
            vperjurrnc                 := 'N';
         When Others Then
            vperjurrnc                 := 'N';
      End;
      Return vperjurrnc;
   End;
   Function validapersona(   -- equiros, 17/9/97
      ppersona                   In       Varchar2,
      pnombre                    In Out   Varchar2 )
      Return Boolean Is
   -- EFECTUA: validar la existencia de una persona
   Begin
      Select nombre
        Into pnombre
        From personas
       Where cod_persona = ppersona;
      Return True;
   --
   Exception
      When No_data_found Then
         Return False;
   End;
   
   --Funcion para buscar el sector contable asignado a la persona
   --frodriguez
   --26/08/2016
   --Banco Multiple Ademi s. a.
   Function Obtiene_SectorContable(
            pcodigo_cliente               In  Number)
            Return varchar2
            Is
            vsector personas.cod_sec_contable%Type;
            Begin
                Begin
                    Select cod_sec_contable
                    Into vsector 
                    From pa.personas
                    Where cod_persona=pcodigo_cliente;
                    Exception
                    When no_data_found Then
                        vsector:=Null;
                End;
                Return(vsector);
            End; 
End;
/

