use PumoriPlusCTZ1
-- SQL query for RC005

Declare @MigDate date, @v_MigDate nvarchar(15)
set @MigDate =(select Today from ControlTable);
set @v_MigDate=REPLACE(REPLACE(CONVERT(VARCHAR,@MigDate,106), ' ','-'), ',','')

IF OBJECT_ID('tempdb.dbo.#FinalMaster', 'U') IS NOT NULL
  DROP TABLE #FinalMaster;

SELECT  * INTO #FinalMaster FROM 
(SELECT t2.ClientCode
		,min(AcOpenDate) AS AcOpenDate
FROM Master(NOLOCK) t1  join ClientTable(NOLOCK) t2 on t1.ClientCode=t2.ClientCode
WHERE t2.ClientCode NOT IN
( 

		select ClientCode from ClientTable(NoLock) where ClientCode in
		 (
			Select ClientCode from Master(NoLock) where BranchCode not in ('242','243')
				 and IsBlocked<>'C' and AcType<'50'
		)
		and 
		(
		ClientCategory  like 'Com%'
		OR ClientCategory  like 'Partn%'
		OR ClientCategory  like 'Sole%'
		OR ClientCategory like 'Oth%'
		)
)
AND 
t2.ClientCode in
		 (
			Select ClientCode from Master(NoLock) where BranchCode not in ('242','243')
				 and IsBlocked<>'C' and AcType<'50'
		)
GROUP BY t2.ClientCode

)X

--3,28,574 rows

IF OBJECT_ID('tempdb.dbo.#DocDetail', 'U') IS NOT NULL
  DROP TABLE #DocDetail;

select * Into #DocDetail from (
SELECT 
ClientCode
, 'CTZN'  AS DOCCODE
,  'CITIZENSHIP' AS DOCDESCR

/*, case when CitizenshipNo ='' then '-'
	when  CitizenshipNo is null then '***'
	else CitizenshipNo end As REFERENCENUMBER
*/

,case when CitizenshipNo  like '%[0-9]%' then CitizenshipNo 
    		  else case when ClientId like '%[0-9]%' then ClientId
    				else '*****' end
    		  end as REFERENCENUMBER
 , DistrictCode  
 ,Review_Date As DOCRECEIVEDDATE
 , NULL IssueDate
, NULL ExpiryDate
,CountryCode
 From ClientTable(NOLOCK) t2
WHERE-- ClientCategory like 'Ind%' OR ClientCategory like '' 
 exists(select 1 from #FinalMaster t1 where t1.ClientCode = t2.ClientCode)
 
 --319371 rows
 
union all
SELECT 
ClientCode
, 'PP'  AS DOCCODE
,  'PASSPORT' AS DOCDESCR
, PassportNo AS REFERENCENUMBER
 , DistrictCode 
 ,Review_Date As DOCRECEIVEDDATE
 , NULL IssueDate
,PassportExpiryDate  ExpiryDate
,CountryCode
 From ClientTable(NOLOCK)	t2
WHERE --(ClientCategory like 'Ind%' OR ClientCategory like '')
exists(select 1 from #FinalMaster t1 where t1.ClientCode = t2.ClientCode)
 and ISNULL(PassportNo,'')<>''
)y

 -----LOOKUP TABLE
IF OBJECT_ID('FINMIG.dbo.RC005_LOOKUP', 'U') IS NOT NULL
  DROP TABLE FINMIG.dbo.RC005_LOOKUP;
--511 rows
SELECT * INTO FINMIG.dbo.RC005_LOOKUP FROM (
SELECT 
'R0' + t2.ClientCode AS ORGKEY
,'' AS DOCDUEDATE
,REPLACE(REPLACE(CONVERT(VARCHAR,isnull(t2.DOCRECEIVEDDATE,AcOpenDate),106), ' ','-'), ',','') AS DOCRECEIVEDDATE
,'30-Dec-2099' AS DOCEXPIRYDATE
,'N' AS DOCDELFLG
,'' AS DOCREMARKS
,'Y' AS SCANNED
, t2.DOCCODE DOCCODE
,t2.DOCDESCR DOCDESCR
,t2.REFERENCENUMBER REFERENCENUMBER
, t2.DOCDESCR As TYPE
,'N' AS ISMANDATORY
,'N' AS SCANREQUIRED
,'' AS ROLE
,'POI' AS DOCTYPECODE
,DOCDESCR AS DOCTYPEDESCR
,'' AS MINDOCSREQD
,'' AS WAIVEDORDEFEREDDATE
,CASE WHEN t2.CountryCode = '11' THEN 'IN'
	WHEN t2.CountryCode = '25' THEN 'CH'
	WHEN t2.CountryCode = '30' THEN 'JP'
	WHEN t2.CountryCode = '50' THEN 'AE'
	ELSE 'NP' END AS COUNTRYOFISSUE
,isnull(m.CITYCode,'NMIG') AS PLACEOFISSUE
,REPLACE(REPLACE(CONVERT(VARCHAR,t1.AcOpenDate,106), ' ','-'), ',','') AS DOCISSUEDATE
,DOCCODE AS IDENTIFICATIONTYPE
,'' AS CORE_CUST_ID
,'Y' AS IS_DOCUMENT_VERIFIED
,'' AS BEN_OWN_KEY
,'01' AS BANK_ID
,'' AS DOCTYPEDESCR_ALT1
,'' AS DOCDESCR_ALT1
,'Received' AS STATUS
FROM #FinalMaster t1 JOIN #DocDetail t2 ON t1.ClientCode = t2.ClientCode
left join FINMIG.dbo.Mapping(NOLOCK) m
on substring(ltrim(t2.DistrictCode), patindex('%[^0]%',ltrim(t2.DistrictCode)),10) =m.DistrictCode
where LEFT(t2.ClientCode,1) <> '_'
--AND t1.ClientCode ='R0MIG'
)X
ORDER BY ORGKEY


--347422 rows third migration
