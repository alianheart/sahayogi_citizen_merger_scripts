--CS007_BookVersion
USE PPIVSahayogiVBL

select
	'CBS' indicator				,
	C.MainCode Ac                ,
	F.ForAcid as foracid,
	ltrim(rtrim(CyDesc)) as acct_crncy_code,
	RIGHT(SPACE(16)+F_SolId+cast(ltrim(rtrim(C.ChequeNo)) as varchar(16)), 16) begin_chq_num          ,
	
	
	--RIGHT(SPACE(16)+CAST(ChequeNo AS VARCHAR(16)),16) begin_chq_num,
	--ltrim(rtrim(C.NoOfPics)) chq_num_of_lvs         ,
	'1' as chq_num_of_lvs,
	--RIGHT(SPACE(4)+CAST(count(ChequeNo) AS VARCHAR(4)),4)chq_num_of_lvs,

	case when CreateOn < (ISNULL(AcOpenDate,(select min(TranDate)
	 from Master m join TransDetail t on t.MainCode = m.MainCode
		where m.MainCode = M.MainCode
group by m.MainCode))) THEN
	ISNULL(REPLACE(REPLACE(CONVERT(VARCHAR,AcOpenDate,105), ' ','-'), ',',''),(select REPLACE(REPLACE(CONVERT(VARCHAR,min(TranDate),105), ' ','-'), ',','')
	 from Master m join TransDetail t on t.MainCode = m.MainCode
		where m.MainCode = M.MainCode
group by m.MainCode)) ELSE REPLACE(REPLACE(CONVERT(VARCHAR,CreateOn,105), ' ','-'), ',','') END as chq_issu_date
	--else REPLACE(REPLACE(CONVERT(VARCHAR,C.CreateOn,105), ' ','-'), ',','') end chq_issu_date	,


		,CASE WHEN CheqStatus = 'V' then 'U'
		 WHEN CheqStatus = 'I' then 'P'
		 WHEN CheqStatus = 'C' THEN 'C'
		 WHEN CheqStatus = 'S' THEN 'U'
		 WHEN CheqStatus = 'Z' THEN 'I'
		 WHEN CheqStatus = 'D' THEN 'D'
		 WHEN CheqStatus = 'R' THEN 'R'
		 END	chq_lvs_stat           ,

--C.CheqStatus As chq_lvs_stat           ,
	'' begin_chq_alpha        ,
	'' dummy 
FROM ChequeInven(NoLock)  C--FINMIG.dbo.ChqBook2 (NoLock) C 
join Master M on  M.MainCode = C.MainCode
join CurrencyTable t3 on M.CyCode =t3.CyCode
join (select ForAcid, MainCode, F_SolId from FINMIG.dbo.ForAcidSBA union all select ForAcid, MainCode, F_SolId from FINMIG.dbo.ForAcidOD) F on F.MainCode = C.MainCode
where 1=1
and IsBlocked <> 'C'
and MoveType = '4'
and M.AcType not in ('19','2E','2F', '1D') --by durga dai,
and CheqStatus in ('V', 'S')
