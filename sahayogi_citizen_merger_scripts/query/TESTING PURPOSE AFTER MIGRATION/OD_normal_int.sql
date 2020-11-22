
use PPIVSahayogiVBL;

DECLARE @l_DAY DATE, @v_DAY nvarchar(15),@MTH DATE,@v_MONTH nvarchar(15), @MigDate date, @v_MigDate nvarchar(15),
@QTR DATE, @v_QTR nvarchar(15), @HYR DATE,@v_HYR nvarchar(15), @YR DATE, @v_YR nvarchar(15)

set @l_DAY = (select LastDay from ControlTable);
set @v_DAY=REPLACE(REPLACE(CONVERT(VARCHAR,@l_DAY,105), ' ','-'), ',','')

set @MigDate = (select Today from ControlTable);
set @v_MigDate=REPLACE(REPLACE(CONVERT(VARCHAR,@MigDate,105), ' ','-'), ',','')
 


--select * from #FinalMaster where ForAcid = '0010100000028505'
--TEMP TABLE
IF OBJECT_ID('tempdb.dbo.#OverDues', 'U') IS NOT NULL
  DROP TABLE #OverDues;

  select * into #OverDues from (
select ReferenceNo,BranchCode,
sum(IntOverDues)+sum(isnull(IntOnIntOverDues,0))+sum(isnull(IntOnPriOverDues,0)) as OverDuesall
from FINMIG.dbo.PastDue group by ReferenceNo,BranchCode
)x



select sum(NRML_ACCRUED_AMOUNT_DR) from (
select 
'ODA' INDICATOR                 
,'' ACID    
,f1.MainCode
,f1.ForAcid FORACID                   
,f1.CyCode CRNCY_CODE                
,f1.F_SolId SOL_ID                    
,'' AS INTEREST_CALC_UPTO_DATE_CR
,'' AS ACCRUED_UPTO_DATE_CR  
,'' AS BOOKED_UPTO_DATE_CR   
,'' XFER_INT_AMT_CR           
,'' AS  NRML_ACCRUED_AMOUNT_CR
--,ISNULL(M.IntCrAmt,0) AS NRML_ACCRUED_AMOUNT_CR    
,'' AS NRML_BOOKED_AMOUNT_CR     
,@v_DAY AS INTEREST_CALC_UPTO_DATE_DR
,@v_DAY AS ACCRUED_UPTO_DATE_DR           
,@v_DAY AS BOOKED_UPTO_DATE_DR       
,'' XFER_INT_AMT_DR   
,case when ISNULL(M.IntDrAmt-isnull(OverDuesall,0),0) < 0 then 0
else ISNULL(M.IntDrAmt-isnull(OverDuesall,0),0) end as NRML_ACCRUED_AMOUNT_DR
--,ISNULL(M.IntDrAmt,0)AS  NRML_BOOKED_AMOUNT_DR    
,--ISNULL(M.IntDrAmt-isnull(OverDuesall,0),0) AS NRML_BOOKED_AMOUNT_DR 
case when ISNULL(M.IntDrAmt-isnull(OverDuesall,0),0) < 0 then 0
else ISNULL(M.IntDrAmt-isnull(OverDuesall,0),0) end AS NRML_BOOKED_AMOUNT_DR   
,case when ISNULL(M.IntDrAmt-isnull(OverDuesall,0),0) < 0 then 0
else ISNULL(M.IntDrAmt-isnull(OverDuesall,0),0) end AS LAST_NRML_BOOKED_AMOUNT_DR 
,'' PENALINT_ACCRUED_AMOUNT_DR
,'' PENALINT_BOOKED_AMOUNT_DR 
,'' PENAL_INTEREST_AMOUNT_DR 
FROM FINMIG..ForAcidOD f1 join Master M
on f1.MainCode=M.MainCode and f1.BranchCode=M.BranchCode
left join #OverDues pd on 
f1.MainCode = pd.ReferenceNo and f1.BranchCode=pd.BranchCode
where 1=1)f
--and f1.MainCode = '00104500016435000001'
--and f1.MainCode in ('00104700010928000002', '00404300040325000003')
--order by f1.ForAcid

--197501 rows in third migration
