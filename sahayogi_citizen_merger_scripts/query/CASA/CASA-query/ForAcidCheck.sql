--select
select * from FINMIG..ForAcidOD

--null check
select * from FINMIG..ForAcidOD
where isnull(MainCode, '') = '' or isnull(ForAcid, '') = ''
--or isnull(F_SolId, '') = '' or isnull(CyCode, '') = ''
or isnull(F_SCHEME_CODE, '') = ''

--duplicate check
select MainCode, count(MainCode)
from FINMIG..ForAcidOD
group by MainCode
having count(MainCode) >1

select ForAcid, count(ForAcid)
from FINMIG..ForAcidOD
group by ForAcid
having count(ForAcid) > 1

--length check
select * from FINMIG..ForAcidOD 
where len(ForAcid) <> 16

select * from BranchTable

select * from FINMIG..ForAcidSBA  where MainCode in ( select MainCode from FINMIG..ForAcidOD)

select * from FINMIG..ForAcidOD  where ForAcid in ( select ForAcid from FINMIG..ForAcidSBA)

--saving count
select count(*) from FINMIG..ForAcidSBA a join FINMIG..PRODUCT_MAPPING p
on a.AcType = p.ACTYPE where p.MODULE = 'CURRENT'

--current count
select count(*) from FINMIG..ForAcidSBA a join FINMIG..PRODUCT_MAPPING p
on a.AcType = p.ACTYPE where p.MODULE = 'SAVING'

select count(*) from FINMIG..ForAcidOD

