use PPIVSahayogiVBL

Declare @MigDate date, @v_MigDate nvarchar(15)
set @MigDate =(select Today from ControlTable);
set @v_MigDate=REPLACE(REPLACE(CONVERT(VARCHAR,@MigDate,106), ' ','-'), ',','')

IF OBJECT_ID('tempdb.dbo.#ISEBANKINGENABLED', 'U') IS NOT NULL
  DROP TABLE #ISEBANKINGENABLED;
SELECT * INTO #ISEBANKINGENABLED
FROM (SELECT DISTINCT mt.ClientCode as EBANKING FROM Master(nolock) mt
	where mt.MainCode in (select MainCode0 from CustomerTable(nolock)) and mt.IsBlocked<>'C')X

IF OBJECT_ID('tempdb.dbo.#FinalMaster', 'U') IS NOT NULL
  DROP TABLE #FinalMaster;

select * INTO #FinalMaster from (
SELECT  DISTINCT
		M.ClientCode
		,replace(replace(replace(t.Name, '&', 'and'), ',', '/'), '"', '/') as Name
		,AcType
		,BranchCode
		,(select F_SolId from FINMIG..SolMap where BranchCode = M.BranchCode) as F_SolId
		,CASE WHEN ltrim(rtrim(M.Obligor)) IN (SELECT ltrim(rtrim(ObligorCode)) FROM FINMIG.dbo.RCT WHERE RCT_ID='15') THEN 
		 (select CODE FROM FINMIG.dbo.RCT WHERE M.Obligor=ObligorCode AND RCT_ID='15')
		 ELSE '' END AS Obligor	
		,min(AcOpenDate) AS AcOpenDate
    	,CyDesc as CyCode
    	,case when CitizenshipNo  like '%[0-9]%' then CitizenshipNo 
    		  else case when ClientId like '%[0-9]%' then ClientId
    				else '*****' end
    		  end as CitizenshipNo
		,IsBlocked
		,M.AcOfficer
		,case when FINMIG.dbo.F_IsValidEmail(eMail)=1 then eMail
		else '' end as eMail
		,CASE WHEN M.ClientCode in (select EBANKING from #ISEBANKINGENABLED ) then 'Y' 
		ELSE 'N' END AS ISEBANKINGENABLED 
,ROW_NUMBER() OVER( PARTITION BY M.ClientCode ORDER BY AcOpenDate,BranchCode) AS SerialNumber
FROM Master M  join ClientTable t 
on M.ClientCode=t.ClientCode
join CurrencyTable C
on M.CyCode = C.CyCode 
where M.ClientCode 
in
(
Select ClientCode from Master(NoLock) --where BranchCode not in ('242','243')
where IsBlocked<>'C' and AcType<'50'
) 
		and (t.TypeofClient<>'002' or (isnull(t.TypeofClient, '')=''))
GROUP BY M.ClientCode, AcType, BranchCode, M.Obligor, AcOpenDate, MainCode, IsBlocked, M.AcOfficer
,M.CyCode,C.CyDesc,eMail,CitizenshipNo,ClientId,t.Name

)x
where SerialNumber=1;


-- Query for RC001
select * into FINMIG..DateOfBirth from ( 
SELECT DISTINCT
t1.ClientCode

--01 in phone local code
,CASE 
	WHEN isnull(t2.DateOfBirth, '') = '' then
		CASE WHEN isnull(t2.NepDate,'') = ''  then  '01-Jan-1995'
		ELSE
		
		CASE WHEN LEN(isnull(t2.NepDate,'')) = 10
		THEN case when dbo.f_GetRomanDate(substring(t2.NepDate, 1, 2),substring(t2.NepDate, 4, 2), substring(t2.NepDate, 7, 4)) > @MigDate
			then '01-Jan-1995' else REPLACE(
			REPLACE(convert(VARCHAR, dbo.f_GetRomanDate(substring(t2.NepDate, 1, 2),substring(t2.NepDate, 4, 2), substring(t2.NepDate, 7, 4)),106),' ','-'), ',','')
		 END
	else '01-Jan-1995' end end
	else 
	case 
	WHEN t2.DateOfBirth >= AcOpenDate
	then case when dbo.f_GetRomanDate(datepart(day,t2.DateOfBirth),datepart(month,t2.DateOfBirth), datepart(year,t2.DateOfBirth)) > @MigDate
	then '01-Jan-1995' 
	else  REPLACE(REPLACE(CONVERT(VARCHAR,dbo.f_GetRomanDate(datepart(day,t2.DateOfBirth),datepart(month,t2.DateOfBirth), datepart(year,t2.DateOfBirth)),106), ' ','-'), ',','') 
	end
	--else REPLACE(REPLACE(CONVERT(VARCHAR,t2.DateOfBirth,106), ' ','-'), ',','') 
	
	
	when t2.DateOfBirth >= @MigDate 
	then REPLACE(REPLACE(CONVERT(VARCHAR,dbo.f_GetRomanDate(datepart(day,t2.DateOfBirth),datepart(month,t2.DateOfBirth), datepart(year,t2.DateOfBirth)),106), ' ','-'), ',','')
ELSE REPLACE(REPLACE(CONVERT(VARCHAR,t2.DateOfBirth,106), ' ','-'), ',','') 

end end AS CUST_DOB


FROM #FinalMaster t1 join ClientTable t2
join FINMIG..GEN_CIFID G on G.ClientCode = t2.ClientCode
ON t1.ClientCode = t2.ClientCode
left join FINMIG.dbo.Mapping m --need to edit
on substring(ltrim(t2.DistrictCode), patindex('%[^0]%',ltrim(t2.DistrictCode)),10) = m.DistrictCode
where G.ClientSeg = 'R') h
--order by ORGKEY)
--00063114