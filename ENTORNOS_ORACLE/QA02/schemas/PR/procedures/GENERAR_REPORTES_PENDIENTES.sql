CREATE OR REPLACE procedure PR.generar_reportes_pendientes(pnocredito   in varchar2) is
  cursor crep is
    select *
    from pr.reportes_pendientes_v c
    where (c.no_credito = pnocredito or pnocredito is null)
      and trunc(c.fecha_adicion) >= (sysdate - 3); --to_date(pa.obt_parametros('1', 'PA', 'FECHA_PROCESO_HELADO'),'dd/mm/yyyy'); --ChangeNum 20240419 JoseEsteban
      --and rownum <= 50;
    verror_reporte      varchar2(4000);
--
begin
    for reg in crep
    loop
        if reg.tipopersona = 'CLIENTE' then
            -- Generar Reportes del Cliente
            begin
                pr.generar_reportes_prestamo(reg.codigo_empresa,
                                             reg.no_credito, -- pCreditoNuevo      ,
                                             null, --pCreditoAnterior   ,
                                             false, --pValidaReprestamo  ,
                                             verror_reporte);
            exception when others then
                dbms_output.put_line('Error en ' || reg.tipopersona||' '||sqlerrm);
            end;
        elsif reg.tipopersona in ('CODEUDOR','FIADOR') then
            -- Generar Reportes de Fiador Codeudor
            begin
                pr.generar_rep_fiadorcodeudor( pcodigoempresa     => reg.codigo_empresa,
                                               pcodigopersona     => reg.codigo_cliente,
                                               ptipo              => case when reg.tipopersona = 'FIADOR' then 'F' when reg.tipopersona = 'CODEUDOR' then 'O' end,      --'O' = Codeudor
                                               pcreditonuevo      => reg.no_credito,
                                               pcreditoanterior   => null,
                                               pvalidareprestamo  => false,
                                               perror             => verror_reporte);
            exception when others then
                dbms_output.put_line('Error en ' || reg.tipopersona||' '||sqlerrm);
            end;
        end if;
    end loop;
end;
/
