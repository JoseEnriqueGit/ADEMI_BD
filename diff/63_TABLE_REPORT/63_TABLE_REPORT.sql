SELECT
    SR.ID_REPRESTAMO,
    T1.F_NUM_PRESTAMO,
    NVL(T1.TIPO_ARCHIVO, SUBSTR(T1.NOMBRE_ARCHIVO, 0, INSTRB(T1.NOMBRE_ARCHIVO, '_') - 1)) AS TIPO_ARCHIVO,
    T1.F_DOCUMENT_TYPE,
    SR.IDENTIFICACION,
    (SR.NOMBRES || ' ' || SR.APELLIDOS) AS CLIENTE,
    T1.URL_REPORTE,
    T1.NOMBRE_ARCHIVO,
    T1.FECHA_REPORTE,
    T1.ESTADO_REPORTE,
    T1.REIMPRIMIR
FROM
    PR.PR_SOLICITUD_REPRESTAMO SR
JOIN (
    SELECT
        CASE R.ESTADO_REPORTE
            WHEN 'E' THEN
                '<a href="' || APEX_PAGE.GET_URL(p_page => 66, p_items => 'P66_CODIGO_REPORTE,P66_ESTADO_REPORTE', p_values => R.CODIGO_REPORTE || ',P') || '">Reprocesar</a>'
            WHEN 'D' THEN
                '<a href="' || APEX_PAGE.GET_URL(p_page => 66, p_items => 'P66_CODIGO_REPORTE,P66_ESTADO_REPORTE', p_values => R.CODIGO_REPORTE || ',R') || '">Reprocesar</a>'
            WHEN 'S' THEN
                '<a href="' || APEX_PAGE.GET_URL(p_page => 66, p_items => 'P66_CODIGO_REPORTE,P66_ESTADO_REPORTE', p_values => R.CODIGO_REPORTE || ',P') || '">Reprocesar</a>'
            WHEN 'H' THEN -- Lógica Dinámica para 'RESERVADO PARA DESCARGA'
                 '<a href="' || APEX_PAGE.GET_URL(
                        p_page   => 66, 
                        p_items  => 'P66_CODIGO_REPORTE,P66_ESTADO_REPORTE', 
                        p_values => R.CODIGO_REPORTE || ',' || 
                                    CASE 
                                        WHEN R.ID_TIPO_DOCUMENTO IN ('477', '474', '452') THEN 'P' -- FEC, FUD, Conozca -> Pendiente
                                        ELSE 'R' -- Seguros, Buró, Deponente -> Robotizado
                                    END
                    ) || '">Reprocesar</a>'
            ELSE
                NULL
        END AS REIMPRIMIR,
        R.ID_APLICACION AS applicationid,
        R.ID_TIPO_DOCUMENTO AS F_DOCUMENT_TYPE,
        NULL AS TIPO_IDENTIFICACION,
        NULL AS IDENTIFICACION,
        IA.PKG_API_PKM.ObtieneParteReferencia(R.CODIGO_REFERENCIA, ':', 1) AS F_NUM_PRESTAMO,
        IA.PKG_API_PKM.ObtieneParteReferencia(R.CODIGO_REFERENCIA, ':', 2) AS F_PREST_ANTERIOR,
        NULL AS TIPO_ARCHIVO,
        NULL AS ID_TEMPFUD,
        '<a href="' || APEX_UTIL.PREPARE_URL(p_url => R.URL_REPORTE, p_checksum_type => 'PUBLIC_BOOKMARK') || '" target="_blank">Descargar</a>' AS URL_REPORTE,
        REPLACE(R.NOMBRE_ARCHIVO, ':', '_') AS NOMBRE_ARCHIVO,
        R.CODIGO_REPORTE,
        R.FECHA_REPORTE,
        R.ESTADO_REPORTE,
        NVL(R.ENVIAR_API, 'N') AS ENVIAR_API
    FROM
        PA.PA_REPORTES_AUTOMATICOS R
    WHERE
        R.URL_REPORTE IS NOT NULL
        AND R.ORIGEN_PKM = 'Represtamo'

    UNION ALL

    SELECT
        CASE R.ESTADO_REPORTE
            WHEN 'E' THEN
                '<a href="' || APEX_PAGE.GET_URL(p_page => 66, p_items => 'P66_CODIGO_REPORTE,P66_ESTADO_REPORTE', p_values => R.CODIGO_REPORTE || ',R') || '">Reprocesar</a>'
            WHEN 'D' THEN
                '<a href="' || APEX_PAGE.GET_URL(p_page => 66, p_items => 'P66_CODIGO_REPORTE,P66_ESTADO_REPORTE', p_values => R.CODIGO_REPORTE || ',R') || '">Reprocesar</a>'
            WHEN 'S' THEN
                '<a href="' || APEX_PAGE.GET_URL(p_page => 66, p_items => 'P66_CODIGO_REPORTE,P66_ESTADO_REPORTE', p_values => R.CODIGO_REPORTE || ',R') || '">Reprocesar</a>'
            WHEN 'H' THEN -- Lógica Dinámica para 'RESERVADO PARA DESCARGA'
                '<a href="' || APEX_PAGE.GET_URL(
                        p_page   => 66, 
                        p_items  => 'P66_CODIGO_REPORTE,P66_ESTADO_REPORTE', 
                        p_values => R.CODIGO_REPORTE || ',' || 
                                    CASE 
                                        WHEN R.ID_TIPO_DOCUMENTO IN ('477', '474', '452') THEN 'P' -- FEC, FUD, Conozca -> Pendiente
                                        ELSE 'R' -- Seguros, Buró, Deponente -> Robotizado
                                    END
                    ) || '">Reprocesar</a>'
            ELSE
                NULL
        END AS REIMPRIMIR,
        R.ID_APLICACION AS applicationid,
        R.ID_TIPO_DOCUMENTO AS F_DOCUMENT_TYPE,
        IA.PKG_API_PKM.ObtieneParteReferencia(R.CODIGO_REFERENCIA, ':', 1) AS TIPO_IDENTIFICACION,
        PA.Formatear_Identificacion(
            IA.PKG_API_PKM.ObtieneParteReferencia(R.CODIGO_REFERENCIA, ':', 2),
            (SELECT mascara FROM tipos_id WHERE cod_tipo_id = IA.PKG_API_PKM.ObtieneParteReferencia(R.CODIGO_REFERENCIA, ':', 1)),
            'ESPA') AS IDENTIFICACION,
        IA.PKG_API_PKM.ObtieneParteReferencia(R.CODIGO_REFERENCIA, ':', 3) AS F_NUM_PRESTAMO,
        IA.PKG_API_PKM.ObtieneParteReferencia(R.CODIGO_REFERENCIA, ':', 4) AS F_PREST_ANTERIOR,
        IA.PKG_API_PKM.ObtieneParteReferencia(R.CODIGO_REFERENCIA, ':', 5) AS TIPO_ARCHIVO,
        IA.PKG_API_PKM.ObtieneParteReferencia(R.CODIGO_REFERENCIA, ':', 6) AS ID_TEMPFUD,
        CASE R.ID_TIPO_DOCUMENTO
            WHEN '204' THEN
                '<a href="' || APEX_UTIL.PREPARE_URL(p_url =>
                (SELECT VALOR FROM PA.PA_PARAMETROS_MVP WHERE CODIGO_PARAMETRO = 'URL_DIGITAL_DOCUMENTS') || '/AcceptanceInsurance?creditNumber=' || IA.PKG_API_PKM.ObtieneParteReferencia(R.CODIGO_REFERENCIA, ':', 3), p_checksum_type => 'PUBLIC_BOOKMARK') || '" target="_blank">Descargar</a>'
            WHEN '218' THEN
                '<a href="' || APEX_UTIL.PREPARE_URL(p_url =>
                    (SELECT VALOR FROM PA.PA_PARAMETROS_MVP WHERE CODIGO_PARAMETRO = 'URL_DIGITAL_DOCUMENTS') || '/MiPymeInsurance?creditNumber=' || IA.PKG_API_PKM.ObtieneParteReferencia(R.CODIGO_REFERENCIA, ':', 3), p_checksum_type => 'PUBLIC_BOOKMARK') || '" target="_blank">Descargar</a>'
            WHEN '1850' THEN
                '<a href="' || APEX_UTIL.PREPARE_URL(p_url =>
                    (SELECT VALOR FROM PA.PA_PARAMETROS_MVP WHERE CODIGO_PARAMETRO = 'URL_DIGITAL_DOCUMENTS') || '/OptionalInsurance?creditNumber=' || IA.PKG_API_PKM.ObtieneParteReferencia(R.CODIGO_REFERENCIA, ':', 3), p_checksum_type => 'PUBLIC_BOOKMARK') || '" target="_blank">Descargar</a>'
            WHEN '451' THEN
                '<a href="' || APEX_UTIL.PREPARE_URL(p_url =>
                (SELECT VALOR FROM PA.PA_PARAMETROS_MVP WHERE CODIGO_PARAMETRO = 'URL_DIGITAL_DOCUMENTS') || '/Deponente?creditNumber=' || IA.PKG_API_PKM.ObtieneParteReferencia(R.CODIGO_REFERENCIA, ':', 3), p_checksum_type => 'PUBLIC_BOOKMARK') || '" target="_blank">Descargar</a>'
            ELSE
                R.URL_REPORTE
        END AS URL_REPORTE,
        REPLACE(R.NOMBRE_ARCHIVO, ':', '_') AS NOMBRE_ARCHIVO,
        R.CODIGO_REPORTE,
        R.FECHA_REPORTE,
        R.ESTADO_REPORTE,
        NVL(R.ENVIAR_API, 'N') AS ENVIAR_API
    FROM
        PA.PA_REPORTES_AUTOMATICOS R
    WHERE
        R.URL_REPORTE IS NULL
        AND R.ORIGEN_PKM = 'Represtamo'
) T1 ON T1.F_NUM_PRESTAMO = SR.NO_CREDITO
WHERE
    REGEXP_LIKE(T1.F_NUM_PRESTAMO, '^\d+$');