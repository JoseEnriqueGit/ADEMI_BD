-- ============================================================================
-- Valida el estado ACTUAL de uno o varios represtamos en pr.pr_represtamos
-- y confirma si caen dentro de la lista de la card "Total Preaprobados"
-- ============================================================================
-- Uso: cambiar los IDs en la clausula IN

SELECT
    r.id_represtamo,
    r.estado,
    r.mto_preaprobado,
    r.fecha_proceso,
    r.codigo_empresa,
    CASE WHEN r.estado IN ('AP','AYR','BLI','BLP','CP','CRN','RZ','MS','EP','LA','NR','NP','CRA','CRD','CRV','CRS','SC')
         THEN 'SI cuenta en Total Preaprobados'
         ELSE 'NO cuenta'
    END AS validacion_preaprobados,
    CASE WHEN r.estado IN ('CP','MS','NR')
         THEN 'SI cuenta en Disponible'
         ELSE 'NO cuenta'
    END AS validacion_disponible
FROM pr.pr_represtamos r
WHERE r.id_represtamo IN (
    -- Coloca aqui los IDs a validar:
    2603881386,
    2503303053
);
