CREATE OR REPLACE PROCEDURE JOOGANDO.CALCULAR_CERTIFICADO_DIGITAL_SIM (
    -- Parámetros de ENTRADA:
    -- Estos son los datos que el usuario (a través de la API) o el sistema proporcionan para la simulación.
    -- Fueron definidos basándose en los campos clave que el SOW indica que el cliente debe ingresar o que son necesarios para los cálculos.
    p_monto                   IN NUMBER,        -- Monto de la inversión.
    p_plazo_dias              IN NUMBER,        -- Plazo del certificado en días.
    p_modalidad_pago_interes  IN VARCHAR2,     -- Modalidad de pago: 'CAPITALIZABLE' o 'CREDITO_CUENTA'. [cite: 13]
    p_cod_producto            IN VARCHAR2,     -- Código del producto, ej: 'CFD' o su equivalente numérico como '350'. [cite: 8]
    p_cod_empresa             IN VARCHAR2,     -- Código de la empresa/banco, ej: 'ADEMI' o su equivalente numérico.
    p_cod_moneda              IN VARCHAR2,     -- Código de la moneda, ej: 'DOP'. [cite: 13]
    p_fecha_calculo           IN DATE DEFAULT SYSDATE, -- Fecha para la cual se realiza el cálculo (importante para tasas vigentes).

    -- Parámetros de SALIDA:
    -- Estos son los resultados que el procedimiento calculará y devolverá.
    o_tasa_anual_neta         OUT NUMBER,      -- La tasa de interés neta anual efectiva.
    o_interes_calculado       OUT NUMBER,      -- El monto total de interés ganado (ganancias aproximadas).
    o_capital_mas_interes     OUT NUMBER,      -- Suma del monto inicial más el interés calculado.
    o_error_code              OUT VARCHAR2,    -- Código de error si algo falla durante la ejecución.
    o_error_message           OUT VARCHAR2     -- Mensaje descriptivo del error.
)
IS
    -- Sección de Declaración de Variables Internas:
    -- Usadas para almacenar valores intermedios durante los cálculos.

    -- Variables para parámetros de producto:
    v_base_calculo            NUMBER;          -- Almacenará la base de días para el cálculo de interés (360 o 365).
                                             -- Inspirado en :bkproducto.base_calculo de los triggers de Forms y necesario para la fórmula de interés.
    v_porcentaje_renta        NUMBER;          -- Almacenará el porcentaje de renta/impuesto sobre la tasa (si la tasa neta se calcula aplicando esto).
                                             -- Inspirado en :bkproducto.porcentaje_renta y el procedimiento CD.pkg_cd_inter.cd_calcula_tasa_neta.

    -- Variables para obtener tasa (basadas en los parámetros de las funciones de CD.pkg_cd_inter):
    v_cod_tasa                VARCHAR2(10);    -- Código de la tasa aplicable.
    v_spread                  NUMBER;          -- Valor del spread.
    v_operacion               VARCHAR2(1);     -- Operación del spread ('+' o '-').
    v_tasa_valor_ref          NUMBER;          -- Valor de tasa devuelto por Obtiene_CDTasActual.
    v_tasa_bruta_base         NUMBER;          -- Tasa bruta obtenida antes de ajustes.
    v_control_obt_tasa        NUMBER;          -- Código de retorno de Obtiene_CDTasActual.

    -- Variables para errores devueltos por las funciones de CD.pkg_cd_inter:
    v_error_pkg               VARCHAR2(10);
    v_sqlcode_pkg             NUMBER;

BEGIN -- Inicio del cuerpo ejecutable del procedimiento.

    -- Inicialización de variables de salida de error para asegurar que no contengan valores previos.
    o_error_code := NULL;
    o_error_message := NULL;

    ----------------------------------------------------------------------------------------------------
    -- Paso 1: Obtener parámetros del producto (base_calculo, porcentaje_renta)
    ----------------------------------------------------------------------------------------------------
    -- Razonamiento: Las reglas de cálculo (como la base de días y el porcentaje de impuesto sobre la tasa)
    -- son específicas del producto financiero. Es necesario consultarlas primero.
    -- Reutilización/Guía: Esta sección se basa en la necesidad identificada en el trigger
    -- WHEN-NEW-RECORD-INSTANCE de Forms, que obtenía estos datos del bloque :bkproducto.
    -- Asumimos que estos datos ahora residen en una tabla como CD_PRODUCTO_X_EMPRESA.
    -- La imagen que me proporcionaste de CD_PRODUCTO_X_EMPRESA confirma los campos BASE_CALCULO y PORCENTAJE_RENTA.
    BEGIN
        SELECT base_calculo, porcentaje_renta
        INTO v_base_calculo, v_porcentaje_renta
        FROM CD_PRODUCTO_X_EMPRESA -- Nombre de tabla confirmado por tus imágenes.
        WHERE cod_empresa = p_cod_empresa   -- Filtro por empresa.
          AND cod_producto = p_cod_producto; -- Filtro por el código de producto.
    EXCEPTION
        WHEN NO_DATA_FOUND THEN -- Si no se encuentra el producto o sus parámetros.
            o_error_code := 'PROD-001';
            o_error_message := 'Producto no encontrado o parámetros no configurados: ' || p_cod_producto;
            RETURN; -- Termina la ejecución del procedimiento.
        WHEN OTHERS THEN -- Cualquier otro error durante la consulta.
            o_error_code := 'PROD-ERR';
            o_error_message := 'Error obteniendo parámetros del producto: ' || SQLERRM;
            RETURN;
    END;

    -- Validación adicional: Asegura que los parámetros críticos del producto se hayan cargado.
    IF v_base_calculo IS NULL OR v_porcentaje_renta IS NULL THEN
        o_error_code := 'PROD-002';
        o_error_message := 'Base de cálculo o porcentaje de renta no configurados para el producto: ' || p_cod_producto;
        RETURN;
    END IF;

    ----------------------------------------------------------------------------------------------------
    -- Paso 2: Obtener parámetros de la tasa (código de tasa, spread, operación)
    ----------------------------------------------------------------------------------------------------
    -- Razonamiento: La tasa de un certificado no es fija; depende de factores como el monto,
    -- el plazo, el producto, etc. Este paso busca la "plantilla" de tasa aplicable.
    -- Reutilización/Guía: Se invoca directamente la función Obtiene_CDTasActual del paquete
    -- CD.pkg_cd_inter, cuya lógica me proporcionaste. Este paquete es una "caja negra" existente
    -- que ya realiza esta búsqueda.
    v_control_obt_tasa := CD.pkg_cd_inter.Obtiene_CDTasActual(
        pcodempresa  => p_cod_empresa,
        pcodproducto => p_cod_producto,
        pplazo       => p_plazo_dias,
        pmonto       => p_monto,
        pcodtasa     => v_cod_tasa,       -- Salida: Código de tasa.
        pspread      => v_spread,         -- Salida: Valor del spread.
        poperacion   => v_operacion,      -- Salida: Operación del spread.
        pvalortasa   => v_tasa_valor_ref  -- Salida: Valor de referencia de la tasa.
    );

    -- Validación: Si Obtiene_CDTasActual no retorna una configuración de tasa válida (retorna 0 o pcodtasa es NULL).
    IF v_control_obt_tasa = 0 OR v_cod_tasa IS NULL THEN
        o_error_code := 'TASA-001';
        o_error_message := 'No se pudo obtener la configuración de tasa para los parámetros dados (Monto: ' || p_monto || ', Plazo: ' || p_plazo_dias || ', Prod: ' || p_cod_producto || ').';
        RETURN;
    END IF;

    ----------------------------------------------------------------------------------------------------
    -- Paso 3: Obtener el valor de la tasa bruta base
    ----------------------------------------------------------------------------------------------------
    -- Razonamiento: El código de tasa obtenido en el paso anterior es una referencia. Necesitamos
    -- el valor numérico de esa tasa bruta que esté vigente en la fecha del cálculo.
    -- Reutilización/Guía: Se invoca directamente la función CD_TASINTERES_BASE del paquete CD.pkg_cd_inter.
    v_tasa_bruta_base := CD.pkg_cd_inter.CD_TASINTERES_BASE(
        p_empresa => p_cod_empresa,
        p_tasa    => v_cod_tasa,         -- Código de tasa del paso anterior.
        p_fecha   => p_fecha_calculo,    -- Fecha para la cual se busca la tasa.
        p_error   => v_error_pkg,        -- Salida: Código de error del paquete.
        p_sqlcode => v_sqlcode_pkg       -- Salida: SQLCODE del error del paquete.
    );

    -- Validación: Si CD_TASINTERES_BASE reporta un error o no devuelve una tasa.
    IF v_error_pkg IS NOT NULL OR v_tasa_bruta_base IS NULL THEN
        o_error_code := 'TASA-002';
        o_error_message := 'Error obteniendo tasa base (' || v_error_pkg || ') para el código de tasa ' || v_cod_tasa || '. SQLCODE: ' || v_sqlcode_pkg;
        RETURN;
    END IF;

    ----------------------------------------------------------------------------------------------------
    -- Paso 4: Calcular la tasa neta
    ----------------------------------------------------------------------------------------------------
    -- Razonamiento: La tasa neta es la que finalmente se usa para calcular los intereses del cliente.
    -- Se ajusta la tasa bruta con el spread y luego se aplica el porcentaje de renta (impuesto).
    -- Reutilización/Guía: Se invoca el procedimiento cd_calcula_tasa_neta del paquete CD.pkg_cd_inter.
    -- Es crucial que la lógica de este procedimiento (cómo aplica el spread y la renta) sea la correcta y definitiva.
    DECLARE
        l_tasa_bruta_ajustada NUMBER := v_tasa_bruta_base; -- Variable local para pasar como IN OUT a cd_calcula_tasa_neta.
    BEGIN
        CD.pkg_cd_inter.cd_calcula_tasa_neta(
            p_tasa_bruta  => l_tasa_bruta_ajustada, -- IN OUT: cd_calcula_tasa_neta ajusta esta con el spread.
            p_spread      => v_spread,
            p_renta       => v_porcentaje_renta,   -- Obtenido de la configuración del producto.
            p_tasa_neta   => o_tasa_anual_neta,    -- Salida: La tasa neta final.
            p_operacion   => v_operacion,          -- Cómo aplicar el spread.
            p_error       => v_error_pkg           -- Salida: Código de error del paquete.
        );

        -- Validación: Si cd_calcula_tasa_neta reporta un error.
        IF v_error_pkg IS NOT NULL THEN
            o_error_code := 'TASA-003';
            o_error_message := 'Error calculando tasa neta (' || v_error_pkg || '). Tasa bruta base: ' || v_tasa_bruta_base || ', spread: ' || v_spread || ', %renta: ' || v_porcentaje_renta;
            RETURN;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN -- Captura cualquier error inesperado durante la llamada a cd_calcula_tasa_neta.
             o_error_code := 'TASA-CALC-ERR';
             o_error_message := 'Excepción no controlada en cd_calcula_tasa_neta: ' || SQLERRM;
             RETURN;
    END;

    -- Validación: Asegura que la tasa neta calculada no sea nula.
    IF o_tasa_anual_neta IS NULL THEN
        o_error_code := 'TASA-004';
        o_error_message := 'El cálculo de la tasa neta resultó en NULL después de los ajustes.';
        RETURN;
    END IF;

    ----------------------------------------------------------------------------------------------------
    -- Paso 5: Calcular el interés
    ----------------------------------------------------------------------------------------------------
    -- Razonamiento: Se aplica la fórmula estándar de interés simple para proyectar las ganancias.
    -- Fórmula: Interés = Principal * (Tasa Anual Neta / 100) * (Plazo en Días / Base de Días del Año)
    IF v_base_calculo = 0 THEN -- Validación para evitar división por cero.
        o_error_code := 'CALC-001';
        o_error_message := 'La base de cálculo de días (v_base_calculo) no puede ser cero.';
        RETURN;
    END IF;

    o_interes_calculado := (p_monto * (o_tasa_anual_neta / 100) * p_plazo_dias) / v_base_calculo;
    o_interes_calculado := ROUND(o_interes_calculado, 2); -- Redondeo a 2 decimales, práctica financiera común.

    ----------------------------------------------------------------------------------------------------
    -- Paso 6: Calcular Capital + Intereses
    ----------------------------------------------------------------------------------------------------
    -- Razonamiento: Este es uno de los valores principales que la simulación debe retornar.
    o_capital_mas_interes := p_monto + o_interes_calculado;
    o_capital_mas_interes := ROUND(o_capital_mas_interes, 2); -- Redondeo del total.

EXCEPTION
    WHEN OTHERS THEN -- Bloque de manejo de errores general para cualquier excepción no prevista.
        o_error_code := 'SIM-ERR-GEN';
        o_error_message := 'Error inesperado en CALCULAR_CERTIFICADO_DIGITAL_SIM: ' || SQLERRM;
        -- No se incluye RETURN aquí para que el bloque anónimo que llama pueda
        -- capturar estos valores de o_error_code y o_error_message e insertarlos en la tabla temporal.
END CALCULAR_CERTIFICADO_DIGITAL_SIM;
/