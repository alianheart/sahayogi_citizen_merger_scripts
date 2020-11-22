use PPIVSahayogiVBL --New query

Declare @MigDate date, @v_MigDate nvarchar(15), @IntCalTillDate date
select  @MigDate=Today ,@IntCalTillDate=LastDay   from ControlTable;
set @v_MigDate=REPLACE(REPLACE(CONVERT(VARCHAR,@MigDate,105), ' ','-'), ',','') 


IF OBJECT_ID('tempdb.dbo.#TotalLoan', 'U') IS NOT NULL
  DROP TABLE #TotalLoan;
 
select * into #TotalLoan  from FINMIG.dbo.TotalLoan;

--check query
/*
SELECT*  FROM FINMIG..TotalLoan
where MaturityDate is null
*/

--select * from #TotalLoan where isnull(Deal_MainCode,'')<>'' and MainCode='P18011773516'

-----------------For Past Due-----------
DECLARE @BranchCode VARCHAR(3)
IF OBJECT_ID('tempdb.dbo.#PastDuedList', 'U') IS NOT NULL
  DROP TABLE #PastDuedList;

select * into #PastDuedList from FINMIG.dbo.PastDue

IF OBJECT_ID('tempdb.dbo.#PastDue', 'U') IS NOT NULL
  DROP TABLE #PastDue; 
 
 select * into #PastDue from 
(
select BranchCode,ReferenceNo
,sum(IntOverDues)  Past_Due_Interest
,sum(IntOnIntOverDues) IntOnInt--IntOnIntOverDues
,sum(IntOnPriOverDues) Penal--IntOnPriOverDues
,sum(PriOverDues) Past_Due_Principal
,min(dmd_date) Due_Date from #PastDuedList 
where 1=1
group by BranchCode,ReferenceNo
)x

 select  
 flaa.ForAcid foracid
 ,flaa.MainCode
,'0'  cust_cr_pref_pcnt
,'0' cust_dr_pref_pcnt
,'0'  id_cr_pref_pcnt

,case 
	when (select INTEREST_TABLE_CODE from FINMIG.dbo.ForAcidLAA f where f.MainCode = la.MainCode) like '%ZERO%' 
	THEN RIGHT(SPACE(10)+CAST(la.IntDrRate AS VARCHAR(10)),10) 
else '' end as id_dr_pref_pcnt
,'V'  repricing_plan
, '' peg_frequency_in_months
, '' peg_frequency_in_days
,'O'  int_route_flg
 ,la.CyDesc as acct_crncy_code
 ,flaa.F_SolId as sol_id
 ,la.GL_SUBHEAD_CODE gl_sub_head_code	-- Get From mapping Table
 ,la.F_SCHEME_CODE schm_code	-- Get From mapping Table
--,la.Nominee cif_id	
,G.cif_id as cif_id
--,m.AcOpenDate acct_opn_date
,CONVERT(VARCHAR(10),la.AcOpenDate,105) as acct_opn_date
,RIGHT(SPACE(17)+CAST(la.Limit AS VARCHAR(17)),17) sanct_lim
,'' ledg_num

,isnull((select Code from FINMIG..Sectorwise pa where pa.MainCode = la.MainCode), 'DEPO')  AS sector_code
	
,ISNULL((select Code from FINMIG..SubSectorWise ss where ss.MainCode = la.MainCode) ,'DEPO') as sub_sector_code
,'MIGRA'  purpose_of_advn

 ,ISNULL((select Code from FINMIG..NatureOfAdvance na where na.MainCode = la.MainCode) ,'MIGR') as nature_of_advn

,'MIG' as free_code_3
,la.MainCode sanct_ref_num
,CONVERT(VARCHAR(10),la.AcOpenDate,105) lim_sanct_date
,'HO' sanct_levl_code
--,MaturityDate lim_exp_date
,case when MaturityDate<la.AcOpenDate or isnull(MaturityDate,'')='' OR  MaturityDate=la.AcOpenDate then @v_MigDate
	else CONVERT(VARCHAR(10),MaturityDate,105) end as lim_exp_date
,'CCO' sanct_auth_code
,CONVERT(VARCHAR(10),la.AcOpenDate,105)loan_paper_date
,ISNULL(Nom.ForAcid,'') as op_acid
,case   when 	ISNULL(Nom.ForAcid,'')<>'' then 
				case when Nom.CyCode  = 11 then 'INR'
				when Nom.CyCode  = 21 then 'USD'
				when Nom.CyCode  = 22 then 'GBP'
				when Nom.CyCode  = 23 then 'AUD'
				when Nom.CyCode  = 24 then 'CAD'
				when Nom.CyCode  = 25 then 'CHF'
				when Nom.CyCode  = 28 then 'SGD'
				when Nom.CyCode  = 30 then 'JPY'
				when Nom.CyCode  = 31 then 'SEK'
				when Nom.CyCode  = 35 then 'DKK'
				when Nom.CyCode  = 36 then 'HKD'
				when Nom.CyCode  = 37 then 'SAR'
				when Nom.CyCode  = 50 then 'AED'
				when Nom.CyCode  = 63 then 'THB' 
				when Nom.CyCode  = 65 then 'EUR'
				else 'NPR'  end
			else '' end	as op_crncy_code
 /*,case  when ISNULL(Nom.ForAcid,'')<>'' then isnull(Nom.BranchCode,'001')
		else '' end  as op_sol_id*/
,case when ISNULL(Nom.ForAcid,'')<>'' then isnull(Nom.F_SolId,'096')
		else '' end  as op_sol_id

/*
 ,case when la.AcType>'43' then 'M'
		else case  when ISNULL(Nom.ForAcid,'')<>'' then 'E' 
			else 'N' end
	end as dmd_satisfy_mthd
*/
,case  when ISNULL(Nom.ForAcid,'')<>'' then 'E' 
			else 'N'
	end as dmd_satisfy_mthd

 ,case  when ISNULL(Nom.ForAcid,'')<>'' then 'Y'
		else 'N' end as lien_on_oper_acct_flg
 ,'' ds_rate_code
 /*
 --, pm.INTEREST_TABLE_CODE int_tbl_code  -- from Mapping table int_tbl_code
 , CASE WHEN la.MainCode in (select MainCode from AcCustType where CustType in ('TA','RA')) then 'LZERO'
		ELSE la.INTEREST_TABLE_CODE END AS int_tbl_code
*/		
,case when la.T_LoanType='DEAL' then 
	case when exists (SELECT MainCode  from AcCustType A where CustType in ('TA','RA') and CustTypeCode in ('R','T') and A.MainCode = la.Deal_MainCode) OR la.CyCode <> '01' OR la.AcType >'43' then 
			case when  la.AcType >'43' then 'TZERO' ELSE 
				case when  la.INTEREST_TABLE_CODE='FORCE' THEN la.INTEREST_TABLE_CODE else
						  case when la.CyCode='21' then 'UZERO' else 'LZERO'	END
			END
			end
		else 
	 la.INTEREST_TABLE_CODE end
	else
		case when exists (SELECT MainCode  from AcCustType A where CustType in ('TA','RA') and CustTypeCode in ('R','T') and A.MainCode = la.MainCode) OR la.CyCode <> '01' OR la.AcType >'43' then 
			case when  la.AcType >'43' then 'TZERO' ELSE 
				case when  la.INTEREST_TABLE_CODE='FORCE' THEN la.INTEREST_TABLE_CODE else
						  case when la.CyCode='21' then 'UZERO' else 'LZERO'	END
				END
				end
		else 
		la.INTEREST_TABLE_CODE end
	  end as int_tbl_code 

, 'Y' int_on_p_flg
, 'N' pi_on_pdmd_ovdu_flg --PREVIOUS 'Y', CHANGE AFTER RAGHUNATH MAIL 2018-10-05
, 'N' pdmd_ovdu_eom_flg
, 'N' int_on_idmd_flg
, 'N' pi_on_idmd_ovdu_flg --PREVIOUS 'Y', CHANGE AFTER RAGHUNATH MAIL 2018-10-05
, 'N' idmd_ovdu_eom_flg
, @v_MigDate xfer_eff_date
,'' AS cum_norm_int_amt
,'' AS cum_pen_int_amt
,'' AS cum_addnl_int_amt
--From #FinalDealTable t1 
,case when isnull(la.IntDrAmt_IntAccrued,0)<0 then RIGHT(SPACE(17)+CAST('0.00' AS VARCHAR(17)),17)
		else  RIGHT(SPACE(17)+CAST(abs(la.Balance)+isnull(la.IntDrAmt_IntAccrued,0)
+isnull((select isnull(IntOnInt,0)+isnull(Penal,0) from #PastDue pde where pde.ReferenceNo = la.MainCode and pde.BranchCode=la.BranchCode),0)
 AS VARCHAR(17)),17) end AS liab_as_on_xfer_eff_date
,RIGHT(SPACE(17)+CAST('0' AS VARCHAR(17)),17) AS rephasement_principal
,CONVERT(VARCHAR(10),@IntCalTillDate,105) AS interest_calc_upto_date_dr

--	,'' AS rep_shdl_date  --NBD
 	,CASE WHEN la.LoanType = 'EMI' THEN  
		(select convert(varchar, ISNULL(max(DueDate),la.AcOpenDate),105)
			 AS emi_date from LoanRepaySched lr 
		 where la.MainCode = lr.MainCode  and DueDate<=@IntCalTillDate)
	ELSE convert(varchar,la.AcOpenDate,105) END AS  rep_shdl_date
	
	--,ISNULL(RIGHT(SPACE(3)+CAST(la.NoOfPeriods AS VARCHAR(3)),3),0) AS rep_perd_mths --TBD
	--,'' rep_perd_mths --need to fix it
	,CASE WHEN MaturityDate<la.AcOpenDate or isnull(MaturityDate,'')='' or MaturityDate=la.AcOpenDate then  cast( datediff(day,la.AcOpenDate,@MigDate)/30 as varchar)
	 else cast(datediff(day,la.AcOpenDate,MaturityDate)/30 as varchar) end as rep_perd_mths
	,CASE WHEN MaturityDate<la.AcOpenDate or isnull(MaturityDate,'')='' or MaturityDate=la.AcOpenDate then  cast (datediff(day,la.AcOpenDate,@MigDate)%30 as varchar) 
	 else cast(datediff(day,la.AcOpenDate,MaturityDate)%30 as varchar) end as rep_perd_days
	--,'' AS rep_perd_days	
	
	/* -------2018-10-30 as per Roman Dai's mail
	
	,CASE WHEN la.MainCode in (select ReferenceNo from #PastDue p where p.ReferenceNo = la.MainCode and la.BranchCode = p.BranchCode)THEN 'Y'
	 ELSE 'N' END AS pd_flg
	,CASE WHEN (select Due_Date from #PastDue p where p.ReferenceNo = la.MainCode and la.BranchCode = p.BranchCode) < la.AcOpenDate THEN @v_MigDate ELSE
	isnull(REPLACE(CONVERT(VARCHAR(10),(select Due_Date from #PastDue p where p.ReferenceNo = la.MainCode and la.BranchCode = p.BranchCode),105),' ','-'),'') END AS pd_xfer_date 
	--,'' AS prv_to_pd_gl_sub_head_code     --TBD
	,CASE WHEN la.MainCode in (select ReferenceNo from #PastDue p where p.ReferenceNo = la.MainCode and la.BranchCode = p.BranchCode) then
		case when la.LoanType = 'EMI' then '34050'
	else '34051' end
	else '' end as prv_to_pd_gl_sub_head_code
	--,RIGHT(SPACE(17)+CAST('0' AS VARCHAR(17)),17) AS int_suspense_amt   -- sepearate table will be provided (optional)
	,CASE WHEN la.MainCode in (select ReferenceNo from #PastDue p where p.ReferenceNo = la.MainCode and la.BranchCode = p.BranchCode)
	then right(space(17)+cast(isnull((select Past_Due_Interest from  #PastDue P where la.MainCode = P.ReferenceNo and la.BranchCode = P.BranchCode),'0')as varchar(17)),17)
	else '' end AS int_suspense_amt 
	--,RIGHT(SPACE(17)+CAST('0' AS VARCHAR(17)),17) AS penal_int_suspense_amt  -- need to confirm (optional)
	,case when la.MainCode in (select ReferenceNo from #PastDue p where p.ReferenceNo = la.MainCode and la.BranchCode = p.BranchCode )THEN
	right(space(17)+cast(isnull((select P.IntOnInt + P.Penal from  #PastDue P where la.MainCode = P.ReferenceNo and la.BranchCode = P.BranchCode),'0')as varchar(17)),17)
	else '' end AS penal_int_suspense_amt  
	*/
    ,'N' AS pd_flg	-------2018-10-30 as per Roman Dai's mail
    ,'' AS pd_xfer_date -------2018-10-30 as per Roman Dai's mail
    ,'' AS prv_to_pd_gl_sub_head_code -------2018-10-30 as per Roman Dai's mail
    ,'' AS int_suspense_amt  -------2018-10-30 as per Roman Dai's mail
    ,'' AS penal_int_suspense_amt  -------2018-10-30 as per Roman Dai's mail
    
	,'N' AS chrge_off_flg
	,'' AS chrge_off_date   
	,RIGHT(SPACE(17)+CAST('0' AS VARCHAR(17)),17) AS chrge_off_principal 
	,RIGHT(SPACE(17)+CAST('0' AS VARCHAR(17)),17) AS pending_interest
	,RIGHT(SPACE(17)+CAST('0' AS VARCHAR(17)),17) AS principal_recovery
	,RIGHT(SPACE(17)+CAST('0' AS VARCHAR(17)),17) AS interest_recovery
	,'' AS source_deal_code
	,'' AS disburse_deal_code
	,'N' AS apply_late_fee_flg
	,'0' AS late_fee_grace_perd_mnths
	,'0' AS late_fee_grace_perd_days
	,'N' AS upfront_instl_coll
	,'' AS num_advance_instlmnt
	,'' AS upfront_instl_amt
	,'' AS dpd_cntr
	--,RIGHT(SPACE(17)+CAST('0' AS VARCHAR(17)),17) AS sum_principal_dmd_amt --PastDuedList.GoodBaln
	,CASE WHEN la.MainCode in (select ReferenceNo from #PastDue p where p.ReferenceNo = la.MainCode and la.BranchCode = p.BranchCode )
	then right(space(17)+cast(isnull((select Past_Due_Principal from #PastDue p where p.ReferenceNo = la.MainCode and la.BranchCode = p.BranchCode),'0') as varchar(17)),17)
	else '' end AS sum_principal_dmd_amt
	,'N' AS payoff_flg
	,'Y' AS xclude_for_comb_stmt
	,'' AS stmt_cif_id
	,'000000000000000000000000000000000000000000000' AS xfer_cycle_str
	,'' AS bank_irr_rate
	,'' AS value_of_asset
	,'MIG' AS acct_occp_code
	,'MIGRA' AS borrower_category_code  -- Need to be confirmed as mapping is seen in the sheet (optional)

,ISNULL((select Code from FINMIG..ModeOfAdvance ma where ma.MainCode = la.MainCode),'NA') AS mode_of_advn

	--,'MIG' AS type_of_advn
	,isnull((select Code from FINMIG..AdvanceType at where at.MainCode = la.MainCode), 'MIG')  as type_of_advn
	,'' AS guar_cover_code
	--,'' AS industry_type
	,ISNULL((select Code from FINMIG..IndustryType id where id.MainCode = la.MainCode),'MIGR') as industry_type    
	,isnull((select Code from FINMIG..Freecode1 fr where fr.MainCode = la.MainCode), '') AS  free_code_1 
--	,'MIG' AS free_code_2  --changed in sahayogi migration

   ,'' as free_code_2
	,'' AS free_code_4
	,'' AS free_code_5
	,'' AS free_code_6
	,'' AS free_code_7
	,'' AS free_code_8
	,'' AS free_code_9
	
	--,case when la.MainCode in (select MainCode from FINMIG..FREECODE10) THEN 'JOINT' ELSE '' END AS free_code_10
	,'' AS  free_code_10
	,'SVBL' AS acct_locn_code
	,'' AS crfile_ref_id
	,'' AS dicgc_fee_pcnt
	,'' AS last_compound_date
	,'' AS daily_comp_int_flg
	,'N' AS calc_ovdu_int_flg   
	,'' ei_perd_start_date
	--,CASE WHEN la.LoanType = 'EMI' THEN 
	--	CONVERT(VARCHAR(10),tl.RepayStartDate,105) 
	-- ELSE '' END AS ei_perd_start_date
	,--REPLACE(CONVERT(VARCHAR,MaturityDate,105), ' ','-') ei_perd_end_date
	CASE WHEN flaa.LoanType = 'EMI' THEN (select REPLACE(CONVERT(VARCHAR,max(DueDate),105), ' ','-') from LoanRepaySched lr 
	where la.MainCode = lr.MainCode /*and DueInterest<>0*/) 
	WHEN MaturityDate < la.AcOpenDate THEN  @v_MigDate
	ELSE isnull(REPLACE(CONVERT(VARCHAR,MaturityDate,105), ' ','-'),@v_MigDate)
    END AS ei_perd_end_date
	,'' AS irr_rate
	,'' AS adv_int_amount
	,'' AS amortized_amount
	,'' AS booked_upto_date_dr
	,'' AS adv_int_coll_upto_date
	,'' AS accrual_rate
	,'' AS int_rate_based_on_sanct_lim
	,'' AS int_rest_freq
	,'' AS int_rest_basis
	,'O' AS chrg_route_flg
--	,case when MoveType = '6' and abs(TotDisburse) = Limit then 'Y'
--		else 'N' end AS final_disb_flg
	,'N'  AS final_disb_flg
	,'N' AS auto_reshdl_after_hldy_perd
	,'' AS tot_num_defmnts
	,'' AS num_defmnt_curr_shdl
	,'31-12-2099' AS peg_review_date
	,'' AS pi_based_on_outstanding --PREVIOUS 'O', CHANGE AFTER RAGHUNATH SIR MAIL 2018-10-05
	,'' AS charge_off_type
	,'' AS def_appl_int_rate_flg
	,'' AS def_appl_int_rate
	,'' AS deferred_int_amt
	,'' AS auto_reshdl_not_allowed
	,'' AS reshdl_overdue_prin
	,'' AS reshdl_overdue_int
	,'N' AS loan_type
	,'' AS payoff_reason_code
	, '' rel_deposit_acid    -- REQUIRED FOR LOAN AGAINST TD
	,'' AS last_aod_aos_date
	,'' AS refin_sanct_date
	,'' AS refin_amt
	,'' AS sbsdy_acid
	,'' AS sbsdy_agency
	,'' AS prin_sbsdy_claimed_date
	,'' AS subs_act_code
	,'' AS aod_aos_type
	,'' AS refin_sanct_num
	,'' AS refin_ref_num
	,'' AS refin_avld_date
	,'' AS prin_sbsdy_amt
	,'' AS prin_sbsdy_rcvd_date
	,'' AS pre_process_fee
	,'' AS act_code
	,'' AS probation_prd_mths
	,'' AS probation_prd_days
	,'' AS comp_date_flg
	,'' AS disc_rate_flg
	,'Y' AS int_coll_flg
	,'N' AS ps_despatch_mode
	,'' AS acct_mgr_user_id
	,'OTH' AS mode_of_oper_code
	,'' AS ps_freq_type
	,'' AS ps_freq_week_num
	,'1' AS ps_freq_week_day
	,'' AS ps_freq_start_dd
	,'' AS ps_freq_hldy_stat
	,'N' AS pb_ps_code
	,'' AS ps_next_due_date
	,'' AS fixedterm_mnths
	,'' AS fixedterm_years
	,'' AS min_int_pcnt_dr	--As per parameter
	,'' AS max_int_pcnt_dr	--As per parameter
	,'' AS install_income_ratio
	,'' AS product_group		--TBD
	,la.MainCode AS free_text
	,'' AS linked_acct_id
	,'' AS delinq_reshdl_mthd_flg
	,'' AS total_num_of_switchover
	,'' AS non_starter_flg
	,'' AS float_int_tbl_code
	,'' AS float_repricing_freq_mnths
	,'' AS float_repricing_freq_days
	,'' AS singleemi_tenordiff_flg
	,'' AS iban_number
	,'' AS ias_code
	,'' AS topup_acid
	,'' AS topup_type
	,'0' AS negotiated_rate_dr
	,'F' AS penal_prod_mthd_flg
	,'D' AS penal_rate_mthd_flg
	,'Y' AS full_penal_mthd_flg
	,'' AS hldy_prd_frm_first_disb_flg
	/*,case when lm.RepaySchedType in ('A','E') then 'Y' else 'N' end ei_schm_flg
	,CASE when lm.RepaySchedType in ('A','E') then 'R' else '' end ei_method
	,CASE when lm.RepaySchedType in ('A','E') THEN 'P' ELSE '' END AS ei_formula_flg
*/	
	,case when la.LoanType = 'EMI' then 'Y' else 'N' end ei_schm_flg
	,CASE when la.LoanType = 'EMI' then 'R' else '' end ei_method
	,CASE when la.LoanType = 'EMI' THEN 'P' ELSE '' END AS ei_formula_flg

	,'' AS nrml_hldy_perd_mnths
	,'' AS hldy_perd_int_flg
	,'' AS hldy_perd_int_amt
	,'' AS rshdl_tenor_ei_flg
	,'' AS rshdl_disbt_flg
	,'B' AS rshdl_rate_chng_flg   
	,'Y' AS rshdl_prepay_flg	
	,'O' AS rshdl_amt_flg
	,'N' AS rephase_capitalize_int
	,CASE when la.LoanType = 'EMI' then '' else 'A' END AS rephase_carry_ovdu_dmds
	,'I' AS type_of_instlmnt_comb
	,CASE when la.LoanType = 'EMI' THEN  'Y' ELSE ''  END AS cap_emi_flg                        
	,'' AS emicap_deferred_int
	,'' AS start_dfmnt_mnth
	,'' AS num_mnths_deferred
	,RIGHT(SPACE(10)+CAST('0' AS VARCHAR(10)),10) AS chnl_cr_pref_pcnt
	,RIGHT(SPACE(10)+CAST('0' AS VARCHAR(10)),10) AS chnl_dr_pref_pcnt
	,'' AS channel_id
	,'' AS channel_level_code
	,'' AS instlmnt_grace_perd_term_flg
	,RIGHT(SPACE(10)+CAST('0' AS VARCHAR(10)),10) AS instlmnt_grace_perd_mnths
	,CASE when la.LoanType = 'EMI' THEN  'N' Else 'Y' end AS shift_instlmnt_flg
	,CASE when la.LoanType = 'EMI' THEN  'N' Else 'Y' end AS include_matu_date_flg      
	,'' AS rule_code
	,'' AS cum_capitalize_fees
	,'' AS upfront_instl_int_amt
	,'N' AS recall_flg --Yes for Margin Lending TBD
	,'' AS recall_date
	,'' AS ps_diff_freq_rel_party_flg
	,'' AS swift_diff_freq_rel_party_flg
	,'' AS penal_int_tbl_code   -- Int Tbl code TBD
	,'2' AS penal_pref_pcnt
	,'' AS resp_acct_ref_no
	,'' AS int_version
	,'' AS add_type
	,'' AS phone_type
	,'' AS email_type
	,'' AS accrued_penal_int_recovery --TBD
	,'' AS penal_int_recovery
	,'' AS coll_int_recovery
	,'' AS coll_penal_int_recovery
	,'' AS markup_int_rate_appl_flg
	,'' AS preferred_cal_base
	,'' AS purchase_ref
	,CASE WHEN la.IsBlocked IN ('B','T','L','D') THEN 'T'
	 WHEN la.IsBlocked = '-' THEN 'C'
	 WHEN la.IsBlocked = '+' THEN 'D'
	 ELSE ''
	 END  AS frez_code
	 
	--,CASE WHEN la.IsBlocked = '' THEN 'OTHER'
	--END AS frez_reason_code
	,CASE WHEN la.IsBlocked IN ('B','T','L','D','-','+') THEN 'OTH'
	else '' END AS frez_reason_code
	 --,case when laa.IsBlocked in ('B' ,'T', 'D','-','+','L') then 'OTHER' else '' end frez_reason_code  
 	,'' AS RL001_232
	,'' AS RL001_233
	,'' AS RL001_234
	,'' AS RL001_235
	,'' AS RL001_236
	,'' AS RL001_237
	,'' AS RL001_238
	,'' AS RL001_239
	,'' AS RL001_240
	,'' AS RL001_241
	,'' AS RL001_242
	,'' AS RL001_243
	,'' AS RL001_244
	,'' AS RL001_245
	,'' AS RL001_246
	,'' AS RL001_247
	,'' AS RL001_248
	,'' AS RL001_249
	,'' AS RL001_250
	,'' AS RL001_251
	,'' AS RL001_252
	,'' AS RL001_253
	,'' AS RL001_254
	,'' AS RL001_255
	,'' AS RL001_256
	--, la.Nominee RL001_257
	--,ISNULL(Nom.ForAcid,'0010100000074011') as RL001_257
	,'' AS RL001_257
	,'' AS RL001_258
	,'' AS RL001_259
	,'' AS RL001_260
	,'' AS RL001_261
	,'' AS RL001_262
	,'' AS RL001_263
	,'' AS RL001_264
	,'' AS RL001_265
	,'' AS RL001_266
	,'' AS RL001_267
	,'' AS RL001_268
	,'' AS RL001_269
	,'' AS RL001_270
	,'' AS RL001_271
	,'' AS RL001_272
	,'' AS RL001_273
	,'' AS RL001_274
	,'' AS RL001_275
	,'' AS RL001_276
	,'' AS RL001_277
	,'' AS RL001_278
	,'' AS RL001_279
	,'' AS RL001_280
	,'' AS RL001_281
	,'' AS RL001_282
	,'' AS RL001_283
	,'' AS RL001_284
	,'' AS RL001_285
	,'' AS RL001_286
	,'' AS RL001_287
	,'' AS RL001_288
	,'' AS RL001_289
	,'' AS RL001_290
	,'' AS RL001_291
	,'' AS RL001_292
	,'' AS RL001_293
	,'' AS RL001_294
	,'' AS RL001_295
	,'' AS RL001_296
	,'' AS RL001_297
	,'' AS RL001_298
	,'' AS RL001_299
	,'' AS RL001_300
	,'' AS RL001_301
	,'' AS RL001_302
	,'' AS RL001_303
	,'' AS RL001_304
	,'' AS RL001_305
	,'' AS RL001_306
	,'' AS RL001_307
	,'' AS RL001_308
	,'' AS RL001_309
	,'' AS RL001_310
	,'' AS RL001_311
	,'' AS RL001_312
	,'' AS RL001_313
	,'' AS RL001_314
	,'' AS RL001_315
	,'' AS RL001_316
	,'' AS RL001_317
	,'' AS RL001_318
	,'' AS RL001_319
	,'' AS RL001_320
	,'' AS RL001_321
	,'' AS RL001_322
	,'' AS RL001_323
	,'' AS RL001_324
	,'' AS RL001_325
	,'' AS RL001_326
	,'' AS RL001_327
	,'' AS RL001_328
	,'' AS RL001_329
	,'' AS RL001_330
	,'' AS RL001_331
	,'' AS RL001_332
	,'' AS RL001_333
	,'' AS RL001_334
	,'' AS RL001_335
	,'' AS RL001_336
	,'' AS RL001_337
	,'' AS RL001_338
	,'' AS RL001_339
	,'' AS RL001_340
	,'' AS RL001_341
	,'' AS RL001_342
	,'' AS RL001_343
	,'' AS RL001_344
	,'' AS RL001_345
	,'' AS RL001_346
	,'' AS RL001_347
	,'' AS RL001_348
  from #TotalLoan la 
  join FINMIG.dbo.ForAcidLAA flaa on la.MainCode=flaa.MainCode
 join FINMIG.dbo.GEN_CIFID G on G.ClientCode =la.ClientCode
 left join (SELECT MainCode, ForAcid, F_SolId, CyCode FROM FINMIG.dbo.ForAcidSBA UNION ALL SELECT MainCode, ForAcid, F_SolId, CyCode FROM FINMIG.dbo.ForAcidOD)  Nom on la.Nominee=Nom.MainCode

where la.BranchCode not in ('242','243')

