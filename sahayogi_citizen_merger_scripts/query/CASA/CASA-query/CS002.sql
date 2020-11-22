use PPIVSahayogiVBL
--cs002

Declare @MigDate date, @v_MigDate nvarchar(15),@v_StatusDate nvarchar(15)
set @MigDate = (select Today from ControlTable);
set @v_MigDate=REPLACE(REPLACE(CONVERT(VARCHAR,@MigDate,105), ' ','-'), ',','')
set @v_StatusDate = REPLACE(CONVERT(VARCHAR,(select Today-1 from ControlTable),105), ' ','-')



DECLARE @DAY DATE, @v_DAY nvarchar(15),@MTH DATE,@v_MONTH nvarchar(15),
@QTR DATE, @v_QTR nvarchar(15), @HYR DATE,@v_HYR nvarchar(15), @YR DATE, @v_YR nvarchar(15)

set @DAY = (select LastDay from ControlTable);
set @v_DAY=REPLACE(REPLACE(CONVERT(VARCHAR,@DAY,105), ' ','-'), ',','')

set @MTH = (select NextMonthEnd from FINMIG.dbo.NextIntRunDate );
set @v_MONTH=REPLACE(REPLACE(CONVERT(VARCHAR,@MTH,105), ' ','-'), ',','')

set @QTR = (select NextQtrEnd from FINMIG.dbo.NextIntRunDate );
set @v_QTR=REPLACE(REPLACE(CONVERT(VARCHAR,@QTR,105), ' ','-'), ',','')

set @HYR = (select NextHalfYearEnd from FINMIG.dbo.NextIntRunDate );
set @v_HYR=REPLACE(REPLACE(CONVERT(VARCHAR,@HYR,105), ' ','-'), ',','')

set @YR = (select NextYeaerEnd from FINMIG.dbo.NextIntRunDate );
set @v_YR=REPLACE(REPLACE(CONVERT(VARCHAR,@YR,105), ' ','-'), ',','')


---------------FREE CODE 3 MAPPING QUERY-----------------------
IF OBJECT_ID('tempdb.dbo.#FREECODE3', 'U') IS NOT NULL
  DROP TABLE #FREECODE3;
  
select * INTO #FREECODE3 from (
SELECT  distinct MainCode,BranchCode,UPPER(CONVERT(VARCHAR,CustType)) as CustType,F.FnacleCode as FinacleCode from AcCustType A JOIN
		FINMIG..FREECODE3 F ON UPPER(CONVERT(VARCHAR,CustType))=F.PumoriCustType
	where  A.CustTypeCode ='B')X


IF OBJECT_ID('tempdb.dbo.#FinalMaster', 'U') IS NOT NULL
  DROP TABLE #FinalMaster;

select * INTO #FinalMaster from (
SELECT  DISTINCT
			   t1.ClientCode
              ,AcType
              ,ClientTag3
              ,IntDrRate
              ,IntCrRate
              --,t1.Limit as Limit
            
             ,case when t1.Limit='0' and round(t1.GoodBaln,2)<'0' then ABS(round(GoodBaln,2))
					WHEN t1.Limit<abs(round(t1.GoodBaln,2)) and round(t1.GoodBaln,2)<'0' then ABS(round(GoodBaln,2))
			   else t1.Limit end as Limit
			   ,t1.Limit as Limit1
			   
              ,BranchCode
			  ,(select F_SolId from FINMIG..SolMap where BranchCode = t1.BranchCode) as F_SolId
              ,case when t1.Limit='0' and round(GoodBaln,2)<'0' then @MigDate
              else LimitExpiryDate end as LimitExpiryDate_origi
              --,LimitExpiryDate 
              ,AcOpenDate as AcOpenDate_original
              --DURGA  DAI JAN 1 2019
              ,case when LimitExpiryDate<AcOpenDate	and LimitExpiryDate<='2000-12-31' then @DAY --last day
					else  LimitExpiryDate end as LimitExpiryDate
              ,case when LimitExpiryDate<AcOpenDate	and LimitExpiryDate>'2000-12-31' then dateadd(day,-2,LimitExpiryDate)
					else case when datediff(day,AcOpenDate,LimitExpiryDate)=1 then dateadd(day,-2,LimitExpiryDate)  
					 else AcOpenDate end
					 end as AcOpenDate

              ,MainCode
              ,isnull(TaxPercentOnInt,0) as TaxPercentOnInt
              ,IntPostFrqCr
              ,TaxPostFrq
              ,'02' as PremiumRateDr
              ,DistrictCode
              ,GoodBaln
      		 ,CyDesc as acct_crncy_code
              ,IsBlocked
              ,t1.CyCode
              ,IntPostFrqDr
              ,t1.Name
              ,IsDormant
              ,LastTranDate
              ,(select LastTranDate from FINMIG.dbo.LAST_TRANS_DATE l where t1.MainCode=l.MainCode) as trans_LastTranDate
              ,t1.AcOfficer
              ,ClientCategory
FROM Master t1 join ClientTable t2
on t1.ClientCode = t2.ClientCode
join CurrencyTable t3
on t1.CyCode = t3.CyCode
where (AcType IN (SELECT ACTYPE FROM FINMIG.dbo.PRODUCT_MAPPING WHERE MODULE ='OVERDRAFT' and ACTYPE <>'01')
 or (AcType = '01' and (t1.Limit <>'0' or (t1.Limit='0' and Balance<'0') or (t1.Limit='0' and IntDrAmt<>'0' and t1.CyCode='01')))) ---  AND Balance >0 need to add in logic	
AND BranchCode not in('242','243')
--and AcType not in ('4A', '49')
AND IsBlocked <> 'C'
)x;


--Main Script
select
(select ForAcid from FINMIG.dbo.ForAcidOD f where f.MainCode = t1.MainCode) as foracid,
'N' wtax_flg                                               ,
'' wtax_amount_scope_flg                                  ,
'0' wtax_pcnt                                              ,
'0' wtax_floor_limit                                       ,

(select cif_id from FINMIG.dbo.GEN_CIFID  G where G.ClientCode = t1.ClientCode) as CIF_id,
'0' cust_cr_pref_pcnt                                      ,
'0' cust_dr_pref_pcnt                                      ,
'0' id_cr_pref_pcnt                                        ,


	  
case when (select F_SCHEME_CODE from FINMIG.dbo.ForAcidOD sch where sch.MainCode = t1.MainCode) = 'SH501'
then RIGHT(SPACE(10)+CAST(8 AS VARCHAR(10)),10) else 
case
	when (select INTEREST_TABLE_CODE from FINMIG.dbo.ForAcidOD f where f.MainCode = t1.MainCode) like '%ZERO%' 
	THEN RIGHT(SPACE(10)+CAST(isnull(t1.IntDrRate, '') AS VARCHAR(10)),10) 
else '' end end as id_dr_pref_pcnt,


'0' chnl_cr_pref_pcnt                                      ,
'0' chnl_dr_pref_pcnt                                      ,
'N' Pegged_flg                                             ,
'' peg_frequency_in_months                                ,
'' peg_frequency_in_days                                  ,
'' int_freq_type_cr                                       ,
'' int_freq_week_num_cr                                   ,
'' int_freq_week_day_cr                                   ,
'' int_freq_start_dd_cr                                   ,
'' int_freq_hldy_stat_cr                                  ,
'' next_int_run_date_cr                                   ,
'D' int_freq_type_dr                                       ,
'' int_freq_week_num_dr                                   ,
'' int_freq_week_day_dr                                   ,
'' int_freq_start_dd_dr                                   ,
'N' int_freq_hldy_stat_dr                                  ,
	case when IntPostFrqDr = '1' then @v_MigDate		--next int run date from mapping table
	when IntPostFrqDr = '4' then @v_MONTH
	when IntPostFrqDr = '5' then @v_QTR
	when IntPostFrqDr = '6' then @v_HYR
	when IntPostFrqDr = '7' then @v_YR
else '31-12-2099' end AS next_int_run_date_dr,
'' ledg_num                                               ,


'' AS emp_id    ,

isnull(REPLACE(REPLACE(CONVERT(VARCHAR,AcOpenDate,105), ' ','-'), ',',''), (select REPLACE(REPLACE(CONVERT(VARCHAR,min(TranDate),106), ' ','-'), ',','')
from Master m join TransDetail t on t.MainCode = m.MainCode
where m.MainCode = t1.MainCode
group by m.MainCode)) acct_opn_date                                          ,
'OTH' as  Mode_of_oper_code                                      ,
(select GL_SUBHEAD_CODE from FINMIG.dbo.ForAcidOD f where f.MainCode = t1.MainCode)  as Gl_sub_head_code       --changed                                ,
,(select F_SCHEME_CODE from FINMIG.dbo.ForAcidOD f where f.MainCode = t1.MainCode)   AS Schm_code        --changed                                      ,
--,'Y' Chq_alwd_flg                                           ,

,case when AcType in ('19','2E','2F', '1D') then 'N'
else 'Y' end Chq_alwd_flg

,'S' Pb_ps_code,
'' Frez_code            
,'' Frez_reason_code
,MainCode free_text                                              ,
'A' acct_Status
,isnull((select Code from FINMIG..Freecode1 f where f.MainCode = t1.MainCode), '') as free_code_1

,'' free_code_2                                            ,
ISNULL((select FinacleCode from #FREECODE3 A
	where  t1.MainCode = A.MainCode AND t1.BranchCode = A.BranchCode),'MIG') free_code_3 ,
'' free_code_4                                            ,
'' free_code_5                                            ,
'' free_code_6                                            ,
'' free_code_7                                            ,
'' free_code_8                                            ,
'' free_code_9                                            ,
'' free_code_10                                           ,
(select INTEREST_TABLE_CODE from FINMIG.dbo.ForAcidOD f where f.MainCode = t1.MainCode) as int_tbl_code,

'SVBL' acct_loc_code,
acct_crncy_code as acct_crncy_code                                       ,
F_SolId sol_id                                                 ,
'UBSADMIN' acct_mgr_user_id                                       ,
replace(t1.Name,'"', '') acct_name                                              ,
'N' swift_allowed_flg                                      ,
REPLACE(REPLACE(CONVERT(VARCHAR,isnull(LastTranDate,AcOpenDate),105), ' ','-'), ',','') last_tran_date                                         ,
REPLACE(CONVERT(VARCHAR,isnull(t1.trans_LastTranDate, AcOpenDate),105), ' ','-') last_any_tran_date ,
'' xclude_for_comb_stmt                                   ,
'' stmt_cust_id                                           ,
'' chrg_level_code                                        ,
'' pbf_download_flg                                       ,
'' wtax_level_flg                                         ,

isnull((select Code from FINMIG..Sectorwise s where s.MainCode = t1.MainCode), 'DEPO') AS sector_code,	
ISNULL((select Code from FINMIG..SubSectorWise ss where ss.MainCode = t1.MainCode) ,'DEPO') sub_sector_code                                        ,

'MIGRA' purpose_of_advn ,

ISNULL((select Code from FINMIG..NatureOfAdvance na where na.MainCode = t1.MainCode) ,'MIGR') as nature_of_advn

,ISNULL((select Code from FINMIG..IndustryType it where it.MainCode = t1.MainCode),'MIGR') industry_type                                          ,

/*
CASE WHEN t1.AcType in ('49','4A') then 
	case when exists (select 1 from Master m where m.ClientCode = t1.ClientCode and m.AcType in ('18') and m.BranchCode = '001' AND m.IsBlocked <>'C')  then 'O'
		else 'S' end
	else 'S' end as  int_dr_acct_flg                                        ,
*/
'S' as int_dr_acct_flg
,''  as int_dr_acid,

RIGHT(SPACE(17)+CAST(isnull(t1.Limit,'0') AS VARCHAR(17)),17)  sanct_lim                                              ,
RIGHT(SPACE(17)+CAST(isnull(t1.Limit,'0') AS VARCHAR(17)),17) Drwng_power                                            ,
RIGHT(SPACE(17)+CAST(' ' AS VARCHAR(17)),17) dacc_lim_abs                                           ,
RIGHT(SPACE(8)+CAST(' ' AS VARCHAR(8)),8) dacc_lim_pcnt                                          ,
RIGHT(SPACE(17)+CAST(isnull(t1.Limit,'0') AS VARCHAR(17)),17) max_alwd_advn_lim                 ,
'MIG' health_code                                            , --need verified 'same as RC001'
'HO' sanct_levl_code                                        ,
t1.MainCode sanct_ref_num                                          , 
/* DURGA  DAI JAN 1 2019
case when Limit = '0' then @v_MigDate
else REPLACE(REPLACE(CONVERT(VARCHAR,isnull(AcOpenDate,@v_MigDate),105), ' ','-'), ',','') end lim_sanct_date  ,
case when Limit = '0' then '31-12-2099'
	when LimitExpiryDate<AcOpenDate then @v_MigDate
	when LimitExpiryDate>'2099-12-31' then '31-12-2099'
else isnull(REPLACE(CONVERT(VARCHAR,LimitExpiryDate,105), ' ','-'),'31-12-2099') end lim_exp_date                                           ,
case when Limit = '0' then '30-12-2099'
	when LimitExpiryDate<AcOpenDate then REPLACE(CONVERT(VARCHAR,dateadd(day,-1,@MigDate),105), ' ','-')
	when LimitExpiryDate>'2099-12-31' then '30-12-2099'
else isnull(REPLACE(CONVERT(VARCHAR,LimitExpiryDate-1,105), ' ','-'),'30-12-2099') end lim_review_date                                        ,
REPLACE(REPLACE(CONVERT(VARCHAR,AcOpenDate,105), ' ','-'), ',','') loan_paper_date   
*/ 
    
REPLACE(REPLACE(CONVERT(VARCHAR,AcOpenDate,105), ' ','-'), ',','') AS lim_sanct_date,
case when LimitExpiryDate>'2099-12-31' then '31-12-2099'
else isnull(REPLACE(CONVERT(VARCHAR,LimitExpiryDate,105), ' ','-'),'31-12-2099') end  AS lim_exp_date ,
CASE when LimitExpiryDate>'2099-12-31' then '30-12-2099'
else isnull(REPLACE(CONVERT(VARCHAR,LimitExpiryDate-1,105), ' ','-'),'30-12-2099') end AS lim_review_date  ,  

REPLACE(REPLACE(CONVERT(VARCHAR,AcOpenDate,105), ' ','-'), ',','') loan_paper_date                      ,
'ACO' sanct_auth_code                                        ,
'' ecgc_appl_flg                                          ,
'' ecgc_dr_acid                                           ,
--REPLACE(REPLACE(CONVERT(VARCHAR,DueDate,105), ' ','-'), ',','') due_date                                               ,
REPLACE(CONVERT(VARCHAR,(select Min(DueDate) from PastDuedList P where t1.MainCode = P.ReferenceNo and IsIntDue = 'T'  group by ReferenceNo),105),' ','-') due_date,                                          
'' rpc_acct_flg                                           ,
'' disb_ind                                               ,
'' Compound_date                                          ,
'' daily_comp_int_flg                                     ,
'' COMP_Date_flg                                          ,
'' disc_rate_flg                                          ,
'' dummy                                                  ,
--case when IsDormant='T' then REPLACE(REPLACE(CONVERT(VARCHAR,dateadd(MM,6,isnull(LastTranDate,AcOpenDate)),105), ' ','-'), ',','') else '01-01-1900' end acct_status_date                                       ,
--case when IsDormant='T' then @v_StatusDate else '' end as acct_status_date,  --changed in sahayogi migration
'' as acct_status_date,

'' iban_number                                            ,
'' ias_code                                               ,
'' channel_id                                             ,
'' channel_level_code                                     ,

/*   -------2018-10-30 as per Roman Dai's mail

--RIGHT(SPACE(17)+CAST(NormalInt AS VARCHAR(17)),17) int_suspense_amt,
RIGHT(SPACE(17)+CAST((select sum(NormalInt) from PastDuedList P where t1.MainCode = P.ReferenceNo and IsIntDue = 'T' group by ReferenceNo) AS VARCHAR(17)),17) int_suspense_amt,

case when  t1.MainCode in (select ReferenceNo from PastDuedList P where t1.MainCode = P.ReferenceNo and IsIntDue = 'T')
 then isnull((select case when (PenalIntAmt+IntOnInt) <0 or (PenalIntAmt+IntOnInt) is null  
	then RIGHT(SPACE(17)+CAST('0' AS VARCHAR(17)),17)
else RIGHT(SPACE(17)+CAST(PenalIntAmt+IntOnInt AS VARCHAR(17)),17) end  from LoanMaster L
where t1.MainCode = L.MainCode),'0') else '' end as Penal_int_Suspense_amt                                 ,


'' Chrge_off_flg                                          ,
--isnull(ReferenceNo,'') as pd_flg,
case when t1.MainCode in (select ReferenceNo from PastDuedList P where t1.MainCode = P.ReferenceNo and IsIntDue = 'T') then 'Y' else '' end as pd_flg,
--REPLACE(REPLACE(CONVERT(VARCHAR,DueDate,105), ' ','-'), ',','') pd_xfer_Date                                           ,
isnull(REPLACE(CONVERT(VARCHAR,(select Min(DueDate) from PastDuedList P where t1.MainCode = P.ReferenceNo and IsIntDue = 'T' group by ReferenceNo),105),' ','-'),'') pd_xfer_Date,                                          

*/ -------2018-10-30 as per Roman Dai's mail

'' int_suspense_amt, -------2018-10-30 as per Roman Dai's mail
'' Penal_int_Suspense_amt, -------2018-10-30 as per Roman Dai's mail
'' Chrge_off_flg  ,
'N' pd_flg,		-------2018-10-30 as per Roman Dai's mail
'' pd_xfer_Date,	-------2018-10-30 as per Roman Dai's mail

'' Chrge_off_date                                         ,
'' Chrge_off_principal                                    ,
'' Pending_interest                                       ,
'' Principal_recovery                                     ,
'' interest_recovery                                      ,
'' Charge_off_type                                        ,
'' master_acct_num                                        ,
'' penal_prod_mthd_flg                                    ,
'' penal_rate_mthd_flg                                    ,
'' waive_min_coll_int                                     ,
'' rule_code                                              ,
'' ps_diff_freq_rel_party_flg                             ,
'' swift_diff_freq_rel_party_flg                          ,
'' add_type                                               ,
'' Phone_type                                             ,
'' Email_type                                             ,
'' accrued_penal_int_recovery                             ,
'' penal_int_recovery                                     ,
'' coll_int_recovery                                      ,
'' coll_penal_int_recovery                                ,
'' pending_penal_interest                                 ,
'' pending_penal_booked_interest                          ,
'' int_rate_prd_in_months                                 ,
'' int_rate_prd_in_days                                   ,
'' penal_int_tbl_code                                     ,
'' penal_pref_pcnt                                        ,
'' interpolation_method                                   ,
'' hedged_acct_flg                                        ,
'' used_for_net_off_flg                                   ,
'' alt1_acct_name                                         ,
'' security_indicator                                     ,
'' debt_seniority                                         ,
'' security_code                                          ,
'' Debit_Interest_Method                                  ,
'Y' Service_chrge_collection_flg                           ,
REPLACE(REPLACE(CONVERT(VARCHAR,AcOpenDate-1,105), ' ','-'), ',','') Last_purge_date                                        ,
'' total_project_cost                                     ,
'' loss_carry_fwd                                         ,
'' unadj_profit_carry_fwd                                 ,
'' collect_excess_profit                                  ,
'' adj_order_for_carry_fwd                                ,
'' bank_profit_share_pcnt                                 ,
'' bank_loss_share_pcnt                                   ,
'' profit_adj_freq_type                                   ,
'' profit_adj_freq_week_num                               ,
'' profit_adj_freq_week_day                               ,
'' profit_adj_freq_start_dd                               ,
'' profit_adj_freq_hldy_stat                              ,
'' next_profit_adj_due_date                               ,
'' tot_bank_captl_share_pcnt                              ,
'' profit_adj_grace_prd_mths                              ,
'' profit_adj_grace_prd_days                              ,
'' adj_cycle_end_date                                     ,
'' unadj_profit_carry_fwd_amt                             ,
'' unadj_profit_settle_amt                                ,
'' unadj_profit_charge_off_amt                            ,
'' loss_carry_fwd_amt                                     ,
'' loss_settle_amt                                        ,
'' loss_charge_off_amt                                    ,
'' profit_adj_amt                                         ,
'' loss_adj_amt                                           ,
'' tot_expected_profit_amt                                ,
'' bank_profit_share_amt                                  ,
'' bank_loss_share_amt                                    ,
'' actual_profit_amt                                      ,
'' actual_loss_amt                                        ,
'' collected_amt                                          ,
'' excess_profit_collected_amt                            ,
'' broken_prd_prft_in_legacy                              ,
'' unclaim_status                                         ,
'' unclaim_status_date                                    ,
'' orig_gl_sub_head_code                                  ,
'' pais_applicable_flg                                    ,
'' pais_bank_amt                                          ,
'' pais_cust_amt                                          ,
'' pais_debited_amt                                       ,
'' pais_effective_date                                    ,
'' pais_coverage_end_date                                 ,
'' primary_crop_code                                      ,
'' primary_crop_state_code                                ,
'' primary_no_of_crop_in_year 
FROM #FinalMaster t1
--where t1.MainCode = '00804300080001000002'
--order by foracid
