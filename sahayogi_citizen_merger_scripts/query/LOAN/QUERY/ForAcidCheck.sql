--select
select * from FINMIG..ForAcidLAA

--null check
select * from FINMIG..ForAcidLAA
where isnull(MainCode, '') = '' or isnull(ForAcid, '') = ''
or isnull(F_SolId, '') = '' 
or isnull(F_SCHEME_CODE, '') = ''

--duplicate check
select MainCode, count(MainCode)
from FINMIG..ForAcidLAA
group by MainCode
having count(MainCode) >1

select ForAcid, count(ForAcid)
from FINMIG..ForAcidLAA
group by ForAcid
having count(ForAcid) > 1

--length check
select * from FINMIG..ForAcidLAA 
where len(ForAcid) <> 16

select * from BranchTable

select * from FINMIG..ForAcidLAA  where MainCode in ( select MainCode from FINMIG..ForAcidSBA)

select * from FINMIG..ForAcidLAA  where ForAcid in ( select ForAcid from FINMIG..ForAcidOD)

select count(*) from FINMIG..ForAcidLAA