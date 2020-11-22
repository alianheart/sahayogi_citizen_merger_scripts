USE PPIVSahayogiVBL
Declare @MigDate date, @v_MigDate nvarchar(15)
set @MigDate =(select Today from ControlTable);
set @v_MigDate=REPLACE(REPLACE(CONVERT(VARCHAR,@MigDate,105), ' ','-'), ',','')

--CS005_SBA

select 
'BAL' indicator	,
ForAcid as foracid,
RIGHT(SPACE(17)+CAST(round(t1.GoodBaln,2) AS VARCHAR(17)),17) tran_amt                 ,
@v_MigDate AS tran_date,  --'MIGRATION DATE' 
CyDesc as tran_crncy_code,
F.F_SolId sol_id                   ,
'' dummy
from Master t1 
join CurrencyTable t3 on t1.CyCode =  t3.CyCode
join  FINMIG.dbo.ForAcidSBA F
on t1.MainCode= F.MainCode
where 1=1
--AND	t1.AcType not in ('01','03')
AND t1.AcType in (select ACTYPE from FINMIG..PRODUCT_MAPPING where MODULE = 'SAVING')
AND IsBlocked <> 'C'
and isnull(round(t1.GoodBaln,2),0)<>0
order by sol_id,tran_crncy_code


--290122 ROWS IN SECOND MIGRATION           



