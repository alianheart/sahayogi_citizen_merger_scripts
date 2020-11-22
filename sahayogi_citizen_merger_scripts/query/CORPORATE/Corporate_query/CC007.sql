use PPIVSahayogiVBL
Declare @MigDate date, @v_MigDate nvarchar(15)
set @MigDate = (select LastDay from ControlTable);

IF OBJECT_ID('tempdb.dbo.#FinalMaster', 'U') IS NOT NULL
  DROP TABLE #FinalMaster;			-- Drop temporary table if it exists
SELECT * INTO #FinalMaster FROM
(
	SELECT DISTINCT
	 
	M.ClientCode
	,min(AcOpenDate) AcOpenDate
	,G.cif_id
	,ROW_NUMBER() OVER( PARTITION BY M.ClientCode ORDER BY AcOpenDate,BranchCode) AS SerialNumber
	--INTO #FinalMaster
	FROM Master M WITH (NOLOCK) 
	JOIN ClientTable t2 ON M.ClientCode = t2.ClientCode
	join FINMIG..GEN_CIFID G on G.ClientCode = M.ClientCode
where G.ClientSeg = 'C' 
	group by M.ClientCode,G.cif_id, AcOpenDate, BranchCode
) AS t 
WHERE t.SerialNumber = 1 ORDER BY 1;



IF OBJECT_ID('tempdb.dbo.#DocDetail', 'U') IS NOT NULL
drop table #DocDetail;
select * Into #DocDetail from (
SELECT 
c.ClientCode 
, 'PANVT'  AS DOCCODE
, 'PAN/ VAT CERTIFICATE' DOCDESCR
,DistrictCode
,case when isnull(PANNumber,'')<>'' then convert(varchar,PANNumber)
      else
		  case when ClientId like '%[0-9]%' then convert(varchar,ClientId)
			else '*****' end
		 END As REFERENCENUMBER
 From ClientTable c with (nolock)  join #FinalMaster m
 on c.ClientCode = m.ClientCode
 
union all

SELECT 
c.ClientCode 
--, 'CREG'  AS DOCCODE
,'COR' AS DOCCODE
, 'CERTIFICATE OF REGISTRATION' DOCDESCR
,DistrictCode
, convert(varchar,ComRegNum) As REFERENCENUMBER
 From ClientTable c with (nolock)  join #FinalMaster m
 on c.ClientCode = m.ClientCode
and ComRegNum is not null) x;

SELECT DISTINCT
  t1.cif_id AS CORP_KEY
--, 'C0'+ t1.ClientCode AS CORP_REP_KEY
, '' AS CORP_REP_KEY
, '' BEN_OWN_KEY
, '' DOCDUEDATE
, REPLACE(REPLACE(CONVERT(VARCHAR,t1.AcOpenDate,106), ' ','-'), ',','') DOCRECEIVEDDATE

,case 
	when isnull(t2.ComRegExpDate, '') = '' then '31-DEC-2099'
	else REPLACE(REPLACE(CONVERT(VARCHAR,dbo.f_GetRomanDate(DatePart(Day,t2.ComRegExpDate),DatePart(MONTH,t2.ComRegExpDate),DatePart(YEAR,t2.ComRegExpDate)),106), ' ','-'), ',','')
  end DOCEXPIRYDATE
, 'N' DOCDELFLG
, '' DOCREMARKS
, '' SCANNED
, p.DOCCODE DOCCODE
, p.DOCDESCR DOCDESCR
, left(p.REFERENCENUMBER, 20) REFERENCENUMBER
, 'Y' ISMANDATORY
, '' SCANREQUIRED
, '' ROLE
--, p.DOCCODE DOCTYPECODE --'POI'


, case 
	when DOCCODE = 'COR' then 'POCR'
	when DOCCODE = 'PANVT' then 'POTR'
	end as DOCTYPECODE
, case 
	when DOCCODE = 'COR' then 'PROOF OF COMPANY REGISTRATION'
	when DOCCODE = 'PANVT' then 'PROOF OF TAX REGISTRATION'
	end as DOCTYPEDESCR

--, DOCDESCR DOCTYPEDESCR
, '' MINDOCSREQD
, '' WAIVEDORDEFEREDDATE
, 'NP' COUNTRYOFISSUE
, isnull(m.CITYCode,'NMIG') PLACEOFISSUE

,case when p.DOCCODE = 'COR' then 
	case when isnull(t2.DateComReg, '') = '' 
	and  len(NepDate) = 10 
	then REPLACE(REPLACE(CONVERT(VARCHAR,dbo.f_GetRomanDate(substring(NepDate, 1, 2), substring(NepDate, 4, 2), substring(NepDate, 7, 4)), 106), ' ','-'), ',','')
	else case
	when t2.DateComReg >= @MigDate 
	then REPLACE(REPLACE(CONVERT(VARCHAR, AcOpenDate,106), ' ','-'), ',','')
	else REPLACE(REPLACE(CONVERT(VARCHAR,t2.DateComReg ,106), ' ','-'), ',','')
	end end
when DOCCODE = 'PANVT' then 
case when isnull(t2.PANNumberIssued, '') = '' 
	and  len(isnull(PanNepDate, '')) = 10 
	then REPLACE(REPLACE(CONVERT(VARCHAR,dbo.f_GetRomanDate(substring(PanNepDate, 1, 2), substring(PanNepDate, 4, 2), substring(PanNepDate, 7, 4)), 106), ' ','-'), ',','')
	else case
	when (t2.PANNumberIssued >= @MigDate) or  (isnull(t2.PANNumberIssued, '') = '' and  len(isnull(PanNepDate, '')) <> 10)
	then REPLACE(REPLACE(CONVERT(VARCHAR, AcOpenDate,106), ' ','-'), ',','')
	else REPLACE(REPLACE(CONVERT(VARCHAR,t2.PANNumberIssued ,106), ' ','-'), ',','')
	end end
end DOCISSUEDATE --changed in sahayogi migration

--REPLACE(REPLACE(CONVERT(VARCHAR,t1.AcOpenDate,106), ' ','-'), ',','') DOCISSUEDATE


, DOCCODE IDENTIFICATIONTYPE
, '' CORE_CUST_ID
, 'Y' IS_DOCUMENT_VERIFIED
, '01' BANK_ID
FROM #FinalMaster t1
JOIN #DocDetail p on p.ClientCode=t1.ClientCode
join ClientTable t2 on t1.ClientCode = t2.ClientCode
left join FINMIG.dbo.Mapping m
on substring(ltrim(p.DistrictCode), patindex('%[^0]%',ltrim(p.DistrictCode)),10) = m.DistrictCode
--where t1.ClientCode in ('00103978')
ORDER BY CORP_KEY

--6704