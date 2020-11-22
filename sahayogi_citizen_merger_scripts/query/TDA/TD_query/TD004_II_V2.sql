--TD004 SCRIPT
use PPIVSahayogiVBL
DECLARE @MigDate DATE, @v_MigDate nvarchar(15),@MTH DATE,@mig_MONTH nvarchar(15),
@QTR DATE, @mig_QTR nvarchar(15), @HYR DATE,@mig_HYR nvarchar(15), @YR DATE, @mig_YR nvarchar(15),@MigDate1 DATE, @v_MigDate1 nvarchar(15)


set @MigDate = (select dateadd(day,1,Today) from ControlTable);
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
SELECT 
'T' AS tran_type  
,'BI' AS tran_sub_type 
,ForAcid as foracid1
,ForAcid as foracid
,CyDesc as tran_crncy_code
,RIGHT(SPACE(17)+CAST('0.00' AS VARCHAR(17)),17) AS tran_amt
,'C' AS part_tran_type 
--,CONVERT(VARCHAR,isnull(DealOpenDate,AcOpenDate),105) AS value_date  
--,@v_MigDate as value_date
,case when IntPostFrqCr = '1' AND AcOpenDate<@MigDate then @v_MigDate
	when IntPostFrqCr = '4' AND AcOpenDate<@MTH then @mig_MONTH
	when IntPostFrqCr = '5' AND AcOpenDate<@QTR then @mig_QTR
	when IntPostFrqCr = '6' AND AcOpenDate<@HYR then @mig_HYR
	when IntPostFrqCr = '7' AND AcOpenDate<@YR then @mig_YR
	else convert(VARCHAR,AcOpenDate,105)
	end as value_date
	
--,@v_MigDate1 as value_date
,'' AS agent_emp_ind
,'' AS agent_code
/*
,case when AcType = '1C' then 'NI'
	  when AcType = '1Y' then 'II'
	  else 'PI' end AS flow_code
*/	  
,'II' AS flow_code	   
,'N' AS transaction_end_indicator
from FINMIG.dbo.ForAcidTD fa
join CurrencyTable C
on fa.CyCode = C.CyCode
--and BranchCode between '001' and '064'
and TD_TYPE = 'MASTER'
and fa.MainCode <> '91310310201'

union all

SELECT 
'T' AS tran_type  
,'BI' AS tran_sub_type 
,ForAcid as foracid1
,BranchCode+fa.CyCode+@BACID as foracid
,CyDesc as tran_crncy_code
,RIGHT(SPACE(17)+CAST('0.00' AS VARCHAR(17)),17) AS tran_amt
,'D' AS part_tran_type 
--,CONVERT(VARCHAR,isnull(DealOpenDate,AcOpenDate),105) AS value_date  
--,@v_MigDate as value_date
,case when IntPostFrqCr = '1' AND AcOpenDate<@MigDate then @v_MigDate
	when IntPostFrqCr = '4' AND AcOpenDate<@MTH then @mig_MONTH
	when IntPostFrqCr = '5' AND AcOpenDate<@QTR then @mig_QTR
	when IntPostFrqCr = '6' AND AcOpenDate<@HYR then @mig_HYR
	when IntPostFrqCr = '7' AND AcOpenDate<@YR then @mig_YR
	else convert(VARCHAR,AcOpenDate,105)
	end as value_date
	
--,@v_MigDate1 as value_date
,'' AS agent_emp_ind
,'' AS agent_code
/*,case when AcType = '1C' then 'NI'
	  when AcType = '1Y' then 'II'
	  else 'PI' end AS flow_code
*/	  
,'II' AS flow_code
,'Y' AS transaction_end_indicator
from FINMIG.dbo.ForAcidTD fa
join CurrencyTable C
on fa.CyCode = C.CyCode
--and BranchCode between '001' and '064'
and TD_TYPE = 'MASTER'
and fa.MainCode <> '91310310201'

--and mt.BranchCode = '001' and mt.CyCode ='01'
order by foracid1,part_tran_type
--10718 rows in 5 sec



--155 rows from Master table
-- 282 ROWS IN SECOND MIGRATION 