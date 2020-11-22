select AcType,sum(IntDrAmt_IntAccrued) as intsum_master from FINMIG..ForAcidLAA
group by AcType
order by AcType