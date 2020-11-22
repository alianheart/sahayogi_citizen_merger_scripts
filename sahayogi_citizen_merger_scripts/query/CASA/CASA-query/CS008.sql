use PPIVSahayogiVBL
--CS008
Declare @MigDate date, @v_MigDate nvarchar(15)
set @MigDate =(select Today from ControlTable);


select  
--S.MainCode foracid	
MoveType,
ForAcid as foracid,
RIGHT(SPACE(16)+F_SolId + CAST(ChequeNo AS VARCHAR(16)),16) begin_chq_num         ,
--RequstedDate acpt_date             ,
REPLACE(REPLACE(CONVERT(VARCHAR,@MigDate,105), ' ','-'), ',','') acpt_date,
'' chq_date              ,
--REPLACE(REPLACE(CONVERT(VARCHAR,ChequeDate,105), ' ','-'), ',','') chq_date	,
--RIGHT(SPACE(17)+CAST(ChequeAmt AS VARCHAR(17)),17) chq_amt               ,
'' chq_amt,
--RequestedBy payee_name            ,
'' payee_name,
'1' num_of_lvs,
'' chq_alpha             ,
'' sp_reason_code        , --it should be RRCDM value
RIGHT(SPACE(17)+CAST('' AS VARCHAR(17)),17) acct_bal              ,
CyDesc as acct_crncy_code 
from ChequeInven(NoLock)  S
join Master M
on S.MainCode = M.MainCode
 join CurrencyTable T
on M.CyCode =T.CyCode
join  (select MainCode, ForAcid, F_SolId From FINMIG.dbo.ForAcidSBA UNION all select MainCode, ForAcid, F_SolId from FINMIG.dbo.ForAcidOD) F
on S.MainCode= F.MainCode
and CheqStatus = 'S'
and IsBlocked <> 'C'
and MoveType = '4'
and M.AcType not in ('19', '2E', '2F', '1D')
order by 1


--4710 ROWS IN third MIGRATION