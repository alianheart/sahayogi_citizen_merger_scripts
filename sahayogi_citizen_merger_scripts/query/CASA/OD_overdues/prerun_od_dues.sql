
use PPIVSahayogiVBL;

DECLARE @l_DAY DATE, @v_DAY nvarchar(15),@MTH DATE,@v_MONTH nvarchar(15), @MigDate date, @v_MigDate nvarchar(15),
@QTR DATE, @v_QTR nvarchar(15), @HYR DATE,@v_HYR nvarchar(15), @YR DATE, @v_YR nvarchar(15)

set @l_DAY = (select LastDay from ControlTable);
set @v_DAY=REPLACE(REPLACE(CONVERT(VARCHAR,@l_DAY,105), ' ','-'), ',','')

set @MigDate = (select Today from ControlTable);
set @v_MigDate=REPLACE(REPLACE(CONVERT(VARCHAR,@MigDate,105), ' ','-'), ',','')
 


--select * from #FinalMaster where ForAcid = '0010100000028505'

IF OBJECT_ID('tempdb.dbo.#OverDues', 'U') IS NOT NULL
  DROP TABLE #OverDues;

  select * into #OverDues from (
select ReferenceNo,BranchCode,
sum(IntOverDues) as IntOver,
sum(isnull(IntOnIntOverDues,0))+sum(isnull(IntOnPriOverDues,0)) as PenalOver,
sum(isnull(IntOnIntOverDues,0)) as intonint,
sum(isnull(IntOnPriOverDues,0)) as intonpri,
sum(IntOverDues)+sum(isnull(IntOnIntOverDues,0))+sum(isnull(IntOnPriOverDues,0)) as OverDuesall
	from FINMIG.dbo.PastDue group by ReferenceNo,BranchCode
)x

IF OBJECT_ID('tempdb.dbo.#test1', 'U') IS NOT NULL
  DROP TABLE #test1;
select * into #test1 from(
select 
'ODA' INDICATOR                 
,'' ACID   
,M.BranchCode
,f1.MainCode   
,IntOver 
,PenalOver 
,intonint
,intonpri               
, f1.ForAcid FORACID                   
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
f1.MainCode = pd.ReferenceNo
where 1=1
--(ISNULL(ROUND(M.IntDrAmt,2),0)>0 /*and SCHM_TYPE = 'SBA'*/)
and M.IntDrAmt<isnull(OverDuesall,0)
)x
 --and ForAcid IN ('0180100000004402','0680100000002404')
--group by ForAcid,f1.CyCode,f1.BranchCode,M.IntDrAmt
--order by f1.ForAcid

--FOR OVERDUES

IF OBJECT_ID('FINMIG.dbo.OD_OVERDUE_GREATER', 'U') IS NOT NULL
  DROP TABLE FINMIG.dbo.OD_OVERDUE_GREATER;

SELECT t1.MainCode,
IntOver,
PenalOver,
NRML_ACCRUED_AMOUNT_DR as diffint,
case when IntOver>IntDrAmt then 'INDEM'
	ELSE 'PIDEM' end AS FLOWID
into  FINMIG.dbo.OD_OVERDUE_GREATER 
from #test1 t1 JOIN Master t2 on t1.MainCode =t2.MainCode and t1.BranchCode=t2.BranchCode


--FOR PENAL POST MIGRATION
IF OBJECT_ID('FINMIG.dbo.OD_OVERDUE_PENAL', 'U') IS NOT NULL
  DROP TABLE FINMIG.dbo.OD_OVERDUE_PENAL;

SELECT t1.MainCode,
IntOver,
PenalOver,
intonint AS IntOnInt,
intonpri as IntOnPri,
NRML_ACCRUED_AMOUNT_DR as diffint,
case when ABS(NRML_ACCRUED_AMOUNT_DR)<=intonpri then 'PIDEM'
	WHEN  ABS(NRML_ACCRUED_AMOUNT_DR)<=intonint then 'OIDEM'
	WHEN  ABS(NRML_ACCRUED_AMOUNT_DR)=PenalOver and isnull(IntOver,0)='0' then 'NODEM'
	ELSE 'INDEM' end AS FLOWID
into  FINMIG.dbo.OD_OVERDUE_PENAL 
from #test1 t1 JOIN Master t2 on t1.MainCode =t2.MainCode and t1.BranchCode=t2.BranchCode


