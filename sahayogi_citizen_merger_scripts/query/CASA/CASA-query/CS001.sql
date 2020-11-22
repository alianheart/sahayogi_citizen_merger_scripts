use PPIVSahayogiVBL

Declare @MigDate date, @v_MigDate nvarchar(15)
set @MigDate = (select Today from ControlTable);
set @v_MigDate=REPLACE(REPLACE(CONVERT(VARCHAR,@MigDate,105), ' ','-'), ',','')

DECLARE @DAY DATE, @v_DAY nvarchar(15),@MTH DATE,@v_MONTH nvarchar(15),
@QTR DATE, @v_QTR nvarchar(15), @HYR DATE,@v_HYR nvarchar(15), @YR DATE, @v_YR nvarchar(15)

set @DAY = (select Today from ControlTable);
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
SELECT 
			   m.ClientCode
              ,AcType
              ,IntCrRate
              ,BranchCode
			  ,(select F_SolId from FINMIG..SolMap where BranchCode = m.BranchCode) as F_SolId
              ,AcOpenDate
              ,MainCode
              ,isnull(TaxPercentOnInt,0) as TaxPercentOnInt
              ,IntPostFrqCr
              ,TaxPostFrq
			 ,CyDesc as acct_crncy_code
              ,IsBlocked
              ,replace(replace(m.Name, '&', 'and'), ',', '/') as Name
              ,m.CyCode
              ,IsDormant
			  ,m.Limit
			  ,m.Balance
              ,ClientTag3
              ,GoodBaln
              ,LastTranDate
              ,(select LastTranDate from FINMIG.dbo.LAST_TRANS_DATE l where m.MainCode=l.MainCode) as trans_LastTranDate
              ,m.AcOfficer
              ,ClientCategory
              
			  /*,ISNULL((SELECT ltrim(rtrim(convert(varchar,REPLACE(FreeCode7,' ','')))) from FINMIG..CURRENT_FREE_CODE_7 cf
				where m.MainCode = cf.PumoriAccountNumber),'') as current_free_code_7 */ --changed in sahayogi migration
				,'' as current_free_code_7
              FROM Master(nolock) m join ClientTable(nolock) c on m.ClientCode = c.ClientCode
              JOIN CurrencyTable C
              on m.CyCode = C.CyCode
where (m.MainCode in 
		(select MainCode from Master(nolock) 
		where AcType IN (SELECT ACTYPE FROM FINMIG.dbo.PRODUCT_MAPPING WHERE MODULE = 'SAVING' and IsBlocked<>'C'
		AND BranchCode not in ('242','243') --or Limit <> 0
		))
		OR (m.MainCode in (select MainCode from Master(nolock) 
			where AcType IN (SELECT ACTYPE FROM FINMIG.dbo.PRODUCT_MAPPING WHERE MODULE = 'CURRENT')
								AND Limit = '0'
								AND Balance>='0' and IsBlocked<>'C'
								AND BranchCode not in ('242','243')
								))
	AND m.MainCode not in ( select MainCode from Master(nolock) 
	where AcType='01' and CyCode='01' and IntDrAmt<>'0' and Limit='0' 
	and IsBlocked<>'C' and BranchCode not in ('242','243'))
		))x


select 
--MainCode as foracid,
(select ForAcid from FINMIG.dbo.ForAcidSBA f where f.MainCode = t1.MainCode) as foracid,
--BranchCode+CyCode+Right('00000000'+cast(ROW_NUMBER() OVER( PARTITION BY BranchCode,F_SCHEME_CODE ORDER BY BranchCode,AcOpenDate ,F_SCHEME_CODE) AS nvarchar(8)),8) +right(F_SCHEME_CODE,3) foracid													,											

CASE WHEN AcType <> '01' then
	CASE WHEN TaxPercentOnInt > '0' then 'W' else 'N' END
else 'N' end wtax_flg ,   
CASE WHEN AcType <> '01' then
	CASE WHEN TaxPercentOnInt > '0' then 'P' else '' END 
else'' end wtax_amount_scope_flg   , 
case when F_SCHEME_CODE in ('NK043', 'SD122') then RIGHT(SPACE(8)+CAST(5 AS VARCHAR(8)),8) else RIGHT(SPACE(8)+CAST(TaxPercentOnInt AS VARCHAR(8)),8) end wtax_pcnt,
'' wtax_floor_limit,
/*case when (
ClientCategory  like 'Com%'
OR ClientCategory  like 'Partn%'
OR ClientCategory  like 'Sole%'
OR ClientCategory like 'Oth%'
) then 'C0'+ClientCode
else 'R0'+ClientCode end as CIF_id  ,
*/
(select cif_id from FINMIG.dbo.GEN_CIFID G where G.ClientCode = t1.ClientCode) as CIF_id,
'0' cust_cr_pref_pcnt                                          ,
'0' cust_dr_pref_pcnt

--,case when (select INTEREST_TABLE_CODE from FINMIG.dbo.ForAcidSBA f where f.MainCode = t1.MainCode) 
--like '%ZERO%' THEN RIGHT(SPACE(10)+CAST(t1.IntCrRate AS VARCHAR(10)),10) else '' end id_cr_pref_pcnt ,

,case when INTEREST_TABLE_CODE like '%ZERO%' then RIGHT(SPACE(10)+CAST(t1.IntCrRate AS VARCHAR(10)),10) else '' 
end id_cr_pref_pcnt ,

'0' id_dr_pref_pcnt                                            ,
'0' chnl_cr_pref_pcnt                                          ,
'0' chnl_dr_pref_pcnt                                          ,
'N' Pegged_flg                                                 ,
'' peg_frequency_in_months                                    ,
'' peg_frequency_in_days                                      ,
--'D' int_freq_type_cr                                           ,
/*case when IntPostFrqCr = '1' then 'D'
	when IntPostFrqCr = '4' then 'F'
	when IntPostFrqCr = '5' then 'Q'
	when IntPostFrqCr = '6' then 'H'
	when IntPostFrqCr = '7' then 'Y'
	end AS int_freq_type_cr,
*/	
CASE WHEN AcType <> '01' then 'D'
else 'D' end as int_freq_type_cr,
'' int_freq_week_num_cr                                       ,
'' int_freq_week_day_cr                                       ,
'' int_freq_start_dd_cr                                       ,
'N' int_freq_hldy_stat_cr                                      ,
--'' next_int_run_date_cr                                       ,			--BOD DATE
case when AcType <> '01' then
	case when IntPostFrqCr = '1' then @v_MigDate		--next int run date from mapping table
	when IntPostFrqCr = '4' then @v_MONTH
	when IntPostFrqCr = '5' then @v_QTR
	when IntPostFrqCr = '6' then @v_HYR
	when IntPostFrqCr = '7' then @v_YR
	else '31-12-2099'
	 end
else '31-12-2099' end AS next_int_run_date_cr,
'' int_freq_type_dr                                           ,
'' int_freq_week_num_dr                                       ,
'' int_freq_week_day_dr                                       ,
'' int_freq_start_dd_dr                                       ,
'' int_freq_hldy_stat_dr                                      ,
'' next_int_run_date_dr                                       ,
'' ledg_num                                                   ,
--CASE WHEN (t1.AcType='11' and t1.BranchCode = '001' AND t1.IsBlocked <>'C') and ISNULL(t1.ClientTag3,'') <> '' THEN t1.ClientTag3 ELSE '' END AS emp_id                                  ,
 '' AS emp_id,

ISNULL(REPLACE(REPLACE(CONVERT(VARCHAR,AcOpenDate,105), ' ','-'), ',',''),(select REPLACE(REPLACE(CONVERT(VARCHAR,min(TranDate),105), ' ','-'), ',','')
from Master m join TransDetail t on t.MainCode = m.MainCode
where m.MainCode = t1.MainCode
group by m.MainCode)) acct_opn_date                                        ,
'OTH' as   Mode_of_oper_code                                          ,
GL_SUBHEAD_CODE AS Gl_sub_head_code                                           ,
/*(select GL_SUBHEAD_CODE from FINMIG.dbo.PRODUCT_MAPPING where
	t1.AcType = ACTYPE AND t1.acct_crncy_code = CNCY) AS Gl_sub_head_code,
*/	
F_SCHEME_CODE AS Schm_code                                                  ,
/*
(select F_SCHEME_CODE from FINMIG.dbo.PRODUCT_MAPPING where
	t1.AcType = ACTYPE AND t1.acct_crncy_code = CNCY) AS Schm_code,
*/
case when AcType in ('19','2E','2F', '1D') then 'N'
else 'Y' end Chq_alwd_flg                                               ,
'S' Pb_ps_code                                                 ,


'' Frez_code

,'' as Frez_reason_code,

MainCode free_text,

'A' as acct_Status,

'' free_code_1,
'' free_code_2,
--'MIG' free_code_3,
ISNULL((select FinacleCode from #FREECODE3 A
	where  t1.MainCode = A.MainCode AND t1.BranchCode = A.BranchCode),'MIG') free_code_3 ,                                    
'MIGRA' purpose_of_advn  ,
'' free_code_4,
'' free_code_5,
'' free_code_6,
--ISNULL((SELECT FreeCode7 from FINMIG..CURRENT_FREE_CODE_7 cf
--where t1.MainCode = cf.PumoriAccountNumber),'') as free_code_7,
--ISNULL(t1.current_free_code_7,'') AS free_code_7 , 
'' AS free_code_7,  --suggested by durga dai

'' free_code_8,
'' free_code_9,
'' free_code_10,
--INTEREST_TABLE_CODE as int_tbl_code,
case when AcType <> '01' then
	INTEREST_TABLE_CODE	 
else '' end  int_tbl_code,

/*(select INTEREST_TABLE_CODE from FINMIG.dbo.PRODUCT_MAPPING where
	t1.AcType = ACTYPE AND t1.acct_crncy_code = CNCY) AS int_tbl_code,
	*/
'SVBL' acct_loc_code,
acct_crncy_code	as acct_crncy_code,
F_SolId sol_id,
'UBSADMIN' acct_mgr_user_id,
REPLACE(replace(t1.Name,'"',' '),'–','') acct_name,
'N' swift_allowed_flg                                          ,
REPLACE(CONVERT(VARCHAR,isnull(LastTranDate,AcOpenDate),105), ' ','-') last_tran_date,
--REPLACE(CONVERT(VARCHAR,isnull((select MAX(T.TranDate) from TransDetail T where T.MainCode=t1.MainCode), AcOpenDate),105), ' ','-') last_any_tran_date                                         ,
REPLACE(CONVERT(VARCHAR,isnull(t1.trans_LastTranDate, AcOpenDate),105), ' ','-') last_any_tran_date                                         ,
'Y' xclude_for_comb_stmt,
'' stmt_cust_id,
'' chrg_level_code,
'N' pbf_download_flg,
'A' wtax_level_flg,
RIGHT(SPACE(17)+CAST('0' AS VARCHAR(17)),17) sanct_lim,
RIGHT(SPACE(17)+CAST('0' AS VARCHAR(17)),17) Drwng_power,
RIGHT(SPACE(17)+CAST('0' AS VARCHAR(17)),17) dacc_lim_abs      ,
RIGHT(SPACE(8)+CAST('0' AS VARCHAR(8)),8) dacc_lim_pcnt     ,
RIGHT(SPACE(17)+CAST('0' AS VARCHAR(17)),17) max_alwd_advn_lim  ,
'' health_code                                                ,
'' sanct_levl_code                                            ,
'' sanct_ref_num                                              ,
'' lim_sanct_date                                             ,
'' lim_exp_date                                               ,
'' lim_review_date                                            ,
'' loan_paper_date                                            ,
'' sanct_auth_code                                            ,
'' Compound_date                                              ,
'N' daily_comp_int_flg                                         ,
'' COMP_Date_flg                                              ,
'N' disc_rate_flg                                              ,
'' dummy                                                      ,
/*
case when IsDormant='T'  THEN  
	case when dateadd(MM,6,isnull(LastTranDate,AcOpenDate))>@MigDate then @v_MigDate
	else  REPLACE(CONVERT(VARCHAR,dateadd(MM,6,isnull(LastTranDate,AcOpenDate)),105), ' ','-') end
else '' end  acct_status_date                                           ,
*/
'' acct_status_date,  --changed in sahayogi migration sumesh dai


'' iban_number                                                ,
'' ias_code                                                   ,
'' channel_id                                                 ,
'' channel_level_code                                         ,
RIGHT(SPACE(17)+CAST(' ' AS VARCHAR(17)),17) int_suspense_amt ,
RIGHT(SPACE(17)+CAST(' ' AS VARCHAR(17)),17) Penal_int_Suspense_amt    ,
'' Chrge_off_flg                                              ,
'' pd_flg                                                     ,
'' pd_xfer_Date                                               ,
'' Chrge_off_date                                             ,
RIGHT(SPACE(17)+CAST(' ' AS VARCHAR(17)),17) Chrge_off_principal                                        ,
RIGHT(SPACE(17)+CAST(' ' AS VARCHAR(17)),17) Pending_interest                                           ,
RIGHT(SPACE(17)+CAST(' ' AS VARCHAR(17)),17) Principal_recovery                                         ,
RIGHT(SPACE(17)+CAST(' ' AS VARCHAR(17)),17) interest_recovery                                          ,
'' Charge_off_type                                            ,
'' master_acct_num                                            ,
'' ps_diff_freq_rel_party_flg                                 ,
'' swift_diff_freq_rel_party_flg                              ,
'' add_type                                                   ,
'' Phone_type                                                 ,
'' Email_type                                                 ,
'' Alternate_Acct_Name                                        ,
'' Interest_Rate_Period_Months                                ,
'' Interest_Rate_Period_Days                                  ,
'' Interpolation_Method                                       ,
'' Is_Acct_hedged_Flg                                         ,
'' Used_for_netting_off_flg                                   ,
'' Security_Indicator                                         ,
'' Debt_Security                                              ,
'' Security_Code                                              ,
'' Debit_Interest_Method                                      ,
'Y' serv_chrg_coll_flg                                         ,
'' Last_purge_date                                            ,
'' Total_profit_amt                                           ,
'' Minimum_age_not_met_amt                                    ,
'' Broken_period_profit_paid_flg                              ,
'' Broken_period_profit_amt                                   ,
'' Profit_to_be_recovered                                     ,
'' Profit_distributed_upto_date                               ,
'' Next_profit_distributed_date                               ,
'' Accrued_amt_till_interest_calc_date_cr                     ,          
'' Unclaim_status                                             ,
'' Unclaim_status_date                                        ,
'' Gl_Sub_Head_Code
from #FinalMaster t1
join FINMIG.dbo.PRODUCT_MAPPING
ON AcType = ACTYPE 
AND acct_crncy_code = CNCY
WHERE MODULE in  ('CURRENT','SAVING')
--and F_SCHEME_CODE in ('NK043', 'SD122')
--and MainCode = '00501000005151000002'
order by foracid


