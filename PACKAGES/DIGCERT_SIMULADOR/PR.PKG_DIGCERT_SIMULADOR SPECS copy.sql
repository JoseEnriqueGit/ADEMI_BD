CREATE OR REPLACE PACKAGE PR.pkg_digcert_simulador IS

  TYPE t_default_values IS RECORD (
    codigo_empresa VARCHAR2(1),
    codigo_agencia VARCHAR2(5),
    nombre_agencia VARCHAR2(80)
  );

  TYPE t_cliente IS RECORD (
    client_id       VARCHAR2(15),
    nombre          VARCHAR2(240),
    cedula          VARCHAR2(30),
    cod_ejecutivo   VARCHAR2(30),
    cod_promotor    VARCHAR2(30)
  );

  v_datos_cliente   t_cliente;
  v_default_values  t_default_values;

  PROCEDURE cargar_datos_cliente(p_client_id    IN VARCHAR2,
                                 p_client_cedula IN VARCHAR2);

END pkg_digcert_simulador;
/
