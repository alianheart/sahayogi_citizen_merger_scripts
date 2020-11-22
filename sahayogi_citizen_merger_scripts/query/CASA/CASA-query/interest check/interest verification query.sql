select count(*) as total_count,sum(IntDrAmt) as total_int,AcType from Master where MainCode in 
(select MainCode from FINMIG..ForAcidOD)
group by AcType
order by AcType

