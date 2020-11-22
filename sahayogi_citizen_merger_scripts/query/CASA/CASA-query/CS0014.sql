

--CS0014 SQL QUERY	
use PPIVSahayogiVBL

Declare @MigDate date, @v_MigDate nvarchar(15),@MigDate1 date,@v_MigDate1 nvarchar(15)
set @MigDate = (select Today+1 from ControlTable);
set @v_MigDate=REPLACE(REPLACE(CONVERT(VARCHAR,@MigDate,105), ' ','-'), ',','')

set @MigDate1 = (select Today+2 from ControlTable);
set @v_MigDate1=REPLACE(REPLACE(CONVERT(VARCHAR,@MigDate1,105), ' ','-'), ',','')

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

select distinct --- Lots of Identical data
M.IsBlocked,
F.F_SolId SOL_ID                                                   ,
case when ShowFreq = '1' then 'D'
	when ShowFreq = '4' then 'M'
	else 'D' end SI_Freq_Type                          ,
'' SI_Freq_Week_Num                                                 ,
'' SI_Freq_Week_Day                                                 ,
/*CASE WHEN AmountXfrValue ='A' THEN '1'
	ELSE '' END AS SI_Freq_Start_DD                                                 , -- provided by Durga dai default value 1
*/
 --- For SI_Freq_Type=M, SI_Freq_Start_DD should not be null
 --- so, Rectificed on Jun 21 for  0150100000873010 The frequency combination is invalid.
 
 	replace(case			 
	when ShowFreq = '4' then DatePart(Day,@MTH)
	when ShowFreq = '5' then DatePart(Day,@QTR)
	when ShowFreq = '6' then DatePart(Day,@HYR)
	when ShowFreq = '7' then DatePart(Day,@YR)
	else '' end,0,' ')   AS SI_Freq_Start_DD                                              ,

case when ProcessWhen ='S' then 'N'
	when ProcessWhen='E' then 'P' else  'N' end AS SI_Freq_Hldy_Stat                                                ,
case when ProcessWhen ='S' then 'B'
	when ProcessWhen='E' then 'A' else  'B'end as SI_exec_code       ,
--isnull(ExpiryDate,'31-12-2099') SI_end_date                           ,
case when isnull(ExpiryDate,'')<>'' then 
	case when ExpiryDate < (
			case when ShowFreq = '1' then
		case when ProcessWhen<>'E' then @MigDate1 else @MigDate end 
	when ShowFreq = '4' then @MTH
	when ShowFreq = '5' then @QTR
	when ShowFreq = '6' then @HYR
	when ShowFreq = '7' then @YR
	 else '31-12-2099' end ) then  case when ShowFreq = '1' then
		case when ProcessWhen<>'E' then @v_MigDate1 else @v_MigDate end 
	when ShowFreq = '4' then @v_MONTH
	when ShowFreq = '5' then @v_QTR
	when ShowFreq = '6' then @v_HYR
	when ShowFreq = '7' then @v_YR
	else '31-12-2099'
	 end
	else replace(convert(NVARCHAR, ExpiryDate, 105), ' ', '-') end
else '31-12-2099' end SI_end_date,
--CONVERT(VARCHAR(10),dateadd(day , 30 , ISNULL(ShowDate,@v_MigDate)),105) Next_exec_date      ,	--default value for null = Migration Date +1/also need to check isnull case 

	case when ShowFreq = '1' then
		case when ProcessWhen<>'E' then @v_MigDate1 else @v_MigDate end 		--next int run date from mapping table
	when ShowFreq = '4' then @v_MONTH
	when ShowFreq = '5' then @v_QTR
	when ShowFreq = '6' then @v_HYR
	when ShowFreq = '7' then @v_YR
	else '31-12-2099'
	 end AS Next_exec_date,
F.ForAcid tgt_Acct , --durga dai /amithav                                                 ,
/*CASE WHEN AmountXfrValue ='A' THEN 'E'
	ELSE 'C' END AS Balance_Ind 
*/
'E' as   Balance_Ind, -- by durda dai /amithav jan 06 
                                              
--CASE WHEN AmountXfrValue ='A' THEN 'E'
--	ELSE 'S' END AS Excess_Short_Ind                                                 ,
'E' AS Excess_Short_Ind                                                 ,
RIGHT(SPACE(17)+CAST('' AS VARCHAR(17)),17) Tgt_balance                                                      ,
'Y' Auto_pstd_flg                                                    ,
'Y' Carry_for_alwd_flg                                               ,
'N' Validate_Crncy_Hldy                                 ,
'Y' Del_tran_if_not_pstd                                             ,
RIGHT(SPACE(5)+CAST('0' AS VARCHAR(5)),5) Carry_forward_limit                                              ,
'C' SI_Class                                                         ,
(select G.cif_id from FINMIG.dbo.GEN_CIFID G
	 where G.ClientCode = M.ClientCode) CIF_ID                                                           ,
isnull(Description,'') Remarks                                                          ,
'' Closure_remarks                                                  ,
'' Exec_chrg_code                                            ,
'' Failure_chrg_code                                              ,
'' Chrg_rate_code                                                 ,
'' Chrg_dr_acid ,
CASE WHEN AmountXfrValue ='A' THEN 'F'
	ELSE 'V' END AS Amount_Ind  ,
'N' Create_Memo_Pad_Entry                              ,
CyDesc as Crncy_Code,
CASE WHEN AmountXfrValue ='A' THEN  RIGHT(SPACE(17)+CAST(Amount AS VARCHAR(17)),17)
	else RIGHT(SPACE(17)+CAST('' AS VARCHAR(17)),17) end as Fixed_Amount                                                     , --need to follow up
'D' Part_Tran_Type                                                   ,
/*CASE WHEN AmountXfrValue ='A' THEN 'E'
	ELSE 'C' END AS Balance_Ind 
*/
'E' as   Balance_Ind, -- by durda dai /amithav jan 06                                             ,
--CASE WHEN AmountXfrValue ='A' THEN 'E'
--	ELSE 'S' END AS Excess_Short_Indicator                                           , 	--need to discuss
'E' Excess_Short_Indicator                                           , 	--need to discuss	
F.ForAcid No_of_Account   , 
CASE WHEN AmountXfrValue ='A' THEN ''
	ELSE RIGHT(SPACE(17)+CAST('' AS VARCHAR(17)),17) END AS Acct_Bal                                                  ,
CASE WHEN AmountXfrValue ='A' THEN ''
ELSE RIGHT(SPACE(8)+CAST('100' AS VARCHAR(8)),8) END AS  Percentage                      ,		--need to discuss
CASE WHEN AmountXfrValue ='A' THEN '1'
	ELSE '' END AS Amount_multiple                                                  ,
 F.ForAcid ADM_Account_No_Dr                                                  ,
'N' Round_off_Type                                                   , --Nearest
RIGHT(SPACE(17)+CAST('1.00' AS VARCHAR(17)),17) as Round_off_Value                                                  ,
'N' Collect_Chrg                                                  ,
'' Report_Code                                                      ,
'' Reference_No_cr                                                ,
'Standing Instruction' Tran_particular_cr                                                 ,
'' Tran_remarks_cr		,
'' Intent_Code_cr                                                      ,
'' DD_payable_bank_code                                             ,
'' DD_payable_branch_code                                           ,
'' Payee_name                                                       ,
'' Purchase_Acct_No                                          ,
'' Purchase_Name                                                    ,
'' cr_adv_pymnt_flg                                                 ,
CASE WHEN AmountXfrValue ='A' THEN 'F'
	ELSE 'C' END AS Amount_Indicator                                                 ,
'N' Create_Memo_Pad_Entry                                            ,
Dest.ForAcid ADM_Account_No_Cr                                                  ,
'N' Round_off_Type                                                   ,
RIGHT(SPACE(17)+CAST('1.00' AS VARCHAR(17)),17) as Round_off_Value                                                  ,
'N' Collect_Charges                                                  ,
'' Report_Code                                                      ,
'' Reference_No_dr                                                 ,
'Standing Instruction' Tran_particular_dr                                                  ,
'' Tran_remarks_dr                                                     ,
'' Intent_Code_dr                                                     ,
'' SI_priority                                                      ,
'' si_freq_cal_base                                                 ,
'' cr_ceiling_amt                                                   ,
'' cr_cumulative_amt                                                ,
'' dr_ceiling_amt                                                   ,
'' dr_cumulative_amt                                                ,
'' siFreqNdays                                                      ,
'' Script_File_Name,
S.MainCode,
AmountXfrValue,
Amount,
ShowFreq,
F.ForAcid
from StandingIns S 
join Master M on S.MainCode = M.MainCode
join Master ma on ma.MainCode = S.DestAccount
join CurrencyTable T on M.CyCode =T.CyCode
join (select * From FINMIG.dbo.ForAcidSBA UNION all select * from FINMIG.dbo.ForAcidOD) F on S.MainCode= F.MainCode
join (select * From FINMIG.dbo.ForAcidSBA UNION all select * from FINMIG.dbo.ForAcidOD) Dest on S.DestAccount= Dest.MainCode
where isnull(ExpiryDate,cast('31-DEC-2099' as date))>=@MigDate ---Added on Jun 12 for Issue Date cannot be greater than Expiry Date[]
and ((AmountXfrValue ='A'  and Amount<>0) or (isnull(AmountXfrValue,'') <>'A'))  --Added on Jun 12 Amount should not be zero.
--and M.IsBlocked not in ('B','T','C','+') and M.IsDormant = 'T'
and M.IsBlocked not in ('C') --and M.IsDormant = 'T'



--and DestAccount not in ('0010000210CC','0010000275CC','0010000075CC')
--AND M.MainCode='00101900014842000001'
order by tgt_Acct

-- 1406 ROWS IN THIRD MIGRATION 
