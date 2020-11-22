--Retail Phone and Email Details
USE PPIVSahayogiVBL

Declare @MigDate date, @v_MigDate nvarchar(15)
set @MigDate = (select dateadd(day,1,Today)  from ControlTable);
set @v_MigDate=REPLACE(REPLACE(CONVERT(VARCHAR,@MigDate,106), ' ','-'), ',','')

IF OBJECT_ID('tempdb.dbo.#FinalMaster', 'U') IS NOT NULL
  DROP TABLE #FinalMaster;

SELECT * INTO #FinalMaster FROM (
	SELECT DISTINCT	
		       M.ClientCode
			  ,M.BranchCode
              ,min(AcOpenDate) AS AcOpenDate
              ,M.MainCode
			  ,ROW_NUMBER() OVER( PARTITION BY M.ClientCode ORDER BY AcOpenDate,M.MainCode) AS SerialNumber
FROM Master M with (NOLOCK) 
join ClientTable t with (NOLOCK) on M.ClientCode=t.ClientCode 
join FINMIG.dbo.SolMap B with (NOLOCK) on B.BranchCode = M.BranchCode

WHERE M.ClientCode 
in
(
Select ClientCode from Master(NoLock) --where BranchCode not in ('242','243')
where IsBlocked<>'C' and AcType<'50'
) 
		and (t.TypeofClient<>'002' or (isnull(t.TypeofClient, '')=''))
GROUP BY M.ClientCode, M.BranchCode, AcOpenDate, M.MainCode)x
where SerialNumber=1
ORDER BY ClientCode;


select  * from (

SELECT DISTINCT
ltrim(rtrim(left(RC.cif_id,10))) AS ORGKEY
, 'REGEML' AS PHONEEMAILTYPE
, 'EMAIL' AS PHONEOREMAIL
, '' AS PHONENO
, '' AS PHONENOLOCALCODE
, '' AS PHONENOCITYCODE
, '' AS PHONENOCOUNTRYCODE
, '' AS WORKEXTENSION
, case when FINMIG.dbo.F_IsValidEmail(eMail)=1 then replace(ltrim(rtrim(eMail)),'|','')
 else 'migration@migration.com' end AS EMAIL
, '' AS EMAILPALM
, '' AS URL
, 'Y' AS PREFERREDFLAG
, '' AS START_DATE
, '' AS END_DATE
, '' AS USERFIELD1
, '' AS USERFIELD2
, '' AS USERFIELD3
, '' AS DATE1
, '' AS DATE2
, '' AS DATE3
, '01' AS BANK_ID
,'' AS TEMP
FROM #FinalMaster M (NOLOCK) 
JOIN ClientTable C (NOLOCK) ON C.ClientCode = M.ClientCode
JOIN FINMIG.dbo.GEN_CIFID RC on RC.ClientCode = C.ClientCode

WHERE RC.ClientSeg = 'R' 
and C.eMail like '%@%'
and (isnull(C.eMail,'')<>'')

UNION ALL

SELECT    DISTINCT                 
ltrim(rtrim(left(RC.cif_id,10))) AS ORGKEY
, 'COMMPH1' AS PHONEEMAILTYPE     
, 'PHONE' AS PHONEOREMAIL
, LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(replace(C.Phone,'.', ''),',','-'),'/',''),'|',''))) AS PHONENO
--, left(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(replace(C.Phone,'.', ''),',','-'),'/',''),'|',''))), 20) AS PHONENOLOCALCODE
,'01' AS PHONENOLOCALCODE
, '01' AS PHONENOCITYCODE
, '977' AS PHONENOCOUNTRYCODE
, '' AS WORKEXTENSION
, '' AS EMAIL
, '' AS EMAILPALM
, '' AS URL
, 'Y' AS PREFERREDFLAG
, '' AS START_DATE
, '' AS END_DATE
,'Mobile No- '+isnull(MobileNo,'')+'/'+' Phone No- '+isnull(Phone,'')+'/'+' Fax No- '+isnull(FaxNo,'') AS USERFIELD1
, '' AS USERFIELD2
, '' AS USERFIELD3
, '' AS DATE1
, '' AS DATE2
, '' AS DATE3
, '01' AS BANK_ID
,'' AS TEMP
FROM #FinalMaster M (NOLOCK) 
JOIN ClientTable C (NOLOCK) ON C.ClientCode = M.ClientCode
JOIN FINMIG.dbo.GEN_CIFID RC on RC.ClientCode = C.ClientCode

WHERE  RC.ClientSeg = 'R'
and (isnull(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(replace(C.Phone,'.', ''),',','-'),'/',''),'|',''))),'')<>'')

UNION

SELECT    DISTINCT                 
ltrim(rtrim(left(RC.cif_id,10))) AS ORGKEY
, 'CELLPH' AS PHONEEMAILTYPE     
, 'PHONE' AS PHONEOREMAIL
, CASE WHEN C.MobileNo IS NOT NULL OR C.MobileNo <> '' THEN  LTRIM(RTRIM(REPLACE(REPLACE(replace(replace(C.MobileNo,'.', ''), ',','-'),'/','-'),'|',''))) END AS PHONENO
--, CASE WHEN C.MobileNo IS NOT NULL OR C.MobileNo <> '' THEN  left(LTRIM(RTRIM(REPLACE(REPLACE(replace(replace(C.MobileNo,'.', ''), ',','-'),'/','-'),'|',''))), 20) END AS PHONENOLOCALCODE
,'01' AS PHONENOLOCALCODE
, '01' AS PHONENOCITYCODE
, '977' AS PHONENOCOUNTRYCODE
, '' AS WORKEXTENSION
, '' AS EMAIL
, '' AS EMAILPALM
, '' AS URL
, 'N' AS PREFERREDFLAG
, '' AS START_DATE
, '' AS END_DATE
,'Mobile No- '+isnull(MobileNo,'')+'/'+' Phone No- '+isnull(Phone,'')+'/'+' Fax No- '+isnull(FaxNo,'') AS USERFIELD1
, '' AS USERFIELD2
, '' AS USERFIELD3
, '' AS DATE1
, '' AS DATE2
, '' AS DATE3
, '01' AS BANK_ID
,'' AS TEMP
FROM #FinalMaster M (NOLOCK) 
JOIN ClientTable C (NOLOCK) ON M.ClientCode = C.ClientCode
JOIN FINMIG.dbo.GEN_CIFID RC on RC.ClientCode = C.ClientCode

WHERE RC.ClientSeg = 'R'
and  (isnull(LTRIM(RTRIM(REPLACE(REPLACE(replace(replace(C.MobileNo,'.', ''), ',','-'),'/','-'),'|',''))),'')<>'')
and isnull(C.MobileNo,'') not like ('N%')
)x
order by ORGKEY;

