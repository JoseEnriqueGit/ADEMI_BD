SELECT VALOR INTO vCtelefono FROM PR_CANALES_REPRESTAMO WHERE CANAL = 1 AND ID_REPRESTAMO = vRow_Repre.id_represtamo;

-- SELECT CODIGO_AGENCIA INTO COD_AGENCIA FROM PA.CLIENTES_B2000 WHERE COD_CLIENTE =  vRow_Repre.codigo_cliente;
-- SELECT COUNT(*)
-- INTO vSubqueryResult
-- FROM TABLE(PR.PR_PKG_REPRESTAMOS.F_Obt_Valor_Parametros('SUCURSALES_PILOTO_FIRMA')) t
-- WHERE t.COLUMN_VALUE = COD_AGENCIA;
-- vSucursal := PR.PR_PKG_REPRESTAMOS.f_obt_parametro_Represtamo('SUCURSALES_PILOTO_FIRMA') ;

FOR A IN ACTUALIZA_TELEFONO LOOP
    IF NVL(pMtoPrestamo, 0) < 100000.00 THEN
        IF A.TELEFONO = vCtelefono AND A.TIP_TELEFONO = 'C' THEN
            UPDATE PA.TEL_PERSONAS
                SET NOTIF_DIGITAL = 'S'
            WHERE TIP_TELEFONO = 'C'
                AND COD_AREA || NUM_TELEFONO = vCtelefono
                AND COD_PERSONA = vRow_Repre.codigo_cliente;
        ELSIF A.TELEFONO <> vCtelefono THEN
        --DBMS_OUTPUT.PUT_LINE ( 'VALIDO QUE LOS CANALES SEAN DISTINTOS '  );
            UPDATE PA.TEL_PERSONAS
                SET NOTIF_DIGITAL = 'N'
            WHERE COD_PERSONA = vRow_Repre.codigo_cliente
                AND (COD_AREA || NUM_TELEFONO) <> vCtelefono;
        END IF;
    ELSE
    --DBMS_OUTPUT.PUT_LINE ( 'VALIDO QUE NO ESTA EN LA SUCURSAL HABILITAD '  );
    UPDATE PA.TEL_PERSONAS
        SET NOTIF_DIGITAL = 'N'
        WHERE COD_PERSONA = vRow_Repre.codigo_cliente;
    END IF;
END LOOP;