use PPIVSahayogiVBL
--CS004

--CS004_SBA&OD

select 
ForAcid as foracid,
CyDesc as acct_crncy_code,
F.F_SolId sol_id                            ,
'1' nom_srl_num                       ,
REPLACE(replace(left(t1.Beneficiary,40),'"',''),'€','') as nom_name,
isnull(replace(t2.Address1,'"',''),'MIG') nom_addr1                         ,
ISNULL(replace(t2.Address2,'"',''),'MIG') nom_addr2                         ,
ISNULL(replace(t2.Address3,'"',''),'MIG') nom_addr3                         ,
'MIG' nom_reltn_code ,
'1' nom_reg_num                       ,
--NULL nom_city_code                     ,
isnull(m.CITYCode,'NMIG') AS nom_city_code,
--NULL nom_State_Code                        ,
isnull(m.StateCode,'MIGR') AS State_Code,
'NP' Country_Code                      ,
'977' ZIP_Code                      ,
'' minor_guard_code                  ,
'' nom_date_of_birth                 ,
'N' minor_flg                         ,
--100 nom_pcnt                          ,
RIGHT(SPACE(10)+CAST(100 AS INT),10) nom_pcnt,
'Y' last_nominee_flg                  ,
'' pref_lang_code                    ,
REPLACE(replace(left(t1.Beneficiary,40),'"',''),'€','') AS pref_lang_nom_name                ,
'' Dummy                             ,
(select cif_id from FINMIG.dbo.GEN_CIFID  cm where cm.ClientCode = t1.ClientCode) as CIF_ID
FROM Master t1 join ClientTable t2 on t1.ClientCode = t2.ClientCode
left outer join FINMIG.dbo.Mapping m
on substring(ltrim(t2.DistrictCode), patindex('%[^0]%',ltrim(t2.DistrictCode)),10) =m.DistrictCode
join CurrencyTable t3 on t1.CyCode =  t3.CyCode
join  (select MainCode, ForAcid, F_SolId From FINMIG.dbo.ForAcidSBA UNION all select MainCode, ForAcid, F_SolId from FINMIG.dbo.ForAcidOD) F
on t1.MainCode= F.MainCode
where 1=1
and t1.BranchCode not in('242','243')
AND IsBlocked <> 'C'
--and t1.AcType not in ('4A', '49')
and isnull(t1.Beneficiary,'')<> ''
order by foracid

--172204 rows in 3rd migration

/*
select Nominee as NomineeMainCode, ForAcid as NomineeForAcid, x.MainCode as CustomerMainCode, ForAcid1 as CustomerForAcid from (
select Nominee, l.MainCode, ForAcid as ForAcid1  from LoanMaster l join  FINMIG..ForAcidOD b 
on l.MainCode = b.MainCode
and Nominee <> l.MainCode and isnull(Nominee, '') <> '') x join (select ForAcid, MainCode from FINMIG..ForAcidOD
union all select ForAcid, MainCode from FINMIG..ForAcidSBA union all select ForAcid, MainCode 
from FINMIG..ForAcidTD ) a 
on x.Nominee = a.MainCode
*/

/*
select l.Nominee, l.MainCode from LoanMaster l
join FINMIG..ForAcidOD a on l.MainCode = a.MainCode
where Nominee <> l.MainCode and isnull(Nominee, '') <> ''

select MainCode, ForAcid from FINMIG..ForAcidOD where MainCode = '00304700051242000003'
*/