
use PumoriPlusCTZ1
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
dmd_date 
from FINMIG.dbo.PastDue where Flow_ID <>'PRDEM'
AND ReferenceNo not in (select ReferenceNo from FINMIG..OverDuesGreaterThanINT)

UNION ALL

select 
BranchCode,
t1.ReferenceNo,
Flow_ID,
sum(IntOverDues) as flow_amt_indem,
case when Flow_ID ='PIDEM' THEN sum(isnull(IntOnIntOverDues,0)+isnull(IntOnPriOverDues,0))+CAST(diff AS NUMERIC(17,2)) 
	ELSE '0.00' END as flow_amt_pidem,
max(dmd_date) dmd_date
from FINMIG.dbo.PastDue t1 join 
FINMIG.dbo.OverDuesGreaterThanINT t2 on t1.ReferenceNo=t2.ReferenceNo
where Flow_ID not in ('PRDEM')
AND FLOWID='PIDEM'
group by BranchCode,t1.ReferenceNo,Flow_ID,diff

union all

select 
BranchCode,
t1.ReferenceNo,
Flow_ID,
case when Flow_ID ='INDEM' THEN sum(IntOverDues)+CAST(diff AS NUMERIC(17,2))
	ELSE '0.00' END as flow_amt_indem,
sum(isnull(IntOnIntOverDues,0)+isnull(IntOnPriOverDues,0)) as flow_amt_pidem,
max(dmd_date) dmd_date
from FINMIG.dbo.PastDue t1 join 
FINMIG.dbo.OverDuesGreaterThanINT t2 on t1.ReferenceNo=t2.ReferenceNo
where Flow_ID not in ('PRDEM')
AND FLOWID='INDEM'
group by BranchCode,t1.ReferenceNo,Flow_ID,diff
)x




--mainquery
IF OBJECT_ID('tempdb.dbo.#test', 'U') IS NOT NULL
  DROP TABLE #test;
select * into #test from(
SELECT --TOP 10
f.ForAcid AS foracid1
,'T' AS tran_type
,f.AcType
,'BI' AS tran_sub_type
,f.ForAcid AS foracid
--,CASE WHEN ct.CyDesc='IRS' THEN 'INR' ELSE ct.CyDesc END AS tran_crncy_code
,f.CyDesc as tran_crncy_code
,f.BranchCode AS sol_id
--,t.flow_amt_indem as test
,case when Flow_ID='INDEM' THEN RIGHT(SPACE(17)+CAST(ROUND(CAST (t.flow_amt_indem AS decimal(17,2)),2) AS VARCHAR(17)),17)
else RIGHT(SPACE(17)+CAST(ROUND(CAST (t.flow_amt_pidem AS decimal(17,2)),2) AS VARCHAR(17)),17) end AS flow_amt  -- Need to confirm
,'D' AS part_tran_type
,'I' AS type_of_dmds
,case when t.dmd_date<(select AcOpenDate from Master M where t.ReferenceNo = M.MainCode) then (select convert(varchar,AcOpenDate,105) from Master M where t.ReferenceNo = M.MainCode)
 else CONVERT(VARCHAR(10),t.dmd_date,105) end AS value_date
,Flow_ID AS flow_id -- Need to confirm about Penal Due
,case when t.dmd_date<(select AcOpenDate from Master M where t.ReferenceNo = M.MainCode) then (select convert(varchar,AcOpenDate,105) from Master M where t.ReferenceNo = M.MainCode)
 else CONVERT(VARCHAR(10),t.dmd_date,105) end AS   dmd_date
,'N' AS last_tran_flg
,'N' AS tran_end_indicator
,'N' AS advance_payment_flg
,'' AS prepayment_type
,'' AS int_coll_on_prepayment_flg
--,m.Remarks AS tran_rmks   -- Need to confirm  (Loan Master remarks)
,f.ForAcid as tran_rmks
,convert(varchar,@MigDate,105) AS tran_particular
from #loan_temp t
--LEFT JOIN Master m on t.ReferenceNo = m.MainCode AND t.BranchCode = m.BranchCode
join FINMIG.dbo.ForAcidLAA f on 
t.ReferenceNo = f.MainCode and t.BranchCode =f.BranchCode

--t.BranchCode = f.BranchCode and f.Scheme_Type = 'LAA' --lm.MainCode = f.MainCode
where --round(m.Balance,2) <> 0 
1=1
and (t.flow_amt_indem>0 or t.flow_amt_pidem>0)
--and ForAcid ='0010100000035612'

)x


alter table #test
alter column flow_amt float

select AcType,sum(flow_amt) as overdues from #test
group by AcType
order by AcType

