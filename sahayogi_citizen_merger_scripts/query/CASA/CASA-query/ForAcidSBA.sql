use PPIVSahayogiVBL

Declare @MigDate date, @v_MigDate nvarchar(15)
set @MigDate = (select Today from ControlTable);
set @v_MigDate=REPLACE(REPLACE(CONVERT(VARCHAR,@MigDate,105), ' ','-'), ',','')

DECLARE @DAY DATE, @v_DAY nvarchar(15),@MTH DATE,@v_MONTH nvarchar(15),
@QTR DATE, @v_QTR nvarchar(15), @HYR DATE,@v_HYR nvarchar(15), @YR DATE, @v_YR nvarchar(15)

set @DAY = (select Today from ControlTable);
set @v_DAY=REPLACE(REPLACE(CONVERT(VARCHAR,@DAY,105), ' ','-'), ',','')

set @MTH = (select NextMonthEnd from FINMIG.dbo.NextIntRunDate );
set @v_MONTH=REPLACE(REPLACE(CONVERT(VARCHAR,@MTH,105), ' ','-'), ',','')

set @QTR = (select NextQtrEnd from FINMIG.dbo.NextIntRunDate );
set @v_QTR=REPLACE(REPLACE(CONVERT(VARCHAR,@QTR,105), ' ','-'), ',','')

set @HYR = (select NextHalfYearEnd from FINMIG.dbo.NextIntRunDate );
set @v_HYR=REPLACE(REPLACE(CONVERT(VARCHAR,@HYR,105), ' ','-'), ',','')

set @YR = (select NextYeaerEnd from FINMIG.dbo.NextIntRunDate );
set @v_YR=REPLACE(REPLACE(CONVERT(VARCHAR,@YR,105), ' ','-'), ',','')



---------------FREE CODE 3 MAPPING QUERY-----------------------

IF OBJECT_ID('tempdb.dbo.#FREECODE3', 'U') IS NOT NULL
  DROP TABLE #FREECODE3;
  
select * INTO #FREECODE3 from (
SELECT  distinct MainCode,BranchCode,UPPER(CONVERT(VARCHAR,CustType)) as CustType,F.FnacleCode as FinacleCode from AcCustType A JOIN
		FINMIG..FREECODE3 F ON UPPER(CONVERT(VARCHAR,CustType))=F.PumoriCustType
	where  A.CustTypeCode ='B')X



IF OBJECT_ID('tempdb.dbo.#FinalMaster', 'U') IS NOT NULL
  DROP TABLE #FinalMaster;

select * INTO #FinalMaster from (
SELECT 
			   m.ClientCode
              ,AcType
              ,IntCrRate
              ,BranchCode
			  ,(select F_SolId from FINMIG..SolMap where BranchCode = m.BranchCode) as F_SolId
              ,AcOpenDate
              ,MainCode
              ,isnull(TaxPercentOnInt,0) as TaxPercentOnInt
              ,IntPostFrqCr
              ,TaxPostFrq
			 ,CyDesc as acct_crncy_code
              ,IsBlocked
              ,replace(replace(m.Name, '&', 'and'), ',', '/') as Name
              ,m.CyCode
              ,IsDormant
			  ,m.Limit
			  ,m.Balance
              ,ClientTag3
              ,GoodBaln
              ,LastTranDate
              ,(select LastTranDate from FINMIG.dbo.LAST_TRANS_DATE l where m.MainCode=l.MainCode) as trans_LastTranDate
              ,m.AcOfficer
              ,ClientCategory
              
			  /*,ISNULL((SELECT ltrim(rtrim(convert(varchar,REPLACE(FreeCode7,' ','')))) from FINMIG..CURRENT_FREE_CODE_7 cf
				where m.MainCode = cf.PumoriAccountNumber),'') as current_free_code_7 */ --changed in sahayogi migration
				,'' as current_free_code_7
              FROM Master(nolock) m join ClientTable(nolock) c on m.ClientCode = c.ClientCode
              JOIN CurrencyTable C
              on m.CyCode = C.CyCode
where (m.MainCode in 
		(select MainCode from Master(nolock) 
		where AcType IN (SELECT ACTYPE FROM FINMIG.dbo.PRODUCT_MAPPING WHERE MODULE = 'SAVING' and IsBlocked<>'C'
		AND BranchCode not in ('242','243') --or Limit <> 0
		))
		OR (m.MainCode in (select MainCode from Master(nolock) 
			where AcType IN (SELECT ACTYPE FROM FINMIG.dbo.PRODUCT_MAPPING WHERE MODULE = 'CURRENT')
								AND Limit = '0'
								AND Balance>='0' and IsBlocked<>'C'
								AND BranchCode not in ('242','243')
								))
	AND m.MainCode not in ( select MainCode from Master(nolock) 
	where AcType='01' and CyCode='01' and IntDrAmt<>'0' and Limit='0' 
	and IsBlocked<>'C' and BranchCode not in ('242','243'))
		))x


IF OBJECT_ID('FINMIG.dbo.ForAcidSBA', 'U') IS NOT NULL
  DROP TABLE FINMIG.dbo.ForAcidSBA;

SELECT 
                     m.MainCode 
					 ,m.F_SolId
					,m.ClientCode            
                    ,m.BranchCode
                    , CyCode
                    ,GoodBaln 
                    ,ma.F_SCHEME_CODE
					,'*' GL_SUBHEAD_CODE
					,'*' INTEREST_TABLE_CODE
                    ,AcType
                    ,AcOpenDate
                    ,Right('00000000'+cast(ROW_NUMBER() OVER( PARTITION BY m.BranchCode,case when m.Limit = 0 and m.Balance > 0 and AcType = '01' then 'CA201' else ma.F_SCHEME_CODE end , CyCode 
ORDER BY m.MainCode,m.BranchCode,AcOpenDate ,case when m.Limit = 0 and m.Balance > 0 and AcType = '01' then 'CA201' else ma.F_SCHEME_CODE end ,CyCode) AS nvarchar(8)),8) SN0
,m.F_SolId+CyCode+Right('00000000'+cast(ROW_NUMBER() OVER( PARTITION BY m.BranchCode,case when m.Limit = 0 and m.Balance > 0 and AcType = '01' then 'CA201' else ma.F_SCHEME_CODE end ,CyCode 
ORDER BY m.MainCode,m.BranchCode,AcOpenDate ,case when m.Limit = 0 and m.Balance > 0 and AcType = '01' then 'CA201' else ma.F_SCHEME_CODE end ,CyCode) AS nvarchar(8)),8)+right(rtrim(case when m.Limit = 0 and m.Balance > 0 and AcType = '01' then 'CA201' else ma.F_SCHEME_CODE end ),3)  ForAcid into FINMIG.dbo.ForAcidSBA
FROM #FinalMaster m
join  (SELECT * FROM FINMIG.dbo.PRODUCT_MAPPING WHERE MODULE IN ('SAVING','CURRENT')) ma on m.AcType=ma.ACTYPE
and m.acct_crncy_code = ma.CNCY
where MainCode not in (select MainCode from Master where Limit <> 0 and (Balance = 0 or Balance < 0) and AcType = '01')  --and Balance > 0
--and isnull(P_INT_FEQ,'')=(CASE WHEN AcType in ('1E', '1D', '2F', '19') then IntPostFrqCr else '' end)
