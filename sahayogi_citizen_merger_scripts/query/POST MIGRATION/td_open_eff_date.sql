use PPIVSahayogiVBL
-- SQL for TD002 master

DECLARE @MigDate DATE, @v_MigDate nvarchar(15),@MTH DATE,@mig_MONTH nvarchar(15),
@QTR DATE, @mig_QTR nvarchar(15), @HYR DATE,@mig_HYR nvarchar(15), @YR DATE, @mig_YR nvarchar(15),@MigDate1 DATE, @v_MigDate1 nvarchar(15)


set @MigDate = (select dateadd(day,1,Today) from ControlTable);
set @v_MigDate=REPLACE(REPLACE(CONVERT(VARCHAR,@MigDate,106), ' ','-'), ',','')

set @MigDate1 = (select Today from ControlTable);
set @v_MigDate1=REPLACE(REPLACE(CONVERT(VARCHAR,@MigDate1,106), ' ','-'), ',','')

set @MTH = (select dateadd(day,1,LastMonthEnd) from ControlTable);
set @mig_MONTH=REPLACE(REPLACE(CONVERT(VARCHAR,@MTH,106), ' ','-'), ',','')

set @QTR = (select dateadd(day,1,LastQtrEnd) from ControlTable);
set @mig_QTR=REPLACE(REPLACE(CONVERT(VARCHAR,@QTR,106), ' ','-'), ',','')

set @HYR = (select dateadd(day,1,LastHalfYrEnd) from ControlTable);
set @mig_HYR=REPLACE(REPLACE(CONVERT(VARCHAR,@HYR,106), ' ','-'), ',','')

set @YR = (select dateadd(day,1,LastYearEnd) from ControlTable);
set @mig_YR=REPLACE(REPLACE(CONVERT(VARCHAR,@YR,106), ' ','-'), ',','')




IF OBJECT_ID('tempdb.dbo.#SBA_OD', 'U') IS NOT NULL
  DROP TABLE #SBA_OD;  
 SELECT * INTO #SBA_OD FROM (select * from FINMIG.dbo.ForAcidSBA UNION  ALL select * from FINMIG.dbo.ForAcidOD)X
  
/*  Master
IF OBJECT_ID('tempdb.dbo.#tempdealmaster', 'U') IS NOT NULL
  DROP TABLE #tempdealmaster;    -- Drop temporary tempdealmaster table if it exists
  
select * INTO #tempdealmaster from (
SELECT  
		case when M.MainCode ='913102102' then '00055581' --by bank
				else M.ClientCode end as ClientCode
		,AcType
		,BranchCode
		,MainCode
		,IntCrRate
		,TaxPercentOnInt
		,Balance
		--,REPLACE(REPLACE(CONVERT(VARCHAR,AcOpenDate,106), ' ','-'), ',','')as AcOpenDate
		,AcOpenDate
		,IntPostFrqCr
		,M.CyCode as CyCode
		,CyDesc as acct_crncy_code
FROM Master M join CurrencyTable C
on M.CyCode =C.CyCode
where AcType in (Select ACTYPE FROM FINMIG.dbo.PRODUCT_MAPPING WHERE MODULE = 'TERM DEPOSIT')
and Balance<>'0'
and IsBlocked<>'C'


)x;
*/


--DEAL TABLE

IF OBJECT_ID('tempdb.dbo.#FinalDealTable', 'U') IS NOT NULL
  DROP TABLE #FinalDealTable;

select * INTO #FinalDealTable from (
SELECT 		   ReferenceNo
			  ,t1.MainCode
			  ,case when t1.MainCode ='913102102' then '00055581'
					when t1.MainCode ='918101002' then '00147389'
					when t1.MainCode ='918101003' then '00147389'
					when t1.MainCode ='918101004' then '00147389' --by bank
					
				else t2.ClientCode end as ClientCode
			  ,t1.BranchCode
			  /*
	          ,case when t1.MainCode='918101003' then '2019-01-15'
					when t1.MainCode='918101002' then '2019-01-15'
					when t1.MainCode='918101004' then '2019-01-15' 
				else DealOpenDate end as DealOpenDate
				*/
				,DealOpenDate as DealOpenDate
	          ,MaturityDate
	          ,IntCalcFrom
	          ,DealAmt
	          ,TaxPercentOnInt
	          ,IntRate
	          ,NomAcInterest
	          ,IsBlockedDeal
	          ,NomAcMature
	          ,IntPostFrqCr
	          ,IsMatured
	          ,TaxPercentOnDeal
	          ,t1.AcType
	          ,CyDesc as acct_crncy_code
	          ,case when t2.IntPostFrqCr = '1' AND isnull(DealOpenDate,AcOpenDate)<@MigDate then DateDiff(DAY,@MigDate,MaturityDate)
				when t2.IntPostFrqCr = '4' AND isnull(DealOpenDate,AcOpenDate)<@MTH then DateDiff(DAY,@MTH,MaturityDate)
				when t2.IntPostFrqCr = '5' AND isnull(DealOpenDate,AcOpenDate)<@QTR then DateDiff(DAY,@QTR,MaturityDate)
				when t2.IntPostFrqCr = '6' AND isnull(DealOpenDate,AcOpenDate)<@HYR then DateDiff(DAY,@HYR,MaturityDate)
				when t2.IntPostFrqCr = '7' AND isnull(DealOpenDate,AcOpenDate)<@YR then DateDiff(DAY,@YR,MaturityDate)
				else DateDiff(DAY,DealOpenDate,MaturityDate)
				end  as MaturityDays
			  --,isnull(DateDiff(DAY,@MigDate,MaturityDate),0) as MaturityDays
FROM DealTable t1 JOIN Master t2
on t1.MainCode = t2.MainCode and t1.BranchCode= t2.BranchCode
join CurrencyTable t3
on t1.CyCode = t3.CyCode
where t1.AcType IN (SELECT ACTYPE FROM FINMIG.dbo.PRODUCT_MAPPING WHERE MODULE ='TERM DEPOSIT')
and IsBlocked<>'C'
AND DealAmt <> 0
and IsMatured <> 'T'

)x



select 'spool open_effective_date.lst'
union all
select 'UPDATE tbaadm.tam t SET t.open_effective_date = '''+open_effective_date+'''  WHERE t.acid = (SELECT acid FROM tbaadm.gam WHERE foracid = '''+foracid+''');'  FROM (
SELECT


ForAcid as foracid




,case when t1.IntPostFrqCr = '1' AND isnull(DealOpenDate,AcOpenDate)<@MigDate then @v_MigDate
	when t1.IntPostFrqCr = '4' AND isnull(DealOpenDate,AcOpenDate)<@MTH then @mig_MONTH
	when t1.IntPostFrqCr = '5' AND isnull(DealOpenDate,AcOpenDate)<@QTR then @mig_QTR
	when t1.IntPostFrqCr = '6' AND isnull(DealOpenDate,AcOpenDate)<@HYR then @mig_HYR
	when t1.IntPostFrqCr = '7' AND isnull(DealOpenDate,AcOpenDate)<@YR then @mig_YR
	else replace(convert(VARCHAR,isnull(DealOpenDate,AcOpenDate),106), ' ', '-')
	end as open_effective_date

 from FINMIG.dbo.ForAcidTD t1 join #FinalDealTable M
on t1.ReferenceNo =M.ReferenceNo and t1.BranchCode= M.BranchCode
WHERE 1=1 and t1.AcType in ('2A', '2B'))v

union all
select 'commit;'
union all
select 'spool off;';
