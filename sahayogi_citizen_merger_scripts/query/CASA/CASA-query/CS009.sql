use PPIVSahayogiVBL

Declare @MigDate date, @v_MigDate nvarchar(15)
set @MigDate =(select LastDay from ControlTable);
set @v_MigDate=REPLACE(REPLACE(CONVERT(VARCHAR,@MigDate,105), ' ','-'), ',','')

IF OBJECT_ID('tempdb.dbo.#LeanMaster','U') IS NOT NULL
DROP TABLE #LeanMaster; -- Drops table if exists

SELECT * INTO #LeanMaster FROM
(
select 
HeldAmt as HeldAmt
,isnull(sum(H.Amount),'0') as Amount
,M.MainCode
,ForAcid ,
F.F_SCHEME_CODE
,M.CyCode
,F.F_SolId as F_SolId
from Master M 
left join HoldTable H
on M.MainCode =H.MainCode
join  (select F_SolId, MainCode, ForAcid, F_SCHEME_CODE From FINMIG.dbo.ForAcidSBA 
UNION all select F_SolId, MainCode, ForAcid, F_SCHEME_CODE from FINMIG.dbo.ForAcidOD) F
on M.MainCode= F.MainCode
where HeldAmt<>0 or F.F_SCHEME_CODE in ('CA201', 'NK043')
group by HeldAmt,M.MainCode,ForAcid,M.CyCode,M.BranchCode,F_SCHEME_CODE,F_SolId

) as x


--157880
--select * from #LeanMaster --where HeldAmt<>Amount order by MainCode

select
F.MainCode MainCode					,
ForAcid as foracid,
RIGHT(SPACE(17)+CAST(isnull(F.HeldAmt,'0') AS VARCHAR(17)),17) as lien_amt                   ,
CyDesc as alt_crncy_code ,
'MIG' lien_reason_code           ,
--CreatedOn lien_start_date            ,
@v_MigDate lien_start_date,
'31-12-2099' lien_expiry_date     ,
'ULIEN' b2k_type,
'' b2k_id                     ,
'' si_cert_num                ,
'' limit_prefix               ,
'' limit_sufix                ,
'' dc_ref_num                 ,
'' bg_srl_num                 ,
F_SolId sol_id                     ,
'MIG' lien_remarks               ,
'' IPO_institution_name       ,
'' IPO_application_name
from  #LeanMaster F
 join CurrencyTable T
on F.CyCode =T.CyCode 
WHERE 1=1 and F.HeldAmt <> 0


union all


select
F.MainCode MainCode,
ForAcid as foracid,
case when F.F_SCHEME_CODE = 'CA201' then  RIGHT(SPACE(17)+CAST('1000' AS VARCHAR(17)),17)
	when F.F_SCHEME_CODE = 'NK043' then  RIGHT(SPACE(17)+CAST('25000' AS VARCHAR(17)),17)
	end as lien_amt                   ,
CyDesc as alt_crncy_code ,
'MINBL' lien_reason_code           ,
--CreatedOn lien_start_date            ,
@v_MigDate lien_start_date,
'31-12-2099' lien_expiry_date     ,
'ULIEN' b2k_type                   ,
'' b2k_id                     ,
'' si_cert_num                ,
'' limit_prefix               ,
'' limit_sufix                ,
'' dc_ref_num                 ,
'' bg_srl_num                 ,
F_SolId sol_id                     ,
'MIG' lien_remarks               ,
'' IPO_institution_name       ,
'' IPO_application_name
from  #LeanMaster F
 join CurrencyTable T
on F.CyCode = T.CyCode
WHERE 1=1 and F_SCHEME_CODE in ('CA201', 'NK043')
order by foracid