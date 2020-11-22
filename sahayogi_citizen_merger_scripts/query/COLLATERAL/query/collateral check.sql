IF OBJECT_ID('tempdb.dbo.#Loan', 'U') IS NOT NULL
  DROP TABLE #Loan;

select * into #Loan from (
select  distinct ForAcid,t1.MainCode
from FINMIG..TotalLoan t1 join FINMIG..ForAcidLAA t2
on t1.MainCode=t2.MainCode
where isnull(Deal_MainCode,'')=''
union all
select  distinct ForAcid as ForAcid,t1.Deal_MainCode as MainCode
from FINMIG..TotalLoan t1 join FINMIG..ForAcidLAA t2
on t1.MainCode=t2.MainCode
where isnull(Deal_MainCode,'')<>''

)x
order by MainCode


select BranchCode,MainCode,AcType,Balance,IntDrAmt,IntCrAmt,Limit  from Master where MainCode in (select ReferenceNo from FINMIG.dbo.collateral mt
where 
 mt.MortgageCode in (select MortgageCode from MortgageCode)
and  mt.ReferenceNo not in (select MainCode from #Loan union all select MainCode from FINMIG..ForAcidOD
union all select MainCode from FINMIG..ForAcidSBA)) 
--and AcType<'80'
--3698--609

select distinct ForAcid,t1.ReferenceNo,InsPolicyNo from FINMIG.dbo.collateral t1
join (select MainCode,ForAcid from #Loan union all select MainCode,ForAcid from FINMIG..ForAcidOD
union all select MainCode,ForAcid from FINMIG..ForAcidSBA) t2
on t1.ReferenceNo =t2.MainCode
join MortgageCode t3 
on t1.MortgageCode = t3.MortgageCode


select ReferenceNo,InsPolicyNo,t1.MortgageCode,AcType,t2.Balance,t2.IntDrAmt,t2.Limit from FINMIG.dbo.collateral t1
join MortgageCode t3 
on t1.MortgageCode = t3.MortgageCode
join Master t2 on t1.ReferenceNo=t2.MainCode
where 
t1.ReferenceNo  in (select MainCode from #Loan union all select MainCode from FINMIG..ForAcidOD
union all select MainCode from FINMIG..ForAcidSBA)

order by 1


select 5391+16468