use PPIVSahayogiVBL
IF OBJECT_ID('tempdb.dbo.#FinalMaster', 'U') IS NOT NULL
  DROP TABLE #FinalMaster;			-- Drop temporary table if it exists

SELECT * INTO #FinalMaster FROM
(	
	
	SELECT DISTINCT 
	M.Name
	,M.ClientCode
	,AcType
	,G.cif_id
	,M.BranchCode
	,M.Obligor
	,AcOpenDate
	,M.MainCode
	,DateOfBirth
	 ,CyDesc as	 CyCode
	,M.AcOfficer
	,case when FINMIG.dbo.F_IsValidEmail( eMail)=1 then eMail
		else '' end as eMail
	,ROW_NUMBER() OVER( PARTITION BY M.ClientCode ORDER BY AcOpenDate,BranchCode) AS SerialNumber
	FROM Master M with (NOLOCK)
	JOIN ClientTable t2 ON M.ClientCode = t2.ClientCode
	join FINMIG..GEN_CIFID G on G.ClientCode = t2.ClientCode
	join CurrencyTable C
	on M.CyCode = C.CyCode
where G.ClientSeg = 'C'
) AS t
Where t.SerialNumber = 1 
ORDER BY 1;


 
 SELECT DISTINCT
  t1.cif_id CORP_KEY
, t1.cif_id CIFID
, '' CORP_REP_KEY
, 'Registered' ADDRESSCATEGORY
--,  REPLACE(REPLACE(CONVERT(VARCHAR, AcOpenDate,106),' ','-'),',','') AS START_DATE
,case when isnull(t1.DateOfBirth,'')<>'' then REPLACE(CONVERT(VARCHAR, t1.DateOfBirth,106),' ','-') 
else   REPLACE(REPLACE(CONVERT(VARCHAR, AcOpenDate,106),' ','-'),',','') end as  START_DATE

, '' PHONENO1LOCALCODE
, '' PHONENO1CITYCODE
, '977' PHONENO1COUNTRYCODE
, '' PHONENO2LOCALCODE
, '' PHONENO2CITYCODE
, '' PHONENO2COUNTRYCODE
, '' FAXNOLOCALCODE
, '' FAXNOCITYCODE
, '977' FAXNOCOUNTRYCODE
, t1.eMail EMAIL
, '' PAGERNOLOCALCODE
, '' PAGERNOCITYCODE
, '' PAGERNOCOUNTRYCODE
, '' TELEXLOCALCODE
, '' TELEXCITYCODE
, '' TELEXCOUNTRYCODE
, '' HOUSE_NO
, '' PREMISE_NAME
, '' BUILDING_LEVEL
, '' STREET_NO
, '' STREET_NAME
, '' SUBURB
, '' LOCALITY_NAME
, '' TOWN
, '' DOMICILE
--, t2.DistrictCode CITY_CODE
,isnull(m.CITYCode,'NMIG') as CITY_CODE
,isnull(m.StateCode,'MIGR') AS STATE_CODE
--, t2.DistrictCode STATE_CODE
, '977' ZIP
, 'NP' COUNTRY_CODE
, '' SMALL_STR1
, '' SMALL_STR2
, '' SMALL_STR3
, '' SMALL_STR4
, '' SMALL_STR5
, '' SMALL_STR6
, '' SMALL_STR7
, '' SMALL_STR8
, '' SMALL_STR9
, '' SMALL_STR10
, '' MED_STR1
, '' MED_STR2
, '' MED_STR3
, '' MED_STR4
, '' MED_STR5
, '' MED_STR6
, '' MED_STR7
, '' MED_STR8
, '' MED_STR9
, '' MED_STR10
, '' LARGE_STR1
, '' LARGE_STR2
, '' LARGE_STR3
, '' LARGE_STR4
, '' LARGE_STR5
, '' DATE1
, '' DATE2
, '' DATE3
, '' DATE4
, '' DATE5
, '' DATE6
, '' DATE7
, '' DATE8
, '' DATE9
, '' DATE10
, '' NUMBER1
, '' NUMBER2
, '' NUMBER3
, '' NUMBER4
, '' NUMBER5
, '' NUMBER6
, '' NUMBER7
, '' NUMBER8
, '' NUMBER9
, '' NUMBER10
, '' DECIMAL1
, '' DECIMAL2
, '' DECIMAL3
, '' DECIMAL4
, '' DECIMAL5
, '' DECIMAL6
, '' DECIMAL7
, '' DECIMAL8
, '' DECIMAL9
, '' DECIMAL10
, 'Y' PREFERREDADDRESS
, '' HOLDMAILINITIATEDBY
, 'N' HOLDMAILFLAG
, 'BC1' BUSINESSCENTER
, '' HOLDMAILREASON
, 'FREE_TEXT_FORMAT' PREFERREDFORMAT
, 'Add1: '+case when isnull(replace(t2.Address1, '|', ''), '') = '' then 'MIGRATION' else isnull(replace(t2.Address1, '|', ''),'') end
	+'/'+'Add2: '+isnull(Address2,'')
	+'/'+'Add3: '+isnull(Address3,'')
	+'/'+'ConAdd1: '+isnull(replace(t2.Address1, '|', ''),'')
	+'/'+'ConAdd2: '+isnull(ContactAdd2,'')
	+'/'+'ConAdd3: '+isnull(ContactAdd3,'')
	+'/'+'City: '+isnull(City,'')
	+'/'+'PNo: '+isnull(Phone,'')
	+'/'+'MNo: '+isnull(MobileNo,'')
	+'/'+'Fax2: '+isnull(Fax2,'')+'/'+'FaxNo: '+isnull(FaxNo,'') 
--+'/'+'PagerNo: '+isnull(PagerNo,'')
	 FREETEXTADDRESS
, 'FULL_ADDRESS_PUMORI' FREETEXTLABEL
, 'Y' IS_ADDRESS_PROOF_RCVD
, '' LASTUPDATE_DATE
, replace(isnull(rtrim(ltrim(t2.Address1)), 'MIGRATION ADDRESS'), '|', '') ADDRESS_LINE1
, t2.Address2 ADDRESS_LINE2
, t2.Address3 ADDRESS_LINE3
, '01' BANK_ID
, 'Y' ISADDRESSVERIFIED
FROM #FinalMaster t1 JOIN ClientTable t2 ON t1.ClientCode = t2.ClientCode
left join FINMIG.dbo.Mapping m
on substring(ltrim(t2.DistrictCode), patindex('%[^0]%',ltrim(t2.DistrictCode)),10) = m.DistrictCode
--where t1.cif_id in ('C004693722')



union all

 SELECT DISTINCT
  t1.cif_id CORP_KEY
, t1.cif_id CIFID
, '' CORP_REP_KEY
, 'Mailing' ADDRESSCATEGORY
--,  REPLACE(REPLACE(CONVERT(VARCHAR, AcOpenDate,106),' ','-'),',','') AS START_DATE
,case when isnull(t1.DateOfBirth,'')<>'' then REPLACE(CONVERT(VARCHAR, t1.DateOfBirth,106),' ','-') 
else   REPLACE(REPLACE(CONVERT(VARCHAR, AcOpenDate,106),' ','-'),',','') end as  START_DATE

, '' PHONENO1LOCALCODE
, '' PHONENO1CITYCODE
, '977' PHONENO1COUNTRYCODE
, '' PHONENO2LOCALCODE
, '' PHONENO2CITYCODE
, '' PHONENO2COUNTRYCODE
, '' FAXNOLOCALCODE
, '' FAXNOCITYCODE
, '977' FAXNOCOUNTRYCODE
, t1.eMail EMAIL
, '' PAGERNOLOCALCODE
, '' PAGERNOCITYCODE
, '' PAGERNOCOUNTRYCODE
, '' TELEXLOCALCODE
, '' TELEXCITYCODE
, '' TELEXCOUNTRYCODE
, '' HOUSE_NO
, '' PREMISE_NAME
, '' BUILDING_LEVEL
, '' STREET_NO
, '' STREET_NAME
, '' SUBURB
, '' LOCALITY_NAME
, '' TOWN
, '' DOMICILE
--, t2.DistrictCode CITY_CODE
,isnull(m.CITYCode,'NMIG') as CITY_CODE
,isnull(m.StateCode,'MIGR') AS STATE_CODE
--, t2.DistrictCode STATE_CODE
, '977' ZIP
, 'NP' COUNTRY_CODE
, '' SMALL_STR1
, '' SMALL_STR2
, '' SMALL_STR3
, '' SMALL_STR4
, '' SMALL_STR5
, '' SMALL_STR6
, '' SMALL_STR7
, '' SMALL_STR8
, '' SMALL_STR9
, '' SMALL_STR10
, '' MED_STR1
, '' MED_STR2
, '' MED_STR3
, '' MED_STR4
, '' MED_STR5
, '' MED_STR6
, '' MED_STR7
, '' MED_STR8
, '' MED_STR9
, '' MED_STR10
, '' LARGE_STR1
, '' LARGE_STR2
, '' LARGE_STR3
, '' LARGE_STR4
, '' LARGE_STR5
, '' DATE1
, '' DATE2
, '' DATE3
, '' DATE4
, '' DATE5
, '' DATE6
, '' DATE7
, '' DATE8
, '' DATE9
, '' DATE10
, '' NUMBER1
, '' NUMBER2
, '' NUMBER3
, '' NUMBER4
, '' NUMBER5
, '' NUMBER6
, '' NUMBER7
, '' NUMBER8
, '' NUMBER9
, '' NUMBER10
, '' DECIMAL1
, '' DECIMAL2
, '' DECIMAL3
, '' DECIMAL4
, '' DECIMAL5
, '' DECIMAL6
, '' DECIMAL7
, '' DECIMAL8
, '' DECIMAL9
, '' DECIMAL10
, 'N' PREFERREDADDRESS 
, '' HOLDMAILINITIATEDBY
, 'N' HOLDMAILFLAG
, 'BC1' BUSINESSCENTER
, '' HOLDMAILREASON
, 'FREE_TEXT_FORMAT' PREFERREDFORMAT
, 'Add1: '+case when isnull(replace(t2.ContactAdd1, '|', ''), '') = '' then 'MIGRATION' else isnull(replace(t2.ContactAdd1, '|', ''),'') end
	+'/'+'Add2: '+isnull(Address2,'')
	+'/'+'Add3: '+isnull(Address3,'')
	+'/'+'ConAdd1: '+isnull(replace(t2.ContactAdd1, '|', ''),'')
	+'/'+'ConAdd2: '+isnull(ContactAdd2,'')
	+'/'+'ConAdd3: '+isnull(ContactAdd3,'')
	+'/'+'City: '+isnull(City,'')
	+'/'+'PNo: '+isnull(Phone,'')
	+'/'+'MNo: '+isnull(MobileNo,'')
	+'/'+'Fax2: '+isnull(Fax2,'')+'/'+'FaxNo: '+isnull(FaxNo,'') 
--+'/'+'PagerNo: '+isnull(PagerNo,'')
	 FREETEXTADDRESS
, 'FULL_ADDRESS_PUMORI' FREETEXTLABEL
, 'Y' IS_ADDRESS_PROOF_RCVD
, '' LASTUPDATE_DATE
, replace(isnull(rtrim(ltrim(replace(replace(replace(replace(t2.Address1, char(9), ''),char(13), ''), char(10), ''), '', ''))), 'MIGRATION ADDRESS'), '|', '') ADDRESS_LINE1
, t2.Address2 ADDRESS_LINE2
, t2.Address3 ADDRESS_LINE3
, '01' BANK_ID
, 'Y' ISADDRESSVERIFIED
FROM #FinalMaster t1 JOIN ClientTable t2 ON t1.ClientCode = t2.ClientCode
left join FINMIG.dbo.Mapping m
on substring(ltrim(t2.DistrictCode), patindex('%[^0]%',ltrim(t2.DistrictCode)),10) = m.DistrictCode
--where t1.cif_id in ('C004693722')

ORDER BY CORP_KEY
