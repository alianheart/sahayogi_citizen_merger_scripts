use PPIVSahayogiVBL
Declare @MigDate date, @v_MigDate nvarchar(15)
set @MigDate =(select Today from ControlTable);
set @v_MigDate=REPLACE(REPLACE(CONVERT(VARCHAR,@MigDate,106), ' ','-'), ',','')

IF OBJECT_ID('tempdb.dbo.#FinalMaster', 'U') IS NOT NULL
  DROP TABLE #FinalMaster;

select * INTO #FinalMaster from (
SELECT  DISTINCT
		M.ClientCode
		,G.cif_id
		,AcType
		,BranchCode
		,CASE WHEN ltrim(rtrim(M.Obligor)) IN (SELECT ltrim(rtrim(ObligorCode)) FROM FINMIG.dbo.RCT WHERE RCT_ID='15') THEN 
		 (select CODE FROM FINMIG.dbo.RCT WHERE M.Obligor	=ObligorCode AND RCT_ID='15')
		 ELSE '' END AS Obligor	
		,min(AcOpenDate) AS AcOpenDate
    	,CyDesc as CyCode
    	,case when CitizenshipNo  like '%[0-9]%' then CitizenshipNo 
    		  else case when ClientId like '%[0-9]%' then ClientId
    				else '*****' end
    		  end as CitizenshipNo
		,IsBlocked
		,M.AcOfficer
		,case when FINMIG.dbo.F_IsValidEmail( eMail)=1 then eMail
		else '' end as eMail
,ROW_NUMBER() OVER( PARTITION BY M.ClientCode ORDER BY AcOpenDate,BranchCode,M.Obligor) AS SerialNumber
FROM Master M  join ClientTable t 
on M.ClientCode=t.ClientCode
join FINMIG..GEN_CIFID G on G.ClientCode = t.ClientCode
join CurrencyTable C
on M.CyCode = C.CyCode 
WHERE G.ClientSeg = 'R'
GROUP BY M.ClientCode, AcType, cif_id, BranchCode, M.Obligor, AcOpenDate, MainCode, IsBlocked, M.AcOfficer
,M.CyCode,C.CyDesc,eMail,CitizenshipNo,ClientId

)x
where SerialNumber=1;


SELECT distinct
t1.cif_id AS ORGKEY
, t3.CODE AS GROUPHOUSEHOLDCODE
, '' AS SHAREHOLDING_IN_PERCENTAGE
, '' AS TEXT1
, '' AS TEXT2
, '' AS TEXT3
, '' AS DATE1
, '' AS DATE2
, '' AS DATE3
, '' AS DROPDOWN1
, '' AS DROPDOWN2
, '' AS DROPDOWN3
, '' AS LOOKUP1
, '' AS LOOKUP2
, '' AS LOOKUP3
, replace(replace(t2.Name,'<',''),'>','') AS GROUPHOUSEHOLDNAME
, '01' AS BANK_ID
, t3.CODE AS GROUP_ID
, 'Y' AS PRIMARY_GROUP_INDICATOR
,'' as dummy
from #FinalMaster t1
join ObligorTable t2 on t1.Obligor=t2.Obligor
JOIN FINMIG..RCT t3 on t2.Obligor=t3.ObligorCode where RCT_ID='15' --and cif_id = 'R004589513'

ORDER BY 1;

/*
select distinct t3.CODE AS GROUP_ID , replace(replace(t2.Name,'<',''),'>','') AS GROUPHOUSEHOLDNAME
from #FinalMaster t1
join ObligorTable t2 on t1.Obligor=t2.Obligor
JOIN FINMIG..RCT t3 on t2.Obligor=t3.ObligorCode and RCT_ID='15'
ORDER BY 1
*/