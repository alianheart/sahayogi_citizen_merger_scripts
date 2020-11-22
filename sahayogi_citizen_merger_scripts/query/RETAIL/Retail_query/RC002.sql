use PPIVSahayogiVBL;

Declare @MigDate date, @v_MigDate nvarchar(15)
set @MigDate =(select Today from ControlTable);
set @v_MigDate=REPLACE(REPLACE(CONVERT(VARCHAR,@MigDate,106), ' ','-'), ',','')


SELECT distinct
G.ClientCode
,G.cif_id AS ORGKEY
,'Mailing' AS ADDRESSCATEGORY
,isnull(REPLACE(REPLACE(CONVERT(VARCHAR,isnull(case when tmaster.mindate < dob.CUST_DOB then dob.CUST_DOB else tmaster.mindate end, dob.CUST_DOB),106), ' ','-'), ',',''), @v_MigDate)  AS START_DATE
--,t2.DateOfBirth
--,AcOpenDate
,'' AS PHONENO1LOCALCODE
,'' AS PHONENO1CITYCODE
,'' AS PHONENO1COUNTRYCODE
,'' AS PHONENO2LOCALCODE
,'' AS PHONENO2CITYCODE
,'' AS PHONENO2COUNTRYCODE
,'' AS WORKEXTENSION
,'' AS FAXNOLOCALCODE
,'' AS FAXNOCITYCODE
,'' AS FAXNOCOUNTRYCODE
--,t2.eMail AS EMAIL
,case when FINMIG.dbo.F_IsValidEmail( t2.eMail)=1 then t2.eMail
		else '' end as EMAIL
,'' AS PAGERNOLOCALCODE
,'' AS PAGERNOCITYCODE
,'' AS PAGERNOCOUNTRYCODE
,'' AS TELEXLOCALCODE
,'' AS TELEXCITYCODE
,'' AS TELEXCOUNTRYCODE
,'' AS HOUSE_NO
,'' AS PREMISE_NAME
,'' AS BUILDING_LEVEL
,'' AS STREET_NO
,'' AS STREET_NAME
,'' AS SUBURB
,'' AS LOCALITY_NAME
,'' AS TOWN
,'' AS DOMICILE
--,t2.DistrictCode AS CITY_CODE
,isnull(m.CITYCode,'NMIG') AS CITY_CODE
,isnull(m.StateCode,'MIGR') AS STATE_CODE
--,t2.DistrictCode AS STATE_CODE

,'977' AS ZIP
--,ct.CountryCode as COUNTRY_CODE
,case	when t2.CountryCode = '11' then 'IN'
		when t2.CountryCode = '21' then 'US'
		when t2.CountryCode = '23' then 'AU'
		when t2.CountryCode = '32' then 'AT'
else 'NP' end as COUNTRY_CODE
,case when isnull(t2.ContactAdd1, '') = '' then 'MIGRATION'
else replace(t2.Address1, '|', '') end  AS ADDRESS_LINE1
,t2.Address2 AS ADDRESS_LINE2
,t2.Address3 AS ADDRESS_LINE3
,'31-Dec-2099' AS END_DATE
,'' AS SMALL_STR1
,'' AS SMALL_STR2
,'' AS SMALL_STR3
,'' AS SMALL_STR4
,'' AS SMALL_STR5
,'' AS SMALL_STR6
,'' AS SMALL_STR7
,'' AS SMALL_STR8
,'' AS SMALL_STR9
,'' AS SMALL_STR10
,'' AS MED_STR1
,'' AS MED_STR2
,'' AS MED_STR3
,'' AS MED_STR4
,'' AS MED_STR5
,'' AS MED_STR6
,'' AS MED_STR7
,'' AS MED_STR8
,'' AS MED_STR9
,'' AS MED_STR10
,'' AS LARGE_STR1
,'' AS LARGE_STR2
,'' AS LARGE_STR3
,'' AS LARGE_STR4
,'' AS LARGE_STR5
,'' AS DATE1
,'' AS DATE2
,'' AS DATE3
,'' AS DATE4
,'' AS DATE5
,'' AS DATE6
,'' AS DATE7
,'' AS DATE8
,'' AS DATE9
,'' AS DATE10
,'' AS NUMBER1
,'' AS NUMBER2
,'' AS NUMBER3
,'' AS NUMBER4
,'' AS NUMBER5
,'' AS NUMBER6
,'' AS NUMBER7
,'' AS NUMBER8
,'' AS NUMBER9
,'' AS NUMBER10
,'' AS DECIMAL1
,'' AS DECIMAL2
,'' AS DECIMAL3
,'' AS DECIMAL4
,'' AS DECIMAL5
,'' AS DECIMAL6
,'' AS DECIMAL7
,'' AS DECIMAL8
,'' AS DECIMAL9
,'' AS DECIMAL10
,G.cif_id AS CIFID
,'Y' AS PREFERREDADDRESS
,'' AS HOLDMAILINITIATEDBY
,'N' AS HOLDMAILFLAG
,'' AS BUSINESSCENTER
,'' AS HOLDMAILREASON
,'FREE_TEXT_FORMAT' AS PREFERREDFORMAT
,'Add1: '+ case when isnull(t2.Address1, '') = '' then 'MIGRATION'
	else isnull(replace(t2.Address1, '|', ''),'') end
	+'/'+'Add2: '+isnull(replace(t2.Address2, '|', ''),'')
	+'/'+'Add3: '+isnull(replace(t2.Address3, '|', ''),'')
	+'/'+'ContAdd1: '+isnull(replace(t2.ContactAdd1, '|', ''),'')
	+'/'+'ContAdd2: '+isnull(replace(t2.ContactAdd2, '|', ''),'')
	+'/'+'ContAdd3: '+isnull(replace(t2.ContactAdd3, '|', ''),'')
	+'/'+'City: '+isnull(t2.City,'')
	+'/'+'PHNo: '+isnull(t2.Phone,'')
	+'/'+'MobNo: '+isnull(t2.MobileNo,'')
	+'/'+'Fax2: '+isnull(Fax2,'')
	+'/'+'FaxNo: '+isnull(t2.FaxNo,'')   
	+'/'+'AltAdd1: '+isnull(replace(AlternateAdd1, '|', ''),'')
	+'/'+'AltAdd2 '+isnull(replace(AlternateAdd2, '|', ''),'') 
	+'/'+'AltAdd3: '+isnull(replace(AlternateAdd3, '|', ''),'')
	 AS FREETEXTADDRESS
,'FULL_ADDRESS_PUMORI' AS FREETEXTLABEL
,'N' AS IS_ADDRESS_PROOF_RCVD
,REPLACE(REPLACE(CONVERT(VARCHAR,GETDATE(),106), ' ','-'), ',','') AS LASTUPDATE_DATE
,'01' AS BANK_ID
,'' AS ISADDRESSVERIFIED
FROM Master t1 JOIN ClientTable t2 ON t1.ClientCode = t2.ClientCode
join FINMIG..GEN_CIFID G on G.ClientCode = t1.ClientCode
join FINMIG..DateOfBirth dob on dob.ClientCode = t2.ClientCode
left join FINMIG.dbo.Mapping m
on substring(ltrim(t2.DistrictCode), patindex('%[^0]%',ltrim(t2.DistrictCode)),10) =m.DistrictCode
JOIN 

(
SELECT t.ClientCode,
	
	MIN(m.AcOpenDate) AS mindate
	FROM ClientTable t join Master m on  t.ClientCode = m.ClientCode 
	GROUP BY t.ClientCode , t.DateOfBirth
) AS tmaster ON t1.ClientCode = tmaster.ClientCode --AND tmaster.mindate = t1.AcOpenDate

WHERE G.ClientSeg = 'R'  --and G.cif_id in ('R004600625', 'R004601705', 'R004609540')

--order by ORGKEY
union all



-- Query for RC002
--USE PumoriPlusCTZ

SELECT distinct
G.ClientCode
,G.cif_id AS ORGKEY
,'PERM' AS ADDRESSCATEGORY
,isnull(REPLACE(REPLACE(CONVERT(VARCHAR,isnull(case when tmaster.mindate < dob.CUST_DOB then dob.CUST_DOB else tmaster.mindate end, dob.CUST_DOB),106), ' ','-'), ',',''), @v_MigDate)  AS START_DATE
--,t2.DateOfBirth
--,AcOpenDate
,'' AS PHONENO1LOCALCODE
,'' AS PHONENO1CITYCODE
,'' AS PHONENO1COUNTRYCODE
,'' AS PHONENO2LOCALCODE
,'' AS PHONENO2CITYCODE
,'' AS PHONENO2COUNTRYCODE
,'' AS WORKEXTENSION
,'' AS FAXNOLOCALCODE
,'' AS FAXNOCITYCODE
,'' AS FAXNOCOUNTRYCODE
--,t2.eMail AS EMAIL
,case when FINMIG.dbo.F_IsValidEmail( t2.eMail)=1 then t2.eMail
		else '' end as EMAIL
,'' AS PAGERNOLOCALCODE
,'' AS PAGERNOCITYCODE
,'' AS PAGERNOCOUNTRYCODE
,'' AS TELEXLOCALCODE
,'' AS TELEXCITYCODE
,'' AS TELEXCOUNTRYCODE
,'' AS HOUSE_NO
,'' AS PREMISE_NAME
,'' AS BUILDING_LEVEL
,'' AS STREET_NO
,'' AS STREET_NAME
,'' AS SUBURB
,'' AS LOCALITY_NAME
,'' AS TOWN
,'' AS DOMICILE
--,t2.DistrictCode AS CITY_CODE
,isnull(m.CITYCode,'NMIG') AS CITY_CODE
,isnull(m.StateCode,'MIGR') AS STATE_CODE
--,t2.DistrictCode AS STATE_CODE

,'977' AS ZIP
--,ct.CountryCode as COUNTRY_CODE
,case	when t2.CountryCode = '11' then 'IN'
		when t2.CountryCode = '21' then 'US'
		when t2.CountryCode = '23' then 'AU'
		when t2.CountryCode = '32' then 'AT'
else 'NP' end as COUNTRY_CODE
,case when isnull(t2.Address1, '') = '' then 'MIGRATION' --as per durga dai
else replace(t2.Address1, '|', '') end  AS ADDRESS_LINE1
,t2.Address2 AS ADDRESS_LINE2
,t2.Address3 AS ADDRESS_LINE3
,'31-Dec-2099' AS END_DATE
,'' AS SMALL_STR1
,'' AS SMALL_STR2
,'' AS SMALL_STR3
,'' AS SMALL_STR4
,'' AS SMALL_STR5
,'' AS SMALL_STR6
,'' AS SMALL_STR7
,'' AS SMALL_STR8
,'' AS SMALL_STR9
,'' AS SMALL_STR10
,'' AS MED_STR1
,'' AS MED_STR2
,'' AS MED_STR3
,'' AS MED_STR4
,'' AS MED_STR5
,'' AS MED_STR6
,'' AS MED_STR7
,'' AS MED_STR8
,'' AS MED_STR9
,'' AS MED_STR10
,'' AS LARGE_STR1
,'' AS LARGE_STR2
,'' AS LARGE_STR3
,'' AS LARGE_STR4
,'' AS LARGE_STR5
,'' AS DATE1
,'' AS DATE2
,'' AS DATE3
,'' AS DATE4
,'' AS DATE5
,'' AS DATE6
,'' AS DATE7
,'' AS DATE8
,'' AS DATE9
,'' AS DATE10
,'' AS NUMBER1
,'' AS NUMBER2
,'' AS NUMBER3
,'' AS NUMBER4
,'' AS NUMBER5
,'' AS NUMBER6
,'' AS NUMBER7
,'' AS NUMBER8
,'' AS NUMBER9
,'' AS NUMBER10
,'' AS DECIMAL1
,'' AS DECIMAL2
,'' AS DECIMAL3
,'' AS DECIMAL4
,'' AS DECIMAL5
,'' AS DECIMAL6
,'' AS DECIMAL7
,'' AS DECIMAL8
,'' AS DECIMAL9
,'' AS DECIMAL10
,G.cif_id AS CIFID
,'N' AS PREFERREDADDRESS
,'' AS HOLDMAILINITIATEDBY
,'N' AS HOLDMAILFLAG
,'' AS BUSINESSCENTER
,'' AS HOLDMAILREASON
,'FREE_TEXT_FORMAT' AS PREFERREDFORMAT
,'Add1: '+ case when isnull(t2.Address1, '') = '' then 'MIGRATION'
	else isnull(replace(t2.Address1, '|', ''),'') end
	+'/'+'Add2: '+isnull(replace(t2.Address2, '|', ''),'')
	+'/'+'Add3: '+isnull(replace(t2.Address3, '|', ''),'')
	+'/'+'ContAdd1: '+isnull(replace(t2.ContactAdd1, '|', ''),'')
	+'/'+'ContAdd2: '+isnull(replace(t2.ContactAdd2, '|', ''),'')
	+'/'+'ContAdd3: '+isnull(replace(t2.ContactAdd3, '|', ''),'')
	+'/'+'City: '+isnull(t2.City,'')
	+'/'+'PHNo: '+isnull(t2.Phone,'')
	+'/'+'MobNo: '+isnull(t2.MobileNo,'')
	+'/'+'Fax2: '+isnull(Fax2,'')
	+'/'+'FaxNo: '+isnull(t2.FaxNo,'')   
	+'/'+'AltAdd1: '+isnull(replace(AlternateAdd1, '|', ''),'')
	+'/'+'AltAdd2 '+isnull(replace(AlternateAdd2, '|', ''),'') 
	+'/'+'AltAdd3: '+isnull(replace(AlternateAdd3, '|', ''),'')
	 AS FREETEXTADDRESS
,'FULL_ADDRESS_PUMORI' AS FREETEXTLABEL
,'N' AS IS_ADDRESS_PROOF_RCVD
,REPLACE(REPLACE(CONVERT(VARCHAR,GETDATE(),106), ' ','-'), ',','') AS LASTUPDATE_DATE
,'01' AS BANK_ID
,'' AS ISADDRESSVERIFIED
FROM Master t1 JOIN ClientTable t2 ON t1.ClientCode = t2.ClientCode
join FINMIG..GEN_CIFID G on G.ClientCode = t1.ClientCode
join FINMIG..DateOfBirth dob on dob.ClientCode = t2.ClientCode
left join FINMIG.dbo.Mapping m
on substring(ltrim(t2.DistrictCode), patindex('%[^0]%',ltrim(t2.DistrictCode)),10) =m.DistrictCode
JOIN 

(
SELECT t.ClientCode,
	
	MIN(m.AcOpenDate) AS mindate
	FROM ClientTable t join Master m on  t.ClientCode = m.ClientCode 
	GROUP BY t.ClientCode , t.DateOfBirth
) AS tmaster ON t1.ClientCode = tmaster.ClientCode --AND tmaster.mindate = t1.AcOpenDate

WHERE G.ClientSeg = 'R'  --and G.cif_id in ('R004600625', 'R004601705', 'R004609540')

order by ORGKEY
