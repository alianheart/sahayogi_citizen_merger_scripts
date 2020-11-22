----PastDue Generation-----

Declare @MigDate date, @v_MigDate nvarchar(15), @IntCalTillDate date
select  @MigDate=Today ,@IntCalTillDate=LastDay   from ControlTable;
set @v_MigDate=REPLACE(REPLACE(CONVERT(VARCHAR,@MigDate,105), ' ','-'), ',','')


 IF OBJECT_ID('FINMIG.dbo.PastDue', 'U') IS NOT NULL
  DROP TABLE FINMIG.dbo.PastDue;

--IF OBJECT_ID('tempdb.dbo.#PastDuedList', 'U') IS NOT NULL
 -- DROP TABLE #PastDuedList;


 select * into FINMIG.dbo.PastDue --#PastDuedList
 from(
 
SELECT
P.BranchCode,
P.ReferenceNo,
'INDEM' Flow_ID,
NormalInt IntOverDues,
0 IntOnIntOverDues,
0 IntOnPriOverDues,
0 PriOverDues,
'' Remarks,
 DueDate dmd_date
 --@MigDate as RunDate

FROM PastDuedList  P (NOLOCK)
WHERE 1=1
and  P.IsIntDue='T' and  P.NormalInt<>0

Union all

SELECT
P.BranchCode,
P.ReferenceNo,
'PIDEM' Flow_ID,
0 IntOverDues,
NewPastDuedInt IntOnIntOverDues,
0 IntOnPriOverDues,
0 PriOverDues,
'' Remarks,
 DueDate dmd_date
 --@MigDate as RunDate
FROM PastDuedList  P (NOLOCK)
WHERE 1=1
 and  P.IsIntDue='T' and  P.NewPastDuedInt<>0

union all
 
  select P.BranchCode,
P.ReferenceNo,
'PIDEM' Flow_ID,  --OIDEM
0 IntOverDues,
0 IntOnIntOverDues,
NewPastDuedInt IntOnPriOverDues,
0 PriOverDues,
'OIDEM' Remarks,
DueDate dmd_date
-- ,@MigDate as RunDate
from PastDuedList P
where 1=1
and P.IsBalnDue='T'
 
union all

select pdl.BranchCode,
pdl.ReferenceNo,
'PRDEM' Flow_ID, 
0 IntOverDues,
0 IntOnIntOverDues,
0 IntOnPriOverDues,
GoodBaln PriOverDues,
'' Remarks,
DueDate dmd_date
--,@MigDate as RunDate
FROM PastDuedList pdl
--join  FINMIG.dbo.ForAcidLAA F
--on pdl.ReferenceNo = F.MainCode
WHERE IsBalnDue ='T' and GoodBaln<>0
and pdl.ReferenceNo  not in  (
select MainCode from FINMIG..ForAcidLAA where LoanType='EMI')

Union all

select
l.BranchCode,
l.MainCode ReferenceNo,
'PRDEM' FlowId,
0 IntOverDues,
0 IntOnIntOverDues,
0 IntOnPriOverDues,
(Isnull(DuePrincipal,0)-Isnull(PaidPrincipal,0)) PriOverDues,
'' Remarks,
l.DueDate
From LoanRepaySched l WHERE MainCode in (
select MainCode from FINMIG..ForAcidLAA where LoanType='EMI')
and DueDate<@MigDate and (isnull(DuePrincipal,0)-isnull(PaidPrincipal,0))>0

-- durga dai's logic

union all 

select BranchCode,ReferenceNo,Flow_ID, IntOverDues,IntOnInOverDues,InOnPriOverDues,PriOverDues, '' AS Remarks, dmd_date from(
SELECT BranchCode,'ReferenceNo'=MainCode,'Flow_ID'='INDEM',(round(IntDrAmt,2)) as IntOverDues,IntOnInOverDues=0,InOnPriOverDues=0,0 as PriOverDues,LimitExpiryDate as dmd_date FROM Master(NoLock) where MoveType='6'
and LimitExpiryDate<(select Today from ControlTable)
and MainCode not in (select ReferenceNo from PastDuedList)
and (Limit+abs(Balance)+IntDrAmt)>0
and BranchCode not in ('242','243')
and (Balance<0 or IntDrAmt>0)
 
union all
 
SELECT BranchCode,'ReferenceNo'=MainCode,'Flow_ID'='PRDEM',0 as IntOverDues,IntOnInOverDues=0,InOnPriOverDues=0,(round(Balance,2)*(-1)) as PriOverDues,LimitExpiryDate as dmd_date FROM Master(NoLock) where MoveType='6'
and LimitExpiryDate<(select Today from ControlTable)
and MainCode not in (select ReferenceNo from PastDuedList)
and (Limit+abs(Balance)+IntDrAmt)>0
and BranchCode not in ('242','243')
and (Balance<0 or IntDrAmt>0)) x where IntOverDues+PriOverDues>0)c