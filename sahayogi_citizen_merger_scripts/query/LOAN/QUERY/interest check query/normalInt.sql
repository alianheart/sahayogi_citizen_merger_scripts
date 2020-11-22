-- Query for RL025 (Customization)

--DECLARE @MIGRATION_DATE AS DATE = GETDATE()

use PPIVSahayogiVBL;

Declare @MigDate date, @v_MigDate nvarchar(15)
set @MigDate = (select LastDay from ControlTable);

--TEMP TABLE
IF OBJECT_ID('tempdb.dbo.#PastDue', 'U') IS NOT NULL
  DROP TABLE #PastDue;

  select * into #PastDue from (
select ReferenceNo,BranchCode,
sum(IntOverDues)+sum(isnull(IntOnIntOverDues,0))+sum(isnull(IntOnPriOverDues,0)) as OverDuesall
from FINMIG.dbo.PastDue group by ReferenceNo,BranchCode
)x
/*
select * from #PastDue where OverDuesall ='44.12'

SELECT SUM(OverDuesall) FROM #PastDue
WHERE ReferenceNo IN (SELECT MainCode from FINMIG..ForAcidLAA where AcType ='3S')
*/


IF OBJECT_ID('tempdb.dbo.#test', 'U') IS NOT NULL
  DROP TABLE #test;

select * into #test from (
SELECT 
'INT'	AS	INDICATOR                 
,''	AS	ACID    
,fa.AcType                 
,ForAcid AS	FORACID                   
,CyDesc AS	CRNCY_CODE                
,fa.BranchCode AS SOL_ID
,''	AS	INTEREST_CALC_UPTO_DATE_CR
,''	AS	ACCRUED_UPTO_DATE_CR      
,''	AS	BOOKED_UPTO_DATE_CR       
,''	AS	XFER_INT_AMT_CR           
,''	AS	NRML_ACCRUED_AMOUNT_CR    
,''	AS	NRML_BOOKED_AMOUNT_CR     
,REPLACE(REPLACE(CONVERT(VARCHAR,@MigDate,106), ' ','-'), ',','')	AS	INTEREST_CALC_UPTO_DATE_DR
,REPLACE(REPLACE(CONVERT(VARCHAR,@MigDate,106), ' ','-'), ',','')	AS	ACCRUED_UPTO_DATE_DR      
,REPLACE(REPLACE(CONVERT(VARCHAR,@MigDate,106), ' ','-'), ',','') 	AS	BOOKED_UPTO_DATE_DR       
,''	AS	XFER_INT_AMT_DR   
,ISNULL(IntDrAmt_IntAccrued-isnull(OverDuesall,0),0) AS NRML_ACCRUED_AMOUNT_DR  
,ISNULL(IntDrAmt_IntAccrued-isnull(OverDuesall,0),0) AS NRML_BOOKED_AMOUNT_DR   
,''	AS	PENALINT_ACCRUED_AMOUNT_DR
,''	AS	PENALINT_BOOKED_AMOUNT_DR 
,''	AS	PENAL_INTEREST_AMOUNT_DR
 from FINMIG.dbo.ForAcidLAA fa
 left join FINMIG.dbo.#PastDue dl
on fa.MainCode = dl.ReferenceNo and fa.BranchCode=dl.BranchCode
--LEFT JOIN LoanMaster lm ON m.MainCode = lm.MainCode AND m.BranchCode = lm.BranchCode
where 1=1--round(abs(Balance),2)=0 
 --AND round(IntDrAmt_IntAccrued,2)<>0
--AND m.Limit <> 0
--AND LEN(m.ClientCode) >= 8
--and fa.BranchCode between '001' and '064'
and isnull(ForAcid,'')<>''
--AND AcType ='3S'
and IntDrAmt_IntAccrued>isnull(OverDuesall,0)
)X

alter table #test
alter column NRML_ACCRUED_AMOUNT_DR float

select AcType,sum(NRML_ACCRUED_AMOUNT_DR) as NormalInt from #test
group by AcType
order by AcType



