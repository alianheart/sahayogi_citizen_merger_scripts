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

SELECT DISTINCT
t1.ClientCode
,G.cif_id AS ORGKEY
,G.cif_id AS CIFID
,'CUSTOMER' AS ENTITYTYPE
,'RETAL' AS CUST_TYPE_CODE
,CASE WHEN upper(Gender) = 'M' THEN 'MR.'
WHEN upper(Gender) = 'F' and upper(MaritalStatus) = 'M'  THEN 'MRS.'
WHEN upper(Gender) = 'F' and upper(isnull(MaritalStatus, 'U')) <> 'M' THEN 'MISS.'
else 'MST.'
END AS SALUTATION_CODE -- CamelCase for Column
,case when isnull(isnull(SUBSTRING(t1.Name,1,charindex(' ',t1.Name)),' '),'')<>'' then 
		ltrim(rtrim(isnull(SUBSTRING(t1.Name,1,charindex(' ',t1.Name)),' ')))
		else ltrim(rtrim(t1.Name)) end as CUST_FIRST_NAME
--,(LEFT(t1.Name, CHARINDEX(' ', Name))) as CUST_FIRST_NAME1

,CASE WHEN charindex(' ',replace(replace(replace(replace(replace(replace(ltrim(t1.Name),'"',''),'''',''),'(',''),'/',''),'&',''),')','')) 
> 0 then
	replace(replace(replace(replace(replace(replace(replace(replace(replace(ltrim(RTRIM(t1.Name)),'"',''),'''',''),'(',''),'/',''),'&',''),')',''),'|',''), 
	SUBSTRING(replace(replace(replace(replace(replace(replace(replace(ltrim(RTRIM(t1.Name)),'"',''),'''',''),'(',''),'/',''),'&',''),')',''),'|',''),0,
	charindex(' ',replace(replace(replace(replace(replace(replace(replace(ltrim(RTRIM(t1.Name)),'"',''),'''',''),'(',''),'/',''),'&',''),')',''),'|',''))) , ''),
	reverse(SUBSTRING(reverse(ltrim(rtrim(t1.Name))),0,charindex(' ',reverse(ltrim(rtrim(t1.Name)))))),'') 
	ELSE '' END AS CUST_MIDDLE_NAME


,case when isnull((CASE WHEN charindex(' ',replace(replace(replace(replace(replace(replace(replace(ltrim(RTRIM(t1.Name)),'"',''),'''',''),'(',''),'/',''),'&',''),')',''),'|','')) > 0 
THEN reverse(SUBSTRING(REVERSE(replace(replace(replace(replace(replace(replace(replace(RTRIM(t1.Name),'"',''),'''',''),'(',''),'/',''),'&',''),')',''),'|','')),1,
CHARINDEX(' ',REVERSE(replace(replace(replace(replace(replace(replace(replace(ltrim(RTRIM(t1.Name)),'"',''),'''',''),'(',''),'/',''),'&',''),')',''),'|',''))))) 
	ELSE '.' END),'')='' then '.' 
else (CASE WHEN charindex(' ',replace(replace(replace(replace(replace(replace(replace(replace(ltrim(RTRIM(t1.Name)),'"',''),'''',''),'(',''),'/',''),'&',''),')',''),'|',''),',',' ')) > 0 
THEN reverse(SUBSTRING(REVERSE(replace(replace(replace(replace(replace(replace(replace(replace(RTRIM(t1.Name),'"',''),'''',''),'(',''),'/',''),'&',''),')',''),'|',''),',',' ')),1,
CHARINDEX(' ',REVERSE(replace(replace(replace(replace(replace(replace(replace(replace(ltrim(RTRIM(t1.Name)),'"',''),'''',''),'(',''),'/',''),'&',''),')',''),'|',''),',',' '))))) 
	ELSE '.' END) end AS  CUST_LAST_NAME


,case when isnull(isnull(SUBSTRING(t1.Name,1,charindex(' ',t1.Name)),' '),'')<>'' then 
		ltrim(rtrim(isnull(SUBSTRING(t1.Name,1,charindex(' ',t1.Name)),' ')))
		else ltrim(rtrim(t1.Name)) end as PREFERREDNAME
		 
,left(ltrim(rtrim(case when isnull(isnull(SUBSTRING(ltrim(rtrim(t1.Name)),1,charindex(' ',ltrim(rtrim(t1.Name)))),' '),'')<>'' then 
		ltrim(rtrim(isnull(SUBSTRING(ltrim(rtrim(t1.Name)),1,charindex(' ',ltrim(rtrim(t1.Name)))),' ')))
		else ltrim(rtrim(t1.Name)) end)),10) as SHORT_NAME

,(select CUST_DOB from FINMIG..DateOfBirth as date where date.ClientCode = t1.ClientCode) AS CUST_DOB

,CASE WHEN Gender IN ('M','m') THEN 'M'
WHEN Gender IN ('F','f') THEN 'F'
WHEN Gender='O' THEN 'O'
ELSE 'O' END AS GENDER -- Currently different values for gender

,case 
	when rtrim(ltrim(OccupationList)) = 'AGRICULTURE' then 'AGP'
	when rtrim(ltrim(OccupationList)) = 'BUSINESS' then 'BSM'
	when rtrim(ltrim(OccupationList)) = 'DOCTOR' then 'DR'
	when rtrim(ltrim(OccupationList)) = 'ENGINEER' then 'ENG'
	when rtrim(ltrim(OccupationList)) = 'HOME MAKER' then 'HOW'
	when rtrim(ltrim(OccupationList)) = 'HOUSEWIFE' then 'HOW'
	when rtrim(ltrim(OccupationList)) = 'NEPAL ARMY' then 'ARM'
	when rtrim(ltrim(OccupationList)) = 'NEPAL POLICE' then 'POL'
	when rtrim(ltrim(OccupationList)) like 'OTHER%' then 'OTH'
	when rtrim(ltrim(OccupationList)) = 'PLEASE SPECIFY' then 'OTH'
	when rtrim(ltrim(OccupationList)) = 'PROFESSOR' then 'PROF'
	when rtrim(ltrim(OccupationList)) = 'RETIRED' then 'RET'
	when rtrim(ltrim(OccupationList)) = 'SALARY PERSON' then 'EMP'
	when rtrim(ltrim(OccupationList)) = 'SELF EMPLOYED' then 'SEM'
	when rtrim(ltrim(OccupationList)) = 'SERVICE' then 'SERV'
	when rtrim(ltrim(OccupationList)) = 'STUDENT' then 'STD'
else 'MIG' end AS OCCUPATION_CODE --changed in sahayogi migration


,CASE WHEN t2.CountryCode = '01' THEN 'NP' -- 'NEPALESE'
WHEN t2.CountryCode = '11' THEN 'IN' --'INDIAN'
WHEN t2.CountryCode = '21' THEN 'AS' --'AMERICAN'
WHEN t2.CountryCode = '23' THEN 'AU' --'AUSTRALIAN'
WHEN t2.CountryCode = '24' THEN 'CA' -- 'CANADIAN'
WHEN t2.CountryCode = '25' THEN 'CH' -- 'SWISS'
WHEN t2.CountryCode = '26' THEN  'DE'--'GERMAN'
WHEN t2.CountryCode = '27' THEN 'NL'--'DUTCH'
WHEN t2.CountryCode = '32' THEN 'AT'--'AUSTRIAN'
ELSE 'NP'--'OTHERS'
END AS NATIONALITY

,CASE WHEN Salutation IN ('MR', 'MR.', 'M.R', 'Mr','.MR', 'MR-','MR..','MR./')   THEN 'MR.'
WHEN Salutation IN ('MRS','MRS.','MRS.','MRS.','Mrs')  THEN 'MRS.'
WHEN Salutation IN ('MISS','MISS.','MISS') THEN 'MISS.' 
ELSE 'MR.' END as NATIVELANGTITLE
,t1.Name AS NATIVELANGNAME
,'Y' AS DOCUMENT_RECIEVED

,'N' AS STAFFFLAG


,'' as STAFFEMPLOYEEID
,'UBSADMIN' AS MANAGER  
,CASE when exists (select distinct C.ClientCode
from ClientTable C(NOLOCK), Master  M(NOLOCK), AcCustType A(NOLOCK) 
where C.ClientCode=M.ClientCode and M.BranchCode=A.BranchCode and M.MainCode=A.MainCode and A.CustTypeCode='B' 
and A.MainCode in (select MainCode from AcCustType(NoLock) where CustTypeCode='B')
and C.ClientCode=M.ClientCode 
and C.ClientCategory like 'Indi%'
and A.CustType in ('CB','NB','XB','UB','DB','OB','WC') 
and C.ClientCode=t2.ClientCode) then 'Y' else 'N' end as CUSTOMERNREFLAG

,CASE when exists (select distinct C.ClientCode
from ClientTable C(NOLOCK), Master  M(NOLOCK), AcCustType A(NOLOCK) 
where C.ClientCode=M.ClientCode and M.BranchCode=A.BranchCode and M.MainCode=A.MainCode and A.CustTypeCode='B' 
and A.MainCode in (select MainCode from AcCustType where CustTypeCode='B' )
and C.ClientCode=M.ClientCode 
and A.CustType in ('CB','NB','XB','UB','DB','OB','WC') 
and C.ClientCode=t2.ClientCode) then @v_MigDate else '' end as DATEOFBECOMINGNRE
--,'' AS DATEOFBECOMINGNRE -- MigrationDate
,CASE  when ( (t2.IsMinor ='Y' ) or DateDiff(Year  ,t2.DateOfBirth ,@MigDate) between 0 and  18) THEN 'Y' 
	ELSE 'N' END   CUSTOMERMINOR 
--CASE WHEN DATEDIFF(year, t2.DateOfBirth, GETDATE()) <=16 THEN 'Y' ELSE 'N'
,CASE  when ( (t2.IsMinor ='Y' ) 
		or DateDiff(Year  ,t2.DateOfBirth ,@MigDate) between 0 and  18) THEN G.cif_id
	ELSE '' END
	 AS MINORGAURDIANID
,CASE  when ( (t2.IsMinor ='Y' ) or DateDiff(Year  ,t2.DateOfBirth ,@MigDate) between 0 and  18) THEN 'G' 
	ELSE '' END AS MINOR_GUARD_CODE 
--CASE WHEN DATEPART(year,t2.DateOfBirth) <= 16 THEN REVERSE(SUBSTRING(REVERSE(t1.Name),1,CHARINDEX(' ',REVERSE(t1.Name)))) 
--ELSE '' END
, REVERSE(SUBSTRING(REVERSE(t1.Name),1,CHARINDEX(' ',REVERSE(t1.Name)))) AS MINOR_GUARD_NAME
--,ISNULL(ZoneCode,'MIG') AS REGION
,RIGHT('000'+CAST(ISNULL(ZoneCode,'MIG') AS VARCHAR(3)),3) AS REGION
,F_SolId AS PRIMARY_SERVICE_CENTRE
,ISNULL(REPLACE(REPLACE(CONVERT(VARCHAR,t1.AcOpenDate,106), ' ','-'), ',',''), (select REPLACE(REPLACE(CONVERT(VARCHAR,min(TranDate),106), ' ','-'), ',','')
from Master m join TransDetail t on t.MainCode = m.MainCode
where m.ClientCode = G.ClientCode
group by m.ClientCode)) AS RELATIONSHIPOPENINGDATE

,CASE WHEN ClientStatus='D' THEN 'DCSED'
 ELSE 'ACTVE' END AS STATUS_CODE 
,'' AS CUSTSTATUSCHGDATE
,'' AS HOUSEHOLDID
,'' AS HOUSEHOLDNAME
,CyCode AS CRNCY_CODE_RETAIL
--,isnull(CyCode,'01') as CRNCY_CODE_RETAIL
,CASE WHEN ltrim(upper(Key_Risk_Grade)) like 'H%' THEN 'HIG'
WHEN ltrim(upper(Key_Risk_Grade)) like 'M%' THEN 'MED'
WHEN ltrim(upper(Key_Risk_Grade)) like 'L%' THEN 'LOW'
ELSE 'MIG' END AS RATING_CODE 
--,'MIG' AS RATING_CODE
,'' AS RATINGDATE
,'' AS CUST_PREF_TILL_DATE
,'TDS05' AS TDS_TBL_CODE
,'R0MIG' AS INTRODUCERID --need to confirm
--,case when (isnull(t2.IntroducedBy,'') ='' )then '' else 'MR.' end AS INTRODUCERSALUTATION
,'MR.' AS INTRODUCERSALUTATION
--,t2.IntroducedBy AS INTRODUCERNAME
,'R0MIG' AS INTRODUCERNAME
,'' AS INTRODUCERSTATUSCODE
,'' AS OFFLINE_CUM_DEBIT_LIMIT
,'' AS CUST_TOT_TOD_ALWD_TIMES
,'' AS CUST_COMMU_CODE
,'' AS CARD_HOLDER
,'MIG' AS CUST_HLTH
,'' AS CUST_HLTH_CODE 
/*
,case when exists (select 1 from Master m where m.ClientCode = t1.ClientCode and m.AcType between '80' and '98' ) THEN 'Y'
 ELSE 'N' END AS TFPARTYFLAG
 */
 ,'N' AS TFPARTYFLAG
,F_SolId  AS PRIMARY_SOL_ID 
,'' AS CONSTITUTION_REF_CODE
,'' AS CUST_OTHR_BANK_CODE
,REPLACE(REPLACE(CONVERT(VARCHAR,AcOpenDate,106), ' ','-'), ',','') AS CUST_FIRST_ACCT_DATE 
,'' AS CHRG_LEVEL_CODE
,'' AS CHRG_DR_FORACID
,'' AS CHRG_DR_SOL_ID
,'N' AS CUST_CHRG_HISTORY_FLG
,'N' AS COMBINED_STMT_REQD
,'' AS LOANS_STMT_TYPE
,'' AS TD_STMT_TYPE
,'' AS COMB_STMT_CHRG_CODE
,'C' AS DESPATCH_MODE
,'' AS CS_LAST_PRINTED_DATE
,'' AS CS_NEXT_DUE_DATE
,'N' AS ALLOW_SWEEPS
,'' AS PS_FREQ_TYPE
,'' AS PS_FREQ_WEEK_NUM
,'' AS PS_FREQ_WEEK_DAY
,'' AS PS_FREQ_START_DD
,'' AS PS_FREQ_HLDY_STAT
,'CUSTOMER' AS ENTITY_TYPE
,'' AS LINKEDRETAILCIF
,'N' AS HSHLDUFLAG
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
,'' AS NUMBER6
,'' AS NUMBER5
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
,replace(cif_id, 'R', '') AS CORE_CUST_ID
,'' AS PERSONTYPE
,'INFENG' AS CUST_LANGUAGE --seed dependent value
,'' AS CUST_STAFF_STATUS
,'' AS PHONE
,'' AS EXTENSION
,'' AS FAX
,'' AS FAX_HOME
,'' AS PHONE_HOME
,'' AS PHONE_HOME2
,'' AS PHONE_CELL
,'' AS EMAIL_HOME
,'' AS EMAIL_PALM
,'' AS EMAIL
--,'ALTHE' AS CITY
--,t2.DistrictCode AS CITY
,isnull(m.CITYCode,'NMIG') AS CITY
,'' AS PREFERREDCHANNELID
,'' AS CUSTOMERRELATIONSHIPNO
,'' AS RELATIONSHIPVALUE
,'' AS CATEGORY
,'' AS NUMBEROFPRODUCTS
,'' AS RELATIONSHIPMGRID
,'5' AS RELATIONSHIPCREATEDBYID
,left(t2.WebAddress,50) AS URL
--,t2.ClientStatus AS STATUS
,CASE WHEN ClientStatus='D' THEN 'DCSED'
 ELSE 'ACTVE' END AS STATUS 
,'' AS INDUSTRY
,'' AS PARENTORG
,'' AS COMPETITOR
,'' AS SICCODE
,'' AS CIN
,'' AS DESIGNATION
,'' AS ASSISTANT
,'' AS INTERNALSCORE
,'' AS CREDITBUREAUSCOREVALIDITY
,'' AS CREDITBUREAUSCORE
,'' AS CREDITBUREAUREQUESTDATE
,'' AS CREDITBUREAUDESCRIPTION
,'' AS MAIDENNAMEOFMOTHER
,'' AS ANNUALREVENUE
,'' AS REVENUEUNITS
,'' AS TICKERSYMBOL
,'N' AS AUTOAPPROVAL
,'N' AS FREEZEPRODUCTSALE
,'' AS RELATIONSHIPFIELD1
,'' AS RELATIONSHIPFIELD2
,'' AS RELATIONSHIPFIELD3
,'' AS DELINQUENCYFLG  
,CASE when exists (select distinct C.ClientCode
from ClientTable C(NOLOCK), Master  M(NOLOCK), AcCustType A(NOLOCK) 
where C.ClientCode=M.ClientCode and M.BranchCode=A.BranchCode and M.MainCode=A.MainCode and A.CustTypeCode='B' 
and A.MainCode in (select MainCode from AcCustType(NoLock) where CustTypeCode='B')
and C.ClientCode=M.ClientCode 
and C.ClientCategory like 'Indi%'
and A.CustType in ('CB','NB','XB','UB','DB','OB','WC') 
and C.ClientCode=t2.ClientCode) then 'Y' else 'N' end as CUSTOMERNREFLG

,'' AS COMBINEDSTATEMENTFLG
,'' AS CUSTOMERTRADE
--,CASE WHEN t2.DistrictCode = t2.DistrictCode THEN t2.DistrictCode ELSE '' END AS PLACEOFBIRTH
,isnull(m.CITYCode,'NMIG') AS PLACEOFBIRTH
,CASE WHEN t2.CountryCode = '11' THEN 'IN'
	WHEN t2.CountryCode = '25' THEN 'CH'
	WHEN t2.CountryCode = '30' THEN 'JP'
	WHEN t2.CountryCode = '50' THEN 'AE'
	ELSE 'NP' END AS COUNTRYOFBIRTH
,'' AS PROOFOFAGEFLAG
,'' AS PROOFOFAGEDOCUMENT
,'' AS NAMESUFFIX
,'' AS MAIDENNAME
,'' AS CUSTOMERPROFITABILITY
,'' AS CURRENTCREXPOSURE
,'' AS TOTALCREXPOSURE
,'' AS POTENTIALCRLINE
,'' AS AVAILABLECRLIMIT
,'' AS CREDITSCOREREQUESTEDFLAG
,'' AS CREDITHISTORYREQUESTEDFLAG
,'' as GROUPID
/*,ISNULL(t1.Obligor,'') AS GROUPID*/ --new
--,CASE WHEN t1.Obligor IN (SELECT CODE FROM FINMIG.dbo.RCT WHERE RCT_ID='15') THEN t1.Obligor
--ELSE '' END AS GROUPID
--,'' AS GROUPID
,'' AS FLG1
,'' AS FLG2
,'' AS FLG3
,'' AS ALERT1
,'' AS ALERT2
,'' AS ALERT3
,'' AS RELATIONSHIPOFFER1
,'' AS RELATIONSHIPOFFER2
,'' AS DTDATE1
,'' AS DTDATE2
,'' AS DTDATE3
,'' AS DTDATE4
,'' AS DTDATE5
,'' AS DTDATE6
,'' AS DTDATE7
,'' AS DTDATE8
,'' AS DTDATE9
,000 AS AMOUNT1
,'' AS AMOUNT2
,'' AS AMOUNT3
,'' AS AMOUNT4
,'' AS AMOUNT5
,  t2.DateOfBirth  AS STRFIELD1
, '' STRFIELD2
, '' AS STRFIELD3
,'' AS STRFIELD4
,'' AS STRFIELD5
,'' AS STRFIELD6
,'' AS STRFIELD7
,'' AS STRFIELD8
,'' AS STRFIELD9
,'' AS STRFIELD10
,'' AS STRFIELD11
,'' AS STRFIELD12
,'N' AS STRFIELD13  -- Need to be confirmed
,'' AS STRFIELD14  -- dependent on STRFIELD13
,'' AS STRFIELD15
,'' AS USERFLAG1
,'' AS USERFLAG2
,'' AS USERFLAG3
,'' AS USERFLAG4
,'' AS MLUSERFIELD1
,'' AS MLUSERFIELD2
,'' AS MLUSERFIELD3
,'' AS MLUSERFIELD4
,'' AS MLUSERFIELD5
,'' AS MLUSERFIELD6
,'' AS MLUSERFIELD7
,'' AS MLUSERFIELD8
,'' AS MLUSERFIELD9
,'' AS MLUSERFIELD10
,'' AS MLUSERFIELD11
,'' AS NOTES
,'' AS PRIORITYCODE
,'' AS CREATED_FROM
,'' AS CONSTITUTION_CODE
,'N' AS STRFIELD16 
,'' AS STRFIELD17
,'' AS STRFIELD18
,'' AS STRFIELD19
,'' AS STRFIELD20
,'' AS STRFIELD21
,'' AS STRFIELD22
,'' AS AMOUNT6
,'' AS AMOUNT7
,'' AS AMOUNT8
,'' AS AMOUNT9
,'' AS AMOUNT10
,'' AS AMOUNT11
,'' AS AMOUNT12
,'' AS INTFIELD1
,'' AS INTFIELD2
,'' AS INTFIELD3
,'' AS INTFIELD4
,'' AS INTFIELD5
,'' AS NICK_NAME
,'' AS MOTHER_NAME
,left(replace(t2.FathersName, '`', ''),20) AS FATHER_HUSBAND_NAME
,'' AS PREVIOUS_NAME
,'' AS LEAD_SOURCE
,'' AS RELATIONSHIP_TYPE
,'' AS RM_GROUP_ID
,'' AS RELATIONSHIP_LEVEL
,'' AS DSA_ID
,'' AS PHOTOGRAPH_ID
,'' AS SECURE_ID
,'' AS DELIQUENCYPERIOD
,'' AS ADDNAME1
,'' AS ADDNAME2
,'' AS ADDNAME3
,'' AS ADDNAME4
,'' AS ADDNAME5
,REPLACE(REPLACE(CONVERT(VARCHAR,GETDATE(),106), ' ','-'), ',','') AS OLDENTITYCREATEDON
,'' AS OLDENTITYTYPE
,'' AS OLDENTITYID
,'' AS DOCUMENT_RECEIVED
,'' AS SUSPEND_NOTES
,'' AS SUSPEND_REASON
,'' AS BLACKLIST_NOTES
,'' AS BLACKLIST_REASON
,'' AS NEGATED_NOTES
,'' AS NEGATED_REASON
,CASE WHEN ltrim(upper(Key_Risk_Grade)) like 'H%' THEN 'HR'
WHEN ltrim(upper(Key_Risk_Grade)) like 'M%' THEN 'MR'
WHEN ltrim(upper(Key_Risk_Grade)) like 'L%' THEN 'LR'
ELSE 'LR' END AS SEGMENTATION_CLASS 
,'' AS NAME
,left(t2.Remarks,60) AS MANAGEROPINION  
,'' AS INTROD_STATUS
,'INFENG' AS NATIVELANGCODE
,CASE  when ( (t2.IsMinor ='Y' ) 
		or DateDiff(Year  ,t2.DateOfBirth ,@MigDate) between 0 and  18) THEN REPLACE(REPLACE(CONVERT(VARCHAR,(DATEADD(YEAR, 18,t2.DateOfBirth)),106), ' ','-'), ',','')  ELSE NULL END AS MINORATTAINMAJORDATE
,'' AS NREBECOMINGORDDATE
,'' AS STARTDATE
,'' AS ADD1_FIRST_NAME
,'' AS ADD1_MIDDLE_NAME
,'' AS ADD1_LAST_NAME
,'' AS ADD2_FIRST_NAME
,'' AS ADD2_MIDDLE_NAME
,'' AS ADD2_LAST_NAME
,'' AS ADD3_FIRST_NAME
,'' AS ADD3_MIDDLE_NAME
,'' AS ADD3_LAST_NAME
,'' AS ADD4_FIRST_NAME
,'' AS ADD4_MIDDLE_NAME
,'' AS ADD4_LAST_NAME
,'' AS ADD5_FIRST_NAME
,'' AS ADD5_MIDDLE_NAME
,'' AS ADD5_LAST_NAME
,'' AS DUAL_FIRST_NAME
,'' AS DUAL_MIDDLE_NAME
,'' AS DUAL_LAST_NAME
,'' AS CUST_COMMUNITY
,'' AS CORE_INTROD_CUST_ID
,'' AS INTROD_SALUTATION_CODE
,'' AS TDS_CUST_ID
,left(t1.CitizenshipNo,16) AS NAT_ID_CARD_NUM
,'' AS PSPRT_ISSUE_DATE
,t2.PassportCountry AS PSPRT_DET
,REPLACE(REPLACE(CONVERT(VARCHAR,t2.PassportExpiryDate,106), ' ','-'), ',','') AS PSPRT_EXP_DATE
,CyCode AS CRNCY_CODE
--,'01' AS CRNCY_CODE
,'' AS PREF_CODE
,'' AS INTROD_STATUS_CODE
,'' AS NATIVELANGTITLE_CODE
,'' AS GROUPID_CODE
,'DEPO' AS SECTOR
,'DEPO' AS SUBSECTOR
,'' AS CUSTCREATIONMODE
,'' AS FIRST_PRODUCT_PROCESSOR
,'' AS INTERFACE_REFERENCE_ID
,'MIG' AS CUST_HEALTH_REF_CODE
,'' AS TDS_CIFID
,'' AS PREF_CODE_RCODE
,'' AS CUST_SWIFT_CODE_DESC
,'' AS IS_SWIFT_CODE_OF_BANK
,'' AS NATIVELANGCODE_CODE
,'' AS CREATEDBYSYSTEMID
,'COMMEML' AS PREFERREDEMAILTYPE
,'CELLPH' AS PREFERREDPHONE
,CASE WHEN isnull(t2.FathersName,'')<>'' THEN t2.FathersName
	ELSE 'MIG' END AS FIRST_NAME_NATIVE
,CASE WHEN isnull(t2.GFathersName,'')<>'' THEN t2.GFathersName
	ELSE 'MIG' END  AS MIDDLE_NAME_NATIVE
,isnull(t2.SpouseName,'') AS LAST_NAME_NATIVE
,'' AS SHORT_NAME_NATIVE

--,--isnull(concat(ltrim(rtrim(Son)),ltrim(rtrim(Daughter))), '') as FIRST_NAME_NATIVE1 --son daughter
,ltrim(rtrim(isnull(Son, ''))) + ' ' + ltrim(rtrim(isnull(Daughter, ''))) as FIRST_NAME_NATIVE1


--Son FIRST_NAME_NATIVE1
,CASE WHEN isnull(GMotherName,'')<>'' THEN t2.GMotherName
else '' end AS MIDDLE_NAME_NATIVE1 --Grandmother name


,isnull(t2.MotherName,'') AS LAST_NAME_NATIVE1
,t1.ClientCode AS SHORT_NAME_NATIVE1 --durga dai and sumesh dai
,'' AS SECONDARYRM_ID
,'' AS TERTIARYRM_ID

,CASE WHEN ltrim(upper(Key_Risk_Grade)) like 'H%' THEN ( case when VIP='T' then 'VIP'
														when NF2F='T' then 'NF2F'
														when PEP='T' then 'PEP'
														when HPP='T' then 'HPP'
														else 'MIG' END)
WHEN ltrim(upper(Key_Risk_Grade)) like 'M%' THEN 'MR'
WHEN ltrim(upper(Key_Risk_Grade)) like 'L%' THEN 'LR'
ELSE 'LR' END AS SUBSEGMENT
--,'MIG' AS SUBSEGMENT
,'' AS ACCESSOWNERGROUP
,'' AS ACCESSOWNERSEGMENT
,'' AS ACCESSOWNERBC
,'' AS ACCESSOWNERAGENT
,'' AS ACCESSASSIGNEEAGENT
,'' AS CHARGELEVELCODE
,'' AS INTUSERFIELD1
,'' AS INTUSERFIELD2
,'' AS INTUSERFIELD3
,'' AS INTUSERFIELD4
,'' AS INTUSERFIELD5
,'' AS STRUSERFIELD1
,'' AS STRUSERFIELD2
,'Y' AS STRUSERFIELD3
,'' AS STRUSERFIELD4
,'' AS STRUSERFIELD5
,'' AS STRUSERFIELD6
,'' AS STRUSERFIELD7
,'' AS STRUSERFIELD8
,'' AS STRUSERFIELD9
,'' AS STRUSERFIELD10
,'' AS STRUSERFIELD11
,'' AS STRUSERFIELD12
,'' AS STRUSERFIELD13
,'' AS STRUSERFIELD14
,'' AS STRUSERFIELD15
,'' AS STRUSERFIELD16
,'' AS STRUSERFIELD17
,'' AS STRUSERFIELD18
,'' AS STRUSERFIELD19
,'' AS STRUSERFIELD20
,'' AS STRUSERFIELD21
,'' AS STRUSERFIELD22
,'' AS STRUSERFIELD23
,'' AS STRUSERFIELD24
,case when t2.PEP='T' then 'Y' else 'N' end AS STRUSERFIELD25 
,'' AS STRUSERFIELD26
,'' AS STRUSERFIELD27
,'' AS STRUSERFIELD28
,'' AS STRUSERFIELD29
,'' AS STRUSERFIELD30
,'' AS DATEUSERFIELD1
,'' AS DATEUSERFIELD2
,'' AS DATEUSERFIELD3
,'' AS DATEUSERFIELD4
,'' AS DATEUSERFIELD5
,'' AS BACKENDID
,'' AS RISK_PROFILE_SCORE
,'' AS RISK_PROFILE_EXPIRY_DATE
,'CELLPH' AS PREFERREDPHONETYPE
,t1.eMail AS PREFERREDEMAIL
,'' AS NOOFCREDITCARDS
,'' AS REASONFORMOVINGOUT
,'' AS COMPETITORPRODUCTID
,'' AS OCCUPATIONTYPE
,'01' AS BANK_ID
,'' AS ZAKAT_DEDUCTION
,'N' AS ASSET_CLASSIFICATION
,'' AS CUSTOMER_LEVEL_PROVISIONING
,'N' AS ISLAMIC_BANKING_CUSTOMER
,'GREGORIAN' AS PREFERREDCALENDAR
,'' AS IDTYPER1
,'' AS IDTYPER2
,'' AS IDTYPER3
,'' AS IDTYPER4
,'' AS IDTYPER5
,'' AS CUST_LAST_NAME_ALT1
,'' AS CUST_FIRST_NAME_ALT1
,'' AS CUST_MIDDLE_NAME_ALT1
,'' AS STRFIELD6_ALT1
,'' AS NAME_ALT1
,'' AS SHORT_NAME_ALT1
,ISEBANKINGENABLED AS ISEBANKINGENABLED
,'N' AS PURGEFLAG
,CASE WHEN t2.ClientStatus = 'Z' THEN 'Y' ELSE 'N' END AS SUSPENDED
,CASE WHEN t2.ClientStatus = 'b' THEN 'Y' ELSE 'N' END AS BLACKLISTED
--'' AS BLACKLISTED -- Condition for Black list
,'' AS NEGATED
,'' AS ACCOUNTID
,replace(t2.Address1, '|', '') AS ADDRESS_LINE1
,t2.Address2 AS ADDRESS_LINE2
,t2.Address3 AS ADDRESS_LINE3
,isnull(m.StateCode,'MIGR') AS STATE
,CASE WHEN t2.CountryCode = '11' THEN 'IN'
	WHEN t2.CountryCode = '25' THEN 'CH'
	WHEN t2.CountryCode = '30' THEN 'JP'
	WHEN t2.CountryCode = '50' THEN 'AE'
	ELSE 'NP' END AS COUNTRY
/*,CASE WHEN t2.CountryCode ='NP' THEN '01' 
	WHEN t2.CountryCode='' then '01' ELSE t2.CountryCode END AS COUNTRY
,t2.CountryCode AS COUNTRY
*/
,'' AS ZIP
--,'UBSADMIN' AS BOCREATEDBYLOGINID
,'' as BOCREATEDBYLOGINID

,case when isnull(t2.KYCUpDate, '') = '' then 'N'
	else case when isnull(t2.KYCUpDate, '') <> ''and t2.KYCUpDate>@MigDate then 'N' else 'Y' end end AS SUBMITFORKYC ----changed in sahayogi migration

,CASE WHEN t2.Review_Date>@MigDate THEN REPLACE(REPLACE(CONVERT(VARCHAR,t2.Review_Date,106), ' ','-'), ',','') 
		ELSE '' END AS KYC_REVIEWDATE

,CASE WHEN t2.KYCUpDate>@MigDate THEN '' 
	  ELSE  REPLACE(REPLACE(CONVERT(VARCHAR,t2.KYCUpDate ,106), ' ','-'), ',','') END AS KYC_DATE  --changed in sahayogi migration

,CASE WHEN ltrim(upper(Key_Risk_Grade)) like 'H%' THEN 'HIGH' --AS PER DURGA DAI'S MAIL 2018-12-12
	WHEN ltrim(upper(Key_Risk_Grade)) like 'M%' THEN 'MODERATE'
	WHEN ltrim(upper(Key_Risk_Grade)) like 'L%' THEN 'LOW'
	ELSE 'MIG' END AS RISKRATING
,CASE WHEN t1.AcType = '1E' THEN 'Y'
WHEN DateDiff(Year  ,t2.DateOfBirth ,@MigDate) >= 55 THEN 'Y' ELSE 'N' END AS SENIORCITIZEN
,REPLACE(REPLACE(CONVERT(VARCHAR,DATEADD(Year, 55, t2.DateOfBirth),106), ' ','-'), ',','')  AS SENCITIZENAPPLICABLEDATE
,'' AS SENCITIZENCONVERSIONFLAG
,'' AS FOREIGNACCTAXREPORTINGREQ
,'' AS FOREIGNTAXREPORTINGCOUNTRY
,'' AS FOREIGNTAXREPORTINGSTATUS
,'' AS LASTFOREIGNTAXREVIEWDATE
,'' AS NEXTFOREIGNTAXREVIEWDATE
,'' AS FATCAREMARKS
,'' AS DATEOFDEATH

/*
,CASE WHEN ClientStatus='D' THEN @MigDate
 ELSE '' END AS DATEOFDEATH 
 */
/*
,CASE WHEN ClientStatus='D' THEN @MigDate
 ELSE '' END AS DATEOFNOTIFICATION
*/
,'' AS DATEOFNOTIFICATION

,'' AS PHYSICAL_STATE
,'' AS UNIQUEIDNUMBER
FROM #FinalMaster t1 join ClientTable t2
join FINMIG..GEN_CIFID G on G.ClientCode = t2.ClientCode
ON t1.ClientCode = t2.ClientCode
left join FINMIG.dbo.Mapping m --need to edit
on substring(ltrim(t2.DistrictCode), patindex('%[^0]%',ltrim(t2.DistrictCode)),10) = m.DistrictCode
where G.ClientSeg = 'R' --and t1.ClientCode = '00046098'
--and G.cif_id = 'R004616760'
order by ORGKEY