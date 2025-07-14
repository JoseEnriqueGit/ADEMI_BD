DECLARE
    v_ultimo_lote NUMBER;
BEGIN
    SELECT MAX(id_lote) INTO v_ultimo_lote FROM PR.PR_CHAMPION_CHALLENGE_LOG;
    
    IF v_ultimo_lote IS NULL THEN
        DBMS_OUTPUT.PUT_LINE('No hay lotes en el log para procesar.');
        RETURN;
    END IF;
    
    UPDATE PR.PR_CHAMPION_CHALLENGE_LOG log
    SET 
        log.tipo_desembolso = 'DESEMBOLSO POR FIRMA DIGITAL',
        log.no_credito_nuevo_core = (
            SELECT cred.no_credito
            FROM pr_creditos cred
            WHERE cred.codigo_cliente = log.cod_cliente
              AND cred.estado = 'D'
              AND cred.f_primer_desembolso BETWEEN log.fecha_proceso AND log.fecha_proceso + 30
              AND cred.no_credito != log.no_credito
              AND ROWNUM = 1
        ),
        log.FECHA_DESEMBOLSO_CORE = (
            SELECT cred.f_primer_desembolso
            FROM pr_creditos cred
            WHERE cred.codigo_cliente = log.cod_cliente
              AND cred.estado = 'D'
              AND cred.f_primer_desembolso BETWEEN log.fecha_proceso AND log.fecha_proceso + 30
              AND cred.no_credito != log.no_credito
              AND ROWNUM = 1
        )
    WHERE log.id_lote = v_ultimo_lote
        AND log.grupo_asignado = 'CHAMPION'
        AND log.tipo_desembolso IS NULL
        AND EXISTS (
            SELECT 1 
            FROM pr_bitacora_represtamo b1
            WHERE b1.id_represtamo = log.id_represtamo
              AND b1.codigo_estado = 'CRY'
        )
        AND EXISTS (
            SELECT 1 
            FROM pr_bitacora_represtamo b2
            WHERE b2.id_represtamo = log.id_represtamo
              AND b2.codigo_estado = 'CRD'
        );
    
    UPDATE PR.PR_CHAMPION_CHALLENGE_LOG log
    SET 
        log.tipo_desembolso = 'DESEMBOLSO TRADICIONAL',
        log.no_credito_nuevo_core = (
            SELECT cred.no_credito
            FROM pr_creditos cred
            WHERE cred.codigo_cliente = log.cod_cliente
              AND cred.estado = 'D'
              AND cred.f_primer_desembolso BETWEEN log.fecha_proceso AND log.fecha_proceso + 30
              AND cred.no_credito != log.no_credito
              AND ROWNUM = 1
        ),
        log.FECHA_DESEMBOLSO_CORE = (
            SELECT cred.f_primer_desembolso
            FROM pr_creditos cred
            WHERE cred.codigo_cliente = log.cod_cliente
              AND cred.estado = 'D'
              AND cred.f_primer_desembolso BETWEEN log.fecha_proceso AND log.fecha_proceso + 30
              AND cred.no_credito != log.no_credito
              AND ROWNUM = 1
        )
    WHERE log.id_lote = v_ultimo_lote
        AND log.grupo_asignado = 'CHAMPION'
        AND log.tipo_desembolso IS NULL
        AND EXISTS (
            SELECT 1 
            FROM pr_bitacora_represtamo b1
            WHERE b1.id_represtamo = log.id_represtamo
              AND b1.codigo_estado = 'CRD'
        )
        AND NOT EXISTS (
            SELECT 1 
            FROM pr_bitacora_represtamo b2
            WHERE b2.id_represtamo = log.id_represtamo
              AND b2.codigo_estado = 'CRY'
        );

    UPDATE PR.PR_CHAMPION_CHALLENGE_LOG log
    SET 
        log.tipo_desembolso = 'DESEMBOLSO POR OFICINA',
        log.no_credito_nuevo_core = (
            SELECT cred.no_credito
            FROM pr_creditos cred
            WHERE cred.codigo_cliente = log.cod_cliente
              AND cred.estado = 'D'
              AND cred.f_primer_desembolso BETWEEN log.fecha_proceso AND log.fecha_proceso + 30
              AND cred.no_credito != log.no_credito
              AND ROWNUM = 1
        ),
        log.FECHA_DESEMBOLSO_CORE = (
            SELECT cred.f_primer_desembolso
            FROM pr_creditos cred
            WHERE cred.codigo_cliente = log.cod_cliente
              AND cred.estado = 'D'
              AND cred.f_primer_desembolso BETWEEN log.fecha_proceso AND log.fecha_proceso + 30
              AND cred.no_credito != log.no_credito
              AND ROWNUM = 1
        )
    WHERE log.id_lote = v_ultimo_lote
        AND log.grupo_asignado = 'CHALLENGER'
        AND log.tipo_desembolso IS NULL
        AND (
            SELECT cred.no_credito
            FROM pr_creditos cred
            WHERE cred.codigo_cliente = log.cod_cliente
              AND cred.estado = 'D'
              AND cred.f_primer_desembolso BETWEEN log.fecha_proceso AND log.fecha_proceso + 30
              AND cred.no_credito != log.no_credito
              AND ROWNUM = 1
        ) IS NOT NULL;
    
    COMMIT;
        
EXCEPTION
    WHEN OTHERS THEN
        --DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('No se guardó ningún cambio.');
        ROLLBACK;
END;
/