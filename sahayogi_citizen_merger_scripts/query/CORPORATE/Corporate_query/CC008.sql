--Corporate phone, email and fax Details
USE PPIVSahayogiVBL 

Declare @MigDate date, @v_MigDate nvarchar(15)
set @MigDate =(select Today  from ControlTable); 
set @v_MigDate=REPLACE(REPLACE(CONVERT(VARCHAR,@MigDate,106), ' ','-'), ',','')

IF OBJECT_ID('tempdb.dbo.#FinalMaster','U') IS NOT NULL
DROP TABLE #FinalMaster; -- Drops table if exists

SELECT * INTO #FinalMaster FROM (
	
	SELECT DISTINCT 
	 M.Name
	,M.ClientCode
	,G.cif_id
	,AcType
	,M.IsBlocked
	,M.BranchCode
	,M.Obligor
	,IsDormant
	,M.MainCode
	,CyCode
	--,(select F_SolId from FINMIG..SolMap where BranchCode = M.BranchCode) as solid
	,min(AcOpenDate) AcOpenDate	
	,ROW_NUMBER() OVER( PARTITION BY M.ClientCode ORDER BY AcOpenDate) AS SerialNumber
	FROM Master M with (NOLOCK)
	JOIN ClientTable t2 with (NOLOCK) ON M.ClientCode = t2.ClientCode
	join FINMIG.dbo.GEN_CIFID G with (NOLOCK) on G.ClientCode = t2.ClientCode
where t2.ClientCode in
 (
	Select ClientCode from Master(NoLock) where BranchCode not in ('242','243')
		 and IsBlocked<>'C' and AcType<'50'
) and t2.TypeofClient = '002'
 Group by M.Name,M.ClientCode,G.cif_id,AcType,M.BranchCode,M.Obligor,IsDormant,M.MainCode,CyCode,AcOpenDate,M.IsBlocked
 ) as t
 where t.SerialNumber='1'
 order by 1;
 
 select * from (
SELECT 
ltrim(rtrim(M.cif_id)) AS CORP_KEY
, 'WORKPH1' AS PHONEEMAILTYPE
, 'PHONE' AS PHONEOREMAIL
, left(replace(isnull(Phone,MobileNo), ']', ''),16) AS PHONENOLOCALCODE
, '01' AS PHONENOCITYCODE
, '977' AS PHONENOCOUNTRYCODE
, '' AS WORKEXTENSION
, '' AS EMAIL
, '' AS EMAILPALM
, '' AS URL
, 'Y' AS PREFERREDFLAG
, '' AS START_DATE
, '' AS END_DATE
, 'Mobile No- '+isnull(MobileNo,'')+'/'+'Phon No- '+isnull(Phone,'')+'/'+'Fax No- '+isnull(FaxNo,'') AS USERFIELD1
, '' AS USERFIELD2
, '' AS USERFIELD3
, '' AS DATE1
, '' AS DATE2
, '' AS DATE3
, '01' AS BANK_ID
, '' TEMP
from ClientTable C 
join #FinalMaster M on M.ClientCode=C.ClientCode
join FINMIG..GEN_CIFID CC on CC.ClientCode=C.ClientCode
where isnull(isnull(C.Phone,MobileNo) ,'')<>''
AND CC.ClientSeg = 'C'

UNION ALL

SELECT 
ltrim(rtrim(M.cif_id)) AS CORP_KEY
, 'COMMEML' AS PHONEEMAILTYPE
, 'EMAIL' AS PHONEOREMAIL
, '' AS PHONENOLOCALCODE
, '' AS PHONENOCITYCODE
, '' AS PHONENOCOUNTRYCODE
, '' AS WORKEXTENSION
,case when FINMIG.dbo.F_IsValidEmail( eMail)=1 then eMail
		else 'migration@migration.com' end AS EMAIL
, '' AS EMAILPALM
--, isnull(replace(replace(C.WebsiteAddress,'"',''),'|',''),'') AS URL
,'' AS URL
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
, '' TEMP
from ClientTable C 
join #FinalMaster M on M.ClientCode=C.ClientCode
join FINMIG..GEN_CIFID CC on CC.ClientCode=C.ClientCode
where 
 CC.ClientSeg = 'C'
and (ltrim(rtrim(eMail)) like '%_@__%.__%' and isnull(ltrim(rtrim(eMail)),'')<>'')
)s --where CORP_KEY = 'C004692078'

order by CORP_KEY
