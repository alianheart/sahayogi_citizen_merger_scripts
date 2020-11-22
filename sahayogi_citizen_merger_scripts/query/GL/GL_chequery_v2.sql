/*
ALTER TABLE FINMIG.dbo.GL_MAPPING
ALTER COLUMN NPR_BALANCE MONEY

ALTER TABLE FINMIG.dbo.GL_MAPPING
ALTER COLUMN BASE_CCY  MONEY
*/
Declare @MigDate date, @v_MigDate nvarchar(15)
set @MigDate = (select Today from ControlTable);
SELECT x.sol_id,ROUND(SUM(ref_amt),2) as GL_Dif_Amount from (
select  
c.CyDesc AS tran_crncy_code
,gl.SOLID AS sol_id
, CASE WHEN BASE_CCY<0 THEN 'D' ELSE 'C' END AS part_tran_type
,RIGHT(SPACE(17)+CAST(ABS(ROUND(NPR_BALANCE,2)) AS VARCHAR(17)),17) AS tran_amt
,ROUND(NPR_BALANCE,2) AS ref_amt

FROM  FINMIG.dbo.GL_MAPPING gl 
		join CurrencyTable c on c.CyCode=CCYCODE
WHERE round(NPR_BALANCE,2)<>'0'
--and m.BranchCode between '001' and '064' 
--AND  gl.SOLID='067'

)x
group by sol_id
 having SUM(ROUND(ref_amt,2))<>0
order by 1
--select * FROM  FINMIG.dbo.GL_MAPPING where SOLID = '015'


select * from FINMIG.dbo.GL_MAPPING where ABS(ISNULL(BASE_CCY,0))<=0.09
AND CCYCODE<>'01'

/*
update FINMIG..GL_MAPPING
set FORACID_WITH_MIGRA = '999'+substring(FORACID_WITH_MIGRA, 4, 11)
where FORACID_WITH_MIGRA in ('09601294070502', '09601294070602')


select FORACID_WITH_MIGRA, '991'+substring(FORACID_WITH_MIGRA, 4, 11), *
from FINMIG..GL_MAPPING where FORACID_WITH_MIGRA in ('99101300170101', '09701300170101')
*/