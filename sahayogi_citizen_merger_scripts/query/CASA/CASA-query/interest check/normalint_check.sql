
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



select * into #test from (
select 
'ODA' INDICATOR                 
,'' ACID        
,f1.ForAcid FORACID 
                 
,f1.CyCode CRNCY_CODE                
,f1.BranchCode SOL_ID                    
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
,M.AcType
,M.MainCode
,ISNULL(M.IntDrAmt-isnull(OverDuesall,0),0) NRML_ACCRUED_AMOUNT_DR
--,ISNULL(M.IntDrAmt,0)AS  NRML_BOOKED_AMOUNT_DR    
--,ISNULL(M.IntDrAmt-isnull(IntOverDues,0),0) AS NRML_BOOKED_AMOUNT_DR 
,ISNULL(M.IntDrAmt-isnull(OverDuesall,0),0) AS NRML_BOOKED_AMOUNT_DR    
,'' PENALINT_ACCRUED_AMOUNT_DR
,'' PENALINT_BOOKED_AMOUNT_DR 
,'' PENAL_INTEREST_AMOUNT_DR 
FROM FINMIG..ForAcidOD f1 join Master M
on f1.MainCode=M.MainCode and f1.BranchCode=M.BranchCode
left join #OverDues pd on 
f1.MainCode = pd.ReferenceNo and f1.BranchCode=pd.BranchCode
where 1=1
--(ISNULL(ROUND(M.IntDrAmt,2),0)>0 /*and SCHM_TYPE = 'SBA'*/)
and M.IntDrAmt>isnull(OverDuesall,0)
)x
--and ForAcid IN ('0180100000004402','0680100000002404')
--group by ForAcid,f1.CyCode,f1.BranchCode,M.IntDrAmt
--order by f1.ForAcid

--197501 rows in third migration


select count(*) as total_count,sum(NRML_BOOKED_AMOUNT_DR) as total_int,AcType from #test
group by AcType
order by AcType
