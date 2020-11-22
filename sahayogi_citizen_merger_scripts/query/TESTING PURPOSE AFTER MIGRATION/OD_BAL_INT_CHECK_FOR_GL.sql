
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

select 
f1.GoodBaln,
f1.BranchCode,
f1.AcType,
F_SCHEME_CODE
, case when ISNULL(M.IntDrAmt, 0) < 0 then 0 else ISNULL(M.IntDrAmt, 0) end as INTEREST

FROM FINMIG..ForAcidOD f1 join Master M
on f1.MainCode=M.MainCode and f1.BranchCode=M.BranchCode
left join #OverDues pd on 
f1.MainCode = pd.ReferenceNo and f1.BranchCode=pd.BranchCode
where 1=1
order by f1.ForAcid

--197501 rows in third migration
