use PPIVSahayogiVBL

Declare @MigDate date, @v_MigDate nvarchar(15)
set @MigDate =(select Today from ControlTable);
set @v_MigDate=REPLACE(REPLACE(CONVERT(VARCHAR,@MigDate,106), ' ','-'), ',','')

IF OBJECT_ID('tempdb.dbo.#FinalMaster','U') IS NOT NULL
DROP TABLE #FinalMaster; -- Drops table if exists

SELECT * INTO #FinalMaster FROM
(	
	SELECT  
	replace(replace(replace(t2.Name, '&', 'and'), ',', '/'), '"', '/') as Name
	,M.ClientCode
	,AcType
	,M.BranchCode
	,(select F_SolId from FINMIG..SolMap where BranchCode = M.BranchCode) F_SolId
	,CASE WHEN M.Obligor IN (SELECT ObligorCode FROM FINMIG.dbo.RCT WHERE RCT_ID='15') THEN 
	(select CODE FROM FINMIG.dbo.RCT WHERE M.Obligor=ObligorCode AND RCT_ID='15')
	 ELSE '' END AS Obligor	
	,MIN(AcOpenDate) as AcOpenDate
	,DateOfBirth
	,M.MainCode
	,CyDesc as CyCode
	,M.AcOfficer
	,case when FINMIG.dbo.F_IsValidEmail( eMail)=1 then eMail
		else '' end as eMail
	,ROW_NUMBER() OVER( PARTITION BY M.ClientCode ORDER BY AcOpenDate,BranchCode) AS SerialNumber
	FROM Master M with (NOLOCK)
	JOIN ClientTable t2 ON M.ClientCode = t2.ClientCode
	join CurrencyTable C
	on M.CyCode = C.CyCode
where t2.ClientCode in
 (
	Select ClientCode from Master(NoLock) where BranchCode not in ('242','243')
		 and IsBlocked<>'C' and AcType<'50'
)
and t2.TypeofClient = '002'

GROUP BY t2.Name,M.ClientCode, AcType, BranchCode, M.Obligor, AcOpenDate, MainCode, IsBlocked, M.AcOfficer,M.CyCode,C.CyDesc,DateOfBirth,eMail

) AS t
Where t.SerialNumber = 1 




-- 14,854 rows in 5sec
-- 16223 rows second migration
-- QUERY CC001

SELECT DISTINCT
C.cif_id AS CORP_KEY
,'CUSTOMER' ENTITY_TYPE
,replace(replace(t1.Name, '|', ''), '''', '') CORPORATENAME_NATIVE
, REPLACE(REPLACE(CONVERT(VARCHAR, AcOpenDate,106),' ','-'),',','') AS RELATIONSHIP_STARTDATE

,'ACTVE' as STATUS
--, 'CORPORATE' LEGALENTITY_TYPE
, case 
	when isnull(ClientCategory, '') = '' then '013' 
	when upper(ClientCategory) = 'COR' then '013' 
	when upper(ClientCategory) = 'GOV' then 'GVENT'
	when upper(ClientCategory) = 'JOI' then 'JV'
	when upper(ClientCategory) = 'LTD' then 'LTDCO' 
	when upper(ClientCategory) = 'NON' then 'NGO'
	when upper(ClientCategory) = 'OTH' then '013'
	when upper(ClientCategory) = 'PRE' then '013'
	when upper(ClientCategory) = 'PAR' then 'PRTNR'
	when upper(ClientCategory) = 'PUB' then 'LTDCO' 
	when upper(ClientCategory) = 'PVT' then 'PVTCO'
	when upper(ClientCategory) = 'SOL' then 'SOLEP'
	when upper(ClientCategory) = 'TRU' then 'TRUST'
	end as  LEGALENTITY_TYPE
, CASE WHEN ltrim(upper(Key_Risk_Grade)) like 'H%' THEN 'HR'
WHEN ltrim(upper(Key_Risk_Grade)) like 'M%' THEN 'MR'
WHEN ltrim(upper(Key_Risk_Grade)) like 'L%' THEN 'LR'
ELSE 'LR' 
END AS  SEGMENT
/*, CASE WHEN Key_Risk_Grade IN ('VIP','NF2F','PEP','HPP') THEN 'HR'
	WHEN Key_Risk_Grade = 'Lr' THEN 'LR' 
	WHEN Key_Risk_Grade = 'Mr' THEN 'MR' 
ELSE 'MIG' END  AS SUBSEGMENT
*/
,CASE WHEN ltrim(upper(Key_Risk_Grade)) like 'H%' THEN ( case when VIP='T' then 'VIP'
														when NF2F='T' then 'PEPS1'
														when PEP='T' then 'PEPS1'
														when HPP='T' then 'HPP'
														else 'OTH2' END)
WHEN ltrim(upper(Key_Risk_Grade)) like 'M%' THEN 'MR'
WHEN ltrim(upper(Key_Risk_Grade)) like 'L%' THEN 'LR'
ELSE 'LR' END AS SUBSEGMENT

, isnull(t2.WebAddress,'') WEBSITE_ADDRESS
, CASE WHEN t2.Designation is not NULL and t2.Designation <> '' THEN left(t2.Designation,30) 
	ELSE 'MIGR' END AS KEYCONTACT_PERSONNAME
, '01' AS PHONECITYCODE
--,CASE WHEN t2.Phone = t2.Phone and t2.Phone <> '' THEN LEFT(t2.Phone,15) ELSE '01' END AS PHONELOCALCODE
,CASE WHEN t2.Phone is not null and t2.Phone<>'' THEN 
	case when Phone  not like '%[0-9]%' then '0000'
	when patindex('%,%',Phone)>0 then left(substring(Phone,0,patindex('%,%',Phone)),16)
	when patindex('%/%',Phone)>0 then left(substring(Phone,0,patindex('%/%',Phone)),16)
	when patindex('%;%',Phone)>0 then left(substring(Phone,0,patindex('%;%',Phone)),16)
	else left(t2.Phone,15)  end
 ELSE '0000' END AS PHONELOCALCODE

, '977' PHONECOUNTRYCODE
,  'Remarks: '+isnull(t2.Remarks,'')+'/'+'Telephone2: '+isnull(t2.Telephone2,'') AS NOTES
, 'NP' PRINCIPLE_PLACEOPERATION
, 'BG2' BUSINESS_GROUP
, 'UBSADMIN' PRIMARYRM_ID
,case when isnull(t1.DateOfBirth,'')<>'' then REPLACE(CONVERT(VARCHAR, t1.DateOfBirth,106),' ','-') else   REPLACE(REPLACE(CONVERT(VARCHAR, AcOpenDate,106),' ','-'),',','') end as  DATE_OF_INCORPORATION
, '' DATE_OF_COMMENCEMENT
, t1.F_SolId PRIMARY_SERVICE_CENTER
, 'UBSADMIN' RELATIONSHIP_CREATEDBY
, 'DEPO' SECTOR
, 'DEPO' SUBSECTOR
,  left('PAN:'+isnull(CONVERT(VARCHAR, PANNumber, 120),0)+' IDt:'+isnull(LEFT(CONVERT(VARCHAR, PanNepDate, 120), 10),0)+' '+isnull(LEFT(CONVERT(VARCHAR, PANNumberIssued, 120), 10),0),20) TAXID
, 'GOLD' ENTITYCLASS
, '000' AVERAGE_ANNUALINCOME
, isnull(t2.SourceofFunds, 'MIGRATION SOURCE') SOURCE_OF_FUNDS
, '' GROUP_ID
--,CASE WHEN t1.Obligor IN (SELECT CODE FROM FINMIG.dbo.RCT WHERE RCT_ID='15') THEN t1.Obligor
--ELSE '' END AS GROUP_ID_CODE
,isnull(t1.Obligor,'') GROUP_ID_CODE

, '' PARENT_CIF
,CASE WHEN ltrim(upper(Key_Risk_Grade)) like 'H%' THEN 'HG'
	WHEN ltrim(upper(Key_Risk_Grade)) like 'M%' THEN 'MED'
	WHEN ltrim(upper(Key_Risk_Grade)) like 'L%' THEN 'LOW'
ELSE 'MIG' END AS CUSTOMER_RATING
, '' HEALTH_CODE
, '' RECORD_STATUS
, '' EFFECTIVE_DATE
, '' LINE_OF_ACTIVITY_DESC
, '' CUST_MGR_OPIN
, 'CORPORATE' CUST_TYPE_DESC
, '' CUST_STAT_CHG_DATE
, '' TDS_TBL_DESC
, '' CUST_SWIFT_CODE
, 'N' IS_SWIFT_CODE_OF_BANK
, 0 CUSTDEPOSITSINOTHERBANKS
, 0 TOTALFUNDBASE
, 0 TOTALNONFUNDBASE
, '' ADVANCEASONDATE
, '' CUST_CONST
, 'Y' DOCUMENT_RECEIVED_FLAG
--, 'NPR' CRNCY_CODE_CORPORATE
,CyCode AS CRNCY_CODE_CORPORATE 
--,case when exists (select 1 from Master m where m.ClientCode = t1.ClientCode and m.AcType between '80' and '98' ) THEN 'Y' ELSE 'N' END AS TRADE_SERVICES_AVAILED
,'N' as TRADE_SERVICES_AVAILED
, t1.F_SolId PRIMARYSOLID
, '' CHRG_DR_FORACID
, '' CHRG_DR_SOL_ID
, 'N' CUST_CHRG_HISTORY_FLG
, 999 TOT_TOD_ALWD_TIMES
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
, '' DATE6_85
, '' DATE7_85
, '' DATE8_85
, '' DATE9_85
, '' DATE10_85
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
, '' DECIMAL9
, '' DECIMAL10
, '' DECIMAL8
, replace(C.cif_id, 'C', '') as CORE_CUST_ID
, '' CIFID
, '' CREATEDBYSYSTEMID
, UPPER(replace(replace(t1.Name, '|', ''), '''', '')) AS CORPORATENAME_NATIVE1
--, LEFT(replace(replace(t1.Name, '|', ''), '''', ''),10) AS SHORT_NAME_NATIVE1
, t1.ClientCode as SHORT_NAME_NATIVE1
, '' OWNERAGENT
, 'UBSADMIN' PRIMARYRMLOGIN_ID
, '' SECONDARYRMLOGIN_ID
, '' TERTIARYRMLOGIN_ID
, '' ACCESSOWNERGROUP
, '' ACCESSOWNERSEGMENT
, '' ACCESSOWNERBC
, '' ACCESSOWNERAGENT
, '' ACCESSASSIGNEEAGENT
, '' PRIMARYPARENTCOMPANY
, 'NP' COUNTRYOFPRINCIPALOPERATION
, '' PARENTCIF_ID
, '' CHARGELEVELCODE
, 'NP' COUNTRYOFORIGIN
, 'NP' COUNTRYOFINCORPORATION
, '' INTUSERFIELD1
, '' INTUSERFIELD2
, '' INTUSERFIELD3
, '' INTUSERFIELD4
, '' INTUSERFIELD5
, 'M/S.' STRUSERFIELD1
, '' STRUSERFIELD2
, CASE WHEN Review_Date <>'' AND Key_Risk_Grade <> ' ' THEN 'Y' ELSE 'N' END AS STRUSERFIELD3
, '' STRUSERFIELD4
, '' STRUSERFIELD5
, 'Y' STRUSERFIELD6
, '' STRUSERFIELD7
, '' STRUSERFIELD8
, '' STRUSERFIELD9
, '' STRUSERFIELD10
, '' STRUSERFIELD11
, '' STRUSERFIELD12
, '' STRUSERFIELD13
, 'N' STRUSERFIELD14
, '' STRUSERFIELD15
, 'NP' STRUSERFIELD16
, '' STRUSERFIELD17
, 'N' STRUSERFIELD18
, '' STRUSERFIELD19
, '' STRUSERFIELD20
, '' STRUSERFIELD21
, '' STRUSERFIELD22
, '' STRUSERFIELD23
, '' STRUSERFIELD24
, '' STRUSERFIELD25
, 'MIGR' STRUSERFIELD26
, 'NP' STRUSERFIELD27
, '' STRUSERFIELD28
, '' STRUSERFIELD29
, '' STRUSERFIELD30
, '' DATEUSERFIELD1
, '' DATEUSERFIELD2
, '' DATEUSERFIELD3
, '' DATEUSERFIELD4
, '' DATEUSERFIELD5
, 'INFENG' NATIVELANGCODE
, 'MIG' CUST_HLTH
, '' LASTSUBMITTEDDATE
, '' RISK_PROFILE_SCORE
 /* '' RISK_PROFILE_EXPIRY_DATE */
, REPLACE(REPLACE(CONVERT(VARCHAR, t2.Review_Date,106),' ','-'),',','') AS RISK_PROFILE_EXPIRY_DATE
, '' OUTSTANDING_MORTAGE
, replace(replace(t1.Name, '|', ''), '''', '') CORPORATE_NAME
, left(replace(replace(t1.Name, '|', ''), '''', ''),10)  SHORT_NAME
, left(replace(replace(t1.Name, '|', ''), '''', ''),10)  SHORT_NAME_NATIVE
, CASE WHEN isnull(t2.ComRegNum,'')<>'' THEN convert(varchar,ComRegNum) ELSE 'MIG' END AS REGISTRATION_NUMBER
, '' CHANNELSACCESSED
, '' ZIP
, '' BACKENDID
, 'N' DELINQUENCY_FLAG
, 'N' SUSPEND_FLAG
, '' SUSPEND_NOTES
, '' SUSPEND_REASON
,  CASE WHEN t2.ClientStatus ='b'THEN 'Y' ELSE 'N' END BLACKLIST_FLAG
, '' BLACKLIST_NOTES
, '' BLACKLIST_REASON
, '' NEGATIVE_FLAG
, '' NEGATIVE_NOTES
, '' NEGATIVE_REASON
, 'UBSADMIN' DSAID   
, 'MIG' CUSTASSET_CLASSIFICATION
, '' CLASSIFIED_ON
, '' CUST_CREATION_MODE
, '' INCREMENTALDATEUPDATE
, 'INFENG' LANG_CODE
, '' TDS_CUST_ID
, '' OTHERLIMITS
--, '' CORE_INTROD_CUST_ID
, 'R0MIG' CORE_INTROD_CUST_ID
--, t2.IntroducedBy INTROD_NAME
,'R0MIG' AS INTROD_NAME
, '' INTROD_STAT_CODE
, '' ENTITY_STAGE
, '' ENTITY_STEP_STATUS
, t1.eMail EMAIL2
--, t2.Obligor CUST_GRP
--,CASE WHEN t2.Obligor IN (SELECT CODE FROM FINMIG.dbo.RCT WHERE RCT_ID='15') THEN t2.Obligor
--ELSE '' END AS CUST_GRP
,'GRP1' CUST_GRP
, '' CUST_CONST_CODE
, '' CUSTASSET_CLSFTION_CODE
, '' LEGALENTITY_TYPE_CODE
--, isnull(m.StateCode,'MIGR') REGION_CODE
,'MIG' REGION_CODE
, '004' PRIORITY_CODE
--, '999' BUSINESS_TYPE_CODE
,'OTH' BUSINESS_TYPE_CODE
, '999' RELATIONSHIP_TYPE_CODE
,CyCode as CRNCY_CODE
, '' STR1
, '' STR2
, '' STR3
, '' STR4
, '' STR5
, '' STR6
, '' STR7
, '' STR8
, '' STR9
, '' STR10
, '' STR11
, '' STR12
, '' STR13
, '' STR14
, '' STR15
, '000' AMOUNT1
, '' AMOUNT2
, '' AMOUNT3
, '' AMOUNT4
, '' AMOUNT5
, '' INT1
, '' INT2
, '' INT3
, '' INT4
, '' INT5
, '' FLAG1
, '' FLAG2
, '' FLAG3
, '' FLAG4
, '' FLAG5
, '' MLUSERFIELD1
, '' MLUSERFIELD2
, '' MLUSERFIELD3
, '' MLUSERFIELD4
, '' MLUSERFIELD5
, '' MLUSERFIELD6
, '' MLUSERFIELD7
, '' MLUSERFIELD8
, '' MLUSERFIELD9
, '' MLUSERFIELD10
, '' UNIQUEGROUPFLAG
, '01' BANK_ID
, 'N' ZAKAT_DEDUCTION
, '' ASSET_CLASSIFICATION
, 'N' CUSTOMER_LEVEL_PROVISIONING
, 'N' ISLAMIC_BANKING_CUSTOMER
, '' PREFERREDCALENDAR
--, 'C0'+t1.ClientCode IDTYPEC1
,C.cif_id as IDTYPEC1
, '' IDTYPEC2
, '' IDTYPEC3
, '' IDTYPEC4
, '' IDTYPEC5
, '' IDTYPEC6
, '' IDTYPEC7
, '' IDTYPEC8
, '' IDTYPEC9
, '' IDTYPEC10
, '' CORPORATE_NAME_ALT1
, '' SHORT_NAME_ALT1
, '' KEYCONTACT_PERSONNAME_ALT1
, '' PARENT_CIF_ALT1
, '' BOCREATEDBYLOGINID
,case 
	when isnull(t2.KYCUpDate, '') = '' 
	then 'N'
	else 
		case 
			when isnull(t2.KYCUpDate, '') <> ''and t2.KYCUpDate>@MigDate 
			then 'N' 
			else 'Y' 
		end 
end  SUBMITFORKYC

,CASE WHEN t2.Review_Date>@MigDate THEN REPLACE(REPLACE(CONVERT(VARCHAR,t2.Review_Date,106), ' ','-'), ',','') 
		ELSE '' END AS KYC_REVIEWDATE

,CASE 
	WHEN t2.KYCUpDate>@MigDate 
	THEN '' 
	ELSE  REPLACE(REPLACE(CONVERT(VARCHAR,t2.KYCUpDate ,106), ' ','-'), ',','') 
END AS KYC_DATE

, '' RISKRATING
, '' FOREIGNACCTAXREPORTINGREQ
, '' FOREIGNTAXREPORTINGCOUNTRY
, '' FOREIGNTAXREPORTINGSTATUS
, '' LASTFOREIGNTAXREVIEWDATE
, '' NEXTFOREIGNTAXREVIEWDATE
, '' FATCAREMARKS
, '' MLUSERFIELD11
, '' MLUSERFIELD12
, '' MLUSERFIELD13
, '' MLUSERFIELD14
, '' MLUSERFIELD15
, '' MLUSERFIELD16
, '' MLUSERFIELD17
, '' MLUSERFIELD18
, '' MLUSERFIELD19
, '' INT6
, '' INT7
, '' DATE6
, '' DATE7
, '' DATE8
, '' DATE9
, '' DATE10 
FROM #FinalMaster t1 
 JOIN ClientTable t2 ON t1.ClientCode = t2.ClientCode 
 join FINMIG..GEN_CIFID C on C.ClientCode = t1.ClientCode  
left JOIN ObligorTable t5 ON t2.Obligor = t5.Obligor
left join FINMIG.dbo.Mapping m
on substring(ltrim(t2.DistrictCode), patindex('%[^0]%',ltrim(t2.DistrictCode)),10) = m.DistrictCode
where  C.ClientSeg = 'C'
--and C.ClientCode = '00103978'
ORDER BY CORP_KEY


