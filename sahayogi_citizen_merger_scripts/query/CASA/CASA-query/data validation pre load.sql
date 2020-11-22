
------saving only------------
select sum(GoodBaln) as GoodBalance ,sum(Balance) as Balancce, count(*) as NumberOfCount,CyCode,AcType from   Master where MainCode in (select MainCode from FINMIG..ForAcidSBA
where AcType not in ('01','03')) 
group by CyCode,AcType

select sum(GoodBaln) as GoodBalance , count(*) as NumberOfCount from   Master where MainCode in (select MainCode from FINMIG..ForAcidSBA
where AcType not in ('01','03')) 

--SBA INTEREST CHECK
select * from Master where ISNULL(ROUND(IntCrAmt,2),0)>0 
and AcType in (select ACTYPE from FINMIG..PRODUCT_MAPPING where MODULE in ('SAVING'))

--LIEN CHECK CASA

select HeldAmt, AcType from Master where HeldAmt <> 0
and IsBlocked <> 'C' 
and AcType in (select ACTYPE from FINMIG..PRODUCT_MAPPING where MODULE not IN ('SAVING', 'CURRENT', 'OVERDRAFT'))

------current only------------

select sum(GoodBaln) as Balance ,count(*) as NumberOfCount,CyCode,AcType from   Master 
where MainCode in (select MainCode from FINMIG..ForAcidSBA
where AcType  in ('01','03'))
group by CyCode,AcType

select sum(GoodBaln) as Balance ,count(*) as NumberOfCount from   Master 
where MainCode in (select MainCode from FINMIG..ForAcidSBA
where AcType  in ('01','03'))


------over draft only ----------------
select sum(GoodBaln) as Balance ,sum(IntDrAmt) as interest,count(*) as NumberOfCount,AcType from   Master 
where MainCode in (select MainCode from FINMIG..ForAcidOD)
group by AcType
order by AcType

select 20319402829.3639-20331652664.3639

select MainCode from FINMIG..ForAcidSBA where ForAcid is null

------TD  only ----------------

select sum(DealAmt_Balance) as Balance ,count(*) as NumberOfCount
from FINMIG..ForAcidTD where ForAcid is not null
group by CyCode,AcType




select * from Master where MainCode='00100000500B'


--LOAN

SELECT sum(Balance),count(*),AcType FROM FINMIG..TotalLoan
group by AcType
order by AcType



365672
370127

select * from FINMIG..ForAcidOD where ForAcid is null

SELECT * FROM FINMIG..PRODUCT_MAPPING WHERE MODULE LIKE '%CURRENT%'

SELECT * FROM FINMIG..PRODUCT_MAPPING WHERE ACTYPE ='39'
