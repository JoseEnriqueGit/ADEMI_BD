-- ============================================================================
-- Muestra el historial completo de estados de un represtamo en la bitacora
-- y marca cuales caen en la card "Total Preaprobados" o "Disponible"
-- ============================================================================
-- Nota: pr.pr_bitacora_represtamo NO tiene columna USUARIO_ADICION.
--       Columnas disponibles: id_represtamo, id_bitacora, codigo_estado,
--       fecha_bitacora, fecha_adicion.
-- Uso: cambiar los IDs en la clausula IN

SELECT
    b.id_represtamo,
    b.id_bitacora,
    b.codigo_estado,
    b.fecha_bitacora,
    b.fecha_adicion,
    CASE WHEN b.codigo_estado IN ('AP','AYR','BLI','BLP','CP','CRN','RZ','MS','EP','LA','NR','NP','CRA','CRD','CRV','CRS','SC')
         THEN 'SI'
         ELSE 'NO'
    END AS cuenta_en_preaprobados,
    CASE WHEN b.codigo_estado IN ('CP','MS','NR')
         THEN 'SI'
         ELSE 'NO'
    END AS cuenta_en_disponible
FROM pr.pr_bitacora_represtamo b
WHERE b.id_represtamo IN (
    -- Coloca aqui los IDs a validar:
    2603881386,
    2503303053
)
ORDER BY b.id_represtamo, b.id_bitacora;
