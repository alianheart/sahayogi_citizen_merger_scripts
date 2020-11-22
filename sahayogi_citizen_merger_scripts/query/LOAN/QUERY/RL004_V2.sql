--RL004 scripting
use PPIVSahayogiVBL
Declare @MigDate date, @v_MigDate nvarchar(15), @IntCalTillDate date
select  @MigDate=Today ,@IntCalTillDate=Today   from ControlTable;
set @v_MigDate=CONVERT(VARCHAR,@MigDate,105)

Declare @BACID nvarchar(15)= '080050101';

--MIGRA_LAA= 080050101

SELECT distinct
'T' AS tran_type
,'BI' AS tran_sub_type
,ForAcid AS foracidt
,ForAcid AS foracid
,CyDesc AS tran_crncy_code
,F_SolId AS sol_id
,RIGHT(SPACE(17)+CAST(ABS(Balance) AS VARCHAR(17)),17) AS flow_amt 
--,RIGHT(SPACE(17)+CAST(-1*Balance AS VARCHAR(17)),17) AS flow_amt
,case when Balance>0 and T_LoanType='LOAN' then 'C'
	  when Balance<0 and T_LoanType ='DEAL' THEN 'C'
	  else 'D' end AS part_tran_type
 -- note:- loan amount>0 then c else D
--	note :- deal amount> 0 then d else 
,'A' AS type_of_dmds
,@v_MigDate AS value_date
,'DISB' as flow_id
--,case when Balance <0 then 'DISB'  else '' end AS flow_id
,@v_MigDate AS dmd_date
,'N' AS last_tran_flg
,'N' AS rl004_013
,'N' AS advance_payment_flg
,'' AS prepayment_type
,'' AS int_coll_on_prepayment_flg
,'Migration upload' AS tran_rmks  -- Need to confirm
,'Migration upload' AS tran_particular
FROM FINMIG.dbo.ForAcidLAA lm
WHERE 1=1
AND round(abs(lm.Balance),2)<>0
and isnull(ForAcid,'')<>''
--and lm.ForAcid = '0140100000112644' --
 
union all

SELECT 
'T' AS tran_type
,'BI' AS tran_sub_type
,ForAcid AS foracidt
,lm.F_SolId+c.CyCode+@BACID as foracid
,lm.CyDesc AS tran_crncy_code
,F_SolId AS sol_id
,RIGHT(SPACE(17)+CAST(ABS(Balance) AS VARCHAR(17)),17) AS flow_amt 
--,RIGHT(SPACE(17)+CAST(-1*Balance AS VARCHAR(17)),17) AS flow_amt
--,case when Balance<0 then 'C' else 'D' end AS part_tran_type 
,case when Balance>0 and T_LoanType='LOAN' then 'D' 
	when Balance<0 and T_LoanType='DEAL' then 'D' 
	else 'C' end AS part_tran_type
,'A' AS type_of_dmds
,@v_MigDate AS value_date
,'' AS flow_id
--,case when Balance>0 then 'DISB'  else '' end AS flow_id
,@v_MigDate AS dmd_date
,'N' AS last_tran_flg
,'N' AS rl004_013
,'N' AS advance_payment_flg
,'' AS prepayment_type
,'' AS int_coll_on_prepayment_flg
,'Migration upload' AS tran_rmks  -- Need to confirm
,'Migration upload' AS tran_particular
FROM FINMIG.dbo.ForAcidLAA lm join CurrencyTable c on lm.CyDesc=c.CyDesc 
WHERE 1=1
--and lm.BranchCode ='991'
AND round(abs(lm.Balance),2)<>0
--and lm.ForAcid = '0010100000015615' 
and isnull(ForAcid,'')<>''
order by foracidt,part_tran_type 



--43072 rows in third migration
