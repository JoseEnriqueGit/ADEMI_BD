CREATE OR REPLACE PACKAGE PA.p_datos_persona Is
   Function obt_scoring_persona(
      p_codpersona                        Varchar2,
      p_tipscoring                        Varchar2 )
      Return Number;
   Function hay_mensajes_pendientes(
      p_codempresa                        Varchar2,
      p_codpersona                        Varchar2 )
      Return Boolean;
   Function hay_alertas_pendientes(
      p_codempresa                        Varchar2,
      p_codpersona                        Varchar2 )
      Return Boolean;
   Function hay_actividades_pendientes(
      p_codempresa                        Varchar2,
      p_codpersona                        Varchar2,
      p_codusuario                        Varchar2 )
      Return Boolean;
   Function esta_en_lista_negra(
      p_codempresa                        Varchar2,
      p_codpersona                        Varchar2 )
      Return Boolean;
   Function esta_en_lista_oficialia(
      p_codempresa                        Varchar2,
      p_codpersona                        Varchar2 )
      Return Boolean;
   Function esta_en_lista_negra_no_cliente(
      p_numid                             Varchar2,
      tipo                                Varchar2 )
      Return Boolean;

    FUNCTION en_lista_negra_no_cliente_nomb(pc_primer_nombre    IN VARCHAR2,    --
                                            pc_segundo_nombre   IN VARCHAR2,    -- IVAN BERGES 13/08/2025
                                            pc_primer_apellido  IN VARCHAR2,    --
                                            pc_segundo_apellido IN VARCHAR2)    --
    RETURN BOOLEAN;      
      
   Function esta_en_lista_ofac(
      p_codempresa                        Varchar2,
      p_codpersona                        Varchar2 )
      Return Boolean;
   Function esta_en_lista_ong(
      p_codempresa                        Varchar2,
      p_codpersona                        Varchar2 )
      Return Boolean;
   Function esta_en_lista_pep(
      p_codempresa                        Varchar2,
      p_codpersona                        Varchar2 )
      Return Boolean;
   --WLAPAZ - EXCELLO REQ. 11727
   Function fes_pep(
      p_codpersona       Varchar2,
      p_es               Varchar2)
      Return varchar2;
   --
   Function esta_en_lista_se(
      p_codempresa                        Varchar2,
      p_codpersona                        Varchar2 )
      Return Boolean;
   Function ofrecer_paquete_productos(
      p_codempresa                        Varchar2,
      p_codpersona                        Varchar2 )
      Return Boolean;
   Function oportunidad_venta_productos(
      p_codempresa                        Varchar2,
      p_codpersona                        Varchar2 )
      Return Boolean;
   Function pictures(
      p_codempresa                        Varchar2,
      p_codagencia                        Varchar2,
      p_codpersona                        Varchar2,
      p_codusuario                        Varchar2 )
      Return Varchar2;
   Function relacion_persona_banco(
      p_codempresa                        Varchar2,
      p_codpersona                        Varchar2 )
      Return Varchar2;
   Procedure obt_datos_persona(
      p_codempresa                        Varchar2,
      p_codagencia                        Varchar2,
      p_codpersona                        Varchar2,
      p_codusuario                        Varchar2,
      p_pictures                 In Out   Varchar2,
      p_relacionbanco            In Out   Varchar2,
      p_nomoficial               In Out   Varchar2,
      p_nompromotor              In Out   Varchar2,
      p_categoria_clte           In Out   Varchar2 );
   Function obt_sect_economico(
      p_persona                           Varchar2,
      p_esfisica                          Varchar2 )
      Return Varchar2;
   /*
       EFECTUA : Busca un nombre en la lista OFAC y devuelve la cantidad de registros parecidos
                 de acuerdo al porcentaje de parecido especificado. Si no se especifica un porcentaje
                 se utiliza el porcentaje por defecto definido en el parametro PORC_PAREC_OFAC
                 del sistema PA
       HISTORIA: JDELACRUZ (JAC) 21-jun-2011
   */
   Function es_parecido_ofac(
      pnombre                    In       Varchar2 )
      Return Number;
   /*
    Registro y tabla para devolver los elementos que fueron coincidencia al buscar
    parentezcos con la lista OFAC.
    JDELACRUZ (JAC) 21-jun-2011
   */
   Type rofac Is Record(
      codofac                       Number( 10 ),
      nomofac                       Varchar2( 350 )
   );
   Type tofac Is Table Of rofac
      Index By Binary_integer;
   /*
       EFECTUA : Busca un nombre en la lista OFAC y devuelve los registros parecidos de acuerdo
                 al porcentaje de parecido especificado. Si no se especifica un porcentaje
                 se utiliza el porcentaje por defecto definido en el parametro PORC_PAREC_OFAC
       HISTORIA: JDELACRUZ (JAC) 21-jun-2011
   */
   Function parecidos_ofac(
      pnombre                    In       Varchar2,
      pporcentaje                In       Number := 0 )
      Return tofac;
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
      Return Number;
   /*
       EFECTUA : Invoca un metodo Java que separa una oracion en palabras y las devuelve en un arreglo.
       HISTORIA: JDELACRUZ (JAC) 04-jul-2011
   */
   Procedure arreglo_palabras(
      p_in                       In       Varchar2,
      p_out                      Out      strarray ) As
      Language Java
      Name 'javautl.arreglo_palabras( java.lang.String,
                                     oracle.sql.ARRAY[] )';
   Function cta_aplica_norma253(
      p_num_cuenta                        Number )
      Return Varchar2;
   Function clte_aplica_norma253(
      pcodcliente                         Number )
      Return Varchar2;
   Function clte_aplica_normadgii132011(
      pcodcliente                         Number )
      Return Varchar2;
   Function validapersona(   -- equiros, 17/9/97
      ppersona                   In       Varchar2,
      pnombre                    In Out   Varchar2 )
      Return Boolean;
      
   Function Obtiene_SectorContable(
            pcodigo_cliente               In  Number)
            Return varchar2;
End;
/

