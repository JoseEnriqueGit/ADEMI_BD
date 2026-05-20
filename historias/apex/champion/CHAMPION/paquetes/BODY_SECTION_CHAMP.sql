PROCEDURE P_SPLIT_CHAMPION_CHALLENGER(
    p_id_lote            IN NUMBER,
    p_nombre_campana     IN VARCHAR2,
    p_challenger_ratio   IN NUMBER DEFAULT 0.40,
    p_error              OUT VARCHAR2
) IS
    -- Definición del tipo para el registro de un candidato
    TYPE type_candidate_rec IS RECORD (
        id_represtamo         NUMBER,
        nombre_cliente        VARCHAR(100),
        identificacion        VARCHAR(30),
        cod_cliente           NUMBER,
        no_credito            NUMBER,
        mto_preaprobado       NUMBER,
        tipo_credito          NUMBER,
        xcore_global          NUMBER,
        oficina               VARCHAR(50),
        zona                  VARCHAR(50),
        oficial               VARCHAR(50)
    );
    -- Definición del tipo para la colección (array) de candidatos
    TYPE type_candidate_tbl IS TABLE OF type_candidate_rec;
    v_candidates         type_candidate_tbl;

    -- Variables internas
    v_challenger_count   NUMBER;
    v_total_candidates   NUMBER := 0;
    v_previous_runs      NUMBER;
    
BEGIN
    SELECT 
        r.id_represtamo, pa.obt_nombre_persona(r.codigo_cliente)AS "nombre_cliente", s.identificacion, r.codigo_cliente, r.no_credito, r.mto_preaprobado,
        s.tipo_credito, r.xcore_global, ag.descripcion AS "Oficina", pa.obt_desc_zona(1, ag.cod_zona) AS "Zona", 
        pa.obt_nombre_empleado(c.codigo_empresa, c.codigo_ejecutivo) AS "Oficial"
    BULK COLLECT INTO v_candidates
    FROM pr.pr_represtamos r
    JOIN pr.pr_solicitud_represtamo s ON r.id_represtamo = s.id_represtamo
    JOIN pr.pr_creditos c ON c.no_credito = r.no_credito
    JOIN pa.agencia ag ON ag.cod_agencia = c.codigo_agencia
    WHERE r.estado = 'NP';

    v_total_candidates := v_candidates.COUNT;
    IF v_total_candidates = 0 THEN
        p_error := 'No hay candidatos en estado NP para procesar.';
        RETURN;
    END IF;
    
    v_challenger_count := TRUNC(v_total_candidates * p_challenger_ratio);

    FOR i IN 1..v_total_candidates LOOP
        DECLARE
            j           INTEGER := TRUNC(DBMS_RANDOM.VALUE(i, v_total_candidates + 1));
            temp_rec    type_candidate_rec;
        BEGIN
            temp_rec          := v_candidates(i);
            v_candidates(i)   := v_candidates(j);
            v_candidates(j)   := temp_rec;
        END;
    END LOOP;
    
    -- 4. Procesar la colección ya mezclada
    FOR i IN 1..v_total_candidates LOOP
        -- Contar cuántas veces este cliente/crédito original ya existe en el log
        SELECT COUNT(*)
        INTO v_previous_runs
        FROM PR.PR_CHAMPION_CHALLENGE_LOG
        WHERE cod_cliente = v_candidates(i).cod_cliente
          AND no_credito = v_candidates(i).no_credito;
          
        IF i <= v_challenger_count THEN
            -- Es un CHALLENGER: Cambiar estado a CHCH (AHORA LCC)
            P_Generar_Bitacora(
                pIdReprestamo  => v_candidates(i).id_represtamo,
                pEstado        => 'LCC',
                pObservaciones => 'Asignado al grupo Challenger. Lote ID: ' || p_id_lote,
                pUsuario       => 'JOB_CHAMPION_CHALLENGE',
                pCanal         => NULL,
                pStep          => NULL
            );
            
            -- Registrar en el LOG como Challenger
            INSERT INTO PR.PR_CHAMPION_CHALLENGE_LOG (
                id_lote, id_represtamo, nombre_cliente, identificacion, cod_cliente, no_credito, fecha_proceso,
                nombre_campana, xcore_al_preaprobar, monto_preaprobado,
                tipo_credito, grupo_asignado, canal_notificacion, veces_procesado, oficina, zona, oficial
            ) VALUES (
                p_id_lote, v_candidates(i).id_represtamo, v_candidates(i).nombre_cliente, v_candidates(i).identificacion, v_candidates(i).cod_cliente, v_candidates(i).no_credito, SYSDATE,
                p_nombre_campana, v_candidates(i).xcore_global, v_candidates(i).mto_preaprobado,
                v_candidates(i).tipo_credito, 'CHALLENGER', NULL, v_previous_runs + 1, v_candidates(i).oficina, v_candidates(i).zona, v_candidates(i).oficial
            );
        ELSE
            -- Es un CHAMPION: Se queda en NP, solo se registra en el log
            INSERT INTO PR.PR_CHAMPION_CHALLENGE_LOG (
                id_lote, id_represtamo, nombre_cliente, identificacion, cod_cliente, no_credito, fecha_proceso,
                nombre_campana, xcore_al_preaprobar, monto_preaprobado,
                tipo_credito, grupo_asignado, canal_notificacion, veces_procesado, oficina, zona, oficial
            ) VALUES (
                p_id_lote, v_candidates(i).id_represtamo, v_candidates(i).nombre_cliente, v_candidates(i).identificacion, v_candidates(i).cod_cliente, v_candidates(i).no_credito, SYSDATE,
                p_nombre_campana, v_candidates(i).xcore_global, v_candidates(i).mto_preaprobado,
                v_candidates(i).tipo_credito, 'CHAMPION', 'SMS', v_previous_runs + 1, v_candidates(i).oficina, v_candidates(i).zona, v_candidates(i).oficial
            );
        END IF;
    END LOOP;

    p_error := 'Proceso de división finalizado. Total: ' || v_total_candidates || 
               '. Challengers: ' || v_challenger_count || 
               '. Champions: ' || (v_total_candidates - v_challenger_count);
EXCEPTION
    WHEN OTHERS THEN
        p_error := 'ERROR en P_SPLIT_CHAMPION_CHALLENGER: ' || SQLERRM;
END P_SPLIT_CHAMPION_CHALLENGER;
PROCEDURE P_EJECUTAR_CAMPANA_CHALLENGE(
    p_error OUT VARCHAR2
) IS
    v_nombre_campana VARCHAR2(100) := 'Campaña ' || TO_CHAR(SYSDATE, 'YYYY-MM');
    v_id_lote        NUMBER;
BEGIN

    SELECT PR.PR_LOTE_ID_SEC.NEXTVAL INTO v_id_lote FROM DUAL;
    
    P_SPLIT_CHAMPION_CHALLENGER(
        p_id_lote => v_id_lote,
        p_nombre_campana => v_nombre_campana,
        p_challenger_ratio => 0.40,
        p_error => p_error
    );
    
    COMMIT;
    
EXCEPTION
    WHEN OTHERS THEN
        p_error := 'ERROR en P_EJECUTAR_CAMPANA_CHALLENGE: ' || SQLERRM;
        ROLLBACK;
END P_EJECUTAR_CAMPANA_CHALLENGE;

PROCEDURE ACTUALIZAR_CHAMPION_CHALLENGE
AS
    v_ultimo_lote NUMBER;
BEGIN
    SELECT MAX(id_lote) INTO v_ultimo_lote FROM PR.PR_CHAMPION_CHALLENGE_LOG;
    
    IF v_ultimo_lote IS NULL THEN
        DBMS_OUTPUT.PUT_LINE('No hay lotes en el log para procesar.');
        RETURN;
    END IF;
    
    -- Actualizar DESEMBOLSO POR FIRMA DIGITAL
    UPDATE PR.PR_CHAMPION_CHALLENGE_LOG log
    SET 
        log.tipo_desembolso = 'DESEMBOLSO POR FIRMA DIGITAL',
        log.no_credito_nuevo_core = (
            SELECT cred.no_credito
            FROM (
                SELECT cred.no_credito
                FROM pr_creditos cred
                WHERE cred.codigo_cliente = log.cod_cliente
                  AND cred.estado = 'D'
                  AND cred.f_primer_desembolso BETWEEN log.fecha_proceso AND log.fecha_proceso + 30
                  AND cred.no_credito != log.no_credito
                ORDER BY cred.f_primer_desembolso DESC
            ) cred
            WHERE ROWNUM = 1
        ),
        log.FECHA_DESEMBOLSO_CORE = (
            SELECT cred.f_primer_desembolso
            FROM (
                SELECT cred.f_primer_desembolso
                FROM pr_creditos cred
                WHERE cred.codigo_cliente = log.cod_cliente
                  AND cred.estado = 'D'
                  AND cred.f_primer_desembolso BETWEEN log.fecha_proceso AND log.fecha_proceso + 30
                  AND cred.no_credito != log.no_credito
                ORDER BY cred.f_primer_desembolso DESC
            ) cred
            WHERE ROWNUM = 1
        ),
        log.MONTO_DESEMBOLSADO = (
            SELECT cred.monto_credito
            FROM (
                SELECT cred.monto_credito
                FROM pr_creditos cred
                WHERE cred.codigo_cliente = log.cod_cliente
                  AND cred.estado = 'D'
                  AND cred.f_primer_desembolso BETWEEN log.fecha_proceso AND log.fecha_proceso + 30
                  AND cred.no_credito != log.no_credito
                ORDER BY cred.f_primer_desembolso DESC
            ) cred
            WHERE ROWNUM = 1
        ),
        log.ESTADO_FINAL_DIGITAL = (
            SELECT bit.codigo_estado
            FROM (
                SELECT bit.codigo_estado
                FROM pr_bitacora_represtamo bit
                WHERE bit.id_represtamo = log.id_represtamo
                ORDER BY bit.fecha_bitacora DESC, bit.id_bitacora DESC
            ) bit
            WHERE ROWNUM = 1
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
    
    -- Actualizar DESEMBOLSO TRADICIONAL
    UPDATE PR.PR_CHAMPION_CHALLENGE_LOG log
    SET 
        log.tipo_desembolso = 'DESEMBOLSO TRADICIONAL',
        log.no_credito_nuevo_core = (
            SELECT cred.no_credito
            FROM (
                SELECT cred.no_credito
                FROM pr_creditos cred
                WHERE cred.codigo_cliente = log.cod_cliente
                  AND cred.estado = 'D'
                  AND cred.f_primer_desembolso BETWEEN log.fecha_proceso AND log.fecha_proceso + 30
                  AND cred.no_credito != log.no_credito
                ORDER BY cred.f_primer_desembolso DESC
            ) cred
            WHERE ROWNUM = 1
        ),
        log.FECHA_DESEMBOLSO_CORE = (
            SELECT cred.f_primer_desembolso
            FROM (
                SELECT cred.f_primer_desembolso
                FROM pr_creditos cred
                WHERE cred.codigo_cliente = log.cod_cliente
                  AND cred.estado = 'D'
                  AND cred.f_primer_desembolso BETWEEN log.fecha_proceso AND log.fecha_proceso + 30
                  AND cred.no_credito != log.no_credito
                ORDER BY cred.f_primer_desembolso DESC
            ) cred
            WHERE ROWNUM = 1
        ),
        log.MONTO_DESEMBOLSADO = (
            SELECT cred.monto_credito
            FROM (
                SELECT cred.monto_credito
                FROM pr_creditos cred
                WHERE cred.codigo_cliente = log.cod_cliente
                  AND cred.estado = 'D'
                  AND cred.f_primer_desembolso BETWEEN log.fecha_proceso AND log.fecha_proceso + 30
                  AND cred.no_credito != log.no_credito
                ORDER BY cred.f_primer_desembolso DESC
            ) cred
            WHERE ROWNUM = 1
        ),
        log.ESTADO_FINAL_DIGITAL = (
            SELECT bit.codigo_estado
            FROM (
                SELECT bit.codigo_estado
                FROM pr_bitacora_represtamo bit
                WHERE bit.id_represtamo = log.id_represtamo
                ORDER BY bit.fecha_bitacora DESC, bit.id_bitacora DESC
            ) bit
            WHERE ROWNUM = 1
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
    
    -- Actualizar DESEMBOLSO POR OFICINA
    UPDATE PR.PR_CHAMPION_CHALLENGE_LOG log
    SET 
        log.tipo_desembolso = 'DESEMBOLSO POR OFICINA',
        log.no_credito_nuevo_core = (
            SELECT cred.no_credito
            FROM (
                SELECT cred.no_credito
                FROM pr_creditos cred
                WHERE cred.codigo_cliente = log.cod_cliente
                  AND cred.estado = 'D'
                  AND cred.f_primer_desembolso BETWEEN log.fecha_proceso AND log.fecha_proceso + 30
                  AND cred.no_credito != log.no_credito
                ORDER BY cred.f_primer_desembolso DESC
            ) cred
            WHERE ROWNUM = 1
        ),
        log.FECHA_DESEMBOLSO_CORE = (
            SELECT cred.f_primer_desembolso
            FROM (
                SELECT cred.f_primer_desembolso
                FROM pr_creditos cred
                WHERE cred.codigo_cliente = log.cod_cliente
                  AND cred.estado = 'D'
                  AND cred.f_primer_desembolso BETWEEN log.fecha_proceso AND log.fecha_proceso + 30
                  AND cred.no_credito != log.no_credito
                ORDER BY cred.f_primer_desembolso DESC
            ) cred
            WHERE ROWNUM = 1
        ),
        log.MONTO_DESEMBOLSADO = (
            SELECT cred.monto_credito
            FROM (
                SELECT cred.monto_credito
                FROM pr_creditos cred
                WHERE cred.codigo_cliente = log.cod_cliente
                  AND cred.estado = 'D'
                  AND cred.f_primer_desembolso BETWEEN log.fecha_proceso AND log.fecha_proceso + 30
                  AND cred.no_credito != log.no_credito
                ORDER BY cred.f_primer_desembolso DESC
            ) cred
            WHERE ROWNUM = 1
        ),
        log.ESTADO_FINAL_DIGITAL = (
            SELECT bit.codigo_estado
            FROM (
                SELECT bit.codigo_estado
                FROM pr_bitacora_represtamo bit
                WHERE bit.id_represtamo = log.id_represtamo
                ORDER BY bit.fecha_bitacora DESC, bit.id_bitacora DESC
            ) bit
            WHERE ROWNUM = 1
        )
    WHERE log.id_lote = v_ultimo_lote
        AND log.grupo_asignado = 'CHALLENGER'
        AND log.tipo_desembolso IS NULL
        AND (
            SELECT cred.no_credito
            FROM (
                SELECT cred.no_credito
                FROM pr_creditos cred
                WHERE cred.codigo_cliente = log.cod_cliente
                  AND cred.estado = 'D'
                  AND cred.f_primer_desembolso BETWEEN log.fecha_proceso AND log.fecha_proceso + 30
                  AND cred.no_credito != log.no_credito
                ORDER BY cred.f_primer_desembolso DESC
            ) cred
            WHERE ROWNUM = 1
        ) IS NOT NULL;
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Proceso completado exitosamente para el lote: ' || v_ultimo_lote);
        
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('No se guardó ningún cambio.');
        ROLLBACK;
        RAISE;
END ACTUALIZAR_CHAMPION_CHALLENGE;
END PR_PKG_REPRESTAMOS;
/