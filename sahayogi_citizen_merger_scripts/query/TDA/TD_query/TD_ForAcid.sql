use PPIVSahayogiVBL
-- SQL for TD002 master

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
		--,REPLACE(REPLACE(CONVERT(VARCHAR,AcOpenDate,105), ' ','-'), ',','')as AcOpenDate
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
and IsMatured <> 'T'
AND DealAmt <> 0

)x

--select * from #FinalDealTable where MainCode = '00621800073445000003'



use PPIVSahayogiVBL
IF OBJECT_ID('FINMIG.dbo.ForAcidTD', 'U') IS NOT NULL
  DROP TABLE FINMIG.dbo.ForAcidTD;

SELECT 
                     MainCode 
                    ,ReferenceNo
                    ,CASE WHEN ReferenceNo IS NOT NULL THEN 'DEAL' ELSE 'MASTER' END AS TD_TYPE         
                    ,BranchCode
					,(select F_SolId from FINMIG..SolMap where BranchCode = ft.BranchCode) as F_SolId
                    ,CyCode 
                    ,AcType
                    ,IntPostFrqCr 
                    ,Balance as DealAmt_Balance
                    ,Interest as IntAccrued_IntCrAmt
                    ,F_SCHEME_CODE
                    ,AcOpenDate,
					GL_SUBHEAD_CODE
					,INTEREST_TABLE_CODE
                    ,Right('00000000'+cast(ROW_NUMBER() OVER( PARTITION BY BranchCode,F_SCHEME_CODE,CyCode 
ORDER BY MainCode,BranchCode,AcOpenDate ,F_SCHEME_CODE,CyCode) AS nvarchar(8)),8) SN0
,(select F_SolId from FINMIG..SolMap where BranchCode = ft.BranchCode)+CyCode+Right('00000000'+cast(ROW_NUMBER() OVER( PARTITION BY BranchCode,F_SCHEME_CODE,CyCode 
ORDER BY MainCode,ReferenceNo,BranchCode,AcOpenDate ,F_SCHEME_CODE,CyCode) AS nvarchar(8)),8)+right(rtrim(F_SCHEME_CODE),3)  ForAcid into FINMIG.dbo.ForAcidTD
 FROM (SELECT 
  mt.MainCode
 ,ReferenceNo           
 ,BranchCode
 ,mt.CyCode
 ,mt.AcType
 ,isnull(DealAmt,Balance) as Balance
 ,isnull(IntAccrued,IntCrAmt) as Interest
 ,isnull(dt.IntPostFrqCr,mt.IntPostFrqCr) as IntPostFrqCr
 ,isnull(DealOpenDate,AcOpenDate) as AcOpenDate
  
  -----***************************************************F_SCHEME_CODE****************************************************

  ,CASE WHEN mt.AcType = '25' then 
	case when dt.MaturityDays >= 913 then
	(SELECT F_SCHEME_CODE FROM FINMIG.dbo.PRODUCT_MAPPING 
					WHERE MODULE = 'TERM DEPOSIT' and ACTYPE= dt.AcType AND P_INT_FEQ=mt.IntPostFrqCr 
					and CNCY=mt.CyDesc and (dt.MaturityDays between L_LIMIT AND U_LIMIT))
	else 
	(select F_SCHEME_CODE FROM FINMIG.dbo.PRODUCT_MAPPING
	WHERE  MODULE = 'TERM DEPOSIT' and ACTYPE='2D' AND P_INT_FEQ=mt.IntPostFrqCr 
	and CNCY=mt.CyDesc)
	END
	WHEN mt.AcType = '26' then
				 case when dt.MaturityDays > 1825 
			THEN (SELECT F_SCHEME_CODE FROM FINMIG.dbo.PRODUCT_MAPPING
					WHERE  MODULE = 'TERM DEPOSIT' and ACTYPE= dt.AcType AND P_INT_FEQ=mt.IntPostFrqCr 
					and CNCY=mt.CyDesc and (dt.MaturityDays between L_LIMIT AND U_LIMIT))
				WHEN dt.MaturityDays between 914 and 1825 
				THEN (SELECT F_SCHEME_CODE FROM FINMIG.dbo.PRODUCT_MAPPING
					WHERE  MODULE = 'TERM DEPOSIT' and ACTYPE= '25' AND P_INT_FEQ=mt.IntPostFrqCr 
					and CNCY=mt.CyDesc)
	else 
		(SELECT F_SCHEME_CODE FROM FINMIG.dbo.PRODUCT_MAPPING
					WHERE  MODULE = 'TERM DEPOSIT' and ACTYPE= '2D' AND P_INT_FEQ=mt.IntPostFrqCr 
					and CNCY=mt.CyDesc)
	END
	when mt.AcType = '27' then
			 case when dt.MaturityDays > 1825 
			THEN (SELECT F_SCHEME_CODE FROM FINMIG.dbo.PRODUCT_MAPPING
					WHERE  MODULE = 'TERM DEPOSIT' and ACTYPE= dt.AcType AND P_INT_FEQ=mt.IntPostFrqCr 
					and CNCY=mt.CyDesc and (dt.MaturityDays between L_LIMIT AND U_LIMIT))
				WHEN dt.MaturityDays between 914 and 1825 
				THEN (SELECT F_SCHEME_CODE FROM FINMIG.dbo.PRODUCT_MAPPING
					WHERE  MODULE = 'TERM DEPOSIT' and ACTYPE= '25' AND P_INT_FEQ=mt.IntPostFrqCr 
					and CNCY=mt.CyDesc)
	else 
		(SELECT F_SCHEME_CODE FROM FINMIG.dbo.PRODUCT_MAPPING
					WHERE  MODULE = 'TERM DEPOSIT' and ACTYPE= '2D' AND P_INT_FEQ=mt.IntPostFrqCr 
					and CNCY=mt.CyDesc)
		END			
	when mt.AcType = '28' then 
	case when dt.MaturityDays > 1825 
			THEN (SELECT F_SCHEME_CODE FROM FINMIG.dbo.PRODUCT_MAPPING
					WHERE  MODULE = 'TERM DEPOSIT' and ACTYPE= dt.AcType AND P_INT_FEQ=mt.IntPostFrqCr 
					and CNCY=mt.CyDesc and (dt.MaturityDays between L_LIMIT AND U_LIMIT))
				WHEN dt.MaturityDays between 914 and 1825 
				THEN (SELECT F_SCHEME_CODE FROM FINMIG.dbo.PRODUCT_MAPPING
					WHERE  MODULE = 'TERM DEPOSIT' and ACTYPE= '25' AND P_INT_FEQ=mt.IntPostFrqCr 
					and CNCY=mt.CyDesc)
	else 
		(SELECT F_SCHEME_CODE FROM FINMIG.dbo.PRODUCT_MAPPING
					WHERE  MODULE = 'TERM DEPOSIT' and ACTYPE= '2D' AND P_INT_FEQ=mt.IntPostFrqCr 
					and CNCY=mt.CyDesc)
	END

	when mt.AcType = '2H' then 
	case when dt.MaturityDays > 1825 
			THEN (SELECT F_SCHEME_CODE FROM FINMIG.dbo.PRODUCT_MAPPING
					WHERE  MODULE = 'TERM DEPOSIT' and ACTYPE= dt.AcType AND P_INT_FEQ=mt.IntPostFrqCr 
					and CNCY=mt.CyDesc and (dt.MaturityDays between L_LIMIT AND U_LIMIT))
				WHEN dt.MaturityDays between 914 and 1825 
				THEN (SELECT F_SCHEME_CODE FROM FINMIG.dbo.PRODUCT_MAPPING
					WHERE  MODULE = 'TERM DEPOSIT' and ACTYPE= '25' AND P_INT_FEQ=mt.IntPostFrqCr 
					and CNCY=mt.CyDesc)
	else 
		(SELECT F_SCHEME_CODE FROM FINMIG.dbo.PRODUCT_MAPPING
					WHERE  MODULE = 'TERM DEPOSIT' and ACTYPE= '2D' AND P_INT_FEQ=mt.IntPostFrqCr 
					and CNCY=mt.CyDesc)
	end
	WHEN mt.AcType = '23' then 
		case when dt.MaturityDays > 913 then
			(SELECT F_SCHEME_CODE FROM FINMIG.dbo.PRODUCT_MAPPING
					WHERE  MODULE = 'TERM DEPOSIT' and ACTYPE= dt.AcType AND P_INT_FEQ=mt.IntPostFrqCr 
					and CNCY=mt.CyDesc and (dt.MaturityDays between L_LIMIT AND U_LIMIT))
		else 
		(SELECT F_SCHEME_CODE FROM FINMIG.dbo.PRODUCT_MAPPING
		WHERE  MODULE = 'TERM DEPOSIT' and ACTYPE= '2D' AND P_INT_FEQ=mt.IntPostFrqCr and CNCY=mt.CyDesc)
		
	END
	WHEN mt.AcType = '24' then 
		case when dt.MaturityDays > 913
			THEN (SELECT F_SCHEME_CODE FROM FINMIG.dbo.PRODUCT_MAPPING
					WHERE ACTYPE= dt.AcType AND P_INT_FEQ=mt.IntPostFrqCr 
					and CNCY=mt.CyDesc and (dt.MaturityDays between L_LIMIT AND U_LIMIT))	
		else (SELECT F_SCHEME_CODE FROM FINMIG.dbo.PRODUCT_MAPPING
					WHERE ACTYPE= '2D' AND P_INT_FEQ=mt.IntPostFrqCr 
					and CNCY=mt.CyDesc)
		
	END
	/*
	WHEN mt.AcType = '20' then 
	 case when dt.MaturityDays <= 914
	 THEN (SELECT F_SCHEME_CODE FROM FINMIG.dbo.PRODUCT_MAPPING
					WHERE ACTYPE= dt.AcType AND P_INT_FEQ=mt.IntPostFrqCr 
					and CNCY=mt.CyDesc and (dt.MaturityDays between L_LIMIT AND U_LIMIT))
	end
	WHEN mt.AcType = '21' then 
	 case when dt.MaturityDays <= 914
	 THEN (SELECT F_SCHEME_CODE FROM FINMIG.dbo.PRODUCT_MAPPING
					WHERE ACTYPE= dt.AcType AND P_INT_FEQ=mt.IntPostFrqCr 
					and CNCY=mt.CyDesc and (dt.MaturityDays between L_LIMIT AND U_LIMIT))
	end
	WHEN mt.AcType = '22' then 
	 case when dt.MaturityDays <= 914
	 THEN (SELECT F_SCHEME_CODE FROM FINMIG.dbo.PRODUCT_MAPPING
					WHERE ACTYPE= dt.AcType AND P_INT_FEQ=mt.IntPostFrqCr 
					and CNCY=mt.CyDesc and (dt.MaturityDays between L_LIMIT AND U_LIMIT))
	end
	*/


	else
	(select F_SCHEME_CODE FROM FINMIG.dbo.PRODUCT_MAPPING
	 WHERE ACTYPE= dt.AcType AND P_INT_FEQ=dt.IntPostFrqCr 
 and CNCY=mt.CyDesc )
 end as F_SCHEME_CODE,


 -----***************************************************GL_SUBHEAD_CODE****************************************************

 CASE WHEN mt.AcType = '25' then 
	case when dt.MaturityDays >= 913 then
	(SELECT GL_SUBHEAD_CODE FROM FINMIG.dbo.PRODUCT_MAPPING 
					WHERE MODULE = 'TERM DEPOSIT' and ACTYPE= dt.AcType AND P_INT_FEQ=mt.IntPostFrqCr 
					and CNCY=mt.CyDesc and (dt.MaturityDays between L_LIMIT AND U_LIMIT))
	else 
	(select GL_SUBHEAD_CODE FROM FINMIG.dbo.PRODUCT_MAPPING
	WHERE  MODULE = 'TERM DEPOSIT' and ACTYPE='2D' AND P_INT_FEQ=mt.IntPostFrqCr 
	and CNCY=mt.CyDesc)
	END

	WHEN mt.AcType = '26' then
				 case when dt.MaturityDays > 1825 
			THEN (SELECT GL_SUBHEAD_CODE FROM FINMIG.dbo.PRODUCT_MAPPING
					WHERE  MODULE = 'TERM DEPOSIT' and ACTYPE= dt.AcType AND P_INT_FEQ=mt.IntPostFrqCr 
					and CNCY=mt.CyDesc and (dt.MaturityDays between L_LIMIT AND U_LIMIT))
				WHEN dt.MaturityDays between 914 and 1825 
				THEN (SELECT GL_SUBHEAD_CODE FROM FINMIG.dbo.PRODUCT_MAPPING
					WHERE  MODULE = 'TERM DEPOSIT' and ACTYPE= '25' AND P_INT_FEQ=mt.IntPostFrqCr 
					and CNCY=mt.CyDesc)
	else 
		(SELECT GL_SUBHEAD_CODE FROM FINMIG.dbo.PRODUCT_MAPPING
					WHERE  MODULE = 'TERM DEPOSIT' and ACTYPE= '2D' AND P_INT_FEQ=mt.IntPostFrqCr 
					and CNCY=mt.CyDesc)
	END
	when mt.AcType = '27' then
		case when dt.MaturityDays > 1825 
			THEN (SELECT GL_SUBHEAD_CODE FROM FINMIG.dbo.PRODUCT_MAPPING
					WHERE  MODULE = 'TERM DEPOSIT' and ACTYPE= dt.AcType AND P_INT_FEQ=mt.IntPostFrqCr 
					and CNCY=mt.CyDesc and (dt.MaturityDays between L_LIMIT AND U_LIMIT))
				WHEN dt.MaturityDays between 914 and 1825 
				THEN (SELECT GL_SUBHEAD_CODE FROM FINMIG.dbo.PRODUCT_MAPPING
					WHERE  MODULE = 'TERM DEPOSIT' and ACTYPE= '25' AND P_INT_FEQ=mt.IntPostFrqCr 
					and CNCY=mt.CyDesc)
	else 
		(SELECT GL_SUBHEAD_CODE FROM FINMIG.dbo.PRODUCT_MAPPING
					WHERE  MODULE = 'TERM DEPOSIT' and ACTYPE= '2D' AND P_INT_FEQ=mt.IntPostFrqCr 
					and CNCY=mt.CyDesc)
		END			
	when mt.AcType = '28' then 
	case when dt.MaturityDays > 1825 
			THEN (SELECT GL_SUBHEAD_CODE FROM FINMIG.dbo.PRODUCT_MAPPING
					WHERE  MODULE = 'TERM DEPOSIT' and ACTYPE= dt.AcType AND P_INT_FEQ=mt.IntPostFrqCr 
					and CNCY=mt.CyDesc and (dt.MaturityDays between L_LIMIT AND U_LIMIT))
				WHEN dt.MaturityDays between 914 and 1825 
				THEN (SELECT GL_SUBHEAD_CODE FROM FINMIG.dbo.PRODUCT_MAPPING
					WHERE  MODULE = 'TERM DEPOSIT' and ACTYPE= '25' AND P_INT_FEQ=mt.IntPostFrqCr 
					and CNCY=mt.CyDesc)
	else 
		(SELECT GL_SUBHEAD_CODE FROM FINMIG.dbo.PRODUCT_MAPPING
					WHERE  MODULE = 'TERM DEPOSIT' and ACTYPE= '2D' AND P_INT_FEQ=mt.IntPostFrqCr 
					and CNCY=mt.CyDesc)
	END
	when mt.AcType = '2H' then 
	case when dt.MaturityDays > 1825 
			THEN (SELECT GL_SUBHEAD_CODE FROM FINMIG.dbo.PRODUCT_MAPPING
					WHERE  MODULE = 'TERM DEPOSIT' and ACTYPE= dt.AcType AND P_INT_FEQ=mt.IntPostFrqCr 
					and CNCY=mt.CyDesc and (dt.MaturityDays between L_LIMIT AND U_LIMIT))
				WHEN dt.MaturityDays between 914 and 1825 
				THEN (SELECT GL_SUBHEAD_CODE FROM FINMIG.dbo.PRODUCT_MAPPING
					WHERE  MODULE = 'TERM DEPOSIT' and ACTYPE= '25' AND P_INT_FEQ=mt.IntPostFrqCr 
					and CNCY=mt.CyDesc)
	else 
		(SELECT GL_SUBHEAD_CODE FROM FINMIG.dbo.PRODUCT_MAPPING
					WHERE  MODULE = 'TERM DEPOSIT' and ACTYPE= '2D' AND P_INT_FEQ=mt.IntPostFrqCr 
					and CNCY=mt.CyDesc)
	END
	WHEN mt.AcType = '23' then
	case when dt.MaturityDays > 913 then
			(SELECT GL_SUBHEAD_CODE FROM FINMIG.dbo.PRODUCT_MAPPING
					WHERE  MODULE = 'TERM DEPOSIT' and ACTYPE= dt.AcType AND P_INT_FEQ=mt.IntPostFrqCr 
					and CNCY=mt.CyDesc and (dt.MaturityDays between L_LIMIT AND U_LIMIT))
		else 
		(SELECT GL_SUBHEAD_CODE FROM FINMIG.dbo.PRODUCT_MAPPING
		WHERE  MODULE = 'TERM DEPOSIT' and ACTYPE= '2D' AND P_INT_FEQ=mt.IntPostFrqCr and CNCY=mt.CyDesc)
	END

	WHEN mt.AcType = '24' then 
		case when dt.MaturityDays > 913
			THEN (SELECT GL_SUBHEAD_CODE FROM FINMIG.dbo.PRODUCT_MAPPING
					WHERE ACTYPE= dt.AcType AND P_INT_FEQ=mt.IntPostFrqCr 
					and CNCY=mt.CyDesc and (dt.MaturityDays between L_LIMIT AND U_LIMIT))	
		else (SELECT GL_SUBHEAD_CODE FROM FINMIG.dbo.PRODUCT_MAPPING
					WHERE ACTYPE= '2D' AND P_INT_FEQ=mt.IntPostFrqCr 
					and CNCY=mt.CyDesc)
	END

	/*
	WHEN mt.AcType = '20' then 
	 case when dt.MaturityDays <= 914
	 THEN (SELECT GL_SUBHEAD_CODE FROM FINMIG.dbo.PRODUCT_MAPPING
					WHERE ACTYPE= dt.AcType AND P_INT_FEQ=mt.IntPostFrqCr 
					and CNCY=mt.CyDesc and (dt.MaturityDays between L_LIMIT AND U_LIMIT))
	end
	WHEN mt.AcType = '21' then 
	 case when dt.MaturityDays <= 914
	 THEN (SELECT GL_SUBHEAD_CODE FROM FINMIG.dbo.PRODUCT_MAPPING
					WHERE ACTYPE= dt.AcType AND P_INT_FEQ=mt.IntPostFrqCr 
					and CNCY=mt.CyDesc and (dt.MaturityDays between L_LIMIT AND U_LIMIT))
	end
	WHEN mt.AcType = '22' then 
	 case when dt.MaturityDays <= 914
	 THEN (SELECT GL_SUBHEAD_CODE FROM FINMIG.dbo.PRODUCT_MAPPING
					WHERE ACTYPE= dt.AcType AND P_INT_FEQ=mt.IntPostFrqCr 
					and CNCY=mt.CyDesc and (dt.MaturityDays between L_LIMIT AND U_LIMIT))
	end
	*/
	else
	(select GL_SUBHEAD_CODE FROM FINMIG.dbo.PRODUCT_MAPPING
	 WHERE ACTYPE= dt.AcType AND P_INT_FEQ=dt.IntPostFrqCr 
 and CNCY=mt.CyDesc )
 end as GL_SUBHEAD_CODE

-----***************************************************GL_SUBHEAD_CODE****************************************************

 ,'ZEROT' AS INTEREST_TABLE_CODE


  from ( 
select MainCode
		,m.CyCode
		,CyDesc as CyDesc
		,AcOpenDate,Balance,BranchCode,AcType,IntCrAmt,m.IntPostFrqCr from Master m join CurrencyTable C on m.CyCode = C.CyCode 
where (m.AcType in (Select ACTYPE FROM FINMIG.dbo.PRODUCT_MAPPING WHERE MODULE = 'TERM DEPOSIT'))
and ROUND(Balance,2)<>'0'
and IsBlocked<>'C'
)mt 
 join(
select d.MainCode,d.DealAmt,d.CyCode,d.DealOpenDate,d.ReferenceNo,d.AcType,IntAccrued,m.IntPostFrqCr
,fd.MaturityDays as MaturityDays  
from DealTable d join Master m on d.MainCode=m.MainCode and d.BranchCode= m.BranchCode
join #FinalDealTable fd on fd.ReferenceNo = d.ReferenceNo and fd.BranchCode=d.BranchCode
where d.AcType in (Select ACTYPE FROM FINMIG.dbo.PRODUCT_MAPPING WHERE MODULE = 'TERM DEPOSIT')
and ROUND(d.DealAmt,2) <>'0'
and IsBlocked<>'C'
and d.IsMatured <> 'T'
)dt
on mt.MainCode=dt.MainCode) ft

--select ACTYPE, F_SCHEME_CODE, P_INT_FEQ, OTHER_CONDITION, L_LIMIT, U_LIMIT from FINMIG..PRODUCT_MAPPING where MODULE = 'TERM DEPOSIT'
