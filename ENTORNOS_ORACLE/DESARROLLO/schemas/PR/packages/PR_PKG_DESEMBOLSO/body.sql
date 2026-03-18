create or replace PACKAGE BODY    PR_PKG_DESEMBOLSO
AS
    FUNCTION Get_Mensaje_Err (P_Mensaje IN VARCHAR2, P_Sistema IN VARCHAR2)
        RETURN VARCHAR2
    IS
        V_Mensaje   Mensajes_Sistema.Texto%TYPE;
    BEGIN
        SELECT Texto
          INTO V_Mensaje
          FROM Mensajes_Sistema
         WHERE Cod_Sistema = P_Sistema AND Num_Mensaje = P_Mensaje;

        RETURN (V_Mensaje);
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            RETURN (NULL);
    END;

    FUNCTION F_Etiqueta (Pbloque IN VARCHAR2, Pcampo IN VARCHAR2)
        RETURN VARCHAR2
    IS
        Vetiqueta   VARCHAR2 (500);
    BEGIN
        SELECT Etiqueta
          INTO Vetiqueta
          FROM Etiquetas_Formas
         WHERE     Nom_Forma = 'PR0110'
               AND Nom_Bloque = Pbloque
               AND Nom_Campo = Pcampo;

        RETURN Vetiqueta;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END;


    PROCEDURE Obtiene_Parametros (pMensaje_Error IN OUT VARCHAR2)
    IS
    BEGIN
        ET_MENS23 := F_ETIQUETA ('ETIQUETAS', 'ET_MENS23');
        ET_ETIQ1 := F_ETIQUETA ('ETIQUETAS', 'ET_ETIQ1');
        ET_ETIQ2 := F_ETIQUETA ('ETIQUETAS', 'ET_ETIQ2');
        ET_Mens8 := F_ETIQUETA ('ETIQUETAS', 'ET_MENS8');

        ET_Descripcion3 := F_ETIQUETA ('ETIQUETAS', 'ET_DESCRIPCION3');
        ET_DESCRIPCION4 := F_ETIQUETA ('ETIQUETAS', 'ET_DESCRIPCION4');
        ET_Descripcion5 := F_ETIQUETA ('ETIQUETAS', 'ET_DESCRIPCION5');
        ET_Observaciones := F_ETIQUETA ('ETIQUETAS', 'ET_OBSERVACIONES');

        V_Sub_Trans :=
            Param.Parametro_X_Empresa ('1', 'DESEMBOLSO_PRESTAMO', 'PR');
    EXCEPTION
        WHEN OTHERS
        THEN
            pMensaje_Error := 'Error cargando parametros operacioneales ';
            RETURN;
    END;

    PROCEDURE Formatea_Cuenta (Cuenta_Fuente   IN OUT NUMBER,
                               Verror          IN OUT NUMBER)
    IS
        --
        -- Este Proceso Se Encarga De Formatear Una Cuenta
        -- Recibe Como Parametro El Numero De La Cuenta
        -- Y Devuelve La Cuenta Formateada.
        -- La Variable Error Devuelve Lo Siguiente
        --            0  No Hubo Errores
        --            1  La Cuenta Es Nula
        --            9  Otro Error Ocurrio
        Cuenta_Destino   NUMBER (14);
    BEGIN
        Verror := 0;

        IF (Cuenta_Fuente IS NULL)
        THEN
            Verror := 1;                                 -- La Cuenta Es  Nula
        ELSE
            Cuenta_Destino :=
                TO_NUMBER (
                       SUBSTR (TO_CHAR (Cuenta_Fuente), 1, 1)
                    || LPAD (SUBSTR (TO_CHAR (Cuenta_Fuente), 2), 13, '0'));
            Cuenta_Fuente := Cuenta_Destino;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            Verror := 9;
            RETURN;
    END;

    PROCEDURE Valida_Existencia_Cuenta (Cuenta                  NUMBER,
                                        Empresa                 VARCHAR2,
                                        Moneda                  NUMBER,
                                        C_Cliente               VARCHAR2,
                                        Es_De_Personas          BOOLEAN,
                                        Verror           IN OUT NUMBER)
    IS
        -- Este Procedimiento Se Encarga De Validar Que Una Cuenta Exista
        -- Recibe El Numero De La Cuenta,Moneda,  El Codigo De La Empresa Y
        -- Opcionalmente
        -- Un Codigo De Cliente Y Un Indicador Con Los Siguientes Valores
        -- True  : El Codigo De Cliente Es Igual Al De La Tabla Personas.
        -- False : El Codigo De Cliente Debe Ser Convertido Igual Al De Personas
        -- Envie Null En Los Campos Que No Quiere Que Se Utilicen
        -- Los Posibles Valores De Error Son :
        --             0   Nu Hubo Errores, La Cuenta Existe
        --             1   No Encontro Cliente En Tabla Cliente
        --             2   No Encontro La Cuenta Contable
        --             3   La Cuenta No Pertenece Al Cliente
        --             4   No Existe Moneda De La Cuenta
        --             5   La Moneda De La Cuenta Es Diferente A Moneda Buscada
        --             6   La Cuenta Es Nula
        --             7   La Cuenta No Existe O No Esta Activa
        --
        Codigo_Cliente    VARCHAR2 (15);
        Cod2_Cliente      VARCHAR2 (15);
        Num_Error         NUMBER (1);
        Codigo_Producto   VARCHAR2 (4);
        --  Cod2_Producto     VARCHAR2 (4);
        Codigo_Moneda     NUMBER (4);
        V_Estado_Cta      VARCHAR2 (1);
    BEGIN
        Verror := 0;

        IF Cuenta IS NOT NULL
        THEN
            IF C_Cliente IS NOT NULL
            THEN
                IF NOT Es_De_Personas
                THEN
                    Num_Error := 1;    -- No Encontro Cliente En Tabla Cliente

                    SELECT Cod_Cliente
                      INTO Codigo_Cliente
                      FROM Cliente
                     WHERE Cod_Empresa = Empresa AND C_Cliente = Num_Cliente;
                ELSE
                    Codigo_Cliente := C_Cliente;
                END IF;
            ELSE
                Codigo_Cliente := NULL;
            END IF;

            Num_Error := 2;                    -- No Existe La Cuenta Contable

            BEGIN
                SELECT Cod_Cliente, Cod_Producto, Ind_Estado
                  INTO Cod2_Cliente, Codigo_Producto, V_Estado_Cta
                  FROM Cuenta_Efectivo
                 WHERE Cod_Empresa = Empresa AND Num_Cuenta = Cuenta;

                IF Codigo_Cliente IS NOT NULL
                THEN
                    IF Codigo_Cliente != Cod2_Cliente
                    THEN
                        Verror := 3;       --La Cuenta No Pertenece Al Cliente
                    END IF;
                END IF;

                IF V_Estado_Cta = '6'
                THEN                        --malmanzar 09-02-2022 Req. 140573
                    UPDATE Cuenta_Efectivo
                       SET Ind_Estado = '1'
                     WHERE Cod_Empresa = Empresa AND Num_Cuenta = Cuenta;

                    V_Estado_Cta := '1';
                END IF;

                IF V_Estado_Cta NOT IN ('1', '6')
                THEN
                    Verror := 7;
                END IF;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    Verror := 7;
            END;

            IF Verror = 0
            THEN
                Num_Error := 4;            -- No Existe La Moneda De La Cuenta

                SELECT TO_NUMBER (Cod_Moneda)
                  INTO Codigo_Moneda
                  FROM Productos
                 WHERE     Cod_Empresa = Empresa
                       AND Cod_Producto = Codigo_Producto;

                IF Codigo_Moneda != Moneda
                THEN
                    Verror := 5;                 --Cuenta Con Moneda Diferente
                END IF;
            END IF;
        ELSE
            Verror := 6;                                     -- Cuenta Es Nula
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            Verror := Num_Error;
    END;

    PROCEDURE P_Datos_Adicionales_Credito (
        P_Cod_Empresa             IN     VARCHAR2,
        P_Credito                 IN     NUMBER,
        V_Ind_Cred_Univ              OUT VARCHAR2,
        V_Oficial_Autorizado         OUT VARCHAR2,
        V_Grupo_Tipo_Credito         OUT VARCHAR2,
        V_Saldo_Disponible           OUT NUMBER,
        V_Saldo_Actual               OUT NUMBER,
        V_Dias_Periodo_Cuota         OUT NUMBER,
        V_Dias_Periodo_Interes       OUT NUMBER,
        V_Dias_Periodo_Comision      OUT NUMBER,
        V_Msg_Err                    OUT VARCHAR2)
    IS
        V_Mensaje_Error   VARCHAR2 (6) := NULL;
        V_Encontrado      VARCHAR2 (1) := 'S';
        -- Veslineamultiple  Varchar2(1) := Null;
        --Vtipcredorigen    Number      := Null;
        V_Cr              Pr_Creditos%ROWTYPE;
    --T_Abrev           Monedas.Abreviatura%Type;


    BEGIN
        --- Carga registro del credito --
        BEGIN
            SELECT *
              INTO V_Cr
              FROM Pr_Creditos
             WHERE Codigo_Empresa = P_Cod_Empresa AND No_Credito = P_Credito;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                V_Encontrado := 'N';
        END;

        IF V_Encontrado = 'S'
        THEN
            BEGIN
                SELECT NVL (Ind_Credito_Universitario, 'N'),
                       NVL (Oficial_Autorizado, 'N'),
                       Grupo_Tipo_Credito
                  INTO V_Ind_Cred_Univ,
                       V_Oficial_Autorizado,
                       V_Grupo_Tipo_Credito
                  FROM Pr_Tipo_Credito
                 WHERE     Codigo_Empresa = V_Cr.Codigo_Empresa
                       AND Tipo_Credito = V_Cr.Tipo_Credito;
            EXCEPTION
                WHEN OTHERS
                THEN
                    V_Ind_Cred_Univ := 'N';
                    V_Oficial_Autorizado := 'N';
                    V_Grupo_Tipo_Credito := NULL;
            END;


            V_Saldo_Disponible :=
                Saldo_Disponible_Pr (V_Cr.Codigo_Empresa,
                                     'ESPA',
                                     V_Cr.No_Credito);

            Pr_Plan.Calcular_Saldo_Movimientos (
                V_Cr.Codigo_Empresa,
                V_Cr.No_Credito,
                NVL (V_Cr.F_Primer_Desembolso, V_Cr.F_Apertura),
                V_Fecha_Sist,
                V_Saldo_Actual,
                V_Mensaje_Error);

            IF V_Mensaje_Error IS NOT NULL
            THEN
                V_Msg_Err := Get_Mensaje_Err (V_Mensaje_Error, 'PR');
                RETURN;
            END IF;

            --- Datos sobre Periodicidad ----
            BEGIN
                SELECT Dias_Periodo
                  INTO V_Dias_Periodo_Cuota
                  FROM Pr_Periodicidad
                 WHERE Codigo_Periodo = V_Cr.Codigo_Periodo_Cuota;

                IF V_Cr.Tipo_Cuota = 'M'
                THEN
                    SELECT Dias_Periodo
                      INTO V_Dias_Periodo_Interes
                      FROM Pr_Periodicidad
                     WHERE Codigo_Periodo = V_Cr.Codigo_Periodo_Intereses;
                END IF;

                IF V_Cr.Tipo_Comision IS NOT NULL
                THEN
                    SELECT Dias_Periodo
                      INTO V_Dias_Periodo_Comision
                      FROM Pr_Periodicidad
                     WHERE Codigo_Periodo = V_Cr.Periodo_Comision_Normal;
                END IF;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    -- Error: La Periodicidad No Existe
                    V_Msg_Err := Get_Mensaje_Err ('000382', 'PR');
                WHEN TOO_MANY_ROWS
                THEN
                    -- La Periodicidad Está Duplicada
                    V_Msg_Err := Get_Mensaje_Err ('000383', 'PR');
                WHEN OTHERS
                THEN
                    V_Msg_Err := Get_Mensaje_Err ('000032', 'PR');
            END;
        END IF;
    END;

    FUNCTION Cuotas_Atrasadas (P_Codigo_Empresa         NUMBER,
                               P_No_Credito             NUMBER,
                               P_Fecha_Calendario       DATE,
                               P_Error              OUT VARCHAR2)
        RETURN NUMBER
    IS
        --
        -- Variables Locales.
        V_Cantidad_Cuotas   NUMBER := 0;
    BEGIN
        SELECT COUNT (1)
          INTO V_Cantidad_Cuotas
          FROM Pr_Plan_Pagos Ppp
         WHERE     Ppp.Codigo_Empresa = P_Codigo_Empresa
               AND Ppp.No_Credito = P_No_Credito
               AND Ppp.Estado != 'C'
               AND Ppp.F_Cuota <= P_Fecha_Calendario;

        RETURN V_Cantidad_Cuotas;
    EXCEPTION
        WHEN OTHERS
        THEN
            P_Error := SQLERRM;
            RETURN V_Cantidad_Cuotas;
    END;


    PROCEDURE Inserta_Monitor (Estado_Cliente VARCHAR2)
    IS
    /************************************************************************************** **
    ** Procedimiento Que Se Encarga De Insertar A Bitacora_Monitor Las Transacciones De Los **
    ** Clientes Que Se Encuentre En Estado R - Restringido                                  **
    ** Rceballos 12/04/2010                                                                 **
    *************************************************************************************** **/
    BEGIN
        Pa.Audita_Transaccion (
            Ptiporegistro       => '1',
            Pcodsistema         => 'PR',
            Porigentx           => 'PR',
            Ptipotx             => 3,      --Tipo De Movimiento Del Desembolso
            Psubtipotx          => '',
            Pfechatx            => TO_CHAR (V_Fecha_Sist, 'YYYYMMDD'), --Fechatx
            Phoratx             => TO_CHAR (SYSDATE, 'Hh24miss'),     --Horatx
            Pusuariotx          => USER,
            Pusuariomod         => '',                        --Usuario Modif.
            Pusuariorev         => '',                       --Usuario Reversa
            Pusuarioaut         => '',                      --Usuario Autoriza
            Pfechamod           => '',                    --Fecha Modificacion
            Pfecharev           => '',                       --Fecha Reversion
            Pfechaaut           => '',                    --Fecha Autorizacion
            Pagencia            => Bkcredit.Codigo_Empresa,
            Preferencia         => '', -- Nulo Por Que No Se Obtiene Al Momento De Enviar
            Pnumcuenta          => NULL,
            Pmontotx            => 0, --Mto Del Ingreso De La Moneda Destino(Extranjera)
            Pmontoefectivo      => 0,
            Pmontodocumento     => 0, --Mto Del Ingreso De La Moneda Destino(Extranjera)
            Pmontockpropio      => 0,
            Pmontockotros       => 0,
            Preverso            => '',
            Pmonedatx           => Bkcredit.Codigo_Moneda, --Moneda De La Transaccion
            Pcodcliente         => Bkcredit.Codigo_Cliente, --Codigo Del Cliente
            Pnumerodocumento    => '',
            Pcodcajero          => '',                     --Codigo Del Cajero
            Ptasacambio         => NULL,                      --Tasa De Cambio
            Pestadomovimiento   => 'I',
            Pdescripciontx      => '',
            Pnumautorizacion    => '',
            Pnumtarjeta         => NULL,
            Ptabla              => '',
            Pdatosantes         => NULL,
            Pdatosdespues       => NULL,
            Pestadocliente      => Estado_Cliente);
    END;

    PROCEDURE Prevalida_Credito (P_Msg_Error OUT VARCHAR2)
    IS
        V_Mensaje             VARCHAR2 (6);
        Dias_Vencidos         NUMBER (5);
        Cliente_Restringido   VARCHAR2 (1);
        Vestadocliente        VARCHAR2 (1);
        Valerta               NUMBER;
        V_Cant_Cuotas         NUMBER;
        V_Error               VARCHAR2 (500);
        Salir                 EXCEPTION;
    BEGIN
        IF Bkcredit.Ind_Credito_Universitario = 'S'
        THEN
            V_Cant_Cuotas :=
                Cuotas_Atrasadas (Bkcredit.Codigo_Empresa,
                                  Bkcredit.No_Credito,
                                  V_Fecha_Sist,
                                  V_Error);

            IF V_Error IS NULL AND V_Cant_Cuotas > 0
            THEN
                P_Msg_Error :=
                    REPLACE (Get_Mensaje_Err ('001849', 'PR'),
                             '@',
                             TO_CHAR (V_Cant_Cuotas));
                RAISE Salir;
            END IF;

            IF V_Error IS NOT NULL
            THEN
                P_Msg_Error := Get_Mensaje_Err ('001850', 'PR');
                RAISE Salir;
            END IF;
        END IF;

        -- ----------------------------------------------------------------------------------------- --
        -- Si Es Un Cliente Restringido, Notificamos Y No Permitimos Que Se Puedan Seguir Ejecutando --
        -- Las Operaciones De Esta Forma [Proyecto Inactivacion Y Bloqueo De Clientes]               --
        -- Rceballos 22/03/2010                                                                      --
        -- ----------------------------------------------------------------------------------------- --
        BEGIN
            SELECT DISTINCT 'S', Per.Estado_Persona
              INTO Cliente_Restringido, Vestadocliente
              FROM Personas Per
             WHERE     Per.Cod_Persona = Bkcredit.Codigo_Cliente
                   AND Per.Estado_Persona = 'R';
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                Cliente_Restringido := 'N';
        END;

        IF NVL (Cliente_Restringido, 'N') = 'S'
        THEN
            P_Msg_error :=
                'No se puede ejecutar esta operación, debido a que el cliente está Restringido.';
            Inserta_Monitor (Vestadocliente);
            RAISE Salir;
        END IF;

        --
        Pr_Procs.Verifica_Vencimiento (Bkcredit.Codigo_Empresa,
                                       Bkcredit.No_Credito,
                                       V_Fecha_Sist,
                                       Dias_Vencidos,
                                       V_Mensaje);

        IF V_Mensaje IS NOT NULL
        THEN
            P_Msg_Error := Get_Mensaje_Err (V_Mensaje, 'PR');
            RAISE Salir;
        END IF;
    --        If  Bkcredit.Saldo_Disponible <= 0 Then
    --            P_Msg_Error := Get_Mensaje_Err('000534','PR');
    --            Raise Salir;
    --        End If;

    EXCEPTION
        WHEN Salir
        THEN
            RETURN;
    END;

    PROCEDURE Descontar_Cuota (P_Msj_Error IN OUT VARCHAR2)
    IS
        ---------
        V_F_Gracia_Hasta    DATE;
        V_Periodicidad      NUMBER;
        V_Fecha_Hasta       DATE;
        V_Dias_Periodo      NUMBER;
        V_Dia_Pago          VARCHAR2 (2);
        V_Msj_Error         VARCHAR2 (100);
        V_Dias_Calendario   NUMBER;
    BEGIN
        IF (Bkcredit.Tipo_Calendario IN (1, 4))
        THEN
            V_Dias_Calendario := 365;
        ELSE
            V_Dias_Calendario := 360;
        END IF;

        IF (Bkcredit.Tipo_Cuota = 'M')
        THEN
            V_Periodicidad := Bkcredit.Dias_Periodo_Interes;
        ELSE
            V_Periodicidad := Bkcredit.Dias_Periodo_Cuota;
        END IF;

        --
        V_Dia_Pago := TO_CHAR (Bkdesem.Fecha_Desembolso, 'Dd');
        Pr_Plan.Fecha_Cuota_Sig (Bkdesem.Fecha_Desembolso,
                                 V_Dia_Pago,
                                 V_Dia_Pago,
                                 V_Periodicidad,
                                 Bkcredit.Tipo_Calendario,
                                 V_Fecha_Hasta,
                                 V_Msj_Error);

        IF (V_Fecha_Hasta > Bkcredit.F_Vencimiento)
        THEN
            Restar_Fechas (Bkcredit.F_Vencimiento,
                           Bkdesem.Fecha_Desembolso,
                           V_Dias_Calendario,
                           V_Periodicidad,
                           V_Msj_Error);
            V_Fecha_Hasta := Bkcredit.F_Vencimiento;
        ELSE
            Restar_Fechas (V_Fecha_Hasta,
                           Bkdesem.Fecha_Desembolso,
                           365,
                           V_Dias_Periodo,
                           P_Msj_Error);

            IF (Bkcredit.Tipo_Calendario IN (1, 4))
            THEN
                V_Periodicidad := V_Dias_Periodo;
            END IF;
        END IF;

        --
        IF (Bkcredit.F_Primer_Desembolso IS NOT NULL)
        THEN
            Bkcredit.Dias_Intereses := 0;
            Bkcredit.F_Intereses_Hasta := Bkcredit.F_Ultimo_Pago_Intereses;
            Bkdesem.Monto_Cuota := 0;
            Bkdesem.Monto_Cuota_Principal := 0;
            Bkdesem.Monto_Cuota_Intereses := 0;
            RETURN;
        END IF;

        --
        IF (Bkcredit.Tipo_Intereses = 'A')
        THEN
            Bkcredit.Dias_Intereses := V_Periodicidad;
            Bkcredit.F_Intereses_Hasta := V_Fecha_Hasta;
            --
            Pr_Procs.Agregar_Dias (Bkdesem.Fecha_Desembolso,
                                   Bkcredit.Gracia_Principal,
                                   360,
                                   V_F_Gracia_Hasta,
                                   V_Msj_Error);

            IF (V_Msj_Error IS NOT NULL)
            THEN
                P_Msj_Error := Get_Mensaje_Err (V_Msj_Error, 'PR');
                RETURN;
            END IF;

            IF (V_F_Gracia_Hasta > Bkdesem.Fecha_Desembolso)
            THEN
                IF (Bkcredit.Tipo_Cuota = 'M')
                THEN
                    Bkdesem.Monto_Cuota_Principal := 0;
                    Pr_Plan.Formula_Intereses (Bkcredit.Tipo_Intereses,
                                               Bkcredit.Tipo_Calendario,
                                               Bkdesem.Monto_Desembolso,
                                               Bkcredit.Tasa_Interes,
                                               V_Periodicidad,
                                               Bkdesem.Monto_Cuota_Intereses,
                                               V_Msj_Error);

                    IF (P_Msj_Error IS NOT NULL)
                    THEN
                        P_Msj_Error := Get_Mensaje_Err (V_Msj_Error, 'PR');
                        RETURN;
                    END IF;
                ELSE
                    Bkdesem.Monto_Cuota_Principal := 0;
                    Pr_Plan.Formula_Intereses (Bkcredit.Tipo_Intereses,
                                               Bkcredit.Tipo_Calendario,
                                               Bkdesem.Monto_Desembolso,
                                               Bkcredit.Tasa_Interes,
                                               V_Periodicidad,
                                               Bkdesem.Monto_Cuota_Intereses,
                                               V_Msj_Error);

                    IF (V_Msj_Error IS NOT NULL)
                    THEN
                        P_Msj_Error := Get_Mensaje_Err (V_Msj_Error, 'PR');
                        RETURN;
                    END IF;
                END IF;
            ELSIF (Bkcredit.Tipo_Cuota IN ('N', 'L'))
            THEN
                Pr_Plan.Formula_Amortizacion (Bkcredit.Tipo_Cuota,
                                              Bkcredit.Tipo_Calendario,
                                              Bkdesem.Monto_Desembolso,
                                              V_Periodicidad,
                                              Bkcredit.Tasa_Interes,
                                              Bkcredit.Cuota,
                                              Bkdesem.Monto_Cuota_Principal,
                                              V_Msj_Error);

                IF (V_Msj_Error IS NOT NULL)
                THEN
                    P_Msj_Error := Get_Mensaje_Err (V_Msj_Error, 'PR');
                    RETURN;
                END IF;

                Bkdesem.Monto_Cuota_Intereses :=
                    Bkcredit.Cuota - Bkdesem.Monto_Cuota_Principal;
            ELSIF (Bkcredit.Tipo_Cuota = 'P')
            THEN
                Bkdesem.Monto_Cuota_Principal := Bkcredit.Cuota;
                Pr_Plan.Formula_Intereses (
                    Bkcredit.Tipo_Intereses,
                    Bkcredit.Tipo_Calendario,
                    Bkdesem.Monto_Desembolso - Bkdesem.Monto_Cuota_Principal,
                    Bkcredit.Tasa_Interes,
                    V_Periodicidad,
                    Bkdesem.Monto_Cuota_Intereses,
                    V_Msj_Error);

                IF (P_Msj_Error IS NOT NULL)
                THEN
                    P_Msj_Error := Get_Mensaje_Err (V_Msj_Error, 'PR');
                    RETURN;
                END IF;
            ELSIF (Bkcredit.Tipo_Cuota = 'V')
            THEN
                Bkdesem.Monto_Cuota_Principal := 0;
                Pr_Plan.Formula_Intereses (Bkcredit.Tipo_Intereses,
                                           Bkcredit.Tipo_Calendario,
                                           Bkdesem.Monto_Desembolso,
                                           Bkcredit.Tasa_Interes,
                                           V_Periodicidad,
                                           Bkdesem.Monto_Cuota_Intereses,
                                           V_Msj_Error);

                IF (P_Msj_Error IS NOT NULL)
                THEN
                    P_Msj_Error := Get_Mensaje_Err (V_Msj_Error, 'PR');
                    RETURN;
                END IF;
            ELSIF (Bkcredit.Tipo_Cuota = 'M')
            THEN
                IF (Bkcredit.Codigo_Periodo_Cuota =
                    Bkcredit.Codigo_Periodo_Intereses)
                THEN
                    Bkdesem.Monto_Cuota_Principal := Bkcredit.Cuota;
                    Pr_Plan.Formula_Intereses (
                        Bkcredit.Tipo_Intereses,
                        Bkcredit.Tipo_Calendario,
                          Bkdesem.Monto_Desembolso
                        - Bkdesem.Monto_Cuota_Principal,
                        Bkcredit.Tasa_Interes,
                        V_Periodicidad,
                        Bkdesem.Monto_Cuota_Intereses,
                        V_Msj_Error);

                    IF (V_Msj_Error IS NOT NULL)
                    THEN
                        P_Msj_Error := Get_Mensaje_Err (V_Msj_Error, 'PR');
                        RETURN;
                    END IF;
                ELSE
                    Bkdesem.Monto_Cuota_Principal := 0;
                    Pr_Plan.Formula_Intereses (Bkcredit.Tipo_Intereses,
                                               Bkcredit.Tipo_Calendario,
                                               Bkdesem.Monto_Desembolso,
                                               Bkcredit.Tasa_Interes,
                                               V_Periodicidad,
                                               Bkdesem.Monto_Cuota_Intereses,
                                               V_Msj_Error);

                    IF (V_Msj_Error IS NOT NULL)
                    THEN
                        P_Msj_Error := Get_Mensaje_Err (V_Msj_Error, 'PR');
                        RETURN;
                    END IF;
                END IF;                         -- Periodicidad Multiperiodica
            END IF;           -- Primer Desembolso Con Tipo Interes Anticipado
        ELSE
            Bkcredit.Dias_Intereses := 0;
            Bkcredit.F_Intereses_Hasta := Bkcredit.F_Ultimo_Pago_Intereses;
            Bkdesem.Monto_Cuota_Principal := 0;
            Bkdesem.Monto_Cuota_Intereses := 0;
        END IF;

        --
        Bkdesem.Monto_Cuota :=
            Bkdesem.Monto_Cuota_Principal + Bkdesem.Monto_Cuota_Intereses;
    END;


    PROCEDURE Descontar_Comision (P_Msj_Error IN OUT VARCHAR2)
    IS
        -- Calcula El Monto Por Comision A Descontar
        V_Fecha_Hasta_Comision    DATE;
        V_Msj_Error               VARCHAR2 (6);
        V_Dias_Calendario         NUMBER;
        V_Dias_Periodo            NUMBER;
        V_Dias_Periodo2           NUMBER;
        V_Dia_Pago                VARCHAR2 (2);
        V_Periodicidad            NUMBER;
        V_Comision_Sobre_Saldos   VARCHAR2 (1);
        Salir                     EXCEPTION;
    BEGIN
        -- Busca Si Debe Calcular Comision Sobre Saldos O Un Pct Fijo Sobre El Monto Del Credito
        --
        BEGIN
            SELECT Comision_Sobre_Saldos
              INTO V_Comision_Sobre_Saldos
              FROM Pr_Tipo_Credito
             WHERE     Codigo_Empresa = Bkcredit.Codigo_Empresa
                   AND Tipo_Credito = Bkcredit.Tipo_Credito;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                P_Msj_Error := Get_Mensaje_Err ('000456', 'PR');
                RAISE Salir;
        END;

        IF (Bkcredit.Tipo_Calendario IN (1, 4))
        THEN
            V_Dias_Calendario := 365;
        ELSE
            V_Dias_Calendario := 360;
        END IF;

        V_Periodicidad := Bkcredit.Dias_Periodo_Comision;
        V_Dia_Pago := TO_CHAR (Bkdesem.Fecha_Desembolso, 'DD');
        --
        Pr_Plan.Fecha_Cuota_Sig (Bkdesem.Fecha_Desembolso,
                                 V_Dia_Pago,
                                 V_Dia_Pago,
                                 V_Periodicidad,
                                 Bkcredit.Tipo_Calendario,
                                 V_Fecha_Hasta_Comision,
                                 V_Msj_Error);

        IF (V_Fecha_Hasta_Comision > Bkcredit.F_Vencimiento)
        THEN
            Pr_Plan.Restar_Fechas (Bkcredit.F_Vencimiento,
                                   Bkdesem.Fecha_Desembolso,
                                   V_Dias_Calendario,
                                   V_Periodicidad,
                                   V_Msj_Error);
            V_Fecha_Hasta_Comision := Bkcredit.F_Vencimiento;
        ELSE
            Restar_Fechas (V_Fecha_Hasta_Comision,
                           Bkdesem.Fecha_Desembolso,
                           365,
                           V_Dias_Periodo,
                           V_Msj_Error);

            IF (Bkcredit.Tipo_Calendario IN (1, 4))
            THEN
                V_Periodicidad := V_Dias_Periodo;
            END IF;
        END IF;

        IF (Bkcredit.F_Primer_Desembolso IS NOT NULL)
        THEN
            Bkcredit.Dias_Comision := 0;
            Bkcredit.F_Comision_Hasta := Bkcredit.F_Ultimo_Pago_Comision;
            Bkdesem.Monto_Comision := 0;
            RETURN;
        END IF;

        IF (    Bkcredit.Comision_Normal IS NOT NULL
            AND Bkcredit.Comision_Normal > 0
            AND Bkcredit.Tipo_Comision = 'A')
        THEN
            Bkcredit.Dias_Comision := V_Periodicidad;
            Bkcredit.F_Comision_Hasta := V_Fecha_Hasta_Comision;

            --
            IF V_Comision_Sobre_Saldos = 'S'
            THEN
                IF (Bkcredit.Tipo_Intereses = 'V')
                THEN
                    Pr_Plan.Formula_Intereses (Bkcredit.Tipo_Intereses,
                                               Bkcredit.Tipo_Calendario,
                                               Bkdesem.Monto_Desembolso,
                                               Bkcredit.Comision_Normal,
                                               V_Periodicidad,
                                               Bkdesem.Monto_Comision,
                                               V_Msj_Error);

                    IF (V_Msj_Error IS NOT NULL)
                    THEN
                        P_Msj_Error := Get_Mensaje_Err (V_Msj_Error, 'PR');
                        RETURN;
                    END IF;
                ELSIF (Bkcredit.Tipo_Intereses = 'A')
                THEN
                    IF Bkcredit.F_Primer_Desembolso IS NOT NULL
                    THEN
                        Bkdesem.Monto_Comision := 0;
                        RETURN;
                    END IF;

                    Pr_Plan.Formula_Intereses (
                        Bkcredit.Tipo_Intereses,
                        Bkcredit.Tipo_Calendario,
                          Bkdesem.Monto_Desembolso
                        - Bkdesem.Monto_Cuota_Principal,
                        Bkcredit.Comision_Normal,
                        V_Periodicidad,
                        Bkdesem.Monto_Comision,
                        V_Msj_Error);

                    IF (V_Msj_Error IS NOT NULL)
                    THEN
                        P_Msj_Error := Get_Mensaje_Err (V_Msj_Error, 'PR');
                        RETURN;
                    END IF;
                END IF;                                        -- Tipo_Interes
            ELSE
                -- Calcula Comision Con Un Pct Fijo Sobre El Monto Del Credito
                Bkdesem.Monto_Comision :=
                    Bkcredit.Monto_Credito * (Bkcredit.Comision_Normal / 100);
            END IF;
        ELSE
            Bkcredit.Dias_Comision := 0;
            Bkcredit.F_Comision_Hasta := Bkcredit.F_Ultimo_Pago_Comision;
            Bkdesem.Monto_Comision := 0;
        END IF;
    END;                                                 -- Descontar_Comision

    PROCEDURE Descontar_Poliza (P_Msj_Error IN OUT VARCHAR2)
    IS
    BEGIN
        -- Busca Las Polizas Colectivas Y Las Descuenta
        IF (Bkcredit.F_Primer_Desembolso IS NOT NULL)
        THEN
            Bkdesem.Monto_Poliza := 0;
            RETURN;
        END IF;

        BEGIN
            SELECT NVL (SUM (NVL (Monto_A_Pagar, 0)), 0)
              INTO Bkdesem.Monto_Poliza
              FROM Pr_Polizas_X_Credito
             WHERE     Codigo_Empresa = Bkcredit.Codigo_Empresa
                   AND No_Credito = Bkcredit.No_Credito
                   AND Tipo_Cobro = 'A'
                   AND F_Ultima_Generacion IS NULL
                   AND Numero_Poliza IN
                           (SELECT Numero_Poliza
                              FROM Pr_Polizas
                             WHERE     Codigo_Empresa =
                                       Bkcredit.Codigo_Empresa
                                   AND Modalidad_Poliza = 'C');
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                Bkdesem.Monto_Poliza := 0;
            WHEN TOO_MANY_ROWS
            THEN
                P_Msj_Error := Get_Mensaje_Err ('000454', 'PR');
                RETURN;
            WHEN OTHERS
            THEN
                P_Msj_Error := Get_Mensaje_Err ('000032', 'PR');
                RETURN;
        END;

        Bkdesem.Monto_Poliza := NVL (Bkdesem.Monto_Poliza, 0);
    END;


    PROCEDURE Borra_Cargo (P_Cod_Empresa IN VARCHAR2, P_Credito IN NUMBER)
    IS
        V_Hay_Cargo      NUMBER := 0;
        PCod_cargo_imp   NUMBER
            := NVL (
                   Param.Parametro_X_Empresa (P_Cod_Empresa,
                                              'COD_CARGO_LEY288',
                                              'PR'),
                   0);
    BEGIN
        SELECT COUNT (*)
          INTO V_Hay_Cargo
          FROM Pr_Cargos_X_Credito
         WHERE     Codigo_Empresa = P_Cod_Empresa
               AND No_Credito = P_Credito
               AND Codigo_Cargo = Pcod_Cargo_Imp;

        --- By Wen 28-02-05 Para Parametro Del Punto 15
        IF (V_Hay_Cargo <> 0)
        THEN
            DELETE FROM Pr_Cargos_X_Credito
                  WHERE     Codigo_Empresa = P_Cod_Empresa
                        AND No_Credito = P_Credito
                        AND Codigo_Cargo = Pcod_Cargo_Imp
                        AND Codigo_Tipo_Transaccion = 3;
        END IF;
    END;

    PROCEDURE Generar_Cargos_2 (P_Cod_Empresa     IN     NUMBER,
                                P_No_Credito      IN     NUMBER,
                                P_Saldo_Credito   IN     NUMBER,
                                P_Msj_Error       IN OUT VARCHAR2)
    IS
        -- Cargos Automaticos Pero Anticipados
        CURSOR Cargos_Anticipados (P_Empresa NUMBER, P_Credito NUMBER)
        IS
              SELECT Cred.Codigo_Cargo,
                     Cred.Tipo_Cargo,
                     Cred.Monto_Cargo,
                     Cred.Monto_Minimo,
                     Cred.Monto_Maximo,
                     Cred.Tipo_Cobro,
                     Cred.F_Ultima_Generacion,
                     Cred.Codigo_Tipo_Transaccion,
                     Car.Descripcion
                FROM Pr_Cargos_X_Credito Cred, Pr_Cargos Car
               WHERE     Cred.Codigo_Empresa = P_Empresa
                     AND Cred.No_Credito = P_Credito
                     AND Cred.Codigo_Tipo_Transaccion = 1 -- Cargos Automaticos
                     AND Cred.Tipo_Cobro = 'A'                  -- Anticipados
                     AND Cred.F_Ultima_Generacion IS NULL -- Nunca Se Ha Cobrado
                     AND Car.Codigo_Cargo = Cred.Codigo_Cargo
            ORDER BY Cred.Codigo_Cargo;

        --
        -- Cargos De Desembolso
        CURSOR Cargos_Desembolso (P_Cod_Empresa NUMBER, P_No_Credito NUMBER)
        IS
              SELECT Cred.Codigo_Cargo,
                     Cred.Tipo_Cargo,
                     Cred.Monto_Cargo,
                     Cred.Monto_Minimo,
                     Cred.Monto_Maximo,
                     Cred.Tipo_Cobro,
                     Cred.F_Ultima_Generacion,
                     Cred.Codigo_Tipo_Transaccion,
                     Car.Descripcion
                FROM Pr_Cargos_X_Credito Cred, Pr_Cargos Car
               WHERE     Cred.Codigo_Empresa = P_Cod_Empresa
                     AND Cred.No_Credito = P_No_Credito
                     AND Cred.Codigo_Tipo_Transaccion = 3
                     AND Car.Codigo_Cargo = Cred.Codigo_Cargo
            ORDER BY Cred.Codigo_Cargo;

        --

        V_Primera_Vez        BOOLEAN := TRUE;
        V_Acumulado          NUMBER (16, 2) := 0;
        V_Codigo_Cargo_Iva   NUMBER;
        V_Monto_Cargo_Iva    NUMBER (16, 2);
        Vmontocargo          NUMBER (16, 2);
        Salida               EXCEPTION;
    --
    BEGIN
        Bkdesem.Monto_Iva_Cargos := 0;
        Bkdesem.Monto_Iva_Comision := 0;

        PbkcargO.Delete;

        -- Inserta Cargos Automaticos Pero Solo Los Anticipados

        IF (Bkcredit.F_Primer_Desembolso IS NULL)
        THEN
            FOR C IN Cargos_Anticipados (P_Cod_Empresa, P_No_Credito)
            LOOP
                IF (V_Primera_Vez)
                THEN
                    V_Primera_Vez := FALSE;
                ELSE
                    VC := VC + 1;
                END IF;

                --
                PbkcargO (VC).Codigo_Cargo := C.Codigo_Cargo;
                PbkcargO (VC).Descripcion := C.Descripcion;
                PbkcargO (VC).Tipo_Cobro := C.Tipo_Cobro;
                PbkcargO (VC).Codigo_Tipo_Transaccion :=
                    C.Codigo_Tipo_Transaccion;
                PbkcargO (VC).F_Ultima_Generacion := C.F_Ultima_Generacion;

                IF (C.Tipo_Cargo = 'M')
                THEN
                    PbkcargO (VC).Monto_Cargo := C.Monto_Cargo;
                    PbkcargO (VC).Monto_Porcentaje := NULL;
                ELSIF (C.Tipo_Cargo = 'P')
                THEN
                    PbkcargO (VC).Monto_Porcentaje := C.Monto_Cargo;
                    PbkcargO (VC).Monto_Cargo :=
                        P_Saldo_Credito * C.Monto_Cargo / 100;

                    IF (PbkcargO (VC).Monto_Cargo < C.Monto_Minimo)
                    THEN
                        PbkcargO (VC).Monto_Cargo := C.Monto_Minimo;
                    ELSIF (PbkcargO (VC).Monto_Cargo > C.Monto_Maximo)
                    THEN
                        PbkcargO (VC).Monto_Cargo := C.Monto_Maximo;
                    END IF;
                END IF;

                V_Acumulado := V_Acumulado + PbkcargO (VC).Monto_Cargo;

                -- Determina Si Se Cobra Iva Para Este Cargo

                Pr_Procs.Calcular_Iva (P_Cod_Empresa,
                                       P_No_Credito,
                                       C.Codigo_Cargo,
                                       PbkcargO (VC).Monto_Cargo,
                                       V_Codigo_Cargo_Iva,
                                       V_Monto_Cargo_Iva);

                IF V_Monto_Cargo_Iva > 0
                THEN
                    Vc := Vc + 1;                               --Next_Record;
                    PbkcargO (VC).Codigo_Cargo := V_Codigo_Cargo_Iva;
                    PbkcargO (VC).Descripcion :=
                        'IMP' || ' ' || C.Descripcion;                 -- Iva/
                    PbkcargO (VC).Tipo_Cobro := C.Tipo_Cobro;
                    PbkcargO (VC).Codigo_Tipo_Transaccion := 2; -- Cargo Manual
                    PbkcargO (VC).Monto_Cargo := V_Monto_Cargo_Iva;
                    PbkcargO (VC).Monto_Porcentaje := NULL;
                    --
                    Bkdesem.Monto_Iva_Cargos :=
                        NVL (Bkdesem.Monto_Iva_Cargos, 0) + V_Monto_Cargo_Iva;
                END IF;
            END LOOP;
        END IF;

        FOR C IN Cargos_Desembolso (P_Cod_Empresa, P_No_Credito)
        LOOP
            IF (V_Primera_Vez)
            THEN
                V_Primera_Vez := FALSE;
            ELSE
                VC := VC + 1;
            END IF;

            PbkcargO (VC).Codigo_Cargo := C.Codigo_Cargo;
            PbkcargO (VC).Descripcion := C.Descripcion;
            PbkcargO (VC).Tipo_Cobro := C.Tipo_Cobro;
            PbkcargO (VC).Codigo_Tipo_Transaccion :=
                C.Codigo_Tipo_Transaccion;
            PbkcargO (VC).F_Ultima_Generacion := C.F_Ultima_Generacion;
            Vmontocargo := 0;


            IF (C.Tipo_Cargo = 'M')
            THEN
                -- Se Cobra Un Monto
                PbkcargO (VC).Monto_Cargo := C.Monto_Cargo;
                PbkcargO (VC).Monto_Porcentaje := NULL;
            ELSIF (C.Tipo_Cargo = 'P')
            THEN
                -- Se Cobra Un Porcentaje
                IF Vmontocargo = 0
                THEN
                    PbkcargO (VC).Monto_Porcentaje := C.Monto_Cargo;
                ELSE
                    PbkcargO (VC).Monto_Porcentaje := Vmontocargo;
                END IF;

                IF NVL (Bkcredit.Ind_Credito_Universitario, 'N') = 'S'
                THEN
                    PbkcargO (VC).Monto_Cargo :=
                          Bkdesem.Monto_Desembolso
                        * (PbkcargO (VC).Monto_Porcentaje / 100);
                ELSE
                    PbkcargO (VC).Monto_Cargo :=
                          P_Saldo_Credito
                        * (PbkcargO (VC).Monto_Porcentaje / 100);
                END IF;


                IF C.Tipo_Cobro = 'P'
                THEN
                    IF Bkcredit.F_Primer_Desembolso IS NULL
                    THEN
                        PbkcargO (VC).Monto_Cargo :=
                              Bkdesem.Monto_Desembolso
                            * (Pbkcargo (VC).Monto_Porcentaje / 100);
                    ELSE
                        PbkcargO (VC).Monto_Cargo := 0;
                    END IF;
                END IF;


                IF C.Tipo_Cobro <> 'P' AND Vmontocargo > 0
                THEN
                    IF (PbkcargO (VC).Monto_Cargo < C.Monto_Minimo)
                    THEN
                        PbkcargO (VC).Monto_Cargo := C.Monto_Minimo;
                    ELSIF (PbkcargO (VC).Monto_Cargo > C.Monto_Maximo)
                    THEN
                        PbkcargO (VC).Monto_Cargo := C.Monto_Maximo;
                    END IF;
                ELSIF C.Tipo_Cobro = 'P' AND Vmontocargo > 0
                THEN
                    IF Bkcredit.F_Primer_Desembolso IS NULL
                    THEN
                        IF (PbkcargO (VC).Monto_Cargo < C.Monto_Minimo)
                        THEN
                            PbkcargO (VC).Monto_Cargo := C.Monto_Minimo;
                        ELSIF (PbkcargO (VC).Monto_Cargo > C.Monto_Maximo)
                        THEN
                            PbkcargO (VC).Monto_Cargo := C.Monto_Maximo;
                        END IF;
                    ELSE
                        PbkcargO (VC).Monto_Cargo := 0;
                    END IF;
                END IF;
            END IF;

            V_Acumulado := V_Acumulado + PbkcargO (VC).Monto_Cargo;

            IF PbkcargO (VC).Tipo_Cobro IN ('A', 'P')
            THEN
                Bkdesem.Monto_Cargos_A :=
                      NVL (Bkdesem.Monto_Cargos_A, 0)
                    + NVL (PbkcargO (VC).Monto_Cargo, 0);
            END IF;


            Pr_Procs.Calcular_Iva (P_Cod_Empresa,
                                   P_No_Credito,
                                   C.Codigo_Cargo,
                                   PbkcargO (VC).Monto_Cargo,
                                   V_Codigo_Cargo_Iva,
                                   V_Monto_Cargo_Iva);

            IF V_Monto_Cargo_Iva > 0
            THEN
                ----Next_Record;
                PbkcargO (VC).Codigo_Cargo := V_Codigo_Cargo_Iva;
                PbkcargO (VC).Descripcion := 'IMP' || ' ' || C.Descripcion; -- Iva/
                PbkcargO (VC).Tipo_Cobro := C.Tipo_Cobro;
                PbkcargO (VC).Codigo_Tipo_Transaccion := 2;    -- Cargo Manual
                PbkcargO (VC).Monto_Cargo := V_Monto_Cargo_Iva;
                PbkcargO (VC).Monto_Porcentaje := NULL;

                Bkdesem.Monto_Iva_Cargos :=
                    NVL (Bkdesem.Monto_Iva_Cargos, 0) + V_Monto_Cargo_Iva;
            END IF;
        END LOOP;                                        -- Cargos Por Generar

        -- Actualiza Los Cargos Automaticos Vencidos Para Que La F_Ultima_Generacion Quede Seteada
        -- Con La Fecha De Desembolso. Si Es Un Cargo Automatico
        UPDATE Pr_Cargos_X_Credito
           SET F_Ultima_Generacion = Bkdesem.Fecha_Desembolso
         WHERE     Codigo_Empresa = Bkcredit.Codigo_Empresa
               AND No_Credito = Bkcredit.No_Credito
               AND Codigo_Tipo_Transaccion = 1
               AND Tipo_Cobro = 'V';

        Bkdesem.Monto_Cargos := V_Acumulado + Bkdesem.Monto_Iva_Cargos;
    END;

    PROCEDURE Descontar_Cuotas_Anticipadas (
        Numcuotasp        IN     NUMBER,
        Totalprincipalp      OUT NUMBER,
        Totalinteresesp      OUT NUMBER,
        Totalcuotasp         OUT NUMBER,
        Fecinthastap         OUT DATE,
        Diasinteresesp       OUT NUMBER,
        P_Msj_Error       IN OUT VARCHAR2)
    IS
        V_F_Gracia_Hasta    DATE;
        V_Periodicidad      NUMBER;
        V_Fecha_Hasta       DATE;
        V_Dias_Periodo      NUMBER;
        V_Dia_Pago          VARCHAR2 (2);
        V_Dias_Calendario   NUMBER;
        V_Fecha_Desde       DATE;
        V_Saldo_Credito     NUMBER (18, 2);
        V_Principal         NUMBER (18, 2);
        V_Intereses         NUMBER (18, 2);
        V_Dias              NUMBER := 0;
        V_Total_Intereses   NUMBER (18, 2);
        V_Total_Principal   NUMBER (18, 2);
        V_Total_Dias        NUMBER := 0;
        V_Msj_Error         VARCHAR2 (50);
    BEGIN
        IF (Bkcredit.Tipo_Calendario IN (1, 4))
        THEN
            V_Dias_Calendario := 365;
        ELSE
            V_Dias_Calendario := 360;
        END IF;

        IF (Bkcredit.Tipo_Cuota = 'M')
        THEN
            V_Periodicidad := Bkcredit.Dias_Periodo_Interes;
        ELSE
            V_Periodicidad := Bkcredit.Dias_Periodo_Cuota;
        END IF;

        V_Fecha_Desde := Bkdesem.Fecha_Desembolso;
        V_Saldo_Credito := Bkdesem.Monto_Desembolso;
        V_Dia_Pago := TO_CHAR (Bkdesem.Fecha_Desembolso, 'Dd');
        V_Total_Intereses := 0;
        V_Total_Principal := 0;
        V_Total_Dias := 0;

        FOR I IN 1 .. Numcuotasp
        LOOP
            V_Principal := 0;
            V_Intereses := 0;
            V_Dias := 0;
            Pr_Plan.Fecha_Cuota_Sig (V_Fecha_Desde,
                                     V_Dia_Pago,
                                     V_Dia_Pago,
                                     V_Periodicidad,
                                     Bkcredit.Tipo_Calendario,
                                     V_Fecha_Hasta,
                                     P_Msj_Error);

            IF (V_Fecha_Hasta > Bkcredit.F_Vencimiento)
            THEN
                Pr_Plan.Restar_Fechas (Bkcredit.F_Vencimiento,
                                       V_Fecha_Desde,
                                       V_Dias_Calendario,
                                       V_Dias,
                                       P_Msj_Error);
                V_Fecha_Hasta := Bkcredit.F_Vencimiento;
            ELSE
                Pr_Plan.Restar_Fechas (V_Fecha_Hasta,
                                       V_Fecha_Desde,
                                       365,
                                       V_Dias,
                                       P_Msj_Error);
            END IF;

            IF (Bkcredit.F_Primer_Desembolso IS NOT NULL)
            THEN
                V_Principal := 0;
                V_Intereses := 0;
                RETURN;
            END IF;

            IF (Bkcredit.Tipo_Intereses = 'A')
            THEN
                Pr_Procs.Agregar_Dias (Bkdesem.Fecha_Desembolso,
                                       Bkcredit.Gracia_Principal,
                                       360,
                                       V_F_Gracia_Hasta,
                                       V_Msj_Error);

                IF (V_Msj_Error IS NOT NULL)
                THEN
                    P_Msj_Error := Get_Mensaje_Err (V_Msj_Error, 'PR');
                    RETURN;
                END IF;

                IF (V_F_Gracia_Hasta > V_Fecha_Desde)
                THEN
                    IF (Bkcredit.Tipo_Cuota = 'M')
                    THEN
                        V_Principal := 0;
                        Pr_Plan.Formula_Intereses (Bkcredit.Tipo_Intereses,
                                                   Bkcredit.Tipo_Calendario,
                                                   V_Saldo_Credito,
                                                   Bkcredit.Tasa_Interes,
                                                   V_Periodicidad,
                                                   V_Intereses,
                                                   V_Msj_Error);

                        IF (V_Msj_Error IS NOT NULL)
                        THEN
                            P_Msj_Error :=
                                Get_Mensaje_Err (V_Msj_Error, 'PR');
                            RETURN;
                        END IF;
                    ELSE
                        V_Principal := 0;
                        Pr_Plan.Formula_Intereses (Bkcredit.Tipo_Intereses,
                                                   Bkcredit.Tipo_Calendario,
                                                   V_Saldo_Credito,
                                                   Bkcredit.Tasa_Interes,
                                                   V_Periodicidad,
                                                   V_Intereses,
                                                   V_Msj_Error);

                        IF (V_Msj_Error IS NOT NULL)
                        THEN
                            P_Msj_Error :=
                                Get_Mensaje_Err (V_Msj_Error, 'PR');
                            RETURN;
                        END IF;
                    END IF;
                ELSIF (Bkcredit.Tipo_Cuota IN ('N', 'L'))
                THEN
                    Pr_Plan.Formula_Amortizacion (Bkcredit.Tipo_Cuota,
                                                  Bkcredit.Tipo_Calendario,
                                                  V_Saldo_Credito,
                                                  V_Periodicidad,
                                                  Bkcredit.Tasa_Interes,
                                                  Bkcredit.Cuota,
                                                  V_Principal,
                                                  V_Msj_Error);

                    IF (V_Msj_Error IS NOT NULL)
                    THEN
                        P_Msj_Error := Get_Mensaje_Err (V_Msj_Error, 'PR');
                        RETURN;
                    END IF;

                    V_Intereses :=
                        Bkcredit.Cuota - Bkdesem.Monto_Cuota_Principal;
                ELSIF (Bkcredit.Tipo_Cuota = 'P')
                THEN
                    V_Principal := Bkcredit.Cuota;
                    Pr_Plan.Formula_Intereses (Bkcredit.Tipo_Intereses,
                                               Bkcredit.Tipo_Calendario,
                                               V_Saldo_Credito - V_Principal,
                                               Bkcredit.Tasa_Interes,
                                               V_Periodicidad,
                                               V_Intereses,
                                               V_Msj_Error);

                    IF (P_Msj_Error IS NOT NULL)
                    THEN
                        P_Msj_Error := Get_Mensaje_Err (V_Msj_Error, 'PR');
                        RETURN;
                    END IF;
                ELSIF (Bkcredit.Tipo_Cuota = 'V')
                THEN
                    V_Principal := 0;
                    Pr_Plan.Formula_Intereses (Bkcredit.Tipo_Intereses,
                                               Bkcredit.Tipo_Calendario,
                                               V_Saldo_Credito,
                                               Bkcredit.Tasa_Interes,
                                               V_Periodicidad,
                                               V_Intereses,
                                               V_Msj_Error);

                    IF (P_Msj_Error IS NOT NULL)
                    THEN
                        P_Msj_Error := Get_Mensaje_Err (V_Msj_Error, 'PR');
                        RETURN;
                    END IF;
                ELSIF (Bkcredit.Tipo_Cuota = 'M')
                THEN
                    IF (Bkcredit.Codigo_Periodo_Cuota =
                        Bkcredit.Codigo_Periodo_Intereses)
                    THEN
                        V_Principal := Bkcredit.Cuota;
                        Pr_Plan.Formula_Intereses (
                            Bkcredit.Tipo_Intereses,
                            Bkcredit.Tipo_Calendario,
                            V_Saldo_Credito - V_Principal,
                            Bkcredit.Tasa_Interes,
                            V_Periodicidad,
                            V_Intereses,
                            V_Msj_Error);

                        IF (V_Msj_Error IS NOT NULL)
                        THEN
                            P_Msj_Error :=
                                Get_Mensaje_Err (V_Msj_Error, 'PR');
                            RETURN;
                        END IF;
                    ELSE
                        V_Principal := 0;
                        Pr_Plan.Formula_Intereses (Bkcredit.Tipo_Intereses,
                                                   Bkcredit.Tipo_Calendario,
                                                   V_Saldo_Credito,
                                                   Bkcredit.Tasa_Interes,
                                                   V_Periodicidad,
                                                   V_Intereses,
                                                   V_Msj_Error);

                        IF (V_Msj_Error IS NOT NULL)
                        THEN
                            P_Msj_Error :=
                                Get_Mensaje_Err (V_Msj_Error, 'PR');
                            RETURN;
                        END IF;
                    END IF;                     -- Periodicidad Multiperiodica
                END IF;       -- Primer Desembolso Con Tipo Interes Anticipado
            ELSE                             -- Sin Los Intereses Son Vencidos
                Pr_Procs.Agregar_Dias (Bkdesem.Fecha_Desembolso,
                                       Bkcredit.Gracia_Principal,
                                       360,
                                       V_F_Gracia_Hasta,
                                       V_Msj_Error);

                IF (V_Msj_Error IS NOT NULL)
                THEN
                    P_Msj_Error := Get_Mensaje_Err (V_Msj_Error, 'PR');
                    RETURN;
                END IF;

                IF (V_F_Gracia_Hasta > V_Fecha_Desde)
                THEN
                    IF (Bkcredit.Tipo_Cuota = 'M')
                    THEN
                        V_Principal := 0;
                        Pr_Plan.Formula_Intereses (Bkcredit.Tipo_Intereses,
                                                   Bkcredit.Tipo_Calendario,
                                                   V_Saldo_Credito,
                                                   Bkcredit.Tasa_Interes,
                                                   V_Dias,
                                                   V_Intereses,
                                                   V_Msj_Error);

                        IF (V_Msj_Error IS NOT NULL)
                        THEN
                            P_Msj_Error :=
                                Get_Mensaje_Err (V_Msj_Error, 'PR');
                            RETURN;
                        END IF;
                    ELSE
                        V_Principal := 0;
                        Pr_Plan.Formula_Intereses (Bkcredit.Tipo_Intereses,
                                                   Bkcredit.Tipo_Calendario,
                                                   V_Saldo_Credito,
                                                   Bkcredit.Tasa_Interes,
                                                   V_Dias,
                                                   V_Intereses,
                                                   V_Msj_Error);

                        IF (V_Msj_Error IS NOT NULL)
                        THEN
                            P_Msj_Error :=
                                Get_Mensaje_Err (V_Msj_Error, 'PR');
                            RETURN;
                        END IF;
                    END IF;
                ELSIF (Bkcredit.Tipo_Cuota IN ('N', 'L'))
                THEN
                    Pr_Plan.Formula_Intereses (Bkcredit.Tipo_Intereses,
                                               Bkcredit.Tipo_Calendario,
                                               V_Saldo_Credito,
                                               Bkcredit.Tasa_Interes,
                                               V_Dias,
                                               V_Intereses,
                                               V_Msj_Error);

                    IF (V_Msj_Error IS NOT NULL)
                    THEN
                        P_Msj_Error := Get_Mensaje_Err (V_Msj_Error, 'PR');
                        RETURN;
                    END IF;

                    V_Principal := Bkcredit.Cuota - V_Intereses;
                ELSIF (Bkcredit.Tipo_Cuota = 'P')
                THEN
                    V_Principal := Bkcredit.Cuota;
                    Pr_Plan.Formula_Intereses (Bkcredit.Tipo_Intereses,
                                               Bkcredit.Tipo_Calendario,
                                               V_Saldo_Credito,
                                               Bkcredit.Tasa_Interes,
                                               V_Dias,
                                               V_Intereses,
                                               V_Msj_Error);

                    IF (V_Msj_Error IS NOT NULL)
                    THEN
                        P_Msj_Error := Get_Mensaje_Err (V_Msj_Error, 'PR');
                        RETURN;
                    END IF;
                ELSIF (Bkcredit.Tipo_Cuota = 'V')
                THEN
                    V_Principal := 0;
                    Pr_Plan.Formula_Intereses (Bkcredit.Tipo_Intereses,
                                               Bkcredit.Tipo_Calendario,
                                               V_Saldo_Credito,
                                               Bkcredit.Tasa_Interes,
                                               V_Dias,
                                               V_Intereses,
                                               V_Msj_Error);

                    IF (V_Msj_Error IS NOT NULL)
                    THEN
                        P_Msj_Error := Get_Mensaje_Err (V_Msj_Error, 'PR');
                        RETURN;
                    END IF;
                ELSIF (Bkcredit.Tipo_Cuota = 'M')
                THEN
                    IF (Bkcredit.Codigo_Periodo_Cuota =
                        Bkcredit.Codigo_Periodo_Intereses)
                    THEN
                        V_Principal := Bkcredit.Cuota;
                        Pr_Plan.Formula_Intereses (Bkcredit.Tipo_Intereses,
                                                   Bkcredit.Tipo_Calendario,
                                                   V_Saldo_Credito,
                                                   Bkcredit.Tasa_Interes,
                                                   V_Dias,
                                                   V_Intereses,
                                                   V_Msj_Error);

                        IF (V_Msj_Error IS NOT NULL)
                        THEN
                            P_Msj_Error :=
                                Get_Mensaje_Err (V_Msj_Error, 'PR');
                            RETURN;
                        END IF;
                    ELSE
                        V_Principal := 0;
                        Pr_Plan.Formula_Intereses (Bkcredit.Tipo_Intereses,
                                                   Bkcredit.Tipo_Calendario,
                                                   V_Saldo_Credito,
                                                   Bkcredit.Tasa_Interes,
                                                   V_Dias,
                                                   V_Intereses,
                                                   V_Msj_Error);

                        IF (V_Msj_Error IS NOT NULL)
                        THEN
                            P_Msj_Error :=
                                Get_Mensaje_Err (V_Msj_Error, 'PR');
                            RETURN;
                        END IF;
                    END IF;                     -- Periodicidad Multiperiodica
                END IF;       -- Primer Desembolso Con Tipo Interes Anticipado
            END IF;

            V_Fecha_Desde := V_Fecha_Hasta;                            -- + 1;

            IF V_Principal > V_Saldo_Credito
            THEN
                V_Principal := V_Saldo_Credito;
            END IF;

            V_Saldo_Credito := V_Saldo_Credito - V_Principal;
            V_Total_Intereses :=
                NVL (V_Total_Intereses, 0) + NVL (V_Intereses, 0);
            V_Total_Principal :=
                NVL (V_Total_Principal, 0) + NVL (V_Principal, 0);
            V_Total_Dias := NVL (V_Total_Dias, 0) + NVL (V_Dias, 0);

            IF V_Saldo_Credito = 0
            THEN
                EXIT;
            END IF;
        END LOOP;

        Totalprincipalp := NVL (V_Total_Principal, 0);
        Totalinteresesp := NVL (V_Total_Intereses, 0);
        Totalcuotasp :=
            NVL (V_Total_Principal, 0) + NVL (V_Total_Intereses, 0);
        Fecinthastap := V_Fecha_Hasta;
        Diasinteresesp := V_Total_Dias;
    END;

    PROCEDURE Datos_Oper_Desembolso (P_Cod_Empresa    IN     VARCHAR2,
                                     P_Credito        IN     NUMBER,
                                     P_Fecha_Desemb   IN     DATE,
                                     P_Monto_Desemb   IN     NUMBER,
                                     P_Msj_Error         OUT VARCHAR2)
    IS
        /*
            Este proceso  equivale al program uniT  BLOQUE_DESEMBOLSO  de  la forma  PR0110 (Desembolsos de Dinero)
        */


        V_Cuantos           NUMBER (10);
        V_Bloqueado         VARCHAR2 (1) := NULL;
        --
        V_Total_Principal   NUMBER (18, 2) := 0;
        V_Total_Intereses   NUMBER (18, 2) := 0;
        V_Total_Cuotas      NUMBER (18, 2) := 0;
        V_Total_Dias        NUMBER (5) := 0;
        V_Fecha_Int_Hasta   DATE;
        V_Msj_Error         VARCHAR2 (500) := NULL;
        --
        Salir               EXCEPTION;
        --  V_Mensaje         Varchar2(200);
        --Fpdesembolso      Date;
        --     Nmontocansaldo      NUMBER (18, 2) := 0;
        V_Cr                Pr_Creditos%ROWTYPE;
        V_Encontrado        VARCHAR2 (1) := 'S';
    BEGIN
        --- Carga registro del credito --
        BEGIN
            SELECT *
              INTO V_Cr
              FROM Pr_Creditos
             WHERE Codigo_Empresa = P_Cod_Empresa AND No_Credito = P_Credito;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                V_Encontrado := 'N';
        END;

        IF V_Encontrado = 'S'
        THEN
            Bkdesem.Codigo_Cliente := V_Cr.Codigo_Cliente;
            Bkdesem.Fecha_Desembolso := V_Fecha_Sist;
            Bkdesem.Tipo_Desembolso := V_Cr.Tipo_Desembolso;
            Bkdesem.Numero_Cuenta := V_Cr.Cuenta_Desem;

            -- Determina si el  Cliente esta excento del pago de impuesto
            BEGIN
                SELECT NVL (Paga_Imp_Ley288, 'S')
                  INTO Bkdesem.Paga_Impley
                  FROM Personas
                 WHERE Cod_Persona = V_Cr.Codigo_Cliente;
            EXCEPTION
                WHEN OTHERS
                THEN
                    Bkdesem.Paga_Impley := 'S';
            END;

            -- Se verifica si existe un bloqueo para el credito o en
            -- el caso de  una linea, para el crédito madre
            BEGIN
                IF     NVL (V_Cr.Bloqueo_Desembolso, 'N') = 'S'
                   AND V_Cr.No_Credito_Origen IS NULL
                THEN
                    P_Msj_Error := Get_Mensaje_Err ('000537', 'PR');
                    RAISE Salir;
                ELSIF V_Cr.No_Credito_Origen IS NOT NULL
                THEN
                    BEGIN
                        SELECT NVL (Bloqueo_Desembolso, 'N')
                          INTO V_Bloqueado
                          FROM Pr_Creditos
                         WHERE     Codigo_Empresa = P_Cod_Empresa
                               AND No_Credito = V_Cr.No_Credito_Origen;
                    EXCEPTION
                        WHEN NO_DATA_FOUND
                        THEN
                            V_Bloqueado := 'N';
                    END;

                    IF V_Bloqueado = 'S'
                    THEN
                        P_Msj_Error := Get_Mensaje_Err ('000538', 'PR');
                        RAISE Salir;
                    END IF;
                END IF;
            END;

            -- Control De Requisitos Pendientes
            BEGIN
                SELECT NVL (COUNT ('D'), 0)
                  INTO V_Cuantos
                  FROM Pr_Req_X_Creditos
                 WHERE     Codigo_Empresa = P_Cod_Empresa
                       AND No_Credito = V_Cr.No_Credito
                       AND Obligatorio = 'S'
                       AND Estado = 'P'
                       AND Autorizado_Por IS NULL;

                IF V_Cuantos >= 1
                THEN
                    P_Msj_Error := Get_Mensaje_Err ('000405', 'PR');
                    RAISE Salir;
                END IF;
            END;                                                 -- Requisitos

            -- Control De Plan Libre Pre-Negociado
            IF (V_Cr.Tipo_Cuota = 'L')
            THEN
                BEGIN
                    SELECT NVL (COUNT ('D'), 0)
                      INTO V_Cuantos
                      FROM Pr_Plan_Libre_Tmp
                     WHERE     Codigo_Empresa = P_Cod_Empresa
                           AND Credito_O_Solicitud = 'C'
                           AND No_Credito = V_Cr.No_Credito;

                    IF V_Cuantos <= 1
                    THEN
                        Bkdesem.Plan_Libre := 'NUEVO';                -- Nuevo
                    ELSIF (V_Cuantos > 1)
                    THEN
                        Bkdesem.Plan_Libre := 'PRE-NEGOCIADO'; -- Pre-Negociad
                    END IF;
                END;
            END IF;                                              -- Plan Libre

            -- Se Recalcula El Disponible En El Momento Por Problemas Con
            -- Desembolsos Consecutivos
            Bkdesem.Monto_Disponible :=
                NVL (
                    Saldo_Disponible_Pr (V_Cr.Codigo_Empresa,
                                         'ESPA',
                                         V_Cr.No_Credito),
                    0);

            -- Calcula Sobregiro ---
            /*Begin
                  If Nvl(V_Cr.Permite_Sobregiro,'N') = 'S' Then
                      Bkdesem.Monto_Sobregiro :=  Nvl(V_Cr.Monto_Credito,0) *
                                                 (Nvl(V_Cr.Porcentaje_Sobregiro,0) / 100);
                  Else
                      Bkdesem.Monto_Sobregiro := 0;
                  End If;

                  If (( Bkdesem.Monto_Disponible + Bkdesem.Monto_Sobregiro <= 0) Or
                      ( Bkdesem.Monto_Disponible + Bkdesem.Monto_Sobregiro < P_Monto_Desemb)
                     )
                  Then
                      P_Msj_Error := Get_Mensaje_Err('000534', 'PR');
                      Raise Salir;
                  End If;
             End;  */

            ---Bkdesem.Monto_Desembolso := Bkdesem.Monto_Disponible;
            Bkdesem.Monto_Desembolso := P_Monto_Desemb;

            -- Calcula Los Montos De Los Rubros Que Se Descuentan Del
            -- Desembolso
            Bkdesem.Cobrar_Cargos := V_Cr.Desc_Cargos;
            Bkdesem.Cobrar_Poliza := 'N';

            -- Bkdesem.Cobrar_Cuota    := Desc_Cuota;
            -- Bkdesem.Cobrar_Comision := Desc_Comision;

            IF Bkdesem.Cobrar_Cuota = 'S'
            THEN
                Descontar_Cuota (V_Msj_Error);

                IF (V_Msj_Error IS NOT NULL)
                THEN
                    P_Msj_Error := Get_Mensaje_Err (V_Msj_Error, 'PR');
                    RAISE Salir;
                END IF;
            END IF;

            IF Bkdesem.Cobrar_Comision = 'S'
            THEN
                Descontar_Comision (V_Msj_Error);

                IF (V_Msj_Error IS NOT NULL)
                THEN
                    P_Msj_Error := Get_Mensaje_Err (V_Msj_Error, 'PR');
                    RAISE Salir;
                END IF;
            END IF;

            IF Bkdesem.Cobrar_Poliza = 'S'
            THEN
                Descontar_Poliza (V_Msj_Error);

                IF (V_Msj_Error IS NOT NULL)
                THEN
                    P_Msj_Error := Get_Mensaje_Err (V_Msj_Error, 'PR');
                END IF;
            ELSE
                Bkdesem.Monto_Poliza := 0;
            END IF;

            IF Bkdesem.Cobrar_Cargos = 'S'
            THEN
                Borra_Cargo (V_Cr.Codigo_Empresa, V_Cr.No_Credito);
                Generar_Cargos_2 (V_Cr.Codigo_Empresa,
                                  V_Cr.No_Credito,
                                  NVL (Bkdesem.Monto_Desembolso, 0),
                                  V_Msj_Error);

                IF (V_Msj_Error IS NOT NULL)
                THEN
                    P_Msj_Error := V_Msj_Error;
                    RAISE Salir;
                END IF;
            END IF;

            ---Message('Interes Desc Creditos');Message(' '||V_Cr.Descuenta_Intereses_Desembolso);
            IF NVL (V_Cr.Descuenta_Intereses_Desembolso, 'N') = 'S'
            THEN
                Descontar_Cuotas_Anticipadas (V_Cr.Cantidad_Cuotas_Descontar,
                                              V_Total_Principal,
                                              V_Total_Intereses,
                                              V_Total_Cuotas,
                                              V_Fecha_Int_Hasta,
                                              V_Total_Dias,
                                              V_Msj_Error);
                Bkdesem.Monto_Cuota_Intereses := V_Total_Intereses;
                Bkcredit.F_Intereses_Hasta := V_Fecha_Int_Hasta;
                Bkcredit.Dias_Intereses := V_Total_Dias;
                Bkdesem.Monto_Cuota :=
                      Bkdesem.Monto_Cuota_Intereses
                    + Bkdesem.Monto_Cuota_Principal;
            END IF;

            /* Codigo ya está incluido en funcion cancelacion creditos
                FOR C1
                    IN (SELECT *
                          FROM Pr_Cancelacion_Creditos
                         WHERE     Codigo_Empresa = V_Cr.Codigo_Empresa
                               AND No_Credito = V_Cr.No_Credito
                               AND EXISTS
                                       (SELECT *
                                          FROM Pr_Creditos Pr
                                         WHERE     Pr.Codigo_Empresa =
                                                   Bkcredit.Codigo_Empresa
                                               AND Pr.No_Credito =
                                                   No_Credito_Cancelado
                                               AND Pr.Estado <> 'C'))
                LOOP
                    Nmontocansaldo :=
                        Pr_Interfaz_Abonos.Obtienemontocancelaciontotal (
                            Empresap   => V_Cr.Codigo_Empresa, -- Codigo De La Empresa.
                            Creditop   => C1.No_Credito_Cancelado, -- Numero De Credito.
                            Fechap     => Bkdesem.Fecha_Desembolso);
                    Bkdesem.Monto_Canc_Creditos :=
                        NVL (Bkdesem.Monto_Canc_Creditos, 0) + Nmontocansaldo;
                END LOOP;
                */

            Bkdesem.Total_Desembolso :=
                  NVL (Bkdesem.Monto_Desembolso, 0)
                - NVL (Bkdesem.Monto_Canc_Creditos, 0)
                - NVL (Bkdesem.Monto_Cargos, 0)
                - NVL (Bkdesem.Monto_Iva_Cargos, 0)
                - NVL (Bkdesem.Monto_Comision, 0)
                - NVL (Bkdesem.Monto_Iva_Comision, 0)
                - NVL (Bkdesem.Monto_Poliza, 0)
                - NVL (Bkdesem.Monto_Cuota, 0);


            Bkdesem.Observaciones1 :=
                   'Desembolso Prest. No.: '
                || ' '
                || TO_CHAR (V_Cr.No_Credito)
                || ', '
                || 'Monto: '
                || ' '
                || TO_CHAR (Bkdesem.Monto_Desembolso, '99,999,999.99');
        ELSE
            P_Msj_Error := 'Crédito No Exite';
        END IF;
    EXCEPTION
        WHEN Salir
        THEN
            RETURN;
    END;

    PROCEDURE Actualiza_Credito (P_Msj_Error OUT VARCHAR2)
    IS
        V_Mensaje_Error          VARCHAR2 (6);
        V_Monto_X_Desembolsar    NUMBER (16, 2);
        Vmontosaldo              NUMBER;
        Vparametro_Desem         VARCHAR2 (300)
            := Param.Parametro_X_Empresa (1, 'V_DIA_PROXIMA_CUOTA', 'PR');
        Vdias_Extra              NUMBER := 0;
        --Vdia_Pago   Number;
        Salir                    EXCEPTION;
        vparametro_extra_desem   NUMBER := 0;
    BEGIN
        Bkcredit.Primer_Desembolso := 'N';

        vparametro_extra_desem :=
            pr_plan.f_dias_extras (BKDesem.FECHA_DESEMBOLSO);

        --
        -- Si Es El Primer Desembolso, Calcula La Nueva F. Vencimto. De
        -- Acuerdo Con El Plazo, Y El Dia De Pago Se Toma Del Dia
        -- Del Desembolso
        --
        IF (Bkcredit.F_Primer_Desembolso IS NULL)
        THEN
            Bkcredit.Primer_Desembolso := 'S';
            Bkcredit.F_Primer_Desembolso := Bkdesem.Fecha_Desembolso;

            --            IF TO_CHAR (Bkcredit.F_Primer_Desembolso, 'DD') >=
            --               NVL (Vparametro_Desem, '35')
            --            THEN
            --                Bkcredit.Dia_Pago :=
            --                    TO_CHAR (
            --                        Calendar.Obtener_Sig_Fec_Habil (
            --                            1,
            --                            0,
            --                            LAST_DAY (Bkcredit.F_Primer_Desembolso)),
            --                        'DD');
            --                Vdias_Extra :=
            --                      Calendar.Obtener_Sig_Fec_Habil (
            --                          1,
            --                          0,
            --                          LAST_DAY (Bkcredit.F_Primer_Desembolso))
            --                    - Bkcredit.F_Primer_Desembolso;
            --            ELSE
            --                Vdias_Extra := 0;
            --            END IF;
            IF     TO_CHAR (Bkcredit.F_Primer_Desembolso, 'DD') >=
                   NVL (Vparametro_Desem, '35')
               AND PR.F_aplica_d_mas_6 (Bkcredit.Codigo_Empresa,
                                        BKCredit.no_credito)
            THEN
                Vdias_Extra := vparametro_extra_desem;
            ELSE
                Vdias_Extra := 0;
            END IF;

            Bkcredit.Dia_Pago :=
                TO_CHAR (Bkdesem.Fecha_Desembolso + Vdias_Extra, 'DD');

            IF BKCredit.dia_pago = 31
            THEN
                BKCredit.dia_pago := 30;
            END IF;


            DBMS_OUTPUT.put_line (
                   'Bkcredit.Plazo_Segun_Unidad>>  '
                || Bkcredit.Plazo_Segun_Unidad);
            DBMS_OUTPUT.put_line (
                   'Bkcredit.F_Primer_Desembolso>>  '
                || Bkcredit.F_Primer_Desembolso);
            DBMS_OUTPUT.put_line (
                   'Bkcredit.F_Primer_Desembolso>>  '
                || Bkcredit.F_Primer_Desembolso);


            Bkcredit.Dias_Extra := Vdias_Extra;
            DBMS_OUTPUT.put_line (
                'Bkcredit.Dias_Extra>>  ' || Bkcredit.Dias_Extra);

            /* Bkcredit.Plazo := ADD_MONTHS (Bkcredit.F_Primer_Desembolso,
                               NVL (Bkcredit.Plazo_Segun_Unidad, 0))
                 - Bkcredit.F_Primer_Desembolso
                 + Vdias_Extra; */
            --Malmanzar 26-02-2018

            Bkcredit.Plazo :=
                  ADD_MONTHS (Bkcredit.F_Primer_Desembolso + Vdias_Extra,
                              NVL (Bkcredit.Plazo_Segun_Unidad, 0))
                - Bkcredit.F_Primer_Desembolso;         --Malmanzar 02-09-2020

            -- Setea Fecha Vencimiento
            IF (Bkcredit.Tipo_Calendario IN (2, 3))
            THEN
                -- Interes Financiero
                Pr_Procs.Agregar_Dias (Bkcredit.F_Primer_Desembolso,
                                       Bkcredit.Plazo,
                                       360,
                                       Bkcredit.F_Vencimiento,
                                       V_Mensaje_Error);
            ELSIF (Bkcredit.Tipo_Calendario IN (1, 4))
            THEN
                -- Interes Natural
                Bkcredit.F_Vencimiento :=
                    Bkcredit.F_Primer_Desembolso + Bkcredit.Plazo;
                DBMS_OUTPUT.put_line (
                       'Bkcredit.Plazo>>  '
                    || Bkcredit.Plazo
                    || ' Linea '
                    || $$plsql_line);
            END IF;

            IF (V_Mensaje_Error IS NOT NULL)
            THEN
                P_Msj_Error := Get_Mensaje_Err (V_Mensaje_Error, 'PR');
                RAISE Salir;
            END IF;
        END IF;

        IF     Bkcredit.Tipo_Cuota = 'L'
           AND Bkdesem.Plan_Libre = 'PRE-NEGOCIADO'
           AND Bkcredit.F_Apertura <> Bkdesem.Fecha_Desembolso
        THEN
            -- La Fecha De Apertura Debe Coincidir Con La Fecha De Desembolso
            P_Msj_Error := Get_Mensaje_Err ('000588', 'PR');
            RAISE Salir;
        END IF;

        Bkcredit.F_Ultimo_Desembolso := Bkdesem.Fecha_Desembolso;
        Bkcredit.Estado := 'D';
        Bkcredit.Monto_Desembolsado :=
              NVL (Bkcredit.Monto_Desembolsado, 0)
            + NVL (Bkdesem.Monto_Desembolso, 0);

        --Saldo Del Credito
        Pr_Plan.Calcular_Saldo_Movimientos (Bkcredit.Codigo_Empresa,
                                            Bkcredit.No_Credito,
                                            Bkcredit.F_Primer_Desembolso,
                                            V_Fecha_Sist,
                                            Vmontosaldo,
                                            V_Mensaje_Error);
        Bkdesem.Nuevosaldo :=
            NVL (Vmontosaldo, 0) + NVL (Bkdesem.Monto_Desembolso, 0);

        IF Bkcredit.Grupo_Tipo_Credito != 'H'
        THEN
            UPDATE Pr_Garantias
               SET Fecha_Ultimo_Bloqueo =
                       DECODE (Fecha_Ultimo_Bloqueo,
                               NULL, V_Fecha_Sist,
                               Fecha_Ultimo_Bloqueo),
                   Fecha_Remate =
                       DECODE (Fecha_Remate,
                               NULL, V_Fecha_Sist,
                               Fecha_Remate)
             WHERE     Codigo_Empresa = Bkcredit.Codigo_Empresa
                   AND Numero_Garantia IN
                           (SELECT Numero_Garantia
                              FROM Pr_Garantias_X_Credito
                             WHERE     Codigo_Empresa =
                                       Bkcredit.Codigo_Empresa
                                   AND No_Credito = Bkcredit.No_Credito)
                   AND (Fecha_Ultimo_Bloqueo IS NULL OR Fecha_Remate IS NULL);
        END IF;

        IF (NVL (Bkdesem.Monto_Desembolso, 0) >
            NVL (Bkcredit.Monto_Credito, 0))
        THEN
            V_Monto_X_Desembolsar := NVL (Bkcredit.Monto_Credito, 0);
        ELSE
            V_Monto_X_Desembolsar := NVL (Bkdesem.Monto_Desembolso, 0);
        END IF;

        --
        IF (Bkcredit.No_Credito_Origen IS NOT NULL)
        THEN
            UPDATE Pr_Creditos
               SET Monto_Desembolsado =
                         NVL (Monto_Desembolsado, 0)
                       + NVL (Bkdesem.Monto_Desembolso, 0),
                   Monto_X_Desembolsar =
                       NVL (Monto_X_Desembolsar, 0) - V_Monto_X_Desembolsar
             WHERE     Codigo_Empresa = Bkcredit.Codigo_Empresa
                   AND No_Credito = Bkcredit.No_Credito_Origen;
        END IF;

        -- Si Es Interes Anticipado Y Se Descuenta La Primera Cuota,
        -- Se Actualiza El Credito De Acuerdo Con La Amortizacion, El
        -- Interes Y Los Dias De Interes Del Caso.
        --
        IF (    Bkcredit.Primer_Desembolso = 'S'
            AND Bkdesem.Cobrar_Cuota = 'S'
            AND Bkdesem.Monto_Cuota > 0)
        THEN
            IF (Bkdesem.Monto_Cuota_Principal > 0)
            THEN
                Bkcredit.Monto_Pagado_Principal :=
                      NVL (Bkcredit.Monto_Pagado_Principal, 0)
                    + NVL (Bkdesem.Monto_Cuota_Principal, 0);

                IF (Bkcredit.Tipo_Cuota IN ('L',
                                            'N',
                                            'V',
                                            'P'))
                THEN
                    Pr_Procs.Agregar_Dias (Bkcredit.F_Primer_Desembolso,
                                           Bkcredit.Dias_Periodo_Cuota,
                                           360,
                                           Bkcredit.F_Ultimo_Pago_Principal,
                                           V_Mensaje_Error);

                    IF (V_Mensaje_Error IS NOT NULL)
                    THEN
                        P_Msj_Error :=
                            Get_Mensaje_Err (V_Mensaje_Error, 'PR');
                        RAISE Salir;
                    END IF;
                ELSIF (Bkcredit.Tipo_Cuota IN ('M'))
                THEN
                    Pr_Procs.Agregar_Dias (Bkcredit.F_Primer_Desembolso,
                                           Bkcredit.Dias_Periodo_Interes,
                                           360,
                                           Bkcredit.F_Ultimo_Pago_Principal,
                                           V_Mensaje_Error);

                    IF (V_Mensaje_Error IS NOT NULL)
                    THEN
                        P_Msj_Error :=
                            Get_Mensaje_Err (V_Mensaje_Error, 'PR');
                        RAISE Salir;
                    END IF;
                END IF;
            ELSE
                Bkcredit.Monto_Pagado_Principal := 0;
                Bkcredit.F_Ultimo_Pago_Principal := Bkdesem.Fecha_Desembolso;
            END IF;

            IF (Bkdesem.Monto_Cuota_Intereses > 0)
            THEN
                -- Pagado Interes
                Bkcredit.Monto_Pagado_Intereses :=
                      NVL (Bkcredit.Monto_Pagado_Intereses, 0)
                    + NVL (Bkdesem.Monto_Cuota_Intereses, 0);
                Bkcredit.F_Ultimo_Pago_Intereses :=
                    Bkcredit.F_Intereses_Hasta;
                Bkcredit.Intereses_Anticipados :=
                      NVL (Bkcredit.Intereses_Anticipados, 0)
                    + NVL (Bkdesem.Monto_Cuota_Intereses, 0);
            END IF;                                     -- Monto Cuota Interes
        ELSIF (Bkcredit.Primer_Desembolso = 'S')
        THEN
            Bkcredit.Monto_Pagado_Principal := 0;
            Bkcredit.Monto_Pagado_Intereses := 0;
            Bkcredit.F_Ultimo_Pago_Intereses := Bkdesem.Fecha_Desembolso;
            Bkcredit.F_Ultimo_Pago_Principal := Bkdesem.Fecha_Desembolso;
        END IF;

        IF (    Bkcredit.Primer_Desembolso = 'S'
            AND Bkdesem.Cobrar_Comision = 'S'
            AND Bkdesem.Monto_Comision > 0)
        THEN
            Bkcredit.F_Ultimo_Pago_Comision := Bkcredit.F_Comision_Hasta;
        ELSIF (    Bkcredit.Primer_Desembolso = 'S'
               AND Bkdesem.Cobrar_Comision = 'N'
               AND Bkdesem.Monto_Comision > 0)
        THEN
            Bkcredit.F_Ultimo_Pago_Comision := Bkdesem.Fecha_Desembolso;
        ELSIF (Bkcredit.Primer_Desembolso = 'S')
        THEN
            Bkcredit.F_Ultimo_Pago_Comision := Bkdesem.Fecha_Desembolso;
        END IF;                                               -- Pago Comision

        -- Fecha Moratorios Hasta

        IF (Bkcredit.Primer_Desembolso = 'S')
        THEN
            Bkcredit.F_Ultimo_Pago_Mora := Bkdesem.Fecha_Desembolso;
        END IF;

        -- Fecha Hasta De Pago De Comision Atrasada

        IF (Bkcredit.Primer_Desembolso = 'S')
        THEN
            Bkcredit.F_Pago_Comision_Atrasada := Bkdesem.Fecha_Desembolso;
        END IF;

        IF (Bkcredit.Primer_Desembolso = 'S')
        THEN
            Bkcredit.F_Pago_Cobro_Administrativo := Bkdesem.Fecha_Desembolso;
        END IF;

        Vdias_Extra := 0;
    EXCEPTION
        WHEN Salir
        THEN
            ROLLBACK;
            RETURN;
    END;

    PROCEDURE Obtiene_Subapli_Bcc (P_Empresa          NUMBER,
                                   P_Cuenta           NUMBER,
                                   V_Subapli   IN OUT NUMBER,
                                   V_Agencia   IN OUT NUMBER,
                                   N_Error     IN OUT NUMBER)
    IS
    BEGIN
        N_Error := 0;

        SELECT TO_NUMBER (Cod_Producto), TO_NUMBER (Cod_Agencia)
          INTO V_Subapli, V_Agencia
          FROM Cuenta_Efectivo
         WHERE Cod_Empresa = P_Empresa AND Num_Cuenta = P_Cuenta;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            N_Error := 1;
    END;


    PROCEDURE Generar_Cargos_3 (P_Cod_Empresa       IN     NUMBER,
                                P_Cod_Agencia       IN     NUMBER,
                                P_No_Credito        IN     NUMBER,
                                P_Cod_Transaccion   IN     NUMBER,
                                P_F_Movimiento      IN     DATE,
                                P_Saldo_Credito     IN     NUMBER,
                                P_Usuario           IN     VARCHAR2,
                                P_Sub_Aplicacion    IN     NUMBER,
                                P_Sub_Transa        IN     NUMBER,
                                P_Documento         IN     VARCHAR2,
                                P_Aplicacion        IN     VARCHAR2,
                                P_Descripcion       IN     VARCHAR2,
                                P_Tipo_Credito      IN     NUMBER,
                                P_Fecha             IN     DATE,
                                P_Bcg               IN     VARCHAR2,
                                P_Numero_Asiento    IN     NUMBER,
                                P_Msj_Error         IN OUT VARCHAR2)
    IS
        V_Consecutivo                 VARCHAR2 (250);
        V_Resultado                   BOOLEAN;
        V_Estado                      VARCHAR2 (5);
        V_Monto                       NUMBER;
        V_Cod_Cargo                   NUMBER (10);
        V_Valor_Anterior1             VARCHAR2 (250);
        V_Valor_Actual1               VARCHAR2 (250);
        V_Cuenta_Contable             VARCHAR2 (25);
        V_Tc1                         NUMBER;
        V_Tc2                         NUMBER;
        V_Monto_Linea_Asiento         NUMBER;
        V_Monto_Gasto_Linea_Asiento   NUMBER;                     --05-02-2024
        V_Etiqueta_Cargo              VARCHAR2 (15);
        pCod_cargo_imp                VARCHAR2 (10)
            := Param.Parametro_X_Empresa (Bkcredit.Codigo_Empresa,
                                          'COD_CARGO_LEY288',
                                          'PR');

        --
        Salir                         EXCEPTION;
        -- malmanzar 11-09-2024 Begin

        -- malmanzar 11-09-2024 Begin  05-02-2024
        pCUENTA_CONTABLE_DIF          VARCHAR2 (60);
        pTIPO_MOVIMIENTO              VARCHAR2 (60);
        pES_DIFERIDO                  VARCHAR2 (60);
        pCUENTA_CONTABLE_GASTO        VARCHAR2 (60);             -- 20-12-2024
        pCUENTA_CONTABLE_PROV         VARCHAR2 (60);             -- 20-12-2024
        pPORC_GASTO                   NUMBER (4, 2);             -- 20-12-2024
        vMonto_Gasto_dif              NUMBER (18, 2);            -- 20-12-2024
        --
        v_cartera                     VARCHAR2 (30);              --10-12-2024
    -- malmanzar 11-09-2024 End
    -- malmanzar 11-09-2024 End
    BEGIN
        -- Se Recorre El Bloque De Cargos
        IF Pbkcargo.COUNT = 0
        THEN
            RETURN;
        END IF;

        FOR Vreg IN Pbkcargo.FIRST .. Pbkcargo.LAST
        LOOP
            --
            Pr_Procs.Asigna_Transaccion (V_Consecutivo, 'ESPA');

            IF (Bkdesem.Cobrar_Cargos = 'S')
            THEN
                V_Estado := 'A';
                V_Monto := 0;
            ELSE
                V_Estado := 'P';
                V_Monto := Pbkcargo (Vreg).Monto_Cargo;
            END IF;

            IF (Pbkcargo (Vreg).Codigo_Tipo_Transaccion = 1)
            THEN
                V_Cod_Cargo := 1;
            ELSE
                V_Cod_Cargo := 2;
            END IF;

            V_Valor_Anterior1 :=
                   '|'
                || TO_CHAR (Pbkcargo (Vreg).F_Ultima_Generacion,
                            'Dd/Mm/Yyyy')
                || '|';
            V_Valor_Actual1 := '|' || TO_CHAR (P_Cod_Transaccion) || '|';

            Pr_Procs.Genera_Movimiento_Credito (
                -- Empresa, Agencia, No Credito, Transaccion (Cargos Automaticos)
                P_Cod_Empresa,
                P_Cod_Agencia,
                P_No_Credito,
                V_Cod_Cargo,
                -- F Mov, Monto Mov, No Documento Mov, Tipo Pago, No Cuenta
                P_F_Movimiento,
                Pbkcargo (Vreg).Monto_Cargo,
                V_Consecutivo,
                NULL,
                NULL,
                -- No Trans, Montos: Cargo, Princ, Interes, Mora, Commis, Poliz
                TO_CHAR (Bkcredit.Numero_Transaccion),
                V_Monto,
                0,
                0,
                0,
                0,
                0,
                -- No Cuota, Asiento, Dias Mora, Dias Interes, Estado
                NULL,
                NULL,
                NULL,
                NULL,
                V_Estado,
                -- Observ: 1, 2, 3, 4, Cod Firma Legal, Cod Juzgado, Plazo Ant,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                -- Nivel Aprob, F Aplic, Pago Menor, Usuario, Cod Cargo,
                NULL,
                P_F_Movimiento,
                NULL,
                P_Usuario,
                Pbkcargo (Vreg).Codigo_Cargo,
                -- F Pago, Valor Ant1, Valor Ant2, Valor Act1, Valor Act2
                NULL,
                V_Valor_Anterior1,
                NULL,
                V_Valor_Actual1,
                NULL,
                -- F Aplicado, Dias Principal, Dias Comision,
                P_F_Movimiento,
                NULL,
                NULL,
                -- Tipo Poliza, Numero Poliza, Resultado
                NULL,
                NULL,
                P_Cierre.Ccodidioma,
                V_Resultado,
                P_Msj_Error);

            -----dbms_output.Put_Line('Genera_Mov X Cargo:'||To_Char(V_Consecutivo)||'.  Error:'||  P_Msj_Error);
            IF (NOT V_Resultado)
            THEN
                -- Error:  Insertando El Movimiento
                P_Msj_Error := '000024';
                RAISE Salir;
            END IF;

            -----dbms_output.Put_Line('Cargos 004 . Pbcg = '||Pbcg||'  Bkdesem.Cobrar_Cargos '|| Bkdesem.Cobrar_Cargos);
            IF ((P_Bcg = 'S') AND (Bkdesem.Cobrar_Cargos = 'S'))
            THEN
                Pr_Procs.Cuenta_Contable_Cargos_Bpr (
                    P_Cod_Empresa,
                    P_Tipo_Credito,
                    Pbkcargo (Vreg).Codigo_Tipo_Transaccion,
                    Pbkcargo (Vreg).Codigo_Cargo,
                    V_Cuenta_Contable,
                    P_Msj_Error);

                -----dbms_output.Put_Line('Cuenta Contable Cargos: '||  V_Cuenta_Contable);
                IF (P_Msj_Error IS NOT NULL)
                THEN
                    RAISE Salir;
                END IF;

                Pr_Procs.Convierte_Monto_Credcta (
                    P_Cod_Empresa,
                    Pbkcargo (Vreg).Monto_Cargo,
                    Bkcredit.Codigo_Moneda,
                    V_Cuenta_Contable,
                    P_Fecha,
                    V_Monto_Linea_Asiento,
                    P_Msj_Error);

                IF P_Msj_Error IS NOT NULL
                THEN
                    -- Message(P_Msj_Error);
                    RAISE Salir;
                END IF;

                -- Rmartinez 06/10/2004
                -- Para Que Presente El Valor De Los Cargos En El Cheque
                IF Pbkcargo (Vreg).Codigo_Cargo = 1
                THEN
                    V_Etiqueta_Cargo := '(G.L.)';
                ELSIF Pbkcargo (Vreg).Codigo_Cargo = 14
                THEN
                    V_Etiqueta_Cargo := '(Poliza)';
                ELSIF Pbkcargo (Vreg).Codigo_Cargo = Pcod_Cargo_Imp
                THEN
                    V_Etiqueta_Cargo := '(Ley288-04)'; ---- Tenia Esto 0.15%B.C. By Wen 01-03-05
                END IF;

                IF Bkdesem.Observaciones2 IS NULL
                THEN
                    Bkdesem.Observaciones2 :=
                           'Menos:'
                        || ' '
                        || TO_CHAR (V_Monto_Linea_Asiento, '99,999.99')
                        || ' '
                        || V_Etiqueta_Cargo;
                ELSE
                    Bkdesem.Observaciones2 :=
                           Bkdesem.Observaciones2
                        || ', '
                        || TO_CHAR (V_Monto_Linea_Asiento, '999,999.99')
                        || ' '
                        || V_Etiqueta_Cargo;
                END IF;

                --Here Begin
                -- p_depura('Generar_Cargos_3 antes linea asiento Linea '||$$plsql_line);

                ---malmanzar 14-12-2022, aqui se debe realizar el diferimiento del cargo Begin, tomar en cuenta la reversión.
                --malmanzar 16-11-2022, req. 156144 Begin

                v_cartera := F_CARTERA (P_Cod_Empresa, P_No_Credito); --05-02-2025

                BEGIN
                    CG.cg_pkg_cargo_diferido.P_CONCEPTO_DIFERIDO (
                        pCODIGO_EMPRESA          => P_Cod_Empresa,
                        pCOD_SISTEMA             => 'PR',
                        pCONCEPTO                => Pbkcargo (Vreg).Codigo_Cargo,
                        pCODIGO_MONEDA           => Bkcredit.Codigo_Moneda,
                        pCARTERA                 => v_cartera, --malmanzar 10-12-2024
                        -- Out
                        pCUENTA_CONTABLE_DIF     => pCUENTA_CONTABLE_DIF,
                        pTIPO_MOVIMIENTO         => pTIPO_MOVIMIENTO,
                        pES_DIFERIDO             => pES_DIFERIDO,
                        pCUENTA_CONTABLE_GASTO   => pCUENTA_CONTABLE_GASTO,
                        pCUENTA_CONTABLE_PROV    => pCUENTA_CONTABLE_PROV,
                        pPORC_GASTO              => pPORC_GASTO);

                    IF NVL (pES_DIFERIDO, 'N') = 'S'
                    THEN
                        --Calcular Monto Gasto
                        IF NVL (pPORC_GASTO, 0) > 0
                        THEN
                            vMonto_Gasto_dif :=
                                ROUND (
                                      Pbkcargo (Vreg).Monto_Cargo
                                    * pPORC_GASTO
                                    / 100,
                                    2);
                        ELSE
                            vMonto_Gasto_dif := 0;
                        END IF;


                        --Lineas asiento Gasto difirido Begin  20-12-2024
                        IF     vMonto_Gasto_dif > 0
                           AND pCUENTA_CONTABLE_GASTO IS NOT NULL
                           AND pCUENTA_CONTABLE_PROV IS NOT NULL
                        THEN
                            Pr_Procs.Convierte_Monto_Credcta (
                                P_Cod_Empresa,
                                vMonto_Gasto_dif, --Pbkcargo (Vreg).Monto_Cargo,
                                Bkcredit.Codigo_Moneda,
                                pCUENTA_CONTABLE_GASTO,
                                P_Fecha,
                                V_Monto_Gasto_Linea_Asiento,
                                P_Msj_Error);

                            IF P_Msj_Error IS NOT NULL
                            THEN
                                -- Message(P_Msj_Error);
                                RAISE Salir;
                            END IF;

                            Cg_Utl.Lineas_Del_Asiento (
                                P_Cod_Empresa,
                                P_Cod_Agencia,
                                P_Aplicacion,
                                P_Sub_Aplicacion,
                                Pbkcargo (Vreg).Codigo_Tipo_Transaccion,
                                P_Sub_Transa,
                                P_Documento,
                                P_Descripcion,
                                P_Fecha,                         -- Movimiento
                                P_Fecha,                              -- Valor
                                P_Fecha,                            -- Asiento
                                P_Numero_Asiento,
                                pCUENTA_CONTABLE_GASTO,   --V_Cuenta_Contable,
                                Bkcredit.Codigo_Agencia,           -- Auxiliar
                                V_Monto_Gasto_Linea_Asiento,
                                'N',                          -- Acumula Monto
                                'D',                                 -- Dédito
                                'N',                            -- Modificable
                                V_Tc1,                   -- Tipo Cambio Origen
                                V_Tc2,                   -- Tipo Cambio Origen
                                USER,
                                P_Msj_Error);

                            ---  --dbms_output.Put_Line('Linea Asiento Cargos, Num-Asto: '||P_Numero_Asiento||' Monto: '||To_Char(V_Monto_Linea_Asiento,'999990.00'));

                            IF (P_Msj_Error IS NOT NULL)
                            THEN
                                -- Message(P_Msj_Error);    --- By Wen 15/12/2004
                                RAISE Salir;
                            END IF;


                            Cg_Utl.Lineas_Del_Asiento (
                                P_Cod_Empresa,
                                P_Cod_Agencia,
                                P_Aplicacion,
                                P_Sub_Aplicacion,
                                Pbkcargo (Vreg).Codigo_Tipo_Transaccion,
                                P_Sub_Transa,
                                P_Documento,
                                P_Descripcion,
                                P_Fecha,                         -- Movimiento
                                P_Fecha,                              -- Valor
                                P_Fecha,                            -- Asiento
                                P_Numero_Asiento,
                                pCUENTA_CONTABLE_PROV,    --V_Cuenta_Contable,
                                Bkcredit.Codigo_Agencia,           -- Auxiliar
                                V_Monto_Gasto_Linea_Asiento,
                                'N',                          -- Acumula Monto
                                'C',                                -- Crédito
                                'N',                            -- Modificable
                                V_Tc1,                   -- Tipo Cambio Origen
                                V_Tc2,                   -- Tipo Cambio Origen
                                USER,
                                P_Msj_Error);

                            ---  --dbms_output.Put_Line('Linea Asiento Cargos, Num-Asto: '||P_Numero_Asiento||' Monto: '||To_Char(V_Monto_Linea_Asiento,'999990.00'));

                            IF (P_Msj_Error IS NOT NULL)
                            THEN
                                -- Message(P_Msj_Error);    --- By Wen 15/12/2004
                                RAISE Salir;
                            END IF;
                        END IF;                         --vMonto_Gasto_dif > 0

                        --Lineas asiento Gasto difirido end    20-12-2024



                                                   --Crea movimiento a diferir
                        CG.CG_PKG_CARGO_DIFERIDO.pCREA_CARGO_DIFERIDO (
                            pCodigo_Empresa           => P_Cod_Empresa, --IN NUMBER,
                            pCod_Sistema              => 'PR',
                            pTipo_Cargo               => 'PD',
                            pConcepto                 => Pbkcargo (Vreg).Codigo_Cargo,
                            pCartera                  => v_cartera, --malmanzar 10-12-2024
                            pNUM_CTA_CREDITO          => P_No_Credito,
                            pNum_Tarjeta              => P_No_Credito,
                            pFecha_Proceso            => P_Fecha,   --IN DATE,
                            pTipo_Transaccion         =>
                                Pbkcargo (Vreg).Codigo_Tipo_Transaccion, -- v_registros (i).tip_transaccion, --IN VARCHAR2,
                            pCodigo_Agencia           => P_Cod_Agencia, --vAgencia_Producto,--pagencia, --IN NUMBER,
                            pCodigo_Moneda            => Bkcredit.Codigo_Moneda, --vmoneda.cod_moneda, --IN NUMBER,
                            pMonto_Cargo              => Pbkcargo (Vreg).Monto_Cargo, --  v_registros (i).vn_dmtotransac, --IN NUMBER,
                            pCuenta_Contable_Dif      => pCUENTA_CONTABLE_DIF, --IN VARCHAR2
                            pCuenta_Contable_Origen   => v_Cuenta_Contable, --IN VARCHAR2
                            pCuenta_Contable_Gasto    =>
                                pCUENTA_CONTABLE_GASTO,           --20-12-2024
                            pCuenta_Contable_Prov     => pCUENTA_CONTABLE_PROV, --20-12-2024
                            pMonto_Gasto              => vMonto_Gasto_dif, --CASE WHEN   NVL(pPORC_GASTO,0) > 0 THEN ROUND(Pbkcargo (Vreg).Monto_Cargo * pPORC_GASTO/ 100,2) ELSE 0 END,   --20-12-2024
                            pNumero_Asiento           => P_Numero_Asiento, --v_numeroasiento,
                            pDESC_TRANSACCION         => P_Descripcion, ----------
                            pSUBTIP_TRANSAC           => NULL, ---P_Sub_Transa, -----------   18-12-2024
                            pCODIGO_SUB_APLICACION    => P_Sub_Aplicacion -----------
                                                                         );

                        V_Cuenta_Contable := pCUENTA_CONTABLE_DIF;
                    END IF;                        --(pES_DIFERIDO, 'N') = 'S'
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        NULL;              --vconterrores := vconterrores + 1;
                END;

                --malmanzar 16-11-2022 req. 156144 End
                --Here End

                Cg_Utl.Lineas_Del_Asiento (
                    P_Cod_Empresa,
                    P_Cod_Agencia,
                    P_Aplicacion,
                    P_Sub_Aplicacion,
                    Pbkcargo (Vreg).Codigo_Tipo_Transaccion,
                    P_Sub_Transa,
                    P_Documento,
                    P_Descripcion,
                    P_Fecha,                                     -- Movimiento
                    P_Fecha,                                          -- Valor
                    P_Fecha,                                        -- Asiento
                    P_Numero_Asiento,
                    V_Cuenta_Contable,
                    Bkcredit.Codigo_Agencia,                       -- Auxiliar
                    V_Monto_Linea_Asiento,
                    'N',                                      -- Acumula Monto
                    'C',                                            -- Credito
                    'N',                                        -- Modificable
                    V_Tc1,                               -- Tipo Cambio Origen
                    V_Tc2,                               -- Tipo Cambio Origen
                    USER,
                    P_Msj_Error);

                ---  --dbms_output.Put_Line('Linea Asiento Cargos, Num-Asto: '||P_Numero_Asiento||' Monto: '||To_Char(V_Monto_Linea_Asiento,'999990.00'));

                IF (P_Msj_Error IS NOT NULL)
                THEN
                    -- Message(P_Msj_Error);    --- By Wen 15/12/2004
                    RAISE Salir;
                END IF;
            END IF; -- Interface Contable (Conta = 'S') Y Estoy Cobrando Cargos

            -----dbms_output.Put_Line('Cargos 009 Transac  '||  Pbkcargo(Vreg).Codigo_Tipo_Transaccion);

            IF (Pbkcargo (Vreg).Codigo_Tipo_Transaccion = 1)
            THEN
                -- Si Es Un Cargo Automatico
                UPDATE Pr_Cargos_X_Credito
                   SET F_Ultima_Generacion = Bkdesem.Fecha_Desembolso
                 WHERE     Codigo_Empresa = TO_NUMBER (P_Cierre.Ccodempresa)
                       AND No_Credito = Bkcredit.No_Credito
                       AND Codigo_Tipo_Transaccion = 1
                       AND Codigo_Cargo = Pbkcargo (Vreg).Codigo_Cargo;
            END IF;
        END LOOP;
    -----dbms_output.Put_Line('Genera-Cargos3 , Sale Del Loop. Error: '||P_Msj_Error);
    EXCEPTION
        WHEN Salir
        THEN
            RETURN;
        WHEN OTHERS
        THEN
            -----dbms_output.Put_Line('Cargos Entro When Others');
            P_Msj_Error := '000032';
            RETURN;
    END;                                                   -- Generar_Cargos_3

    PROCEDURE Cuadre_Asiento_Centimo_Pr (Pcodigoempresa   IN     NUMBER,
                                         Pcodigoagencia   IN     NUMBER,
                                         P_Cod_Idioma     IN     VARCHAR2,
                                         Psubaplicacion   IN     NUMBER,
                                         Pnumtransac      IN     VARCHAR2,
                                         Ptransaccion     IN     NUMBER,
                                         Pauxiliar        IN     NUMBER,
                                         Pfechamov        IN     DATE,
                                         Pnoasiento       IN     NUMBER,
                                         Pmontodife       IN OUT NUMBER,
                                         P_Usuario        IN     VARCHAR2,
                                         P_Desc1          IN     VARCHAR2, -- Debe Decir: Diferencias Por Conversion De Monedas
                                         Pmsjerror        IN OUT VARCHAR2)
    IS
        CURSOR Cmonedas (Pcodigoempresa   NUMBER,
                         Pmonedaorigen    NUMBER,
                         Pfechamov        DATE,
                         Pnoasiento       NUMBER)
        IS
            SELECT Codigo_Moneda Codigo, Abreviatura
              FROM Monedas
             WHERE     Codigo_Moneda <> Pmonedaorigen
                   AND Codigo_Moneda IN
                           (SELECT DISTINCT Cat.Moneda_Cuenta
                              FROM Cg_Movimiento_Detalle  Mov,
                                   Cg_Catalogo_X_Empresa  Cat
                             WHERE     Mov.Codigo_Empresa = Pcodigoempresa
                                   AND Mov.Fecha_Movimiento = Pfechamov
                                   AND Mov.Numero_Asiento = Pnoasiento
                                   AND Cat.Codigo_Empresa = Pcodigoempresa
                                   AND Cat.Moneda_Cuenta <> Pmonedaorigen
                                   AND Cat.Cuenta_Contable =
                                       Mov.Cuenta_Contable);

        Vmoneda          Cmonedas%ROWTYPE;

        -- Cuenta Contable Y Tipos De Cambio
        Vctactable       Cg_Catalogo_X_Empresa.Cuenta_Contable%TYPE;
        Vtcdummy1        NUMBER;
        Vtcdummy2        NUMBER;
        -- Diferencias
        Vdifdb           NUMBER := 0;
        Vdifcr           NUMBER := 0;
        Vmargen          NUMBER;
        -- Otros
        Vaccion          VARCHAR2 (100) := 'INCLUIR';
        Vlinea           VARCHAR2 (50) := NULL;
        -- Debitos Y Creditos
        Vtotaldbcuenta   NUMBER;
        Vtotalcrcuenta   NUMBER;
        Vtotaldborigen   NUMBER;
        Vtotalcrorigen   NUMBER;
        -- Tipos De Cambio Promedio
        Vpromtccuenta    NUMBER;
        Vpromtcorigen    NUMBER;
        -- Temporales
        Vdummy           NUMBER;
        Vhuboajustes     BOOLEAN := FALSE;
        Vmonedaorigen    NUMBER;
        Vmonedabase      NUMBER;
    ---
    BEGIN
        DBMS_OUTPUT.put_line (
               '$$plsqle_type '
            || $$plsql_type
            || ' Program '
            || $$plsql_unit
            || ' Linea '
            || $$plsql_line);
        Pmsjerror := NULL;

        SELECT NVL (SUM (Debito), 0) - NVL (SUM (Credito), 0)
          INTO Pmontodife
          FROM Cg_Movimiento_Detalle
         WHERE     Codigo_Empresa = Pcodigoempresa
               AND Fecha_Movimiento = Pfechamov
               AND Numero_Asiento = Pnoasiento;

        --
        -- Se Obtiene El Margen De Tolerancia Para Diferencias Por Conversion
        -- Entre Tipos De Cambio
        --
        BEGIN
            SELECT NVL (Diferencia_Conversion, 0)
              INTO Vmargen
              FROM Cg_Parametros
             WHERE Codigo_Empresa = Pcodigoempresa;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                Pmsjerror := '000034'; -- Error: No Se Encontro Los Parametros
                RETURN;
            WHEN TOO_MANY_ROWS
            THEN
                Pmsjerror := '000195'; -- Parametros Duplicados Para La Empresa
                RETURN;
        END;

        IF (Pmontodife = 0)
        THEN
            UPDATE Cg_Movimiento_Detalle
               SET Estado = 'P'
             WHERE     Codigo_Empresa = Pcodigoempresa
                   AND Fecha_Movimiento = Pfechamov
                   AND Numero_Asiento = Pnoasiento;

            ---
            UPDATE Cg_Movimiento_Resumen
               SET Estado = 'P'
             WHERE     Codigo_Empresa = Pcodigoempresa
                   AND Fecha_Movimiento = Pfechamov
                   AND Numero_Asiento = Pnoasiento;
        ---
        ELSIF (ABS (Pmontodife) < Vmargen)
        THEN
            --
            -- Aqui Verifican Errores Por Diferencia De Conversion Entre
            -- Monedas.
            --
            -- Determina Moneda Base Y Moneda Origen
            --
            BEGIN
                SELECT Codigo_Moneda_Origen, Codigo_Moneda_Base_Tc
                  INTO Vmonedaorigen, Vmonedabase
                  FROM Empresas
                 WHERE Codigo_Empresa = Pcodigoempresa;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    Pmsjerror := '000011';       --Error: La Empresa No Existe
                    RETURN;
                WHEN TOO_MANY_ROWS
                THEN
                    Pmsjerror := '000012'; -- Error: La Empresa Esta Duplicada
                    RETURN;
                WHEN OTHERS
                THEN
                    Pmsjerror := '000032';
                    RETURN;
            END;

            Vhuboajustes := FALSE;
            Cuenta_Contable (Pcodigoempresa,
                             'BPR',
                             Psubaplicacion,
                             'Diferencias_Por_Conversion',
                             Vctactable,
                             Pmsjerror);

            IF (Pmsjerror IS NOT NULL)
            THEN
                RETURN;
            END IF;

            FOR Vmoneda IN Cmonedas (Pcodigoempresa,
                                     Vmonedaorigen,
                                     Pfechamov,
                                     Pnoasiento)
            LOOP
                --
                -- Se Obtienen Los Montos Al Debito Y Credito En Las Monedas
                -- De La Cuenta Y Origen Ver Si Cuadran. Tambien Se Calcula
                -- Un Promedio De Los Tipos De Cambio Utilizados Para Las
                -- Conversiones.
                --
                SELECT NVL (SUM (Debito_Cta), 0),
                       NVL (SUM (Credito_Cta), 0),
                       NVL (SUM (Debito), 0),
                       NVL (SUM (Credito), 0),
                       AVG (Tipo_Cambio1),
                       AVG (Tipo_Cambio2)
                  INTO Vtotaldbcuenta,
                       Vtotalcrcuenta,
                       Vtotaldborigen,
                       Vtotalcrorigen,
                       Vpromtccuenta,
                       Vpromtcorigen
                  FROM Cg_Movimiento_Detalle
                 WHERE     Codigo_Empresa = Pcodigoempresa
                       AND Fecha_Movimiento = Pfechamov
                       AND Numero_Asiento = Pnoasiento
                       AND Cuenta_Contable IN
                               (SELECT Cuenta_Contable
                                  FROM Cg_Catalogo_X_Empresa
                                 WHERE     Codigo_Empresa = Pcodigoempresa
                                       AND Moneda_Cuenta = Vmoneda.Codigo);

                --
                -- Se Verifican Diferencias En Los Debitos
                --
                Cg_Utl.Convierte_Monto (Pcodigoempresa,
                                        Vtotaldbcuenta,
                                        Vmoneda.Codigo,
                                        Pfechamov,
                                        Vpromtccuenta,
                                        Vpromtcorigen,
                                        Vdifdb,
                                        Vdummy,
                                        Pmsjerror);
                Vdifdb :=
                      (TRUNC (Vdifdb * POWER (10, 2) + 0.5) / POWER (10, 2))
                    - (  TRUNC (Vtotaldborigen * POWER (10, 2) + 0.5)
                       / POWER (10, 2));
                --
                -- Se Verifican Diferencias En Los Creditos
                --
                Cg_Utl.Convierte_Monto (Pcodigoempresa,
                                        Vtotalcrcuenta,
                                        Vmoneda.Codigo,
                                        Pfechamov,
                                        Vpromtccuenta,
                                        Vpromtcorigen,
                                        Vdifcr,
                                        Vdummy,
                                        Pmsjerror);
                Vdifcr :=
                      (TRUNC (Vdifcr * POWER (10, 2) + 0.5) / POWER (10, 2))
                    - (  TRUNC (Vtotalcrorigen * POWER (10, 2) + 0.5)
                       / POWER (10, 2));

                --
                -- Un Error Conversion Puede Ser A Favor O En Contra, Por
                -- Lo Cual Un Error Negativo Al Credito Por Ejemplo, Se
                -- Tomara Como Un Error Positivo Al Debito Y Visceversa.
                --
                IF (Vdifdb < 0 AND Vdifcr < 0)
                THEN
                    Vdifdb := ABS (Vdifcr);
                    Vdifcr := ABS (Vdifdb);
                ELSIF (Vdifdb >= 0 AND Vdifcr < 0)
                THEN
                    Vdifdb := Vdifdb + ABS (Vdifcr);
                    Vdifcr := 0;
                ELSIF (Vdifdb < 0 AND Vdifcr >= 0)
                THEN
                    Vdifdb := 0;
                    Vdifcr := Vdifcr + ABS (Vdifdb);
                END IF;

                IF (Vdifdb < Vdifcr)
                THEN
                    Vhuboajustes := TRUE;
                    -- P_Desc1 -> Diferencias Por Conversion De Monedas
                    Cg_Utl.Lineas_Del_Asiento (Pcodigoempresa,
                                               Pcodigoagencia,
                                               'Bpr',
                                               Psubaplicacion,
                                               Ptransaccion,
                                               NULL,
                                               Pnumtransac,
                                               P_Desc1,
                                               Pfechamov,
                                               Pfechamov,
                                               Pfechamov,
                                               Pnoasiento,
                                               Vctactable,
                                               Pauxiliar,
                                               (Vdifcr - Vdifdb),
                                               'S',
                                               'C',
                                               'N',
                                               Vtcdummy1,
                                               Vtcdummy2,
                                               P_Usuario,
                                               Pmsjerror);

                    IF (Pmsjerror IS NOT NULL)
                    THEN
                        RETURN;
                    ELSE
                        Vaccion := 'ACTUALIZAR';
                    END IF;
                ELSIF (Vdifdb > Vdifcr)
                THEN
                    Vhuboajustes := TRUE;
                    Cg_Utl.Lineas_Del_Asiento (
                        Pcodigoempresa,
                        Pcodigoagencia,
                        'BPR',
                        Psubaplicacion,
                        Ptransaccion,
                        NULL,
                        Pnumtransac,
                        'DIFERENCIAS POR CONVERSION DE MONEDAS ',
                        Pfechamov,
                        Pfechamov,
                        Pfechamov,
                        Pnoasiento,
                        Vctactable,
                        Pauxiliar,
                        (Vdifdb - Vdifcr),
                        'S',
                        'D',
                        'N',
                        Vtcdummy1,
                        Vtcdummy2,
                        P_Usuario,
                        Pmsjerror);

                    IF (Pmsjerror IS NOT NULL)
                    THEN
                        RETURN;
                    ELSE
                        Vaccion := 'ACTUALIZAR';
                    END IF;
                END IF;                   -- Movimiento Al Debito O Al Credito
            END LOOP;                                  -- Recorrido De Monedas

            IF (Vhuboajustes)
            THEN
                SELECT NVL (SUM (Debito), 0) - NVL (SUM (Credito), 0)
                  INTO Pmontodife
                  FROM Cg_Movimiento_Detalle
                 WHERE     Codigo_Empresa = Pcodigoempresa
                       AND Fecha_Movimiento = Pfechamov
                       AND Numero_Asiento = Pnoasiento;

                IF (Pmontodife = 0)
                THEN
                    UPDATE Cg_Movimiento_Detalle
                       SET Estado = 'P'
                     WHERE     Codigo_Empresa = Pcodigoempresa
                           AND Fecha_Movimiento = Pfechamov
                           AND Numero_Asiento = Pnoasiento;

                    ---
                    UPDATE Cg_Movimiento_Resumen
                       SET Estado = 'P'
                     WHERE     Codigo_Empresa = Pcodigoempresa
                           AND Fecha_Movimiento = Pfechamov
                           AND Numero_Asiento = Pnoasiento;
                ---
                END IF;
            END IF;
        END IF;                      -- Verificacion De Cuadratura Del Asiento

        IF (Pmontodife <> 0)
        THEN
            Pmsjerror := '000196';                     -- El Asiento No Cuadra
            RETURN;
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            Pmsjerror := '000197';                     -- No Existe El Asiento
            RETURN;
        WHEN OTHERS
        THEN
            Pmsjerror := '000032';
            RETURN;
    END;

    PROCEDURE Solicitud_Bcc (P_Empresa            IN     NUMBER,
                             P_Agencia            IN     NUMBER,
                             P_Transaccion        IN     NUMBER,
                             P_Subtransa          IN     NUMBER,
                             P_Aplicacion         IN     VARCHAR2,
                             P_Subaplicacion      IN     NUMBER,
                             P_Cuenta             IN     VARCHAR2,
                             P_Tipo_Desem         IN     VARCHAR2,
                             P_Cliente            IN     NUMBER,
                             P_Fecha_Movimiento   IN     DATE,
                             P_Fecha              IN     DATE,
                             P_Observaciones1     IN     VARCHAR2,
                             P_Observaciones2     IN     VARCHAR2,
                             P_Observaciones3     IN     VARCHAR2,
                             P_Observaciones4     IN     VARCHAR2,
                             P_Tipo_Cargos        IN     VARCHAR2,
                             P_Documento          IN     VARCHAR2,
                             P_No_Movimiento      IN OUT NUMBER,
                             P_Numero_Asiento     IN OUT NUMBER,
                             P_Tc1                IN OUT NUMBER,
                             P_Tc2                IN OUT NUMBER,
                             P_Mensaje_Error      IN OUT VARCHAR2,
                             Pcoderror            IN OUT VARCHAR2)
    IS
        --
        --  Funcion :Realiza La Solicitud De Nota De Debito De La Cuenta Cc

        --       V_Conta                 VARCHAR2 (1);
        V_Diferencia            NUMBER;
        V_Numero_Asiento        NUMBER;
        V_Mensaje_Error         VARCHAR2 (500);
        V_Mensaje_Error2        VARCHAR2 (500);
        V_Descripcion           VARCHAR2 (250);
        V_Subaplicacion         NUMBER (3);
        V_Cuenta_Contable       VARCHAR2 (25);
        --        V_Unidad_Ejecutora      NUMBER (15);
        --       V_Monto                 NUMBER;
        V_Resultado             BOOLEAN;
        V_Num_Mov               NUMBER;
        V_Num_Mov_Cng           NUMBER; --- Excello:JPH:2020-07-17:REQ._112142
        V_Numero                NUMBER;
        V_Error                 VARCHAR2 (6);
        V_Errapli               NUMBER;
        N_Error                 NUMBER (1);
        V_Agenciadecta          NUMBER (5);
        V_No_Documento          VARCHAR2 (250);
        V_Cargo                 NUMBER (5);
        V_Estado                VARCHAR2 (10);
        V_Dias_Poliza           NUMBER (5);
        V_F_Prox_Poliza         DATE;
        V_Valor1_Actual         VARCHAR2 (250);
        V_Valor1_Anterior       VARCHAR2 (250);
        --        Vsector                 VARCHAR2 (6);
        --       V_Concepto              VARCHAR2 (100);             -- Api 18/Oct/2008
        --
        V_Monto_Linea_Asiento   NUMBER;
        V_Cod_Cliente_Desem     Cuenta_Efectivo.Cod_Cliente%TYPE;
        lc_congela              VARCHAR2 (30);
        vMontoPunto15           NUMBER := 0;
        vimpuesto               NUMBER := 0;
        ln_secuencia            NUMBER;

        nMontoCanSaldo          NUMBER (16, 2);         --malmanzar 14-02-2023
        --       vSaldo_Disponible       NUMBER;
        --       V_Monto_Cancelacion     NUMBER;

        -- Excepciones --
        Bcc                     EXCEPTION;
        Conta                   EXCEPTION;
        Cargo                   EXCEPTION;
        General                 EXCEPTION;
        --        Salir                   EXCEPTION;

        -- Nuevas varables ---
        PBCG                    VARCHAR2 (1) := NULL;
        PBCC                    VARCHAR2 (1) := NULL;
        PBBA                    VARCHAR2 (1) := NULL;

        ---V_Mensaje_Error      Varchar2(1) := Null;

        -- Cursores ----
        CURSOR Polizas (V_Empresa NUMBER, V_Credito NUMBER)
        IS
            SELECT Tipo_Poliza,
                   Numero_Poliza,
                   Tipo_Cobro,
                   NVL (Monto_A_Pagar, 0)     Monto_A_Pagar,
                   F_Ultima_Generacion,
                   Codigo_Periodo
              FROM Pr_Polizas_X_Credito
             WHERE     Codigo_Empresa = V_Empresa
                   AND No_Credito = V_Credito
                   AND F_Ultima_Generacion IS NULL
                   AND Numero_Poliza IN
                           (SELECT Numero_Poliza
                              FROM Pr_Polizas
                             WHERE     Codigo_Empresa = P_Empresa
                                   AND Modalidad_Poliza = 'C');
    BEGIN
        DBMS_OUTPUT.put_line ('P_Cuenta ' || P_Cuenta);
        DBMS_OUTPUT.put_line ('P_Tipo_Desem ' || P_Tipo_Desem);
        -- Determina si hay interfase con otros sistemas --
        PR_PROCS.Busca_Interfase (P_Empresa,
                                  P_Agencia,
                                  'ESPA',
                                  'BCG',
                                  PBCG,
                                  V_Mensaje_Error);
        PR_PROCS.Busca_Interfase (P_Empresa,
                                  P_Agencia,
                                  'ESPA',
                                  'BCC',
                                  PBCC,
                                  V_Mensaje_Error);
        PR_PROCS.Busca_Interfase (P_Empresa,
                                  P_Agencia,
                                  'ESPA',
                                  'BBA',
                                  PBBA,
                                  V_Mensaje_Error);

        -- Et_Descripcion4: Desembolso Del Credito #
        -- Et_Descripcion5: A La Cuenta #
        V_Descripcion :=
               'Desembolso Del Credito #'
            || ' '
            || TO_CHAR (Bkcredit.No_Credito)
            || ' '
            || 'A La Cuenta #'
            || ' '
            || TO_CHAR (P_Cuenta);

        IF P_Tipo_Desem = 'C'
        THEN
            Obtiene_Subapli_Bcc (P_Empresa,
                                 TO_NUMBER (Bkdesem.Numero_Cuenta),
                                 V_Subaplicacion,
                                 V_Agenciadecta,
                                 N_Error);

            IF N_Error <> 0
            THEN
                Pcoderror := '000584';
                RAISE General;
            END IF;
        ELSE
            V_Subaplicacion := bkcredit.codigo_sub_aplicacion;
        END IF;                                        --IF P_Tipo_Desem = 'C'

        -- Verifica Si Hay Interface Contable
        IF PBCG = 'S'
        THEN
            Cg_Utl.Caratula_Del_Asiento (P_Empresa,
                                         P_Agencia,
                                         P_Aplicacion,
                                         P_Subaplicacion,
                                         P_Transaccion,
                                         P_Subtransa,
                                         P_Documento,
                                         V_Descripcion,
                                         P_Fecha,
                                         P_Fecha,
                                         V_Numero_Asiento,
                                         USER,
                                         V_Mensaje_Error2);

            ---Dbms_Output.Put_Line('Solbcc 002 .Caratula Asiento. Error: '||V_Mensaje_Error2 );

            IF V_Mensaje_Error2 IS NOT NULL
            THEN
                P_Mensaje_Error := V_Mensaje_Error2;
                RAISE Conta;
            END IF;

            P_Numero_Asiento := V_Numero_Asiento;

            ---Dbms_Output.Put_Line('Solbcc 003 . Numero-Asiento'||To_Char(V_Numero_Asiento));

            -- Busca Cuenta De Principal De Prestamos
            -- Modificado Bsc
            /*  --Comentado para utilizar funcion f_busca_cuenta_cartera --malmanzar 23-04-2020
              Pr_Procs.Cuenta_Contable_Principal_Bpr (Bkcredit.Codigo_Empresa,
                                                      Bkcredit.Tipo_Credito,
                                                      'D',
                                                      Bkcredit.No_Credito,
                                                      V_Cuenta_Contable,
                                                      V_Mensaje_Error);
                                                      */
            --MALMANZAR

            v_cuenta_contable :=
                PR.f_busca_cuenta_cartera (Bkcredit.Codigo_Empresa, --malmanzar 23-04-2020
                                           bkcredit.no_credito,
                                           'CAPITAL');

            IF v_cuenta_contable IS NULL
            THEN
                RAISE conta;
            END IF;

            ---Dbms_Output.Put_Line('Solbcc 004 .Cta Contable Princ: '||V_Cuenta_Contable||'  Errr: '||V_Mensaje_Error);

            /*IF V_Mensaje_Error IS NOT NULL
            THEN
                P_Mensaje_Error := V_Mensaje_Error;
                RAISE Conta;
            END IF;*/

            Pr_Procs.Convierte_Monto_Credcta (P_Empresa,
                                              Bkdesem.Monto_Desembolso,
                                              Bkcredit.Codigo_Moneda,
                                              V_Cuenta_Contable,
                                              P_Fecha,
                                              V_Monto_Linea_Asiento,
                                              V_Mensaje_Error);

            ----Dbms_Output.Put_Line('Solbcc 005 .V_Monto_Linea_Asiento: '||To_Char(V_Monto_Linea_Asiento,'9999999990.00'));

            IF V_Mensaje_Error IS NOT NULL
            THEN
                Pcoderror := V_Mensaje_Error;
                P_Mensaje_Error := 'Convierte_Monto_Credcta';
                RAISE Conta;
            END IF;

            ----Dbms_Output.Put_Line('Solbcc 005.1. Linea Asiento. Numasto: '||To_Char(V_Numero_Asiento)||' Mto: '||To_Char(V_Monto_Linea_Asiento,'9999990.00'));
            BEGIN
                Cg_Utl.Lineas_Del_Asiento (P_Empresa,
                                           P_Agencia,
                                           P_Aplicacion,
                                           P_Subaplicacion,
                                           P_Transaccion,
                                           P_Subtransa,
                                           P_Documento,
                                           V_Descripcion,
                                           P_Fecha,             /*Movimiento*/
                                           P_Fecha,                  /*Valor*/
                                           P_Fecha,                /*Asiento*/
                                           V_Numero_Asiento,
                                           RTRIM (V_Cuenta_Contable),
                                           Bkcredit.Codigo_Agencia, /*Auxiliar*/
                                           V_Monto_Linea_Asiento,
                                           'N',              /*Acumula Monto*/
                                           'D',                     /*Debito*/
                                           'N',                /*Modificable*/
                                           P_Tc1,       /*Tipo Cambio Origen*/
                                           P_Tc2,       /*Tipo Cambio Origen*/
                                           USER,
                                           V_Mensaje_Error2);
            EXCEPTION
                WHEN OTHERS
                THEN
                    V_Mensaje_Error2 :=
                        'Err En Lineas_Del_Asiento ' || SQLERRM;
            END;

            ---Dbms_Output.Put_Line('Solbcc 006 '||V_Mensaje_Error2);

            IF V_Mensaje_Error2 IS NOT NULL
            THEN
                P_Mensaje_Error := V_Mensaje_Error2;
                RAISE Conta;
            END IF;

            -- Busca Cuenta De Principal Cuenta Corriente

            IF Bkdesem.Numero_Cuenta IS NOT NULL AND P_Tipo_Desem = 'C'
            THEN
                SELECT Cod_Cliente
                  INTO V_Cod_Cliente_Desem
                  FROM Cuenta_Efectivo
                 WHERE     Num_Cuenta = TO_NUMBER (Bkdesem.Numero_Cuenta)
                       AND Cod_Empresa = P_Empresa;
            ELSE
                V_Cod_Cliente_Desem := Bkcredit.Codigo_Cliente;
            END IF;

            IF P_Tipo_Desem = 'C'
            THEN
                Cg_Utl.Cuenta_Contable_Sector (P_Empresa,
                                               'BCC',         /* Aplicacion */
                                               V_Subaplicacion,
                                               'PRINCIPAL',
                                               V_Cod_Cliente_Desem, -- Eblanco: 21-11-2011: Cod Cliente Due?O De La Cuenta Para Desembolso
                                               V_Cuenta_Contable,
                                               V_Mensaje_Error);
            ELSE
                V_Cuenta_Contable := P_CUENTA;
            END IF;

            ---Dbms_Output.Put_Line('Solbcc 008. Cta Contable Sector: '|| V_Cuenta_Contable);

            IF V_Mensaje_Error IS NOT NULL
            THEN
                Pcoderror := V_Mensaje_Error;
                P_Mensaje_Error := V_Mensaje_Error;
                RAISE Conta;
            END IF;

            Pr_Procs.Convierte_Monto_Credcta (P_Empresa,
                                              Bkdesem.Total_Desembolso,
                                              Bkcredit.Codigo_Moneda,
                                              V_Cuenta_Contable,
                                              P_Fecha,
                                              V_Monto_Linea_Asiento,
                                              V_Mensaje_Error);

            ---Dbms_Output.Put_Line('Solbcc 009 .V_Monto_Linea_Asiento: '||V_Monto_Linea_Asiento);
            IF V_Mensaje_Error IS NOT NULL
            THEN
                Pcoderror := V_Mensaje_Error;
                P_Mensaje_Error := V_Mensaje_Error;
                RAISE Conta;
            END IF;

            ---Dbms_Output.Put_Line('Solbcc 009 . Lineaasto: '|| V_Numero_Asiento);
            BEGIN
                Cg_Utl.Lineas_Del_Asiento (P_Empresa,
                                           P_Agencia,
                                           P_Aplicacion,
                                           P_Subaplicacion,
                                           P_Transaccion,
                                           P_Subtransa,
                                           P_Documento,
                                           V_Descripcion,
                                           P_Fecha,             /*Movimiento*/
                                           P_Fecha,                  /*Valor*/
                                           P_Fecha,                /*Asiento*/
                                           V_Numero_Asiento,
                                           RTRIM (V_Cuenta_Contable),
                                           V_Agenciadecta,        /*Auxiliar*/
                                           V_Monto_Linea_Asiento,
                                           'N',              /*Acumula Monto*/
                                           'C',                    /*Credito*/
                                           'N',                /*Modificable*/
                                           P_Tc1,       /*Tipo Cambio Origen*/
                                           P_Tc2,       /*Tipo Cambio Origen*/
                                           USER,
                                           V_Mensaje_Error2);
            EXCEPTION
                WHEN OTHERS
                THEN
                    V_Mensaje_Error2 :=
                        'Err En Lineas_Del_Asiento ' || SQLERRM;
            END;

            ---Dbms_Output.Put_Line('Solbcc 010 '||V_Mensaje_Error2);

            IF V_Mensaje_Error2 IS NOT NULL
            THEN
                P_Mensaje_Error := V_Mensaje_Error2;
                RAISE Conta;
            END IF;
        END IF;                                              -- If P_Bcg = 'S'

        --
        -- Generacion, Cobro Y Contabilizacion De Cargos
        ---Dbms_Output.Put_Line('Solbcc 011 Antes Cargos 3 '||V_Mensaje_Error);

        Generar_Cargos_3 (P_Empresa,
                          P_Agencia,
                          Bkcredit.No_Credito,
                          3,
                          P_Fecha_Movimiento,
                          Bkdesem.Monto_Desembolso,
                          USER,
                          P_Subaplicacion,
                          0,
                          P_Documento,
                          P_Aplicacion,
                          V_Descripcion,
                          Bkcredit.Tipo_Credito,
                          P_Fecha,
                          Pbcg,
                          V_Numero_Asiento,
                          V_Mensaje_Error);

        --Dbms_Output.Put_Line('Desp Gene Cargos3 '||V_Mensaje_Error);
        IF (V_Mensaje_Error IS NOT NULL)
        THEN
            Pcoderror := V_Mensaje_Error;
            P_Mensaje_Error := V_Mensaje_Error;
            RAISE General;
        END IF;

        /*Dbms_Output.Put_Line('Solbcc 012, Tipo Comision '||  Bkcredit.Tipo_Comision||
        ' Cobrar Comis '||Bkdesem.Cobrar_Comision||' Mto Comis '||Nvl(Bkdesem.Monto_Comision ,0));*/
        --
        IF (Bkcredit.Tipo_Comision = 'A')
        THEN
            -- Comision Anticipada
            IF (    NVL (Bkdesem.Cobrar_Comision, 'N') = 'N'
                AND Bkdesem.Monto_Comision > 0)
            THEN
                -- Si No Se Cobra En El Desembolso Se Genera Un Cargo
                Pr_Procs.Asigna_Transaccion (V_No_Documento,
                                             P_Cierre.Ccodidioma);

                BEGIN
                    SELECT Cargo_Comision
                      INTO V_Cargo
                      FROM Pr_Tipo_Credito
                     WHERE     Codigo_Empresa = P_Empresa
                           AND Tipo_Credito = Bkcredit.Tipo_Credito;

                    IF (V_Cargo IS NULL)
                    THEN
                        -- El Credito No Tiene Cargo Para Comision
                        V_Mensaje_Error := '000572';
                        P_Mensaje_Error := V_Mensaje_Error;
                        RAISE General;
                    END IF;

                    V_Valor1_Anterior :=
                           '|'
                        || TO_CHAR (Bkcredit.F_Ultimo_Pago_Comision,
                                    'DD/MM/YYYYY')
                        || '|';
                    V_Valor1_Actual :=
                           '|'
                        || TO_CHAR (Bkcredit.F_Comision_Hasta, 'DD/MM/YYYYY')
                        || '|';
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        -- El Tipo De Credito No Existe
                        V_Mensaje_Error := '000456';
                        P_Mensaje_Error := V_Mensaje_Error;
                        RAISE General;
                    WHEN TOO_MANY_ROWS
                    THEN
                        -- El Tipo De Credito Esta Duplicado
                        V_Mensaje_Error := '000377';
                        P_Mensaje_Error := V_Mensaje_Error;
                        RAISE General;
                /*  When Others Then
                       V_Mensaje_Error:='000032';
                       P_Mensaje_Error := V_Mensaje_Error;
                       Raise General;*/
                END;

                ----Dbms_Output.Put_Line('Solbcc 013 Genera Mov Credito');

                Pr_Procs.Genera_Movimiento_Credito (
                    -- Empresa, Agencia, No Credito, Tipo Transaccion,
                    P_Empresa,
                    P_Agencia,
                    Bkcredit.No_Credito,
                    2,
                    -- Fecha Mov., Monto Mov., No Documento, Tipo Pago,
                    P_Fecha_Movimiento,
                    Bkdesem.Monto_Comision,
                    V_No_Documento,
                    NULL,
                    -- No Cuenta, No Transaccion,
                    NULL,
                    TO_CHAR (Bkcredit.Numero_Transaccion),
                    -- Montos: Cargos, Principal, Interes, Mora, Comision, Poliza,
                    Bkdesem.Monto_Comision,
                    0,
                    0,
                    0,
                    0,
                    0,
                    -- No Cuota, No Asiento, Dias Mora, Dias Interes, Estado,
                    NULL,
                    V_Numero_Asiento,
                    0,
                    0,
                    'P',
                    -- Observaciones: 1, 2, 3 Y 4, Firma Legal, Juzgado
                    -- Et_Observaciones1: Cargo Manual: Por Comision Anticipada No Cobrada En Desembolso
                    Et_Observaciones,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    -- Plazo Anterior, Nivel Aprob., F. Aplic., Pago Menor,
                    NULL,
                    NULL,
                    P_Fecha_Movimiento,
                    NULL,
                    -- Usuario, Cod. Cargo, F. Pago
                    USER,
                    V_Cargo,
                    NULL,
                    -- Valor Ant1, Valor Ant2, Valor Act1, Valor Act2
                    V_Valor1_Anterior,
                    NULL,
                    V_Valor1_Actual,
                    NULL,
                    -- Valor Act1, Valor Act2, F Aplicado
                    P_Fecha_Movimiento,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    P_Cierre.Ccodidioma,
                    V_Resultado,
                    V_Mensaje_Error);
            ---Dbms_Output.Put_Line('Solbcc 014  '||        V_Mensaje_Error);

            ELSIF (    Bkdesem.Cobrar_Comision = 'S'
                   AND Bkdesem.Monto_Comision > 0)
            THEN
                ---Dbms_Output.Put_Line('Solbcc 014.2. Cobra Comision = S Y Mto Comis > 0');
                Pr_Procs.Cuenta_Contable_Bpr (Bkcredit.Codigo_Empresa,
                                              Bkcredit.Tipo_Credito,
                                              'D',
                                              'COMISION',
                                              '0',
                                              V_Cuenta_Contable,
                                              V_Mensaje_Error);

                IF V_Mensaje_Error IS NOT NULL
                THEN
                    P_Mensaje_Error := V_Mensaje_Error;
                    RAISE Conta;
                END IF;

                Pr_Procs.Convierte_Monto_Credcta (P_Empresa,
                                                  Bkdesem.Monto_Comision,
                                                  Bkcredit.Codigo_Moneda,
                                                  V_Cuenta_Contable,
                                                  P_Fecha,
                                                  V_Monto_Linea_Asiento,
                                                  V_Mensaje_Error);

                IF V_Mensaje_Error IS NOT NULL
                THEN
                    P_Mensaje_Error := V_Mensaje_Error;
                    RAISE Conta;
                END IF;

                ---Dbms_Output.Put_Line('Solbcc 015. Inserta Linea Del Asiento');
                BEGIN
                    Cg_Utl.Lineas_Del_Asiento (P_Empresa,
                                               P_Agencia,
                                               P_Aplicacion,
                                               P_Subaplicacion,
                                               P_Transaccion, -- Emision De Cheque
                                               P_Subtransa,  -- Subtransaccion
                                               P_Documento,
                                               V_Descripcion,
                                               P_Fecha,          -- Movimiento
                                               P_Fecha,               -- Valor
                                               P_Fecha,             -- Asiento
                                               V_Numero_Asiento,
                                               RTRIM (V_Cuenta_Contable),
                                               Bkcredit.Codigo_Agencia, -- Auxiliar
                                               V_Monto_Linea_Asiento,
                                               'N',           -- Acumula Monto
                                               'C',                 -- Credito
                                               'N',             -- Modificable
                                               P_Tc1,    -- Tipo Cambio Origen
                                               P_Tc2,    -- Tipo Cambio Origen
                                               USER,
                                               V_Mensaje_Error2);
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        V_Mensaje_Error2 :=
                            'Err En Lineas_Del_Asiento ' || SQLERRM;
                END;

                IF V_Mensaje_Error2 IS NOT NULL
                THEN
                    P_Mensaje_Error := V_Mensaje_Error2;
                    RAISE Conta;
                END IF;
            END IF;                                           -- Se Cobra O No
        ELSIF (Bkcredit.Tipo_Comision = 'V')
        THEN
            ----Dbms_Output.Put_Line('Tipo Comision = V');
            IF (    (Bkcredit.Es_Linea_Credito = 'S')
                AND (Bkcredit.F_Primer_Desembolso IS NULL))
            THEN
                -- Si No Se Cobra En El Desembolso Se Genera Un Cargo
                ---Dbms_Output.Put_Line('Antes De Select Cargo_Comision');
                BEGIN
                    SELECT Cargo_Comision
                      INTO V_Cargo
                      FROM Pr_Tipo_Credito
                     WHERE     Codigo_Empresa = P_Empresa
                           AND Tipo_Credito = Bkcredit.Tipo_Credito;

                    IF (V_Cargo IS NULL)
                    THEN
                        -- El Credito No Tiene Cargo Para Comision
                        V_Mensaje_Error := '000572';
                        P_Mensaje_Error := V_Mensaje_Error;
                        RAISE General;
                    END IF;

                    V_Valor1_Actual := '|' || TO_CHAR (P_Transaccion) || '|';
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        -- El Tipo De Credito No Existe
                        V_Mensaje_Error := '000456';
                        Pcoderror := V_Mensaje_Error;
                        RAISE General;
                    WHEN TOO_MANY_ROWS
                    THEN
                        -- El Tipo De Credito Esta Duplicado
                        V_Mensaje_Error := '000377';
                        Pcoderror := V_Mensaje_Error;
                        RAISE General;
                    WHEN General
                    THEN
                        RAISE General;
                /* When Others Then
                     V_Mensaje_Error:='000032';
                     Pcoderror := V_Mensaje_Error;
                     Raise General;*/
                END;

                ---Dbms_Output.Put_Line('Ins Pr-Cargos-X-Cre');
                INSERT INTO Pr_Cargos_X_Credito (Codigo_Empresa,
                                                 No_Credito,
                                                 Codigo_Cargo,
                                                 Codigo_Tipo_Transaccion,
                                                 Tipo_Cargo,
                                                 Monto_Cargo,
                                                 Monto_Minimo,
                                                 Monto_Maximo,
                                                 Tipo_Cobro,
                                                 Codigo_Periodo,
                                                 Adicionado_Por,
                                                 Fecha_Adicion)
                     VALUES (P_Empresa,
                             Bkcredit.No_Credito,
                             V_Cargo,
                             1,
                             'P',
                             Bkcredit.Comision_Normal,
                             1,
                             1000000000,
                             'V',
                             Bkcredit.Codigo_Periodo_Cuota,
                             USER,
                             SYSDATE);
            END IF;                                       -- Lineas De Credito
        END IF;                                         -- Comision Anticipada


        -- Cobro Y Contabilizacion De Poliza

        ----Dbms_Output.Put_Line('Bkdesem.Cobrar_Poliza  '||Bkdesem.Cobrar_Poliza ||'  Bkdesem.Monto_Poliza  '||To_Char(Bkdesem.Monto_Poliza ));
        IF (Bkdesem.Cobrar_Poliza = 'N' AND Bkdesem.Monto_Poliza > 0)
        THEN
            -- Si No Se Cobra En El Desembolso Y Si Hay Polizas Por Cobrar,
            -- Se Generan Los Movimientos En Estado 'A'
            V_Estado := 'A';
        ELSIF (    Bkdesem.Cobrar_Poliza = 'S'
               AND Bkdesem.Monto_Poliza > 0
               AND Pbcg = 'S')
        THEN
            -- Si Si Se Cobra Del Desembolso, Si Hay Polizas Y Si Hay
            -- Contabilidad, Se Generan Los Movimientos En Estado 'P'
            -- Y Se Contabiliza A Continuacion
            V_Estado := 'P';
            Pr_Procs.Cuenta_Contable_Bpr (Bkcredit.Codigo_Empresa,
                                          Bkcredit.Tipo_Credito,
                                          'D',
                                          'Poliza',
                                          '0',
                                          V_Cuenta_Contable,
                                          V_Mensaje_Error);

            IF V_Mensaje_Error IS NOT NULL
            THEN
                P_Mensaje_Error := V_Mensaje_Error;
                RAISE Conta;
            END IF;

            Pr_Procs.Convierte_Monto_Credcta (P_Empresa,
                                              Bkdesem.Monto_Poliza,
                                              Bkcredit.Codigo_Moneda,
                                              V_Cuenta_Contable,
                                              P_Fecha,
                                              V_Monto_Linea_Asiento,
                                              V_Mensaje_Error);

            IF V_Mensaje_Error IS NOT NULL
            THEN
                P_Mensaje_Error := V_Mensaje_Error;
                RAISE Conta;
            END IF;

            ----Dbms_Output.Put_Line('Solbcc 016.Inserta Linea Del Asiento Poliza');

            BEGIN
                Cg_Utl.Lineas_Del_Asiento (P_Empresa,
                                           P_Agencia,
                                           P_Aplicacion,
                                           P_Subaplicacion,
                                           P_Transaccion, -- Emision De Cheque
                                           P_Subtransa,      -- Subtransaccion
                                           P_Documento,
                                           V_Descripcion,
                                           P_Fecha,              -- Movimiento
                                           P_Fecha,                   -- Valor
                                           P_Fecha,                 -- Asiento
                                           V_Numero_Asiento,
                                           RTRIM (V_Cuenta_Contable),
                                           Bkcredit.Codigo_Agencia, -- Auxiliar
                                           V_Monto_Linea_Asiento,
                                           'N',               -- Acumula Monto
                                           'C',                     -- Credito
                                           'N',                 -- Modificable
                                           P_Tc1,        -- Tipo Cambio Origen
                                           P_Tc2,        -- Tipo Cambio Origen
                                           USER,
                                           V_Mensaje_Error2);
            EXCEPTION
                WHEN OTHERS
                THEN
                    V_Mensaje_Error2 :=
                        'Err En Lineas_Del_Asiento ' || SQLERRM;
            END;

            IF V_Mensaje_Error2 IS NOT NULL
            THEN
                P_Mensaje_Error := V_Mensaje_Error2;
                RAISE Conta;
            END IF;
        ELSIF (    Bkdesem.Cobrar_Poliza = 'S'
               AND Bkdesem.Monto_Poliza > 0
               AND Pbcg = 'N')
        THEN
            -- Si Si Se Cobra Del Desembolso, Si Hay Polizas Y No Hay
            -- Contabilidad, Se Hace Todo Esto
            V_Estado := 'P';
        END IF;                                               -- Se Cobra O No

        -- Genera Los Movimientos Con El Estado Correcto

        FOR P IN Polizas (P_Empresa, Bkcredit.No_Credito)
        LOOP
            ---Dbms_Output.Put_Line('Ingeso Loop Polizas');
            -- Periodicidad De La Poliza
            IF P.Tipo_Cobro = 'A'
            THEN
                IF (P.Codigo_Periodo IS NULL)
                THEN
                    -- El Periodo De La Poliza Es Nulo
                    V_Mensaje_Error := '000576';
                    EXIT;
                ELSE
                    BEGIN
                        SELECT Dias_Periodo
                          INTO V_Dias_Poliza
                          FROM Pr_Periodicidad
                         WHERE Codigo_Periodo = P.Codigo_Periodo;

                        IF (V_Dias_Poliza IS NULL OR V_Dias_Poliza <= 0)
                        THEN
                            -- El Periodo De La Poliza Es Nulo
                            V_Mensaje_Error := '000576';
                            EXIT;
                        END IF;
                    EXCEPTION
                        WHEN NO_DATA_FOUND
                        THEN
                            -- El Periodo De La Poliza No Fue Encontrado
                            V_Mensaje_Error := '000577';
                            EXIT;
                        WHEN TOO_MANY_ROWS
                        THEN
                            -- El Periodo De La Poliza Esta Duplicado
                            V_Mensaje_Error := '000578';
                            EXIT;
                    /*   When Others Then
                            V_Mensaje_Error:='000032';
                            Exit;*/
                    END;
                END IF;

                -- Calcula La Fecha De Proxima Generacion Y Setea
                -- Valor1_Actual Y Valor1_Anterior
                Pr_Procs.Agregar_Dias (P_Fecha_Movimiento,
                                       V_Dias_Poliza,
                                       360,
                                       V_F_Prox_Poliza,
                                       V_Mensaje_Error);

                IF (V_Mensaje_Error IS NOT NULL)
                THEN
                    EXIT;
                END IF;

                V_Valor1_Anterior :=
                       '|'
                    || TO_CHAR (P_Fecha_Movimiento, 'Dd/Mm/Yyyy')
                    || '|'
                    || TO_CHAR (P.F_Ultima_Generacion, 'Dd/Mm/Yyyy')
                    || '|';
                V_Valor1_Actual :=
                    '|' || TO_CHAR (V_F_Prox_Poliza, 'Dd/Mm/Yyyy') || '|';
                Bkcredit.F_Poliza_Desde := P_Fecha_Movimiento;
                Bkcredit.F_Poliza_Hasta := V_F_Prox_Poliza;
                -- Genera El Movimiento De Poliza
                Pr_Procs.Asigna_Transaccion (V_No_Documento,
                                             P_Cierre.Ccodidioma);

                ---Dbms_Output.Put_Line('Solbcc 017. Genera_Mov_Credito');

                Pr_Procs.Genera_Movimiento_Credito (
                    -- Empresa, Agencia, No Credito, Tipo Transaccion,
                    P_Empresa,
                    P_Agencia,
                    Bkcredit.No_Credito,
                    32,
                    -- Fecha Mov., Monto Mov., No Documento, Tipo Pago,
                    P_Fecha_Movimiento,
                    P.Monto_A_Pagar,
                    V_No_Documento,
                    NULL,
                    --  No Cuenta, No Transaccion,
                    NULL,
                    TO_CHAR (Bkcredit.Numero_Transaccion),
                    -- Montos: Cargos, Principal, Interes, Mora, Comision, Poliza,
                    0,
                    0,
                    0,
                    0,
                    0,
                    P.Monto_A_Pagar,
                    -- No Cuota, No Asiento, Dias Mora, Dias Interes, Estado,
                    NULL,
                    V_Numero_Asiento,
                    0,
                    0,
                    V_Estado,
                    -- Observaciones: 1, 2, 3 Y 4, Firma Legal, Juzgado
                    Et_Descripcion3,                      -- Poliza Anticipada
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    -- Plazo Anterior, Nivel Aprob., F. Aplic., Pago Menor,
                    NULL,
                    NULL,
                    P_Fecha_Movimiento,
                    NULL,
                    -- Usuario, Cod. Cargo, F. Pago, Valor Ant1, Valor Ant2,
                    USER,
                    NULL,
                    NULL,
                    V_Valor1_Anterior,
                    NULL,
                    -- Valor Act1, Valor Act2, F Aplicado,
                    V_Valor1_Actual,
                    NULL,
                    P_Fecha_Movimiento,
                    -- Dias Principal, Dias Comision
                    0,
                    0,
                    -- Tipo Poliza, Numero Poliza, Resultado
                    P.Tipo_Poliza,
                    P.Numero_Poliza,
                    P_Cierre.Ccodidioma,
                    V_Resultado,
                    V_Mensaje_Error);

                IF (NOT V_Resultado)
                THEN
                    -- Se Presentaron Problemas Generando Los Movimientos
                    V_Mensaje_Error := '000577';
                    EXIT;
                END IF;
            END IF;

            ---Dbms_Output.Put_Line('Update Pr_Polizas_X_Credito');
            UPDATE Pr_Polizas_X_Credito
               SET F_Ultima_Generacion = NULL -- Rmartinez 28/09/2007 Bkdesem.Fecha_Desembolso
             WHERE     Codigo_Empresa = P_Empresa
                   AND No_Credito = Bkcredit.No_Credito
                   AND Tipo_Poliza = P.Tipo_Poliza
                   AND Numero_Poliza = P.Numero_Poliza;
        END LOOP;

        IF (V_Mensaje_Error IS NOT NULL)
        THEN
            P_Mensaje_Error := V_Mensaje_Error;
            RAISE General;
        END IF;

        -- Et_Descripcion4: Desembolso Del Credito
        V_Descripcion :=
            Et_Descripcion4 || ' ' || TO_CHAR (Bkcredit.No_Credito);

        --
        IF P_Tipo_Desem = 'C'
        THEN                               ---Desembolso a cuenta realacionada
            ---Dbms_Output.Put_Line('Antes Ccmov.Agregamov');
            CC_MOV_IVR.pSistemaFuenteVar := 'BPR'; ---malmanzar 02-07-2020 Req. 112496

            Ccmov.Agrega_Movimiento (TO_CHAR (P_Empresa),
                                     TO_CHAR (P_Agencia),
                                     'CC',
                                     TO_NUMBER (P_Cuenta),
                                     TO_CHAR (V_Subaplicacion),
                                     58,
                                     V_Sub_Trans,
                                     USER,
                                     P_Fecha,
                                     TO_NUMBER (P_Documento),
                                     Bkdesem.Total_Desembolso,
                                     V_Descripcion,
                                     'BPR',
                                     NULL,
                                     'N',
                                     V_Num_Mov);

            ----Dbms_Output.Put_Line('Num Mov: '||To_Char(V_Num_Mov));

            IF V_Num_Mov <> 0
            THEN
                Ccmov.Aplica_Movimiento (V_Num_Mov,
                                         NULL,
                                         NULL,
                                         NULL,
                                         NULL,
                                         NULL,
                                         V_Numero,
                                         V_Errapli,
                                         V_Error,
                                         NULL);

                ----Dbms_Output.Put_Line('Aplica Mov Ccmov'||   V_Error);

                IF V_Error <> '000005'
                THEN
                    Pcoderror := V_Error;
                    RAISE Bcc;
                ELSE
                    UPDATE Movimto_Diario
                       SET Estado_Movimto = 'C'
                     WHERE Num_Movto_D = V_Num_Mov;
                END IF;
            END IF;

            P_No_Movimiento := TO_CHAR (V_Num_Mov);

            --           --Congela o no los fondos desembolsados según parámetro  2020-04-17
            lc_congela :=
                param.parametro_general ('CONG_AUTO_DESEMBOLSO', 'PR');


            --Malmanzar se Excluye monto punto15 del monto a ser congelado


            --malmanzar 14-02-2023 Begin
            --Fin de la busquedad
            nMontoCanSaldo := 0;

            FOR C1
                IN (SELECT *
                      FROM PR_CANCELACION_CREDITOS
                     WHERE     Codigo_Empresa = Bkcredit.Codigo_Empresa --pCodigo_Empresa
                           AND No_Credito = Bkcredit.No_Credito
                           AND EXISTS
                                   (SELECT 1
                                      FROM pr_creditos pr
                                     WHERE     pr.Codigo_Empresa =
                                               Bkcredit.Codigo_Empresa --pCodigo_Empresa
                                           AND pr.No_Credito =
                                               NO_CREDITO_CANCELADO
                                           AND pr.estado IN ('D',
                                                             'V',
                                                             'M',
                                                             'E',
                                                             'J')))
            LOOP
                --pr_pagos_prestamos.obtieneMontoCancelacionTotal
                nMontoCanSaldo :=
                      NVL (nMontoCanSaldo, 0)
                    + NVL (
                          pr_pagos_prestamos.F_SALDO_TOTAL_OPERACIONES (
                              p_empresa      => Bkcredit.codigo_empresa, -- Codigo de la Empresa.
                              p_no_credito   => C1.no_credito_Cancelado, -- Numero de Credito.
                              p_fecha        => P_Fecha_Movimiento --pFecha_Desembolso -- Fecha de Aplicacion.
                                                                  ),
                          0);
            END LOOP;

            IF NVL (nMontoCanSaldo, 0) > 0
            THEN
                -- If NVL (bkdesem.Monto_Cancelacion, 0) > 0 Then
                --malmanzar 14-02-2023 End
                BEGIN
                    vMontoPunto15 :=
                        PR_PKG_DESEMBOLSO.f_punto15_Cancelacion (
                            p_empresa,
                            Bkcredit.No_Credito,
                            p_fecha);
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        vMontoPunto15 := 0;
                END;
            ELSE
                vMontoPunto15 := 0;
            END IF;


            IF NVL (lc_congela, 'N') = 'S'
            THEN
                BEGIN
                    --- Excello:JPH:2020-07-17:REQ._112142:Begin >>
                    --==================================================== --
                    /* Se cambia la generacion del congelameinto directo
                       por la creacion del movimiento de cong  para que
                       se vea  el  registro del mismo en  los movimiejntos
                       del cleinte y evitar los errores de que no se cea
                       en ocaciones
                    */
                    --==================================================== --

                    Ccmov.Agrega_Movimiento (
                        TO_CHAR (P_Empresa),
                        TO_CHAR (P_Agencia),
                        'CC',
                        TO_NUMBER (P_Cuenta),
                        TO_CHAR (V_Subaplicacion),
                        95,
                        5,
                        USER,
                        P_Fecha,
                        TO_NUMBER (P_Documento),
                          Bkdesem.Total_Desembolso
                        /*- (NVL (bkdesem.Monto_Cancelacion, 0) + nvl(vMontoPunto15,0)),*/
                        --malmanzar 14-02-2023
                        - (NVL (nMontoCanSaldo, 0) + NVL (vMontoPunto15, 0)), --malmanzar 14-02-2023
                        'DESEMBOLSO DE CREDITO',
                        'BPR',
                        NULL,
                        'N',
                        V_Num_Mov_Cng);

                    IF NVL (V_Num_Mov_Cng, 0) > 0
                    THEN
                        Ccmov.Aplica_Movimiento (V_Num_Mov_Cng,
                                                 NULL,
                                                 NULL,
                                                 NULL,
                                                 NULL,
                                                 NULL,
                                                 Ln_Secuencia,
                                                 V_Errapli,
                                                 V_Error,
                                                 NULL);

                        IF v_error <> '000005'
                        THEN
                            DBMS_OUTPUT.PUT_LINE ('v_error ' || v_error);
                            --utilitarios.mensaje( v_error, variables.codidioma, 'CC' );
                            Pcoderror := V_Error;
                            RAISE bcc;
                        END IF;
                    END IF;
                /*cc_mov_ivr.aplica_cong (
                        95,
                        5,
                        p_fecha,
                        TO_CHAR (p_empresa),
                        TO_NUMBER (p_cuenta),
                        TO_CHAR (p_agencia),
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        ln_secuencia,
                          Bkdesem.Total_Desembolso
                        - (NVL (bkdesem.Monto_Cancelacion, 0) + nvl(vMontoPunto15,0)), --NVL(V_Monto_Cancelacion,0),--MALMANZAR 18-04-2020--:BKDesem.Monto_CC,
                        'DESEMBOLSO DE CREDITO',
                        USER,
                        NULL,
                        NULL,
                        v_error,
                        'N');

                    IF v_error <> '000005'
                    THEN
                        DBMS_OUTPUT.PUT_LINE ('v_error ' || v_error);
                        --utilitarios.mensaje( v_error, variables.codidioma, 'CC' );
                        Pcoderror := V_Error;
                        RAISE bcc;
                    END IF;
                   */
                --==================================================== --
                -- Excello:JPH:2020-07-17:REQ._112142: End <<

                END;
            END IF;
        ---


        END IF;       --Desembolso a cuenta relacionada --malmanzar 2020-04-16



        --
        --Pago del Recredito  malmanzar 17-04-2020
        IF P_Tipo_Desem = 'C'
        THEN
            v_mensaje_error :=
                cancelacion_recredito (P_Empresa,
                                       Bkcredit.No_Credito,
                                       P_Fecha,
                                       P_Cuenta,
                                       p_Agencia,
                                       v_numero_asiento,
                                       -- V_Monto_Cancelacion,
                                       TO_CHAR (Bkcredit.Numero_Transaccion) --To_Number(P_Documento)  -- Excello:JPH:2019-11-13:REQ_83180: Nuevo Parametro
                                                                            );

            DBMS_OUTPUT.put_line (
                   'v_mensaje_error '
                || v_mensaje_error
                || ' Linea '
                || $$plsql_line);

            IF v_mensaje_error IS NOT NULL
            THEN
                ROLLBACK;
                P_Mensaje_Error := v_mensaje_error;
                Pcoderror := v_mensaje_error;
                RAISE conta;
            END IF;
        END IF;


        ---

        CC_MOV_IVR.pSistemaFuenteVar := NULL;

        --

        IF PBCG = 'S'
        THEN
            -- Determina si se requere asiento de contingencia para la transaccion ---
            IF Pr_Pagos_Utl.F_Afecta_Contingencia (P_Empresa,
                                                   Bkcredit.No_Credito,
                                                   P_Transaccion) =
               'S'
            THEN                                        --Malmanzar 01-06-2018
                Pr_Pagos_Utl.P_Asiento_Contingencia (
                    P_Empresa          => P_Empresa,
                    P_Agencia          => P_Agencia,
                    P_No_Credito       => Bkcredit.No_Credito,
                    Psub_Aplicacion    => P_Subaplicacion,
                    P_Usuario          => USER,
                    P_Idioma           => 'ESPA',
                    Pfechasist         => P_Fecha,
                    Ptransaccion       => P_Transaccion,
                    Pmonto             => Bkdesem.Monto_Desembolso,
                    Pmoneda            => Bkcredit.Codigo_Moneda,
                    Ptipo_Movimiento   => 'C',
                    Pnumero_Asiento    => V_Numero_Asiento,
                    P_Mensaje          => V_Mensaje_Error2);
            END IF;

            --Bkdesem.Monto_Cancelacion := 0; malmanzar 14-02-2023 req. 3709,  --03-09-2020

            -- Et_Etiq2: Diferencias Por Conversion De Monedas
            ---Dbms_Output.Put_Line('Cuadre Asiento');
            /*Cuadre_Asiento_Centimo_Pr (P_Empresa,
                                       P_Agencia,
                                       P_Cierre.Ccodidioma,
                                       P_Subaplicacion,
                                       P_Documento,
                                       P_Transaccion,
                                       P_Agencia,
                                       P_Fecha,
                                       V_Numero_Asiento,
                                       V_Diferencia,
                                       USER,
                                       Et_Etiq2,
                                       V_Mensaje_Error);*/
            ---malmanzar 02-02-2022

            cg_utl.cuadre_asiento (P_Empresa,
                                   P_Fecha,
                                   V_Numero_Asiento,
                                   V_Diferencia,
                                   V_Mensaje_Error); ---malmanzar02-02-2022 se cambia cuadre asiento centimo por cuadre_asiento esto es para evitar error desembolso prestamos US$ con cargo.


            IF V_Mensaje_Error IS NOT NULL
            THEN
                P_Mensaje_Error := V_Mensaje_Error;
                RAISE Conta;
            END IF;
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            -- No Se Encontro El Codigo De Producto De Cuenta
            --Utilitarios.Mensaje('000584', Pcodidioma, 'Pr');
            Pcoderror := '000584';
            ROLLBACK;
            raise_application_error (
                -20000,
                   SQLERRM
                || ' -> traza: '
                || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
            RETURN;
        WHEN Bcc
        THEN
            -- Se Presentaron Problemas Con La Nota De Credito
            --Utilitarios.Mensaje('000585', Pcodidioma, 'Pr');
            Pcoderror := '000585';
            ROLLBACK;
            raise_application_error (
                -20000,
                   SQLERRM
                || ' -> traza: '
                || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
            RETURN;
        WHEN Conta
        THEN
            ROLLBACK;
            RETURN;
        WHEN Cargo
        THEN
            -- Problemas Generando Cargos
            Pcoderror := '000025';
            ROLLBACK;
            RETURN;
        WHEN General
        THEN
            -- Es Imposible Generar El Desembolso
            Pcoderror := '000575';

            ROLLBACK;
            raise_application_error (
                -20000,
                   SQLERRM
                || ' -> traza: '
                || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
            RETURN;
    /*   When Others Then
           -- Utilitarios.Mensaje_Error('000032', Pcodidioma, 'Pr', Sqlcode);
           Pcoderror := '000032';
           Rollback;
           Return;*/
    END;


    PROCEDURE Genera_Desembolso (
        P_Cod_Empresa       IN     NUMBER,
        P_No_Credito        IN     NUMBER,
        P_Codigo_Agencia    IN     NUMBER,                  ---Agencia proceso
        P_Monto_Desemb      IN     NUMBER,
        P_MONTO_COMISION    IN     NUMBER,
        pMontoCancelacion   IN     NUMBER,
        P_Tipo_Desemb       IN     VARCHAR2,
        P_CUENTA            IN     VARCHAR2,
        P_Mensaje              OUT VARCHAR2,
        P_Nummov_Desemb        OUT VARCHAR2,
        P_Hacer_Commit      IN     VARCHAR2 DEFAULT 'N')
    IS
        CURSOR C_credito IS
            SELECT *
              FROM Pr_Creditos
             WHERE     Codigo_Empresa = P_Cod_Empresa
                   AND No_Credito = P_No_Credito;

        -- Variables ---
        --- V_Descripcion          Varchar2(250);
        V_Mensaje_Error           VARCHAR2 (500);
        V_Mensaje_Error1          VARCHAR2 (500);
        V_Numero_Asiento          NUMBER (10);
        --  V_Numero_Cuenta        Varchar2(30);
        V_Autorizacion            NUMBER (10);
        V_Documento_Movim         VARCHAR2 (250);
        --V_Documento_Cuota      Varchar2(250);
        V_Tipo_Pago_Cargos        VARCHAR2 (1);
        --  V_Documento_Cargos     Varchar2(250);
        --  V_Cantidad_Cuotas      Number(10);
        V_Tc1                     NUMBER;
        V_Tc2                     NUMBER;
        V_Estado                  VARCHAR2 (1);
        V_Resultado               BOOLEAN;
        -- V_Resultado_Cc         Varchar2(80);
        V_F_Aplicado              DATE;
        V_Cuota_Base              NUMBER;
        V_Valor1_Actual           VARCHAR2 (250);
        V_Valor2_Actual           VARCHAR2 (250);
        --  V_Fecha_Prox_Pago      Date;
        V_Valor_Cuota_Ant         NUMBER (16, 2);

        --
        V_Principal               NUMBER (16, 2) := 0;
        V_Interes                 NUMBER (16, 2) := 0;
        V_Comision                NUMBER (16, 2) := 0;
        V_Poliza                  NUMBER (16, 2) := 0;
        V_Cargos                  NUMBER (16, 2) := 0;
        --
        --  V_Continua             Boolean;
        --  V_Archivo              Varchar2(250);
        --  V_Tipo_Desembolso      Varchar2(250);
        --  V_Dia_Pago_Tipo_Credito Varchar2(2);
        --  V_Sub_Transaccion      Varchar2(5);
        --   Excepciones --
        Salir                     EXCEPTION;
        Trabaja_Sabado            BOOLEAN;
        Trabaja_Domingo           BOOLEAN;

        --  Vdescerr              Varchar2(500)   := Null;
        --  Vcodeerr              Varchar2(10)    := Null;
        --  Vnumpolbco            Varchar2(20)    := Null;
        --  Vnumpolcred           Varchar2(20)    := Null;
        --  Vnumcot               Varchar2(20)    := Null;
        --  Vmontopol             Number(18,2)    := Null;
        --  Vcuotas               Number(18,2)    := Null;
        --  Vestado               Varchar2(1)     := Null;
        --  Vemail                Varchar2(100)   := Null;
        --  Vnombre_Sol           Varchar2(65)    := Null;
        --  Vcongarantcer         Varchar2(1)     := Null;
        --  Fpdesembolso          Date;
        --  Ctipocredito          Varchar2(10)    := Null;
        --  Nmonto_Credito        Number(16,2)    :=0;
        --  Nmontocansaldo        Number(16,2)    :=0;
        V_Mensaje                 VARCHAR2 (250) := NULL;
        --  Vcuota_N              Number          :=0;
        --  Ves_Linea_Credito      Pr_Creditos.Es_Linea_Credito%Type;
        --  Vmultiples_Desembolsos Pr_Tipo_Credito.Multiples_Desembolsos%Type;
        ---

        V_Existe_Cr               VARCHAR2 (1) := NULL;
        V_Idioma                  VARCHAR (10) := 'ESPA';
        V_Observaciones1          VARCHAR2 (250) := NULL;
        V_Observaciones2          VARCHAR2 (250) := NULL;
        -- V_Primer_Desembolso     Varchar2(1)   := Null;
        --  V_Es_Cuota_Multiple     Varchar2(1)   := Null;
        V_Ind_Cred_Univ           VARCHAR2 (1) := NULL;
        V_Oficial_Autorizado      VARCHAR2 (1) := NULL;
        V_Grupo_Tipo_Credito      VARCHAR2 (1) := NULL;
        V_Numero_Transaccion      NUMBER := 0;
        -- V_CodSub_Aplicacion     Number := 0;
        V_Saldo_Disponible        NUMBER := 0;
        V_Saldo_Actual            NUMBER := 0;
        V_Dias_Periodo_Cuota      NUMBER := 0;
        V_Dias_Periodo_Interes    NUMBER := 0;
        V_Dias_Periodo_Comision   NUMBER := 0;
        V_Monto_Desemb            NUMBER := 0;
        N_Error                   NUMBER := 0;
        K                         Pr_Creditos%ROWTYPE;
        Cuenta_C                  Cuenta_Efectivo.Num_Cuenta%TYPE;
        Vclientereferente         Cuenta_Efectivo.Cod_Cliente%TYPE;
        P_Fecha_Desemb            DATE := V_Fecha_Sist;
        v_fecha_prox_pago         DATE;
        v_cuota                   NUMBER := 0;
        vdias_extra               NUMBER := 0;          --malmanzar 2020-04-15
        vparametro_desem          VARCHAR2 (300)
            := param.PARAMETRO_X_EMPRESA (1, 'V_DIA_PROXIMA_CUOTA', 'PR');
        vSaldo_Disponible         NUMBER;
    BEGIN
        --Verifica que el monto sea mayor a cero
        IF NVL (P_Monto_Desemb, 0) <= 0
        THEN
            P_Mensaje := '001639'; --ERROR: El monto solicitado debe ser mayor que 0
            RETURN;
        END IF;

        --Verifica el Saldo Disponible del crédito
        vSaldo_Disponible :=
            SALDO_DISPONIBLE_PR (P_EMPRESA      => P_Cod_Empresa,
                                 P_Cod_Idioma   => 'ESPA',
                                 P_CREDITO      => P_No_Credito);

        IF vSaldo_Disponible < NVL (P_Monto_Desemb, 0)
        THEN
            P_Mensaje := '000534'; --El monto excede el Disponible para Desembolsar
            RETURN;
        END IF;

        --Verifica que el desembolso sea con credito a cuenta en los casos de Re-Crédito.
        IF P_Tipo_Desemb != 'C'
        THEN
            IF PR_PKG_DESEMBOLSO.es_recredito (
                   pcodigo_empresa   => P_Cod_Empresa,
                   pno_credito       => P_No_Credito)
            THEN
                P_Mensaje := '001815'; --Tipo de Desembolso debe ser a una cuenta de Efetivo, Favor Verificar
                RETURN;
            END IF;
        END IF;


        V_Mensaje := NULL;

        Validaciones_Generales (pCodigo_Empresa   => P_Cod_Empresa,
                                pNo_Credito       => P_No_Credito,
                                pTipo_Desem       => P_Tipo_Desemb,
                                pNum_Cuenta       => P_CUENTA,
                                pError            => V_Mensaje);

        IF V_Mensaje IS NOT NULL
        THEN
            P_Mensaje := V_Mensaje;
            RETURN;
        END IF;

        -- Inicializacion de arreglos ---
        /* BBkcredit.redit.Delete;
         Bkdesem.Delete;*/
        Pbkcargo.Delete;

        OPEN C_credito;

        FETCH C_credito INTO K;

        IF C_credito%FOUND
        THEN
            V_Existe_Cr := 'S';
        END IF;

        CLOSE C_credito;



        IF NVL (V_Existe_Cr, 'N') = 'S'
        THEN
            -- Carga Parametos Operacionales --
            Obtiene_Parametros (V_Mensaje);

            IF V_Mensaje IS NOT NULL
            THEN
                RAISE Salir;
            END IF;



            Bkcredit.Numero_Cf := K.Numero_Cf;
            Bkcredit.Codigo_Empresa := K.Codigo_Empresa;
            Bkcredit.Codigo_Agencia := K.Codigo_Agencia;
            Bkcredit.Estado := K.Estado;
            Bkcredit.Es_Linea_Credito := K.Es_Linea_Credito;
            Bkcredit.Tipo_Linea := K.Tipo_Linea;
            Bkcredit.Codigo_Cliente := K.Codigo_Cliente;
            Bkcredit.Manejo := K.Manejo;
            Bkcredit.Tipo_Intereses := K.Tipo_Intereses;
            Bkcredit.Tipo_Calendario := K.Tipo_Calendario;
            Bkcredit.Tipo_Cuota := K.Tipo_Cuota;
            Bkcredit.Codigo_Periodo_Intereses := K.Codigo_Periodo_Intereses;
            Bkcredit.Periodo_Comision_Normal := K.Periodo_Comision_Normal;
            Bkcredit.Comision_Normal := K.Comision_Normal;
            Bkcredit.Cuota := K.Cuota;
            Bkcredit.Monto_Desembolsado := K.Monto_Desembolsado;
            Bkcredit.Monto_Pagado_Principal := K.Monto_Pagado_Principal;
            Bkcredit.Monto_Pagado_Intereses := K.Monto_Pagado_Intereses;
            Bkcredit.Monto_Revalorizacion := K.Monto_Revalorizacion;
            Bkcredit.Plazo := K.Plazo;
            Bkcredit.No_Solicitud := K.No_Solicitud;
            Bkcredit.Tasa_Interes := K.Tasa_Interes;
            Bkcredit.Gracia_Principal := K.Gracia_Principal;
            Bkcredit.Gracia_Mora := K.Gracia_Mora;
            Bkcredit.Periodos_Gracia_Principal := K.Periodos_Gracia_Principal;
            Bkcredit.Codigo_Origen := K.Codigo_Origen;
            Bkcredit.Codigo_Nivel_Aprobacion := K.Codigo_Nivel_Aprobacion;
            Bkcredit.F_Ultimo_Pago_Principal := K.F_Ultimo_Pago_Principal;
            Bkcredit.F_Ultimo_Pago_Intereses := K.F_Ultimo_Pago_Intereses;
            Bkcredit.F_Primer_Desembolso := K.F_Primer_Desembolso;
            Bkcredit.F_Ultimo_Desembolso := K.F_Ultimo_Desembolso;
            Bkcredit.F_Proxima_Comision := K.F_Proxima_Comision;
            Bkcredit.F_Aprobacion := K.F_Aprobacion;
            Bkcredit.F_Ultimo_Pago_Mora := K.F_Ultimo_Pago_Mora;
            Bkcredit.F_Reconocim_Intereses := K.F_Reconocim_Intereses;
            Bkcredit.F_Principal_Anterior := K.F_Principal_Anterior;
            Bkcredit.F_Intereses_Anterior := K.F_Intereses_Anterior;
            Bkcredit.F_Mora_Anterior := K.F_Mora_Anterior;
            Bkcredit.F_Ultima_Revalorizacion := K.F_Ultima_Revalorizacion;
            Bkcredit.Cuenta_Abono := K.Cuenta_Abono;
            Bkcredit.Tipo_Desembolso := p_tipo_desemb; --  K.Tipo_Desembolso  ;   ---malmanzar 2020-04-16
            Bkcredit.Cuenta_Desem := K.Cuenta_Desem;
            Bkcredit.Observaciones1 := K.Observaciones1;
            Bkcredit.Observaciones2 := K.Observaciones2;
            Bkcredit.Codigo_Sub_Aplicacion := K.Codigo_Sub_Aplicacion;
            Bkcredit.Tipo_Comision := K.Tipo_Comision;
            Bkcredit.F_Ultimo_Pago_Comision := K.F_Ultimo_Pago_Comision;
            Bkcredit.F_Pago_Comision_Atrasada := K.F_Pago_Comision_Atrasada;
            Bkcredit.F_Pago_Cobro_Administrativo :=
                K.F_Pago_Cobro_Administrativo;
            Bkcredit.No_Credito := K.No_Credito;
            Bkcredit.No_Credito_Origen := K.No_Credito_Origen;
            Bkcredit.Monto_Credito := K.Monto_Credito;
            Bkcredit.F_Apertura := K.F_Apertura;
            Bkcredit.F_Vencimiento := K.F_Vencimiento;
            Bkcredit.F_Cancelacion := K.F_Cancelacion;
            Bkcredit.F_Adjudicacion := K.F_Adjudicacion;
            Bkcredit.F_Ultima_Revision := K.F_Ultima_Revision;
            Bkcredit.Tipo_Credito := K.Tipo_Credito;
            Bkcredit.Codigo_Moneda := K.Codigo_Moneda;
            Bkcredit.Dia_Pago := K.Dia_Pago;
            Bkcredit.Intereses_Anticipados := K.Intereses_Anticipados;
            Bkcredit.Descuenta_Intereses_Desembolso :=
                K.Descuenta_Intereses_Desembolso;
            Bkcredit.Cantidad_Cuotas_Descontar := K.Cantidad_Cuotas_Descontar;
            Bkcredit.No_Poliza_Bco := K.No_Poliza_Bco;
            Bkcredit.Codigo_Referente := K.Codigo_Referente;
            Bkcredit.Plazo := K.Plazo;
            Bkcredit.Plazo_Segun_Unidad := K.Plazo_Segun_Unidad;
            Bkcredit.Codigo_sub_aplicacion := k.Codigo_sub_aplicacion;

            --dbms_output.put_line('Bkcredit.Codigo_sub_aplicacion '||Bkcredit.Codigo_sub_aplicacion);


            --- Busqueda datos relacionados al credito --
            P_Datos_Adicionales_Credito (Bkcredit.Codigo_Empresa,
                                         Bkcredit.No_Credito,
                                         V_Ind_Cred_Univ,
                                         V_Oficial_Autorizado,
                                         V_Grupo_Tipo_Credito,
                                         V_Saldo_Disponible,
                                         V_Saldo_Actual,
                                         V_Dias_Periodo_Cuota,
                                         V_Dias_Periodo_Interes,
                                         V_Dias_Periodo_Comision,
                                         V_Mensaje);

            IF V_Mensaje IS NOT NULL
            THEN
                RAISE Salir;
            END IF;

            --
            --Bkdesem.Monto_Cancelacion := NVL (pMontoCancelacion, 0); --malmanzar 14-02-2023 req. 3709
            --
            Bkcredit.Ind_Credito_Universitario := V_Ind_Cred_Univ;
            Bkcredit.Oficial_Autorizado := V_Oficial_Autorizado;
            Bkcredit.Grupo_Tipo_Credito := V_Grupo_Tipo_Credito;
            Bkcredit.Saldo_Disponible := V_Saldo_Disponible;
            Bkcredit.Saldo_Actual := V_Saldo_Actual;
            Bkcredit.Dias_Periodo_Cuota := V_Dias_Periodo_Cuota;
            Bkcredit.Dias_Periodo_Interes := V_Dias_Periodo_Interes;
            Bkcredit.Dias_Periodo_Comision := V_Dias_Periodo_Comision;

            --- Datossobre  tipo de Credito asociado  --
            BEGIN
                SELECT NVL (Es_Cuota_Multiple, 'N'),
                       NVL (Multiples_Desembolsos, 'N'),
                       Ind_Es_Reserva
                  INTO Bkcredit.Es_Cuota_Multiple,
                       Bkcredit.Multiples_Desembolsos,
                       Bkcredit.Es_Reserva
                  FROM Pr_Tipo_Credito
                 WHERE     Codigo_Empresa = Bkcredit.Codigo_Empresa
                       AND Tipo_Credito = Bkcredit.Tipo_Credito; ---malmanzar 2020-04-16 error bkcredit.no_credito
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    Bkcredit.Es_Cuota_Multiple := 'N';
                    Bkcredit.Multiples_Desembolsos := 'N';
                    Bkcredit.Es_Reserva := NULL;
            END;

            --- Pre validaciones del credito antes de cargar datos del deembolso
            Prevalida_Credito (V_Mensaje);

            IF V_Mensaje IS NOT NULL
            THEN
                RAISE Salir;
            END IF;

            --- Realiza todos los calculos a realizar en el desembolso y los almacena en la variable Bkdesem. --
            Datos_Oper_Desembolso (Bkcredit.Codigo_Empresa,
                                   Bkcredit.No_Credito,
                                   P_Fecha_Desemb,
                                   P_Monto_Desemb,
                                   V_Mensaje);

            IF V_Mensaje IS NOT NULL
            THEN
                RAISE Salir;
            END IF;

            Bkdesem.Tipo_Desembolso := p_tipo_desemb;

            --- p_depura('Plsql_Program '||$$plsql_unit||' Linea '||$$plsql_line||' Bkdesem.Tipo_Desembolso  '||Bkdesem.Tipo_Desembolso );
            IF Bkdesem.Tipo_Desembolso = 'C'
            THEN                                    ---< Tipo Desembolso = C >
                --    p_depura('Plsql_Program '||$$plsql_unit||' Linea '||$$plsql_line);
                Cuenta_C := TO_NUMBER (Bkdesem.Numero_Cuenta);
                ----  Formatea_Cuenta (Cuenta_C, N_Error); --  --- Excello"JPH:2023-10-05:REQ_12672

                -- IF N_Error = 0  ----- Excello"JPH:2023-10-05:REQ_12672
                --THEN                                        ---< N_Error = 0 >
                Valida_Existencia_Cuenta (Cuenta_C,
                                          TO_CHAR (Bkcredit.Codigo_Empresa),
                                          Bkcredit.Codigo_Moneda,
                                          TO_CHAR (Bkdesem.Codigo_Cliente),
                                          FALSE,
                                          N_Error);

                IF     N_Error = 3
                   AND NVL (Bkcredit.Descuenta_Intereses_Desembolso, 'N') =
                       'S'
                THEN                                        ---< N_Error = 3 >
                    BEGIN
                        SELECT NVL (Codigo_Cliente, Bkdesem.Codigo_Cliente)
                          INTO Vclientereferente
                          FROM Pr_Referentes
                         WHERE Codigo_Referente = Bkcredit.Codigo_Referente;
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            Vclientereferente := Bkdesem.Codigo_Cliente;
                    END;

                    Valida_Existencia_Cuenta (
                        Cuenta_C,
                        TO_CHAR (Bkcredit.Codigo_Empresa),
                        Bkcredit.Codigo_Moneda,
                        TO_CHAR (Vclientereferente),
                        FALSE,
                        N_Error);
                END IF;                                      ---</N_Error = 3>

                IF N_Error <> 0
                THEN                                           ---<Error != 0>
                    Bkdesem.Numero_Cuenta := NULL;
                    V_Mensaje :=
                        'Cuenta para desembolso no existe o no es válida';
                    RAISE Salir;
                ELSE
                    Bkdesem.Numero_Cuenta := Cuenta_C;
                END IF;                                       ---</Error != 0>
            ---END IF;                                     --</ N_Error = 0 >
            END IF;                                ---</ Tipo Desembolso = C >

            IF (   Bkdesem.Total_Desembolso IS NULL
                OR Bkdesem.Total_Desembolso < 0)
            THEN
                V_Mensaje := Get_Mensaje_Err ('000563', 'PR');
                RAISE Salir;
            END IF;

            IF Bkdesem.Numero_Cuenta IS NULL
            THEN
                -- Debe Digitar El Numero De Cuenta
                V_Mensaje := 'Numero de cuenta no enviado';
                RAISE Salir;
            END IF;

            --- Actualiza datos del credito --
            Actualiza_Credito (V_Mensaje);

            IF V_Mensaje IS NOT NULL
            THEN
                RAISE Salir;
            END IF;

            ----
            -- Adigna Valor cuota actuual ---
            V_Valor_Cuota_Ant := Bkcredit.Cuota;

            --Begin malmanzar 2020-04-16
            Act_poliza_multiple_desem (
                pCodigo_Empresa       => Bkcredit.Codigo_Empresa,
                pNo_Credito           => Bkcredit.No_Credito,
                pfecha_desembolso     => BKDesem.FECHA_DESEMBOLSO,
                pMonto_Desembolsado   => BKCredit.monto_desembolsado);

            --End malmanzar 2020-04-16

            ---- p_depura('Linea '||$$plsql_line||' phu bkcredit.cuota '||bkcredit.cuota);


            --Funcionalidad desembolso d+6 / malmanzar 2020-04-16


            IF     TO_CHAR (BKDesem.FECHA_DESEMBOLSO, 'DD') >=
                   NVL (vparametro_desem, '35')
               AND PR.F_aplica_d_mas_6 (Bkcredit.Codigo_Empresa,
                                        BKCredit.no_credito)
            THEN         --funcion que determina si aplica para D+6 31-08-2018
                ---
                vdias_extra :=
                    pr_plan.f_dias_extras (BKDesem.FECHA_DESEMBOLSO);
            ---
            ELSE
                ---
                vdias_extra := 0;
            END IF;

            -- Calcula Cuota ---
            -- If Nvl(Bkcredit.Es_linea_Credito,'N') = 'S' Or Nvl(Bkcredit.Multiples_Desembolsos,'N') = 'S' Then
            IF 1 = 2
            THEN                                     ---prueba temp 16-04-2020
                Pr.Pr_Plan.Calcula_Cuota (Bkcredit.Codigo_Empresa,
                                          Bkcredit.No_Credito,
                                          Bkcredit.F_Apertura,
                                          Bkcredit.F_Vencimiento,
                                          Bkcredit.Gracia_Principal,
                                          Bkcredit.Monto_Desembolsado,
                                          Bkcredit.Tipo_Cuota,
                                          Bkcredit.Dias_Periodo_Cuota,
                                          Bkcredit.Tasa_Interes,
                                          Bkcredit.Tipo_Intereses,
                                          Bkcredit.Tipo_Calendario,
                                          Bkcredit.Plazo,
                                          Bkcredit.F_Apertura,
                                          TRUE,
                                          TRUE,
                                          Bkcredit.Cuota,
                                          V_Mensaje_Error);

                p_depura (
                       'Linea '
                    || $$plsql_line
                    || ' phu2 bkcredit.cuota '
                    || bkcredit.cuota);
            ELSE
                p_depura (
                       'Linea '
                    || $$plsql_line
                    || ' phu3 bkcredit.cuota '
                    || bkcredit.cuota);
                /*Begin

                      Pr_Proyeccion_Libre.Recalculo_Cuota_Nivelada (Bkcredit.Codigo_Empresa,Bkcredit.No_Credito,Bkcredit.Tasa_Interes ,
                                                                    Round((Bkcredit.Plazo /Bkcredit.Dias_Periodo_Cuota)), Bkcredit.Cuota);
                End;*/
                BKCredit.cuota :=
                    pr.pr_pkg_cuota.fn_calcula_cuota (
                        pf_primer_desem           => BKDesem.FECHA_DESEMBOLSO, --:BKCredit.f_apertura,-- Date,
                        pf_vencimiento            => BKCredit.f_vencimiento, -- Date,
                        pgracia_principal         => BKCredit.gracia_principal, -- Number,       -- en dias
                        psaldo_real               => BKCredit.monto_desembolsado, -- Number,       -- := 50000;--,
                        ptipo_cuota               => BKCredit.tipo_cuota, -- Varchar2,     --'N';
                        pperiodicidad             => BKCredit.dias_periodo_cuota, --vdias_periodo,-- Number,       -- := 90;
                        ptasa                     => BKCredit.tasa_interes, --- Number,       -- 44;   -- porcentaje (23, 27.5, etc)
                        ptipo_interes             => BKCredit.tipo_intereses, -- Varchar2,     --(1):= 'V';   -- (V)encido o (A)nticipado
                        ptipo_calendario          => BKCredit.tipo_calendario, -- Number,--- := 4;   -- tipos de cal: 1, 2, 3 o 4
                        pplazo_total              => BKCredit.plazo, -- Number,-- := add_months(TRUNC(SYSDATE),36) - trunc(sysdate);--,   -- en dias
                        pf_calculo                => BKDesem.FECHA_DESEMBOLSO,
                        pdias_extra               => NVL (vdias_extra, 0),
                        pPeriodo_Gracia_interes   => 0);
            END IF;

            IF V_Mensaje_Error IS NOT NULL
            THEN
                V_Mensaje :=
                       'Error al  recalcular cuota para el  crédito : '
                    || Bkcredit.No_Credito
                    || Get_Mensaje_Err (V_Mensaje_Error, 'PR');
                RAISE Salir;
            END IF;

            -- Genera Secuencia del Movimiento --
            SELECT Movimientos_Bpr.NEXTVAL
              INTO V_Numero_Transaccion
              FROM DUAL;

            --- Generando Nota de credito a la cuenta  (CC) ---

            IF Bkdesem.Tipo_Desembolso IN ('C', 'A')
            THEN
                BEGIN
                    V_Estado := 'A';
                    Bkcredit.Numero_Autorizacion_Bcc := V_Autorizacion;
                    V_Documento_Movim := V_Autorizacion;
                    V_Observaciones1 :=
                           'Desembolso Prest. No.: '
                        || TO_CHAR (Bkcredit.No_Credito)
                        || ' '
                        || 'Monto '
                        || TO_CHAR (P_Monto_Desemb, '99,999,999.99')
                        || ' en Cuenta '
                        || Bkcredit.Cuenta_Desem;

                    V_Observaciones2 :=
                           'Menos:  '
                        || TO_CHAR (P_Monto_Comision, '99,999,999.99');

                    Solicitud_Bcc (Bkcredit.Codigo_Empresa,
                                   P_Codigo_Agencia, --Bkcredit.Codigo_Agencia,
                                   3, -- Tipo Transaccion Desembolso De Dinero
                                   NULL,              -- No Hay Subtransaccion
                                   'BPR',
                                   Bkcredit.Codigo_Sub_Aplicacion,
                                   P_CUENTA,         ---Bkcredit.Cuenta_Desem,
                                   bkdesem.Tipo_Desembolso,      ----malmanzar
                                   Bkcredit.Codigo_Cliente,
                                   P_Fecha_Desemb,
                                   V_Fecha_Sist,
                                   V_Observaciones1,
                                   V_Observaciones2,
                                   NULL,
                                   NULL,
                                   V_Tipo_Pago_Cargos,
                                   TO_CHAR (V_Numero_Transaccion),
                                   V_Documento_Movim,
                                   V_Numero_Asiento,
                                   V_Tc1,
                                   V_Tc2,
                                   V_Mensaje_Error1,
                                   V_Mensaje_Error);
                END;

                IF V_Mensaje_Error IS NOT NULL
                THEN
                    P_Mensaje := V_Mensaje_Error;      ---malmanzar 03-07-2020
                    DBMS_OUTPUT.PUT_LINE (
                           'V_Mensaje_Error '
                        || V_Mensaje_Error
                        || ' Linea '
                        || $$plsql_line);
                    V_Mensaje := Get_Mensaje_Err (V_Mensaje_Error, 'PR');
                    DBMS_OUTPUT.PUT_LINE ('V_Mensaje ' || V_Mensaje);
                    ROLLBACK;
                    RETURN;
                --RAISE Salir;
                ELSIF V_Mensaje_Error1 IS NOT NULL
                THEN
                    V_Mensaje := V_Mensaje_Error1;
                    RAISE Salir;
                END IF;

                --
                --                 Elsif Bkdesem.Tipo_Desembolso = 'A' then
                --
                --                 dbms_output.put_line($$plsql_line||' << Linea V_Numero_Asiento'||V_Numero_Asiento);
                --                 pr.PR_PKG_DESEMBOLSO.Solicitud_Contable(P_EMPRESA            =>Bkcredit.Codigo_Empresa,
                --                                                        P_No_Credito         => Bkcredit.No_Credito,
                --                                                        P_AGENCIA            => Bkcredit.Codigo_Agencia,
                --                                                        P_TRANSACCION        => 3,     -- Tipo Transaccion Desembolso De Dinero
                --                                                        P_SUBTRANSACCION     => Null,  -- No Hay Subtransaccion ,
                --                                                        P_APLICACION         => 'BPR',
                --                                                        P_SUBAPLICACION      => Bkcredit.Codigo_Sub_Aplicacion,
                --                                                        P_CUENTA             => P_CUENTA,
                --                                                        P_FECHA_MOVIMIENTO   => P_Fecha_Desemb,
                --                                                        P_FECHA              => P_Fecha_Desemb,
                --                                                        P_MONTO              => P_Monto_Desemb,
                --                                                        pMONTO_COMISION      => P_MONTO_COMISION,
                --                                                        P_NUMERO_TRANSACCION => To_Char(V_Numero_Transaccion),
                --                                                        pcobrar_comision     => V_Tipo_Pago_Cargos,
                --                                                        P_TIPO_CARGOS        => 'A',--V_Tipo_Pago_Cargos,
                --                                                        P_DOCUMENTO          => V_Documento_Movim,
                --                                                        P_NUMERO_ASIENTO     => V_Numero_Asiento);
                DBMS_OUTPUT.put_line (
                       $$plsql_line
                    || ' << Linea V_Numero_Asiento'
                    || V_Numero_Asiento);
            END IF;                                             --<Tipo desem>

            IF (Bkcredit.Primer_Desembolso = 'S')
            THEN
                V_F_Aplicado := Bkdesem.Fecha_Desembolso;
                V_Cuota_Base := 0;
            ELSE
                --- Determina  Fecha de aplicación del movimiento --
                Pr_Procs.Fecha_Aplicado (Bkcredit.Codigo_Empresa,
                                         Bkcredit.No_Credito,
                                         P_Fecha_Desemb,
                                         3,
                                         P_Fecha_Desemb,
                                         P_Fecha_Desemb,
                                         V_Cuota_Base,
                                         V_F_Aplicado,
                                         V_Mensaje_Error);

                IF (V_Mensaje_Error IS NOT NULL)
                THEN
                    P_Mensaje :=
                           'Error ejecutnado proceso PR_PROCS.FECHA_APLICADO:  '
                        || Get_Mensaje_Err (V_Mensaje_Error, 'PR');
                    RAISE Salir;
                ELSIF (V_F_Aplicado IS NULL)
                THEN
                    -- Error: El Plan De Pagos No Tiene Cuota Siguiente A La Fecha Dada
                    P_Mensaje := Get_Mensaje_Err ('000472', 'PR');
                    RAISE Salir;
                END IF;
            END IF;


            IF (Bkcredit.Primer_Desembolso = 'S')
            THEN
                V_Valor1_Actual :=
                       '|'
                    || 'S'
                    || '|'
                    || TO_CHAR (NVL (Bkdesem.Monto_Cuota_Principal, 0))
                    || '|'
                    || TO_CHAR (NVL (Bkdesem.Monto_Cuota_Intereses, 0))
                    || '|'
                    || TO_CHAR (NVL (Bkdesem.Monto_Comision, 0))
                    || '|'
                    || TO_CHAR (NVL (Bkdesem.Monto_Poliza, 0))
                    || '|'
                    || TO_CHAR (NVL (Bkdesem.Monto_Cargos, 0))
                    || '|'
                    || Bkdesem.Tipo_Desembolso
                    || '|'
                    || V_Documento_Movim
                    || '|';
            ELSE
                V_Valor1_Actual :=
                       '|'
                    || 'N'
                    || '|'
                    || TO_CHAR (NVL (Bkdesem.Monto_Cuota_Principal, 0))
                    || '|'
                    || TO_CHAR (NVL (Bkdesem.Monto_Cuota_Intereses, 0))
                    || '|'
                    || TO_CHAR (NVL (Bkdesem.Monto_Comision, 0))
                    || '|'
                    || TO_CHAR (NVL (Bkdesem.Monto_Poliza, 0))
                    || '|'
                    || TO_CHAR (NVL (Bkdesem.Monto_Cargos, 0))
                    || '|'
                    || Bkdesem.Tipo_Desembolso
                    || '|'
                    || V_Documento_Movim
                    || '|';
            END IF;

            V_Valor2_Actual :=
                '|' || TO_CHAR (V_Fecha_Sist, 'DD/MM/YYYY') || '|';

            --- Manejo de cargos y descuentos ---
            V_Cargos := NVL (Bkdesem.Monto_Cargos, 0);
            V_Principal := NVL (Bkdesem.Monto_Cuota_Principal, 0);
            V_Interes := NVL (Bkdesem.Monto_Cuota_Intereses, 0);
            V_Comision := NVL (Bkdesem.Monto_Comision, 0);
            V_Poliza := NVL (Bkdesem.Monto_Poliza, 0);

            IF Bkcredit.Es_linea_Credito = 'S' AND Bkcredit.Es_Reserva = 'S'
            THEN
                IF Bkcredit.Primer_Desembolso = 'N'
                THEN
                    V_Monto_Desemb := P_Monto_Desemb;
                    V_Cargos := 0;
                ELSE
                    -- Se suma el cargao pues la cuenta esta sobregirada en
                    -- el monto enviado como parámetro para que al momento
                    -- de  aplciar el credito a la misma  y restar el cargo
                    -- no siga sobregirada
                    V_Monto_Desemb := P_Monto_Desemb + V_Cargos;
                END IF;
            ELSE
                V_Monto_Desemb := P_Monto_Desemb;
            END IF;

            Pr_Procs.Genera_Movimiento_Credito (
                P_Cod_Empresa,                                       --Empresa
                P_Codigo_Agencia, --50,                                                 -- Agencia
                Bkcredit.No_Credito,                                -- Credito
                3,                                      -- Tipo de Transaacion
                P_Fecha_Desemb,                                   -- Fecha Mob
                V_Monto_Desemb,                                   -- Monto Mov
                V_Numero_Transaccion,                          -- No Documento
                P_Tipo_Desemb, --'C'                  , -- Tipo Pago (Tipo Desembolso)
                P_Cuenta, --Bkcredit.Cuenta_Desem       , -- No Cuenta Efectivo
                V_Numero_Transaccion,                        -- No Transaccion
                V_Cargos,                                            -- Cargos
                V_Principal,                                      -- Principal
                V_Interes,                                        -- Intereses
                0,                                                     -- Mora
                V_Comision,                                        -- Comision
                V_Poliza,                                            -- Poliza
                NULL,                                              -- No Cuota
                V_Numero_Asiento,                       -- No Asiento contable
                0,                                                -- Dias Mora
                Bkcredit.dias_intereses,                       -- Dias Interes
                'A',                                             -- Estado Mov
                V_Observaciones1,                             -- Observacones1
                V_Observaciones2,                             -- Observacones2
                NULL,                                         -- Observacones3
                NULL,                                         -- Observacones4
                NULL,                                           -- Firma Legal
                NULL,                                               -- Juzgado
                NULL,                                        -- Plazo Anterior
                NULL,                                          -- Nivel Aprob.
                P_Fecha_Desemb,                                   -- F. Aplic.
                NULL,                                            -- Pago Menor
                USER,                                               -- Usuario
                NULL,                                            -- Cod. Cargo
                NULL,                                               -- F. Pago
                '|' || TO_CHAR (V_Valor_Cuota_Ant) || '|',       -- Valor Ant1
                NULL,                                           -- Valor Ant2,
                V_Valor1_Actual,                                -- Valor act 1
                V_Valor2_Actual,                                -- Valor Act 2
                V_F_Aplicado,                                    -- F Aplicado
                NULL,
                0,                                             --Dias Comision
                NULL,
                NULL,
                V_Idioma,
                V_Resultado,
                V_Mensaje_Error);

            IF NOT V_Resultado
            THEN
                V_Mensaje := V_Mensaje_Error;
                raise_application_error (
                    -20000,
                       SQLERRM
                    || ' -> traza: '
                    || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);

                RAISE Salir;
            END IF;



            ---Begin malmanzar 15-04-2020
            v_cuota := K.cuota;

            --End malmanzar 15-04-2020
            --- Actualizacion de Plan de Pagos
            IF    (    Bkcredit.Es_Linea_Credito = 'N'
                   AND Bkcredit.Primer_Desembolso = 'S')
               OR (    Bkcredit.Es_Linea_Credito = 'S'
                   AND NVL (Bkcredit.Es_Cuota_Multiple, 'N') = 'S')
               OR (    Bkcredit.Es_Linea_Credito = 'S'
                   AND Bkcredit.Manejo = 2
                   AND Bkcredit.Primer_Desembolso = 'S')
            THEN
                DBMS_OUTPUT.put_line (
                       'Linea '
                    || $$plsql_line
                    || ' Bkcredit.F_Vencimiento '
                    || Bkcredit.F_Vencimiento);
                Pr_Plan.Tprimer_Desembolso (P_Cod_Empresa,          -- Empresa
                                            P_Codigo_Agencia, --50,                     -- Agencia
                                            Bkcredit.No_Credito,    -- Credito
                                            Trabaja_Sabado, -- p_trabaja_sabado
                                            Trabaja_Domingo, -- p_trabaja_domingo
                                            V_Idioma,                -- Idioma
                                            P_Fecha_Desemb,         -- p_f_hoy
                                            Bkcredit.F_Apertura, -- p_f_apertur
                                            P_Fecha_Desemb, -- p_f_primer_desem
                                            NULL,          -- p_f_constitucion
                                            Bkcredit.Plazo,         -- p_plazo
                                            Bkcredit.F_Vencimiento, -- p_f_vencimiento
                                            Bkcredit.Tipo_Calendario, -- p_tipo_cal
                                            Bkcredit.Tipo_Intereses, -- p_tipo_int
                                            Bkcredit.Gracia_Principal, -- p_gracia_principal
                                            Bkcredit.Dia_Pago,   -- p_dia_pago
                                            Bkcredit.Dias_Periodo_Cuota, -- p_perio_cuo
                                            Bkcredit.Dias_Periodo_Interes, -- p_perio_int
                                            Bkcredit.Tipo_Comision, -- p_tipo_comision
                                            Bkcredit.Dias_Periodo_Comision, -- p_perio_comision
                                            Bkcredit.Comision_Normal, -- p_pct_comision
                                            Bkcredit.Tipo_Cuota, -- p_tipo_cuota
                                            Bkcredit.Cuota, -- p_cuota ---malmanzar 15-04-2020
                                            Bkcredit.Tasa_Interes, -- p_tasa_int
                                            0,                 -- p_cuota_base
                                            TO_CHAR (V_Numero_Transaccion), -- p_mov_n
                                            P_Monto_Desemb, -- p_monto_desembolso
                                            V_Principal,  -- p_monto_principal
                                            V_Interes,      -- p_monto_interes
                                            V_Comision,    -- p_monto_comision
                                            V_Poliza,        -- p_monto_poliza
                                            V_Valor1_Actual, -- p_mov_valor1_actual
                                            USER,                 -- p_usuario
                                            V_Mensaje_Error     -- p_msj_error
                                                           );
            ELSIF    (Bkcredit.Es_Linea_Credito = 'N')
                  OR (Bkcredit.Es_Linea_Credito = 'S' AND Bkcredit.Manejo = 2)
            THEN
                UPDATE Pr_Plan_Pagos
                   SET Cuota = Bkcredit.Cuota
                 WHERE     Codigo_Empresa = P_Cod_Empresa
                       AND No_Credito = Bkcredit.No_Credito;

                Pr_Plan.Tdesembolso (P_Cod_Empresa,                 -- Empresa
                                     P_Codigo_Agencia, --50,                            -- Agencia
                                     Bkcredit.No_Credito,           -- Credito
                                     P_Fecha_Desemb,                -- p_f_hoy
                                     Bkcredit.F_Apertura,       -- p_f_apertur
                                     Bkcredit.F_Primer_Desembolso, -- p_f_primer_desem
                                     NULL,                 -- p_f_constitucion
                                     Bkcredit.Plazo,                -- p_plazo
                                     Bkcredit.F_Vencimiento, -- p_f_vencimiento
                                     Bkcredit.Tipo_Calendario,   -- p_tipo_cal
                                     Bkcredit.Tipo_Intereses,    -- p_tipo_int
                                     Bkcredit.Gracia_Principal, -- p_gracia_principal
                                     V_Cuota_Base,             -- p_cuota_base
                                     TO_CHAR (V_Numero_Transaccion), -- p_mov_n
                                     V_F_Aplicado,         -- p_mov_f_aplicado
                                     P_Monto_Desemb,     -- p_monto_desembolso
                                     V_Principal,         -- p_monto_principal
                                     V_Interes,             -- p_monto_interes
                                     V_Comision,           -- p_monto_comision
                                     V_Poliza,               -- p_monto_poliza
                                     V_Valor1_Actual,   -- p_mov_valor1_actual
                                     USER,                        -- p_usuario
                                     V_cuota,
                                     V_Mensaje_Error            -- p_msj_error
                                                    );
            END IF;                                  -- Actualizacion Del Plan


            IF (V_Mensaje_Error IS NOT NULL)
            THEN
                IF     Bkcredit.Manejo = 2
                   AND V_Mensaje_Error IN ('000068',
                                           '000070',
                                           '000065',
                                           '000066')
                THEN
                    V_Mensaje_Error := NULL;

                    BEGIN
                        UPDATE Pr_Plan_Pagos
                           SET Saldo_Credito = Bkdesem.Nuevosaldo
                         WHERE     Codigo_Empresa = Bkcredit.Codigo_Empresa
                               AND No_Credito = Bkcredit.No_Credito
                               AND No_Cuota =
                                   (SELECT MAX (No_Cuota)
                                      FROM Pr_Plan_Pagos
                                     WHERE     No_Credito =
                                               Bkcredit.No_Credito
                                           AND Codigo_Empresa =
                                               Bkcredit.Codigo_Empresa
                                           AND No_Cuota > 0);
                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            NULL;
                    END;
                ELSE
                    --p_depura('V_Mensaje_Error '||V_Mensaje_Error);
                    --  V_Mensaje := V_Mensaje_Error;-- Get_Mensaje_Err (V_Mensaje_Error, 'PR');
                    --  raise_application_error(-20000, SQLERRM||' -> traza: '||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
                    --RAISE Salir;
                    V_Mensaje_Error := NULL;
                END IF;
            END IF;

            --- Actualiza el credito con el resultado de las operaciones del desembolso

            UPDATE Pr_Creditos
               SET F_Primer_Desembolso = Bkcredit.F_Primer_Desembolso,
                   Cuota = Bkcredit.cuota,             ---malmanzar 2020-04-15
                   Dia_Pago = Bkcredit.Dia_Pago,
                   Estado = 'D',
                   F_Vencimiento = Bkcredit.F_Vencimiento,
                   F_Ultimo_Desembolso = Bkcredit.F_Ultimo_Desembolso,
                   Monto_Desembolsado = Bkcredit.Monto_Desembolsado,
                   Monto_Pagado_Principal = Bkcredit.Monto_Pagado_Principal,
                   Monto_Pagado_Intereses = Bkcredit.Monto_Pagado_Intereses,
                   F_Ultimo_Pago_Intereses = Bkcredit.F_Ultimo_Pago_Intereses,
                   F_Ultimo_Pago_Principal = Bkcredit.F_Ultimo_Pago_Principal,
                   F_Ultimo_Pago_Comision = Bkcredit.F_Ultimo_Pago_Comision,
                   F_Ultimo_Pago_Mora = Bkcredit.F_Ultimo_Pago_Mora,
                   F_Pago_Comision_Atrasada =
                       Bkcredit.F_Pago_Comision_Atrasada,
                   F_Pago_Cobro_Administrativo =
                       Bkcredit.F_Pago_Cobro_Administrativo,
                   Codigo_Sub_Aplicacion = Bkcredit.Codigo_Sub_Aplicacion
             WHERE     Codigo_Empresa = Bkcredit.Codigo_Empresa
                   AND No_Credito = Bkcredit.No_Credito;

            IF P_Hacer_Commit = 'S'
            THEN
                COMMIT;
            END IF;

            P_Nummov_Desemb := V_Numero_Transaccion;
        ELSE
            P_Mensaje := 'Crédito no encontrado, no procede el desembolso';
        END IF;


        ---Crear recibo Begin

        BKCredit.Desc_cliente :=
            PA.OBT_NOMBRE_PERSONA (BKCredit.codigo_cliente);


        PR_PAGOS_PRESTAMOS.proxima_fecha_pago (
            p_empresa        => Bkcredit.Codigo_Empresa,
            p_no_credito     => BKCredit.no_credito,
            p_fecha_corte    => BKDesem.FECHA_DESEMBOLSO,
            p_proximo_pago   => v_fecha_prox_pago);

        --
        pr.pr_pagos_prestamos.crea_recibo (
            p_codigo_empresa          => Bkcredit.Codigo_Empresa,
            p_tipo_abono              => 'D',       --bkdesem.Tipo_Desembolso,
            p_no_identificacion       => TO_CHAR (V_Numero_Transaccion), --TO_CHAR(BKCredit.numero_transaccion),
            p_no_credito              => TO_CHAR (BKCredit.no_credito),
            p_es_linea_credito        => BKCredit.es_linea_credito,
            p_codigo_agencia          => P_Codigo_Agencia, --BKCredit.codigo_agencia,
            p_tipo_transaccion        => 3,
            p_codigo_cliente          => BKCredit.codigo_cliente,
            p_nombre_cliente          => BKCredit.Desc_cliente,
            p_recibo_caja             => TO_CHAR (V_Numero_Transaccion), --BKCredit.numero_transaccion,
            p_numero_asiento          => V_Numero_Asiento, --BKCredit.numero_asiento,
            p_monto_original          => BKDesem.monto_desembolso,
            p_saldo_anterior          => 0,
            p_monto_amortizacion      => 0,
            p_saldo_actual            => BKDesem.monto_desembolso,
            p_monto_intereses         => 0,
            p_monto_moratorios        => 0,
            p_monto_comision          => 0,          --Bkdesem.monto_comision,
            p_monto_cargos            => P_MONTO_COMISION,            ----here
            p_monto_poliza            => 0,
            p_monto_reconocidos       => 0,
            p_monto_total_pagar       => P_MONTO_COMISION,
            p_codigo_moneda           => bkcredit.codigo_moneda,
            p_dias_intereses          => 0,
            p_desde_intereses         => bkDesem.FECHA_DESEMBOLSO,
            p_hasta_intereses         => NULL,
            p_tasa_intereses          => BKCREDIT.TASA_INTERES,
            p_dias_moratorios         => 0,
            p_desde_moratorios        => bKDesem.FECHA_DESEMBOLSO,
            p_hasta_moratorios        => NULL,
            p_tasa_moratorios         => 0,
            p_dias_comision           => 0,
            p_desde_comision          => bKDesem.FECHA_DESEMBOLSO,
            p_hasta_comision          => NULL,
            p_tasa_comision           => 0,
            p_dias_reconocidos        => 0,
            p_fecha_proximo_pago      => v_fecha_prox_pago,
            p_fecha_creacion_recibo   => BKDesem.FECHA_DESEMBOLSO,
            p_recibo_creado_por       => USER,
            p_codigo_origen           => 1,
            p_desde_principal         => bKDesem.FECHA_DESEMBOLSO,
            p_hasta_principal         => NULL,
            p_desde_poliza            => bKDesem.FECHA_DESEMBOLSO,
            p_hasta_poliza            => NULL,
            p_cobro_administrativo    => NULL,
            p_monto_iva               => 0,
            p_mensaje                 => p_mensaje);

        ---Crear Recibo End

        P_Nummov_Desemb := V_Numero_Transaccion;
        vdias_extra := 0;

        --Inserta Desembolso FileFlow
        pInsertaFileFlow (pNoCredito          => TO_CHAR (p_no_credito),
                          pEstatus_Credito    => 'DE',      --vestado_credito,
                          pUsuario            => USER,
                          PEstatus_Registro   => '0');
    /* EXCEPTION
         WHEN Salir
         THEN
             ROLLBACK;
             P_Mensaje := V_Mensaje;
             raise_application_error (
                 -20000,
                    SQLERRM
                 || ' -> traza: '
                 || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
             RETURN;
             */
    END;                                                        -- Fin Proceso


    PROCEDURE Completa_Asiento (P_Empresa         IN     NUMBER,
                                P_Agencia         IN     NUMBER,
                                P_Moneda          IN     VARCHAR2,
                                P_Credito         IN     NUMBER,
                                P_Aplicacion      IN     VARCHAR2,
                                P_Subaplicacion   IN     NUMBER,
                                P_Transaccion     IN     NUMBER,
                                P_Subtransac      IN     NUMBER,
                                P_Numtransac      IN     VARCHAR2,
                                P_Descrip         IN     VARCHAR2,
                                P_Fecha           IN     DATE,
                                P_Numasiento      IN     NUMBER,
                                P_Auxiliarp       IN     NUMBER,
                                P_Usuario         IN     VARCHAR2,
                                P_Principal       IN     NUMBER,
                                P_Interes         IN     NUMBER,
                                P_Mora            IN     NUMBER,
                                P_Mensajeerr         OUT VARCHAR2)
    IS
        V_Cuenta_Contable       NUMBER := 0;
        V_Monto_Linea_Asiento   NUMBER := 0;
        V_Msg_Err               VARCHAR2 (500) := NULL;
        V_Msg_ErrEnc            VARCHAR2 (100) := NULL;
        V_Msg_Cod_Err           VARCHAR2 (50) := NULL;
        V_Tc1                   NUMBER (15) := 0;
        V_Tc2                   NUMBER (15) := 0;
    BEGIN
        DBMS_OUTPUT.put_line (
               '$$plsqle_type '
            || $$plsql_type
            || ' Program '
            || $$plsql_unit
            || ' Linea '
            || $$plsql_line);
        V_Msg_ErrEnc :=
            'ERROR EN PROCESO  PKG_LINEA_RESERVAS_OPR COMPLETA ASEINTO ';

        -- Linea Asiento Capital ---
        IF P_Principal > 0
        THEN
            V_Cuenta_Contable :=
                Pr.F_Busca_Cuenta_Cartera (P_Empresa, P_Credito, 'CAPITAL');

            IF V_Cuenta_Contable IS NULL
            THEN
                V_Msg_Err := Get_Mensaje_Err ('000014', 'PR');
                P_Mensajeerr := V_Msg_ErrEnc || V_Msg_Err;
                RETURN;
            END IF;


            Pr_Procs.Convierte_Monto_Credcta (P_Empresa,
                                              P_Principal,
                                              P_Moneda,
                                              V_Cuenta_Contable,
                                              P_Fecha,
                                              V_Monto_Linea_Asiento,
                                              V_Msg_Cod_Err);

            IF V_Msg_Cod_Err IS NOT NULL
            THEN
                V_Msg_Err := Get_Mensaje_Err (V_Msg_Cod_Err, 'PR');
                P_Mensajeerr := V_Msg_ErrEnc || V_Msg_Err;
                RETURN;
            END IF;

            Cg_Utl.Lineas_Del_Asiento (P_Empresa,
                                       P_Agencia,
                                       'BPR',
                                       P_Subaplicacion,
                                       P_Transaccion,
                                       NULL,
                                       P_Numtransac,
                                       P_Descrip,
                                       P_Fecha,
                                       P_Fecha,
                                       P_Fecha,
                                       P_Numasiento,
                                       V_Cuenta_Contable,
                                       P_Auxiliarp,
                                       V_Monto_Linea_Asiento,
                                       'N',                      -- No Acumula
                                       'C',             -- Tipo Movimiento  --
                                       'N',           -- No Modifica Linea  --
                                       V_Tc1,         -- Tipo De Cambio Orig--
                                       V_Tc2,         -- Tipo De Cambio Base--
                                       P_Usuario,
                                       V_Msg_Err,
                                       P_Credito);                --Referencia

            IF V_Msg_Err IS NOT NULL
            THEN
                P_Mensajeerr := V_Msg_ErrEnc || V_Msg_Err;
                RETURN;
            END IF;
        END IF;                                      --If P_Principal > 0 Then

        --- Linea asiento intereses
        IF P_Interes > 0
        THEN
            V_Monto_Linea_Asiento := 0;
            V_Cuenta_Contable := 0;

            V_Cuenta_Contable :=
                Pr.F_Busca_Cuenta_Cartera (P_Empresa, P_Credito, 'INTERESES');

            IF V_Cuenta_Contable IS NULL
            THEN
                V_Msg_Err := Get_Mensaje_Err ('000014', 'PR');
                P_Mensajeerr := V_Msg_ErrEnc || V_Msg_Err;
                RETURN;
            END IF;


            Pr_Procs.Convierte_Monto_Credcta (P_Empresa,
                                              P_Interes,
                                              P_Moneda,
                                              V_Cuenta_Contable,
                                              P_Fecha,
                                              V_Monto_Linea_Asiento,
                                              V_Msg_Cod_Err);

            IF V_Msg_Cod_Err IS NOT NULL
            THEN
                V_Msg_Err := Get_Mensaje_Err (V_Msg_Cod_Err, 'PR');
                P_Mensajeerr := V_Msg_ErrEnc || V_Msg_Err;
                RETURN;
            END IF;

            Cg_Utl.Lineas_Del_Asiento (P_Empresa,
                                       P_Agencia,
                                       'BPR',
                                       P_Subaplicacion,
                                       P_Transaccion,
                                       NULL,
                                       P_Numtransac,
                                       P_Descrip,
                                       P_Fecha,
                                       P_Fecha,
                                       P_Fecha,
                                       P_Numasiento,
                                       V_Cuenta_Contable,
                                       P_Auxiliarp,
                                       V_Monto_Linea_Asiento,
                                       'N',                      -- No Acumula
                                       'C',             -- Tipo Movimiento  --
                                       'N',           -- No Modifica Linea  --
                                       V_Tc1,         -- Tipo De Cambio Orig--
                                       V_Tc2,         -- Tipo De Cambio Base--
                                       P_Usuario,
                                       V_Msg_Err,
                                       P_Credito);                --Referencia

            IF V_Msg_Err IS NOT NULL
            THEN
                P_Mensajeerr := V_Msg_ErrEnc || V_Msg_Err;
                RETURN;
            END IF;
        END IF;                                        --If P_Interes > 0 Then

        --- Linea asiento Mora
        IF P_Mora > 0
        THEN
            V_Monto_Linea_Asiento := 0;
            V_Cuenta_Contable := 0;

            V_Cuenta_Contable :=
                Pr.F_Busca_Cuenta_Cartera (P_Empresa, P_Credito, 'MORA');

            IF V_Cuenta_Contable IS NULL
            THEN
                V_Msg_Err := Get_Mensaje_Err ('000014', 'PR');
                P_Mensajeerr := V_Msg_ErrEnc || V_Msg_Err;
                RETURN;
            END IF;


            Pr_Procs.Convierte_Monto_Credcta (P_Empresa,
                                              P_Mora,
                                              P_Moneda,
                                              V_Cuenta_Contable,
                                              P_Fecha,
                                              V_Monto_Linea_Asiento,
                                              V_Msg_Cod_Err);

            IF V_Msg_Cod_Err IS NOT NULL
            THEN
                V_Msg_Err := Get_Mensaje_Err (V_Msg_Cod_Err, 'PR');
                P_Mensajeerr := V_Msg_ErrEnc || V_Msg_Err;
                RETURN;
            END IF;

            Cg_Utl.Lineas_Del_Asiento (P_Empresa,
                                       P_Agencia,
                                       'BPR',
                                       P_Subaplicacion,
                                       P_Transaccion,
                                       NULL,
                                       P_Numtransac,
                                       P_Descrip,
                                       P_Fecha,
                                       P_Fecha,
                                       P_Fecha,
                                       P_Numasiento,
                                       V_Cuenta_Contable,
                                       P_Auxiliarp,
                                       V_Monto_Linea_Asiento,
                                       'N',                      -- No Acumula
                                       'C',             -- Tipo Movimiento  --
                                       'N',           -- No Modifica Linea  --
                                       V_Tc1,         -- Tipo De Cambio Orig--
                                       V_Tc2,         -- Tipo De Cambio Base--
                                       P_Usuario,
                                       V_Msg_Err,
                                       P_Credito);                --Referencia

            IF V_Msg_Err IS NOT NULL
            THEN
                P_Mensajeerr := V_Msg_ErrEnc || V_Msg_Err;
                RETURN;
            END IF;
        END IF;                                             --If Mora > 0 Then
    END;

    PROCEDURE Act_poliza_multiple_desem (pCodigo_Empresa       IN NUMBER,
                                         pNo_Credito           IN NUMBER,
                                         pfecha_desembolso     IN DATE,
                                         pMonto_Desembolsado   IN NUMBER)
    IS
        ves_linea_Credito            pr_creditos.es_linea_credito%TYPE;
        vmultiples_desembolsos       pr_tipo_credito.multiples_desembolsos%TYPE;
        vind_credito_universitario   pr_tipo_credito.ind_credito_universitario%TYPE;
        vdesembolso_pactado          pr_tipo_credito.desembolso_pactado%TYPE;
        vmonto_poliza                NUMBER;
        p_msj_error                  VARCHAR2 (300);
    BEGIN
        DBMS_OUTPUT.put_line (
               '$$plsqle_type '
            || $$plsql_type
            || ' Program '
            || $$plsql_unit
            || ' Linea '
            || $$plsql_line);

        --- malmanzar 25-10-2018 para actualizar poliza creditos multiples desembolsos principalmente
        --los educativos
        BEGIN
            SELECT NVL (cre.es_linea_Credito, 'N'),
                   NVL (tip.multiples_desembolsos, 'N'),
                   NVL (ind_credito_universitario, 'N'),
                   NVL (desembolso_pactado, 'N')
              INTO ves_linea_Credito,
                   vmultiples_desembolsos,
                   vind_credito_universitario,
                   vdesembolso_pactado
              FROM pr_creditos cre, pr_tipo_credito tip
             WHERE     cre.codigo_empresa = pCodigo_Empresa
                   AND cre.no_credito = pNo_Credito
                   AND cre.codigo_empresa = tip.codigo_empresa
                   AND cre.tipo_credito = tip.tipo_credito;
        EXCEPTION
            WHEN OTHERS
            THEN
                pa.p_depura ('Error into ' || SQLERRM);
                ves_linea_Credito := 'N';
                vind_credito_universitario := 'N';
                vdesembolso_pactado := 'N';
        END;

        IF vind_credito_universitario = 'S' OR vdesembolso_pactado = 'S'
        THEN
            BEGIN
                PR.PKG_POLIZAS.Generar_Poliza (pCodigo_Empresa,
                                               pNo_Credito,
                                               pfecha_desembolso,
                                               pMonto_Desembolsado,
                                               p_msj_error);
            END;

            BEGIN
                SELECT NVL (SUM (monto_a_pagar), 0)
                  INTO vmonto_poliza
                  FROM pr.pr_polizas_x_credito
                 WHERE     codigo_empresa = pCodigo_Empresa
                       AND no_credito = pNo_Credito;

                UPDATE pr_plan_pagos
                   SET poliza = vmonto_poliza, saldo_poliza = vmonto_poliza
                 WHERE     codigo_empresa = pCodigo_Empresa
                       AND no_credito = pNo_Credito
                       AND estado = 'A'
                       AND f_cuota >= pfecha_desembolso;
            END;
        END IF;
    ---  fin malmanzar 25-10-2018
    END Act_poliza_multiple_desem;

    /*****************************************************
    *  Autor: Ing. Bladimir L. Fernandez
    *  Fecha: 06/01/2016
    *  Observacion: Cancelar los creditos pendientes con el
    *               Credito que se esta desembolsando
    */
    FUNCTION Cancelacion_ReCredito (
        pCodigo_Empresa     IN     NUMBER,
        pNo_Credito         IN     NUMBER,
        pFecha_Desembolso   IN     DATE,
        pNumero_Cuenta      IN     VARCHAR2,
        pCodigo_Agencia     IN     NUMBER,
        pNumAsiento         IN OUT VARCHAR2,
        --pMon_Cancelacion    OUT    NUMBER,
        P_Documento         IN     NUMBER DEFAULT 0 -- Excello:JPH:2019-11-13: Se requiere para identificar la operacion de PR
                                                   )
        RETURN VARCHAR2
    IS
        V_MENSAJE_ERROR            VARCHAR2 (255);
        --V_NUMERO_CUENTA        varchar2(30); ---malmanzar 22-11-2019 no se utiliza
        V_DOCUMENTO_MOVIM          VARCHAR2 (250);
        --  fDesembolso  date;
        --  cTipoCredito  varchar2(10);
        --  nMonto_Credito number(16,2);
        nMontoCanSaldo             NUMBER (16, 2);

        v_inte_condonada           NUMBER := 0;
        v_mora_condonada           NUMBER := 0;
        v_poliza_condonada         NUMBER := 0;
        --
        v_solic_ingreso            NUMBER;
        VNUMERO_ASIENTO            NUMBER;
        VCARGOS_PENDIENTES         NUMBER := 0;
        VNumero_Cuenta             VARCHAR2 (30);
        v_Raise                    EXCEPTION;
        lc_congela                 VARCHAR2 (1);
        ln_secuencia               NUMBER;
        vSaldo_Disponible          NUMBER;
        vMonto_Total_Cancelacion   NUMBER;
    BEGIN
        VNumero_Cuenta := pNumero_Cuenta;

        --BFernandez Realizar la Cancelacion del Credito
        --06/01/2016
        --Buscar la Cuenta Contable
        ---malmanzar 22-11-2019 no se utiliza
        /*cg_utl.Cuenta_Contable_sector(to_number(pCodigo_Empresa), 'BPR', :BKCredit.Codigo_Sub_Aplicacion, 'CANCELACION_DESEMBOLSO', :BKCredit.Codigo_Cliente,
                                       V_NUMERO_CUENTA, V_MENSAJE_ERROR);
        if V_MENSAJE_ERROR is not null then
           v_mensaje_error := '000159';
        end if;*/

        --Fin de la busquedad
        FOR C1
            IN (SELECT *
                  FROM PR_CANCELACION_CREDITOS
                 WHERE     Codigo_Empresa = pCodigo_Empresa  --pCodigo_Empresa
                       AND No_Credito = pNo_Credito
                       AND EXISTS
                               (SELECT 1
                                  FROM pr_creditos pr
                                 WHERE     pr.Codigo_Empresa =
                                           pCodigo_Empresa   --pCodigo_Empresa
                                       AND pr.No_Credito =
                                           NO_CREDITO_CANCELADO
                                       AND pr.estado IN ('D',
                                                         'V',
                                                         'M',
                                                         'E',
                                                         'J')))
        LOOP
            --pr_pagos_prestamos.obtieneMontoCancelacionTotal
            nMontoCanSaldo :=
                pr_pagos_prestamos.F_SALDO_TOTAL_OPERACIONES (
                    p_empresa      => pCodigo_empresa, -- Codigo de la Empresa.
                    p_no_credito   => C1.no_credito_Cancelado, -- Numero de Credito.
                    p_fecha        => pFecha_Desembolso -- Fecha de Aplicacion.
                                                       );



            IF NVL (nMontoCanSaldo, 0) > 0
            THEN
                pr_pagos_prestamos.Set_Transaccion_Prestamo (40); --Asigna transaccion abono normal


                IF 1 = 1
                THEN
                    BEGIN
                        pr.pr_pagos_prestamos.aplica_pago (
                            pcodigo_empresa         => pCodigo_Empresa,
                            pno_credito             => C1.no_credito_Cancelado, --:GLOBAL.PRESTAMO,
                            pmonto                  => nMontoCanSaldo, --VTOTAL_PAGO,---:bkinfo.monto_recibir,---:bkinfo.monto_neto,-- monto_recibir,
                            pfecha                  => pFecha_Desembolso, --:variables.FECHA_HOY,
                            ptipo_cobro             => 'C', --:bkinfo.tipo_cobro,
                            pcuenta_abono           => vNUMERO_CUENTA, --:bkinfo.numero_cuenta,
                            Pusuario                => USER,
                            p_error                 => V_MENSAJE_ERROR, --p_error,
                            vmonto_condona_int      => v_inte_condonada,
                            vmonto_condona_mor      => v_mora_condonada,
                            vmonto_condona_pol      => v_poliza_condonada,
                            pdocumento_movimiento   => v_solic_ingreso, --:Variables.NUMERO_SOLICITUD,
                            pnumero_asiento         => VNUMERO_ASIENTO,
                            P_AGENCIA_PROCESO       => pCodigo_Agencia); ---_PROCESO);

                        IF V_MENSAJE_ERROR IS NOT NULL
                        THEN
                            DBMS_OUTPUT.put_line (
                                   ' pr.pr_pagos_prestamos.aplica_pago => v_mensaje_error '
                                || v_mensaje_error);
                            v_mensaje_error :=
                                   'v_mensaje_error '
                                || v_mensaje_error
                                || ' 000759 '
                                || SQLERRM; ---malmanzar pendiente error cancelando re-credito
                            DBMS_OUTPUT.put_line (
                                'v_mensaje_error ' || v_mensaje_error);

                            V_MENSAJE_ERROR := '000369';
                        --   v_raise;

                        END IF;
                    END;


                    --malmanzar 19-07-2019 Begin

                    UPDATE PR_CANCELACION_CREDITOS
                       SET No_Documento_Movimiento = V_DOCUMENTO_MOVIM,
                           Fecha_Cancelacion = PFECHA_DESEMBOLSO,
                           Monto_Cancelacion = nMontoCanSaldo
                     WHERE     Codigo_Empresa = pCodigo_Empresa
                           AND No_Credito = C1.No_Credito
                           AND No_Credito_Cancelado = C1.No_Credito_Cancelado;
                END IF;                                            ---if 1 = 2
            END IF;
        END LOOP;


        --Fin BFernandez


        RETURN (V_MENSAJE_ERROR);
    EXCEPTION
        WHEN v_Raise
        THEN
            RETURN (V_MENSAJE_ERROR);
    END Cancelacion_ReCredito;

    PROCEDURE descongela_monto_recredito (
        pCodigo_Empresa    NUMBER,
        pCodAgencia        NUMBER,                       --:b_cta.cod_agencia,
        pCodSistema        VARCHAR2,
        pnum_cuenta        cc.cuenta_efectivo.num_cuenta%TYPE,
        pMontoMovimiento   cc.movimto_diario.mon_movimiento%TYPE,
        P_Documento        Movimto_Diario.Num_Documento%TYPE --- Excello:JPH:2019-11-13:REQ_83180: Nuevo Parametro
                                                            )
    ---pNumCongelamiento Number)
    IS
        CURSOR c_cuenta IS
            SELECT cod_producto, ind_pag_interes
              FROM cuenta_efectivo
             WHERE cod_empresa = pCodigo_Empresa AND num_cuenta = pnum_cuenta;

        V_cuenta               c_cuenta%ROWTYPE;
        vfechacal              DATE := pa.fecha_actual_calendario ('CC', 1, 0);

        vNumMovtoD             NUMBER;

        vErrAplic              NUMBER (2);
        vCodError              VARCHAR2 (6);
        vSecCongel             NUMBER (8);
        v_Usuario              VARCHAR2 (30) := USER;
        form_trigger_failure   EXCEPTION;
    BEGIN
        --- dbms_output.put_line('Linea '||$$plsql_line||' sqlerrm '||sqlerrm);
        DBMS_OUTPUT.put_line (
            'Linea ' || $$plsql_line || ' pCodAgencia ' || pCodAgencia);
        DBMS_OUTPUT.put_line (
            'Linea ' || $$plsql_line || ' pCodSistema ' || pCodSistema);
        DBMS_OUTPUT.put_line (
            'Linea ' || $$plsql_line || ' pnum_cuenta ' || pnum_cuenta);
        DBMS_OUTPUT.put_line (
            'Linea ' || $$plsql_line || ' P_Documento ' || P_Documento);
        DBMS_OUTPUT.put_line (
               'Linea '
            || $$plsql_line
            || ' pMontoMovimiento '
            || pMontoMovimiento);



        BEGIN
            SELECT MAX (sec_congela)
              INTO vSecCongel
              FROM congelamientos
             WHERE fec_inicio = vfechacal AND Num_Cuenta = pnum_cuenta; --- Excello:JPH:2019-11-13:REQ_83180: Se debe  buscar el ultiomo congelameinto para la cuaeta
        END;

        DBMS_OUTPUT.put_line (
            'Linea ' || $$plsql_line || ' vSecCongel ' || vSecCongel);

        BEGIN
            OPEN c_cuenta;

            FETCH c_cuenta INTO v_cuenta;

            CLOSE c_cuenta;

            -- Se agrega el movimiento diario
            CCMOV.Agrega_Movimiento (
                pCodigo_Empresa,
                pCodAgencia,                             --:b_cta.cod_agencia,
                pCodSistema,
                pnum_cuenta,                              --:b_cta.num_cuenta,
                v_cuenta.cod_producto,                  --:b_cta.cod_producto,
                96,
                5,                                  --:b_desc.subtip_transacc,
                v_usuario,
                vfechacal,                           --:b_desc.fec_movimiento,
                --- Excello:JPH:2019-11-13:REQ_83180: Begin >> -- Se cambia la sec del congelameinto por el No de operacion --
                P_Documento,
                ----vSecCongel,--pNumCongelamiento,--:b_desc.num_documento,
                --- Excello:JPH:2019-11-13:REQ_83180: End <<
                pMontoMovimiento,                    --:b_desc.mon_movimiento,
                'Descongelamiento Cancelacion recredito', --:b_desc.descripcion,
                'B' || pCodSistema,
                0,
                'N',                              --:variables.apl_cargo_desc,
                vNumMovtoD);
            DBMS_OUTPUT.put_line ('Linea ' || $$plsql_line);
        EXCEPTION
            WHEN OTHERS
            THEN
                --UTILITARIOS.mensaje('000044',:variables.CodIdioma,'CC');
                vCodError := '000044';
                DBMS_OUTPUT.put_line (
                    'Linea ' || $$plsql_line || ' sqlerrm ' || SQLERRM);
                RAISE form_trigger_failure;
        END;

        DBMS_OUTPUT.put_line ('Linea ' || $$plsql_line);

        BEGIN
            -- Se aplica el movimiento
            CCMOV.Aplica_Movimiento (vNumMovtoD,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     vSecCongel, --vSecCongel,--pNumCongelamiento,--:b_desc.sec_congela,
                                     vErrAplic,
                                     vCodError);
            DBMS_OUTPUT.put_line (
                   'Linea '
                || $$plsql_line
                || ' vCodError '
                || vCodError
                || ' vErrAplic '
                || vErrAplic);

            IF (vCodError <> '000005')
            THEN
                DBMS_OUTPUT.put_line (
                       'Linea '
                    || $$plsql_line
                    || ' vCodError '
                    || vCodError
                    || ' vErrAplic '
                    || vErrAplic);

                -- Se elimina el movimiento diario de "agrega_movimiento"
                DELETE movimto_diario
                 WHERE num_movto_d = vNumMovtoD;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                DBMS_OUTPUT.put_line ('sqlerrm ' || SQLERRM);
        END;
    EXCEPTION
        WHEN form_trigger_failure
        THEN
            DBMS_OUTPUT.put_line (
                'Linea ' || $$plsql_line || 'sqlerrm ' || SQLERRM);
            ROLLBACK;
            RETURN;
    ---end if;
    --end if;
    END descongela_monto_Recredito;

    PROCEDURE Validaciones_Generales (pCodigo_Empresa   IN     NUMBER,
                                      pNo_Credito       IN     NUMBER,
                                      pTipo_Desem       IN     VARCHAR2,
                                      pNum_Cuenta       IN     VARCHAR2,
                                      pError               OUT VARCHAR2)
    IS
        vCliente_Credito       PR_CREDITOS.CODIGO_CLIENTE%TYPE;
        vEstado_Credito        PR_CREDITOS.ESTADO%TYPE;
        vMoneda_Credito        NUMBER;
        vCuenta_Desem          VARCHAR2 (30);
        vCliente_Cuenta        NUMBER;
        vMoneda_Cuenta         NUMBER;
        vMoneda_Contable       NUMBER;
        vEstado_Cuenta_Conta   CG_CATALOGO_X_EMPRESA.ESTADO%TYPE;
    BEGIN
        IF pTipo_Desem IS NULL
        THEN
            pError := '000986';               --Tipo desembolso es obligatorio
            RETURN;
        END IF;

        IF pNum_Cuenta IS NULL
        THEN
            pError := '000417';                ---Numero Cuenta es obligatorio
            RETURN;
        END IF;



        BEGIN
            SELECT Codigo_Cliente,
                   estado,
                   Codigo_Moneda,
                   Cuenta_Desem
              INTO vCliente_Credito,
                   vEstado_Credito,
                   vMoneda_Credito,
                   vCuenta_Desem
              FROM pr_creditos
             WHERE     Codigo_Empresa = pCodigo_Empresa
                   AND No_Credito = pNo_Credito;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                pError := '000542';              --ERROR: El Credito no existe
                RETURN;
        END;

        ---
        IF pTipo_Desem = 'C'
        THEN                           --if pTipo_Desem = 'C' Crédito a Cuenta
            --Cuenta desembolso
            IF vCuenta_Desem IS NULL
            THEN
                pError := '000417';    --El Numero de Cuenta no puede ser nulo
                RETURN;
            ELSE
                --Cuenta relacionada
                IF vCuenta_Desem != pNum_Cuenta
                THEN
                    pError := '001157'; --Debe digitar el Numero el de Cuenta Relacionada
                    RETURN;
                END IF;
            END IF;                --end if pTipo_Desem = 'C' Crédito a Cuenta

            BEGIN
                SELECT a.cod_cliente, b.cod_moneda
                  INTO vCliente_Cuenta, vMoneda_Cuenta
                  FROM cuenta_efectivo a, productos b
                 WHERE     a.cod_empresa = b.cod_empresa
                       AND a.cod_producto = b.cod_producto
                       AND a.cod_empresa = pCodigo_Empresa
                       AND a.num_cuenta = pNum_Cuenta;

                IF vCliente_Cuenta != vCliente_Credito
                THEN
                    pError := '000414'; --El Numero de Cuenta no pertenece al Cliente
                    RETURN;
                END IF;

                ---
                IF vMoneda_Cuenta != vMoneda_Credito
                THEN
                    pError := '000416'; --El Tipo de Moneda de la Cuenta es diferente a la que tiene el Credito
                    RETURN;
                END IF;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    pError := '000560'; -- El Numero de Cuenta no se encuentra registrada
                    RETURN;
            END;
        ELSIF pTipo_Desem = 'A'
        THEN                                  --Desembolso con Cuenta Contable
            BEGIN
                SELECT MONEDA_CUENTA, ESTADO
                  INTO vMoneda_Contable, vEstado_Cuenta_Conta
                  FROM CG_CATALOGO_X_EMPRESA CAT
                 WHERE     CODIGO_EMPRESA = pCodigo_Empresa
                       AND CUENTA_CONTABLE = pNum_Cuenta;

                IF vEstado_Cuenta_Conta != 'A'
                THEN
                    pError := '000887';       --cuenta contable no esta activa
                    RETURN;
                END IF;

                IF vMoneda_Contable != vMoneda_Credito
                THEN
                    pError := '002358'; --Moneda Cuenta Contable es diferente a la del crédito
                END IF;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    pError := '000887';           ---Cuenta Contable no Existe
                    RETURN;
            END;
        ELSE                                  ---pTipo_Desembolso no permitido
            pError := '000550';     --Tipo de Desembolso invalido, Verifiquelo
            RETURN;
        END IF;
    --End;

    END;

    FUNCTION Es_Recredito (pcodigo_empresa NUMBER, pno_credito NUMBER)
        RETURN BOOLEAN
    IS
        vcount    NUMBER;
        vresult   BOOLEAN;
    BEGIN
        SELECT COUNT (1)
          INTO vcount
          FROM pr_cancelacion_creditos
         WHERE codigo_empresa = pcodigo_empresa AND no_credito = pno_credito;

        IF vcount > 0
        THEN
            vresult := TRUE;
        ELSE
            vresult := FALSE;
        END IF;

        RETURN vresult;
    END Es_Recredito;

    FUNCTION f_punto15_Cancelacion (pcodigo_empresa     NUMBER,
                                    pno_credito         NUMBER,
                                    pFecha_Desembolso   DATE)
        RETURN NUMBER
    IS
        vimpuesto        NUMBER := 0;
        vMonto_Punto15   NUMBER := 0;
        vTotal_Punto15   NUMBER := 0;
        nMontoCanSaldo   NUMBER := 0;
    BEGIN
        BEGIN
            SELECT SUBSTR (valor, 1, 15)
              INTO vimpuesto
              FROM parametros_x_empresa
             WHERE     (cod_empresa = pcodigo_empresa)
                   AND (cod_sistema = 'PA')
                   AND (abrev_parametro = 'IMP_LEY288');
        -- vMontoPunto15 := (NVL (bkdesem.Monto_Cancelacion, 0)* vimpuesto)/100;

        EXCEPTION
            WHEN OTHERS
            THEN
                vimpuesto := 0;
        END;

        IF NVL (vimpuesto, 0) > 0
        THEN
            FOR C1
                IN (SELECT *
                      FROM PR_CANCELACION_CREDITOS
                     WHERE     Codigo_Empresa = pCodigo_Empresa --pCodigo_Empresa
                           AND No_Credito = pNo_Credito
                           AND EXISTS
                                   (SELECT 1
                                      FROM pr_creditos pr
                                     WHERE     pr.Codigo_Empresa =
                                               pCodigo_Empresa --pCodigo_Empresa
                                           AND pr.No_Credito =
                                               NO_CREDITO_CANCELADO
                                           AND pr.estado IN ('D',
                                                             'V',
                                                             'M',
                                                             'E',
                                                             'J')))
            LOOP
                --pr_pagos_prestamos.obtieneMontoCancelacionTotal
                nMontoCanSaldo :=
                    pr_pagos_prestamos.F_SALDO_TOTAL_OPERACIONES (
                        p_empresa      => pCodigo_empresa, -- Codigo de la Empresa.
                        p_no_credito   => C1.no_credito_Cancelado, -- Numero de Credito.
                        p_fecha        => pFecha_Desembolso -- Fecha de Aplicacion.
                                                           );
                vMonto_Punto15 :=
                    ROUND (NVL (nMontoCanSaldo, 0) * vimpuesto / 100, 2);
                vTotal_Punto15 :=
                    NVL (vTotal_Punto15, 0) + NVL (vMonto_Punto15, 0);
            END LOOP;
        END IF;

        RETURN vTotal_Punto15;
    END f_punto15_Cancelacion;

    PROCEDURE p_desembolso_digital (P_Cod_Empresa     IN     NUMBER,
                                    P_No_Credito      IN     NUMBER,
                                    P_AGENCIA            OUT NUMBER,
                                    P_NUM_CUENTA         OUT NUMBER,
                                    P_Nummov_Desemb      OUT NUMBER,
                                    P_ERROR              OUT VARCHAR2)
    ---RETURN BOOLEAN
    IS
        CURSOR C_Credit (EmpresaP NUMBER, CreditoP NUMBER)
        IS
            SELECT Monto_Credito, Cuenta_Desem, Codigo_Agencia
              FROM Pr_Creditos
             WHERE Codigo_Empresa = EmpresaP AND No_Credito = CreditoP;


        --In
        --P_Cod_Empresa      Number := 1;
        --P_No_Credito       Number := 1350319;
        --P_Codigo_Agencia   nUMBER := 50;
        --P_Monto_Desemb     Number := 25000;
        p_monto_comision    NUMBER;
        pMontoCancelacion   NUMBER;
        P_Tipo_Desemb       VARCHAR2 (1);                          --- := 'C';
        P_CUENTA            VARCHAR2 (30);             -- := '20051458615692';
        --Out
        P_Mensaje           VARCHAR2 (300);
        --- P_Nummov_Desemb     VARCHAR2 (50);
        P_Hacer_Commit      VARCHAR2 (1); -- := 'N';               --- Default 'N'
        ---V_MSG_ERROR         VARCHAR2 (500);

        vRow                C_Credit%ROWTYPE;
    ---vReturn             BOOLEAN;
    BEGIN
        ---declare
        --P_Cod_Empresa        NUMBER := 1;
        ---P_No_Credito       NUMBER := 1475848;
        ---P_Saldo_Credito    NUMBER := 80000;
        ---P_Msj_Error        VARCHAR2(300);



        p_monto_comision := 0;
        pMontoCancelacion := 0;
        P_Tipo_Desemb := 'C';
        P_Hacer_Commit := 'N';                         ---malmanzar 06-06-2023

        OPEN C_Credit (P_Cod_Empresa, P_No_Credito);

        FETCH C_Credit INTO vRow;

        IF C_Credit%FOUND
        THEN
            BEGIN
                pr_pkg_desembolso.Generar_Cargos_2 (P_Cod_Empresa,
                                                    P_No_Credito,
                                                    vRow.Monto_Credito,
                                                    P_Mensaje);


                p_monto_comision := pr_pkg_desembolso.Bkdesem.Monto_Cargos;
            EXCEPTION
                WHEN OTHERS
                THEN
                    p_monto_comision := 0;
            END;


            PR.PR_PKG_DESEMBOLSO.Genera_Desembolso (
                P_Cod_Empresa       => P_Cod_Empresa,
                P_No_Credito        => P_No_Credito,
                P_Codigo_Agencia    => vRow.Codigo_Agencia, ---Agencia proceso
                P_Monto_Desemb      => vRow.Monto_Credito,
                P_MONTO_COMISION    => P_MONTO_COMISION,
                pMontoCancelacion   => pMontoCancelacion,
                P_Tipo_Desemb       => P_Tipo_Desemb,
                P_CUENTA            => vRow.Cuenta_Desem,
                P_Mensaje           => P_Mensaje,
                P_Nummov_Desemb     => P_Nummov_Desemb,
                P_Hacer_Commit      => P_Hacer_Commit);


            P_AGENCIA := vRow.Codigo_Agencia;
            P_NUM_CUENTA := vRow.Cuenta_Desem;
            P_Nummov_Desemb := P_Nummov_Desemb;

            P_Descongela_Monto_Digital (
                pCodigo_Empresa   => P_Cod_Empresa,
                pCodAgencia       => vRow.Codigo_Agencia,
                pCodSistema       => 'CC',
                pnum_cuenta       => vRow.Cuenta_Desem,
                P_Documento       => P_Nummov_Desemb);



            IF P_Mensaje IS NOT NULL
            THEN
                P_ERROR :=
                    PR.PR_PKG_DESEMBOLSO.Get_Mensaje_Err (P_Mensaje, 'PR');

                ---                vReturn := FALSE;
                ROLLBACK;
                RETURN;
            END IF;
        ELSE                                      ---No_data_found pr_creditos
            P_ERROR := 'Crédito: ' || P_No_Credito || ' no encontrado';
            RETURN;
        END IF;

        CLOSE C_Credit;
    ---vReturn := TRUE;
    --RETURN vReturn;
    EXCEPTION
        WHEN OTHERS
        THEN
            ROLLBACK;
            P_ERROR :=
                   'SQLERRM: '
                || SQLERRM
                || ' -> traza: '
                || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
            RETURN;
    END;


    PROCEDURE p_reporte_desembolso (pCodigo_Empresa          NUMBER,
                                    pNo_Credito              NUMBER,
                                    pTipo_Abono              VARCHAR2,
                                    pNo_Recibo               NUMBER,
                                    pCodigo_Agencia          NUMBER,
                                    pError            IN OUT VARCHAR2)
    IS
        vReporteBlob     BLOB;
        vReportName      VARCHAR2 (100) := 'prr0040.rep';
        vConnexion       VARCHAR2 (200);
        vMasterKey       RAW (2000);
        vUsername        VARCHAR2 (30);
        vPass            VARCHAR2 (30);
        vDb              VARCHAR2 (30);
        v_IdArchivo      VARCHAR2 (2000)
            := PARAM.PARAMETRO_X_EMPRESA ('1', 'ID_ARCHIVO_DESEM', 'PR');
        vExtension       VARCHAR2 (10) := 'pdf';
        vNombrearchivo   VARCHAR2 (256);
        vParametrosRep   PR.PR_PKG_DESEMBOLSO.t_Params_Reportes
                             := PR.PR_PKG_DESEMBOLSO.t_Params_Reportes ();
        vParametroRep    PR.PR_PKG_DESEMBOLSO.t_Parametro_Reporte
                             := PR.PR_PKG_DESEMBOLSO.t_Parametro_Reporte ();
        vIndx            PLS_INTEGER := 0;
        vDirectorio      VARCHAR2 (100)
            := PARAM.PARAMETRO_X_EMPRESA ('1', 'DIR_REPORTES', 'IA'); --PA.OBT_PARAMETROS ('1', 'PR', 'DIR_PLAN_PROYECCION');

        P_ET_Recibo3     VARCHAR2 (100);

        vDocumento       VARCHAR2 (30) := 'NOTA_DESEMBOLSO';

        TblArchivo       pa.PKG_API_PKM.tDescargaList
                             := PA.PKG_API_PKM.tDescargaList ();
        l_RESULTADO      VARCHAR2 (32767);
        vSesion          NUMBER;
        vDescAgencia     PA.AGENCIA.DESCRIPCION%TYPE;
        vDescEmpresa     PA.EMPRESA.TIT_REPORTES%TYPE;

        CURSOR c_Etiqueta (p_CosSistema      IN VARCHAR2,
                           p_NombreReporte   IN VARCHAR2)
        IS
            SELECT etiqueta, UPPER (NOM_CAMPO) NOM_CAMPO
              FROM ETIQUETAS_REPORTE
             WHERE     COD_IDIOMA = 'ESPA'
                   AND COD_SISTEMA = p_CosSistema                       --'PR'
                   AND NOM_REPORTE = p_NombreReporte               --'PRR0007'
                                                    --AND NOM_CAMPO = 'ETIQ15';
                                                    ;

        TYPE tEtiqueta IS TABLE OF c_Etiqueta%ROWTYPE;

        vEtiqueta        tEtiqueta;
        
       -- v_ambiente  varchar2(150);
    BEGIN
        BEGIN
            -- Authentication
            vMasterKey := pa.Obt_Parametro_General_raw ('MKDB', 'PR');
            vUsername :=
                PA.DECIFRAR (pa.Obt_Parametro_General_raw ('DBUSR', 'PR'),
                             vMasterKey);
            vPass :=
                PA.DECIFRAR (pa.Obt_Parametro_General_raw ('DBPWD', 'PR'),
                             vMasterKey);
            vDb :=
                PA.DECIFRAR (pa.Obt_Parametro_General_raw ('DBDB', 'PR'),
                             vMasterKey);

            -- Determina el String Connection
            SELECT    vUsername
                   || '/'
                   || vPass
                   || '@'
                   || NVL (vDb, SYS_CONTEXT ('USERENV', 'SERVICE_NAME'))
              INTO vConnexion
              FROM DUAL;
        ---vConnexion := 'ia/ia@ADMQA1'; --temporalmente hasta resolver con Omar 10-06-2023
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                vConnexion := NULL;                          --'ia/ia@ADMQA1';
        END;

        BEGIN
            SELECT etiqueta
              INTO P_ET_Recibo3
              FROM ETIQUETAS_REPORTE
             WHERE     COD_IDIOMA = 'ESPA'
                   AND COD_SISTEMA = 'PR'
                   AND NOM_REPORTE = 'PRR0040'
                   AND NOM_CAMPO = 'RECIBO3';
        EXCEPTION
            WHEN OTHERS
            THEN
                P_ET_Recibo3 := 'Desembolso';
        END;

        -- Ejecutar el Oracle Report
        BEGIN
            -- Nota de Desembolso
            vReportName := 'prr0040.rep';
            vParametrosRep.DELETE;
            vIndx := vIndx + 1;
            vParametroRep.Nombre := 'PG_Cod_Empresa';
            vParametroRep.Valor := '"' || pCodigo_Empresa || '"';
            vParametrosRep.EXTEND;
            vParametrosRep (vIndx) := vParametroRep;
            vIndx := vIndx + 1;
            vParametroRep.Nombre := 'PG_COD_AGENCIA';
            vParametroRep.Valor := '"' || pCodigo_Agencia || '"';
            vParametrosRep.EXTEND;
            vParametrosRep (vIndx) := vParametroRep;
            vIndx := vIndx + 1;
            vParametroRep.Nombre := 'P_ET_Recibo3';
            vParametroRep.Valor := '"' || P_ET_Recibo3 || '"';
            vParametrosRep.EXTEND;
            vParametrosRep (vIndx) := vParametroRep;
            vIndx := vIndx + 1;
            vParametroRep.Nombre := 'PTIPO_ABONO';
            vParametroRep.Valor := '"' || PTIPO_ABONO || '"';
            vParametrosRep.EXTEND;
            vParametrosRep (vIndx) := vParametroRep;
            vIndx := vIndx + 1;
            vParametroRep.Nombre := 'PIDENTIFICACION';
            vParametroRep.Valor := '"' || pNo_Recibo || '"';
            vParametrosRep.EXTEND;
            vParametrosRep (vIndx) := vParametroRep;
            vIndx := vIndx + 1;
            vParametroRep.Nombre := 'PRECIBO_CAJA';
            vParametroRep.Valor := '"' || pNo_Recibo || '"';
            vParametrosRep.EXTEND;
            vParametrosRep (vIndx) := vParametroRep;
            vIndx := vIndx + 1;
            vParametroRep.Nombre := 'PNO_CREDITO';
            vParametroRep.Valor := '"' || PNO_CREDITO || '"';
            vParametrosRep.EXTEND;
            vParametrosRep (vIndx) := vParametroRep;

            vReporteBlob :=
                Generar_Reporte (p_NombreReporte   => vReportName,
                                 p_Conexion        => vConnexion,
                                 p_Parametros      => vParametrosRep,
                                 p_Error           => pError);
        EXCEPTION
            WHEN OTHERS
            THEN
                pError :=
                       'Error generando el reporte '
                    || vReportName
                    || ' del crédito '
                    || pNo_Credito
                    || ' '
                    || SQLERRM
                    || ' '
                    || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
                RAISE_APPLICATION_ERROR (-20100, pError);
        END;

        DBMS_OUTPUT.PUT_LINE (
               vReportName
            || ' LENGTH (vReporteBlob) = '
            || LENGTH (vReporteBlob));

        IF LENGTH (vReporteBlob) > 0
        THEN
            vDocumento := 'NOTA_DESEMBOLSO';
            vNombrearchivo :=
                   pNo_Credito
                || '_'
                || vDocumento
                || '_'
                || TO_CHAR (SYSDATE, 'DD-MM-YYYY-HH-MI-SS')
                || '.'
                || vExtension;

            -- Crear el archivo PDF
            BEGIN
                PA.PKG_REPORTS.EscribeArchivo (pblobdata    => vReporteBlob,
                                               pdirectory   => vDirectorio,
                                               pfilename    => vNombreArchivo);
            EXCEPTION
                WHEN OTHERS
                THEN
                    pError :=
                           'Error creando el archivo '
                        || vDirectorio
                        || ' '
                        || vNombreArchivo
                        || ' '
                        || SQLERRM
                        || ' '
                        || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
                    RAISE_APPLICATION_ERROR (-20100, pError);
            END;

            v_Idarchivo :=
                PARAM.PARAMETRO_X_EMPRESA ('1', 'ID_ARCHIVO_DESEM', 'PR');

            ---Envío a FileFlow
            
            
--            SELECT GLOBAL_NAME INTO v_ambiente FROM  GLOBAL_NAME;
--            
--            IF v_ambiente  NOT IN ('ADMQA1', 'QADEMI02') THEN  --temp
            
            BEGIN
                PR_PKG_DESEMBOLSO.p_envia_archivo_FileFlow (pNo_Credito,
                                                            vNombreArchivo,
                                                            '2',
                                                            v_Idarchivo,
                                                            pError);
            EXCEPTION
                WHEN OTHERS
                THEN
                    pError :=
                           'Error generando enviando archivo a FileFlow '
                        || vNombreArchivo
                        || ' del crédito '
                        || pNo_Credito
                        || ' '
                        || SQLERRM
                        || ' '
                        || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
                    RAISE_APPLICATION_ERROR (-20100, pError);
            END;
          ---  END IF;

            TblArchivo.EXTEND;
            TblArchivo (1).id := v_Idarchivo;
            TblArchivo (1).Name := vNombreArchivo;
            TblArchivo (1).FilePath := vDirectorio;
            TblArchivo (1).DirectoryName := vDirectorio;
            TblArchivo (1).Extension := '.pdf';
        ELSE
            pError :=
                   'Error Generando el reporte de la Nota del Desembolso'
                || vNombreArchivo
                || ' del crédito '
                || pNo_Credito
                || ' '
                || SQLERRM
                || ' '
                || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
            RAISE_APPLICATION_ERROR (-20100, pError);
        END IF;



        BEGIN
            --  Genera la projectos de la tabla de pagos
            Genera_Pagos_Proyectado (pEmpresa     => pCodigo_Empresa,
                                     pNoCredito   => PNO_CREDITO,
                                     pSesion      => vSesion);

            -- Tabla de Pagos Proyeccion
            vReportName := 'prr0007.rep';

            vIndx := 0;
            vParametrosRep.DELETE;
            vDescEmpresa := PA.OBT_DESCRIPCION_EMPRESA (pCodigo_Empresa);
            vDescAgencia :=
                PA.OBT_DESCRIPCION_AGENCIA (pCodigo_Empresa, pCodigo_Agencia);

            vIndx := vIndx + 1;
            vParametroRep.Nombre := 'PG_Cod_Empresa';
            vParametroRep.Valor := '"' || pCodigo_Empresa || '"';
            vParametrosRep.EXTEND;
            vParametrosRep (vIndx) := vParametroRep;
            vIndx := vIndx + 1;
            vParametroRep.Nombre := 'PG_Tit_Empresa';
            vParametroRep.Valor := '"' || vDescEmpresa || '"';
            vParametrosRep.EXTEND;
            vParametrosRep (vIndx) := vParametroRep;
            vIndx := vIndx + 1;
            vParametroRep.Nombre := 'PG_Tit_Agencia';
            vParametroRep.Valor := '"' || vDescAgencia || '"';
            vParametrosRep.EXTEND;
            vParametrosRep (vIndx) := vParametroRep;
            vIndx := vIndx + 1;
            vParametroRep.Nombre := 'PG_Tit_Sistema';
            vParametroRep.Valor := '"Administración de Préstamos"';
            vParametrosRep.EXTEND;
            vParametrosRep (vIndx) := vParametroRep;
            vIndx := vIndx + 1;
            vParametroRep.Nombre := 'PG_Tit_Reporte';
            vParametroRep.Valor := '"TABLA DE PAGOS PROYECTADA"';
            vParametrosRep.EXTEND;
            vParametrosRep (vIndx) := vParametroRep;
            vIndx := vIndx + 1;
            vParametroRep.Nombre := 'P_No_Credito';
            vParametroRep.Valor := '"' || PNO_CREDITO || '"';
            vParametrosRep.EXTEND;
            vParametrosRep (vIndx) := vParametroRep;
            vIndx := vIndx + 1;
            vParametroRep.Nombre := 'P_Sesion';
            vParametroRep.Valor := '"' || vSesion || '"';
            vParametrosRep.EXTEND;
            vParametrosRep (vIndx) := vParametroRep;

            OPEN c_Etiqueta ('PR', 'PRR0007');

            LOOP
                FETCH c_Etiqueta BULK COLLECT INTO vEtiqueta LIMIT 500;

                FOR i IN 1 .. vEtiqueta.COUNT
                LOOP
                    vIndx := vIndx + 1;
                    vParametroRep.Nombre :=
                        'P_ET_' || vEtiqueta (i).NOM_CAMPO;
                    vParametroRep.Valor :=
                        '"' || vEtiqueta (i).etiqueta || '"';
                    vParametrosRep.EXTEND;
                    vParametrosRep (vIndx) := vParametroRep;
                END LOOP;

                EXIT WHEN c_Etiqueta%NOTFOUND;
            END LOOP;

            CLOSE c_Etiqueta;

            vReporteBlob :=
                Generar_Reporte (p_NombreReporte   => vReportName,
                                 p_Conexion        => vConnexion,
                                 p_Parametros      => vParametrosRep,
                                 p_Error           => pError);
        EXCEPTION
            WHEN OTHERS
            THEN
                pError :=
                       'Error generando el reporte '
                    || vReportName
                    || ' del crédito '
                    || pNo_Credito
                    || ' '
                    || SQLERRM
                    || ' '
                    || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
                RAISE_APPLICATION_ERROR (-20100, pError);
        END;

        vDocumento := 'TABLA_PAGOS_PROYECTADOS';
        vNombrearchivo :=
               pNo_Credito
            || '_'
            || vDocumento
            || '_'
            || TO_CHAR (SYSDATE, 'DD-MM-YYYY-HH-MI-SS')
            || '.'
            || vExtension;

        IF LENGTH (vReporteBlob) > 0
        THEN
            -- Crear el archivo PDF
            BEGIN
                PA.PKG_REPORTS.EscribeArchivo (pblobdata    => vReporteBlob,
                                               pdirectory   => vDirectorio,
                                               pfilename    => vNombreArchivo);
            EXCEPTION
                WHEN OTHERS
                THEN
                    pError :=
                           'Error creando el archivo '
                        || vDirectorio
                        || ' '
                        || vNombreArchivo
                        || ' '
                        || SQLERRM;
                    RAISE_APPLICATION_ERROR (-20100, pError);
            END;

            v_Idarchivo :=
                PARAM.PARAMETRO_X_EMPRESA ('1', 'ID_ARCHIVO_PAGPROY', 'PR');


--
--	   
--	   SELECT GLOBAL_NAME INTO v_ambiente FROM  GLOBAL_NAME;
--            
--            IF v_ambiente NOT IN ('ADMQA1', 'QADEMI02') THEN  --temp
            ---Envío a FileFlow
            
            
            BEGIN
                PR_PKG_DESEMBOLSO.p_envia_archivo_FileFlow (pNo_Credito,
                                                            vNombreArchivo,
                                                            '2',
                                                            v_Idarchivo,
                                                            pError);
            EXCEPTION
                WHEN OTHERS
                THEN
                    pError :=
                           'Error generando enviando archivo a FileFlow '
                        || vNombreArchivo
                        || ' del crédito '
                        || pNo_Credito
                        || ' '
                        || SQLERRM
                        || ' '
                        || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
                    RAISE_APPLICATION_ERROR (-20100, pError);
            END;

           --END IF;
            TblArchivo.EXTEND;
            TblArchivo (2).id := v_Idarchivo;
            TblArchivo (2).Name := vNombreArchivo;
            TblArchivo (2).FilePath := vDirectorio;
            TblArchivo (2).DirectoryName := vDirectorio;
            TblArchivo (2).Extension := '.pdf';
        ELSE
            pError :=
                   'Error Generando el reporte de la Tabla de pagos proyectados'
                || vNombreArchivo
                || ' del crédito '
                || pNo_Credito
                || ' '
                || SQLERRM
                || ' '
                || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
            RAISE_APPLICATION_ERROR (-20100, pError);
        END IF;


        /* Envio documentos firmados*/
        BEGIN
            PR.PKG_SOLIC_DOC_FIRMADOS.ProcesarSolicitud (
                pCodigo_Empresa   => pCodigo_Empresa,
                pNo_Credito       => pNo_Credito,
                pArchivos         => TblArchivo,
                pResultado        => l_RESULTADO);
        EXCEPTION
            WHEN OTHERS
            THEN
                pError :=
                       'Error Procesando Documentos Firmados '
                    || vNombreArchivo
                    || ' del crédito '
                    || pNo_Credito
                    || ' '
                    || SQLERRM
                    || ' '
                    || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
                RAISE_APPLICATION_ERROR (-20100, pError);
        END;
    END;

    PROCEDURE P_Descongela_Monto_Digital (
        pCodigo_Empresa   NUMBER,
        pCodAgencia       NUMBER,                        --:b_cta.cod_agencia,
        pCodSistema       VARCHAR2,
        pnum_cuenta       cc.cuenta_efectivo.num_cuenta%TYPE,
        --pMontoMovimiento   cc.movimto_diario.mon_movimiento%TYPE,
        P_Documento       Movimto_Diario.Num_Documento%TYPE --- Excello:JPH:2019-11-13:REQ_83180: Nuevo Parametro
                                                           )
    ---pNumCongelamiento Number)
    IS
        CURSOR c_cuenta IS
            SELECT cod_producto, cod_agencia, ind_pag_interes
              FROM cuenta_efectivo
             WHERE cod_empresa = pCodigo_Empresa AND num_cuenta = pnum_cuenta;

        V_cuenta               c_cuenta%ROWTYPE;
        vfechacal              DATE := pa.fecha_actual_calendario ('CC', 1, 0);

        vNumMovtoD             NUMBER;

        vMonto_Congelado       CONGELAMIENTOS.MON_CONGELADO%TYPE; --- 09-06-2023
        v_FEC_FINAL            DATE;                             -- 09-06-2023

        vErrAplic              NUMBER (2);
        vCodError              VARCHAR2 (6);
        vSecCongel             NUMBER (8);
        v_Usuario              VARCHAR2 (30) := USER;

        vsubtransac            VARCHAR2 (300);

        form_trigger_failure   EXCEPTION;
    BEGIN
        BEGIN
            SELECT sec_congela, mon_congelado, FEC_FINAL
              INTO vSecCongel, vMonto_Congelado, v_FEC_FINAL
              FROM congelamientos
             WHERE     fec_inicio = vfechacal
                   AND Num_Cuenta = pnum_cuenta
                   AND SEC_CONGELA =
                       (SELECT MAX (sec_congela)
                          FROM congelamientos
                         WHERE     Num_Cuenta = pnum_cuenta
                               AND fec_inicio = vfechacal);

            IF v_FEC_FINAL IS NULL
            THEN ---El desembolso no coloca la fecha y es tomada en consideracion en aplica movimiento de cc_mov_ivr
                UPDATE congelamientos
                   SET FEC_FINAL = FEC_INICIO
                 WHERE Num_Cuenta = pnum_cuenta AND sec_congela = vSecCongel;
            END IF;
        END;

        BEGIN
            OPEN c_cuenta;

            FETCH c_cuenta INTO v_cuenta;

            CLOSE c_cuenta;

            vsubtransac :=
                obt_parametros (pCodigo_Empresa,
                                'CC',
                                'SUBTIP_DESCONG_AUTOM'); --,p_cierre.cCodIdioma,);

            -- Se agrega el movimiento diario
            CCMOV.Agrega_Movimiento (pCodigo_Empresa,
                                     pCodAgencia,        --:b_cta.cod_agencia,
                                     pCodSistema,
                                     pnum_cuenta,         --:b_cta.num_cuenta,
                                     v_cuenta.cod_producto, --:b_cta.cod_producto,
                                     96,
                                     vsubtransac, --4, ---5, 09-06-2023                                 --:b_desc.subtip_transacc,
                                     v_usuario,
                                     vfechacal,      --:b_desc.fec_movimiento,
                                     P_Documento,
                                     vMonto_Congelado,     --pMontoMovimiento,
                                     'Descongelamiento  Digital', --:b_desc.descripcion,
                                     pCodSistema,
                                     0,
                                     'N',         --:variables.apl_cargo_desc,
                                     vNumMovtoD);
        EXCEPTION
            WHEN OTHERS
            THEN
                vCodError := '000044';
                RAISE form_trigger_failure;
        END;


        BEGIN
            -- Se aplica el movimiento
            CCMOV.Aplica_Movimiento (vNumMovtoD,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     vSecCongel,
                                     vErrAplic,
                                     vCodError,
                                     NULL);
            DBMS_OUTPUT.put_line (
                   'Linea '
                || $$plsql_line
                || ' vCodError '
                || vCodError
                || ' vErrAplic '
                || vErrAplic);

            IF (vCodError <> '000005')
            THEN
                DBMS_OUTPUT.put_line (
                       'Linea '
                    || $$plsql_line
                    || ' vCodError '
                    || vCodError
                    || ' vErrAplic '
                    || vErrAplic);

                -- Se elimina el movimiento diario de "agrega_movimiento"
                DELETE movimto_diario
                 WHERE num_movto_d = vNumMovtoD;
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                DBMS_OUTPUT.put_line ('sqlerrm ' || SQLERRM);
        END;
    EXCEPTION
        WHEN form_trigger_failure
        THEN
            DBMS_OUTPUT.put_line (
                'Linea ' || $$plsql_line || 'sqlerrm ' || SQLERRM);
            ROLLBACK;
            RETURN;
    END P_Descongela_Monto_Digital;

    PROCEDURE p_envia_archivo_FileFlow (p_No_Credito        IN     NUMBER,
                                        P_NombreArchivo     IN     VARCHAR2,
                                        P_IdAplication      IN     VARCHAR2,
                                        P_IdTipoDocumento   IN     VARCHAR2,
                                        pError                 OUT VARCHAR2)
    IS
        vUsuario         VARCHAR2 (30)
            := NVL (
                   PA.PARAM.PARAMETRO_X_EMPRESA ('1',
                                                 'USUARIO_API_PKM',
                                                 'IA'),
                   'api');
                   
             
                   
        vPass            VARCHAR2 (30)
            := NVL (
                   PA.PARAM.PARAMETRO_X_EMPRESA ('1',
                                                 'PASSWORD_API_PKM',
                                                 'IA'),
                   'A123456789');
                   
  
                   
        vToken           VARCHAR2 (4000);
        vDirOracle       VARCHAR2 (300) := 'RPT_REGULATORIOS';
        vFilename        VARCHAR2 (256) := P_NombreArchivo;
        vFileData        BLOB;
        vAplicacionPkm   VARCHAR2 (2) := '2';
        vTipoDocPKM      VARCHAR2 (30)
            := NVL (
                   P_IdTipoDocumento,
                   PARAM.PARAMETRO_X_EMPRESA ('1', 'ID_ARCHIVO_DESEM', 'PR'));
        vNoCredito       VARCHAR2 (300) := p_No_Credito;
        vProductoAnt     VARCHAR2 (300) := NULL;

        v_URL            VARCHAR2 (4000);
        v_Body           BLOB;
        v_multipart      apex_web_service.t_multipart_parts;
        v_response       CLOB;
        vError           VARCHAR2 (4000);
    BEGIN
    DBMS_OUTPUT.PUT_LINE ( 'vUsuario = ' || vUsuario ); -- PRUEBA     
    DBMS_OUTPUT.PUT_LINE ( 'vPass = ' || vPass );       -- PRUEBA  
    
    
    
        vToken := IA.PKG_API_PKM.Obtener_Token (vUsuario, vPass);
        
        DBMS_OUTPUT.PUT_LINE ('vToken = ' || vToken);

        IF vToken IS NOT NULL
        THEN
            BEGIN
                v_URL :=
                       PA.PARAM.PARAMETRO_X_EMPRESA ('1',
                                                     'URL_API_PKM',
                                                     'PA')
                    || 'fcwebapi/V2/apps/49/index/create?token='
                    || vToken
                    || '='
                    || vAplicacionPkm
                    || '='
                    || vNoCredito
                    || '='
                    || vTipoDocPKM
                    || CASE
                           WHEN vProductoAnt IS NOT NULL
                           THEN
                               '=1129760'
                           ELSE
                               ''
                       END
                    || '='
                    || CASE
                           WHEN vProductoAnt IS NOT NULL THEN 'Represtamo'
                           ELSE 'Normal'
                       END;
                       
                DBMS_OUTPUT.PUT_LINE ('v_URL = ' || v_URL);

                -- Set Headers
                APEX_WEB_SERVICE.g_request_headers.delete ();
                APEX_WEB_SERVICE.g_request_headers (1).name := 'Content-Type';
                APEX_WEB_SERVICE.g_request_headers (1).VALUE :=
                    'multipart/form-data';

                vFileData := ReadFileToBlob (vFilename, vDirOracle, vError);
                
                DBMS_OUTPUT.PUT_LINE (
                    'vFileData Size = ' || LENGTH (vFileData));
                -- Body
                apex_web_service.append_to_multipart (
                    p_multipart      => v_multipart,
                    p_name           => 'Temp',
                    p_filename       => vFilename,
                    p_content_type   => 'application/pdf',
                    p_body_blob      => vFileData);

                v_Body :=
                    apex_web_service.generate_request_body (
                        p_multipart   => v_multipart);

                -- POST Response
                v_response :=
                    apex_web_service.make_rest_request (
                        p_url           => v_Url,
                        p_http_method   => 'POST',
                        p_body_blob     => v_Body);

                DBMS_OUTPUT.PUT_LINE ('v_response = ' || v_response);

                UTL_TCP.CLOSE_ALL_CONNECTIONS ();
            EXCEPTION
                WHEN OTHERS
                THEN
                    vError :=
                        SQLERRM || ' ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
                    DBMS_OUTPUT.PUT_LINE (vError);
                    UTL_TCP.CLOSE_ALL_CONNECTIONS ();
                    RAISE_APPLICATION_ERROR (-20100, vError);
            END;
        END IF;
    /* -- vIdAplication       VARCHAR2 (30) := '2';
     --vIdTipoDocumento    VARCHAR2 (30) := '1849';
     vExtension          VARCHAR2 (30) := '.pdf';
     vCodigoReferencia   VARCHAR2 (50);
 ---vNombreArchivo     varchar2(10);
 BEGIN
     ---IF p_SubirFileFlow THEN
     -- Subir documento a FileFlow
     BEGIN
         ---Carga el Reporte Automatico a FileFlow
         --vCodigoReferencia := p_No_Credito||':'||vNoCreditoAnterior||':'||vDocumento||':'||vIdTemFud;
         vCodigoReferencia := TO_CHAR (p_No_Credito);
         ---vNombreArchivo    :=
         PA.PKG_TIPO_DOCUMENTO_PKM.InsertUrlReporte (
             pCodigoReferencia   => vCodigoReferencia,
             pFechaReporte       => SYSDATE,
             pId_Aplicacion      => P_IdAplication,
             pIdTipoDocumento    => P_IdTipoDocumento,
             pOrigenPkm          => 'Normal',
             pUrlReporte         => NULL,
             pFormatoDocumento   => UPPER (vExtension),
             pNombreArchivo      => P_NombreArchivo,
             pEstado             => 'P',
             pRespuesta          => pError);
     EXCEPTION
         WHEN OTHERS
         THEN
             pError :=
                    'Error cargando reporte a FileFlow '
                 || pError
                 || ' '
                 || SQLERRM;
             RAISE_APPLICATION_ERROR (-20100, pError);
     END;
 ----END IF;*/
    END;


    PROCEDURE P_REALIZA_DESEMBOLSO_D (P_Cod_Empresa   NUMBER,
                                      P_No_Credito    NUMBER)
    IS
        ---Out
        P_Nummov_Desemb   NUMBER;
        P_ERROR           VARCHAR2 (500);
        pTipo_Abono       VARCHAR2 (1) := 'D';
        P_AGENCIA         NUMBER;
        P_NUM_CUENTA      NUMBER;
        P_EXISTE          NUMBER := 0;

        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        PR_PKG_DESEMBOLSO.p_desembolso_digital (P_Cod_Empresa,
                                                P_No_Credito,
                                                P_AGENCIA,
                                                P_NUM_CUENTA,
                                                P_Nummov_Desemb,
                                                P_ERROR);


        SELECT COUNT (*)
          INTO P_EXISTE
          FROM PR_REPORTE_DESEMBOLSO
         WHERE CODIGO_EMPRESA = P_Cod_Empresa AND NO_CREDITO = P_No_Credito;

        IF P_EXISTE = 0
        THEN
            BEGIN --malmanzar 15-01-2023, se inserta para generar documento independiente al proceso Begin
                INSERT INTO PR_REPORTE_DESEMBOLSO (CODIGO_EMPRESA,
                                                   NO_CREDITO,
                                                   CODIGO_AGENCIA,
                                                   PROCESADO,
                                                   TIPO_ABONO,
                                                   NUMMOV_DESEMB,
                                                   FECHA_ADICION,
                                                   ADICIONADO_POR)
                     VALUES (P_Cod_Empresa,
                             P_No_Credito,
                             P_AGENCIA,
                             0,
                             pTipo_Abono,
                             P_Nummov_Desemb,
                             SYSDATE,
                             USER);
            EXCEPTION
                WHEN OTHERS
                THEN
                    NULL;
            END; --malmanzar 15-01-2023, se inserta para generar documento independiente al proceso End
        ELSE
            UPDATE PR.PR_REPORTE_DESEMBOLSO d
               SET d.PROCESADO = 0, d.OBSERVACION = NULL
             WHERE     CODIGO_EMPRESA = P_Cod_Empresa
                   AND NO_CREDITO = P_No_Credito
                   AND CODIGO_AGENCIA = P_AGENCIA;
        END IF;

        COMMIT;
    /*
            BEGIN
                PR_PKG_DESEMBOLSO.p_reporte_desembolso (
                    pCodigo_Empresa   => P_Cod_Empresa,
                    pNo_Credito       => P_No_Credito,
                    pTipo_Abono       => pTipo_Abono,                      --- 'D'
                    pNo_Recibo        => P_Nummov_Desemb,
                    pCodigo_Agencia   => P_AGENCIA,
                    pError            => P_ERROR);

                COMMIT;
            EXCEPTION
                WHEN OTHERS
                THEN
                    NULL;
            END;*/
    EXCEPTION
        WHEN OTHERS
        THEN
            P_ERROR :=
                   'Error realizando el desembolso '
                || p_Error
                || ' '
                || SQLERRM;
            RAISE_APPLICATION_ERROR (-20100, P_ERROR);
    END;

    FUNCTION Generar_Reporte (p_NombreReporte   IN     VARCHAR2,
                              p_Conexion        IN     VARCHAR2,
                              p_Parametros      IN     t_Params_Reportes,
                              p_Error              OUT VARCHAR2)
        RETURN BLOB
    IS
        vExtension      VARCHAR2 (10) := 'pdf';
        vReportHost     VARCHAR2 (100)
            := PARAM.PARAMETRO_X_EMPRESA ('1', 'REPORT_HOST', 'PA'); --REPLACE(PARAM.PARAMETRO_GENERAL ('WEBLOGIC_SERVER', 'PA'), 'http://');
        vReportServer   VARCHAR2 (2000)
            := PARAM.PARAMETRO_X_EMPRESA ('1', 'REPORT_SERVER', 'PA');
        vReportBase     VARCHAR2 (2000)
            := PARAM.PARAMETRO_GENERAL ('RUTA_EJECUT_REPORTES', 'PA') || '/';
        vRespuesta      BLOB;
    BEGIN
        --- Asigna los parametros al reporte
        FOR i IN 1 .. p_Parametros.COUNT
        LOOP
            PA.PKG_REPORTS.AgregaParametro (p_Parametros (i).Nombre,
                                            p_Parametros (i).Valor,
                                            FALSE);
        END LOOP;

        -- Ejecuta el reporte y descarga el pdf
        vRespuesta :=
            PA.PKG_REPORTS.GeneraReporte (pConexion       => p_Conexion,
                                          pReportHost     => vReportHost,
                                          pReportServer   => vReportServer,
                                          pRutaBase       => vReportBase,
                                          pReporte        => p_NombreReporte,
                                          pDesFormat      => vExtension);


        RETURN vRespuesta;
    EXCEPTION
        WHEN OTHERS
        THEN
            p_Error :=
                   'Error generando el reporte '
                || p_NombreReporte
                || ' '
                || SQLERRM
                || ' '
                || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
            RETURN NULL;
    END;

    FUNCTION ReadFileToBlob (in_Filename    IN     VARCHAR2,
                             in_Directory   IN     VARCHAR2,
                             out_Error         OUT VARCHAR2)
        RETURN BLOB
    IS
        v_lob           BLOB;
        v_BFile         BFILE;
        v_src_offset    NUMBER := 1;
        v_dest_offset   NUMBER := 1;
    BEGIN
        DBMS_LOB.createtemporary (v_lob, FALSE, DBMS_LOB.SESSION);

        v_BFile := BFILENAME (in_Directory, in_Filename);

        DBMS_LOB.fileOpen (v_BFile);
        DBMS_LOB.loadblobfromfile (
            dest_lob      => v_lob,
            src_bfile     => v_BFile,
            amount        => DBMS_LOB.getLength (v_BFile),
            dest_offset   => v_dest_offset,
            src_offset    => v_src_offset);

        DBMS_LOB.fileClose (v_BFile);
        RETURN v_lob;
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_LOB.fileClose (v_BFile);
            out_Error :=
                   'Error - ReadFileToBlob '
                || SQLERRM
                || ' '
                || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
            RETURN v_lob;
    END;


    PROCEDURE Genera_Pagos_Proyectado (pEmpresa     IN     NUMBER,
                                       pNoCredito   IN     NUMBER,
                                       pSesion         OUT NUMBER)
    IS
        CURSOR c_credito (empresap NUMBER, no_creditop NUMBER)
        IS
            SELECT tip.es_cuota_multiple, per.dias_periodo, cre.*
              --  codigo_empresa,
              --         f_primer_desembolso,
              --         f_vencimiento,
              --         gracia_principal,
              --         monto_credito,
              --         ---tipo_cuota,
              --         tipo_cuota,
              --         tasa_interes,
              --         tipo_intereses,
              --         tipo_calendario,
              --         plazo
              --         es_cuota_multiple,
              --         --dias_periodo_ordinar,
              --         --cuota_ordinaria,
              --         ---ind_incluye_poliza,
              --         ---monto_credito_ordina,
              --         --Monto_Poliza,
              --         ---MONTO_CUOTAS_POLIZA,
              --         tipo_credito    ,
              --         tipo_comision
              --         --COMISION
              FROM pr_creditos cre, pr_periodicidad per, pr_tipo_credito tip
             WHERE     cre.codigo_empresa = empresap
                   AND cre.no_credito = no_creditop
                   AND cre.codigo_periodo_cuota = per.CODIGO_PERIODO
                   AND tip.codigo_empresa = cre.codigo_empresa
                   AND tip.tipo_credito = cre.tipo_credito;

        ---v_credito  c_credito%rowtype;


        --pf_apertura           DATE :=   TO_DATE ('25-03-2020', 'DD-MM-YYYY');
        --pf_vencimiento        DATE  := TO_DATE ('25-03-2021', 'DD-MM-YYYY');
        --pgracia               NUMBER :=  30;--nvl(:bkbase.gracia,0);
        --pmonto_credito        NUMBER :=  650000;--:bkbase.monto_credito;
        --ptipo_cuota           VARCHAR2(1):='N';
        --pdias_periodo_cuota   NUMBER := 30;---:bkbase.dias_periodo_cuota;
        --ptasa_interes         NUMBER := 15;-- :bkbase.tasa_interes;
        --ptipo_interes         VARCHAR2 (10) := 'V';
        --ptipo_calendario      NUMBER := 4;--:bkbase.tipo_calendario;
        --pplazo                  NUMBER := 365;--:bkbase.plazo;
        --pes_cuota_multiple     VARCHAR2(1) := 'N';
        pdias_periodo_ordinario    NUMBER := 365;             --:bkbase.plazo;
        pcuota_ordinaria           NUMBER := 1;
        pind_incluye_poliza        VARCHAR2 (1) := 'S';
        pmonto_credito_ordinario   NUMBER := 0;
        pMonto_Poliza              NUMBER := 0;        --:bkbase.monto_poliza;
        pMONTO_CUOTAS_POLIZA       NUMBER := 0;
        perror                     VARCHAR2 (300);
        --psesion               NUMBER := :variables.sesion;
        ---pfecha                date := TO_DATE ('25-03-2020', 'DD-MM-YYYY');--:bkbase.f_apertura;
        --ptipo_credito        NUMBER := 0;
        ptipo_comision             VARCHAR2 (1) := 'V';
        PCOMISION                  NUMBER := 0;
        ---v_error varchar2(300);

        Vcuota_new                 NUMBER;
        Vdias_extra                NUMBER := 0;

        Vparametro_Desem           VARCHAR2 (300)
            := Param.Parametro_X_Empresa (1, 'V_DIA_PROXIMA_CUOTA', 'PR'); --malmanzar 20-09-2024
        vparametro_extra_desem     NUMBER := 0;         --malmanzar 20-09-2024

        vsesion                    NUMBER;

        pcodempresa                VARCHAR2 (5) := '1';
        vno_credito                NUMBER := pNoCredito;            --1477362;
        v_fecha_Calendario         DATE;
    BEGIN
        v_fecha_Calendario := pa.fecha_actual_calendario ('PR', 1, 0);

        BEGIN
            SELECT SUM (MONTO_A_PAGAR)
              INTO pMonto_Poliza
              FROM PR_POLIZAS_x_CREDITO
             WHERE CODIGO_EMPRESA = pcodempresa AND NO_CREDITO = vno_credito;
        EXCEPTION
            WHEN OTHERS
            THEN
                pMonto_Poliza := 0;
        END;

        FOR x IN c_credito (pcodempresa, vno_credito)
        LOOP
            --D+6 Begin malmanzar 20-09-2024

            vparametro_extra_desem := 0;
            vparametro_extra_desem :=
                pr_plan.f_dias_extras (x.f_primer_Desembolso);

            IF     TO_CHAR (x.F_Primer_Desembolso, 'DD') >=
                   NVL (Vparametro_Desem, '35')
               AND PR.F_aplica_d_mas_6 (pcodempresa, vno_credito)
            THEN
                Vdias_Extra := vparametro_extra_desem;
            ELSE
                Vdias_Extra := 0;
            END IF;

            --D+6 End  malmanzar 20-09-2024

            ---pf_vencimiento := pf_apertura + pplazo;

            ---manejo_poliza(v_error);

            SELECT sesion.NEXTVAL INTO vsesion FROM DUAL;

            PR.pr_plan_proyeccion.ejecuta_proyeccion (
                x.codigo_empresa,
                x.no_credito,
                x.f_primer_desembolso,
                x.f_vencimiento,                         ---pf_vencimiento   ,
                x.gracia_principal,                       --pgracia          ,
                x.monto_credito,                          --pmonto_credito   ,
                x.tipo_cuota,                            ---ptipo_cuota      ,
                x.dias_periodo,
                x.tasa_interes,                         --ptasa_interes      ,
                x.tipo_intereses,                       --ptipo_interes      ,
                x.tipo_calendario,
                x.plazo,
                x.es_cuota_multiple,
                pdias_periodo_ordinario,
                pcuota_ordinaria,
                pind_incluye_poliza,
                pmonto_credito_ordinario,
                pMonto_Poliza,
                pMONTO_CUOTAS_POLIZA,
                perror,
                vsesion,
                v_fecha_Calendario,
                x.tipo_credito,
                ptipo_comision,
                PCOMISION,
                vcuota_new,
                Vdias_extra);
        ---
        --synchronize;

        --:system.message_level := 20;
        --commit;
        ---:system.message_level := 0;

        /* BEGIN  --malmanzar 25-09-2024
             UPDATE pr_plan_pagos_tmp b
                SET principal = principal + saldo_credito,
                    saldo_credito = 0
              WHERE     codigo_empresa = pcodempresa
                    AND no_credito = '1'
                    AND sesion = vsesion
                    AND no_cuota =
                        (SELECT MAX (no_cuota)
                           FROM pr_PLAN_PAGOS_Tmp a
                          WHERE     a.codigo_empresa = b.codigo_empresa
                                AND a.no_credito = b.no_credito
                                AND a.sesion = b.sesion);
           END;*/
        --malmanzar 25-09-2024


        -- :system.message_level := 20;
        -- COMMIT;
        --   :system.message_level := 0;

        END LOOP;

        pSesion := vSesion;

        DBMS_OUTPUT.put_line ('vsesion ' || vsesion);
    ---imprime_proyeccion;
    ---  ImprimirReporte('prr0013', FALSE);

    END;

    FUNCTION F_CARTERA (pcodigo_emprea NUMBER, pNo_credito NUMBER)
        RETURN VARCHAR2
    IS
        CURSOR C_DATA IS
            SELECT CASE
                       WHEN t.GRUPO_TIPO_CREDITO = 'C' THEN 'COMERCIAL'
                       WHEN t.GRUPO_TIPO_CREDITO = 'H' THEN 'HIPOTECARIO'
                       WHEN t.GRUPO_TIPO_CREDITO = 'P' THEN 'CONSUMO'
                   END
              FROM pr_creditos c, pr_tipo_Credito t
             WHERE     c.codigo_empresa = pcodigo_emprea
                   AND c.no_credito = pno_credito
                   AND c.codigo_empresa = t.codigo_empresa
                   AND c.tipo_credito = t.tipo_credito;

        v_Cartera   VARCHAR2 (30);
    BEGIN
        OPEN C_DATA;

        FETCH C_DATA INTO v_Cartera;

        CLOSE C_DATA;



        RETURN v_Cartera;
    END;



    FUNCTION f_cargos_desembolso (P_Cod_Empresa NUMBER, P_No_Credito NUMBER)
        RETURN NUMBER
    IS
        P_Saldo_Credito   NUMBER := 0;
        P_Msj_Error       VARCHAR2 (300);

        CURSOR C_DATA IS
            SELECT MONTO_CREDITO
              INTO P_Saldo_Credito
              FROM PR_CREDITOS
             WHERE     CODIGO_EMPRESA = P_Cod_Empresa
                   AND NO_CREDITO = P_No_Credito;

        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        OPEN C_DATA;

        FETCH C_DATA INTO P_Saldo_Credito;

        CLOSE C_DATA;

        pr.PR_PKG_DESEMBOLSO.GENERAR_CARGOS_2 (P_Cod_Empresa,
                                               P_No_Credito,
                                               P_Saldo_Credito,
                                               P_Msj_Error);
        COMMIT;
        RETURN NVL (Bkdesem.Monto_Cargos, 0);
    END;

    ---05-02-2025 Begin
    PROCEDURE Simula_Desembolso (
        P_Cod_Empresa      IN     NUMBER,
        P_No_Credito       IN     NUMBER,
        p_cuota              OUT    NUMBER, --23-05-2025
        P_Mensaje             OUT VARCHAR2
        )
    IS
        CURSOR C_credito IS
            SELECT *
              FROM Pr_Creditos
             WHERE     Codigo_Empresa = P_Cod_Empresa
                   AND No_Credito = P_No_Credito;

        -- Variables ---
        --- V_Descripcion          Varchar2(250);
        V_Mensaje_Error           VARCHAR2 (500);
        V_Valor2_Actual           VARCHAR2 (250);
        V_Valor_Cuota_Ant         NUMBER (16, 2);

        --
        V_Principal               NUMBER (16, 2) := 0;
        V_Interes                 NUMBER (16, 2) := 0;
        V_Comision                NUMBER (16, 2) := 0;
        V_Poliza                  NUMBER (16, 2) := 0;
        V_Cargos                  NUMBER (16, 2) := 0;

        --   Excepciones --
        Salir                     EXCEPTION;
        --
        V_Mensaje                 VARCHAR2 (250) := NULL;
        V_Existe_Cr               VARCHAR2 (1) := NULL;
        V_Ind_Cred_Univ           VARCHAR2 (1) := NULL;
        V_Oficial_Autorizado      VARCHAR2 (1) := NULL;
        V_Grupo_Tipo_Credito      VARCHAR2 (1) := NULL;
        V_Numero_Transaccion      NUMBER := 0;
        V_Saldo_Disponible        NUMBER := 0;
        V_Saldo_Actual            NUMBER := 0;
        V_Dias_Periodo_Cuota      NUMBER := 0;
        V_Dias_Periodo_Interes    NUMBER := 0;
        V_Dias_Periodo_Comision   NUMBER := 0;
        N_Error                   NUMBER := 0;
        K                         Pr_Creditos%ROWTYPE;
        Cuenta_C                  Cuenta_Efectivo.Num_Cuenta%TYPE;
        Vclientereferente         Cuenta_Efectivo.Cod_Cliente%TYPE;
        P_Fecha_Desemb            DATE       := pa.fecha_actual_calendario ('PR', 1, 0);
        p_fecha_vence             DATE;    
        V_PLAZO                   NUMBER;   
        v_cuota                   NUMBER := 0;
        vdias_extra               NUMBER := 0;          --malmanzar 2020-04-15
        vparametro_desem          VARCHAR2 (300)
            := param.PARAMETRO_X_EMPRESA (1, 'V_DIA_PROXIMA_CUOTA', 'PR');
        vSaldo_Disponible         NUMBER;
    BEGIN
      
        -- Inicializacion de arreglos ---
        /* BBkcredit.redit.Delete;
         Bkdesem.Delete;*/
        Pbkcargo.Delete;

        OPEN C_credito;

        FETCH C_credito INTO K;

        IF C_credito%FOUND
        THEN
            V_Existe_Cr := 'S';
        END IF;

        CLOSE C_credito;


                 p_fecha_vence := ADD_MONTHS(P_Fecha_Desemb, K.plazo_segun_unidad); --12-02-2025
                 
                 v_plazo := (p_fecha_vence - p_fecha_desemb) +1; ---12-02-2025

        IF NVL (V_Existe_Cr, 'N') = 'S'
        THEN
            -- Carga Parametos Operacionales --
            Obtiene_Parametros (V_Mensaje);

            IF V_Mensaje IS NOT NULL
            THEN
                RAISE Salir;
            END IF;



            Bkcredit.Numero_Cf := K.Numero_Cf;
            Bkcredit.Codigo_Empresa := K.Codigo_Empresa;
            Bkcredit.Codigo_Agencia := K.Codigo_Agencia;
            Bkcredit.Estado := K.Estado;
            Bkcredit.Es_Linea_Credito := K.Es_Linea_Credito;
            Bkcredit.Tipo_Linea := K.Tipo_Linea;
            Bkcredit.Codigo_Cliente := K.Codigo_Cliente;
            Bkcredit.Manejo := K.Manejo;
            Bkcredit.Tipo_Intereses := K.Tipo_Intereses;
            Bkcredit.Tipo_Calendario := K.Tipo_Calendario;
            Bkcredit.Tipo_Cuota := K.Tipo_Cuota;
            Bkcredit.Codigo_Periodo_Intereses := K.Codigo_Periodo_Intereses;
            Bkcredit.Periodo_Comision_Normal := K.Periodo_Comision_Normal;
            Bkcredit.Comision_Normal := K.Comision_Normal;
            Bkcredit.Cuota := K.Cuota;
            Bkcredit.Monto_Desembolsado := K.Monto_Desembolsado;
            Bkcredit.Monto_Pagado_Principal := K.Monto_Pagado_Principal;
            Bkcredit.Monto_Pagado_Intereses := K.Monto_Pagado_Intereses;
            Bkcredit.Monto_Revalorizacion := K.Monto_Revalorizacion;
            Bkcredit.Plazo := K.Plazo;
            Bkcredit.No_Solicitud := K.No_Solicitud;
            Bkcredit.Tasa_Interes := K.Tasa_Interes;
            Bkcredit.Gracia_Principal := K.Gracia_Principal;
            Bkcredit.Gracia_Mora := K.Gracia_Mora;
            Bkcredit.Periodos_Gracia_Principal := K.Periodos_Gracia_Principal;
            Bkcredit.Codigo_Origen := K.Codigo_Origen;
            Bkcredit.Codigo_Nivel_Aprobacion := K.Codigo_Nivel_Aprobacion;
            Bkcredit.F_Ultimo_Pago_Principal := K.F_Ultimo_Pago_Principal;
            Bkcredit.F_Ultimo_Pago_Intereses := K.F_Ultimo_Pago_Intereses;
            Bkcredit.F_Primer_Desembolso := K.F_Primer_Desembolso;
            Bkcredit.F_Ultimo_Desembolso := K.F_Ultimo_Desembolso;
            Bkcredit.F_Proxima_Comision := K.F_Proxima_Comision;
            Bkcredit.F_Aprobacion := K.F_Aprobacion;
            Bkcredit.F_Ultimo_Pago_Mora := K.F_Ultimo_Pago_Mora;
            Bkcredit.F_Reconocim_Intereses := K.F_Reconocim_Intereses;
            Bkcredit.F_Principal_Anterior := K.F_Principal_Anterior;
            Bkcredit.F_Intereses_Anterior := K.F_Intereses_Anterior;
            Bkcredit.F_Mora_Anterior := K.F_Mora_Anterior;
            Bkcredit.F_Ultima_Revalorizacion := K.F_Ultima_Revalorizacion;
            Bkcredit.Cuenta_Abono := K.Cuenta_Abono;
            --Bkcredit.Tipo_Desembolso := p_tipo_desemb; --  K.Tipo_Desembolso  ;   ---malmanzar 2020-04-16
            Bkcredit.Cuenta_Desem := K.Cuenta_Desem;
            Bkcredit.Observaciones1 := K.Observaciones1;
            Bkcredit.Observaciones2 := K.Observaciones2;
            Bkcredit.Codigo_Sub_Aplicacion := K.Codigo_Sub_Aplicacion;
            Bkcredit.Tipo_Comision := K.Tipo_Comision;
            Bkcredit.F_Ultimo_Pago_Comision := K.F_Ultimo_Pago_Comision;
            Bkcredit.F_Pago_Comision_Atrasada := K.F_Pago_Comision_Atrasada;
            Bkcredit.F_Pago_Cobro_Administrativo :=
                K.F_Pago_Cobro_Administrativo;
            Bkcredit.No_Credito := K.No_Credito;
            Bkcredit.No_Credito_Origen := K.No_Credito_Origen;
            Bkcredit.Monto_Credito := K.Monto_Credito;
            Bkcredit.F_Apertura := K.F_Apertura;
            Bkcredit.F_Vencimiento := K.F_Vencimiento;
            Bkcredit.F_Cancelacion := K.F_Cancelacion;
            Bkcredit.F_Adjudicacion := K.F_Adjudicacion;
            Bkcredit.F_Ultima_Revision := K.F_Ultima_Revision;
            Bkcredit.Tipo_Credito := K.Tipo_Credito;
            Bkcredit.Codigo_Moneda := K.Codigo_Moneda;
            Bkcredit.Dia_Pago := K.Dia_Pago;
            Bkcredit.Intereses_Anticipados := K.Intereses_Anticipados;
            Bkcredit.Descuenta_Intereses_Desembolso :=
                K.Descuenta_Intereses_Desembolso;
            Bkcredit.Cantidad_Cuotas_Descontar := K.Cantidad_Cuotas_Descontar;
            Bkcredit.No_Poliza_Bco := K.No_Poliza_Bco;
            Bkcredit.Codigo_Referente := K.Codigo_Referente;
            Bkcredit.Plazo := K.Plazo;
            Bkcredit.Plazo_Segun_Unidad := K.Plazo_Segun_Unidad;
            Bkcredit.Codigo_sub_aplicacion := k.Codigo_sub_aplicacion;
            bkcredit.monto_Credito := K.MONTO_CREDITO;

            --dbms_output.put_line('Bkcredit.Codigo_sub_aplicacion '||Bkcredit.Codigo_sub_aplicacion);


            --- Busqueda datos relacionados al credito --
            P_Datos_Adicionales_Credito (Bkcredit.Codigo_Empresa,
                                         Bkcredit.No_Credito,
                                         V_Ind_Cred_Univ,
                                         V_Oficial_Autorizado,
                                         V_Grupo_Tipo_Credito,
                                         V_Saldo_Disponible,
                                         V_Saldo_Actual,
                                         V_Dias_Periodo_Cuota,
                                         V_Dias_Periodo_Interes,
                                         V_Dias_Periodo_Comision,
                                         V_Mensaje);

            IF V_Mensaje IS NOT NULL
            THEN
                RAISE Salir;
            END IF;

            --
            --Bkdesem.Monto_Cancelacion := NVL (pMontoCancelacion, 0); --malmanzar 14-02-2023 req. 3709
            --
            Bkcredit.Ind_Credito_Universitario := V_Ind_Cred_Univ;
            Bkcredit.Oficial_Autorizado := V_Oficial_Autorizado;
            Bkcredit.Grupo_Tipo_Credito := V_Grupo_Tipo_Credito;
            Bkcredit.Saldo_Disponible := V_Saldo_Disponible;
            Bkcredit.Saldo_Actual := V_Saldo_Actual;
            Bkcredit.Dias_Periodo_Cuota := V_Dias_Periodo_Cuota;
            Bkcredit.Dias_Periodo_Interes := V_Dias_Periodo_Interes;
            Bkcredit.Dias_Periodo_Comision := V_Dias_Periodo_Comision;

            --- Datossobre  tipo de Credito asociado  --
            BEGIN
                SELECT NVL (Es_Cuota_Multiple, 'N'),
                       NVL (Multiples_Desembolsos, 'N'),
                       Ind_Es_Reserva
                  INTO Bkcredit.Es_Cuota_Multiple,
                       Bkcredit.Multiples_Desembolsos,
                       Bkcredit.Es_Reserva
                  FROM Pr_Tipo_Credito
                 WHERE     Codigo_Empresa = Bkcredit.Codigo_Empresa
                       AND Tipo_Credito = Bkcredit.Tipo_Credito; ---malmanzar 2020-04-16 error bkcredit.no_credito
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    Bkcredit.Es_Cuota_Multiple := 'N';
                    Bkcredit.Multiples_Desembolsos := 'N';
                    Bkcredit.Es_Reserva := NULL;
            END;

            --- Pre validaciones del credito antes de cargar datos del deembolso
            Prevalida_Credito (V_Mensaje);

            IF V_Mensaje IS NOT NULL
            THEN
                RAISE Salir;
            END IF;

 
            ----
            -- Adigna Valor cuota actuual ---
            V_Valor_Cuota_Ant := Bkcredit.Cuota;


            --Funcionalidad desembolso d+6 / malmanzar 2020-04-16


            IF     TO_CHAR (P_Fecha_Desemb, 'DD') >=
                   NVL (vparametro_desem, '35')
               AND PR.F_aplica_d_mas_6 (Bkcredit.Codigo_Empresa,
                                        BKCredit.no_credito)
            THEN         --funcion que determina si aplica para D+6 31-08-2018
                ---
                vdias_extra :=
                    pr_plan.f_dias_extras (P_Fecha_Desemb);
            ---
            ELSE
                ---
                vdias_extra := 0;
            END IF;
            
            
            
            
--            p_depura(   'FECHA_DESEMBOLSO: '||    P_Fecha_Desemb);
--            p_depura(   'f_vencimiento: '||    p_fecha_vence); 
--            p_depura(   'gracia_principal: '||    BKCredit.gracia_principal); 
--            p_depura(   'monto_credito: '||    BKCredit.monto_credito); 
--            p_depura(   'tipo_cuota: ' ||   BKCredit.tipo_cuota);
--            p_depura(   'dias_periodo_cuota: '||    BKCredit.dias_periodo_cuota);
--            p_depura(   'tasa_interes: '   || BKCredit.tasa_interes); 
--            p_depura(   'tipo_intereses: '   || BKCredit.tipo_intereses);
--            p_depura(   'tipo_calendario: ' ||   BKCredit.tipo_calendario);
--            p_depura(   'plazo: ' ||  v_plazo);
            ---p_depura(   'FECHA_DESEMBOLSO: '  ||  BKDesem.FECHA_DESEMBOLSO);
            
            
                       
            
            BKCredit.cuota :=
                pr.pr_pkg_cuota.fn_calcula_cuota (
                    pf_primer_desem           => P_Fecha_Desemb, --:BKCredit.f_apertura,-- Date,
                    pf_vencimiento            => p_fecha_vence,--BKCredit.f_vencimiento, -- Date,
                    pgracia_principal         => BKCredit.gracia_principal, -- Number,       -- en dias
                    psaldo_real               => BKCredit.monto_credito, --  monto_desembolsado, -- Number,       -- := 50000;--,  06-02-2025
                    ptipo_cuota               => BKCredit.tipo_cuota, -- Varchar2,     --'N';
                    pperiodicidad             => BKCredit.dias_periodo_cuota, --vdias_periodo,-- Number,       -- := 90;
                    ptasa                     => BKCredit.tasa_interes, --- Number,       -- 44;   -- porcentaje (23, 27.5, etc)
                    ptipo_interes             => BKCredit.tipo_intereses, -- Varchar2,     --(1):= 'V';   -- (V)encido o (A)nticipado
                    ptipo_calendario          => BKCredit.tipo_calendario, -- Number,--- := 4;   -- tipos de cal: 1, 2, 3 o 4
                    pplazo_total              => v_plazo,-- BKCredit.plazo, -- Number,-- := add_months(TRUNC(SYSDATE),36) - trunc(sysdate);--,   -- en dias
                    pf_calculo                => P_Fecha_Desemb,
                    pdias_extra               => NVL (vdias_extra, 0),
                    pPeriodo_Gracia_interes   => 0);


            p_depura (
                'fnCuota: ' || bkcredit.cuota || ' Linea: ' || $$plsql_line);

            --END IF;

            IF V_Mensaje_Error IS NOT NULL
            THEN
                V_Mensaje :=
                       'Error al  recalcular cuota para el  crédito : '
                    || Bkcredit.No_Credito
                    || Get_Mensaje_Err (V_Mensaje_Error, 'PR');
                RAISE Salir;
            END IF;


            V_Valor2_Actual :=
                '|' || TO_CHAR (V_Fecha_Sist, 'DD/MM/YYYY') || '|';

            --- Manejo de cargos y descuentos ---
            V_Cargos := NVL (Bkdesem.Monto_Cargos, 0);
            V_Principal := NVL (Bkdesem.Monto_Cuota_Principal, 0);
            V_Interes := NVL (Bkdesem.Monto_Cuota_Intereses, 0);
            V_Comision := NVL (Bkdesem.Monto_Comision, 0);
            V_Poliza := NVL (Bkdesem.Monto_Poliza, 0);


            ---Begin malmanzar 15-04-2020
            v_cuota := K.cuota;
            
            p_cuota := bkcredit.cuota; --23-05-2025

            --- Actualiza el credito con el resultado de las operaciones del desembolso
        /* 23-05-2025
            UPDATE Pr_Creditos
               SET Cuota =
                       CASE
                           WHEN Bkcredit.cuota > 0 THEN Bkcredit.cuota
                           ELSE K.CUOTA
                       END,                            ---malmanzar 2020-04-15
                   Dia_Pago = Bkcredit.Dia_Pago,
                   CUOTA_ANTERIOR = V_Valor_Cuota_Ant,
                   F_Vencimiento = Bkcredit.F_Vencimiento
             WHERE     Codigo_Empresa = Bkcredit.Codigo_Empresa
                AND No_Credito = Bkcredit.No_Credito;
             */--23-05-2025   

--            IF P_Hacer_Commit = 'S'
--            THEN
--                COMMIT;
--            END IF;

            --P_Nummov_Desemb := V_Numero_Transaccion;
        ELSE
          P_Mensaje := 'Crédito no encontrado, no procede el desembolso';
        END IF;



        --
        --        P_Nummov_Desemb := V_Numero_Transaccion;
        vdias_extra := 0;
    /* EXCEPTION
         WHEN Salir
         THEN
             ROLLBACK;
             P_Mensaje := V_Mensaje;
             raise_application_error (
                 -20000,
                    SQLERRM
                 || ' -> traza: '
                 || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
             RETURN;
             */
    END Simula_Desembolso;                                      -- Fin Proceso
--05-02-2025 End


END;