USE PPIVSahayogiVBL

select
ForAcid as foracid,
RIGHT(SPACE(17)+CAST(DealAmt AS VARCHAR(17)),17) as lien_amt                   ,
CyDesc as alt_crncy_code ,
 'MIG'lien_reason_code           ,
--CreatedOn lien_start_date            ,
convert(varchar,DealOpenDate,105) lien_start_date,
'31-12-2099' lien_expiry_date     ,
'ULIEN' b2k_type                   ,
'' b2k_id                     ,
'' si_cert_num                ,
'' limit_prefix               ,
'' limit_sufix                ,
'' dc_ref_num                 ,
'' bg_srl_num                 ,
t2.F_SolId sol_id                     ,
CASE WHEN ISNULL(DealRemarks,'')<>'' THEN DealRemarks
	ELSE 'MIGRATION' END AS lien_remarks               ,
'' IPO_institution_name       ,
'' IPO_application_name
from DealTable t1 join 
FINMIG..ForAcidTD t2 on t1.ReferenceNo=t2.ReferenceNo and t1.BranchCode=t2.BranchCode
join CurrencyTable T
on t1.CyCode =T.CyCode
where IsBlockedDeal in ('B','T') and DealAmt<>0 
order by ForAcid

