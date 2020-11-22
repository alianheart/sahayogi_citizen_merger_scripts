
--RL006 script

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
IntOverDues as flow_amt_indem,
isnull(IntOnIntOverDues,0)+isnull(IntOnPriOverDues,0) as flow_amt_pidem,
PriOverDues AS flow_amt_prdem,
dmd_date 
from FINMIG.dbo.PastDue where
ReferenceNo not in (select ReferenceNo from FINMIG..OverDuesGreaterThanINT)
and ReferenceNo not in (select MainCode from Master where IntDrAmt <= 0)

/*
union all

select 
BranchCode,
ReferenceNo,
Flow_ID,
0 as flow_amt_indem,
0 as flow_amt_pidem,
PriOverDues AS flow_amt_prdem,
dmd_date 
from FINMIG.dbo.PastDue where
ReferenceNo in (select ReferenceNo from FINMIG..OverDuesGreaterThanINT where ReferenceNo = '00303400027995000003')
and PriOverDues <> 0 
*/

UNION ALL

select 
BranchCode,
t1.ReferenceNo,
Flow_ID,
sum(IntOverDues) as flow_amt_indem,
case when Flow_ID ='PIDEM' THEN sum(isnull(IntOnIntOverDues,0)+isnull(IntOnPriOverDues,0))+CAST(diff AS NUMERIC(17,2)) 
	ELSE '0.00' END as flow_amt_pidem,
sum(PriOverDues) AS flow_amt_prdem,
max(dmd_date) dmd_date
from FINMIG.dbo.PastDue t1 join 
FINMIG.dbo.OverDuesGreaterThanINT t2 on t1.ReferenceNo=t2.ReferenceNo
where FLOWID='PIDEM'
and t1.ReferenceNo not in (select MainCode from Master where IntDrAmt <= 0)
group by BranchCode,t1.ReferenceNo,Flow_ID,diff

union all 

select 
BranchCode,
t1.ReferenceNo,
Flow_ID,
case when Flow_ID ='INDEM' THEN sum(IntOverDues)+CAST(diff AS NUMERIC(17,2))
	ELSE '0.00' END as flow_amt_indem,
sum(isnull(IntOnIntOverDues,0)+isnull(IntOnPriOverDues,0)) as flow_amt_pidem,
sum(PriOverDues) AS flow_amt_prdem,
max(dmd_date) dmd_date
from FINMIG.dbo.PastDue t1 join 
FINMIG.dbo.OverDuesGreaterThanINT t2 on t1.ReferenceNo=t2.ReferenceNo
where FLOWID='INDEM'
and t1.ReferenceNo not in (select MainCode from Master where IntDrAmt <= 0)
group by BranchCode,t1.ReferenceNo,Flow_ID,diff

)x



SELECT 
--'I' as indi -- only for data extraction purpose
ForAcid AS foracid
,ReferenceNo
,case when pdl.dmd_date<(select AcOpenDate from Master M where pdl.ReferenceNo = M.MainCode) then (select convert(varchar,AcOpenDate,105) from Master M where pdl.ReferenceNo = M.MainCode)
 else CONVERT(VARCHAR(10),pdl.dmd_date,105) end AS dmd_date
,case when pdl.dmd_date<(select AcOpenDate from Master M where pdl.ReferenceNo = M.MainCode) then (select convert(varchar,AcOpenDate,105) from Master M where pdl.ReferenceNo = M.MainCode)
 else CONVERT(VARCHAR(10),pdl.dmd_date,105) end  AS dmd_eff_date
,Flow_ID dmd_flow_id
--,RIGHT(SPACE(17)+CAST(round(pdl.flow_amt,2) AS VARCHAR(17)),17) AS dmd_amt
--, RIGHT(SPACE(17)+cast(cast(pdl.flow_amt_indem as ) as nvarchar(17)),17) as test
,case when Flow_ID='INDEM' THEN RIGHT(SPACE(17)+CAST(ROUND(CAST (flow_amt_indem AS decimal(17,2)),2) AS VARCHAR(17)),17)
	 when  Flow_ID='PIDEM' THEN RIGHT(SPACE(17)+CAST(ROUND(CAST (flow_amt_pidem AS decimal(17,2)),2) AS VARCHAR(17)),17)
	 else RIGHT(SPACE(17)+CAST(round(pdl.flow_amt_prdem,2) AS VARCHAR(17)),17) end AS dmd_amt
,'N' AS late_fee_applied
,RIGHT(SPACE(17)+CAST('' AS VARCHAR(17)),17) AS late_fee_amount
,''  AS late_fee_date
,''  AS latefee_status_flg
,''  AS late_fee_currency_code
,''  AS dmd_ovdu_date
,RIGHT(SPACE(17)+CAST('' AS VARCHAR(17)),17) AS accrued_penal_interest_amount
,''  AS iban_number
FROM #loan_temp pdl
join  FINMIG.dbo.ForAcidLAA F
on pdl.ReferenceNo = F.MainCode and pdl.BranchCode =F.BranchCode
where 1=1
--and ForAcid ='1010100000002655'
and (round(pdl.flow_amt_indem,2)>0 or round(pdl.flow_amt_pidem,2)>0 or round(pdl.flow_amt_prdem,2)>0 )

