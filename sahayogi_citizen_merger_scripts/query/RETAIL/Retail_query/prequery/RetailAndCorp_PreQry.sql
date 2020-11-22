
IF OBJECT_ID('FINMIG.dbo.ClientMapping', 'U') IS NOT NULL
  DROP TABLE FINMIG.dbo.ClientMapping;

select * into FINMIG.dbo.ClientMapping from(
select *  from (select 
		M.ClientCode
		,'R0'+M.ClientCode OrgKey
		,AcType
		,BranchCode
		,M.Obligor
		,min(AcOpenDate) AS AcOpenDate
		,MainCode
    	,CyDesc as CyCode
		,IsBlocked
		,M.AcOfficer
		,case when FINMIG.dbo.F_IsValidEmail( eMail)=1 then eMail
			else '' end as eMail
,ROW_NUMBER() OVER( PARTITION BY M.ClientCode ORDER BY AcOpenDate,BranchCode) AS SerialNumber
,'Y' IsRetail
FROM Master M  join ClientTable t 
on M.ClientCode=t.ClientCode
join CurrencyTable C
on M.CyCode = C.CyCode
WHERE M.ClientCode NOT IN
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
M.ClientCode in
		 (
			Select ClientCode from Master(NoLock) where BranchCode not in ('242','243')
				 and IsBlocked<>'C' and AcType<'50'
		) 
GROUP BY M.ClientCode, AcType, BranchCode, M.Obligor, AcOpenDate, MainCode, IsBlocked, M.AcOfficer,M.CyCode,C.CyDesc,eMail
)x
where SerialNumber=1

union all

SELECT *  FROM
(	
	SELECT  
		M.ClientCode
		,'C0'+M.ClientCode OrgKey
		,AcType
		,BranchCode
		,M.Obligor
		,min(AcOpenDate) AS AcOpenDate
		,MainCode
    	,CyDesc as CyCode
		,IsBlocked
		,M.AcOfficer
		,case when FINMIG.dbo.F_IsValidEmail( eMail)=1 then eMail
		else '' end as eMail
,ROW_NUMBER() OVER( PARTITION BY M.ClientCode ORDER BY AcOpenDate) AS SerialNumber,
'F' IsRetail 
	FROM Master M with (NOLOCK)
	JOIN ClientTable t2 ON M.ClientCode = t2.ClientCode
	join CurrencyTable C
	on M.CyCode = C.CyCode
where t2.ClientCode in
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
GROUP BY M.ClientCode, AcType, BranchCode, M.Obligor, AcOpenDate, MainCode, IsBlocked, M.AcOfficer,M.CyCode,C.CyDesc,eMail
) AS t
Where t.SerialNumber = 1 
)t2
