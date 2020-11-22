-- Query for RC006Email
use PPIVSahayogiVBL
SELECT DISTINCT
'R0' + ClientCode AS ORGKEY
,'REGEML' AS PHONEEMAILTYPE
,'EMAIL' AS PHONEOREMAIL
,'' AS PHONENO    -- though mandatory
,'' AS PHONENOLOCALCODE
,'' AS PHONENOCITYCODE
,'' AS PHONENOCOUNTRYCODE
,'' AS WORKEXTENSION
--,CASE WHEN t2.eMail is not null and t2.eMail<>'' THEN replace(t2.eMail,' ','') ELSE 'migration@migration.com' END AS EMAIL
,case when FINMIG.dbo.F_IsValidEmail(eMail)=1 then eMail
		else 'migration@migration.com' end as EMAIL
,'' AS EMAILPALM
,'' AS URL
,'Y' AS PREFERREDFLAG  -- Modified by Deepak from blank to EMAIL
,'' AS START_DATE
,'' AS END_DATE
,'' AS USERFIELD1
,'' AS USERFIELD2
,'' AS USERFIELD3
,'' AS DATE1
,'' AS DATE2
,'' AS DATE3
,'01' AS BANK_ID
FROM FINMIG.dbo.CRM_PHONMOB
where ClientCode in
		 (
			Select ClientCode from Master(NoLock) where BranchCode not in ('242','243')
				and IsBlocked<>'C' and AcType<'50'
				and eMail LIKE '%_@_%_.__%'
				and eMail IS NOT NULL AND eMail NOT LIKE ''
				AND (eMail  NOT LIKE '%/%' and eMail NOT LIKE '%,%' and eMail NOT LIKE '%@@%' and eMail NOT LIKE '&%' 
				and eMail NOT LIKE '%*%' AND eMail NOT LIKE '%..%' AND eMail NOT LIKE '%|%' AND eMail NOT LIKE '%+%'  
				AND eMail NOT LIKE '%(%' AND eMail NOT LIKE '%)%' AND eMail NOT LIKE '%;%' AND eMail NOT LIKE '%:%' 
				AND eMail NOT LIKE '%[%' AND eMail NOT LIKE '%]%' AND eMail NOT LIKE '%{%' AND eMail NOT LIKE '%}%' 
				AND eMail NOT LIKE '%.' AND eMail NOT LIKE '%!%' AND eMail NOT LIKE '%#%' AND eMail NOT LIKE '%`%'
				AND eMail NOT LIKE '%''%' AND eMail like '%@%') 
		)
and OrgKey like 'R%' 
--AND t2.ClientCode='00391773'		
		--select 42865-42935
-- Query for RC006LandLine
--HOMEPH1:CELLPH:COMMEML

--LIKE '%_@_%_.__%' 

UNION ALL

SELECT DISTINCT
'R0' + ClientCode AS ORGKEY
,'COMMPH1' AS PHONEEMAILTYPE
,'PHONE' AS PHONEOREMAIL
--,CASE WHEN t2.Phone not null and t2.Phone <> '' THEN SUBSTRING( t2.Phone,1,25) ELSE '0000' END AS PHONENO
,left(Phone_edit, 25) PHONENO
--,'01' AS PHONENOLOCALCODE
,left(Phone_edit,20) AS PHONENOLOCALCODE
,'01' AS PHONENOCITYCODE
,'977' AS PHONENOCOUNTRYCODE
,'' AS WORKEXTENSION
,'' AS EMAIL
,'' AS EMAILPALM
,'' AS URL
,'N' AS PREFERREDFLAG
,'' AS START_DATE
,'' AS END_DATE
,'Mobile No- '+isnull(MobileNo,'')+'/'+' Phone No- '+isnull(Phone,'')+'/'+' Fax No- '+isnull(FaxNo,'') AS USERFIELD1
,'' AS USERFIELD2
,'' AS USERFIELD3
,'' AS DATE1
,'' AS DATE2
,'' AS DATE3
,'01' AS BANK_ID
FROM FINMIG.dbo.CRM_PHONMOB
where OrgKey like 'R%'
AND ISNULL(Phone,'')<>''
--AND t2.ClientCode='00391773'

-- Query for RC006MPhone
UNION ALL

SELECT DISTINCT
'R0' + ClientCode AS ORGKEY
,'CELLPH' AS PHONEEMAILTYPE
,'PHONE' AS PHONEOREMAIL
--,CASE WHEN t2.MobileNo is not null and t2.MobileNo<>'' THEN substring(t2.MobileNo,1,25) ELSE '0000' END AS PHONENO
,left(MobileNo_edit, 25) as PHONENO

--,'01' AS PHONENOLOCALCODE
,left(MobileNo_edit,20) as  PHONENOLOCALCODE
,'01' AS PHONENOCITYCODE
,'977' AS PHONENOCOUNTRYCODE
,'' AS WORKEXTENSION
,'' AS EMAIL
,'' AS EMAILPALM
,'' AS URL
,'Y' AS PREFERREDFLAG
,'' AS START_DATE
,'' AS END_DATE
,'Mobile No- '+isnull(MobileNo,'')+'/'+' Phone No- '+isnull(Phone,'')+'/'+' Fax No- '+isnull(FaxNo,'') AS USERFIELD1
,'' AS USERFIELD2
,'' AS USERFIELD3
,'' AS DATE1
,'' AS DATE2
,'' AS DATE3
,'01' AS BANK_ID
FROM FINMIG.dbo.CRM_PHONMOB
where OrgKey like 'R%'
 
ORDER BY ORGKEY

