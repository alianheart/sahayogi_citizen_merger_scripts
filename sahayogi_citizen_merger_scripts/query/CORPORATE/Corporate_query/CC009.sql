USE PPIVSahayogiVBL

IF OBJECT_ID('tempdb.dbo.#FinalMaster', 'U') IS NOT NULL
  DROP TABLE #FinalMaster;			-- Drop temporary table if it exists

SELECT * INTO #FinalMaster FROM
(	
	
	SELECT  
	M.ClientCode
	,G.cif_id
	,CASE WHEN ltrim(rtrim(M.Obligor)) IN (SELECT ltrim(rtrim(ObligorCode)) FROM FINMIG.dbo.RCT WHERE RCT_ID='15') THEN 
	(select CODE FROM FINMIG.dbo.RCT WHERE M.Obligor=ObligorCode AND RCT_ID='15')
	ELSE '' END AS Obligor	
	,ROW_NUMBER() OVER( PARTITION BY M.ClientCode ORDER BY AcOpenDate,BranchCode,M.Obligor) AS SerialNumber
	FROM Master M with (NOLOCK)
	JOIN ClientTable t2 ON M.ClientCode = t2.ClientCode
	join FINMIG..GEN_CIFID G on G.ClientCode = M.ClientCode
	join CurrencyTable C
	on M.CyCode = C.CyCode
where G.ClientSeg = 'C' 
and isnull(M.Obligor,'')<>''
) AS t
Where t.SerialNumber = 1 
ORDER BY 1;

SELECT DISTINCT
t1.ClientCode
,t1.cif_id AS CORP_KEY
,'' AS SHAREHOLDING_IN_PERCENTAGE
,'' AS TEXT1
,'' AS TEXT2
,'' AS TEXT3
,'' AS DATE1
,'' AS DATE2
,'' AS DATE3
,'' AS DROPDOWN1
,'' AS DROPDOWN2
,'' AS DROPDOWN3
,'' AS LOOKUP1
,'' AS LOOKUP2
,'' AS LOOKUP3
, replace(replace(t2.Name,'<',''),'>','') AS GROUPHOUSEHOLDNAME
,'01' AS BANK_ID
--,'' AS  GROUP_ID
,t3.CODE AS GROUP_ID
, 'Y' AS PRIMARY_GROUP_INDICATOR --changed in sahayogi migration
,'' dummy
from #FinalMaster t1
join ObligorTable t2 on t1.Obligor=t2.Obligor
JOIN FINMIG..RCT t3 on t1.Obligor=t3.ObligorCode and RCT_ID='15'
ORDER BY CORP_KEY

--3 count