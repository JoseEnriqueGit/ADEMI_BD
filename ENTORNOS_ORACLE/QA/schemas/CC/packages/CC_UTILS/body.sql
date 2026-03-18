create or replace PACKAGE BODY    "CC_UTILS" AS
  --
  -- ===============================================================================================
  --
   PROCEDURE verifica_reversion (
      pempresa IN VARCHAR2,
      pnummovto IN NUMBER,
      vcoderror IN OUT VARCHAR2
   )
   IS
      CURSOR c1
      IS
         SELECT estado_movimto
           FROM MOVIMTO_DIARIO
          WHERE num_movto_d = pnummovto
            AND cod_empresa = pempresa;

      vestado   VARCHAR2 (1);
   BEGIN
      vcoderror := '004016';
      OPEN  c1;
      FETCH c1 INTO vestado;
      CLOSE c1;

      IF vestado NOT IN ('R', 'E')
      THEN
         vcoderror := '004017';
         pa_err.raise_app;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         pa_err.fijar_error (vcoderror, 'CC', SQLERRM, 'Verifica_Reversion');
         RAISE;
   END verifica_reversion;
  --
  -- ===============================================================================================
  --
   PROCEDURE obtiene_email (
      pesfisica IN VARCHAR2,
      pcodper IN VARCHAR2,
      pemail OUT VARCHAR2
   )
   IS
      vuser      VARCHAR2 (25);
      vdominio   VARCHAR2 (25);
   BEGIN
      IF pesfisica = 'S'
      THEN
         SELECT email_usuario, email_servidor
           INTO vuser, vdominio
           FROM pa.personas_fisicas
          WHERE cod_per_fisica = pcodper;
      ELSE
         SELECT email_usuario, email_servidor
           INTO vuser, vdominio
           FROM pa.personas_juridicas
          WHERE cod_per_juridica = pcodper;
      END IF;

      IF vuser IS NOT NULL
      THEN
         pemail := vuser || '@' || vdominio;
      ELSE
         pemail := 'No definido.';
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         pemail := 'No definido';
   END obtiene_email;
  --
  -- ===============================================================================================
  --
   PROCEDURE obt_mensaje_error (
      pcoderror IN VARCHAR2,
      pcodsistema IN VARCHAR2,
      pcodidioma IN VARCHAR2,
      pmensajeerror IN OUT VARCHAR2
   )
   IS
      vmensaje   VARCHAR2 (2000);
   -- vCodIdioma    varchar2(5) := 'ESPA';
   --
   BEGIN
      --
      SELECT texto
        INTO vmensaje
        FROM mensajes_sistema
       WHERE (num_mensaje = pcoderror)
         AND (cod_sistema = pcodsistema)
         AND (cod_idioma = pcodidioma);
      --
      pmensajeerror := substr(pcodsistema || '-' || pcoderror || ' : ' || vmensaje,2000);
      -- pMensaje := vMensaje;
      RETURN;
   --
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         pmensajeerror := substr('El Mensaje de error : ' || pcodsistema || '-' || pcoderror || ' no fue encontrado',2000);
         RETURN;
      WHEN OTHERS
      THEN
         pmensajeerror := substr('Error al buscar el mensaje de error ' || pcodsistema || '-' || pcoderror || ' ' || TO_CHAR (SQLCODE) || ' ' || SQLERRM,2000);
         RETURN;
   END;
   --
   -- ===============================================================================================
   --
   PROCEDURE obt_parametros (
      pcodempresa IN VARCHAR2,
      pcodsistema IN VARCHAR2,
      pparametro IN VARCHAR2,
      pcodidioma IN VARCHAR2,
      pvalor IN OUT VARCHAR2,
      pdefecto IN VARCHAR2 DEFAULT '%%%',
      pmensajeerror IN OUT VARCHAR2
   )
   IS
      vmsjerror    VARCHAR2 (350) := NULL;
      vmensaje     VARCHAR2 (350) := NULL;
      vcodidioma   VARCHAR2 (5)   := Cc_Constantes.cod_idioma;
   BEGIN
      IF pdefecto = '%%%'
      THEN
         SELECT valor
           INTO pvalor
           FROM parametros_x_empresa
          WHERE (cod_empresa = pcodempresa)
            AND (cod_sistema = pcodsistema)
            AND (abrev_parametro = pparametro);
      ELSE
         BEGIN
            SELECT valor
              INTO pvalor
              FROM parametros_x_empresa
             WHERE (cod_empresa = pcodempresa)
               AND (cod_sistema = pcodsistema)
               AND (abrev_parametro = pparametro);
         EXCEPTION
            WHEN OTHERS
            THEN
               pvalor := pdefecto;
         END;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         -- Delegado no esta registrado en el sistema
         Cc_Utils.obt_mensaje_error ('000110', 'PA', vcodidioma, pmensajeerror);
      WHEN OTHERS
      THEN
         Cc_Utils.obt_mensaje_error ('000111', 'PA', vcodidioma, pmensajeerror);
   END;                                                                                                                                                                                -- obt_parametros
   --
   -- ===============================================================================================
   --
   PROCEDURE actualiza_movimto (
      pempresa IN VARCHAR2,
      pnummovto IN NUMBER,
      pnumcuenta IN NUMBER,
      pestado IN VARCHAR2,
      pnumasiento IN NUMBER,
      ptipocambio IN NUMBER,
      vcoderror IN OUT VARCHAR2
   )
   IS
   BEGIN
      --
      UPDATE MOVIMTO_DIARIO
         SET estado_movimto = NVL (pestado, estado_movimto),
             num_asiento = NVL (pnumasiento, num_asiento),
             tip_cambio = NVL (ptipocambio, tip_cambio)
       WHERE num_movto_d = pnummovto
         AND cod_empresa = pempresa
         AND num_cuenta = pnumcuenta;
   EXCEPTION
      WHEN OTHERS
      THEN
         vcoderror := '001029';
         pa_err.fijar_error (vcoderror, 'CC', SQLERRM, 'Actualiza_Movimto');
         RAISE;
   END actualiza_movimto;
   --
   -- ===============================================================================================
   --
   PROCEDURE valida_cierre_cc (
      pempresa IN VARCHAR2,
      pfecha OUT DATE
   )
   IS
   BEGIN
      SELECT fec_ejecucion
        INTO pfecha
        FROM procesos_x_sistema a, control_proc_x_sist b
       WHERE a.cod_sistema = 'CC'
         AND a.cod_proceso = 'CIERRE_MENSUAL'
         AND b.cod_empresa = pempresa
         AND b.cod_sistema = a.cod_sistema
         AND b.cod_proceso = a.cod_proceso
         AND b.estado_proceso = 'F';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         pfecha := NULL;
   END valida_cierre_cc;
   --
   -- ===============================================================================================
   --
   FUNCTION digito_ctrlchq_bt (
      pcuenta IN VARCHAR2,
      pdocumento IN VARCHAR2,
      pnumeroctrl IN VARCHAR2
   )
      RETURN NUMBER
   IS
   BEGIN
      DECLARE
         v_digitoconca   VARCHAR2 (1);
         v_val_product   NUMBER;
         v_val_digito    NUMBER;
         v_nuevoconcat   VARCHAR2 (20);
         v_digitocontr   NUMBER;
      BEGIN
         v_nuevoconcat := proceso_ctrlchq_bt (pcuenta, pdocumento);

         --INICIA loop que Busca el Digito de Control
         FOR i IN 1 .. 10
         LOOP
            BEGIN                                                                                                                       -- Se busca Segun Correlativo de Modulo y segun la nueva cadena
               v_digitocontr := Cc_Utils.digito_control_bt (i, TO_NUMBER (v_nuevoconcat));

               IF v_digitocontr = TO_NUMBER (pnumeroctrl)                                                                                    --Si El digito de control Coincide con el del Parametro...
               THEN
                  EXIT;                                                                                                                               --...El documento es valido y, se cancela el Loop
               ELSE
                  v_digitocontr := 0;                                                                                                           --De lo contrario El control sera Cero o sea, Invalido.
               END IF;
            END;
         END LOOP;

         RETURN (v_digitocontr);                                                                                                                                                        -- Retorna Valor
      END;
   END;                                                                                                                                                                          --End DIGITO_CTRLCHQ_BT
   --
   -- ===============================================================================================
   --
   FUNCTION proceso_ctrlchq_bt (
      pcta IN VARCHAR2,
      pdoc IN VARCHAR2
   )
      RETURN NUMBER
   IS
   BEGIN
      DECLARE
         v_concatenado   VARCHAR2 (20);
         v_digitoconca   VARCHAR2 (1);
         v_val_product   NUMBER;
         v_val_digito    NUMBER;
         v_nuevoconcat   VARCHAR2 (20);
         v_digitocontr   NUMBER;
      BEGIN
         -- Se concatena la CUENTA Y EL DOCUMENTO EN UN STRING DE 20 CARACTERES
         v_concatenado := RPAD ((LPAD (LTRIM (RTRIM (pcta)), 10, '0') || ' ' || LPAD (RTRIM (LTRIM (pdoc)), 8, '0')), 20, ' ');

         -- INICIA loop que barre el string concatenado
         FOR i IN 1 .. 20
         LOOP
            BEGIN
               v_digitoconca := NVL (RTRIM (LTRIM (SUBSTR (v_concatenado, i, 1))), 0);                                                                        --Se Obtiene Digito por Digito del String
               v_val_product := Cc_Utils.valor_producto_bt (i, v_digitoconca);                                                                       --Se Calcula el Valor Producto del Digito Obtenido
               v_val_digito := Cc_Utils.digito_unidad_bt (v_val_product);                                                                                   --Se Calcula el Digito Unidad  del Producto

               IF (   i <> 11
                   OR i <> 20)
               THEN
                  v_nuevoconcat := RTRIM (LTRIM (v_nuevoconcat)) || TO_CHAR (NVL (v_val_digito, 0));
               END IF;
            END;
         END LOOP;

         RETURN (TO_NUMBER (v_nuevoconcat));
      END;
   END;

   FUNCTION valor_producto_bt (
      pposicion IN NUMBER,
      pdigito IN NUMBER
   )
      RETURN NUMBER
   IS
   BEGIN
      DECLARE
         -- Cursor de Pesos
         -- Correlativos del 32 al 13 respectivamente
         TYPE tipo_tabla IS RECORD (
            correlativo   NUMBER (5),
            valor_peso    NUMBER (5)
         );

         --
         TYPE tipo_peso IS TABLE OF tipo_tabla
            INDEX BY BINARY_INTEGER;

         -- variables
         peso         tipo_peso;
         --
         v_producto   NUMBER;
      --
      BEGIN                                                                                                                                                                                    -- Inicio
         --Llenar Arreglo con Pesos
         --
         peso (1).correlativo := 32;
         peso (1).valor_peso := 11;
         peso (2).correlativo := 31;
         peso (2).valor_peso := 19;
         peso (3).correlativo := 30;
         peso (3).valor_peso := 13;
         peso (4).correlativo := 29;
         peso (4).valor_peso := 45;
         peso (5).correlativo := 28;
         peso (5).valor_peso := 21;
         peso (6).correlativo := 27;
         peso (6).valor_peso := 78;
         peso (7).correlativo := 26;
         peso (7).valor_peso := 9;
         peso (8).correlativo := 25;
         peso (8).valor_peso := 16;
         peso (9).correlativo := 24;
         peso (9).valor_peso := 47;
         --
         peso (10).correlativo := 23;
         peso (10).valor_peso := 98;
         peso (11).correlativo := 22;
         peso (11).valor_peso := 0;
         peso (12).correlativo := 21;
         peso (12).valor_peso := 12;
         peso (13).correlativo := 20;
         peso (13).valor_peso := 15;
         peso (14).correlativo := 19;
         peso (14).valor_peso := 67;
         peso (15).correlativo := 18;
         peso (15).valor_peso := 53;
         peso (16).correlativo := 17;
         peso (16).valor_peso := 6;
         peso (17).correlativo := 16;
         peso (17).valor_peso := 43;
         peso (18).correlativo := 15;
         peso (18).valor_peso := 12;
         peso (19).correlativo := 14;
         peso (19).valor_peso := 25;
         peso (20).correlativo := 13;
         peso (20).valor_peso := 0;
         v_producto := pdigito * peso (pposicion).valor_peso;
         RETURN (v_producto);
      END;
   END;                                                                                                                                                                         -- FIN Valor_producto_BT
   --
   -- ===============================================================================================
   --
   -- -----------------------------------------------------------------------
   -- Banco de los Trabajadores
   -- Funcion para obtener el DIGITO <unidad>
   -- que se toma como base para encontrar el DIGITO DE CONTROL de un Cheque
   -- Ludwin Tzul
   --
   -- -----------------------------------------------------------------------
   FUNCTION digito_unidad_bt (
      pproducto IN NUMBER
   )
      RETURN NUMBER
   IS
      -- Variables
      --
      v_len_numero   NUMBER;
      v_nuevonum     VARCHAR2 (15);
      v_digito       VARCHAR2 (01);
      v_contador     NUMBER;
      v_sumaval      NUMBER;
   BEGIN
      --
      v_len_numero := LENGTH (TO_CHAR (pproducto));
      v_nuevonum := '0';

      --
      --Eliminar nueves para hacer el calculo del digito <Unidad>
      --
      FOR i IN 1 .. v_len_numero
      LOOP
         BEGIN
            v_digito := SUBSTR (TO_CHAR (pproducto), i, 1);

            IF v_digito <> '9'
            THEN
               v_nuevonum := RTRIM (LTRIM (v_nuevonum)) || v_digito;
            END IF;
         END;
      END LOOP;

      --
      -- Se valida nuevo numero
      --
      IF v_nuevonum = '0'
      THEN
         v_nuevonum := '9';                                                                                                                        -- Por Regla general si el digito <producto>
                                                                                                                                                   -- es solo nueves (ej. 999) la suma cabalistica es 9
      ELSE
         v_nuevonum := LTRIM (RTRIM (v_nuevonum));                                                                                                             -- de lo contrario se procede a realizar
      -- a realizar la suma cabalista del resultado
      END IF;

      --
      -- Se realiza sumatoria cabalistica
      --
      v_contador := 0;                                                                                                                                                             -- Contadores en cero
      v_sumaval := 0;

      WHILE (LENGTH (RTRIM (LTRIM (v_nuevonum))) > 1)
      LOOP
         BEGIN
            v_contador := v_contador + 1;
            v_digito := SUBSTR (RTRIM (LTRIM ((v_nuevonum))), v_contador, 1);                                                                                              -- Obtener Digito por Digito
            v_sumaval := v_sumaval + TO_NUMBER (NVL (v_digito, '0'));                                                                                                        -- Sumar Digito por Digito

            IF v_contador = LENGTH (RTRIM (LTRIM (v_nuevonum)))                                                                                                                 -- Evaluar fin de Ciclo
            THEN
               v_nuevonum := TO_CHAR (v_sumaval);                                                                                                                           -- Convertir a char la suma
               v_contador := 0;
               v_sumaval := 0;
            END IF;
         --exit;  la salida del Ciclo es Automatica puesto que el While la Evalua
         --       respecto a la longitud de la variable <V_NUEVONUM>
         END;
      END LOOP;

      -- Retornar valor unico (1 digito);
      RETURN (TO_NUMBER (v_nuevonum));
   END;                                                                                                                                                                          -- End Digito_Unidad_BT
   --
   -- ===============================================================================================
   --
   -- -----------------------------------------------------------------------
   -- Banco de los Trabajadores
   -- Funcion para obtener el <Digito_de_control> Segun el Modulo
   -- Ludwin Tzul.
   -- -----------------------------------------------------------------------
   FUNCTION digito_control_bt (
      pmodulo IN NUMBER,
      pconcatenado IN NUMBER
   )
      RETURN NUMBER
   IS
   BEGIN
      DECLARE
         -- Cursor de MODULOS BT
         -- Correlativos del 01 al 10 respectivamente
         TYPE tipo_tabla IS RECORD (
            correlativo   NUMBER (5),
            valormodulo   NUMBER (5)
         );

         --
         TYPE tipo_modulo IS TABLE OF tipo_tabla
            INDEX BY BINARY_INTEGER;

         -- variables
         modulo         tipo_modulo;
         --
         v_digitoctrl   NUMBER;
      --
      BEGIN                                                                                                                                                                                    -- Inicio
         --Llenar Arreglo con Pesos
         --
         modulo (1).correlativo := 1;
         modulo (1).valormodulo := 1012;
         modulo (2).correlativo := 2;
         modulo (2).valormodulo := 2343;
         modulo (3).correlativo := 3;
         modulo (3).valormodulo := 2123;
         modulo (4).correlativo := 4;
         modulo (4).valormodulo := 7656;
         modulo (5).correlativo := 5;
         modulo (5).valormodulo := 1344;
         modulo (6).correlativo := 6;
         modulo (6).valormodulo := 4576;
         modulo (7).correlativo := 7;
         modulo (7).valormodulo := 3456;
         modulo (8).correlativo := 8;
         modulo (8).valormodulo := 6098;
         modulo (9).correlativo := 9;
         modulo (9).valormodulo := 9083;
         modulo (10).correlativo := 10;
         modulo (10).valormodulo := 1234;
         --
         v_digitoctrl := MOD (pconcatenado, modulo (pmodulo).valormodulo);
         RETURN (v_digitoctrl);
      END;
   END;                                                                                                                                                                        --- FIN DIGITO de CONTROL
   --
   -- ===============================================================================================
   --
   FUNCTION es_credicheque (
      pcodempresa IN VARCHAR2,
      pcodproducto IN VARCHAR2,
      pcuenta IN VARCHAR2
   )
      RETURN BOOLEAN
   IS
      vprodcredicheque   VARCHAR2 (60);
      vmsjerror          VARCHAR2 (100);
      vCuentaRelacionada VARCHAR2(25);
   BEGIN
      SELECT num_cta_relacio
      INTO vCuentaRelacionada
      FROM CUENTA_EFECTIVO
      WHERE num_cuenta = pcuenta
      AND cod_empresa = pcodempresa;
      
      IF vCuentaRelacionada IS NOT NULL THEN
        RETURN TRUE; -- JVP 052006 Bantrab.
      ELSE
        RETURN FALSE;
      END IF;
      
      obt_parametros (pcodempresa, 'CC', 'PRO_CTA_CREDICHEQUE', 'ESPA', vprodcredicheque, '%%%', vmsjerror);

      --
      IF INSTR (vprodcredicheque, pcodproducto) != 0
      THEN
         RETURN TRUE;
      END IF;

      RETURN FALSE;
   END es_credicheque;
   --
   -- ===============================================================================================
   --
   FUNCTION es_credicheque (
      pcodempresa IN VARCHAR2,
      pcodproducto IN VARCHAR2
   )
      RETURN BOOLEAN
   IS
      vprodcredicheque   VARCHAR2 (60);
      vmsjerror          VARCHAR2 (100);
   BEGIN

      
      obt_parametros (pcodempresa, 'CC', 'PRO_CTA_CREDICHEQUE', 'ESPA', vprodcredicheque, '%%%', vmsjerror);

      --
      IF INSTR (vprodcredicheque, pcodproducto) != 0
      THEN
         RETURN TRUE;
      END IF;

      RETURN FALSE;
   END es_credicheque;
   --
   -- ===============================================================================================
   --
   FUNCTION es_preferencial (
      pcodempresa IN VARCHAR2,
      pcodproducto IN VARCHAR2
   )
      RETURN BOOLEAN
   IS
      vprodpreferencial   VARCHAR2 (60);
      vmsjerror           VARCHAR2 (100);
   BEGIN
      --      RETURN TRUE; -- JVP 052006 Bantrab.
      obt_parametros (pcodempresa, 'CC', 'PRO_CTA_PREFERENCIAL', 'ESPA', vprodpreferencial, '%%%', vmsjerror);

      --
      IF INSTR (vprodpreferencial, pcodproducto) != 0
      THEN
         RETURN TRUE;
      END IF;

      RETURN FALSE;
   END es_preferencial;
   --
   -- ===============================================================================================
   --
   FUNCTION filtros_negativos_pr (
      pcodempresa IN VARCHAR2,
      pcodcliente IN VARCHAR2,
      pobservaciones IN OUT VARCHAR2
   )
      RETURN BOOLEAN
   IS
      CURSOR prestamos
      IS
         SELECT no_credito
           FROM Pr_creditos a
          WHERE a.codigo_empresa = pcodempresa
            AND a.codigo_cliente = pcodcliente
            AND a.estado IN ('D', 'J')
            AND a.es_linea_credito = 'N';

      --
      CURSOR filtros
      IS
         SELECT   cod_empresa, cod_sistema, descripcion, funcion, ind_dato_eval, dato_evaluar, tip_comparacion, veces_evaluar, dias_evaluar
             FROM CC_FILTROS_SOBREGIROS
            WHERE cod_empresa = pcodempresa
              AND tipo_parametro = 'PR'
              AND cod_sistema = 'PR'
         ORDER BY consec_param;

      --
      vcomando         VARCHAR2 (300);
      vcursor          NUMBER;
      vres             NUMBER;
      vvalor_retorno   VARCHAR2 (200);
   --
   BEGIN
      FOR p IN prestamos
      LOOP
         FOR f IN filtros
         LOOP
            vcomando := 'begin  :valorret := ' || f.funcion || '(';
            vcomando := vcomando || pcodempresa || ',' || p.no_credito || ',' || CHR (39) || f.dato_evaluar || CHR (39) || ',' || CHR (39) || f.tip_comparacion || CHR (39);
            vcomando := vcomando || '); end;';
            vcursor := DBMS_SQL.OPEN_CURSOR;
            DBMS_SQL.PARSE (vcursor, vcomando, DBMS_SQL.v7);
            DBMS_SQL.BIND_VARIABLE (vcursor, ':valorret', vvalor_retorno, 150);
            vres := DBMS_SQL.EXECUTE (vcursor);
            DBMS_SQL.VARIABLE_VALUE (vcursor, ':valorret', vvalor_retorno);
            DBMS_SQL.CLOSE_CURSOR (vcursor);

            IF vvalor_retorno IS NOT NULL
            THEN
               pobservaciones := vvalor_retorno;
               RETURN TRUE;
            END IF;
         END LOOP;
      END LOOP;

      pobservaciones := NULL;
      RETURN FALSE;
   END;
   --
   -- ===============================================================================================
   --
   FUNCTION credito_cj (
      pcodempresa IN VARCHAR2,
      pcredito IN NUMBER,
      pestadoevaluar IN VARCHAR2,
      ptipcomparacion IN VARCHAR2
   )
      RETURN VARCHAR2
   IS
      vestado          VARCHAR2 (1);
      vobservaciones   VARCHAR2 (150);
   BEGIN
      BEGIN
         SELECT estado
           INTO vestado
           FROM Pr_creditos
          WHERE codigo_empresa = pcodempresa
            AND no_credito = pcredito;
      EXCEPTION
         WHEN OTHERS
         THEN
            vestado := 'X';
      END;

      --
      vobservaciones := 'El cliente tiene operaciones de credito en Cobro Judicial';

      --
      IF ptipcomparacion = '='
      THEN
         IF vestado = pestadoevaluar
         THEN
            RETURN vobservaciones;
         END IF;
      ELSIF ptipcomparacion = '>'
      THEN
         IF vestado > pestadoevaluar
         THEN
            RETURN vobservaciones;
         END IF;
      ELSIF ptipcomparacion = '<'
      THEN
         IF vestado < pestadoevaluar
         THEN
            RETURN vobservaciones;
         END IF;
      ELSIF ptipcomparacion = '<='
      THEN
         IF vestado <= pestadoevaluar
         THEN
            RETURN vobservaciones;
         END IF;
      ELSIF ptipcomparacion = '>='
      THEN
         IF vestado >= pestadoevaluar
         THEN
            RETURN vobservaciones;
         END IF;
      ELSIF ptipcomparacion = 'IN'
      THEN
         IF vestado IN (pestadoevaluar)
         THEN
            RETURN vobservaciones;
         END IF;
      END IF;

      --
      RETURN NULL;
   END;
   --
   -- ===============================================================================================
   --
   FUNCTION credito_atrasado (
      pcodempresa IN VARCHAR2,
      pcredito IN NUMBER,
      pmoraevaluar IN VARCHAR2,
      ptipcomparacion IN VARCHAR2
   )
      RETURN VARCHAR2
   IS
      vmoratorios      NUMBER (18, 2);
      vdiasmora        NUMBER (5);
      vmsjerror        VARCHAR2 (100);
      vobservaciones   VARCHAR2 (150);
   BEGIN
      -- Rmonroy Jun2013. Se modifica por integracion con CR. pr_abonos4
      Pr.Pr_abonos4.calcula_moratorios (pcodempresa, Cc_Constantes.cod_idioma, pcredito, TRUNC (SYSDATE), vmoratorios, vdiasmora, vmsjerror);
      --
      vobservaciones := 'El cliente tiene operaciones de credito atrasadas';

      --
      IF ptipcomparacion = '='
      THEN
         IF vdiasmora = TO_NUMBER (pmoraevaluar)
         THEN
            RETURN vobservaciones;
         END IF;
      ELSIF ptipcomparacion = '>'
      THEN
         IF vdiasmora > TO_NUMBER (pmoraevaluar)
         THEN
            RETURN vobservaciones;
         END IF;
      ELSIF ptipcomparacion = '<'
      THEN
         IF vdiasmora < TO_NUMBER (pmoraevaluar)
         THEN
            RETURN vobservaciones;
         END IF;
      ELSIF ptipcomparacion = '<='
      THEN
         IF vdiasmora <= TO_NUMBER (pmoraevaluar)
         THEN
            RETURN vobservaciones;
         END IF;
      ELSIF ptipcomparacion = '>='
      THEN
         IF vdiasmora >= TO_NUMBER (pmoraevaluar)
         THEN
            RETURN vobservaciones;
         END IF;
      ELSIF ptipcomparacion = 'IN'
      THEN
         IF vdiasmora IN (pmoraevaluar)
         THEN
            RETURN vobservaciones;
         END IF;
      END IF;

      --
      RETURN NULL;
   END;
   --
   -- ===============================================================================================
   --
   FUNCTION saldo_promedio_cta (
      pcodempresa IN VARCHAR2,
      pcuenta IN NUMBER,
      psaldoevaluar IN VARCHAR2,
      ptipcomparacion IN VARCHAR2,
      pdiasevaluar IN NUMBER
   )
      RETURN VARCHAR2
   IS
      vsaldo           NUMBER (20, 2) := 0;
      vtipocambio      NUMBER (10, 2);
      vmoneda          VARCHAR2 (4);
      vobservaciones   VARCHAR2 (150);
   BEGIN
      BEGIN
         SELECT NVL (AVG (sal_promedio), 0)
           INTO vsaldo
           FROM SALDOS_MES
          WHERE cod_empresa = pcodempresa
            AND num_cuenta = pcuenta
            AND fec_saldo >= SYSDATE - pdiasevaluar;
      EXCEPTION
         WHEN OTHERS
         THEN
            vsaldo := 0;
      END;

      --
      vmoneda := 1; --Busca_Moneda_Cuenta (pcodempresa, pcuenta);

      IF vmoneda = '1'
      THEN
         vtipocambio := 1; --cj_moned.obtienetc (pcodempresa, '1', 'R');                                                                                                        -- Otiene Tipo Cambio Compra
         vsaldo := NVL (vsaldo, 0) / vtipocambio;
      END IF;

      vobservaciones := 'La cuenta no cumple con Saldo Promedio';

      IF ptipcomparacion = '='
      THEN
         IF vsaldo = TO_NUMBER (psaldoevaluar)
         THEN
            RETURN vobservaciones;
         END IF;
      ELSIF ptipcomparacion = '>'
      THEN
         IF vsaldo > TO_NUMBER (psaldoevaluar)
         THEN
            RETURN vobservaciones;
         END IF;
      ELSIF ptipcomparacion = '<'
      THEN
         IF vsaldo < TO_NUMBER (psaldoevaluar)
         THEN
            RETURN vobservaciones;
         END IF;
      ELSIF ptipcomparacion = '<='
      THEN
         IF vsaldo <= TO_NUMBER (psaldoevaluar)
         THEN
            RETURN vobservaciones;
         END IF;
      ELSIF ptipcomparacion = '>='
      THEN
         IF vsaldo >= TO_NUMBER (psaldoevaluar)
         THEN
            RETURN vobservaciones;
         END IF;
      ELSIF ptipcomparacion = 'IN'
      THEN
         IF vsaldo IN (psaldoevaluar)
         THEN
            RETURN vobservaciones;
         END IF;
      END IF;

      --
      RETURN NULL;
      --
   END;
   --
   -- ===============================================================================================
   --
   FUNCTION antiguedad_cta (
      pcodempresa IN VARCHAR2,
      pcuenta IN NUMBER,
      pdatoevaluar IN VARCHAR2,
      ptipcomparacion IN VARCHAR2,
      pdiasevaluar IN NUMBER
   )
      RETURN VARCHAR2
   IS
      vfecapertura     DATE;
      vantiguedadcta   NUMBER (5);
      vobservaciones   VARCHAR2 (150);
   BEGIN
      BEGIN
         SELECT fec_apertura
           INTO vfecapertura
           FROM CUENTA_EFECTIVO
          WHERE cod_empresa = pcodempresa
            AND num_cuenta = pcuenta;
      EXCEPTION
         WHEN OTHERS
         THEN
            vfecapertura := TRUNC (SYSDATE);
      END;

      --
      vantiguedadcta := TRUNC (SYSDATE) - vfecapertura;
      vobservaciones := 'La cuenta no cumple con Antiguedad requerida';

      IF ptipcomparacion = '='
      THEN
         IF vantiguedadcta = TO_NUMBER (pdatoevaluar)
         THEN
            RETURN vobservaciones;
         END IF;
      ELSIF ptipcomparacion = '>'
      THEN
         IF vantiguedadcta > TO_NUMBER (pdatoevaluar)
         THEN
            RETURN vobservaciones;
         END IF;
      ELSIF ptipcomparacion = '<'
      THEN
         IF vantiguedadcta < TO_NUMBER (pdatoevaluar)
         THEN
            RETURN vobservaciones;
         END IF;
      ELSIF ptipcomparacion = '<='
      THEN
         IF vantiguedadcta <= TO_NUMBER (pdatoevaluar)
         THEN
            RETURN vobservaciones;
         END IF;
      ELSIF ptipcomparacion = '>='
      THEN
         IF vantiguedadcta >= TO_NUMBER (pdatoevaluar)
         THEN
            RETURN vobservaciones;
         END IF;
      ELSIF ptipcomparacion = 'IN'
      THEN
         IF vantiguedadcta IN (pdatoevaluar)
         THEN
            RETURN vobservaciones;
         END IF;
      END IF;

      --
      RETURN NULL;
   --
   END;
   --
   -- ===============================================================================================
   --
   FUNCTION estado_cta (
      pcodempresa IN VARCHAR2,
      pcuenta IN NUMBER,
      pestadoevaluar IN VARCHAR2,
      ptipcomparacion IN VARCHAR2,
      pdiasevaluar IN NUMBER
   )
      RETURN VARCHAR2
   IS
      vestadocta       VARCHAR2 (1);
      vdesestado       VARCHAR2 (50);
      vobservaciones   VARCHAR2 (150);
      vcomando         VARCHAR2 (100);
   BEGIN
      vestadocta := 1; --Busca_Estado_Cc (pcodempresa, pcuenta);
      SELECT DECODE (vestadocta,
                     '0', 'Pendiente Aprobar',
                     '1', 'Activa',
                     '2', 'Cancelada',
                     '3', 'Bloqueo Parcial',
                     '4', 'Bloqueo Total',
                     '5', 'Embargada',
                     '6', 'Inactiva',
                     '7', 'Cobro Judicial',
                     '9', 'Denegada'
                    )
        INTO vdesestado
        FROM DUAL;
      --
      vobservaciones := 'El cliente tiene cuentas en estado ' || vdesestado;

      IF ptipcomparacion = '='
      THEN
         IF vestadocta = pestadoevaluar
         THEN
            RETURN vobservaciones;
         END IF;
      ELSIF ptipcomparacion = '>'
      THEN
         IF vestadocta > pestadoevaluar
         THEN
            RETURN vobservaciones;
         END IF;
      ELSIF ptipcomparacion = '<'
      THEN
         IF vestadocta < pestadoevaluar
         THEN
            RETURN vobservaciones;
         END IF;
      ELSIF ptipcomparacion = '<='
      THEN
         IF vestadocta <= pestadoevaluar
         THEN
            RETURN vobservaciones;
         END IF;
      ELSIF ptipcomparacion = '>='
      THEN
         IF vestadocta >= pestadoevaluar
         THEN
            RETURN vobservaciones;
         END IF;
      ELSIF ptipcomparacion = 'IN'
      THEN
         vcomando := '''' || vestadocta || '''' || ' IN (' || pestadoevaluar || ')';

         --IF cb_utilcobranza.evalua_comando (vcomando)
         --THEN
          --  RETURN vobservaciones;
         --END IF;
      END IF;

      --
      RETURN NULL;
   --
   END;
   --
   -- ===============================================================================================
   --
   FUNCTION estado_desc (pcodempresa IN VARCHAR2,
                         pcuenta IN NUMBER,
                         pestado IN VARCHAR2)
                 RETURN VARCHAR2 IS
      vdesestado       VARCHAR2 (50);
   BEGIN
      SELECT DECODE (pestado,
                     '0', 'Pendiente Aprobar',
                     '1', 'Activa',
                     '2', 'Cancelada',
                     '3', 'Bloqueo Parcial',
                     '4', 'Bloqueo Total',
                     '5', 'Embargada',
                     '6', 'Inactiva',
                     '7', 'Cobro Judicial',
                     '9', 'Denegada')
        INTO vdesestado
      FROM DUAL;
      RETURN(vdesestado);
   EXCEPTION
      WHEN OTHERS THEN
      RETURN('Estado no conocido...');
   END;
   --
   -- ===============================================================================================
   --
   FUNCTION porc_cheques_rechazados (
      pcodempresa IN VARCHAR2,
      pcuenta IN NUMBER,
      pporcevaluar IN VARCHAR2,
      ptipcomparacion IN VARCHAR2,
      pdiasevaluar IN NUMBER
   )
      RETURN VARCHAR2
   IS
      vcksrechazados   NUMBER (10);
      vckspagados      NUMBER (10);
      vporccks         NUMBER (8, 2);
      vobservaciones   VARCHAR2 (150);
   BEGIN
      --
      SELECT COUNT ('x')
        INTO vcksrechazados
        FROM CKS_RECHAZADOS
       WHERE cod_empresa = pcodempresa
         AND num_cuenta = pcuenta;
      --
      SELECT COUNT ('x')
        INTO vckspagados
        FROM CKS_PAGADOS
       WHERE cod_empresa = pcodempresa
         AND num_cuenta = pcuenta;

      --
      BEGIN
         vporccks := (vcksrechazados * 100) / vckspagados;
      EXCEPTION
         WHEN OTHERS
         THEN
            vporccks := 0;
      END;

      --
      vobservaciones := 'La cuenta tiene un porcentaje alto de Cheques Rechazados';

      --
      IF ptipcomparacion = '='
      THEN
         IF vporccks = TO_NUMBER (pporcevaluar)
         THEN
            RETURN vobservaciones;
         END IF;
      ELSIF ptipcomparacion = '>'
      THEN
         IF vporccks > TO_NUMBER (pporcevaluar)
         THEN
            RETURN vobservaciones;
         END IF;
      ELSIF ptipcomparacion = '<'
      THEN
         IF vporccks < TO_NUMBER (pporcevaluar)
         THEN
            RETURN vobservaciones;
         END IF;
      ELSIF ptipcomparacion = '<='
      THEN
         IF vporccks <= TO_NUMBER (pporcevaluar)
         THEN
            RETURN vobservaciones;
         END IF;
      ELSIF ptipcomparacion = '>='
      THEN
         IF vporccks >= TO_NUMBER (pporcevaluar)
         THEN
            RETURN vobservaciones;
         END IF;
      ELSIF ptipcomparacion = 'IN'
      THEN
         IF vporccks IN (pporcevaluar)
         THEN
            RETURN vobservaciones;
         END IF;
      END IF;

      --
      RETURN NULL;
   --
   END;
   --
   -- ===============================================================================================
   --
   FUNCTION saldo_sobregirado_cta (
      pcodempresa IN VARCHAR2,
      pcuenta IN NUMBER,
      psaldoevaluar IN VARCHAR2,
      ptipcomparacion IN VARCHAR2,
      pdiasevaluar IN NUMBER
   )
      RETURN VARCHAR2
   IS
      vsobautorizado   NUMBER (20, 2) := 0;
      vsobregiro       NUMBER (20, 2) := 0;
      vtipocambio      NUMBER (10, 2);
      vmoneda          VARCHAR2 (4);
      vobservaciones   VARCHAR2 (150);
      vporcentaje      NUMBER (10, 2);
   BEGIN
      BEGIN
         SELECT SUM (mon_autorizado), SUM (mon_utilizado - mon_pagado)
           INTO vsobautorizado, vsobregiro
           FROM AUTORI_X_CUENTA
          WHERE cod_empresa = pcodempresa
            AND num_cuenta = pcuenta
            AND mon_utilizado - mon_pagado <> 0;
      EXCEPTION
         WHEN OTHERS
         THEN
            vsobautorizado := 0;
            vsobregiro := 0;
      END;

       --
      --
      BEGIN
         vporcentaje := NVL (vsobregiro, 0) * 100 / vsobautorizado;
      EXCEPTION
         WHEN OTHERS
         THEN
            vporcentaje := 0;
      END;

      --
      vobservaciones := 'La cuenta se encuentra sobregirada mas de lo permitido';

      IF ptipcomparacion = '='
      THEN
         IF vporcentaje = TO_NUMBER (psaldoevaluar)
         THEN
            RETURN vobservaciones;
         END IF;
      ELSIF ptipcomparacion = '>'
      THEN
         IF vporcentaje > TO_NUMBER (psaldoevaluar)
         THEN
            RETURN vobservaciones;
         END IF;
      ELSIF ptipcomparacion = '<'
      THEN
         IF vporcentaje < TO_NUMBER (psaldoevaluar)
         THEN
            RETURN vobservaciones;
         END IF;
      ELSIF ptipcomparacion = '<='
      THEN
         IF vporcentaje <= TO_NUMBER (psaldoevaluar)
         THEN
            RETURN vobservaciones;
         END IF;
      ELSIF ptipcomparacion = '>='
      THEN
         IF vporcentaje >= TO_NUMBER (psaldoevaluar)
         THEN
            RETURN vobservaciones;
         END IF;
      ELSIF ptipcomparacion = 'IN'
      THEN
         IF vporcentaje IN (psaldoevaluar)
         THEN
            RETURN vobservaciones;
         END IF;
      END IF;

      --
      RETURN NULL;
      --
   END;
   --
   -- ===============================================================================================
   --

   -- JVelasquez 25/07/2008
   -- Se modifica la estructura del Numero de Cuenta CC
   /*FUNCTION obt_num_cuenta (
      p_cod_empresa IN VARCHAR2,
      p_cod_agencia IN VARCHAR2,
      p_cod_sistema IN VARCHAR2 )
      RETURN NUMBER
   IS
      ----
      CURSOR secuencia IS
         SELECT num_cuenta.NEXTVAL
         FROM   DUAL;

      ----
      v_prefijo           CARA_X_PRODUCTO.prefijo_num_cuenta%TYPE;
      v_secuencia         NUMBER;
      v_dig_verificador   NUMBER;
      v_agencia           VARCHAR2(5);
      v_cuenta            CUENTA_EFECTIVO.num_cuenta%TYPE;
      v_largo             VARCHAR2 (5);
   ----
   BEGIN
      SELECT SUBSTR(p_cod_agencia,1,3) INTO v_agencia
   FROM dual;

      -- Consecutivo por agencia
      v_secuencia := pa_utils.obtiene_nuevo_valor_serie ('CONSEC_CC', p_cod_sistema, SUBSTR(p_cod_agencia,1,3)||'0', p_cod_empresa); -- Se cambia a agencia con cero por orden de Roberto Palomo JVP 032006

      -- Obtener Digito verificador
      v_dig_verificador := cj_act.digito_verificador_bt (v_agencia || TO_CHAR (LPAD(v_secuencia,6,0)));

      -- Se concatenan los componentes de la cuenta y se completa con ceros
      v_cuenta := TO_NUMBER (v_agencia||TO_CHAR(v_secuencia)||TO_CHAR (v_dig_verificador));

      -- Obtener el parametro del largo para el relleno de la cuenta con ceros.
      pa_utils.obt_param_general (p_cod_sistema, 'COMPLETA_CUENTA', v_largo);

      v_cuenta := TO_NUMBER (SUBSTR (TO_CHAR (v_cuenta), 1, 3) || LPAD (SUBSTR (TO_CHAR (v_cuenta), 4, TO_NUMBER (v_largo)), TO_NUMBER (v_largo), '0'));

      RETURN v_cuenta;
   END obt_num_cuenta;
   */
   --
   -- ===============================================================================================
   --
   FUNCTION obt_num_cuenta(
      p_empresa IN VARCHAR2,
      p_agencia IN VARCHAR2,
      p_sistema IN VARCHAR2,
      p_producto IN VARCHAR2
   ) Return Number
   IS

      v_agencia_bat       VARCHAR2(5);
      vconsecutivo        VARCHAR (6);
      v_dig_verificador   NUMBER;
      vlargo              NUMBER  (2) := 0;
      v_certif            NUMBER  (14);
   ----
   BEGIN

      v_agencia_bat := SUBSTR(p_agencia,1,4); -- nueva forma de tomar los digitos de la agencia
      -- Obtener consecutivo de cuenta
      vconsecutivo := LPAD (pa_utils.obtiene_nuevo_valor_serie ('CONSEC_CC', p_sistema, p_agencia, p_empresa), 5, 0);

      v_dig_verificador := Digito_verificador(LPAD (v_agencia_bat, 4, '0') || LPAD(p_producto,3,'0') || TO_CHAR (vconsecutivo));
      
      -- JVelasquez. 01/07/2008. Validar que los valores no sean nulos...
      If v_agencia_bat is Null Or p_producto is Null Or vconsecutivo Is Null Or v_dig_verificador Is Null Then
         
         Return Null;
      End If;      

      -- Se cambia la forma de hacer el numero del CDP, solicitado por bantrab, 14-11-2005. CCB
      --p_certif := TO_NUMBER (v_prefijo || LPAD (v_agencia_bat, 2, '0') || TO_CHAR (vconsecutivo) || TO_CHAR (v_dig_verificador));
      v_certif := TO_NUMBER (LPAD (v_agencia_bat, 4, '0') || LPAD(p_producto,3,'0') || TO_CHAR (vconsecutivo) || TO_CHAR (v_dig_verificador)); -- Nueva forma de numero de CDP
      Return v_certif;
   EXCEPTION
      WHEN OTHERS
      THEN
         Return Null;
   --
   END obt_num_cuenta;
   --
   -- ===============================================================================================
   --
   FUNCTION completa_cuenta (
      p_cod_sistema IN VARCHAR2,
      p_cuenta IN NUMBER
   )
      RETURN NUMBER
   IS
      ---
      v_largo    VARCHAR2 (5);
      v_cuenta   CUENTA_EFECTIVO.num_cuenta%TYPE;
   ----
   BEGIN
      -- Obtener el parametro del largo para el relleno de la cuenta con ceros.
      pa_utils.obt_param_general (p_cod_sistema, 'COMPLETA_CUENTA', v_largo);
      --
      --v_cuenta := TO_NUMBER (SUBSTR (TO_CHAR (p_cuenta), 1, 3) || LPAD (SUBSTR (TO_CHAR (p_cuenta), 4, TO_NUMBER (v_largo)), TO_NUMBER (v_largo), '0'));
      v_cuenta := p_cuenta;
      ---
      RETURN v_cuenta;
   END completa_cuenta;

   FUNCTION obt_formato_cta
     RETURN VARCHAR2
   IS
   BEGIN
     --RETURN('9999"-"00000000"-"9');
     /*JGOMEZ 08/10/2013 Temporalmente se modifica*/
     --RETURN('9999"-"999"-"99999"-"9');
     RETURN('9999999999999');
     --RETURN('0000"-"000"-"00000"-"0');
   END obt_formato_cta;
   --
   -- ===============================================================================================
   --
   FUNCTION conviertemontotransferencia (
      pempresa IN VARCHAR2,
      pmonedaorigen IN VARCHAR2,
      pmontoorigen IN NUMBER,
      ptipocambio IN NUMBER
   )
      RETURN NUMBER
   IS
      --
      vmonedaempresa   VARCHAR2 (20);
      vtipocambio      NUMBER;
   BEGIN
      pa_utils.moneda_origen (pempresa, vmonedaempresa);

      IF pmonedaorigen = vmonedaempresa
      THEN
         vtipocambio := 1 / ptipocambio;
      ELSE
         vtipocambio := ptipocambio;
      END IF;

      RETURN pMontoOrigen * vTipoCambio;
   END;
   --
   -- ===============================================================================================
   --
   FUNCTION Digito_verificador(Pnumcuenta IN VARCHAR2) RETURN NUMBER
   IS
      --Variables
      V_cuenta                      VARCHAR2(15);
      V_largoc                      NUMBER;
      V_contar                      NUMBER;
      V_digito                      CHAR;
      V_pesodi                      NUMBER;
      V_sumpes                      NUMBER;
      V_digito_verificadorbt        NUMBER;
   --
   BEGIN
      V_cuenta := RTRIM(LTRIM(Pnumcuenta));
      V_largoc := LENGTH(V_cuenta);
      V_contar := 0;
      V_pesodi := 0;
      V_sumpes := 0;

      --
      IF V_largoc < 15 THEN
         FOR I IN 1 .. V_largoc
         LOOP
            V_contar :=(V_contar + 1);
            V_digito := SUBSTR(V_cuenta, V_contar, 1);
            V_pesodi := NVL(TO_NUMBER(V_digito), 0) *(13 - V_contar);
            V_sumpes := V_sumpes + V_pesodi;

            IF V_contar >= 15
            THEN
               EXIT;
            END IF;
         END LOOP;

         V_digito_verificadorbt :=(10 -(MOD(V_sumpes, 10)));

         IF V_digito_verificadorbt > 9
         THEN
            V_digito_verificadorbt := 0;
         END IF;
      ELSE
         V_digito_verificadorbt := 99;
      END IF;

      --
      RETURN(V_digito_verificadorbt);
      --
   END Digito_verificador;
   --
   -- ===============================================================================================
   --
   FUNCTION formato_cta(pNumCuenta In Varchar2) Return Varchar2 Is
   
   Begin
     If length(pNumCuenta) <> 13 Then
        Return pNumCuenta;
     End If;
     
     Return substr(pNumCuenta,1,4)||'-'||substr(pNumCuenta,5,3)||'-'||substr(pNumCuenta,8,5)||'-'||substr(pNumCuenta,13,1);
        
   End;
   --
   -- ===============================================================================================
   --
   PROCEDURE Reversa_Movimiento_CD ( pNumMovto IN NUMBER ) IS
    --
     CURSOR cur_movto IS
       SELECT cod_empresa, cod_agencia, num_cuenta, mon_movimiento,
              tip_transaccion, cod_producto, num_documento, cod_sistema,
               estado_movimto, ROWID
       FROM MOVIMTO_DIARIO
       WHERE num_movto_d = pNumMovto;
     --
     vMov cur_movto%ROWTYPE;
     --
     wtiptransaccion   cat_tip_transac.tip_transaccion%TYPE := 13;
     nummovi           MOVIMTO_DIARIO.num_movto_d%TYPE;
     Westadomov        MOVIMTO_DIARIO.estado_movimto%TYPE;
     CodErr            VARCHAR2(6)  := '000079';
     sqlerr            VARCHAR2(2000);
     wsecuencia        NUMBER;
     wfechacalendario  DATE;
     error_exception   EXCEPTION;
     vTipTransAlt      NUMBER;
     vSubtranReversion        VARCHAR2(50);
     vMsjError         VARCHAR2(2000);
     --
   BEGIN
     OPEN cur_movto;
     FETCH cur_movto INTO vMov;
     IF cur_movto%NOTFOUND THEN
       CLOSE cur_movto;
       RAISE error_exception;
     END IF;
     CLOSE cur_movto;
     --
     SQLERR := NULL;
     coderr := NULL;
     --
     -- Leer la fecha de hoy segun calendario
     --
     BEGIN
        SELECT fec_hoy
         INTO  wFechaCalendario
         FROM  calendarios
         WHERE (cod_empresa = vMov.cod_empresa)
         AND   (cod_sistema = 'CC' )
         AND   (cod_agencia = vMov.cod_agencia);
     EXCEPTION
        WHEN NO_DATA_FOUND THEN
           coderr := '000079';
           RAISE error_exception;
        WHEN OTHERS THEN
           coderr := '000000';
           RAISE error_exception;
     END;
     --
     IF (vMov.mon_movimiento IS NULL)
     OR (pNumMovto IS NULL)
     THEN
        CODERR := '000100';
        RAISE ERROR_EXCEPTION;
     END IF;
     -- Si es un debito, aplicarle la transaccion 12 y si es un credito aplicarle
     -- la transaccion 13.
     -- enar. 15-03-96.
     IF (Cc_Ctaefe.Es_Debito(vMov.tip_transaccion, vMsjError) ='S') THEN
        wtiptransaccion := 12;
        vSubtranReversion := param.Parametro_x_Empresa(vMov.cod_empresa, 'SUBTRAN_REV_MOVDB_CD','CC');
     ELSE
        wtiptransaccion := 13;
        vSubtranReversion := param.Parametro_x_Empresa(vMov.cod_empresa, 'SUBTRAN_REV_MOVCD_CD','CC');
     END IF;
     --
     IF vSubtranReversion IS NULL
     THEN
        CODERR := '000178';
        RAISE ERROR_EXCEPTION;
     END IF;
     --
     Cc_Ctaefe.Agrega_Movimiento (vMov.cod_empresa, 
                                  vMov.cod_agencia, 
                                  'CC',
                                  vMov.num_cuenta, 
                                  vMov.cod_producto, 
                                  wtiptransaccion, 
                                  vSubtranReversion,
                                  USER, 
                                  wFechaCalendario, 
                                  vMov.num_documento, 
                                  vMov.mon_movimiento,
                                  'REVERSION DE TRANSACCION DESDE CERTIFICADOS', 
                                  'CJ', 
                                  pNumMovto, 
                                  'N', 
                                  NumMovi,
                                  vMsjError);
     --
     Cc_Ctaefe.Aplica_Movimiento (NumMovi, 
                                  wFechaCalendario,
                                  vMov.tip_transaccion, 
                                  NULL, 
                                  NULL, 
                                  NULL, 
                                  wsecuencia,
                                  NULL, 
                                  vMsjError, 
                                  CodErr);
  
     IF CodErr != '000005'
     THEN
        vMsjError := 'Cuenta no tiene saldo';
        RAISE error_exception;
     END IF;
     -- Actualiza la tabla de movimientos
     IF vMov.estado_movimto = 'A'
     THEN
        Westadomov  := 'R';   -- REVERSION DE MOVIM. APLICADOS
     ELSE
        Westadomov  := 'E';   -- REVERSION DE MOVIM. CONTABILIZADOS
     END IF;
     --
     UPDATE MOVIMTO_DIARIO
     SET    estado_movimto = westadomov
     WHERE  ROWID = vMov.ROWID;
     --
     IF CodErr != '000005'
     THEN
        RAISE error_exception;
     END IF;
     --
     IF vMov.tip_transaccion IN (57,58,82) THEN  -- Si se esta reversando una nota de debito se deben reversar los movimientos
                                            --  tipo 87, 88 (Transaccion espejo, Pago tarjeta) asociados a esta
        vTipTransAlt := 87; --cc_utils_cj.Busca_Tip_Trans_Alt(vMov.cod_empresa, vMov.tip_transaccion);
         UPDATE MOVIMTO_DIARIO
            SET estado_movimto = 'R'
            WHERE cod_empresa    = vMov.cod_empresa
              AND num_mov_fuente = pNumMovto
              AND tip_transaccion  = vTipTransAlt;
     END IF;
     --
   EXCEPTION
     WHEN error_exception THEN
        pa_err.fijar_error(CodErr,'CC',SQLERRM, 'reversaMovimiento', ' Movimiento:' ||pNumMovto);
      RAISE;
     WHEN OTHERS THEN
        pa_err.fijar_error('000178','CC',vMsjError|| '-'|| SQLERRM, 'reversaMovimiento', ' Movimiento:' ||pNumMovto);
      RAISE;
   END;
   --
   -- ===============================================================================================
   --
   --- Excello:JPH:2023-03-15: REQ_3550:Begin >>
   Function  F_Mascara_Cta(P_Empresa  In  Varchar2 , P_Cuenta in Number)  Return  Varchar2  Is  
     V_Cta_Mascara    Varchar2(20)   := Null;
     V_Fec_CCL11      Date                := To_Date(Param. Parametro_x_Empresa(P_Empresa,'FECVIGCC11','CC'),'YYYYMMDD');
     V_FecApe_Cta      Date               := Null;
     V_Tip_Cta              Varchar2(1)  := Null;
     V_Existe                 Varchar2(1)  := 'S';
     V_Masc_CA           Varchar2(50)  :=  Param. Parametro_x_Empresa(P_Empresa,'PERMASCCTAAH','CC');
     V_Masc_CC           Varchar2(50)  :=  Param. Parametro_x_Empresa(P_Empresa,'PERMASCCTACO','CC');

   Cursor C_Cuenta  Is
      Select C.Fec_Apertura, P.Tip_Cuenta 
      From Cuenta_Efectivo  C,
           Cara_X_Producto P
      Where C.Num_Cuenta  = P_Cuenta
        And P.Cod_Empresa = C.Cod_Empresa
        And P.Cod_Producto  =  C.Cod_Producto;
      
   Begin
     If  P_Cuenta Is Not Null Then
         Open  C_Cuenta;
         Fetch  C_Cuenta Into  V_FecApe_Cta,V_Tip_Cta ;
         If C_Cuenta%NotFound  Then
            V_Existe := 'N';
         End If;      
         Close C_Cuenta;
         
         If V_Existe = 'S' Then
            If V_Tip_Cta = 'A' Then
               If V_Masc_CA = 'S' Then     
                  V_Cta_Mascara := Substr(P_Cuenta,1,1)||'-'||Lpad(Substr(P_Cuenta,2),13,'0');
               Else
                  V_Cta_Mascara := P_Cuenta;
               End If;
            Else      
               If V_Masc_CC  = 'S' Then
                  If V_FecApe_Cta < V_Fec_CCL11 Then
                     V_Cta_Mascara := Substr(P_Cuenta,1,1)||'-'||Lpad(Substr(P_Cuenta,2),13,'0');
                  Else
                     V_Cta_Mascara := Substr(P_Cuenta,1,1)||'-'||Lpad(Substr(P_Cuenta,2),10,'0');    
                  End If;
               Else
                 V_Cta_Mascara :=  P_Cuenta;
               End If;             
            End If;
         Else
            V_Cta_Mascara := Null;
         End If;   ---If  V_Existe = 'S' Then 
     Else
       V_Cta_Mascara := Null;
     End  If; --If  P_Cuenta Is Not Null Then 
      
     Return(V_Cta_Mascara);
          
   End;   
   --- Excello:JPH:2023-03-15: REQ_3550:End <<

END Cc_Utils;