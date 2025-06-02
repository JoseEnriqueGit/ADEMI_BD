CREATE OR REPLACE PACKAGE BODY CD.cd_interfaz_consulta
IS
   --
   -- OBJETIVO : Proveer rutinas para el control y validaciones de CD
   -- DESCRIPCION : Cada dato (cualquier tipo) que pertenece al esquema CD
   -- (Sistema de Certificados) y que sea necesitado por
   -- cualquier otro esquema, debe proveer una interfaz de consulta
   -- atravez de este paquete.
   -- HISTORIA : H01.- paris.sequeira - HBN-BSCZ-IMP001 - 25 de Junio 2007.
   -- Creacion.
   -- : Eblanco: 06-06-2011: Se incluyo en el cursos que retorna los certificados de un cliente
   -- para que muestre los certificados relacionados como cliente "O". modificacion en ObtieneCertificadoSaldos
   --
   FUNCTION obtienecertificadosaldos (
      pcodempresa     IN       VARCHAR2,    -- Empresa en la cual se consulta
      pcodcliente     IN       VARCHAR2,  -- Cliente al que se debe consultar
      pcoderror       IN OUT   VARCHAR2,
                                   -- Codigo de error generado, al consultar.
      pcertificados   IN OUT   cd_interfaz_consulta.tcertificadosdeposito
                                                 -- Datos de los certificados
   )
      RETURN BOOLEAN
   IS
      --
      -- OBJETIVO : Obtiene los certificados que tiene un cliente.
      -- DESCRIPCION : Segun una empresa y un cliente, se extraen los certificados de deposito
      -- que existen para el mismo.
      -- Esta funcion retorna un TRUE en caso de que la extraccion de datos no de error,
      -- o FALSE en caso contrario.
      -- HISTORIA : H01.- paris.sequeira - HBN-BSCZ-IMP001 - 25 de Junio 2008.
      -- Creacion.
      -- : Eblanco: 06-06-2011: Se incluyo en el cursos que retorna los certificados de un cliente
      -- para que muestre los certificados relacionados como cliente "O"
      -- : FLarsen 06/12/2012 Se agregan los certificados Mancomunados
      -- Definicon de Cursores
      -- Obtiene los datos de los certificados
      CURSOR ccertificados
      IS
         SELECT   cer.cod_empresa, cer.cod_agencia, cer.cliente,
                  cer.num_certificado, cer.cod_producto, cer.monto,
                  cer.estado, cer.fec_vencimiento, cer.tas_neta, cer.titular
             FROM cd_certificado cer
            WHERE cer.cod_empresa = pcodempresa
              AND cer.cliente = pcodcliente
              AND cer.estado IN ('A', 'R')
         -- EBlanco: 06-06-2011: Se incluyo a los cliente relacionados "O"
         UNION
         SELECT   b.cod_empresa, b.cod_agencia, a.codigo_cliente cod_cliente,
                  b.num_certificado, b.cod_producto, b.monto, b.estado,
                  b.fec_vencimiento, b.tas_neta, b.titular
             FROM pa.cuenta_cliente_relacion a, cd_certificado b
            WHERE b.cod_empresa = pcodempresa
              AND a.codigo_cliente = pcodcliente
              AND a.tipo_relacion IN
                     ('O', 'Y')
          -- = 'O' FLarsen 06/12/2012 Se agregan los certificados Mancomunados
              AND a.principal = 'N'
              AND a.num_cuenta = b.num_certificado
              AND b.estado IN ('A', 'R')
         ORDER BY num_certificado;

      -- Definicion de Variables
      -- Control del cursor
      vcantregistros   NUMBER := 0;
   BEGIN
      -- Se obtienen datos de certificados
      FOR cer IN ccertificados
      LOOP
         pcertificados (vcantregistros).cod_empresa := cer.cod_empresa;
         pcertificados (vcantregistros).cod_agencia := cer.cod_agencia;
         pcertificados (vcantregistros).cod_cliente := cer.cliente;
         pcertificados (vcantregistros).numero_certificado :=
                                                          cer.num_certificado;
         pcertificados (vcantregistros).cod_producto := cer.cod_producto;
         pcertificados (vcantregistros).monto := cer.monto;
         pcertificados (vcantregistros).estado := cer.estado;
         pcertificados (vcantregistros).fecha_vencimiento :=
                                                          cer.fec_vencimiento;
         pcertificados (vcantregistros).tasa_neta := cer.tas_neta;
         pcertificados (vcantregistros).titular := cer.titular;
         vcantregistros := NVL (vcantregistros, 0) + 1;
      END LOOP;

      IF vcantregistros = 0
      THEN
         pcoderror := '74';
         RETURN FALSE;
      ELSE
         RETURN (vcantregistros > 0);
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         pcoderror := '428';
         RETURN FALSE;
   END;

   --
   FUNCTION obtienedatoscertificado (
      pcodempresa       IN       VARCHAR2,   -- Empresa en la cual se consulta
      pcodagencia       IN       VARCHAR2,   -- Agencia en la cual se consulta
      pnumcertificado   IN       VARCHAR2,
                                       -- Certificado al que se debe consultar
      -- Flarsen 23/10/2013 Se ignora el usuario debido a que el procedimiento no compila por el Spec Diferente.
      -- pCertificado IN OUT cd.Cd_Interfaz_Consulta.tInfoCertificado, -- Datos del certificado
      pcertificado      IN OUT   cd_interfaz_consulta.tinfocertificado,
                                                      -- Datos del certificado
      pcoderror         OUT      VARCHAR2                   -- Codigo de Error
   )
      RETURN BOOLEAN
   IS
      --
      -- OBJETIVO : Obtiene datos generales de un certificado.
      -- DESCRIPCION : Segun una empresa, una agencia y un cliente, se extraen los datos de un certificado de deposito
      -- que existen para el mismo.
      -- Esta funcion retorna un TRUE en caso de que la extraccion de datos no de error,
      -- o FALSE en caso contrario.
      -- HISTORIA : H01.- paris.sequeira - HBN-BSCZ-IMP001 - 25 de Junio 2008.
      -- Creacion.
      --
      -- Definicion de Cursores
      -- Obtiene los datos de los certificados
      CURSOR ccertificado
      IS
         SELECT cer.cod_empresa, cer.cod_agencia, cer.cliente,
                cer.num_certificado, cer.cod_producto, cer.monto, cer.estado,
                cer.fec_emision, cer.fec_vencimiento, cer.tip_plazo,
                cer.pla_dias, cer.pla_meses, cer.tas_bruta, cer.tas_neta,
                cer.mon_int_x_pagar, cer.mon_retenido,
                NVL (cer.forma_pago_intereses,
                     cer.tip_certificado
                    ) forma_pago_intereses,
                cer.num_cuenta, cer.pla_capitaliza, cer.fre_capitaliza,
                cer.fec_prox_cap, INITCAP (cer.titular) titular
           FROM cd_certificado cer
          WHERE cer.cod_empresa = pcodempresa
            AND cer.num_certificado = pnumcertificado;

      -- Definicion de Variables
      -- Control del cursor
      vcantregistros   NUMBER := 0;
   BEGIN
      -- Se obtienen datos de certificados
      FOR cer IN ccertificado
      LOOP
         pcertificado.cod_empresa := cer.cod_empresa;
         pcertificado.cod_agencia := cer.cod_agencia;
         pcertificado.cod_cliente := cer.cliente;
         pcertificado.numero_certificado := cer.num_certificado;
         pcertificado.cod_producto := cer.cod_producto;
         pcertificado.monto := cer.monto;
         pcertificado.estado := cer.estado;
         pcertificado.fecha_emision := cer.fec_emision;
         pcertificado.fecha_vencimiento := cer.fec_vencimiento;
         pcertificado.tipo_plazo := cer.tip_plazo;
         pcertificado.plazo_dias := cer.pla_dias;
         pcertificado.plazo_meses := cer.pla_meses;
         pcertificado.tasa_bruta := cer.tas_bruta;
         pcertificado.tasa_neta := cer.tas_neta;
         pcertificado.interes_x_pagar := cer.mon_int_x_pagar;
         pcertificado.mon_retenido := cer.mon_retenido;
         pcertificado.forma_pago_int := cer.forma_pago_intereses;
         pcertificado.num_cuenta := cer.num_cuenta;
         pcertificado.pla_capitaliza := cer.pla_capitaliza;
         pcertificado.fre_capitaliza := cer.fre_capitaliza;
         pcertificado.fec_prox_cap := cer.fec_prox_cap;
         pcertificado.titular := cer.titular;
         vcantregistros := NVL (vcantregistros, 0) + 1;
      END LOOP;

      IF vcantregistros = 0
      THEN
         pcoderror := '442';
         RETURN FALSE;
      ELSE
         RETURN (vcantregistros > 0);
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         pcoderror := '442';
         RETURN FALSE;
   END;

   --
   FUNCTION obtienelistabeneficiarios (
      pcodempresa       IN       VARCHAR2,   -- Empresa en la cual se consulta
      pcodagencia       IN       VARCHAR2,   -- Agencia en la cual se consulta
      pnumcertificado   IN       VARCHAR2,
                                       -- Certificado al que se debe consultar
      plistabenef       IN OUT   cd_interfaz_consulta.tlistabeneficiarios
                                                      -- Datos del certificado
   )
      RETURN BOOLEAN
   IS
      --
      -- OBJETIVO    : Obtiene datos generales de los beneficiarios de un certificado.
      -- DESCRIPCION : Segun una empresa, una agencia y un certificado, se extraen los datos de los beneficiarios
      --               que existen para el mismo.
      --               Esta funcion retorna un TRUE en caso de que la extraccion de datos no de error,
      --               o FALSE en caso contrario.
      -- HISTORIA    : H01.- daniel.saborio - HBN-BSCZ-IMP001 - 11 de Julio 2007.
      --               Creacion.
      CURSOR cbeneficiarios
      IS
         SELECT    p.nombre
                || ' ('
                || TO_CHAR (porcentaje)
                || '%)'
                || '<br>&#160;&#160;&#160;' bene
           FROM cd_certificado c, cd_beneficiario a, personas p
          WHERE c.cod_empresa = pcodempresa
            AND c.cod_agencia = pcodagencia
            AND c.num_certificado = pnumcertificado
            AND a.cod_empresa = c.cod_empresa
            AND a.num_certificado = c.num_certificado
            AND p.cod_persona = a.cod_persona;

      vcantregistros   NUMBER := 0;
   BEGIN
      FOR tupla IN cbeneficiarios
      LOOP
         plistabenef (vcantregistros).nom_beneficiario := tupla.bene;
         vcantregistros := vcantregistros + 1;
      END LOOP;

      RETURN vcantregistros > 0;
   END;

   --
   FUNCTION obtienecupones (
      pcodempresa       IN       VARCHAR2,   -- Empresa en la cual se consulta
      pnumcertificado   IN       VARCHAR2,
                                       -- Certificado al que se debe consultar
      pcupones          IN OUT   cd_interfaz_consulta.tcupones,
                                                      -- Datos del certificado
      pcoderror         OUT      VARCHAR2                   -- Codigo de Error
   )
      RETURN BOOLEAN
   IS
      --
      -- OBJETIVO    : Obtiene cupones de un certificado.
      -- DESCRIPCION : Segun una empresa, una agencia y un certificado, se extraen los cupones de un certificado de deposito
      --               que existen para el mismo.
      --               Esta funcion retorna un TRUE en caso de que la extraccion de datos no de error,
      --               o FALSE en caso contrario.
      -- HISTORIA    : H01.- paris.sequeira - HBN-BSCZ-IMP001 - 25 de Junio 2008.
      --               Creacion.
      --
      -- Definicon de Cursores
      -- Obtiene los datos de los cupones
      CURSOR ccupones
      IS
         SELECT cup.cod_empresa, cer.cod_agencia, cer.cliente,
                cup.num_certificado, cup.numero_cupon, cup.monto_bruto,
                cup.monto_neto, cup.estado, cup.fecha_vencimiento,
                cup.fecha_pago, cup.pla_dias
           FROM cd_certificado cer, cd_cupon cup
          WHERE cer.cod_empresa = pcodempresa
            AND cer.num_certificado = pnumcertificado
            AND cup.cod_empresa = cer.cod_empresa
            AND cup.num_certificado = cer.num_certificado;

      -- Definicion de Variables
      -- Control del cursor
      vcantregistros   NUMBER := 0;
   BEGIN
      -- Se obtienen datos de cupones
      FOR cup IN ccupones
      LOOP
         pcupones (vcantregistros).cod_empresa := cup.cod_empresa;
         pcupones (vcantregistros).cod_agencia := cup.cod_agencia;
         pcupones (vcantregistros).cod_cliente := cup.cliente;
         pcupones (vcantregistros).numero_certificado := cup.num_certificado;
         pcupones (vcantregistros).numero_cupon := cup.numero_cupon;
         pcupones (vcantregistros).monto_bruto := cup.monto_bruto;
         pcupones (vcantregistros).monto_neto := cup.monto_neto;
         pcupones (vcantregistros).estado := cup.estado;
         pcupones (vcantregistros).fecha_vencimiento := cup.fecha_vencimiento;
         pcupones (vcantregistros).fecha_pago := cup.fecha_pago;
         pcupones (vcantregistros).plazo_dias := cup.pla_dias;
         vcantregistros := NVL (vcantregistros, 0) + 1;
      END LOOP;

      IF vcantregistros = 0
      THEN
         pcoderror := '75';
         RETURN FALSE;
      ELSE
         RETURN (vcantregistros > 0);
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         pcoderror := '75';
         RETURN FALSE;
   END;

   --
   FUNCTION obtienecertificadoscliente (
      pcodempresa   IN       VARCHAR2,                              -- Empresa
      pcodcliente   IN       NUMBER,                       -- Numero de cuenta
      pcuentas      IN OUT   cd_interfaz_consulta.tcertificadoscliente,
                                                         -- Datos de la cuenta
      pcoderror     OUT      VARCHAR2                       -- Codigo de Error
   )
      RETURN BOOLEAN
   IS
      --
      -- OBJETIVO    : Obtiene los certificados de deposito asociadas al cliente.
      -- DESCRIPCION : Segun una empresa y un codigo de ciente, se extrae informacion del tipo de producto,.
      --               moneda y numero del certificado.
      --               Esta funcion retorna un TRUE en caso de que la extraccion de datos no de error,
      --               o FALSE en caso contrario.
      -- HISTORIA    : H01.- Ricardo Valverde - HBN-BSCZ-IMP001 - 18 de Julio 2007.
      --               Creacion.
      --
      -- Definicon de Cursores
      -- Obtiene los datos de la cuenta
      CURSOR ccuentas
      IS
         SELECT cta.cod_producto, cta.cod_moneda,
                cta.num_certificado num_cuenta, cta.cod_agencia
           FROM cd_certificado cta
          WHERE cta.cod_empresa = pcodempresa
            AND cta.cliente = pcodcliente
            AND cta.estado IN ('A', 'R');

      -- Definicion de Variables
      -- Control del cursor
      vcantregistros   NUMBER := 0;
   BEGIN
      -- Se obtienen datos de la cuenta
      FOR cta IN ccuentas
      LOOP
         pcuentas (vcantregistros).cod_producto := cta.cod_producto;
         pcuentas (vcantregistros).cod_moneda := cta.cod_moneda;
         pcuentas (vcantregistros).num_certificado := cta.num_cuenta;
         pcuentas (vcantregistros).cod_agencia := cta.cod_agencia;
         pcuentas (vcantregistros).ind_mancomunada := 'N';

         IF pa_interfaz_consulta.esproductomancomunado (cta.num_cuenta, 'CD')
         THEN
            pcuentas (vcantregistros).ind_mancomunada := 'Y';
         END IF;

         vcantregistros := NVL (vcantregistros, 0) + 1;
      END LOOP;

      IF vcantregistros = 0
      THEN
         pcoderror := '74';
         RETURN FALSE;
      ELSE
         RETURN (vcantregistros > 0);
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         pcoderror := '74';
         RETURN FALSE;
   END obtienecertificadoscliente;

   --
   FUNCTION validacertificadoscliente (
      pcodempresa   IN       VARCHAR2,                              -- Empresa
      pcodcliente   IN       NUMBER,                       -- Numero de cuenta
      pcoderror     OUT      VARCHAR2                       -- Codigo de Error
   )
      RETURN BOOLEAN
   IS
      --
      -- OBJETIVO    : Valida si el cliente tiene certificados activos.
      -- DESCRIPCION : A partir de un codigo de cliente, la funcion valida si este tiene certificados
      --               activos asociadas.
      --               Esta funcion retorna un TRUE en caso de la condicion de la validacion se cumpla
      --               o FALSE en caso contrario.
      -- HISTORIA    : H01.- Ricardo Valverde - HBN-BSCZ-IMP001 - 18 de Julio 2007.
      --               Creacion.
      -- Definicion de Variables
      vcantregistros   NUMBER := 0;
   BEGIN
      -- Cuenta la cantidad de cuentas activas
      SELECT COUNT (*)
        INTO vcantregistros
        FROM cd_certificado
       WHERE cod_empresa = pcodempresa
         AND cliente = pcodcliente
         AND estado IN ('A', 'R');

      -- Si hay almenos un certificado, retorna cumple la validacion
      IF NVL (vcantregistros, 0) > 0
      THEN
         RETURN TRUE;
      ELSE
         RETURN FALSE;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN FALSE;
   END validacertificadoscliente;

   --
   FUNCTION validacertificadoidcliente (
      pcodempresa          IN       VARCHAR2,          -- Codigo de la empresa
      ptipidentificacion   IN       VARCHAR2,        -- Tipo de ID del cliente
      pnumidentificacion   IN       VARCHAR2,      -- Numero de ID del cliente
      pnumcertificado      IN       VARCHAR2,         -- Numero de certificado
      pcoderror            OUT      VARCHAR2                -- Codigo de Error
   )
      RETURN BOOLEAN
   IS
      --
      -- OBJETIVO    : Valida si el numero de certificado indicado pertenece al cliente con ID especificado.
      -- DESCRIPCION : A partir de un codigo y tipo de ID y un numero de prestamo, se valida si el
      --               certificado pertence al cliente con el numero de ID.
      --               Esta funcion retorna un TRUE en caso de la condicion de la validacion se cumpla
      --               o FALSE en caso contrario.
      -- HISTORIA    : H01.- Ricardo Valverde - HBN-BSCZ-IMP001 - 18 de Julio 2007.
      --               Creacion.
      -- Definicion de Variables
      vcantregistros   NUMBER                         := 0;
      vcodpersona      id_personas.cod_persona%TYPE;
      vestado          VARCHAR2 (1);
   BEGIN
      -- Se obtiene el codigo de persona que tiene asociado el ID
      BEGIN
         SELECT cod_persona
           INTO vcodpersona
           FROM id_personas
          WHERE cod_tipo_id = ptipidentificacion
            AND num_id = pnumidentificacion;
      EXCEPTION
         WHEN OTHERS
         THEN
            pcoderror := '422';
            RETURN FALSE;
      END;

      -- Se verficia que tenga productos activos.

      -- Cuenta la cantidad de cuentas activas
      BEGIN
         SELECT COUNT (*)
           INTO vcantregistros
           FROM cd_certificado
          WHERE cod_empresa = pcodempresa
            AND cliente = vcodpersona
            AND num_certificado = pnumcertificado;
      EXCEPTION
         WHEN OTHERS
         THEN
            pcoderror := '424';
            RETURN FALSE;
      END;

      -- Si hay almenos un certificado, retorna cumple la validacion
      IF NVL (vcantregistros, 0) > 0
      THEN
         -- Verificar el estado del producto
         BEGIN
            SELECT estado
              INTO vestado
              FROM cd_certificado
             WHERE cod_empresa = pcodempresa
               AND cliente = vcodpersona
               AND num_certificado = pnumcertificado;

            IF vestado NOT IN ('A', 'R')
            THEN
               pcoderror := '425';
               RETURN FALSE;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               pcoderror := '425';
               RETURN FALSE;
         END;

         RETURN TRUE;
      ELSE
         pcoderror := '424';
         RETURN FALSE;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         pcoderror := '0';
         RETURN FALSE;
   END validacertificadoidcliente;

   --
   FUNCTION obtienetasarendimientos (
      pcodempresa      IN   VARCHAR2,                 -- Codigo de la empresa.
      pplazodias       IN   NUMBER,                           -- Plazo en dias
      pmonto           IN   NUMBER,                   -- Monto de la inversion
      pmoneda          IN   VARCHAR2,                -- Moneda de la inversion
      pformacobroint   IN   VARCHAR2
                       -- Forma cobro interess (CF=capitalizables, CU=Cupones)
   )
      RETURN NUMBER
   IS
      --
      -- OBJETIVO    : Retorna los tasa de interes de acuerdon con la moneda, plazo, monto y tipo de cobo
      --               de los intereses.
      -- DESCRIPCION : Indicado el monto, plazo, forma de cobro de los intereses determina la tasa de interes.
      --               Esta funcion retorna 0 en caso de error en calculo o los interses en caso contrario.
      -- HISTORIA    : H01.- Ricardo Valverde - HBN-BSCZ-IMP001 - 9 de Octubre 2007.
      --               Creacion.
      --             : H02.- Flarsen 24/05/2013 Se cambia el alias de la tabla principal por el alias de la tabla anidada.
      --                   - Se agrega condicion para indicar la Rendencion Anticipada
      --             : H03.- - Flarsen 24/01/2014 Se filtra el producto debido a que se pueden encontrar fechas vigentes de otros Productos.
      --
      -- Definicion de Variables
      vcodtasa       VARCHAR (10)    := 0;
      vspread        NUMBER (10, 4)  := 0;
      voperacion     VARCHAR2 (1);
      vvalortasa     NUMBER (14, 4)  := 0;
      vtasaneta      NUMBER (14, 4)  := 0;
      vrenta         NUMBER (14, 4)  := 0;
      vfactorrenta   NUMBER (8, 5)   := 0;
      x              VARCHAR2 (1000);
   BEGIN
      -- Se obtiene el codigo de la tasa
      SELECT tas.cod_tasa, tas.spread, tas.operacion,
             NVL (porcentaje_renta, 0) renta
        INTO vcodtasa, vspread, voperacion,
             vrenta
        FROM cd_prd_tasa_plazo_monto tas,
             cd_producto_x_empresa prc,
             productos pro
       WHERE tas.cod_empresa = pcodempresa
         AND tas.estado = 'A'
         AND pplazodias BETWEEN tas.plazo_minimo AND tas.plazo_maximo
         AND pmonto BETWEEN tas.monto_minimo AND tas.monto_maximo
         -- Flarsen 24/05/2013 Se agrega condicion para indicar la Rendencion Anticipada
         AND prc.ind_redencion_ant = 'S'
         --
         AND tas.fecha_vigencia IN (
                SELECT MAX (tai.fecha_vigencia)
                  FROM cd_prd_tasa_plazo_monto tai,
                       cd_producto_x_empresa pri,
                       productos prd
                 WHERE tai.cod_empresa = pcodempresa
                   AND tai.estado = 'A'
                   AND pplazodias BETWEEN tai.plazo_minimo AND tai.plazo_maximo
                   AND pmonto BETWEEN tai.monto_minimo AND tai.monto_maximo
                   -- Flarsen 24/05/2013 Se agrega condicion para indicar la Rendencion Anticipada
                   AND pri.ind_redencion_ant = 'S'
                   --
                   AND tai.fecha_vigencia <= SYSDATE
                   -- Flarsen 24/05/2013 Se cambia el alias de la tabla principal por el alias de la tabla anidada.
                   AND pri.cod_empresa = tai.cod_empresa     --tas.cod_empresa
                   AND pri.cod_producto = tai.cod_producto  --tas.cod_producto
                   -- Flarsen 24/01/2014 Se filtra el producto debido a que se pueden encontrar fechas vigentes de otros Productos.
                   AND tai.cod_empresa = tas.cod_empresa
                   AND tai.cod_producto = tas.cod_producto
                   --
                   AND pri.forma_calculo_interes = pformacobroint
                   AND prd.cod_producto = prc.cod_producto
                   AND prd.cod_moneda = pmoneda)
         AND prc.cod_empresa = tas.cod_empresa
         AND prc.cod_producto = tas.cod_producto
         AND prc.forma_calculo_interes = pformacobroint
         AND pro.cod_cat_producto = 'CD'
         AND pro.cod_producto = prc.cod_producto
         AND pro.cod_moneda = pmoneda
         AND ROWNUM = 1;

         -- Se obtiene el valor actual de la tasa
      --
      SELECT val_tasa
        INTO vvalortasa
        FROM valores_tasas_interes
       WHERE cod_empresa = pcodempresa
         AND cod_tasa = vcodtasa
         AND fec_inicio IN (
                SELECT MAX (fec_inicio)
                  FROM valores_tasas_interes
                 WHERE cod_empresa = pcodempresa
                   AND cod_tasa = vcodtasa
                   AND fec_inicio <= SYSDATE);

      IF vvalortasa < 0
      THEN
         vvalortasa := 0;
      ELSIF voperacion = '+'
      THEN
         vvalortasa := NVL (vvalortasa, 0) + NVL (vspread, 0);
         vtasaneta := vvalortasa;
      ELSIF voperacion = '-'
      THEN
         vvalortasa := NVL (vvalortasa, 0) - NVL (vspread, 0);
         vtasaneta := vvalortasa;
      END IF;

      IF vvalortasa > 0
      THEN
         vfactorrenta := 1 - (NVL (vrenta, 0) / 100);
         vtasaneta := ((NVL (vvalortasa, 0) * 100) / vfactorrenta);
         vtasaneta := vtasaneta / 100;
      END IF;

      RETURN NVL (vtasaneta, 0);
   EXCEPTION
      WHEN OTHERS
      THEN
         x := SQLERRM;
         RETURN 0;
   END obtienetasarendimientos;

   --
   FUNCTION calcularendimientosmes (
      pmonto       IN   NUMBER,                       -- Monto de la inversion
      ptasaanual   IN   NUMBER                              -- Tasa de interes
   )
      RETURN NUMBER
   IS
      --
      -- OBJETIVO    : Retorna el monto de rendimientos de un mes.
      -- DESCRIPCION : Indicado el monto y la tasa anual, se calcula el monto de los interess de un mes.
      --               Esta funcion retorna 0 en caso de error en calculo o los interses en caso contrario.
      -- HISTORIA    : H01.- Ricardo Valverde - HBN-BSCZ-IMP001 - 8 de Setiembre 2007.
      --               Creacion.
      -- Definicion de Variables
      vinteres   NUMBER (18, 2) := 0;
   BEGIN
      RETURN NVL (NVL (pmonto, 0) * (ptasaanual / 12) / 100, 0);
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN 0;
   END calcularendimientosmes;

   --
   --
   FUNCTION obtieneproyecionrendimientos (
      pcodempresa           IN       VARCHAR2,         -- Codigo de la empresa
      pmontoinversion       IN       NUMBER,          -- Monto de la inversion
      pcantidadmeses        IN       NUMBER,   -- Cantidad de meses a invertir
      pindcapitalizable     IN       VARCHAR2,
                                          -- Si es Capitalizable S= si , N = N
      pmoneda               IN       VARCHAR2,             -- Codigo de moneda
      ptasainteres          OUT      NUMBER,                -- Tasa de interes
      prendimientomensual   OUT      NUMBER,
                                       -- Monto de los rendimientos mensuales.
      prendimientofinal     OUT      NUMBER,
                                      -- Rendimiento al vencimiento del plazo.
      ptablarendimientos    OUT      cd_interfaz_consulta.ttablarendimientos,
                                                      -- Tabla de Rendimientos
      pcoderror             OUT      VARCHAR2               -- Codigo de Error
   )
      RETURN BOOLEAN
   IS
      --
      -- OBJETIVO    : Proyecta los rendimientos de una inversion
      -- DESCRIPCION : A partir de un monto, un periodo, una moneda y un indicador de si se capitalizan o no
      --               los intereses, se retorna la proyeccion de los rendimientos de la inversion.
      --               Si no capitaliza, solamente retorna los rendimientos por mes y los totales.
      --               Si capitaliza, se retorna una tabla conteniendo los rendimientos.
      --               Esta funcion retorna un TRUE en caso de la condicion de la validacion se cumpla
      --               o FALSE en caso contrario.
      -- HISTORIA    : H01.- Ricardo Valverde - HBN-BSCZ-IMP001 - 8 de Setiembre 2007.
      --               Creacion.
      -- Definicion de Variables
      vinteresmes       NUMBER (18, 2) := 0;
      vinterestotal     NUMBER (18, 2) := 0;
      vmontoinversion   NUMBER (18, 2) := 0;
      vtasainteres      NUMBER (18, 2) := 0;
      vformacobroint    VARCHAR2 (2);
      vcantregistros    NUMBER         := 0;
   BEGIN
      vformacobroint := 'CU';

      IF NVL (pindcapitalizable, 'N') = 'S'
      THEN
         vformacobroint := 'CF';
      END IF;

      vtasainteres :=
         obtienetasarendimientos (pcodempresa,
                                  pcantidadmeses * 30,
                                  pmontoinversion,
                                  pmoneda,
                                  vformacobroint
                                 );
      ptasainteres := NVL (vtasainteres, 0);
      prendimientomensual := 0;
      prendimientofinal := 0;
      vmontoinversion := NVL (pmontoinversion, 0);

      IF NVL (pindcapitalizable, 'N') = 'N'
      THEN
         vinteresmes :=
            cd_interfaz_consulta.calcularendimientosmes (vmontoinversion,
                                                         vtasainteres
                                                        );
         vinterestotal := vinteresmes * NVL (pcantidadmeses, 0);
         prendimientomensual := NVL (vinteresmes, 0);
         prendimientofinal := NVL (vinterestotal, 0);
         vcantregistros := 1;
      ELSIF NVL (pindcapitalizable, 'N') = 'S'
      THEN
         FOR i IN 1 .. pcantidadmeses
         LOOP
            vinteresmes :=
               cd_interfaz_consulta.calcularendimientosmes (vmontoinversion,
                                                            vtasainteres
                                                           );
            ptablarendimientos (vcantregistros).indicador_mes := i;
            ptablarendimientos (vcantregistros).saldo_inicial :=
                                                      NVL (vmontoinversion, 0);
            ptablarendimientos (vcantregistros).interes :=
                                                          NVL (vinteresmes, 0);
            ptablarendimientos (vcantregistros).saldo_final :=
                                NVL (vmontoinversion, 0)
                                + NVL (vinteresmes, 0);
            vmontoinversion := NVL (vmontoinversion, 0) + NVL (vinteresmes, 0);
            vcantregistros := NVL (vcantregistros, 0) + 1;
         END LOOP;
      END IF;

      IF NVL (vcantregistros, 0) > 0
      THEN
         RETURN TRUE;
      ELSE
         pcoderror := '400';
         RETURN FALSE;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         pcoderror := '400';
         RETURN FALSE;
   END obtieneproyecionrendimientos;

   ---
   FUNCTION obtmensajecondiciones (
      pcodempresa       IN       VARCHAR2,                          -- Empresa
      pcodproducto      IN       VARCHAR2,                 -- Numero de cuenta
      pmonto            IN       VARCHAR2,                      --Monto del CD
      pplazo            IN       VARCHAR2,                            -- plazo
      ptasa             OUT      VARCHAR2,                             -- Tasa
      pmsjcondiciones   OUT      VARCHAR2,         -- Mensaje con condiciones.
      psistemaerror     OUT      VARCHAR2,     -- Sistema del codigo de error.
      pcoderror         OUT      VARCHAR2        -- Codigo del Error en Banca.
   )
      RETURN BOOLEAN
   IS
      /* modificado por HJORGE
      FUNCTION obtMensajeCondiciones (pCodEmpresa     IN  VARCHAR2, -- Empresa
                                      pNumCertificado IN  VARCHAR2, -- Numero de cuenta
                                      pMsjCondiciones OUT VARCHAR2, -- Mensaje con condiciones.
                                      pSistemaError   OUT VARCHAR2, -- Sistema del codigo de error.
                                      pCodError       OUT VARCHAR2  -- Codigo del Error en Banca.
                                     ) RETURN BOOLEAN IS
       */--
         -- OBJETIVO    : Retorna un mensaje con las condiciones del certificado y de la penalidad.
         -- DESCRIPCION : Se retorna un mensaje con las condiciones del certifica y cualquier informacion
         --               relacionada con la penalidad por cancelacion anticipada.
         --               Esta funcion retorna un TRUE en caso de la condicion de la validacion se cumpla
         --               o FALSE en caso contrario.
         -- HISTORIA    : H01.- Ricardo Valverde - HBN-BSCZ-IMP001 - 05 de Febrero 2008.
         --               Creacion.
         -- Definicion de Variables.
      vmsjcondiciones1   VARCHAR2 (5000);
      vmsjcondiciones2   VARCHAR2 (5000);
      vcod_tasa          cd_prd_tasa_plazo_monto.cod_tasa%TYPE;
      voper              VARCHAR2 (1);
      vspread            cd_prd_tasa_plazo_monto.spread%TYPE;
      vfecha             DATE;
      vcoderror          VARCHAR2 (10);
   BEGIN
      -- Se obtiene la fecha del calendario.
      pa.pa_interfaz_consulta.obtfecactualcalendario (pcodempresa,
                                                      'CC',
                                                      NULL,
                                                      vfecha,
                                                      vcoderror
                                                     );

      IF vcoderror IS NOT NULL
      THEN
         pcoderror := vcoderror;
         RETURN FALSE;
      END IF;

      -- Busco el codigo de la tasa
      BEGIN
         SELECT cod_tasa, operacion,
                spread
   -- por HJORGE 29/06/2009 -- Calculo de la Tasa tomando en cuenta el spread.
           INTO vcod_tasa, voper,
                vspread
           FROM cd_prd_tasa_plazo_monto
          WHERE cod_empresa = pcodempresa
            AND cod_producto = pcodproducto
            AND estado = 'A'
            AND pmonto BETWEEN monto_minimo AND monto_maximo
            AND (pplazo * 30.4) BETWEEN plazo_minimo AND plazo_maximo
            AND fecha_vigencia <= vfecha;
      EXCEPTION
         WHEN OTHERS
         THEN
            vcod_tasa := NULL;
            psistemaerror := 'CD';
            pcoderror := '0';
            RETURN FALSE;
      END;

      IF vcod_tasa IS NOT NULL
      THEN
         BEGIN
            -- busco el valor de la tasa
            SELECT DECODE (voper,
                           '-', (val_tasa - vspread),
                           '+', (val_tasa + vspread)
                          ) val_tasa
   -- por HJORGE 29/06/2009 -- Calculo de la Tasa tomando en cuenta el spread.
              INTO ptasa
              FROM valores_tasas_interes
             WHERE cod_empresa = pcodempresa
               AND cod_tasa = vcod_tasa
               AND fec_inicio IN (
                      SELECT MAX (fec_inicio)
                        FROM valores_tasas_interes
                       WHERE cod_empresa = pcodempresa
                         AND cod_tasa = vcod_tasa
                         AND fec_inicio <= vfecha);
         EXCEPTION
            WHEN OTHERS
            THEN
               ptasa := NULL;
               psistemaerror := 'CD';
               pcoderror := '0';
               RETURN FALSE;
         END;
      END IF;

      -- Retorna el mensaje;
      vmsjcondiciones1 :=
         pa_interfaz_consulta.obtieneparametroempresa ('CD',
                                                       pcodempresa,
                                                       'MENSAJE_PENALIDAD1'
                                                      );

      IF vmsjcondiciones1 IS NULL
      THEN
         psistemaerror := 'CD';
         pcoderror := '000668';
         RETURN FALSE;
      END IF;

      vmsjcondiciones2 :=
         pa_interfaz_consulta.obtieneparametroempresa ('CD',
                                                       pcodempresa,
                                                       'MENSAJE_PENALIDAD2'
                                                      );

      IF vmsjcondiciones2 IS NULL
      THEN
         psistemaerror := 'CD';
         pcoderror := '000668';
         RETURN FALSE;
      END IF;

      pmsjcondiciones := vmsjcondiciones1 || ' ' || vmsjcondiciones2;
      RETURN TRUE;
   EXCEPTION
      WHEN OTHERS
      THEN
         psistemaerror := 'CD';
         pcoderror := '409';
         RETURN FALSE;
   END obtmensajecondiciones;

   FUNCTION obtienematrizcertificados (
      pcodempresa          IN       VARCHAR2,          -- Codigo de la empresa
      pcodproducto         IN       VARCHAR2,           -- Codigo del Producto
      pcodmoneda           OUT      VARCHAR2,
      pcoderror            OUT      VARCHAR2,               -- Codigo de Error
      ptablacertificados   OUT      cd_interfaz_consulta.ttablacertificados
                                                     -- Matriz de Certificados
   )
      RETURN BOOLEAN
   IS
-- -------------------------------------------------------------------------------------------------------- --
-- EFECTUA:                                                                                                                    --
--            Crea una tabla matricial con los valores de las tasas agrupadas por plazo               --
--                                                                                                                                    --
-- REQUIERE:                                                                                                                   --
--            N/A                                                                                                                   --
--                                                                                                                                     --
-- Historia:                                                                                                                       --
--          Flarsen 24/10/2013                                                                                              --
--          Se ignora debido a que el plazo de 720 no se esta cargando,  el plazo correcto para --
--          este columna es 99999                                                                                         --
--          Se agrega asignacion para completar la columna a 360 Dias de plazo.                      --
-- -------------------------------------------------------------------------------------------------------- --
      CURSOR ccertificados (pcodigo_producto VARCHAR2)
      IS
         SELECT   monto_minimo, monto_maximo,
                  MAX (CASE
                          WHEN plazo = 30
                             THEN val_tasa
                       END) AS "DIAS30",
                  MAX (CASE
                          WHEN plazo = 60
                             THEN val_tasa
                       END) AS "DIAS60",
                  MAX (CASE
                          WHEN plazo = 90
                             THEN val_tasa
                       END) AS "DIAS90",
                  MAX (CASE
                          WHEN plazo = 120
                             THEN val_tasa
                       END) AS "DIAS120",
                  MAX (CASE
                          WHEN plazo = 180
                             THEN val_tasa
                       END) AS "DIAS180",
                  MAX (CASE
                          WHEN plazo = 360
                             THEN val_tasa
                       END) AS "DIAS360",
                  MAX (CASE
                          WHEN plazo = 540
                             THEN val_tasa
                       END) AS "DIAS540"
                                        -- Flarsen 24/10/2013 Se ignora debido a que el plazo de 720 no se esta cargando,
                                        -- el plazo correcto para este columna es 99999
                                        -- ,MAX(CASE WHEN plazo = 720 THEN val_tasa END) AS "DIAS720"
                  ,
                  MAX (CASE
                          WHEN plazo = 99999
                             THEN val_tasa
                       END) AS "DIAS720"
             FROM (SELECT                           --tm.*, vt.*
                                                    --tm.plazo_minimo as plazo
                          tm.plazo_maximo AS plazo
-- El plazo comparado para colocar la tasa esta en el plazo maximo, no en el minimo ; Acombes 30/03/2010
                                                  ,
                          tm.monto_minimo, tm.monto_maximo, vt.cod_tasa,
                          DECODE (tm.operacion,
                                  '-', (vt.val_tasa - tm.spread),
                                  '+', (vt.val_tasa + tm.spread)
                                 ) val_tasa
                                           --,vt.val_tasa, -- comentado por HJORGE 29/06/2009 -- Calculo de la Tasa tomando en cuenta el spread.
                          ,
                          tm.cod_producto
                     FROM cd_prd_tasa_plazo_monto tm,
                          valores_tasas_interes vt
                    WHERE tm.cod_empresa = pcodempresa
                      AND tm.cod_empresa = vt.cod_empresa
                      AND tm.cod_tasa = vt.cod_tasa
                      AND tm.cod_producto = pcodigo_producto             --300
                      AND tm.estado = 'A'
                      AND vt.fec_inicio IN (
                             SELECT MAX (fec_inicio)
                               FROM valores_tasas_interes
                              WHERE cod_empresa = pcodempresa
                                AND cod_tasa = vt.cod_tasa
                                AND fec_inicio <= SYSDATE))
         GROUP BY monto_minimo, monto_maximo, cod_producto
         ORDER BY 1;

      vcantregistros   NUMBER := 0;
   BEGIN
      -- Moneda del CD
      BEGIN
         SELECT cod_moneda
           INTO pcodmoneda
           FROM productos
          WHERE cod_cat_producto = 'CD' AND cod_producto = pcodproducto;
      EXCEPTION
         WHEN OTHERS
         THEN
            pcodmoneda := NULL;
            pcoderror := '0';
      END;

      --

      -- Se obtienen datos de la cuenta
      FOR cd IN ccertificados (pcodproducto)
      LOOP
         ptablacertificados (vcantregistros).monto_minimo := cd.monto_minimo;
         ptablacertificados (vcantregistros).monto_maximo := cd.monto_maximo;
         ptablacertificados (vcantregistros).dias_30 := cd.dias30;
         ptablacertificados (vcantregistros).dias_60 := cd.dias60;
         ptablacertificados (vcantregistros).dias_90 := cd.dias90;
         ptablacertificados (vcantregistros).dias_120 := cd.dias120;
         ptablacertificados (vcantregistros).dias_180 := cd.dias180;
         -- Flarsen 24/10/2013 Se agrega asignacion para completar la columna a 360 Dias de plazo.
         ptablacertificados (vcantregistros).dias_360 := cd.dias360;
         ptablacertificados (vcantregistros).dias_540 := cd.dias540;
         ptablacertificados (vcantregistros).dias_720 := cd.dias720;
         vcantregistros := NVL (vcantregistros, 0) + 1;
      END LOOP;

      RETURN (vcantregistros > 0);
   EXCEPTION
      WHEN OTHERS
      THEN
         pcoderror := '410';
         RETURN FALSE;
   END obtienematrizcertificados;
END cd_interfaz_consulta;
/
