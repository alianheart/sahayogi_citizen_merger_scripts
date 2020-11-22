use PPIVSahayogiVBL
-- SQL for TD002 master

DECLARE @MigDate DATE, @v_MigDate nvarchar(15),@MTH DATE,@mig_MONTH nvarchar(15),
@QTR DATE, @mig_QTR nvarchar(15), @HYR DATE,@mig_HYR nvarchar(15), @YR DATE, @mig_YR nvarchar(15),@MigDate1 DATE, @v_MigDate1 nvarchar(15)


set @MigDate = (select dateadd(day,1,Today) from ControlTable);
set @v_MigDate=REPLACE(REPLACE(CONVERT(VARCHAR,@MigDate,105), ' ','-'), ',','')

set @MigDate1 = (select Today from ControlTable);
set @v_MigDate1=REPLACE(REPLACE(CONVERT(VARCHAR,@MigDate1,105), ' ','-'), ',','')

set @MTH = (select dateadd(day,1,LastMonthEnd) from ControlTable);
set @mig_MONTH=REPLACE(REPLACE(CONVERT(VARCHAR,@MTH,105), ' ','-'), ',','')

set @QTR = (select dateadd(day,1,LastQtrEnd) from ControlTable);
set @mig_QTR=REPLACE(REPLACE(CONVERT(VARCHAR,@QTR,105), ' ','-'), ',','')

set @HYR = (select dateadd(day,1,LastHalfYrEnd) from ControlTable);
set @mig_HYR=REPLACE(REPLACE(CONVERT(VARCHAR,@HYR,105), ' ','-'), ',','')

set @YR = (select dateadd(day,1,LastYearEnd) from ControlTable);
set @mig_YR=REPLACE(REPLACE(CONVERT(VARCHAR,@YR,105), ' ','-'), ',','')




IF OBJECT_ID('tempdb.dbo.#SBA_OD', 'U') IS NOT NULL
  DROP TABLE #SBA_OD;  
 SELECT * INTO #SBA_OD FROM (select * from FINMIG.dbo.ForAcidSBA UNION  ALL select * from FINMIG.dbo.ForAcidOD)X
  
/*  Master
IF OBJECT_ID('tempdb.dbo.#tempdealmaster', 'U') IS NOT NULL
  DROP TABLE #tempdealmaster;    -- Drop temporary tempdealmaster table if it exists
  
select * INTO #tempdealmaster from (
SELECT  
		case when M.MainCode ='913102102' then '00055581' --by bank
				else M.ClientCode end as ClientCode
		,AcType
		,BranchCode
		,MainCode
		,IntCrRate
		,TaxPercentOnInt
		,Balance
		--,REPLACE(REPLACE(CONVERT(VARCHAR,AcOpenDate,105), ' ','-'), ',','')as AcOpenDate
		,AcOpenDate
		,IntPostFrqCr
		,M.CyCode as CyCode
		,CyDesc as acct_crncy_code
FROM Master M join CurrencyTable C
on M.CyCode =C.CyCode
where AcType in (Select ACTYPE FROM FINMIG.dbo.PRODUCT_MAPPING WHERE MODULE = 'TERM DEPOSIT')
and Balance<>'0'
and IsBlocked<>'C'


)x;
*/


--DEAL TABLE

IF OBJECT_ID('tempdb.dbo.#FinalDealTable', 'U') IS NOT NULL
  DROP TABLE #FinalDealTable;

select * INTO #FinalDealTable from (
SELECT 		   ReferenceNo
			  ,t1.MainCode
			  ,case when t1.MainCode ='913102102' then '00055581'
					when t1.MainCode ='918101002' then '00147389'
					when t1.MainCode ='918101003' then '00147389'
					when t1.MainCode ='918101004' then '00147389' --by bank
					
				else t2.ClientCode end as ClientCode
			  ,t1.BranchCode
			  /*
	          ,case when t1.MainCode='918101003' then '2019-01-15'
					when t1.MainCode='918101002' then '2019-01-15'
					when t1.MainCode='918101004' then '2019-01-15' 
				else DealOpenDate end as DealOpenDate
				*/
				,DealOpenDate as DealOpenDate
	          ,MaturityDate
	          ,IntCalcFrom
	          ,DealAmt
	          ,TaxPercentOnInt
	          ,IntRate
	          ,NomAcInterest
	          ,IsBlockedDeal
	          ,NomAcMature
	          ,IntPostFrqCr
	          ,IsMatured
	          ,TaxPercentOnDeal
	          ,t1.AcType
	          ,CyDesc as acct_crncy_code
	          ,case when t2.IntPostFrqCr = '1' AND isnull(DealOpenDate,AcOpenDate)<@MigDate then DateDiff(DAY,@MigDate,MaturityDate)
				when t2.IntPostFrqCr = '4' AND isnull(DealOpenDate,AcOpenDate)<@MTH then DateDiff(DAY,@MTH,MaturityDate)
				when t2.IntPostFrqCr = '5' AND isnull(DealOpenDate,AcOpenDate)<@QTR then DateDiff(DAY,@QTR,MaturityDate)
				when t2.IntPostFrqCr = '6' AND isnull(DealOpenDate,AcOpenDate)<@HYR then DateDiff(DAY,@HYR,MaturityDate)
				when t2.IntPostFrqCr = '7' AND isnull(DealOpenDate,AcOpenDate)<@YR then DateDiff(DAY,@YR,MaturityDate)
				else DateDiff(DAY,DealOpenDate,MaturityDate)
				end  as MaturityDays
			  --,isnull(DateDiff(DAY,@MigDate,MaturityDate),0) as MaturityDays
FROM DealTable t1 JOIN Master t2
on t1.MainCode = t2.MainCode and t1.BranchCode= t2.BranchCode
join CurrencyTable t3
on t1.CyCode = t3.CyCode
where t1.AcType IN (SELECT ACTYPE FROM FINMIG.dbo.PRODUCT_MAPPING WHERE MODULE ='TERM DEPOSIT')
and IsBlocked<>'C'
AND DealAmt <> 0
and IsMatured <> 'T'

)x


SELECT
RIGHT(SPACE(9)+CAST('' AS VARCHAR(9)),9) AS emp_id
,RIGHT(SPACE(10)+CAST('0' AS VARCHAR(10)),10) AS cust_cr_pref_pcnt
,RIGHT(SPACE(10)+CAST('0' AS VARCHAR(10)),10) AS cust_dr_pref_pcnt
--,RIGHT(SPACE(10)+CAST('0' AS VARCHAR(10)),10) AS id_cr_pref_pcnt
,RIGHT(SPACE(10)+CAST(IntRate AS VARCHAR(10)),10) AS id_cr_pref_pcnt
,RIGHT(SPACE(10)+CAST('0' AS VARCHAR(10)),10) AS id_dr_pref_pcnt
,RIGHT(SPACE(10)+CAST('0' AS VARCHAR(10)),10) AS chnl_cr_pref_pcnt
,RIGHT(SPACE(10)+CAST('0' AS VARCHAR(10)),10) AS chnl_dr_pref_pcnt
,'N' AS pegged_flg
,'' AS peg_frequency_in_months
,'' AS peg_frequency_in_days
,'' AS sulabh_flg
,'N' AS int_accrual_flg
,'R' AS pb_ps_code
,'P' AS wtax_amount_scope_flg
,case when TaxPercentOnDeal ='0' then 'N'
	else 'W' end AS wtax_flg
,'N' AS safe_custody_flg
,RIGHT(SPACE(17)+CAST('0' AS VARCHAR(17)),17) AS cash_excp_amt_lim
,RIGHT(SPACE(17)+CAST('0' AS VARCHAR(17)),17) AS clg_excp_amt_lim
,RIGHT(SPACE(17)+CAST('0' AS VARCHAR(17)),17) AS xfer_excp_amt_lim
,RIGHT(SPACE(17)+CAST('0' AS VARCHAR(17)),17) AS cash_cr_excp_amt_lim
,RIGHT(SPACE(17)+CAST('0' AS VARCHAR(17)),17) AS clg_cr_excp_amt_lim
,RIGHT(SPACE(17)+CAST(DealAmt AS VARCHAR(17)),17) AS xfer_cr_excp_amt_lim

,ForAcid as foracid


,M.acct_crncy_code AS acct_crncy_code   
,t1.F_SolId AS sol_id
, t1.GL_SUBHEAD_CODE as Gl_sub_head_code
 
 ,F_SCHEME_CODE as Schm_code

,(select cif_id from FINMIG.dbo.GEN_CIFID  cm where cm.ClientCode = M.ClientCode) as cif_id
--,'R0'+m.ClientCode AS cif_id
,RIGHT(SPACE(17)+CAST(DealAmt AS VARCHAR(17)),17) AS deposit_amount
,'' AS deposit_period_mths
,'' AS deposit_period_days

,t1.INTEREST_TABLE_CODE as int_tbl_code
 

,'OTH' as mode_of_oper_code --changed in sahayogi migration by durga dai

--,'999' AS mode_of_oper_code		-- available in RRCDM so need to be provided (bank will provide)
,'SVBL' AS acct_locn_code
,'N' AS auto_renewal_flg
,'' AS perd_mths_for_auto_renew
,'' AS perd_days_for_auto_renew
--,REPLACE(REPLACE(CONVERT(VARCHAR,isnull(DealOpenDate,AcOpenDate),105), ' ','-'), ',','') as acct_opn_date

,case when t1.IntPostFrqCr = '1' AND isnull(DealOpenDate,AcOpenDate)<@MigDate then @v_MigDate
	when t1.IntPostFrqCr = '4' AND isnull(DealOpenDate,AcOpenDate)<@MTH then @mig_MONTH
	when t1.IntPostFrqCr = '5' AND isnull(DealOpenDate,AcOpenDate)<@QTR then @mig_QTR
	when t1.IntPostFrqCr = '6' AND isnull(DealOpenDate,AcOpenDate)<@HYR then @mig_HYR
	when t1.IntPostFrqCr = '7' AND isnull(DealOpenDate,AcOpenDate)<@YR then @mig_YR
	else convert(VARCHAR,isnull(DealOpenDate,AcOpenDate),105)
	end acct_opn_date

,case when t1.IntPostFrqCr = '1' AND isnull(DealOpenDate,AcOpenDate)<@MigDate then @v_MigDate
	when t1.IntPostFrqCr = '4' AND isnull(DealOpenDate,AcOpenDate)<@MTH then @mig_MONTH
	when t1.IntPostFrqCr = '5' AND isnull(DealOpenDate,AcOpenDate)<@QTR then @mig_QTR
	when t1.IntPostFrqCr = '6' AND isnull(DealOpenDate,AcOpenDate)<@HYR then @mig_HYR
	when t1.IntPostFrqCr = '7' AND isnull(DealOpenDate,AcOpenDate)<@YR then @mig_YR
	else convert(VARCHAR,isnull(DealOpenDate,AcOpenDate),105)
	end as open_effective_date
--,'' AS open_effective_date --TBD
,'N' AS nominee_print_flg
,'Y' AS printing_flg
,'' AS ledg_num

 ,case when t1.IntPostFrqCr = '1' AND isnull(DealOpenDate,AcOpenDate)<@MigDate then convert(varchar,dateadd(day,-1,@MigDate),105)
	when t1.IntPostFrqCr = '4' AND isnull(DealOpenDate,AcOpenDate)<@MTH then convert(varchar,dateadd(day,-1,@MTH),105)
	when t1.IntPostFrqCr = '5' AND isnull(DealOpenDate,AcOpenDate)<@QTR then convert(varchar,dateadd(day,-1,@QTR),105)
	when t1.IntPostFrqCr = '6' AND isnull(DealOpenDate,AcOpenDate)<@HYR then convert(varchar,dateadd(day,-1,@HYR),105)
	when t1.IntPostFrqCr = '7' AND isnull(DealOpenDate,AcOpenDate)<@YR then convert(varchar,dateadd(day,-1,@YR),105)
	else convert(VARCHAR,isnull(dateadd(day,-1,DealOpenDate),dateadd(day,-1,AcOpenDate)),105)
	end AS interest_calc_upto_date_cr

,case when t1.IntPostFrqCr = '1' AND isnull(DealOpenDate,AcOpenDate)<@MigDate then convert(varchar,dateadd(day,-1,@MigDate),105)
	when t1.IntPostFrqCr = '4' AND isnull(DealOpenDate,AcOpenDate)<@MTH then convert(varchar,dateadd(day,-1,@MTH),105)
	when t1.IntPostFrqCr = '5' AND isnull(DealOpenDate,AcOpenDate)<@QTR then convert(varchar,dateadd(day,-1,@QTR),105)
	when t1.IntPostFrqCr = '6' AND isnull(DealOpenDate,AcOpenDate)<@HYR then convert(varchar,dateadd(day,-1,@HYR),105)
	when t1.IntPostFrqCr = '7' AND isnull(DealOpenDate,AcOpenDate)<@YR then convert(varchar,dateadd(day,-1,@YR),105)
	else convert(VARCHAR,isnull(dateadd(day,-1,DealOpenDate),dateadd(day,-1,AcOpenDate)),105)
	end AS last_interest_run_date_cr


,case when t1.IntPostFrqCr = '1' AND isnull(DealOpenDate,AcOpenDate)<@MigDate then convert(varchar,dateadd(day,-1,@MigDate),105)
	when t1.IntPostFrqCr = '4' AND isnull(DealOpenDate,AcOpenDate)<@MTH then convert(varchar,dateadd(day,-1,@MTH),105)
	when t1.IntPostFrqCr = '5' AND isnull(DealOpenDate,AcOpenDate)<@QTR then convert(varchar,dateadd(day,-1,@QTR),105)
	when t1.IntPostFrqCr = '6' AND isnull(DealOpenDate,AcOpenDate)<@HYR then convert(varchar,dateadd(day,-1,@HYR),105)
	when t1.IntPostFrqCr = '7' AND isnull(DealOpenDate,AcOpenDate)<@YR then convert(varchar,dateadd(day,-1,@YR),105)
	else convert(VARCHAR,isnull(dateadd(day,-1,DealOpenDate),dateadd(day,-1,AcOpenDate)),105)
	end AS last_int_provision_date

,case when t1.IntPostFrqCr = '1' AND isnull(DealOpenDate,AcOpenDate)<@MigDate then @v_MigDate
	when t1.IntPostFrqCr = '4' AND isnull(DealOpenDate,AcOpenDate)<@MTH then @mig_MONTH
	when t1.IntPostFrqCr = '5' AND isnull(DealOpenDate,AcOpenDate)<@QTR then @mig_QTR
	when t1.IntPostFrqCr = '6' AND isnull(DealOpenDate,AcOpenDate)<@HYR then @mig_HYR
	when t1.IntPostFrqCr = '7' AND isnull(DealOpenDate,AcOpenDate)<@YR then @mig_YR
	else convert(VARCHAR,isnull(DealOpenDate,AcOpenDate),105) end AS printed_date
,RIGHT(SPACE(17)+CAST('' AS VARCHAR(17)),17) AS cumulative_int_paid
,RIGHT(SPACE(17)+CAST('' AS VARCHAR(17)),17) AS cumulative_int_credited
,RIGHT(SPACE(17)+CAST(DealAmt AS VARCHAR(17)),17) AS cumulative_instl_paid
,RIGHT(SPACE(17)+CAST(DealAmt AS VARCHAR(17)),17) AS maturity_amount

--,(SELECT isnull(ForAcid,'') from #SBA_OD s WHERE s.MainCode = isnull(M.NomAcInterest,t1.MainCode)) as  int_cr_acid

,case when isnull((SELECT ForAcid from #SBA_OD s WHERE s.MainCode = M.NomAcInterest),'')<>'' then
		 (SELECT ForAcid from #SBA_OD s WHERE s.MainCode = M.NomAcInterest)
		 else case when M.NomAcInterest = '916151000' then t1.F_SolId+'01290150101' --290150501 before(2018-11-18)
				   when M.NomAcInterest = '916152021' then t1.F_SolId+'21290150101' --290150501 before(2018-11-18)
				   when M.NomAcInterest = '922301101' then '99101300160101'       
				   else t1.F_SolId+t1.CyCode+'290150101' end --290150501 before(2018-11-18)
			end	  AS int_cr_acid  
,case when isnull((SELECT ForAcid from #SBA_OD s WHERE s.MainCode = M.NomAcInterest),'')<>'' then M.acct_crncy_code
		 else case when M.NomAcInterest = '916151000' then 'NPR'
				   when M.NomAcInterest = '916152021' then 'USD'
				   else M.acct_crncy_code end
			end op_acct_crncy_code
,t1.F_SolId	 AS op_acct_sol_id			

,'' AS notice_period_mnths
,'' AS notice_period_days
,'' AS notice_date
,'' AS Stamp_Duty_Borne_By_Cust
,RIGHT(SPACE(17)+CAST('0' AS VARCHAR(17)),17) AS Stamp_Duty_Amount
,'' AS stamp_duty_amount_crncy_code
,RIGHT(SPACE(17)+CAST(DealAmt AS VARCHAR(17)),17) AS original_deposit_amount
--,RIGHT(SPACE(8)+CAST(dt.IntRate AS VARCHAR(8)),8) AS abs_rate_of_int
,'' AS abs_rate_of_int
,'N' AS xclude_for_comb_stmt
,'' AS stmt_cust_id

,isnull(REPLACE(REPLACE(CONVERT(VARCHAR,MaturityDate,105), ' ','-'), ',',''),'01-01-2030') AS maturity_date 
,'' AS treasury_rate_pcnt
,'' AS renewal_option
,RIGHT(SPACE(17)+CAST('0' AS VARCHAR(17)),17) AS renewal_amount
,RIGHT(SPACE(17)+CAST('0' AS VARCHAR(17)),17) AS renewal_addnl_amt
,'' AS renewal_addnl_amt_crncy
,'' AS renewal_crncy
,'' AS renewal_master_acct_id
,'' AS Additional_Src_acct_Crncy_Code
,'' AS Additional_acct_Sol_Id
,'' AS renewal_addnl_amt_rate_code
,'' AS renewal_rate_code
,'' AS additional_rate
,'' AS renewal_rate
,'' AS link_oper_account
,RIGHT(SPACE(17)+CAST('0' AS VARCHAR(17)),17) AS outflow_multiple_amt
,case when TaxPercentOnDeal ='0' then ''
	else 'A' end AS wtax_level_flg    -- need to confirm from CAS

, RIGHT(SPACE(8)+CAST(M.TaxPercentOnDeal AS VARCHAR(8)),8)  as wtax_pcnt
,RIGHT(SPACE(17)+CAST('' AS VARCHAR(17)),17) AS wtax_floor_limit

,case when M.ReferenceNo ='F18345782201' then M.ReferenceNo+t1.F_SolId
	  when M.ReferenceNo ='F19538252205' then M.ReferenceNo+t1.F_SolId --changed in 8th mig for SOLID 009
	  when M.ReferenceNo ='F19005862006' then M.ReferenceNo+t1.F_SolId
	  when M.ReferenceNo ='F19005862008' then M.ReferenceNo+t1.F_SolId
	else M.ReferenceNo end AS iban_number


--,M.ReferenceNo AS iban_number
,'' AS ias_code
,'' AS channel_id
,'' AS channel_level_code
,'' AS master_b2k_id
		
,'A'  AS acct_status 
,case when t1.IntPostFrqCr = '1' then @v_MigDate
	when t1.IntPostFrqCr = '4' then @mig_MONTH
	when t1.IntPostFrqCr = '5' then @mig_QTR
	when t1.IntPostFrqCr = '6' then @mig_HYR
	when t1.IntPostFrqCr = '7' then @mig_YR
	else ''	end AS acct_status_date
--,'' AS acct_status_date
,'' AS dummy
,'' AS ps_diff_freq_rel_party_flg
,'' AS swift_diff_freq_rel_party_flg
,RIGHT(SPACE(17)+CAST('0' AS VARCHAR(17)),17) AS fixed_installment_amt
,RIGHT(SPACE(10)+CAST('0' AS VARCHAR(10)),10) AS nrml_installment_pcnt
,'' AS installment_basis
,'' AS max_miss_contrib_allow
--,'N' AS auto_closure_of_irregular_acct
,'' AS auto_closure_of_irregular_acct
,'' AS total_no_of_miss_contrib
,'' AS acct_irregular_status
,'' AS acct_irregular_status_date
,'' AS cumulative_nrml_instl_paid
,'' AS cumulative_initial_dep_paid
,'' AS cumulative_top_up_paid
,'' AS auto_closure_of_zero_bal_mnths
,'' AS auto_closure_of_zero_bal_days
,'' AS last_bonus_run_date
,'' AS last_calc_bonus_amount
,'' AS bonus_upto_date
,'' AS next_bonus_run_date
,'' AS nrml_int_paid_til_lst_bonus
,'' AS bonus_cycle
,'' AS last_calc_bonus_pcnt
,'' AS penalty_amount
,'' AS penalty_charge_event_id
,'' AS cust_address_type
,'' AS cust_phone_type
,'' AS cust_email_type
,'' AS loc_deposit_period_mths
,'' AS loc_deposit_period_days
,'' AS hedged_acct_flg
,'' AS used_for_net_off_flg
,'' AS Maximum_Auto_Renewal_Allowed 
,'Y' AS Close_on_Maturity_Flag
,isnull(REPLACE(REPLACE(CONVERT(VARCHAR,DealOpenDate-1,105), ' ','-'), ',',''),'') AS Last_Purge_Date
--,'' AS Last_Purge_Date 
,'' AS Pay_Preclose_Profit
,'' AS Pay_Maturity_Profit
,'' AS Murabaha_Deposit_Amount
,'' AS Customer_Purchase_ID 
,'' AS Total_Profit_Amount
,'' AS Minimum_Age_not_met_amount 
,'' AS Broken_Period_Profit_paid_Flag
,'' AS Broken_Period_Profit_amount
,'' AS Profit_to_be_recovered
,'' AS Ind_Profit_distributed_upto_Date
,'' AS Ind_next_Profit_distributed_Date
,'' AS Transfer_In_Indicator 
		
,case when isnull((SELECT ForAcid from #SBA_OD s WHERE s.MainCode = M.NomAcMature),'')<>'' then
		 (SELECT ForAcid from #SBA_OD s WHERE s.MainCode = M.NomAcMature)
		 else '' end	  AS Repayment_account_ID
		 		
,'' AS rebate_amount 
,RIGHT(SPACE(20)+CAST('' AS VARCHAR(20)),20) AS branch_office 
,'' AS deferment_period_mnths 
,'' AS continuation_ind 
,'' AS unclaim_status 
,RIGHT(SPACE(10)+CAST('' AS VARCHAR(10)),10)  AS unclaim_status_date 
,RIGHT(SPACE(5)+CAST('' AS VARCHAR(5)),5) AS orig_gl_sub_head_code
 from FINMIG.dbo.ForAcidTD t1 join #FinalDealTable M
on t1.ReferenceNo =M.ReferenceNo and t1.BranchCode= M.BranchCode
WHERE 1=1
--and t1.ForAcid = '1010100000001125'
order by foracid--,cif_id

