/* ============================================================
   IRD-525 - Validacion QA
   Objetivo: confirmar trazabilidad guardada por represtamo.

   Reemplazar :ID_REPRESTAMO por un caso modificado desde APEX.
   ============================================================ */

SELECT b.id_represtamo,
       b.id_bitacora,
       b.codigo_estado,
       b.adicionado_por AS usuario_que_modifico,
       b.fecha_adicion AS fecha_modificacion,
       b.observaciones AS comentario_modificacion
FROM pr.pr_bitacora_represtamo b
WHERE b.id_represtamo = :ID_REPRESTAMO
ORDER BY b.id_bitacora DESC, b.fecha_adicion DESC;
