use PPIVSahayogiVBL; --New query

Declare @MigDate date, @v_MigDate nvarchar(15), @IntCalTillDate date
select  @MigDate=Today ,@IntCalTillDate=LastDay   from ControlTable;
set @v_MigDate=REPLACE(REPLACE(CONVERT(VARCHAR,@MigDate,105), ' ','-'), ',','') 




IF OBJECT_ID('tempdb.dbo.#TotalLoan', 'U') IS NOT NULL
  DROP TABLE #TotalLoan;
 
select * into #TotalLoan
from(
select  m.MainCode
		,'' as Deal_MainCode
		,m.AcType
		, m.MoveType
		, HasRepaySched
		,isNuLL(RepaySchedType,'N') RepaySchedType
		,m.Balance
		,'N' IsDeal
		,m.IntDrAmt
		,IntDrRate
		, m.CyCode
		, ct.CyDesc
		,m.ClientCode
		,G.cif_id
		,m.BranchCode
		,(select F_SolId from FINMIG..SolMap where BranchCode = m.BranchCode) as F_SolId
		,Limit as Limit1
		,case when m.LimitExpiryDate<=m.AcOpenDate	and m.LimitExpiryDate>'2000-12-31' then dateadd(day,-1,m.LimitExpiryDate)
			else m.AcOpenDate end as AcOpenDate
		,case when m.LimitExpiryDate<m.AcOpenDate and m.LimitExpiryDate<'2000-12-31' then @IntCalTillDate
		 else  m.LimitExpiryDate end as MaturityDate
		,datediff(day,m.AcOpenDate,m.LimitExpiryDate) as MaturityDays
		, m.Limit  DealAmt
		,case when isnull(lm.Nominee,'') ='' then 
				CASE WHEN NOT EXISTS (select top 1 MainCode from Master mt where mt.ClientCode = m.ClientCode and AcType < '20' and MoveType not in ('1','3','6') and IsBlocked<>'C' ) THEN ''
				else 
					(select top 1 MainCode from Master mt where mt.ClientCode = m.ClientCode and AcType < '20' and MoveType not in ('1','3','6') and IsBlocked<>'C' order by AcType)
				end	
			else  rtrim(lm.Nominee) 
		 end  as Nominee 
		,'' as PremiumRateDr
		--,case when m.Limit='0' then  ABS(ROUND(m.Balance,2))+round(m.IntDrAmt,2) else m.Limit end as  Limit
		,case when m.Limit='0' then '1' else m.Limit end as  Limit ---change requested by durga dai / raghunath sir
		,IsBlocked
		
		/*
		,case when AcType = '47' then 
		(select  MODULE from FINMIG..PRODUCT_MAPPING where ACTYPE = m.AcType and MODULE='LAA' and m.Limit between L_LIMIT and U_LIMIT)
		else (select  MODULE from FINMIG..PRODUCT_MAPPING where ACTYPE = m.AcType and MODULE='LAA') end as LoanType
		*/
		
		,Case when isnull(lm.HasRepaySched,'F')='T' and RepaySchedType in ('A','E') then 
			case when ((select count(distinct datepart(day,DueDate)) from LoanRepaySched ls where ls.MainCode = lm.MainCode AND DueDate>=@MigDate)>2) then 'NONEMI' 
				else 'EMI'
			end
		else 'NONEMI' end LoanType
		
		,Case when isnull(lm.HasRepaySched,'F')='T' and RepaySchedType in ('A','E') then 
			case when ((select count(distinct datepart(day,DueDate)) from LoanRepaySched ls where ls.MainCode = lm.MainCode AND DueDate>=@MigDate)>2) then 
					CASE WHEN m.AcType in (select ACTYPE FROM FINMIG..PRODUCT_MAPPING WHERE MODULE='LAA' AND OTHER_CONDITION like 'NONEMIMON') then 'NONEMIMON' 
						else 'NONEMI' END
				else 'EMI'
			end
		else 'NONEMI' end LoanType1
		,'LOAN' AS T_LoanType
		,IntDrAmt as IntDrAmt_IntAccrued
		,isnull(RepayFreq,IntPostFrqDr) as RepayFreq
		,TotDisburse as TotDisburse
 from  Master m (NoLock)
left JOIN LoanMaster lm ON lm.MainCode = m.MainCode and lm.BranchCode = m.BranchCode 
join FINMIG..GEN_CIFID G on G.ClientCode = m.ClientCode
LEFT join CurrencyTable ct on m.CyCode=ct.CyCode
where (round(m.Limit,2)+ round(m.IntDrAmt,2)  + ABS(round(m.Balance,2)))>0
AND m.IsBlocked <> 'C'
and m.BranchCode not in ('242','243')
and m.AcType in (select distinct ACTYPE c from FINMIG.[dbo].[PRODUCT_MAPPING] where MODULE='LAA')
and m.MoveType  not in ('1','3')

--and m.AcType in (select AcType from AcTypeTable where MoveType='6')

)x;


IF OBJECT_ID('FINMIG.dbo.TotalLoan', 'U') IS NOT NULL
  DROP TABLE FINMIG.dbo.TotalLoan;

  select 
  *,
	

case when AcType = '47' 
	then (select rtrim(pm.F_SCHEME_CODE) from FINMIG.[dbo].[PRODUCT_MAPPING] pm 
	where l.AcType=pm.ACTYPE and l.LoanType=pm.OTHER_CONDITION
 and l.CyDesc=pm.CNCY and pm.MODULE='LAA' and Limit1 between pm.L_LIMIT and U_LIMIT) 
else (select rtrim(pm.F_SCHEME_CODE) from FINMIG.[dbo].[PRODUCT_MAPPING] pm 
	where l.AcType=pm.ACTYPE and l.LoanType=pm.OTHER_CONDITION
 and l.CyDesc=pm.CNCY and pm.MODULE='LAA')
 end as F_SCHEME_CODE
							

 ,case when AcType = '47' 
	then (select rtrim(pm.GL_SUBHEAD_CODE) from FINMIG.[dbo].[PRODUCT_MAPPING] pm 
	where l.AcType=pm.ACTYPE and l.LoanType=pm.OTHER_CONDITION
 and l.CyDesc=pm.CNCY and pm.MODULE='LAA' and Limit1 between pm.L_LIMIT and U_LIMIT) 
 else (select rtrim(pm.GL_SUBHEAD_CODE) from FINMIG.[dbo].[PRODUCT_MAPPING] pm 
	where l.AcType=pm.ACTYPE and l.LoanType=pm.OTHER_CONDITION
 and l.CyDesc=pm.CNCY and pm.MODULE='LAA') end as GL_SUBHEAD_CODE


 ,case when AcType = '47' 
	then (select rtrim(pm.INTEREST_TABLE_CODE) from FINMIG.[dbo].[PRODUCT_MAPPING] pm 
	where l.AcType=pm.ACTYPE and l.LoanType=pm.OTHER_CONDITION
 and l.CyDesc=pm.CNCY and pm.MODULE='LAA' and Limit1 between pm.L_LIMIT and U_LIMIT) 
 else (select rtrim(pm.INTEREST_TABLE_CODE) from FINMIG.[dbo].[PRODUCT_MAPPING] pm 
	where l.AcType=pm.ACTYPE and l.LoanType=pm.OTHER_CONDITION
 and l.CyDesc=pm.CNCY and pm.MODULE='LAA') end as INTEREST_TABLE_CODE

 into FINMIG.dbo.TotalLoan from #TotalLoan l;
 

--SELECT * FROM FINMIG.dbo.TotalLoan WHERE AcOpenDate>MaturityDate



 -- one time run  FINMIG.dbo.ForAcidLAA Creation


 IF OBJECT_ID('FINMIG.dbo.ForAcidLAA', 'U') IS NOT NULL
  DROP TABLE FINMIG.dbo.ForAcidLAA;

 select  l.MainCode,(select F_SolId from FINMIG..SolMap where BranchCode = l.BranchCode) as F_SolId, l.BranchCode,l.CyDesc,l.AcType,LoanType,LoanType1,l.ClientCode, l.cif_id, RepayFreq,HasRepaySched
 ,T_LoanType,l.Balance,IntDrAmt_IntAccrued,INTEREST_TABLE_CODE,F_SCHEME_CODE,GL_SUBHEAD_CODE,
 (select F_SolId from FINMIG..SolMap where BranchCode = l.BranchCode)+ CyCode+Right('00000000'+cast(ROW_NUMBER() OVER( PARTITION BY l.BranchCode,F_SCHEME_CODE,CyCode 
ORDER BY l.MainCode,l.BranchCode,AcOpenDate ,F_SCHEME_CODE,l.CyCode) AS nvarchar(8)),8)+ right(rtrim(F_SCHEME_CODE),3)  ForAcid
into FINMIG.dbo.ForAcidLAA   
from FINMIG.dbo.TotalLoan l 
 order by l.BranchCode,AcOpenDate ,F_SCHEME_CODE,l.CyCode 



--select * from FINMIG.dbo.TotalLoan

