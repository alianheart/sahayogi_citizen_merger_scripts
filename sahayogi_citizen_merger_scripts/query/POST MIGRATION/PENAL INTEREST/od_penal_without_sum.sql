
--od penal interest 

use PPIVSahayogiVBL
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
ReferenceNo not in (select MainCode from FINMIG..OD_OVERDUE_PENAL)
and  ReferenceNo not in (select MainCode from Master where IntDrAmt <= 0)
--and ReferenceNo = '00404300040325000003'

UNION ALL

select 
BranchCode,
t1.ReferenceNo,
Flow_ID,
IntOverDues as IntOverDues,
isnull(IntOnIntOverDues,0) as IntOnIntOverDues,
case when Flow_ID ='PIDEM' THEN isnull(IntOnPriOverDues,0)
	ELSE '0.00' END as IntOnPriOverDues,
PriOverDues AS PriOverDues,
dmd_date dmd_date
from FINMIG.dbo.PastDue t1 join 
FINMIG.dbo.OD_OVERDUE_PENAL t2 on t1.ReferenceNo=t2.MainCode
where FLOWID='PIDEM' and MainCode not in (select MainCode from Master where IntDrAmt <= 0)
--and ReferenceNo = '00404300040325000003'
--group by BranchCode,t1.ReferenceNo,Flow_ID,diffint

union all 

select 
BranchCode,
t1.ReferenceNo,
Flow_ID,
IntOverDues as IntOverDues,
case when FLOWID ='OIDEM' THEN isnull(IntOnIntOverDues,0)
	ELSE '0.00' END as IntOnIntOverDues,
isnull(IntOnPriOverDues,0) as IntOnPriOverDues,
PriOverDues AS PriOverDues,
dmd_date dmd_date
from FINMIG.dbo.PastDue t1 join 
FINMIG.dbo.OD_OVERDUE_PENAL t2 on t1.ReferenceNo=t2.MainCode
where FLOWID='OIDEM' and MainCode not in (select MainCode from Master where IntDrAmt <= 0)
--and ReferenceNo = '00404300040325000003'
--group by BranchCode,t1.ReferenceNo,FLOWID,diffint,Flow_ID

UNION ALL 

select 
BranchCode,
t1.ReferenceNo,
Flow_ID,
case when Flow_ID ='INDEM' THEN IntOverDues--+CAST(diffint AS NUMERIC(17,2))
	ELSE '0.00' END as IntOverDues,
isnull(IntOnIntOverDues,0) as IntOnIntOverDues,
isnull(IntOnPriOverDues,0) as IntOnPriOverDues,
PriOverDues AS PriOverDues,
dmd_date dmd_date
from FINMIG.dbo.PastDue t1 join 
FINMIG.dbo.OD_OVERDUE_PENAL t2 on t1.ReferenceNo=t2.MainCode
where FLOWID='INDEM' and MainCode not in (select MainCode from Master where IntDrAmt <= 0)
--and ReferenceNo = '00404300040325000003'
--group by BranchCode,t1.ReferenceNo,Flow_ID,diffint
)x


--Main Query

SELECT 
t1.MainCode,
t1.F_SolId  AS SOL_ID
,'' AS ACID
,t1.ForAcid AS FORACID
,'NPR'  AS CRNCY_CODE
,convert(varchar,t2.dmd_date,105) AS VALUE_DATE
,round(cast(sum(IntOverDues) as numeric(17,2)),2) AS INT_DUE
,t3.IntDrRate+2 as PNLRATE_INTDUE
,round(cast(sum(t2.IntOnIntOverDues) as numeric(17,2)),2) as PNLINTAMT_INT
,round(cast(sum(t2.PriOverDues) as numeric(17,2)),2) as PRN_DUE
,'2' AS PENAL_RATE
,round(cast(sum(t2.IntOnPriOverDues) as numeric(17,2)),2) as PNLINTAMT_PRN
--,SUM(t2.IntOverDues)+SUM(t2.IntOnIntOverDues)+SUM(t2.IntOnPriOverDues) as TOTAL_PNL_AMT
,round(cast(sum(t2.IntOnIntOverDues) as numeric(17,2)),2)+round(cast(sum(t2.IntOnPriOverDues) as numeric(17,2)),2) as TOTAL_PNL_AMT ---logic given by roman dai(2018-11-23)
,'N' as DEL_FLG
 from FINMIG..ForAcidOD t1
 JOIN #loan_temp t2 on  t1.MainCode =t2.ReferenceNo and t1.BranchCode =t2.BranchCode
JOIN PPIVSahayogiVBL..Master t3 on t1.MainCode =t3.MainCode
--where t1.MainCode = '00500100052004000001'
GROUP BY t1.BranchCode,t1.F_SolId,t1.ForAcid,t1.MainCode,t2.dmd_date,t3.IntDrRate
order by t1.ForAcid
