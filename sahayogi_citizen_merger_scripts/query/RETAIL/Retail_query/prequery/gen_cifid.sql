  

drop sequence seq_cif_id;

drop view vw_gen_cifid;

drop table FINMIG..GEN_CIFID;

-- create sequence    --max cifid provided by durga dai --R004606864
use FINMIG
CREATE SEQUENCE seq_cif_id  
     AS INT
     START WITH 004606865 --increament by one to durga dai value
     INCREMENT BY 1
     MINVALUE 004606865
     CACHE 10


-- creating view
use FINMIG
GO
create view vw_gen_cifid as (
select
	distinct 
	t.ClientCode,
	'R' as ClientSeg 
from PPIVSahayogiVBL..Master(NoLock) m join PPIVSahayogiVBL..ClientTable t  on m.ClientCode=t.ClientCode
where IsBlocked<>'C' and AcType<'50' --and AcType not in ('18','4A','49') --OD account staff also considered
		and (t.TypeofClient<>'002' or (isnull(t.TypeofClient, '')=''))
union all
select 
	distinct
	t.ClientCode,
	'C' as ClientSeg 
from PPIVSahayogiVBL..Master(NoLock) m join PPIVSahayogiVBL..ClientTable t  on m.ClientCode=t.ClientCode
where IsBlocked<>'C' and AcType<'50' --and AcType not in ('18','4A','49') --OD account staff also considered
		and t.TypeofClient = '002' 
)

--select * from FINMIG..vw_gen_cifid



-- creating gen_cifid
select 
	 ClientCode as ClientCode,
	ClientSeg + RIGHT(('000'+ CONVERT(VARCHAR, NEXT VALUE FOR seq_cif_id)), 9) as cif_id,
	ClientSeg
	into FINMIG..GEN_CIFID from vw_gen_cifid

/*
(100399 rows affected)

Completion time: 2020-09-08T13:34:17.1008252+05:45
*/

-- duplicate check
select 
	ClientCode,
	count(ClientCode)
from FINMIG..GEN_CIFID
group by ClientCode
having count(ClientCode) >1

-- duplicate check
select 
	cif_id,
	count(cif_id)
from FINMIG..GEN_CIFID
group by cif_id
having count(cif_id) >1

-- checking null
select 
	*
from FINMIG..GEN_CIFID
where isnull(cif_id, '') = '' or isnull(cif_id, '') = '' or isnull(ClientSeg, '') = ''

-- checking length
select cif_id from FINMIG..GEN_CIFID where len(cif_id) <> 10

--check with max cif_id
select * from FINMIG..GEN_CIFID where replace(replace(cif_id, 'R', ''), 'C', '') < 004606865;

-- Corporate count check
select * from FINMIG..GEN_CIFID where ClientSeg = 'C'
--6697

-- Retail count check
select * from FINMIG..GEN_CIFID where ClientSeg = 'R'
--94251

select distinct ClientCode,
count(1) from vw_gen_cifid
group by ClientCode
having count(1) > 1

select * from FINMIG..GEN_CIFID 




























select 
	CONVERT(VARCHAR, NEXT VALUE FOR seq_cif_id) as ClientId
	/*case
		when ClientSeg = 'R'
		then 'R'+ RIGHT(('00'+ CONVERT(VARCHAR, NEXT VALUE FOR seq_cif_id)), 8)
		when ClientSeg = 'C'
		then 'C'+ RIGHT(('00'+ CONVERT(VARCHAR, NEXT VALUE FOR seq_cif_id)), 8)
	end as cif_id*/
from vw_gen_cifid

create view vw_gen_cifid as (
select id, fullname, 'R' as ClientSeg from test where id in ('1', '2')
union all
select id, fullname, 'C' as ClientSeg from test where id in ('3', '4')
)

drop view vw_gen_cifid
