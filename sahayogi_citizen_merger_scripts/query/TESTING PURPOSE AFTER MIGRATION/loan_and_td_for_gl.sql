select * from FINMIG..PRODUCT_MAPPING where ACTYPE in ('2A', '2B')


select case when IntDrAmt< 0 then 0 else 
IntDrAmt end as IntDrAmt,
Balance, BranchCode, AcType, LoanType from FINMIG..TotalLoan 



select sum(Balance) from FINMIG..TotalLoan 


select sum(IntDrAmt) from (
select case when IntDrAmt< 0 then 0 else 
IntDrAmt end as IntDrAmt,
Balance, BranchCode, AcType, LoanType from FINMIG..TotalLoan )b


select 24590833.52+272.08



select 
	AcType,
	BranchCode,
	F_SCHEME_CODE, 
sum(DealAmt_Balance) as Balance, sum(IntAccrued_IntCrAmt) as Int_Cr from FINMIG..ForAcidTD 
group by AcType,BranchCode, F_SCHEME_CODE

select sum(DealAmt_Balance) from FINMIG..ForAcidTD

select sum(IntAccrued_IntCrAmt) from FINMIG..ForAcidTD




