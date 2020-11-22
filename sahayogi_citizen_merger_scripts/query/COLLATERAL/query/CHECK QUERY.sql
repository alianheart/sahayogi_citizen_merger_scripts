select * from FINMIG.dbo.collateral mt
join MortgageCode mc 
on mt.MortgageCode = mc.MortgageCode 
JOIN Master M
on M.MainCode = mt.ReferenceNo
join FINMIG..GEN_CIFID cm
on M.ClientCode = cm.ClientCode
where M.MainCode in (select MainCode from Master where IsBlocked='C'
AND AcType in (select ACTYPE FROM FINMIG..PRODUCT_MAPPING WHERE MODULE='LAA'))
