--TD004 SCRIPT
use PPIVSahayogiVBL
DECLARE @MigDate DATE, @v_MigDate nvarchar(15),@MTH DATE,@mig_MONTH nvarchar(15),
@QTR DATE, @mig_QTR nvarchar(15), @HYR DATE,@mig_HYR nvarchar(15), @YR DATE, @mig_YR nvarchar(15),@MigDate1 DATE, @v_MigDate1 nvarchar(15)


set @MigDate = (select Today from ControlTable); --changed in sahayogi migration
--set @MigDate = (select Today from ControlTable);
set @v_MigDate=REPLACE(REPLACE(CONVERT(VARCHAR,@MigDate,105), ' ','-'), ',','')

set @MigDate1 = (select Today from ControlTable);
set @v_MigDate1=REPLACE(REPLACE(CONVERT(VARCHAR,@MigDate1,105), ' ','-'), ',','')

set @MTH = (select dateadd(day,1,LastMonthEnd) from ControlTable);
set @mig_MONTH=REPLACE(REPLACE(CONVERT(VARCHAR,@MTH,105), ' ','-'), ',','')

set @QTR = (select dateadd(day,1,LastQtrEnd) from ControlTable);
set @mig_QTR=REPLACE(REPLACE(CONVERT(VARCHAR,@QTR,105), ' ','-'), ',','')

set @HYR = (select dateadd(day,1,LastHalfYrEnd) from ControlTable);
set @mig_HYR=REPLACE(REPLACE(CONVERT(VARCHAR,@HYR,105), ' ','-'), ',','')

set @YR = (select dateadd(day,1,LastYearEnd) from ControlTable);
set @mig_YR=REPLACE(REPLACE(CONVERT(VARCHAR,@YR,105), ' ','-'), ',','')
--TD004 MASTER
Declare @BACID nvarchar(15)= '080070101';

IF OBJECT_ID('tempdb.dbo.#TD004_PI', 'U') IS NOT NULL
  DROP TABLE #TD004_PI; 

select * into #TD004_PI from(
SELECT 
'T' AS tran_type  
,'BI' AS tran_sub_type 
,ForAcid as foracid1
,ForAcid as foracid
,CyDesc as tran_crncy_code
,RIGHT(SPACE(17)+CAST(DealAmt_Balance AS VARCHAR(17)),17) AS tran_amt
,'C' AS part_tran_type 
--,CONVERT(VARCHAR,isnull(DealOpenDate,AcOpenDate),105) AS value_date  
--,@v_MigDate as value_date

,case when fa.AcType in ('2A', '2B') then @v_MigDate
else 
case when IntPostFrqCr = '1' AND AcOpenDate<@MigDate then @v_MigDate
	when IntPostFrqCr = '4' AND AcOpenDate<@MTH then @mig_MONTH
	when IntPostFrqCr = '5' AND AcOpenDate<@QTR then @mig_QTR
	when IntPostFrqCr = '6' AND AcOpenDate<@HYR then @mig_HYR
	when IntPostFrqCr = '7' AND AcOpenDate<@YR then @mig_YR
	else convert(VARCHAR,AcOpenDate,105) --changed in sahayogi migration AcOpenDate
end
	end as value_date






--,@v_MigDate1 as value_date
,'' AS agent_emp_ind
,'' AS agent_code
/*
,case when AcType = '1C' then 'NI'
	  when AcType = '1Y' then 'II'
	  else 'PI' end AS flow_code
*/	  
,fa.F_SolId as BranchCode
,'PI' AS flow_code	   
,'N' AS transaction_end_indicator
,1 as SerialNumber
from FINMIG.dbo.ForAcidTD fa join DealTable t1
on fa.MainCode = t1.MainCode and fa.ReferenceNo = t1.ReferenceNo
join CurrencyTable C
on fa.CyCode = C.CyCode
--and BranchCode between '001' and '064'
and TD_TYPE = 'DEAL'
and isnull(fa.ForAcid, '') <> '' 
where IsMatured <> 'T'
--and fa.MainCode <> '91310310201' --neapl rastra bank
--AND ForAcid NOT IN ( '0560100000002155','0560100000001155')
union all


--SOL01080070101 MIGRA TDA
SELECT 
'T' AS tran_type  
,'BI' AS tran_sub_type 
,ForAcid as foracid1
,F_SolId+fa.CyCode+@BACID as foracid
,CyDesc as tran_crncy_code
,RIGHT(SPACE(17)+CAST(DealAmt_Balance AS VARCHAR(17)),17) AS tran_amt
,'D' AS part_tran_type 
--,CONVERT(VARCHAR,isnull(DealOpenDate,AcOpenDate),105) AS value_date  
--,@v_MigDate as value_date

/*
,case when IntPostFrqCr = '1' AND AcOpenDate<@MigDate then @v_MigDate
	when IntPostFrqCr = '4' AND AcOpenDate<@MTH then @mig_MONTH
	when IntPostFrqCr = '5' AND AcOpenDate<@QTR then @mig_QTR
	when IntPostFrqCr = '6' AND AcOpenDate<@HYR then @mig_HYR
	when IntPostFrqCr = '7' AND AcOpenDate<@YR then @mig_YR
	else convert(VARCHAR,AcOpenDate,105)
	end as value_date
*/
 ,convert(VARCHAR,@v_MigDate1,105) as value_date --changed in sahayogi migration AcOpenDate
--,@v_MigDate1 as value_date
,'' AS agent_emp_ind
,'' AS agent_code
/*,case when AcType = '1C' then 'NI'
	  when AcType = '1Y' then 'II'
	  else 'PI' end AS flow_code
*/	  
,fa.F_SolId as BranchCode
,'PI' AS flow_code
,'N' AS transaction_end_indicator
,ROW_NUMBER() OVER( PARTITION BY fa.BranchCode,fa.CyCode ORDER BY ForAcid,fa.BranchCode,fa.CyCode) AS SerialNumber
from FINMIG.dbo.ForAcidTD fa
join DealTable t1
on fa.MainCode = t1.MainCode and fa.ReferenceNo = t1.ReferenceNo
join CurrencyTable C
on fa.CyCode = C.CyCode
--and BranchCode between '001' and '064'
and TD_TYPE = 'DEAL'
and isnull(fa.ForAcid, '') <> ''
where IsMatured <> 'T'
--and fa.MainCode <> '91310310201' --neapl rastra bank
--AND ForAcid NOT IN ( '0560100000002155','0560100000001155')
--and mt.BranchCode = '001' and mt.CyCode ='01'
)x
order by foracid1,part_tran_type;
--10718 rows in 5 sec


IF OBJECT_ID('tempdb.dbo.#test_serialnumber1', 'U') IS NOT NULL
  DROP TABLE #test_serialnumber1; 
select * into #test_serialnumber1 from (
select  max(SerialNumber) AS SerialNumber ,BranchCode,tran_crncy_code,'Y' transaction_end_indicator from #TD004_PI
group by BranchCode,tran_crncy_code,transaction_end_indicator 
)X order by BranchCode;




MERGE INTO #TD004_PI AS T1
USING #test_serialnumber1 AS source 
ON T1.BranchCode = source.BranchCode and T1.SerialNumber=source.SerialNumber
AND T1.tran_crncy_code=source.tran_crncy_code  AND part_tran_type ='D'
WHEN MATCHED THEN UPDATE SET T1.transaction_end_indicator = source.transaction_end_indicator;


IF OBJECT_ID('FINMIG..TD004_PI_LOOKUP', 'U') IS NOT NULL
  DROP TABLE FINMIG..TD004_PI_LOOKUP; 
SELECT * INTO FINMIG..TD004_PI_LOOKUP
FROM (SELECT
tran_type
,tran_sub_type
,foracid1
,foracid
,tran_crncy_code
,tran_amt
,part_tran_type
,value_date
,agent_emp_ind
,agent_code
,flow_code
,transaction_end_indicator
 from #TD004_PI)X 


