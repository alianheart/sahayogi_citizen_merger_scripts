--CS007_BookVersion
USE PPIVSahayogiVBL

select
	'CBS' indicator				,
	C.MainCode Ac                ,
	F.ForAcid as foracid,
	ltrim(rtrim(CyDesc)) as acct_crncy_code,
	ltrim(rtrim(C.FrmChqNo)) begin_chq_num          ,
	--RIGHT(SPACE(16)+CAST(ChequeNo AS VARCHAR(16)),16) begin_chq_num,
	ltrim(rtrim(C.NoOfPics)) chq_num_of_lvs         ,
	--RIGHT(SPACE(4)+CAST(count(ChequeNo) AS VARCHAR(4)),4)chq_num_of_lvs,
	REPLACE(REPLACE(CONVERT(VARCHAR,C.CreateOn,105), ' ','-'), ',','') chq_issu_date	,
/*
	CASE WHEN CheqStatus = 'V' then 'U'
		 --WHEN CheqStatus = 'I' then 'P'
		 WHEN CheqStatus = 'C' THEN 'C'
		 WHEN CheqStatus = 'S' THEN 'U'
		 WHEN CheqStatus = 'Z' THEN 'I'
		 WHEN CheqStatus = 'D' THEN 'D'
		 WHEN CheqStatus = 'R' THEN 'R'
		 END	chq_lvs_stat           ,
*/
C.ChqPicStatus As chq_lvs_stat           ,
	'' begin_chq_alpha        ,
	'' dummy 
FROM FINMIG.dbo.ChqBook2 (NoLock) C 
join Master M on  M.MainCode = C.MainCode
join CurrencyTable t3 on M.CyCode =t3.CyCode
join (select * from FINMIG.dbo.ForAcidSBA union all select * from FINMIG.dbo.ForAcidOD) F on F.MainCode = C.MainCode
where 1=1
--AND CheqStatus <> 'I'
--AND CheqStatus ='S'
and IsBlocked <> 'C'
and M.AcType not in ('19', '1D', '2F') --by durga dai,
--and F.ForAcid ='0050100000072027'
order by foracid

