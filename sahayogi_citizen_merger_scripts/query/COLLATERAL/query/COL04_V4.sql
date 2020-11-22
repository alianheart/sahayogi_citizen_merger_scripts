use PPIVSahayogiVBL

DECLARE @MigDate DATE, @v_MigDate nvarchar(15)

set @MigDate = (select Today from ControlTable);
set @v_MigDate=REPLACE(CONVERT(VARCHAR,@MigDate,106), ' ','-');

IF OBJECT_ID('tempdb.dbo.#Loan', 'U') IS NOT NULL
  DROP TABLE #Loan;

select * into #Loan from (
select  distinct ForAcid,t1.MainCode
from FINMIG..TotalLoan t1 join FINMIG..ForAcidLAA t2
on t1.MainCode=t2.MainCode
where isnull(Deal_MainCode,'') = ''
union all
select  distinct ForAcid as ForAcid,t1.Deal_MainCode as MainCode
from FINMIG..TotalLoan t1 join FINMIG..ForAcidLAA t2
on t1.MainCode=t2.MainCode
where isnull(Deal_MainCode,'')<>''

)x
order by MainCode

select distinct
'SIP' AS INDICATOR,
mt.ReferenceNo
,CASE WHEN ISNULL(InsPolicyNo,'')<>'' AND InsPolicyNo<>'-' THEN RIGHT(InsPolicyNo,15)
	ELSE 'MIG' END AS INSU_REF_NUM,
'MIG' AS INSU_TYPE,
CASE WHEN isnull(InsuredAmt,'')<>''	THEN InsuredAmt
	ELSE '1.00' END  AS POLICY_AMT,
case when ISNULL(Insurer,'')<>'' then Insurer
	else 'Migration' end AS COMPANY_NAME,
'' AS ITEMS_INSURD,
isnull(REPLACE(CONVERT(VARCHAR,InsIssueDate,106), ' ','-'),@v_MigDate) AS RISK_COVER_START_DATE ,
case when InsMaturityDate>'2099-12-30' then '30-Dec-2099'
	when InsMaturityDate<InsIssueDate then REPLACE(CONVERT(VARCHAR,dateadd(DAY,1,InsIssueDate),106), ' ','-')
	else isnull(REPLACE(CONVERT(VARCHAR,InsMaturityDate,106), ' ','-'),@v_MigDate) end as RISK_COVER_END_DATE, --date "DD/MM/YYYY",
'' AS FREE_TEXT,
isnull(REPLACE(CONVERT(VARCHAR,InsIssueDate,106), ' ','-'),@v_MigDate) AS LAST_PREMIUM_PAID,-- date "DD/MM/YYYY",
CASE WHEN InsFrq ='7' THEN 'Y'
	  WHEN InsFrq ='6' THEN 'H'
	  WHEN InsFrq ='5' THEN 'Q'
	  WHEN InsFrq ='4' THEN 'M'
	   ELSE 'Y' END AS  PREMIUM_FREQ_TYPE,
isnull(InsPremium,'') AS PREMIUM_AMT,
ForAcid as FORACID
from MortgageTable mt 
join (select MainCode,ForAcid from #Loan union all select MainCode,ForAcid from FINMIG..ForAcidOD
union all select MainCode,ForAcid from FINMIG..ForAcidSBA) fl
on fl.MainCode = mt.ReferenceNo
join MortgageCode mc 
on mt.MortgageCode = mc.MortgageCode 
JOIN Master M
on M.MainCode = mt.ReferenceNo
where ForAcid is not null

--and M.MainCode ='0010000091MD'
--and (isnull(InsuredAmt,0)<>0)
--and (round(abs(mt.MortgageValue),2)>0 or round(abs(M.Limit),2)>0 or round(IntDrAmt,2)<>0 )

--AND InsMaturityDate<InsIssueDate
ORDER BY ForAcid
