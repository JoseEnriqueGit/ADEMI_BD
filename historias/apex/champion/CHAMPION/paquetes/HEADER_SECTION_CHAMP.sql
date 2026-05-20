    PROCEDURE P_SPLIT_CHAMPION_CHALLENGER(
        p_id_lote            IN NUMBER,
        p_nombre_campana     IN VARCHAR2,
        p_challenger_ratio   IN NUMBER DEFAULT 0.40,
        p_error              OUT VARCHAR2);
    PROCEDURE P_EJECUTAR_CAMPANA_CHALLENGE(
    p_error OUT VARCHAR2
    );
    PROCEDURE ACTUALIZAR_CHAMPION_CHALLENGE;