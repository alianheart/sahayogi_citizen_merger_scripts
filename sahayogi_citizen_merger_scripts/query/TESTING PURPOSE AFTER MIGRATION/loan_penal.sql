
--Loan penal interest 

use PPIVSahayogiVBL;
Declare @MigDate date, @v_MigDate nvarchar(15), @BACID nvarchar(100)='MIGRA'; --<000>MIGRA_<AUD>_LAA

set @MigDate = (select Today from ControlTable);




--TEMP TABLE
IF OBJECT_ID('tempdb.dbo.#loan_temp', 'U') IS NOT NULL
  DROP TABLE #loan_temp;

select * into #loan_temp from
(
select 
BranchCode,
ReferenceNo,
Flow_ID,
IntOverDues as IntOverDues,
isnull(IntOnIntOverDues,0) AS IntOnIntOverDues,
isnull(IntOnPriOverDues,0) as IntOnPriOverDues,
PriOverDues AS PriOverDues,
dmd_date 
from FINMIG.dbo.PastDue where
ReferenceNo not in (select MainCode from FINMIG..LOAN_OVERDUE_PENAL)

UNION ALL

select 
BranchCode,
t1.ReferenceNo,
Flow_ID,
sum(IntOverDues) as IntOverDues,
SUM(isnull(IntOnIntOverDues,0)) as IntOnIntOverDues,
case when Flow_ID ='PIDEM' THEN SUM(isnull(IntOnPriOverDues,0))+CAST(diffint AS NUMERIC(17,2)) 
	ELSE '0.00' END as IntOnPriOverDues,
SUM(PriOverDues) AS PriOverDues,
max(dmd_date) dmd_date
from FINMIG.dbo.PastDue t1 join 
FINMIG.dbo.LOAN_OVERDUE_PENAL t2 on t1.ReferenceNo=t2.MainCode
where FLOWID='PIDEM'
group by BranchCode,t1.ReferenceNo,Flow_ID,diffint

union all 

select 
BranchCode,
t1.ReferenceNo,
Flow_ID,
sum(IntOverDues) as IntOverDues,
case when ISNULL(SUM(IntOnIntOverDues),'')<>'' THEN SUM(isnull(IntOnIntOverDues,0))+CAST(diffint AS NUMERIC(17,2)) 
	ELSE '0.00' END as IntOnIntOverDues,
SUM(isnull(IntOnPriOverDues,0)) as IntOnPriOverDues,
SUM(PriOverDues) AS PriOverDues,
max(dmd_date) dmd_date
from FINMIG.dbo.PastDue t1 join 
FINMIG.dbo.LOAN_OVERDUE_PENAL t2 on t1.ReferenceNo=t2.MainCode
where FLOWID='OIDEM'
group by BranchCode,t1.ReferenceNo,FLOWID,diffint,Flow_ID

UNION ALL 

select 
BranchCode,
t1.ReferenceNo,
Flow_ID,
case when Flow_ID ='INDEM' THEN sum(IntOverDues)+CAST(diffint AS NUMERIC(17,2))
	ELSE '0.00' END as IntOverDues,
sum(isnull(IntOnIntOverDues,0)) as IntOnIntOverDues,
sum(isnull(IntOnPriOverDues,0)) as IntOnPriOverDues,
sum(PriOverDues) AS PriOverDues,
max(dmd_date) dmd_date
from FINMIG.dbo.PastDue t1 join 
FINMIG.dbo.LOAN_OVERDUE_PENAL t2 on t1.ReferenceNo=t2.MainCode
where FLOWID='INDEM'
group by BranchCode,t1.ReferenceNo,Flow_ID,diffint
)x

--SELECT 12738.3800+191.86+149.54
select MainCode, FORACID, VALUE_DATE, INT_DUE, PNLRATE_INTDUE, PNLINTAMT_INT, PRN_DUE, PNLINTAMT_PRN, TOTAL_PNL_AMT from (
SELECT 
t1.F_SolId  AS SOL_ID
,'' AS ACID,
t1.MainCode
,t1.ForAcid AS FORACID
,t1.CyDesc  AS CRNCY_CODE
,convert(varchar,t2.dmd_date,105) AS VALUE_DATE
,sum(IntOverDues) AS INT_DUE
,t3.IntDrRate+2 as PNLRATE_INTDUE
,SUM(IntOnIntOverDues) as PNLINTAMT_INT
,SUM(t2.PriOverDues) as PRN_DUE
,'2' AS PENAL_RATE
,SUM(t2.IntOnPriOverDues) as PNLINTAMT_PRN
--,SUM(t2.IntOverDues)+SUM(t2.IntOnIntOverDues)+SUM(t2.IntOnPriOverDues) as TOTAL_PNL_AMT
,SUM(t2.IntOnIntOverDues)+SUM(t2.IntOnPriOverDues) as TOTAL_PNL_AMT ---logic given by roman dai(2018-11-23)
,'N' as DEL_FLG
from FINMIG..ForAcidLAA t1
 JOIN #loan_temp t2 on  t1.MainCode =t2.ReferenceNo and t1.BranchCode=t2.BranchCode
JOIN FINMIG.dbo.TotalLoan t3 on t1.MainCode =t3.MainCode and t1.BranchCode=t2.BranchCode
--where ReferenceNo='0480000007NP'


GROUP BY t1.BranchCode,t1.F_SolId,t1.ForAcid,t1.MainCode,t1.CyDesc,t2.dmd_date,t3.IntDrRate)v
