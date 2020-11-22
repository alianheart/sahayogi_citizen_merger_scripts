USE PPIVSahayogiVBL
Declare @MigDate date, @v_MigDate nvarchar(15)
set @MigDate =(select Today from ControlTable);
set @v_MigDate=REPLACE(REPLACE(CONVERT(VARCHAR,@MigDate,105), ' ','-'), ',','')

--CS005_OD

select 
'BAL' indicator	,
t1.MainCode,
ForAcid as foracid,
RIGHT(SPACE(17)+CAST(round(t1.GoodBaln,2) AS VARCHAR(17)),17) tran_amt                 ,
@v_MigDate AS tran_date,  --'MIGRATION DATE' 
CyDesc as tran_crncy_code,
F.F_SolId sol_id                   ,
'' dummy
from Master t1 
join CurrencyTable t3 on t1.CyCode =  t3.CyCode
join  FINMIG.dbo.ForAcidOD F
on t1.MainCode= F.MainCode
where
t1.BranchCode not in('242','243')
AND IsBlocked <> 'C'
and isnull(round(t1.GoodBaln,2),0)<>0
--and t1.MainCode = '00404300072500000003'
order by sol_id,tran_crncy_code

--7949 rows IN THIRD MIGRATION 
