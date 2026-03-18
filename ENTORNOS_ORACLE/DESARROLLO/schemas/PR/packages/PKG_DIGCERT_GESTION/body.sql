CREATE OR REPLACE PACKAGE BODY PR.pkg_digcert_proceso IS

    PROCEDURE cargar_datos_cliente(
        p_client_id IN VARCHAR2,
        p_Error OUT VARCHAR2
    ) IS
    BEGIN

    SELECT C.COD_CLIENTE,
           P.COD_PERSONA,
           P.NOMBRE,
           IP.NUM_ID,
           C.COD_OFICIAL,
           C.COD_PROMOTOR,
           C.ESTADO_CLIENTE,
           E.ESTA_ACTIVO
      INTO v_datos_cliente.client_id,
           v_datos_cliente.cod_persona,
           v_datos_cliente.nombre,
           v_datos_cliente.cedula,
           v_datos_cliente.cod_ejecutivo,
           v_datos_cliente.cod_promotor,
           v_datos_cliente.estado,
           v_datos_cliente.es_empleado
    FROM PA.PERSONAS P
    INNER JOIN PA.ID_PERSONAS IP ON P.COD_PERSONA = IP.COD_PERSONA
    INNER JOIN PA.CLIENTE C ON C.COD_CLIENTE = P.COD_PERSONA
    LEFT JOIN PA.EMPLEADOS E ON E.COD_PER_FISICA = IP.COD_PERSONA
    WHERE C.COD_CLIENTE = p_client_id;
    
    IF v_datos_cliente.es_empleado IS NULL THEN
        v_datos_cliente.es_empleado := 'N';
    END IF;
    
    IF v_datos_cliente.estado = 'I' THEN
        DBMS_OUTPUT.put_line ('Cliente inactivo: ' || p_client_id);
        p_Error := 'Cliente inactivo: ' || p_client_id;
    END IF;
    
    --DBMS_OUTPUT.PUT_LINE('Datos cargados del cliente: ');
    --DBMS_OUTPUT.PUT_LINE('Cliente id: ' || v_datos_cliente.client_id);
    --DBMS_OUTPUT.PUT_LINE('Codigo persona: ' || v_datos_cliente.cod_persona);
    --DBMS_OUTPUT.PUT_LINE('Nombre: ' || v_datos_cliente.nombre);
    --DBMS_OUTPUT.PUT_LINE('Cedula: ' ||v_datos_cliente.cedula);
    --DBMS_OUTPUT.PUT_LINE('Codigo ejecutivo: ' || v_datos_cliente.cod_ejecutivo);
    --DBMS_OUTPUT.PUT_LINE('Codigo promotor: ' || v_datos_cliente.cod_promotor);
    --DBMS_OUTPUT.PUT_LINE('Estado: ' || v_datos_cliente.estado);
    --DBMS_OUTPUT.PUT_LINE('Es empleado: ' || v_datos_cliente.es_empleado);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_datos_cliente.client_id     := NULL;
          v_datos_cliente.cod_persona   := NULL;
          v_datos_cliente.nombre        := NULL;
          v_datos_cliente.cedula        := NULL;
          v_datos_cliente.cod_ejecutivo := NULL;
          v_datos_cliente.cod_promotor  := NULL;
          v_datos_cliente.estado        := NULL;
          v_datos_cliente.es_empleado   := NULL;
          p_Error := 'No hay datos';

        WHEN OTHERS THEN
          p_Error := 'Ha ocurrido un error';
    END cargar_datos_cliente;
  
    PROCEDURE validar_lista_negra(
      p_client_id IN VARCHAR2,
      p_Error OUT VARCHAR2
    ) IS
      v_exist NUMBER;
    BEGIN
      SELECT 1 INTO v_exist
        FROM PA.LISTA_NEGRA
       WHERE COD_PERSONA = p_client_id
         AND ROWNUM = 1;
      p_Error := 'Cliente restringido por lista negra: ' || p_client_id;
      DBMS_OUTPUT.put_line ('Cliente restringido por lista negra: ' || p_client_id);
      
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
        DBMS_OUTPUT.put_line ('Cliente no restringido por lista negra: ' || p_client_id);
    END validar_lista_negra;
    
    PROCEDURE validar_lista_pep(
      p_client_id IN VARCHAR2,
      p_Error OUT VARCHAR2
    ) IS
      v_exist NUMBER;
    BEGIN
      SELECT 1 INTO v_exist
        FROM PA.LISTA_PEP
       WHERE COD_PERSONA = p_client_id
         AND ROWNUM = 1;
       p_Error := 'Cliente restringido por PEP: ' || p_client_id;
       DBMS_OUTPUT.put_line ('Cliente restringido por PEP: ' || p_client_id);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
        DBMS_OUTPUT.put_line ('Cliente no restringido por PEP: ' || p_client_id);
    END validar_lista_pep;

    PROCEDURE cargar_param_producto(
        p_cod_producto IN VARCHAR2,
        p_Error OUT VARCHAR2
        ) IS
        BEGIN
            SELECT PXE.COD_PRODUCTO,
                   PXE.MONTO_MINIMO,
                   PXE.PLAZO_MINIMO,
                   PXE.PAGA_RENTA,
                   PXE.PORCENTAJE_RENTA,
                   PXE.BASE_CALCULO,
                   PXE.BASE_PLAZO,
                   PXE.IND_PRD_EMP,
                   PXE.IND_RENOVACION_AUTO,
                   PXE.COD_CARTERA,
                   PXE.FORMA_CALCULO_INTERES,
                   PXE.FRE_CAPITALIZA,
                   PROD.COD_MONEDA,
                   PTPM.SPREAD,
                   PTPM.OPERACION,
                   PTPM.PLAZO_MINIMO,
                   PTPM.PLAZO_MAXIMO,
                   PTPM.MONTO_MINIMO,
                   PTPM.MONTO_MAXIMO,
                   PTPM.COD_TASA,
                   PTPM.TASA_MINIMA,
                   PTPM.TASA_MAXIMA
                   
           INTO v_producto.cod_producto,
                v_producto.pxe_monto_minimo,
                v_producto.pxe_plazo_minimo,
                v_producto.paga_renta,
                v_producto.porcentaje_renta,
                v_producto.base_calculo,
                v_producto.base_plazo,
                v_producto.ind_prd_emp,
                v_producto.ind_renovacion_auto,
                v_producto.cod_cartera,
                v_producto.forma_calculo_interes,
                v_producto.fre_capitaliza,
                v_producto.cod_moneda,
                --
                v_producto.spread,
                v_producto.operacion,
                v_producto.ptpm_plazo_minimo,
                v_producto.ptpm_plazo_maximo,
                v_producto.ptpm_monto_minimo,
                v_producto.ptpm_monto_maximo,
                v_producto.cod_tasa,
                v_producto.tasa_minima,
                v_producto.tasa_maxima
            FROM CD.CD_PRODUCTO_X_EMPRESA PXE
            INNER JOIN CD.CD_PRD_TASA_PLAZO_MONTO PTPM
                ON PXE.COD_PRODUCTO = PTPM.COD_PRODUCTO
            INNER JOIN PA.PRODUCTOS PROD
                ON PXE.COD_PRODUCTO = PROD.COD_PRODUCTO
            WHERE PXE.COD_PRODUCTO = p_cod_producto 
                AND PTPM.FECHA_VIGENCIA = (
                    SELECT MAX(sub.FECHA_VIGENCIA)
                    FROM CD.CD_PRD_TASA_PLAZO_MONTO sub
                    WHERE sub.COD_PRODUCTO = PTPM.COD_PRODUCTO
                      AND sub.FECHA_VIGENCIA <= SYSDATE
                      AND sub.ESTADO = 'A');
           
            p_Error := 'Carga de datos completadas exitosamente.';
           
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                p_Error := 'No exite el codigo de producto' || p_cod_producto;
                DBMS_OUTPUT.put_line ('No exite el codigo de producto' || p_cod_producto);
            
            WHEN OTHERS THEN
                p_Error := 'Ha ocurrido un error';
    END cargar_param_producto;
        
    PROCEDURE validar_param_producto(
        p_cod_producto IN VARCHAR2,
        p_plazo_dias IN NUMBER,
        p_monto IN NUMBER,
        p_Error OUT VARCHAR2
        ) IS
        BEGIN
            IF p_monto IS NULL OR p_monto < v_producto.pxe_monto_minimo THEN
                p_Error := 'Monto de apertura inválido. Debe ser mayor o igual a ' || TO_CHAR(v_producto.pxe_plazo_minimo, 'FM999,999,990.00');
            RETURN;
            END IF;
            IF p_plazo_dias IS NULL OR p_plazo_dias NOT BETWEEN v_producto.pxe_plazo_minimo AND v_producto.ptpm_plazo_maximo THEN
                p_Error := 'Plazo en días inválido. Debe estar entre ' || v_producto.pxe_plazo_minimo || ' y ' || v_producto.ptpm_plazo_maximo || ' días.';
            RETURN;
            END IF;
    END validar_param_producto;
    
    --CDUTILS
    /*
        Su propósito es calcular la cantidad de días que hay entre dos fechas.
    */
    PROCEDURE cd_calcula_dias (
        f_inicio         IN DATE,
        f_final          IN DATE,
        base_plazo       IN NUMBER,
        --p_frecuencia     IN VARCHAR2, 
        p_dias_resultado IN OUT NUMBER
    )IS
        --
        plazo NUMBER;
        f_aux DATE;
        vFec1 NUMBER(10);
        vFec2 NUMBER(10);
        --
    BEGIN
       --
       IF base_plazo = 365
       THEN
         p_dias_resultado := f_final - f_inicio;
       ELSE
         --
         vFec1 := to_number(TO_CHAR(f_inicio,'YYYY')) * 360 +
               (to_number(TO_CHAR(f_inicio,'MM')) - 1) * 30 +
                to_number(TO_CHAR(f_inicio,'DD'));
         --
         IF TO_CHAR(f_inicio,'DD') = '31' AND TO_CHAR(last_day(f_inicio),'dd') = '31'
         THEN
           vFec1 := vFec1 - 1;
         END IF;
         --
         IF to_char(f_inicio,'MM') = 2 AND TO_CHAR(f_inicio,'DD') = '28' AND TO_CHAR(last_day(f_inicio),'dd') = '28'
         THEN
           vFec1 := vFec1 + 2;
         END IF;
         --
         IF to_char(f_inicio,'MM') = 2 AND TO_CHAR(f_inicio,'DD') = '29' AND TO_CHAR(last_day(f_inicio),'dd') = '29'
         THEN
           vFec1 := vFec1 + 1;
         END IF;
         --
         vFec2    := to_number(to_char(f_final,'YYYY')) * 360 +
                    (to_number(to_char(f_final,'MM')) - 1) * 30 +
                     to_number(to_char(f_final,'DD'));
         --
         IF to_char(f_final,'DD') = '31' AND to_char(last_day(f_final),'dd') = '31'
         THEN
           vFec2 := vFec2 - 1;
         END IF;
         --
         IF to_char(f_final,'MM') = 2 AND to_char(f_final,'DD') = '28' AND to_char(last_day(f_final),'dd') = '28'
         then
           vFec2 := vFec2 + 2;
         END IF;
         --
         IF to_char(f_final,'MM') = 2 AND to_char(f_final,'DD') = '29' AND to_char(last_day(f_final),'dd') = '29'
         THEN
           vFec2 := vFec2 + 1;
         END IF;
         --
         p_dias_resultado := vFec2 - vFec1;
         --
       END IF;
       
       --DBMS_OUTPUT.PUT_LINE('Fecha final: ' || f_final);
       --DBMS_OUTPUT.PUT_LINE('Total dias: ' || p_dias_resultado);
       --DBMS_OUTPUT.PUT_LINE('Frecuencia: ' || p_frecuencia);
       
    EXCEPTION WHEN OTHERS THEN
       --message('cd_calcula_dias '|| sqlerrm);
       --message(' ');
       RETURN;
    END cd_calcula_dias;

    FUNCTION CD_FECHA_FINANCIERA(
    p_f_base          IN DATE ,
    p_tipo_calendario IN NUMBER ,
    p_dias            IN NUMBER )
    RETURN DATE IS
    BEGIN
      /* 
      ** Proposito : Regresar la fecha que tiene como resulado
      ** sumar a la fecha base los dias indicados de acuerdo al calendario
      ** Argumentos: fecha inicio, dias, calendario base
      */
      DECLARE
         v_f_resultado date;
         v_meses number;
         v_dias number;
         v_dia_resultado number;
         v_mes_resultado number;
         v_anio_resultado number;
         v_ult_dia number;
      begin
         if (p_tipo_calendario = 365) then
            -- calendario natural
            v_f_resultado := p_f_base + p_dias;
         elsif (p_tipo_calendario = 360) then
            -- calendario financiero
            if (mod(p_dias, 30) = 0) then
               v_f_resultado := add_months(p_f_base, p_dias / 30);
               if (p_f_base = last_day(p_f_base) and
                   v_f_resultado = last_day(v_f_resultado) and
                   (to_number(to_char(v_f_resultado,'DD')) >
                    to_number(to_char(p_f_base,'DD')))
                  ) then
                  v_f_resultado := to_date(to_char(p_f_base,'DD') ||
                                           to_char(v_f_resultado,'MMYYYY'),
                                           'DDMMYYYY');
               end if;
            else
               if (p_dias >= 0) then
                  v_meses := trunc(p_dias / 30);
                  v_dias := mod(p_dias, 30);
                  v_f_resultado := add_months(p_f_base, v_meses);
                  if (p_f_base = last_day(p_f_base) and
                      v_f_resultado = last_day(v_f_resultado) and
                      (to_number(to_char(v_f_resultado,'DD')) >
                       to_number(to_char(p_f_base,'DD')))
                     ) then
                     v_f_resultado := to_date(to_char(p_f_base,'DD') ||
                                              to_char(v_f_resultado,'MMYYYY'),
                                              'DDMMYYYY');
                  end if;
                  if (v_f_resultado = last_day(v_f_resultado)) then
                     v_f_resultado := v_f_resultado + v_dias;
                  else
                     -- desarma la fecha en sus partes
                     v_dia_resultado := to_number(to_char(v_f_resultado,'DD'));
                     v_mes_resultado := to_number(to_char(v_f_resultado,'MM'));
                     v_anio_resultado :=
                      to_number(to_char(v_f_resultado,'YYYY'));
                     v_ult_dia := 30;
                     -- agrega los dias que han quedado y analiza el cambio
                     -- de mes y de anio
                     v_dia_resultado := v_dia_resultado + v_dias;
                     if (v_dia_resultado > v_ult_dia) then
                        v_dia_resultado := v_dia_resultado - v_ult_dia;
                        v_mes_resultado := v_mes_resultado + 1;
                     elsif (v_mes_resultado = 2) then
                        v_ult_dia := to_number(
                         to_char(last_day(v_f_resultado),'DD'));
                        if (v_dia_resultado > v_ult_dia) then
                           v_dia_resultado := v_ult_dia;
                        end if;
                     end if;
                     if (v_mes_resultado > 12) then
                        v_mes_resultado := v_mes_resultado - 12;
                        v_anio_resultado := v_anio_resultado + 1;
                     end if;
                     -- arma la fecha de nuevo
                     v_f_resultado := to_date(
                     to_char(v_dia_resultado, '00') ||
                     to_char(v_mes_resultado, '00') ||
                     to_char(v_anio_resultado, '0000'), 'DDMMYYYY');
                  end if;
               else -- p_dias < 0
                  v_meses := -1 * trunc(abs(p_dias) / 30);
                  v_dias := mod(abs(p_dias), 30);
                  v_f_resultado := add_months(p_f_base, v_meses);
                  if (p_f_base = last_day(p_f_base) and
                      v_f_resultado = last_day(v_f_resultado) and
                      (to_number(to_char(v_f_resultado,'DD')) >
                       to_number(to_char(p_f_base,'DD')))
                     ) then
                     v_f_resultado := to_date(to_char(p_f_base,'DD') ||
                                              to_char(v_f_resultado,'MMYYYY'),
                                              'DDMMYYYY');
                  end if;
                  v_mes_resultado := to_number(to_char(v_f_resultado,'MM'));
                  if (to_char(p_f_base, 'DD') = '31' and v_dias = 1) then
                     null;
                  else
                     v_f_resultado := v_f_resultado - v_dias;
                  end if;
                  if (abs(p_dias) < 30) then
                     if (to_char(p_f_base,'DD') = '31') then
                        v_f_resultado := v_f_resultado - 1;
                     elsif (to_char(p_f_base,'MM') = '02' and
                            to_char(p_f_base,'DD') = '28') then
                        v_f_resultado := v_f_resultado + 2;
                     elsif (to_char(p_f_base,'MM') = '02' and
                            to_char(p_f_base,'DD') = '29') then
                        v_f_resultado := v_f_resultado + 1;
                     end if;
                  end if;
                  if (to_number(to_char(v_f_resultado,'DD')) = '31') then
                     v_f_resultado := v_f_resultado - 1;
                  end if;
               end if; -- restar o sumar
            end if; -- periodicidad multiplo de 30
         end if;
         --
         -- Asigna variables de salida
         --
         return(v_f_resultado);
      exception
         when others then
            --utilitarios.mensaje_error('000581',name_in('variables.codidioma'),'CD',SQLERRM);
            --raise form_trigger_failure;
            RETURN NULL; 
      end; 
    END CD_FECHA_FINANCIERA;

    -- SUMA UN MES A LA FECHA DE EMISION
    PROCEDURE CD_FECHA_EXACTA(
        p_fecha_inicial     IN DATE,
        p_calendario_base   IN NUMBER,
        p_valor             IN NUMBER, 
        p_frecuencia        IN VARCHAR2,
        p_fecha_final       OUT DATE,
        p_total_dias        OUT NUMBER
        )IS
    BEGIN
        /* PROCEDURE CD_FECHA_EXACTA
        ** Hecho por: Adrian Zuñiga Morales
        ** Fecha: 10-06-1998
        ** Proposito : Regresar la cantidad de dias y la fecha exaxtos
        ** Observacion: Este procedimiento aplica solo cuando la frecuencia
        ** del calculo es mensual, lo que se requiere es saber
        ** los dias exactos.
        ** Argumentos: fecha inicio, dias,
        */
        DECLARE
         p_Error VARCHAR2(10);
         v_valor NUMBER := 0;
        BEGIN
        --
        -- Revisa las posibles inconsistencias
        --
        IF p_valor <= 0 THEN
           p_Error := '000034'; 
        END IF;

        IF p_frecuencia NOT IN('D', 'M') THEN
           p_Error := '000033';
        END IF;

        IF p_calendario_base NOT IN(360, 365) THEN
           p_Error := 'Calendario base no es 360 ni 365';
        END IF;
        --
        -- Calculo de dias exactos y la fecha exacta
        --
        IF(p_frecuencia = 'M'AND p_calendario_base = 365) THEN
           p_fecha_final := ADD_MONTHS(p_fecha_inicial, p_valor);
           p_total_dias := p_valor;
        ELSIF (p_frecuencia = 'D'AND p_calendario_base = 365) THEN
           p_fecha_final :=(p_fecha_inicial + p_valor);
           CD_CALCULA_DIAS(p_fecha_inicial,
                           p_fecha_final,
                           p_calendario_base,
                           --p_frecuencia,
                           p_total_dias);
        ELSIF (p_frecuencia = 'D'AND p_calendario_base = 360) THEN
              p_fecha_final :=
              CD_FECHA_FINANCIERA(p_fecha_inicial,
                                  p_calendario_base,
                                  p_valor);
              p_total_dias := p_valor;
        ELSIF (p_frecuencia = 'M'AND p_calendario_base = 360) THEN
              --calcula el  numero de dias  a sumar a la fecha base, como es 360
              --y la frecuencia es Meses, estos son de 30 dias por lo que
              --los dias corresponden a multiplicar el p_valor * 30
              p_fecha_final :=CD_FECHA_FINANCIERA(p_fecha_inicial,
                                                  p_calendario_base,
                                                  p_valor*30);
        p_total_dias := p_valor;
    END IF;
    v_certificado_values.fecha_vencimiento := p_fecha_final;
    EXCEPTION
        WHEN OTHERS THEN 
            p_Error := 'Ha ocurrido un error en CD_FECHA_EXACTA';
    END;
END CD_FECHA_EXACTA;

   PROCEDURE calcular_tasas_certificado(
        p_cod_empresa     IN VARCHAR2,
        p_cod_producto    IN VARCHAR2,
        p_plazo_dias      IN NUMBER,
        p_monto           IN NUMBER,
        p_fecha_calculo   IN DATE,
        p_Error      OUT VARCHAR2
    ) IS
        v_control_obt_tasa    NUMBER;
        v_error_pkg           VARCHAR2(10);
        v_sqlcode_pkg         NUMBER;
        l_tasa_bruta_ajustada NUMBER;
    BEGIN

        -- 1. Obtener parámetros de tasa (código, spread, operación)
        v_control_obt_tasa := CD.pkg_cd_inter.Obtiene_CDTasActual(
            pcodempresa  => p_cod_empresa,
            pcodproducto => p_cod_producto,
            pplazo       => p_plazo_dias,
            pmonto       => p_monto,
            pcodtasa     => v_tasas_calculadas.cod_tasa,
            pspread      => v_tasas_calculadas.spread,
            poperacion   => v_tasas_calculadas.operacion,
            pvalortasa   => l_tasa_bruta_ajustada -- Variable dummy, no la usaremos directamente
        );

        IF v_control_obt_tasa = 0 OR v_tasas_calculadas.cod_tasa IS NULL THEN
            p_Error := 'No se pudo obtener la configuración de tasa para los parámetros dados.';
            RETURN;
        END IF;

        -- 2. Obtener el valor de la tasa bruta base
        v_tasas_calculadas.tasa_bruta_base := CD.pkg_cd_inter.CD_TASINTERES_BASE(
            p_empresa => p_cod_empresa,
            p_tasa    => v_tasas_calculadas.cod_tasa,
            p_fecha   => p_fecha_calculo,
            p_error   => v_error_pkg,
            p_sqlcode => v_sqlcode_pkg
        );

        IF v_error_pkg IS NOT NULL OR v_tasas_calculadas.tasa_bruta_base IS NULL THEN
            p_Error := 'Error obteniendo tasa base (' || v_error_pkg || ') para el código ' || v_tasas_calculadas.cod_tasa;
            RETURN;
        END IF;

        -- 3. Calcular la tasa neta final
        l_tasa_bruta_ajustada := v_tasas_calculadas.tasa_bruta_base;
        CD.pkg_cd_inter.cd_calcula_tasa_neta(
            p_tasa_bruta  => l_tasa_bruta_ajustada, -- IN OUT: se ajusta con el spread
            p_spread      => v_tasas_calculadas.spread,
            p_renta       => v_producto.porcentaje_renta,
            p_tasa_neta   => v_tasas_calculadas.tasa_neta_final, -- Salida
            p_operacion   => v_tasas_calculadas.operacion,
            p_error       => v_error_pkg
        );

        v_tasas_calculadas.tasa_bruta_ajustada := l_tasa_bruta_ajustada; -- Guardamos la tasa bruta con el spread aplicado

        IF v_error_pkg IS NOT NULL OR v_tasas_calculadas.tasa_neta_final IS NULL THEN
            p_Error := 'Error calculando la tasa neta (' || v_error_pkg || ').';
            RETURN;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            p_Error := 'Error inesperado en calcular_tasas_certificado';
    END calcular_tasas_certificado;
    
    PROCEDURE INICIAR_SIMULACION_CERTIFICADO (
        p_client_id       IN VARCHAR2,
        p_cod_producto    IN VARCHAR2,
        p_monto           IN NUMBER,
        p_plazo_dias      IN NUMBER,
        p_Error           OUT VARCHAR2
    ) IS
    BEGIN
        cargar_datos_cliente(p_client_id => p_client_id, p_Error => p_Error);

        validar_lista_pep(p_client_id => p_client_id, p_Error => p_Error);

        validar_lista_negra(p_client_id => p_client_id, p_Error => p_Error);

        cargar_param_producto(
            p_cod_producto => p_cod_producto,
            p_Error        => p_Error
        );

        validar_param_producto(
            p_cod_producto => p_cod_producto,
            p_monto      => p_monto,
            p_plazo_dias => p_plazo_dias,
            p_Error      => p_Error
        );
        
        DECLARE
        BEGIN
           CD_FECHA_EXACTA(
              p_fecha_inicial   => SYSDATE,
              p_calendario_base => v_producto.base_plazo,
              p_valor           => p_plazo_dias,
              p_frecuencia      => v_producto.fre_capitaliza,
              p_fecha_final     => v_certificado_values.fecha_vencimiento,
              p_total_dias      => v_certificado_values.plazo_en_dias
           );
           --DBMS_OUTPUT.put_line('Total días: ' || v_certificado_values.plazo_en_dias);
        END;
            
        p_Error := 'Validaciones y carga de datos completadas exitosamente.';
        DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
        --DBMS_OUTPUT.PUT_LINE('Datos cargados del producto: ');
        --DBMS_OUTPUT.PUT_LINE('Codigo del producto: ' || v_producto.cod_producto);
        --DBMS_OUTPUT.PUT_LINE('Monto minimo: ' || v_producto.pxe_monto_minimo);
        --DBMS_OUTPUT.PUT_LINE('Plazo minimo: ' || v_producto.pxe_plazo_minimo);
        --DBMS_OUTPUT.PUT_LINE('Paga renta: ' || v_producto.paga_renta);
        DBMS_OUTPUT.PUT_LINE('Renta %: ' || v_producto.porcentaje_renta);
        --DBMS_OUTPUT.PUT_LINE('Base calculo: ' || v_producto.base_calculo);
        --DBMS_OUTPUT.PUT_LINE('Base plazo: ' || v_producto.base_plazo);
        --DBMS_OUTPUT.PUT_LINE('Ind prd emp: ' || v_producto.ind_prd_emp);
        --DBMS_OUTPUT.PUT_LINE('Ind renovacion auto: ' || v_producto.ind_renovacion_auto);
        --DBMS_OUTPUT.PUT_LINE('Cod cartera: ' || v_producto.cod_cartera);
        --DBMS_OUTPUT.PUT_LINE('Forma calculo interes' || v_producto.cod_cartera);
        --DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
        DBMS_OUTPUT.PUT_LINE('Spread: ' || v_producto.spread);
        --DBMS_OUTPUT.PUT_LINE('Operación Spread: ' || v_producto.operacion);
        --DBMS_OUTPUT.PUT_LINE('Plazo Mínimo (Tasa): ' || v_producto.ptpm_plazo_minimo);
        --DBMS_OUTPUT.PUT_LINE('Plazo Máximo (Tasa): ' || v_producto.ptpm_plazo_maximo);
        --DBMS_OUTPUT.PUT_LINE('Monto Mínimo (Tasa): ' || v_producto.ptpm_monto_minimo);
        --DBMS_OUTPUT.PUT_LINE('Monto Máximo (Tasa): ' || v_producto.ptpm_monto_maximo);
        DBMS_OUTPUT.PUT_LINE('Código de Tasa: ' || v_producto.cod_tasa);
        --DBMS_OUTPUT.PUT_LINE('Tasa Mínima (Rango): ' || v_producto.tasa_minima);
        --DBMS_OUTPUT.PUT_LINE('Tasa Máxima (Rango): ' || v_producto.tasa_maxima);
        --DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
        DBMS_OUTPUT.PUT_LINE('Fecha de vencimiento: ' || TO_CHAR(v_certificado_values.fecha_vencimiento,'DD-MM-YYYY'));
        DBMS_OUTPUT.PUT_LINE('Plazo en dias: ' || v_certificado_values.plazo_en_dias);
        
        calcular_tasas_certificado(
            p_cod_empresa   => v_default_values.codigo_empresa,
            p_cod_producto  => p_cod_producto,
            p_plazo_dias    => p_plazo_dias,
            p_monto         => p_monto,
            p_fecha_calculo => SYSDATE,
            p_Error => p_Error
        );
        
        DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
        DBMS_OUTPUT.PUT_LINE('Tasa bruta base: ' || v_tasas_calculadas.tasa_bruta_base);
        DBMS_OUTPUT.PUT_LINE('Tasa bruta ajustada: ' || v_tasas_calculadas.tasa_bruta_ajustada);
        DBMS_OUTPUT.PUT_LINE('Tasa neta final: ' || v_tasas_calculadas.tasa_neta_final);
        
    EXCEPTION
        WHEN OTHERS THEN
            p_Error := 'Error inesperado en el orquestador: ' || SQLERRM;
    END INICIAR_SIMULACION_CERTIFICADO;
            
END pkg_digcert_proceso;
/