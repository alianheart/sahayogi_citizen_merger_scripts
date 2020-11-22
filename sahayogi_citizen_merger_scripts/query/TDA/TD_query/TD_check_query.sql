select * from FINMIG..TD004_PI_LOOKUP where foracid = '1090100000008121'

select * from FINMIG..ForAcidTD where ForAcid is null

select IsMatured from DealTable
select * from DealTable where MainCode in (
select MainCode from FINMIG..ForAcidTD where ReferenceNo is null)

select * from FINMIG..ForAcidOD where ForAcid = '0960100000025407'

select * from FINMIG..ForAcidTD

--interest check query in dealtable
select IntAccrued from DealTable where IntAccrued <> '0' and IsMatured <> 'T'

--interest check in master
select MainCode ,IntCrAmt from Master where IntCrAmt <> '0' and AcType in (select ACTYPE From FINMIG..PRODUCT_MAPPING where MODULE = 'TERM DEPOSIT') 
and MainCode in( select MainCode from DealTable where IsMatured <> 'T') 

--lien check query
select * from DealTable where IsBlockedDeal in ('B','T')