CREATE OR REPLACE PACKAGE pr.pkg_digcert_simulador IS

  ----------------------------------------------------------------------
  -- 1) Definición de un tipo RECORD para agrupar todos los campos que
  --    vas a necesitar del cliente. Cada atributo corresponde a una columna
  --    de la tabla CLIENTES (o de donde tomes la info).
  ----------------------------------------------------------------------
  TYPE t_cliente IS RECORD (
    client_id   VARCHAR2(15),
    nombre      VARCHAR2(240),
    apellido    VARCHAR2(240),
    cedula      VARCHAR2(20),
    fecha_nac   DATE,
    -- … cualquier otro campo que precises más adelante
    saldo_act   NUMBER
  );

  ----------------------------------------------------------------------
  -- 2) Variable global (package-level) de ese tipo, donde almacenarás
  --    los datos del cliente después de leerlos.
  ----------------------------------------------------------------------
  v_datos_cliente t_cliente;

  ----------------------------------------------------------------------
  -- 3) Procedimiento público para cargar/prender “una vez” el registro
  --    del cliente en memoria. Lo invocas al inicio de tu flujo.
  ----------------------------------------------------------------------
  PROCEDURE cargar_datos_cliente(p_client_id IN VARCHAR2);

  ----------------------------------------------------------------------
  -- 4) Luego defines otros procedimientos o funciones que usen
  --    v_datos_cliente.X (campo X) sin tener que volver a hacer SELECT.
  ----------------------------------------------------------------------
  PROCEDURE procesar_certificado;
  FUNCTION  calcular_riesgo RETURN NUMBER;

END pr.pkg_digcert_simulador;
/

CREATE OR REPLACE PACKAGE BODY pr.pkg_digcert_simulador IS

  PROCEDURE cargar_datos_cliente(p_client_id IN VARCHAR2) IS
  BEGIN
    SELECT client_id,
           nombre,
           apellido,
           cedula,
           fecha_nacimiento,
           saldo_actual
      INTO v_datos_cliente.client_id,
           v_datos_cliente.nombre,
           v_datos_cliente.apellido,
           v_datos_cliente.cedula,
           v_datos_cliente.fecha_nac,
           v_datos_cliente.saldo_act
      FROM clientes
     WHERE client_id = p_client_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- Manejo de caso en que no exista el cliente
      v_datos_cliente.client_id := NULL;
      v_datos_cliente.nombre    := NULL;
      v_datos_cliente.apellido  := NULL;
      v_datos_cliente.cedula    := NULL;
      v_datos_cliente.fecha_nac := NULL;
      v_datos_cliente.saldo_act := NULL;
  END cargar_datos_cliente;

  PROCEDURE procesar_certificado IS
  BEGIN
    IF v_datos_cliente.client_id IS NULL THEN
      RAISE_APPLICATION_ERROR(-20002, 'Debe cargar los datos antes de procesar');
    END IF;

    -- Aquí ya puedes usar directamente:
    -- v_datos_cliente.nombre, v_datos_cliente.apellido, etc.
    DBMS_OUTPUT.PUT_LINE('Procesando certificado para ' || v_datos_cliente.nombre || ' ' || v_datos_cliente.apellido);
  END procesar_certificado;

  -- … demás lógica que use v_datos_cliente.*
END pkg_digcert_simulador;
/



    v_codigo_empresa VARCHAR2(1) := '1';
    v_codigo_agencia VARCHAR2(15) := '0';
    v_nombre_agencia VARCHAR2(15) := 'OFICINA CENTRAL';