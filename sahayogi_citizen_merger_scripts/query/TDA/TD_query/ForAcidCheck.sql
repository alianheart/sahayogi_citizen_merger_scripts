--select
select * from FINMIG..ForAcidTD

--null check
select * from FINMIG..ForAcidTD
where isnull(MainCode, '') = '' or isnull(ForAcid, '') = ''
--or isnull(F_SolId, '') = '' or isnull(CyCode, '') = ''
or isnull(F_SCHEME_CODE, '') = ''

--duplicate check
select ReferenceNo, count(ReferenceNo)
from FINMIG..ForAcidTD
group by ReferenceNo
having count(ReferenceNo) >1

select ForAcid, count(ForAcid)
from FINMIG..ForAcidTD
group by ForAcid
having count(ForAcid) > 1

--length check
select * from FINMIG..ForAcidTD
where len(ForAcid) <> 16

select * from BranchTable

select * from FINMIG..ForAcidTD where MainCode in (select MainCode from FINMIG..ForAcidSBA union all 
select MainCode from FINMIG..ForAcidOD)

select * from FINMIG..ForAcidTD where MainCode in (select MainCode from FINMIG..ForAcidOD)

select count(*) from FINMIG..ForAcidTD