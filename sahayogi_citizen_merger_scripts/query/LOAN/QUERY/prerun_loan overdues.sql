
use PPIVSahayogiVBL;

Declare @MigDate date, @v_MigDate nvarchar(15)
set @MigDate = (select LastDay from ControlTable);


--DECLARE @Next_Quarter_End nvarchar(15)
--set @Next_Quarter_End = (select REPLACE(REPLACE(CONVERT(VARCHAR,Next_Quarter_End,106), ' ','-'), ',','')from test.dbo.Next_IntRun_Date)
IF OBJECT_ID('tempdb.dbo.#OverDues', 'U') IS NOT NULL
  DROP TABLE #OverDues;

select * into #OverDues from (
select ReferenceNo,BranchCode,
sum(isnull(IntOverDues,0)) as IntOver,
sum(isnull(IntOnIntOverDues,0)) AS intonint,
sum(isnull(IntOnPriOverDues,0)) as intonpri,
sum(isnull(IntOnIntOverDues,0))+sum(isnull(IntOnPriOverDues,0)) as PenalOver,
sum(IntOverDues)+sum(isnull(IntOnIntOverDues,0))+sum(isnull(IntOnPriOverDues,0)) as OverDuesall
from FINMIG.dbo.PastDue group by ReferenceNo,BranchCode
)x


--select IntOverDues+IntOnIntOverDues+IntOnPriOverDues  from #PastDue where ReferenceNo ='S18256223202'
IF OBJECT_ID('tempdb.dbo.#test1', 'U') IS NOT NULL
  DROP TABLE #test1;

select * into #test1 from (
SELECT 
'INT'	AS	INDICATOR                 
,''	AS	ACID                      
,ForAcid AS	FORACID                   
,CyDesc AS	CRNCY_CODE                
,fa.BranchCode AS SOL_ID
,fa.AcType
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
,T_LoanType  
,fa.MainCode
,fa.BranchCode
,IntOver
,intonint
,intonpri
,PenalOver
,IntDrAmt_IntAccrued
,ISNULL(IntDrAmt_IntAccrued-isnull(OverDuesall,0),0) NRML_ACCRUED_AMOUNT_DR       
,ISNULL(IntDrAmt_IntAccrued-isnull(OverDuesall,0),0) AS	NRML_BOOKED_AMOUNT_DR     
,''	AS	PENALINT_ACCRUED_AMOUNT_DR
,''	AS	PENALINT_BOOKED_AMOUNT_DR 
,''	AS	PENAL_INTEREST_AMOUNT_DR
 from FINMIG.dbo.ForAcidLAA fa
 left join #OverDues dl
on fa.MainCode = dl.ReferenceNo and fa.BranchCode=dl.BranchCode
--LEFT JOIN LoanMaster lm ON m.MainCode = lm.MainCode AND m.BranchCode = lm.BranchCode
where 1=1--round(abs(Balance),2)=0 
and isnull(ForAcid,'')<>''
and IntDrAmt_IntAccrued<isnull(OverDuesall,0)
)x

--FOR NORMAL INTEREST OVER DUES
IF OBJECT_ID('FINMIG.dbo.OverDuesGreaterThanINT', 'U') IS NOT NULL
  DROP TABLE FINMIG.dbo.OverDuesGreaterThanINT;

SELECT 
t1.MainCode as ReferenceNo,
t1.AcType,
isnull(IntOver,0) as IntOver,
isnull(PenalOver,0) as PenalOver,
NRML_ACCRUED_AMOUNT_DR as diff,
case when IntOver>IntDrAmt_IntAccrued then 'INDEM'
	ELSE 'PIDEM' end AS FLOWID
into  FINMIG.dbo.OverDuesGreaterThanINT 
from #test1 t1 
--JOIN Master t2 on t1.MainCode =t2.MainCode and t1.BranchCode=t2.BranchCode




--FOR PENAL POST MIGRATION
IF OBJECT_ID('FINMIG.dbo.LOAN_OVERDUE_PENAL', 'U') IS NOT NULL
  DROP TABLE FINMIG.dbo.LOAN_OVERDUE_PENAL;





SELECT t1.MainCode,
isnull(IntOver,0) as IntOver,
isnull(PenalOver,0) as PenalOver,
intonint AS IntOnInt, 
intonpri as IntOnPri,
NRML_ACCRUED_AMOUNT_DR as diffint,
case when ABS(NRML_ACCRUED_AMOUNT_DR)<=intonpri then 'PIDEM'
	WHEN  ABS(NRML_ACCRUED_AMOUNT_DR)<=intonint then 'OIDEM'
	WHEN  ABS(NRML_ACCRUED_AMOUNT_DR)=PenalOver AND ISNULL(IntOver,0)='0'  then 'NODEM'
	ELSE 'INDEM' end AS FLOWID
into  FINMIG.dbo.LOAN_OVERDUE_PENAL 
from #test1 t1
--JOIN Master t2 on t1.MainCode =t2.MainCode and t1.BranchCode=t2.BranchCode

--CHECK 'NODEM' TYPE OF RECORD IN FINMIG.dbo.LOAN_OVERDUE_PENAL 
/*
select * from FINMIG.dbo.LOAN_OVERDUE_PENAL
where FLOWID='NODEM'
*/
