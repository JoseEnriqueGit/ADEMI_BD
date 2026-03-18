create or replace PACKAGE    "CC_UTILS" AS
   PROCEDURE verifica_reversion (
      pempresa IN VARCHAR2,
      pnummovto IN NUMBER,
      vcoderror IN OUT VARCHAR2
   );

   --
   PROCEDURE obtiene_email (
      pesfisica IN VARCHAR2,
      pcodper IN VARCHAR2,
      pemail OUT VARCHAR2
   );

   PROCEDURE obt_mensaje_error (
      pcoderror IN VARCHAR2,
      pcodsistema IN VARCHAR2,
      pcodidioma IN VARCHAR2,
      pmensajeerror IN OUT VARCHAR2
   );

   --
   PROCEDURE obt_parametros (
      pcodempresa IN VARCHAR2,
      pcodsistema IN VARCHAR2,
      pparametro IN VARCHAR2,
      pcodidioma IN VARCHAR2,
      pvalor IN OUT VARCHAR2,
      pdefecto IN VARCHAR2 DEFAULT '%%%',
      pmensajeerror IN OUT VARCHAR2
   );

   --
   PROCEDURE actualiza_movimto (
      pempresa IN VARCHAR2,
      pnummovto IN NUMBER,
      pnumcuenta IN NUMBER,
      pestado IN VARCHAR2,
      pnumasiento IN NUMBER,
      ptipocambio IN NUMBER,
      vcoderror IN OUT VARCHAR2
   );

   --
   PROCEDURE valida_cierre_cc (
      pempresa IN VARCHAR2,
      pfecha OUT DATE
   );

--
-- -----------------------------------------------------------------------
   FUNCTION digito_ctrlchq_bt (
      pcuenta IN VARCHAR2,
      pdocumento IN VARCHAR2,
      pnumeroctrl IN VARCHAR2
   )
      RETURN NUMBER;

   FUNCTION proceso_ctrlchq_bt (
      pcta IN VARCHAR2,
      pdoc IN VARCHAR2
   )
      RETURN NUMBER;

   FUNCTION valor_producto_bt (
      pposicion IN NUMBER,
      pdigito IN NUMBER
   )
      RETURN NUMBER;

   FUNCTION digito_unidad_bt (
      pproducto IN NUMBER
   )
      RETURN NUMBER;

   FUNCTION digito_control_bt (
      pmodulo IN NUMBER,
      pconcatenado IN NUMBER
   )
      RETURN NUMBER;

-- -----------------------------------------------------------------------
--
   FUNCTION es_credicheque (
      pcodempresa IN VARCHAR2,
      pcodproducto IN VARCHAR2,
    pcuenta IN VARCHAR2
   )
      RETURN BOOLEAN;

   FUNCTION es_credicheque (
      pcodempresa IN VARCHAR2,
      pcodproducto IN VARCHAR2
   )
      RETURN BOOLEAN;

   --
   FUNCTION es_preferencial (
      pcodempresa IN VARCHAR2,
      pcodproducto IN VARCHAR2
   )
      RETURN BOOLEAN;

   --
   FUNCTION filtros_negativos_pr (
      pcodempresa IN VARCHAR2,
      pcodcliente IN VARCHAR2,
      pobservaciones IN OUT VARCHAR2
   )
      RETURN BOOLEAN;

   --
   FUNCTION credito_cj (
      pcodempresa IN VARCHAR2,
      pcredito IN NUMBER,
      pestadoevaluar IN VARCHAR2,
      ptipcomparacion IN VARCHAR2
   )
      RETURN VARCHAR2;

   --
   FUNCTION credito_atrasado (
      pcodempresa IN VARCHAR2,
      pcredito IN NUMBER,
      pmoraevaluar IN VARCHAR2,
      ptipcomparacion IN VARCHAR2
   )
      RETURN VARCHAR2;

   --
   FUNCTION saldo_promedio_cta (
      pcodempresa IN VARCHAR2,
      pcuenta IN NUMBER,
      psaldoevaluar IN VARCHAR2,
      ptipcomparacion IN VARCHAR2,
      pdiasevaluar IN NUMBER
   )
      RETURN VARCHAR2;

   --
   FUNCTION antiguedad_cta (
      pcodempresa IN VARCHAR2,
      pcuenta IN NUMBER,
      pdatoevaluar IN VARCHAR2,
      ptipcomparacion IN VARCHAR2,
      pdiasevaluar IN NUMBER
   )
      RETURN VARCHAR2;

   --
   FUNCTION porc_cheques_rechazados (
      pcodempresa IN VARCHAR2,
      pcuenta IN NUMBER,
      pporcevaluar IN VARCHAR2,
      ptipcomparacion IN VARCHAR2,
      pdiasevaluar IN NUMBER
   )
      RETURN VARCHAR2;

   --
   FUNCTION estado_cta (
      pcodempresa IN VARCHAR2,
      pcuenta IN NUMBER,
      pestadoevaluar IN VARCHAR2,
      ptipcomparacion IN VARCHAR2,
      pdiasevaluar IN NUMBER
   )
      RETURN VARCHAR2;
   --
   FUNCTION estado_desc (pcodempresa IN VARCHAR2,
                         pcuenta IN NUMBER,
                         pestado IN VARCHAR2)
                 RETURN VARCHAR2;

   --
   FUNCTION saldo_sobregirado_cta (
      pcodempresa IN VARCHAR2,
      pcuenta IN NUMBER,
      psaldoevaluar IN VARCHAR2,
      ptipcomparacion IN VARCHAR2,
      pdiasevaluar IN NUMBER
   )
      RETURN VARCHAR2;

   --
   /*
   FUNCTION obt_num_cuenta (
      p_cod_empresa IN VARCHAR2,
      p_cod_agencia IN VARCHAR2,
      p_cod_sistema IN VARCHAR2 )
      RETURN NUMBER;
   */
   FUNCTION obt_num_cuenta(
      p_empresa IN VARCHAR2,
      p_agencia IN VARCHAR2,
      p_sistema IN VARCHAR2,
      p_producto IN VARCHAR2
   ) Return Number;
   --
   FUNCTION completa_cuenta (
      p_cod_sistema IN VARCHAR2,
      p_cuenta IN NUMBER
   )
      RETURN NUMBER;

   --
   FUNCTION obt_formato_cta  
     RETURN VARCHAR2;
   --
     
   FUNCTION conviertemontotransferencia (
      pempresa IN VARCHAR2,
      pmonedaorigen IN VARCHAR2,
      pmontoorigen IN NUMBER,
      ptipocambio IN NUMBER
   )
      RETURN NUMBER;
      
   FUNCTION Digito_verificador(Pnumcuenta IN VARCHAR2) 
   RETURN NUMBER;
   
   FUNCTION formato_cta(pNumCuenta In Varchar2)
   Return Varchar2;
   
   PROCEDURE Reversa_Movimiento_CD ( pNumMovto IN NUMBER );

   Function F_Mascara_Cta(
     P_Empresa  In  Varchar2, 
     P_Cuenta in Number
   )  
   Return  Varchar2; -- Excello:JPH:2023-03-15: REQ_3550 


END Cc_Utils;