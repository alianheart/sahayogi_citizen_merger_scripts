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

select 
'LAA' INDICATOR                 
,'' ACID                      
, ForAcid FORACID                   
,CyDesc CRNCY_CODE                
,F_SolId SOL_ID                    
, '' INTEREST_CALC_UPTO_DATE_CR
, '' AS ACCRUED_UPTO_DATE_CR  
, '' AS BOOKED_UPTO_DATE_CR   
,'' XFER_INT_AMT_CR           
,'' AS NRML_ACCRUED_AMOUNT_CR
--,ISNULL(M.IntCrAmt,0) AS NRML_ACCRUED_AMOUNT_CR    
,'' AS NRML_BOOKED_AMOUNT_CR     
,REPLACE(REPLACE(CONVERT(VARCHAR,@MigDate,105), ' ','-'), ',','') INTEREST_CALC_UPTO_DATE_DR
,REPLACE(REPLACE(CONVERT(VARCHAR,@MigDate,105), ' ','-'), ',','') AS ACCRUED_UPTO_DATE_DR           
,REPLACE(REPLACE(CONVERT(VARCHAR,@MigDate,105), ' ','-'), ',','') AS BOOKED_UPTO_DATE_DR       
,'' XFER_INT_AMT_DR           
,case when ISNULL(IntDrAmt_IntAccrued-isnull(OverDuesall,0),0) < 0 then 0
else ISNULL(IntDrAmt_IntAccrued-isnull(OverDuesall,0),0) end AS NRML_ACCRUED_AMOUNT_DR
 

,case when ISNULL(IntDrAmt_IntAccrued-isnull(OverDuesall,0),0) < 0 then 0
else ISNULL(IntDrAmt_IntAccrued-isnull(OverDuesall,0),0) end AS NRML_BOOKED_AMOUNT_DR     

,'' PENALINT_ACCRUED_AMOUNT_DR
,'' PENALINT_BOOKED_AMOUNT_DR 
,'' PENAL_INTEREST_AMOUNT_DR 
 from FINMIG.dbo.ForAcidLAA fa
 left join FINMIG.dbo.#PastDue dl
on fa.MainCode = dl.ReferenceNo and fa.BranchCode=dl.BranchCode
--LEFT JOIN LoanMaster lm ON m.MainCode = lm.MainCode AND m.BranchCode = lm.BranchCode
where 1=1--round(abs(Balance),2)=0 
--and fa.MainCode = '00103300051620000003'
and isnull(ForAcid,'')<>''
--and IntDrAmt_IntAccrued<isnull(OverDuesall,0)
ORDER BY ForAcid
