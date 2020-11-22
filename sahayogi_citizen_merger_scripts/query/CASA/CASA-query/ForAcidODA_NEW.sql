use PPIVSahayogiVBL
--cs002

Declare @MigDate date, @v_MigDate nvarchar(15),@v_StatusDate nvarchar(15)
set @MigDate = (select Today from ControlTable);
set @v_MigDate=REPLACE(REPLACE(CONVERT(VARCHAR,@MigDate,105), ' ','-'), ',','')
set @v_StatusDate = REPLACE(CONVERT(VARCHAR,(select Today-1 from ControlTable),105), ' ','-')



DECLARE @DAY DATE, @v_DAY nvarchar(15),@MTH DATE,@v_MONTH nvarchar(15),
@QTR DATE, @v_QTR nvarchar(15), @HYR DATE,@v_HYR nvarchar(15), @YR DATE, @v_YR nvarchar(15)

set @DAY = (select LastDay from ControlTable);
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
SELECT  DISTINCT
			   t1.ClientCode
              ,AcType
              ,ClientTag3
              ,IntDrRate
              ,IntCrRate
              --,t1.Limit as Limit
            
             ,case when t1.Limit='0' and round(t1.GoodBaln,2)<'0' then ABS(round(GoodBaln,2))
					WHEN t1.Limit<abs(round(t1.GoodBaln,2)) and round(t1.GoodBaln,2)<'0' then ABS(round(GoodBaln,2))
			   else t1.Limit end as Limit
			   ,t1.Limit as Limit1
			   
              ,BranchCode
			  ,(select F_SolId from FINMIG..SolMap where BranchCode = t1.BranchCode) as F_SolId
              ,case when t1.Limit='0' and round(GoodBaln,2)<'0' then @MigDate
              else LimitExpiryDate end as LimitExpiryDate_origi
              --,LimitExpiryDate 
              ,AcOpenDate as AcOpenDate_original
              --DURGA  DAI JAN 1 2019
              ,case when LimitExpiryDate<AcOpenDate	and LimitExpiryDate<='2000-12-31' then @DAY --last day
					else  LimitExpiryDate end as LimitExpiryDate
              ,case when LimitExpiryDate<AcOpenDate	and LimitExpiryDate>'2000-12-31' then dateadd(day,-2,LimitExpiryDate)
					else case when datediff(day,AcOpenDate,LimitExpiryDate)=1 then dateadd(day,-2,LimitExpiryDate)  
					 else AcOpenDate end
					 end as AcOpenDate

              ,MainCode
              ,isnull(TaxPercentOnInt,0) as TaxPercentOnInt
              ,IntPostFrqCr
              ,TaxPostFrq
              ,'02' as PremiumRateDr
              ,DistrictCode
              ,GoodBaln
      		 ,CyDesc as acct_crncy_code
              ,IsBlocked
              ,t1.CyCode
              ,IntPostFrqDr
              ,t1.Name
              ,IsDormant
              ,LastTranDate
              ,(select LastTranDate from FINMIG.dbo.LAST_TRANS_DATE l where t1.MainCode=l.MainCode) as trans_LastTranDate
              ,t1.AcOfficer
              ,ClientCategory
FROM Master t1 join ClientTable t2
on t1.ClientCode = t2.ClientCode
join CurrencyTable t3
on t1.CyCode = t3.CyCode
where (AcType IN (SELECT ACTYPE FROM FINMIG.dbo.PRODUCT_MAPPING WHERE MODULE ='OVERDRAFT' and ACTYPE <>'01')
 or (AcType = '01' and (t1.Limit <>'0' or (t1.Limit='0' and Balance<'0') or (t1.Limit='0' and IntDrAmt<>'0' and t1.CyCode='01')))) ---  AND Balance >0 need to add in logic	
AND BranchCode not in('242','243')
--and AcType not in ('4A', '49')
AND IsBlocked <> 'C'
)x;


IF OBJECT_ID('FINMIG.dbo.ForAcidOD', 'U') IS NOT NULL
  DROP TABLE FINMIG.dbo.ForAcidOD;

SELECT 
                     m.MainCode  
					,m.ClientCode            
                    ,BranchCode
					,m.F_SolId
                    , CyCode 
                    ,GoodBaln



                    ,(select distinct case when ACTYPE = '43' and m.Limit1 between 1500000.01 and 2500000   then 'ZO414' 
					when ACTYPE = '43' and m.Limit1 between 2500000.01 and 99999999999 then 'MM416' 
					when ACTYPE = '43' and m.Limit1 between 0 and 1500000 then 'FT415'
					when ACTYPE = '47' and m.Limit1 between 1500000.01 and 2500000    then 'ZO414' 
					when ACTYPE = '47' and m.Limit1 between 2500000.01 and 99999999999 then 'MM416' 
					when ACTYPE = '47' and m.Limit1 between 0 and 1500000 then 'FT415'
					else F_SCHEME_CODE end from  FINMIG.dbo.PRODUCT_MAPPING ma WHERE MODULE = 'OVERDRAFT' 
					and m.AcType=ma.ACTYPE and m.acct_crncy_code = ma.CNCY) F_SCHEME_CODE

					,(select distinct case when ACTYPE = '43' and  m.Limit1 between 1500000.01 and 2500000 then '36065' 
					when ACTYPE = '43' and m.Limit1 between 2500000.01 and 99999999999 then '36067' 
					when ACTYPE = '43' and m.Limit1 between 0 and 1500000 then '36066'
					when ACTYPE = '47' and m.Limit1 between 1500000.01 and 2500000 then '36065' 
					when ACTYPE = '47' and m.Limit1 between 2500000.01 and 99999999999 then '36067' 
					when ACTYPE = '47' and m.Limit1 between 0 and 1500000 then '36066'
					else GL_SUBHEAD_CODE end from  FINMIG.dbo.PRODUCT_MAPPING ma WHERE MODULE = 'OVERDRAFT' 
					and m.AcType=ma.ACTYPE and m.acct_crncy_code = ma.CNCY) GL_SUBHEAD_CODE

					,(select distinct case when ACTYPE = '43' and m.Limit1 between 1500000.01 and 2500000  then 'OZERO' 
					when ACTYPE = '43' and m.Limit1 between 2500000.01 and 99999999999 then 'OZERO' 
					when ACTYPE = '43' and m.Limit1 between 0 and 1500000 then 'OZERO'
					when ACTYPE = '47' and m.Limit1 between 1500000.01 and 2500000    then 'OZERO' 
					when ACTYPE = '47' and m.Limit1 between 2500000.01 and 99999999999 then 'OZERO' 
					when ACTYPE = '47' and m.Limit1 between 0 and 1500000 then 'OZERO'
					else INTEREST_TABLE_CODE end from  FINMIG.dbo.PRODUCT_MAPPING ma WHERE MODULE = 'OVERDRAFT' 
					and m.AcType=ma.ACTYPE and m.acct_crncy_code = ma.CNCY) INTEREST_TABLE_CODE





                    ,AcType
                    ,AcOpenDate
                    ,Right('00000000'+cast(ROW_NUMBER() OVER( PARTITION BY m.BranchCode,(select distinct case when ACTYPE = '43' and m.Limit1 between 1500000.01 and 2500000   then 'ZO414' 
					when ACTYPE = '43' and m.Limit1 between 2500000.01 and 99999999999 then 'MM416' 
					when ACTYPE = '43' and m.Limit1 between 0 and 1500000 then 'FT415'
					when ACTYPE = '47' and m.Limit1 between 1500000.01 and 2500000    then 'ZO414' 
					when ACTYPE = '47' and m.Limit1 between 2500000.01 and 99999999999 then 'MM416' 
					when ACTYPE = '47' and m.Limit1 between 0 and 1500000 then 'FT415'
					else F_SCHEME_CODE end from  FINMIG.dbo.PRODUCT_MAPPING ma WHERE MODULE = 'OVERDRAFT' 
					and m.AcType=ma.ACTYPE and m.acct_crncy_code = ma.CNCY),CyCode 
ORDER BY  m.MainCode,m.BranchCode,AcOpenDate ,(select distinct case when ACTYPE = '43' and m.Limit1 between 1500000.01 and 2500000   then 'ZO414' 
					when ACTYPE = '43' and m.Limit1 between 2500000.01 and 99999999999 then 'MM416' 
					when ACTYPE = '43' and m.Limit1 between 0 and 1500000 then 'FT415'
					when ACTYPE = '47' and m.Limit1 between 1500000.01 and 2500000    then 'ZO414' 
					when ACTYPE = '47' and m.Limit1 between 2500000.01 and 99999999999 then 'MM416' 
					when ACTYPE = '47' and m.Limit1 between 0 and 1500000 then 'FT415'
					else F_SCHEME_CODE end from  FINMIG.dbo.PRODUCT_MAPPING ma WHERE MODULE = 'OVERDRAFT' 
					and m.AcType=ma.ACTYPE and m.acct_crncy_code = ma.CNCY),CyCode) AS nvarchar(8)),8) SN0
,m.F_SolId+CyCode+Right('00000000'+cast(ROW_NUMBER() OVER( PARTITION BY m.BranchCode,(select distinct case when ACTYPE = '43' and m.Limit1 between 1500000.01 and 2500000   then 'ZO414' 
					when ACTYPE = '43' and m.Limit1 between 2500000.01 and 99999999999 then 'MM416' 
					when ACTYPE = '43' and m.Limit1 between 0 and 1500000 then 'FT415'
					when ACTYPE = '47' and m.Limit1 between 1500000.01 and 2500000    then 'ZO414' 
					when ACTYPE = '47' and m.Limit1 between 2500000.01 and 99999999999 then 'MM416' 
					when ACTYPE = '47' and m.Limit1 between 0 and 1500000 then 'FT415'
					else F_SCHEME_CODE end from  FINMIG.dbo.PRODUCT_MAPPING ma WHERE MODULE = 'OVERDRAFT' 
					and m.AcType=ma.ACTYPE and m.acct_crncy_code = ma.CNCY),CyCode 
ORDER BY  m.MainCode,m.BranchCode,AcOpenDate ,(select distinct case when ACTYPE = '43' and m.Limit1 between 1500000.01 and 2500000   then 'ZO414' 
					when ACTYPE = '43' and m.Limit1 between 2500000.01 and 99999999999 then 'MM416' 
					when ACTYPE = '43' and m.Limit1 between 0 and 1500000 then 'FT415'
					when ACTYPE = '47' and m.Limit1 between 1500000.01 and 2500000    then 'ZO414' 
					when ACTYPE = '47' and m.Limit1 between 2500000.01 and 99999999999 then 'MM416' 
					when ACTYPE = '47' and m.Limit1 between 0 and 1500000 then 'FT415'
					else F_SCHEME_CODE end from  FINMIG.dbo.PRODUCT_MAPPING ma WHERE MODULE = 'OVERDRAFT' 
					and m.AcType=ma.ACTYPE and m.acct_crncy_code = ma.CNCY),CyCode) AS nvarchar(8)),8)+right(rtrim((select distinct case when ACTYPE = '43' and m.Limit1 between 1500000.01 and 2500000   then 'ZO414' 
					when ACTYPE = '43' and m.Limit1 between 2500000.01 and 99999999999 then 'MM416' 
					when ACTYPE = '43' and m.Limit1 between 0 and 1500000 then 'FT415'
					when ACTYPE = '47' and m.Limit1 between 1500000.01 and 2500000    then 'ZO414' 
					when ACTYPE = '47' and m.Limit1 between 2500000.01 and 99999999999 then 'MM416' 
					when ACTYPE = '47' and m.Limit1 between 0 and 1500000 then 'FT415'
					else F_SCHEME_CODE end from  FINMIG.dbo.PRODUCT_MAPPING ma WHERE MODULE = 'OVERDRAFT' 
					and m.AcType=ma.ACTYPE and m.acct_crncy_code = ma.CNCY)),3)  ForAcid into FINMIG.dbo.ForAcidOD
FROM #FinalMaster m
--LEFT join  (SELECT * FROM FINMIG.dbo.PRODUCT_MAPPING WHERE MODULE = 'OVERDRAFT') ma on m.AcType=ma.ACTYPE
--and m.acct_crncy_code = ma.CNCY